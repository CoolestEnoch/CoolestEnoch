---
title: Waydroid的碎碎念
category: Linux
date: 2023-07-30 18:00:00
index_img: https://www.gitbook.com/cdn-cgi/image/width=256,dpr=2,height=40,fit=contain,format=auto/https%3A%2F%2F2140589054-files.gitbook.io%2F~%2Ffiles%2Fv0%2Fb%2Fgitbook-legacy-files%2Fo%2Fspaces%252F-MiYFr8anWJnZu5dVlhr%252Favatar-rectangle-1630538785250.png%3Fgeneration%3D1630538786012033%26alt%3Dmedia
---

![封面](https://www.gitbook.com/cdn-cgi/image/width=256,dpr=2,height=40,fit=contain,format=auto/https%3A%2F%2F2140589054-files.gitbook.io%2F~%2Ffiles%2Fv0%2Fb%2Fgitbook-legacy-files%2Fo%2Fspaces%252F-MiYFr8anWJnZu5dVlhr%252Favatar-rectangle-1630538785250.png%3Fgeneration%3D1630538786012033%26alt%3Dmedia)
~~安卓系统，已经融入了我们的生活，那怎么在电脑上运行安卓系统呢，小编~~
*~~(好了请停止你的营销号模式~~*

当然这是基于我的arch linux系统进行操作2333
至于为什么不配置Nvidia显卡相关设置，问就是Fa♂️Q Nvidia（逃
平时基本都是把n卡屏蔽了，省心hhh

# 将显示管理器从X11迁移到Wayland上
从X11迁到wayland上，当然不会山删掉x11,这样在sddm登陆的地方可以选择用wayland来开桌面
``` shell
pacman -S plasma-wayland-session plasma-wayland-protocols qt5-wayland qt6-wayland xorg-xwayland
```

后面就是引用[Ivon大佬的一些操作了](https://ivonblog.com/posts/archlinux-waydroid)




# 迁移内核
**迁移到linux-zen内核**
``` shell
sudo pacman -S linux-zen linux-zen-headers
```
**安装binder_linux并且加载到内核**
``` bash
paru -S binder_linux-dkms
sudo modprobe binder_linux # 现在不需要这样手动启动模块了
```



# 安装Waydroid
**装依赖**
***如果你执意不配置venv的话，先执行这段指令再继续，不然pip会报错:***`sudo mv /usr/lib/python3.x/EXTERNALLY-MANAGED /usr/lib/python3.x/EXTERNALLY-MANAGED.bk`
``` bash
paru -S python-gbinder python-pyclip dbus-python xclip wl-clipboard mailcap python-pgi
pip install PyGObject dbus-python
```
建议先开一个新的venv然后在其中操作完成后，再将该venv的site-packages整个丢到`/usr/lib/python3.xx/site-packages/`下，然后再恢复source你自己的venv。
如果后续系统更新的时候出现`python-gobject`和`python-cairo`说`file already exist`问题，强制覆盖安装一下以下的包然后就可以正常系统更新了：
``` shell
sudo pacman -S python-gobject python-cairo --overwrite '*'
```

**装Waydroid**
``` bash
paru -S waydroid waydroid-image
```

***记得去`grub`里添加内核启动参数`psi=1`要不然waydroid启动会报错`Command failed: % /usr/lib/waydroid/data/scripts/waydroid-net.sh start`***

**第一次启动的话，得先init一下容器**
不过我是不打算弄带gms的，苏菲性能实在太差(悲
``` bash
sudo waydroid init # for non Gapps
sudo waydroid init -s GAPPS -f # for Gapps
```
当然如果想要重新初始化waydroid~~就比如我之前闲得无聊弄了个安卓13的然后发现没`libhoudini`就想保数据回退~~，就这么做
``` bash
sudo waydroid init -f
```

**开一次机试一下**
``` bash
sudo systemctl start waydroid-container
waydroid show-full-ui
```


**安装libhoudini**
``` bash
git clone --depth=1 https://github.com/casualsnek/waydroid_script
cd waydroid_script
sudo python3 -m pip install -r requirements.txt
cd waydroid_script
sudo python3 main.py
```
然后按照命令行的提示来操作就行

当执行完成后，就可以快乐的玩耍了

# 一些基本常用的操作
**开机**
``` bash
waydroid show-full-ui
```

**关机**
``` bash
sudo waydroid session stop && sudo waydroid container stop && sudo systemctl stop waydroid-container
```

**以root身份进adb**
``` bash
sudo waydroid shell
```

**连接adb网络调试**
这东西会在你的电脑里再nat出一个子网，然后waydroid的ip被静态分配到`192.168.240.112`上
``` bash
adb connect 192.168.240.112
```


# 性能调优
**对应用进行dex2oat优化**
*苏菲太需要dex2oat了要不然卡的很*
如果你在带有root权限的安卓的shell中...
``` bash
# 使用everything模式编译所有应用
cmd package compile -m everything -f -a
# 仅针对星穹铁道使用everything模式编译
cmd package compile -m everything -f com.MobileTicket
```
如果你**不**在安卓的shell中...
``` bash
# 使用everything模式编译所有应用
adb shell cmd package compile -m everything -f -a
# 仅针对星穹铁道使用everything模式编译
adb shell cmd package compile -m everything -f com.MobileTicket
```
**可选编译类型**
`interpret-only`: 不编译，仅靠解释运行应用，效率很低，占用空间最小；
`space`: 仅编译一小部分函数，其余不编译，占用空间较小；
`balanced`: 在占用空间与运行效率上做一平衡；
`speed-profile`: 将配置文件中标明的函数编译一遍，这些函数可能是热点函数，为部分编译，频繁使用的功能运行效率会变高，不常使用的效率便会很低；
`speed`: 将程序中所有函数都编译一遍，效率和占用空间均较高；
`everything`: 译所有代码，效率最高，能耗较低，占用空间最高。
[细节见这篇文章](https://my.oschina.net/ososchina/blog/4818813)


**激活冰箱**
``` bash
adb shell dpm set-device-owner com.catchingnow.icebox/.receiver.DPMReceiver
```


**开启全局小窗模式**
这样你可以跟win11的WSA一样体验安卓程序
``` bash
waydroid prop set persist.waydroid.multi_windows true
```


# 一些sao操作
Waydroid的内部存储是被映射到你的`home`目录下的，具体在这个目录:
> ~/.local/share/waydroid/data/media/0

你发现了啥？对的没错，它甚至很慷慨的把整个`/data`分区给映射出来了，也就是`~/.local/share/waydroid/data`这个目录
不过里面的东西所属的用户组跟你电脑的用户组不是同一个，可以通过`ls -al`进行查看
但是你可以以`root`用户的身份去对它进行一些读写，如果要让waydroid可以正常读写你改过的东西的话，还得记得把文件权限改回去哈
**可以用这个命令将目录下所有文件(夹)的权限全改成安卓默认**
``` bash
sudo chown -R 10138 . && sudo chgrp -R 10138 . && sudo chmod -R 755 ./*
```


# 卸载waydroid
停止容器
``` bash
sudo waydroid session stop && sudo systemctl stop waydroid-container
```
删除容器
``` bash
paru -Rs waydroid
sudo rm -rf /var/lib/waydroid /home/.waydroid ~/waydroid ~/.share/waydroid ~/.local/share/applications/*aydroid* ~/.local/share/waydroid
```
注意，最后`rm`的那个目录会把内部存储给清空，如果要备份数据，记得按上一步提到的去备份资料再删除。