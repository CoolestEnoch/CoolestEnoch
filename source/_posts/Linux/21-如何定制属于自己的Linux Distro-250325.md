---
title: 如何定制属于自己的Linux Distro
category: Linux
date: 2025-03-25 00:00:00
index_img: https://i2.hdslb.com/bfs/archive/ce0253f0da7b8d792a1a47439ec381d0cbcdee42.jpg
---


 ![封面](https://i2.hdslb.com/bfs/archive/ce0253f0da7b8d792a1a47439ec381d0cbcdee42.jpg)


# TL;DR
正如RMS所言，计算自由是十分重要的，其中就包括自由的重新分发软件。正好截至写稿日，`Linux`内核是以`GPL v2`发布的。

# 前期准备
我使用的电脑是`Arch Linux`系统，所以后续都基于此前提进行讲述。
安装依赖库，不然编译会出错：
``` shell
sudo pacman -S bc cpio isolinux syslinux genisoimage cdrtools man-pages qemu
```
然后准备好`Linux`主线内核（我使用的是`6.14`）就行，假如你放在`~/LinuxDistroExp/linux`文件夹下。


# 内核
## 处理配置文件
通过`make help`我们可以看到默认可以给32位和64位机器进行构建：
``` config
  i386_defconfig              - Build for i386
  x86_64_defconfig            - Build for x86_64
```
当然，我们使用最小配置进行编译(在上面的输出里可以看到这个配置)：
``` shell
make tinyconfig
```
然后使用`menuconfig`进行配置：
``` shell
make menuconfig
```
接下来就是要去修改一系列的设置，按顺序启用以下设置：
``` config
64-bit kernel
General setup > Initial RAM filesystem and RAM disk (initramfs/initrd) support
    然后取消掉下面的各种压缩选项(这步可做可不做)
General setup > Configure standard kernel features (expert users)
General setup > Configure standard kernel features (expert users) > Enable support for printk
Device Drivers > Character devices > Enable TTY
Executable file formats > Kernel support for ELF binaries
```
然后退出再保存。

## 预构建
``` shell
make -j$(nproc) 
```
然后它会提示你内核构建好了放在哪里。

## 测试预构建的内核
``` shell
qemu-system-x86_64 -kernel arch/x86/boot/bzImage
```
如果你能看到因为找不到`init`的~~*内核怕怕*~~`kernel panic`，那么恭喜你，可以进入下一阶段了！


# 初始化内存盘
## 初探`init`
接下来再新建一个文件夹，作为我们的`initrd`开发目录。
我们需要一个`init`进程，但他需要放在初始化内存盘里。于是我们可以写一个十分简单的`shell`程序作为`init`进程:
``` c
// shell.c
#include <unistd.h>
#include <sys/types.h> // pid_t
#include <sys/wait.h>  // siginfo_t P_ALL WEXITED

int main()
{
    char command[255];
    for (;;)
    {
        write(1, "# ", 2);
        int count = read(0, command, 255);
        command[count - 1] = 0; // 替换掉command结尾的\n变成\0
        pid_t fork_result = fork();
        if (fork_result == 0)
        {
            execve(command, 0, 0);
            break;
        }
        else
        {
            siginfo_t info;
            waitid(P_ALL, 0, &info, WEXITED); // 等待所有进程都退出了再进入下一次shell
        }
    }
    _exit(0);
}
```
然后编译它：
``` shell
gcc shell.c -o shell
```
在本地直接运行它进行测试，注意所有命令都要打绝对路径：
``` shell
┌─[admin@dell] - [~/LinuxDistroExp/initrd] - [Tue Mar 25, 11:45]
└─[$] <> ./shell
# /bin/ls
shell  shell.c
# /bin/neofetch
                   -`
                  .o+`
                 `ooo/                   admin@dell 
                `+oooo:                  ---------- 
               `+oooooo:                 OS: Arch Linux x86_64 
               -+oooooo+:                Host: G5 5500 
             `/:-:++oooo+:               Kernel: 6.13.7-arch1-1 
            `/++++/+++++++:              Uptime: 1 hour, 32 mins 
           `/++++++++++++++:             Packages: 1086 (pacman) 
          `/+++ooooooooooooo/`           Shell: zsh 5.9 
         ./ooosssso++osssssso+`          Resolution: 1920x1080 
        .oossssso-````/ossssss+`         Terminal: code 
       -osssssso.      :ssssssso.        CPU: Intel i5-10300H (8) @ 4.500GHz 
      :osssssss/        osssso+++.       GPU: NVIDIA GeForce GTX 1650 Ti Mobile 
     /ossssssss/        +ssssooo/-       GPU: Intel CometLake-H GT2 [UHD Graphics] 
   `/ossssso+/:-        -:/+osssso+-     Memory: 4891MiB / 31888MiB 
  `+sso+:-`                 `.-/+oso:
 `++:.                           `-/+/                           
 .`                                 `/                           



# ^C
┌─[admin@dell] - [~/LinuxDistroExp/initrd] - [Tue Mar 25, 11:45]
└─[$] <>
```
但问题是，这个shell是动态链接的：
``` shell
┌─[admin@dell] - [~/LinuxDistroExp/initrd] - [Tue Mar 25, 11:45]
└─[$] <> gcc shell.c -o shell
┌─[admin@dell] - [~/LinuxDistroExp/initrd] - [Tue Mar 25, 11:45]
└─[$] <> ldd ./shell                                                  
        linux-vdso.so.1 (0x000076bb9ceb1000)
        libc.so.6 => /usr/lib/libc.so.6 (0x000076bb9cc8b000)
        /lib64/ld-linux-x86-64.so.2 => /usr/lib64/ld-linux-x86-64.so.2 (0x000076bb9ceb3000)
```
这好吗？这不好，因为我们的实验不要包含`GNU`动态链接库。所以我们要静态链接的版本：
``` shell
gcc -static shell.c -o shell
```
这样得到的文件就是静态链接的了:
``` shell
┌─[admin@dell] - [~/LinuxDistroExp/initrd] - [Tue Mar 25, 11:45]
└─[$] <> gcc -static shell.c -o shell
┌─[admin@dell] - [~/LinuxDistroExp/initrd] - [Tue Mar 25, 11:45]
└─[$] <> ldd shell 
        not a dynamic executable
```
但是，这个文件很大啊！780KB，蚊子的腿也是肉啊！~~*你的很大，我忍不了一下*~~
``` shell
┌─[admin@dell] - [~/LinuxDistroExp/userspace] - [Tue Mar 25, 11:45]
└─[$] <> ls -alh shell
-rwxr-xr-x 1 enoch enoch 780K Mar 25 15:09 shell
```
所以，我们要把负责系统调用的函数去自己重新实现一遍。


## 重写系统调用的`wrapper`
在重写`wrapper`之前，我们要注意一个问题，聚焦到这个函数上：
``` c
int waitid(idtype_t idtype, id_t id, siginfo_t *infop, int options);
```
通过`man 2 waitid`查看手册，会发现函数原型下面出现了这么么一段注释：
``` c
SYNOPSIS
       #include <sys/wait.h>

       pid_t wait(int *_Nullable wstatus);
       pid_t waitpid(pid_t pid, int *_Nullable wstatus, int options);

       int waitid(idtype_t idtype, id_t id, siginfo_t *infop, int options);
                       /* This is the glibc and POSIX interface; see
                          VERSIONS for information on the raw system call. */

		/* == 中间省略114514行 == */

VERSIONS
   C library/kernel differences
       wait() is actually a library function that (in glibc) is implemented as a call to wait4(2).

       On  some architectures, there is no waitpid() system call; instead, this interface is implemented via a C library wrap‐
       per function that calls wait4(2).

	/* == 重点注意下面这段话！ == */
       The raw waitid() system call takes a fifth argument, of type struct rusage *.  If this argument is non-NULL, then it is
       used to return resource usage information about the child, in the same manner as wait4(2).  See  getrusage(2)  for  de‐
       tails.
```
所以为了防止重复，我们得把这个函数重命名一下。不过好在这是个负责系统调用的中间函数~~*wrapper*~~，重命名一下也不要紧的。我这里就给他重命名为`cool_waitid`了。
因此，为了能过编译，我们得在c语言程序顶上添加这个五参数的函数原型，并在后续使用它。
``` c
int cool_waitid(idtype_t idtype, id_t id, siginfo_t *infop, int options, void *){};
```

这是完整的c语言程序：
``` c
// shell.c
#include <unistd.h>
#include <sys/types.h> // pid_t
#include <sys/wait.h>  // siginfo_t P_ALL WEXITED

// 自定义 waitid 系统调用封装函数（实现在 sys.S 汇编文件中）
// 参数说明：
// idtype - 指定等待的进程类型（如 P_ALL 表示所有子进程）
// id     - 特定进程ID（当 idtype 为 P_PID 时有效）
// infop  - 用于返回子进程状态信息的结构体指针
// options - 控制等待行为的选项（如 WEXITED 表示等待已终止的进程）
int cool_waitid(idtype_t idtype, id_t id, siginfo_t *infop, int options, void *){};

int main()
{
    char command[255];
    for (;;)
    {
        write(1, "# ", tipLen); // 显示命令行提示符
        int count = read(0, command, 255); // 读取用户输入（最多 255 字节）
        command[count - 1] = 0; // 替换掉command结尾的\n变成\0
        pid_t fork_result = fork(); // 开一个子进程执行命令
        if (fork_result == 0) // 当前进程是子进程
        {
            execve(command, 0, 0); // 使用系统调用来执行命令
            break; // 执行完成后子进程退出循环体然后退出执行
        }
        else // 当前进程是父进程
        {
            siginfo_t info;
            cool_waitid(P_ALL, 0, &info, WEXITED, 0); // 等待所有进程都退出了再进行下一次shell
        }
    }
    _exit(0); // 给子进程退出主循环体后退出运行用
}
```
> 注意：这里如果使用前面的静态编译命令，会导致最终二进制运行报`Segment fault`。
> 使用这个编译参数：`gcc -c shell.c -fno-stack-protector`

回到之前的问题，这些系统调用的具体实现怎么办？
~~*很简单*~~，直接上手搓汇编就行。
> Tip: 如果你使用的是`GNU assembler`，那么注释的语法不是分号而是井号。
> 我这里使用`Intel`格式的汇编。

``` asm
# sys.S
.intel_syntax noprefix

.global write
.global read
.global execve
.global fork
.global cool_waitid
.global _exit

# rax寄存器中存放的是系统调用编号，打开你的内核源码，参考: 
# linux/arch/x86/include/generated/asm/syscalls_64.h

# ssize_t write(int fd, const void *buf, size_t count);
write:
mov rax, 1   # 系统调用号 1 (SYS_write)
syscall
ret

# 后面依葫芦画瓢

# ssize_t read(int fd, void *buf, size_t count);
read:
mov rax, 0   # 系统调用号 0 (SYS_read)
syscall
ret

# int execve(const char *filename, char *const argv[], char *const envp[]);
execve:
mov rax, 59  # 系统调用号 59 (SYS_execve)
syscall
ret

# pid_t fork(void);
fork:
mov rax, 57  # 系统调用号 57 (SYS_fork)
syscall
ret

# int cool_waitid(idtype_t idtype, id_t id, siginfo_t *infop, int options, void *);
cool_waitid:
mov rax, 247 # 系统调用号 247 (SYS_waitid)
mov r10, rcx # 英特尔把rcx寄存器给硬件级的系统调用的返回值了，这会导致冲突，所以Linux在
			# 内核中的是使用r10寄存器而非rcx,但调用时是传递进rcx,所以我们要把值送给r10
			# 具体使用的寄存器： rdi, rsi, rdx, r10, r8, r9
            # 参考https://en.wikipedia.org/wiki/X86_calling_conventions#cite_ref-AMD_28-9
syscall
ret

# 这个系统调用是不需要返回的，可以通过上面那个头文件里看到: __SYSCALL_NORETURN(60, sys_exit)
# void _exit(int status);
_exit:
mov rax, 60  # 系统调用号 60 (SYS_exit)
syscall
```

> 你如果把上述代码丢给AI，它确实可能会发现一些不严谨的问题，比如越界错误等，但本实验只是为了好玩，就不考虑那些了。

接下来编译这个汇编程序：
``` shell
as sys.S
```

最后，我们只需要将这两个程序链接起来就行了：
``` shell
ld -o shell shell.o a.out --entry main -z noexecstack
```
发现，它十分的小！
``` shell
┌─[admin@dell] - [~/LinuxDistroExp/userspace/initrd] - [Tue Mar 25, 11:45]
└─[$] <> ls -alh shell                                               
-rwxr-xr-x 1 enoch enoch 9.7K Mar 25 12:53 init
```
把它改名`init`然后备用。

## 创建`cpio`
这一步很简单，直接使用命令就行了：
``` shell
echo init | cpio -H newc -o > init.cpio
```
好的，现在万事俱备，只欠`qemu`！
``` shell
qemu-system-x86_64 -kernel arch/x86/boot/bzImage -initrd ../userspace/initrd/init.cpio
```
然后在qemu的窗口里你可以看到成功进入了shell，你敲键盘它会有反应，但现在没有任何程序可供执行，~~*所以它只会换行*~~。

# 测试最终系统！And ... tricks!
Linux内核编译的时候其实是支持编译成镜像的，进入`~/LinuxDistroExp/linux`并通过`make help`进行查看：
``` config
Architecture-specific targets (x86):
* bzImage               - Compressed kernel image (arch/x86/boot/bzImage)
  install               - Install kernel using (your) ~/bin/installkernel or
                          (distribution) /sbin/installkernel or install to 
                          $(INSTALL_PATH) and run lilo

  fdimage               - Create 1.4MB boot floppy image (arch/x86/boot/fdimage)
  fdimage144            - Create 1.4MB boot floppy image (arch/x86/boot/fdimage)
  fdimage288            - Create 2.8MB boot floppy image (arch/x86/boot/fdimage)
  hdimage               - Create a BIOS/EFI hard disk image (arch/x86/boot/hdimage)
  isoimage              - Create a boot CD-ROM image (arch/x86/boot/image.iso)
                          bzdisk/fdimage*/hdimage/isoimage also accept:
                          FDARGS="..."  arguments for the booted kernel
                          FDINITRD=file initrd for the booted kernel
```
对就是最后一个。所以我们只要这么修改编译指令就行，它会自动使用以前的编译缓存。
``` shell
make isoimage FDARGS="initrd=/init.cpio" FDINITRD="/path/to/your/init.cpio"
```
然后生成的镜像就会保存在`arch/x86/boot/image.iso`，我们可以直接喂给`qemu`：
``` shell
qemu-system-x86_64 -cdrom arch/x86/boot/image.iso
```
在弹出的窗口里，我们可以看到和之前一样，~~*只会换行*~~。


# 为系统集成Lua运行时
我们去`Lua`官网下载并解压其源代码：
``` shell
┌─[admin@dell] - [~/LinuxDistroExp/3rdsw/lua-5.4.7/src] - [Tue Mar 25, 11:45]
└─[$] <> ls
lapi.c      lcode.h     ldebug.c  lfunc.h   liolib.o    lmem.h      lopcodes.o  lstate.h   ltable.o   luaconf.h   lutf8lib.o
lapi.h      lcode.o     ldebug.h  lfunc.o   ljumptab.h  lmem.o      lopnames.h  lstate.o   ltablib.c  lua.h       lvm.c
lapi.o      lcorolib.c  ldebug.o  lgc.c     llex.c      loadlib.c   loslib.c    lstring.c  ltablib.o  lua.hpp     lvm.h
lauxlib.c   lcorolib.o  ldo.c     lgc.h     llex.h      loadlib.o   loslib.o    lstring.h  ltm.c      lualib.h    lvm.o
lauxlib.h   lctype.c    ldo.h     lgc.o     llex.o      lobject.c   lparser.c   lstring.o  ltm.h      lua.o       lzio.c
lauxlib.o   lctype.h    ldo.o     liblua.a  llimits.h   lobject.h   lparser.h   lstrlib.c  ltm.o      lundump.c   lzio.h
lbaselib.c  lctype.o    ldump.c   linit.c   lmathlib.c  lobject.o   lparser.o   lstrlib.o  lua.c      lundump.h   lzio.o
lbaselib.o  ldblib.c    ldump.o   linit.o   lmathlib.o  lopcodes.c  lprefix.h   ltable.c   luac.c     lundump.o   Makefile
lcode.c     ldblib.o    lfunc.c   liolib.c  lmem.c      lopcodes.h  lstate.c    ltable.h   luac.o     lutf8lib.c
```
在其`Makefile`里，添加静态编译的flag，为了方便，可以和我一样直接使用命令修改：
``` shell
sed -i 's/MYLDFLAGS=/MYLDFLAGS=-static/g' Makefile
```
然后就直接编译就行了：
``` shell
 make
```
完成后我们可以看到，它是静态编译的：
``` shell
┌─[admin@dell] - [~/LinuxDistroExp/3rdsw/lua-5.4.7/src] - [Tue Mar 25, 11:45]
└─[$] <> ldd lua     
        not a dynamic executable
```
接下来，我们只要把`lua`这个二进制文件一起放到`init.cpio`里就行了，先把它放到和`init`在同一个目录下，然后：
``` shell
echo init >> files
echo lua >> files
cat files | cpio -H newc -o > init.cpio
```
当然如果你和我一样专门建了一个文件夹存放initrd里的文件，可以直接使用下面的脚本：
``` shell
rm init.cpio
find . | cpio -H newc -o > init.cpio
```
然后和上面一样，直接编译进单文件镜像或者修改启动参数都行。

***Well done!***
