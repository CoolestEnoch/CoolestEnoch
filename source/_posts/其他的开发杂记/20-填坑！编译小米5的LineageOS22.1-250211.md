---
title: 填坑！编译小米5的LineageOS22.1
category: 其他的开发杂记
date: 2025-02-11 18:00:00
index_img: https://c1.mifile.cn/f/i/16/mi5/index/h-12.jpg
---


![封面](https://c1.mifile.cn/f/i/16/mi5/index/h-12.jpg)
(封面图源 [小米商城](https://www.mi.com/mi5))

# 前情提要
在去年1月25号的时候，我尝试给非官方支持的设备编译LineageOS 20,但却以失败告终。这次，重新尝试一台官方支持的设备，且系统为Lineage 22.1。
***⚠️万字长文预警***
> 环境配置部分，同上期文章。


# 硬件和软件环境
我用的是平时拿来干活的笔记本。硬件方面：`i5-10300H`的处理器，`32GB 2933MHz`的主存，开启了`16GB SWAP`~~*智慧运存*~~，编译环境用的硬盘是`Samsung Evo 870 1TB`；软件方面：采用`Debian 12`系统。~~*主要是Ubuntu太臃肿了*~~
> 是的我今年加了一根16GB的内存条，去年编译的时候物理内存和~~*融合内存*~~SWAP都吃满了，今年除了在`ninja`初次启动的时候两个都吃满，平时编译基本上只吃了80%的物理内存。

> ⚠️本次编译的初次编译耗时一天一夜，CPU平均频率为3.5GHz，请合理评估和安排您的编译时间。后续增量编译平均耗时十分钟，主要耗时部分为打包系统镜像写回硬盘。


# 装依赖
## Part 1: 下载和解压
第一个要装的就是`adb`和`fastboot`。
> ⚠️ 注意！不要去`apt`源里下载，那里的版本太老了。前往谷歌官方下载：`https://dl.google.com/android/repository/platform-tools-latest-linux.zip`

按照`Lineage`官方的[说法](https://wiki.lineageos.org/devices/gemini/build/#install-the-platform-tools)，把他解压到`~`下吧：
``` bash
unzip platform-tools-latest-linux.zip -d ~
```
现在你确定一下`~`目录下是否存在`platform-tools`文件夹，如果存在则继续。
打开你的`~/.profile`或者`~/.zshrc`(本文全文将以`.zshrc`进行举例说明)，在`source $ZSH/oh-my-zsh.sh`前添加以下代码：
``` bash
# add Android SDK platform tools to path
if [ -d "$HOME/platform-tools" ] ; then
    export PATH="$HOME/platform-tools:$PATH"
fi
```
然后，`source`它，再`echo $PATH`一下看看环境变量里是否存在`~/platform-tools`，存在就可以进行下一步。


## Part 2: 从apt源安装
使用apt把这些都装进去：`bc bison build-essential ccache curl flex g++-multilib gcc-multilib git git-lfs gnupg gperf imagemagick lib32readline-dev lib32z1-dev libelf-dev liblz4-tool libsdl1.2-dev libssl-dev libxml2 libxml2-utils lzop pngcrush rsync schedtool squashfs-tools xsltproc zip zlib1g-dev`
对于我使用的`Debian 12`系统，再安装这些:`lib32ncurses-dev libncurses5 libncurses5-dev`

对于`Ubuntu`用户，请按照`Lineage`官网说法进行操作：
``` shell
# For Ubuntu 23.10 (mantic), install libncurses5 from 23.04 (lunar) as follows:
wget http://archive.ubuntu.com/ubuntu/pool/universe/n/ncurses/libtinfo5_6.4-2_amd64.deb && sudo dpkg -i libtinfo5_6.4-2_amd64.deb && rm -f libtinfo5_6.4-2_amd64.deb
wget http://archive.ubuntu.com/ubuntu/pool/universe/n/ncurses/libncurses5_6.4-2_amd64.deb && sudo dpkg -i libncurses5_6.4-2_amd64.deb && rm -f libncurses5_6.4-2_amd64.deb

# While for Ubuntu versions older than 23.10 (mantic), simply install:
lib32ncurses5-dev libncurses5 libncurses5-dev

# Additionally, for Ubuntu versions older than 20.04 (focal), install also:
libwxgtk3.0-dev

# While for Ubuntu versions older than 16.04 (xenial), install:
libwxgtk2.8-dev
```


## Part 3: OpenJDK的安装
`OpenJDK`的版本取决于你想要编译的`Lineage OS`版本。根据官方的提示，我们需要安装Java 11。
下面的信息来自于上面提到的`Lineage`官网教程。
`LineageOS` 18.1及更高版本: `openjdk-11 openjdk-11-source`
`LineageOS` 16.0-17.1: `openjdk-9 openjdk-9-source`
`LineageOS` 14.1-15.1: `openjdk-8-jdk`
> ⚠️注意: 构建这些版本时你需要在`/etc/java-8-openjdk/security/java.security`中从`jdk.tls.disabledAlgorithms`中移除`TLSv1`和`TLSv1.1`相关的东西。

`LineageOS` 11.0-13.0: `openjdk-7-jdk`

> ~~`Ubuntu 16.04`及更新版本的软件源中已将`OpenJDK 1.7`移除了。解决方案参考`Ask Ubuntu`上的问题[“How do I install openjdk 7 on Ubuntu 16.04 or higher?”](http://askubuntu.com/questions/761127/how-do-i-install-openjdk-7-on-ubuntu-16-04-or-higher)。注意热评里那个叫你添加`ppa`源的老登，因为`ppa`源缺乏安全性维护，所以别看他的回答，看后面一个叫你去Debian官网下载的回答。~~
> ~~笔者评：截止写稿时，`Debian 12`源上的`openjdk`只有`17`版本了。所以只能去网站上下载`.deb`包然后安装。这里提供两个下载站：[OpenJDK Archive\(无需登陆但没有deb\)](https://jdk.java.net/archive/)；[Java SE Archive\(概率登陆但有deb\)](https://www.oracle.com/java/technologies/downloads/archive/)。~~


> 但是！我们是不是可以整点活？比如直接去隔壁`Ubuntu`的镜像源网站上下载？比如清华源：
> Ubuntu系统前往这里下载：[下载jdk11-universe](https://mirrors.tuna.tsinghua.edu.cn/ubuntu/pool/universe/o/openjdk-lts/)[下载jdk11-main](https://mirrors.tuna.tsinghua.edu.cn/ubuntu/pool/main/o/openjdk-lts/)；[下载jdk9-universe](https://mirrors.tuna.tsinghua.edu.cn/ubuntu/pool/universe/o/openjdk-9/)；[下载jdk8-universe](https://mirrors.tuna.tsinghua.edu.cn/ubuntu/pool/universe/o/openjdk-8/)[下载jdk8-main](https://mirrors.tuna.tsinghua.edu.cn/ubuntu/pool/main/o/openjdk-8/)；[下载jdk7-main](https://mirrors.tuna.tsinghua.edu.cn/ubuntu/pool/main/o/openjdk-7/)
> Debian系统前往这里下载：[下载jdk11-main](https://mirrors.tuna.tsinghua.edu.cn/debian/pool/main/o/openjdk-11/)[下载jdk8-main](https://mirrors.tuna.tsinghua.edu.cn/debian/pool/main/o/openjdk-8/)
> 使用此方法时如提示缺失依赖则需要补全依赖然后再安装，否则`apt`会报错：`ca-certificates-java java-common libc6`
> 需要把`openjdk-xx-jdk`及其`headless`版本、`openjdk-xx-jre`及其`headless`版本和`openjdk-xx-source`都安装上再继续。


## Part 4: Python的安装
~~*啥？这都什么年代了还教咋装Python？*~~要不是因为不同`Lineage`版本要求的Python版本不一样，~~我也懒得写了~~
`LineageOS` 17.1及更高版本: `python3`
`LineageOS` 11.0-16.0: `python2`
如果你电脑上有多个~~蟒蛇~~`Python`互相冲突，`Lineage`官网推荐的解决方案是用`venv`。相关的东西这里不再赘述。

> ⚠️ 值得一提的是现在Debian源里python的包名改了，如果你要装Python3则需要安装`python-is-python3`，如果是Python2的话需要安装`python-is-python2`。


# 进入准备工作！

## 建立工作目录
> ⚠️ Lineage和清华源上的教程写的不一样，这里冲突部分采用的是Lineage官网教程。

```bash
mkdir -p ~/bin
mkdir -p ~/android/lineage
```
其中`~/bin`存放`git-repo`工具，`~/android/lineage`存放`LineageOS`的源码。


## 安装repo工具
> 这是个啥？
> `repo`是个由Google开发的`git`的增强工具，和`git`配合食用。[参考Google官方文档。](https://source.android.google.cn/docs/setup/download)

``` bash
mkdir ~/bin
PATH=~/bin:$PATH
curl https://mirrors.tuna.tsinghua.edu.cn/git/git-repo > ~/bin/repo
chmod a+x ~/bin/repo
```
更新repo使用这个命令：`export REPO_URL='https://mirrors.tuna.tsinghua.edu.cn/git/git-repo'`
然后再使用上面添加`adb`的方法将`~/bin`目录添加到环境变量中，编辑`.zshrc`...:
``` bash
# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/bin" ] ; then
    PATH="$HOME/bin:$PATH"
fi
```
别忘了再次`source`它一下！


## 配置Git
没啥好说的，设置一下用户名和邮箱，这步没做的话下一步初始化仓库的时候命令行里也会叫你提供这两个信息。
> ⚠️ 注意: 这里的操作是对整个电脑全局的设置。如果你只想在编译系统的源码仓库文件夹内设置这两个信息，则请跳过设置信息这一步，直接进行`lfs`初始化。

``` bash
git config --global user.email "you@example.com"
git config --global user.name "Your Name"
```

为了能让`git`存放大文件，需要初始化一下`Large File Storage`：
``` bash
git lfs install
```

设置`Git`的`Change-Id`：`Lineage`官方说为了防止重复的`Change-Id`,就要这么操作一下。但是我没有进行这一步设置。
> To avoid duplicated Change-Id: trailers in commit messages, especially when cherry-picking changes, make Change-Id: a known trailer to git:

``` bash
git config --global trailer.changeid.key "Change-Id"
```


## 配置编译缓存
这是用`ccache`来加快编译的。将这些内容放入`.zshrc`中然后再`source`一下：
``` bash
export USE_CCACHE=1
export CCACHE_EXEC=/usr/bin/ccache
```
然后回到命令行终端，设置`ccache`大小:
``` bash
ccache -M 50G
```
`ccache`大小影响你的编译速度。如果只编译一个设备，那么给`20-50GB`就够了；如果编译多个设备(不共享内核源码)，则建议配置`75-100GB`。
当然，你也可以启用压缩：
``` bash
ccache -o compression=true
````
> 启用压缩后，一台设备大概给`20G`就够了。



# 初始化LineagOS仓库并换源
> ⚠️先进入`~/android/lineage`目录，再初始化仓库。
``` shell
repo init -u https://mirrors.tuna.tsinghua.edu.cn/git/lineageOS/LineageOS/android.git -b lineage-22.1 --git-lfs --no-clone-bundle
```
确保网络通畅，待同步完成后，打开`~/android/lineage/.repo/manifests/default.xml`，做如下修改：
将
``` xml
  <remote  name="github"
           fetch=".."
           review="review.lineageos.org" />
```
改成
``` xml
  <remote  name="github"
           fetch="https://github.com/" />

  <remote  name="lineage"
           fetch="https://mirrors.tuna.tsinghua.edu.cn/git/lineageOS/"
           review="review.lineageos.org" />
```
将
``` xml
  <remote  name="aosp"
           fetch="https://android.googlesource.com"
           xxx="..."/>
```
改成
``` xml
  <remote  name="aosp"
           fetch="https://mirrors.tuna.tsinghua.edu.cn/git/AOSP"
           xxx="..."/>
```
将
``` xml
  <default revision="..."
           remote="github"
           xxx="..."/>
```
改成
``` xml
  <default revision="..."
           remote="lineage"
           xxx="..."/>
```


随后，同步源码树：
``` shell
repo sync
```
在我家这边，同步源码树的平均网速为10MB/s，整个过程大约耗时一小时左右。


## 准备设备专属代码
### 需要下载的内容
进入`~/android/lineage`目录，执行以下代码：
``` shell
souce build/envsetup.sh
breakfest gemini
```
> ⚠️此处需要保证网络通畅，能正常连接到GitHub，否则会同步失败。

### 不需要下载的内容
掏出你的小米5，插上数据线，给`shell`进程赋予root权限，再打开开发者选项中的`使用Root身份进行ADB调试`。
进入`~/android/lineage/device/xiaomi/gemini`再运行：
``` shell
./extract-files.sh
```
等待其文件提取完成，这一步提取的是闭源驱动，比如摄像头驱动.so。


# 开始构建！
可以通过`croot`命令回到`~/android/lineage`，或手动回去都行。然后运行：
``` shell
brunch gemimi
```
就可以开始构建系统了。当构建完成后，系统包会存放在`out/target/product/gemini/lineage-22.1-YYYYMMDD-UNOFFICIAL-gemini.zip`，使用`out/target/product/gemini/recovery.img`将其通过`adb sideload`刷入。

好了，享受自编译的系统吧！


# 一些可能要用到的细节信息
内核编译使用的`defconfig`是`kernel/xiaomi/msm8996/arch/arm64/configs/vendor/xiaomi/mi8996_defconfig`，和`kernel/xiaomi/msm8996/arch/arm64/configs/vendor/xiaomi/gemini.config`。
相关配置文件可参考`device/xiaomi/msm8996-common/BoardConfigCommon.mk`。
LineageOS的关于页面的彩蛋源码位于`packages/apps/LineageParts/src/org/lineageos/lineageparts/logo/PlatLogoActivity.java`， 我们可以根据需求进行定制。


# 番外：不受支持的`Lindroid`
开源项目地址是[这个](https://github.com/Linux-on-droid/)，主要依据[vendor_lindroid仓库的readme](https://github.com/Linux-on-droid/vendor_lindroid/tree/lindroid-22.1)进行操作。
**1. 向内核的defconfig（此处是`kernel/xiaomi/msm8996/arch/arm64/configs/vendor/xiaomi/gemini.config`）添加以下内容:**
``` config
CONFIG_SYSVIPC=y
CONFIG_UTS_NS=y
CONFIG_PID_NS=y
CONFIG_IPC_NS=y
CONFIG_USER_NS=y
CONFIG_NET_NS=y
CONFIG_CGROUP_DEVICE=y
CONFIG_KERNEL_CGROUP_FREEZER=y
```

**2. 将以下仓库clone到源码树:**
``` shell
git clone --depth=1 https://github.com/example/vendor_lindroid vendor/lindroid
git clone --depth=1 https://github.com/example/external_lxc external/lxc
git clone --depth=1 https://github.com/example/libhybris external/libhybris
```

**3. 修改设备配置信息:**
向`device/xiaomi/gemini/device.mk`添加一行：
``` shell
$(call inherit-product, vendor/lindroid/lindroid.mk)
```

**4. 将SELinux设置为Permissive:**
打开`device/xiaomi/msm8996-common/BoardConfigCommon.mk`，在`Kernel`部分的添加一行启动参数：
``` makefile
BOARD_KERNEL_CMDLINE += androidboot.selinux=permissive
```
> ⚠️注意：关闭SELinux会令设备处于安全风险之中，请自行处理好该设备上的信息安全。

**5. 修改Lineage源码以修复一些作者提到的问题**
应用这个[Patch](https://gerrit.libremobileos.com/c/LMODroid/platform_frameworks_native/+/12936)，或手动修改：
打开`frameworks/native/services/inputflinger/reader/EventHub.cpp`：
将
``` c
    ALOGV("  name:       \"%s\"\n", identifier.name.c_str());
    ALOGV("  location:   \"%s\"\n", identifier.location.c_str());
    ALOGV("  unique id:  \"%s\"\n", identifier.uniqueId.c_str());
    ALOGV("  descriptor: \"%s\"\n", identifier.descriptor.c_str());
    ALOGV("  driver:     v%d.%d.%d\n", driverVersion >> 16, (driverVersion >> 8) & 0xff,
          driverVersion & 0xff);

    // Load the configuration file for the device.
    device->loadConfigurationLocked();

    // Figure out the kinds of events the device reports.
    device->readDeviceBitMask(EVIOCGBIT(EV_KEY, 0), device->keyBitmask);
    device->readDeviceBitMask(EVIOCGBIT(EV_ABS, 0), device->absBitmask);
    device->readDeviceBitMask(EVIOCGBIT(EV_REL, 0), device->relBitmask);
    device->readDeviceBitMask(EVIOCGBIT(EV_SW, 0), device->swBitmask);
    device->readDeviceBitMask(EVIOCGBIT(EV_LED, 0), device->ledBitmask);
    device->readDeviceBitMask(EVIOCGBIT(EV_FF, 0), device->ffBitmask);
    device->readDeviceBitMask(EVIOCGBIT(EV_MSC, 0), device->mscBitmask);
    device->readDeviceBitMask(EVIOCGPROP(0), device->propBitmask);
```
修改为：
``` c
    ALOGV("  name:       \"%s\"\n", identifier.name.c_str());
    ALOGV("  location:   \"%s\"\n", identifier.location.c_str());
    ALOGV("  unique id:  \"%s\"\n", identifier.uniqueId.c_str());
    ALOGV("  descriptor: \"%s\"\n", identifier.descriptor.c_str());
    ALOGV("  driver:     v%d.%d.%d\n", driverVersion >> 16, (driverVersion >> 8) & 0xff,
          driverVersion & 0xff);

    // Load the configuration file for the device.
    device->loadConfigurationLocked();

    // Disable device if device config property set
    if (device->configuration &&
        device->configuration->getBool("device.disabled")) {
        device->disable();
        ALOGV("Disabling device with id %d\n", device->id);
    }

    // Figure out the kinds of events the device reports.
    device->readDeviceBitMask(EVIOCGBIT(EV_KEY, 0), device->keyBitmask);
    device->readDeviceBitMask(EVIOCGBIT(EV_ABS, 0), device->absBitmask);
    device->readDeviceBitMask(EVIOCGBIT(EV_REL, 0), device->relBitmask);
    device->readDeviceBitMask(EVIOCGBIT(EV_SW, 0), device->swBitmask);
    device->readDeviceBitMask(EVIOCGBIT(EV_LED, 0), device->ledBitmask);
    device->readDeviceBitMask(EVIOCGBIT(EV_FF, 0), device->ffBitmask);
    device->readDeviceBitMask(EVIOCGBIT(EV_MSC, 0), device->mscBitmask);
    device->readDeviceBitMask(EVIOCGPROP(0), device->propBitmask);
```
其中修改的部分是：新增了这一段代码：
``` c
    // Disable device if device config property set
    if (device->configuration &&
        device->configuration->getBool("device.disabled")) {
        device->disable();
        ALOGV("Disabling device with id %d\n", device->id);
    }
```


**接下来，就是重新增量编译系统！**
如果你遇到了`CONFIG_SYSVIPC`和`FCM`相关的报错：
``` text
For kernel requirements at matrix level 5, Kernel config errors:
    For config CONFIG_SYSVIPC, value = y but required n
: Success
```
那就去`kernel/configs/*/*/android-base.config`里删掉`# CONFIG_SYSVIPC is not set`。是的没错，是`kernel/configs`下每个子文件夹里的所有子文件夹里的`android-base.config`再重新编译。


如果在开机后遇到了`overlayfs`无法挂载的错误，应用这个[补丁](https://github.com/android-kxxt/android_kernel_xiaomi_sm8450/commit/ae700d3d04a2cd8b34e1dae434b0fdc9cde535c7)，或手动修改：
打开`fs/overlayfs/util.c`：
找到这段代码，将这段代码：
``` c
bool ovl_dentry_weird(struct dentry *dentry)
{
	return dentry->d_flags & (DCACHE_NEED_AUTOMOUNT |
				  DCACHE_MANAGE_TRANSIT |
				  DCACHE_OP_HASH |
				  DCACHE_OP_COMPARE);
				  DCACHE_MANAGE_TRANSIT);
}

enum ovl_path_type ovl_path_type(struct dentry *dentry)
```
修改为：
``` c
bool ovl_dentry_weird(struct dentry *dentry)
{
	return dentry->d_flags & (DCACHE_NEED_AUTOMOUNT |
				  DCACHE_MANAGE_TRANSIT);
}

enum ovl_path_type ovl_path_type(struct dentry *dentry)
```
但是很可惜，我的小米5遇到了这段`overlayfs`的报错：
``` text
02-10 21:18:16.334  3495  3494 I perspectived_lxc: test: overlay - external/lxc/src/lxc/storage/overlay.c:ovl_mount:483 - Invalid argument - Failed to mount "/data/lindroid/lxc/rootfs_ro" on "/data/lindroid/lxc/rootfs" with options "upperdir=/data/lindroid/lxc/container/test/rootfs,lowerdir=/data/lindroid/lxc/rootfs_ro,workdir=/data/lindroid/lxc/container/test/work". Retrying without workdir
02-10 21:18:16.334     0     0 E overlayfs: filesystem on '/data/lindroid/lxc/container/test/rootfs' not supported as upperdir
02-10 21:18:16.336  3495  3494 E perspectived_lxc: test: overlay - external/lxc/src/lxc/storage/overlay.c:ovl_mount:491 - Invalid argument - Failed to mount "/data/lindroid/lxc/rootfs_ro" on "/data/lindroid/lxc/rootfs" with options "upperdir=/data/lindroid/lxc/container/test/rootfs,lowerdir=/data/lindroid/lxc/rootfs_ro"
02-10 21:18:16.336  3495  3494 E perspectived_lxc: test: conf - external/lxc/src/lxc/conf.c:lxc_mount_rootfs:1238 - Failed to mount rootfs "/data/lindroid/lxc/rootfs_ro:/data/lindroid/lxc/container/test/rootfs" onto "/data/lindroid/lxc/rootfs" with options "(null)"
```
但我的内核里并不存在`util.c`。Lindroid作者的回复是，4.4内核太老了，就算修了这个问题，后面会遇到的问题也会很多。
~~*后面的路，以后再来探索吧！*~~
