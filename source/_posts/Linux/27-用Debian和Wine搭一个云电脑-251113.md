---
title: 用Debian和Wine搭一个云电脑
category: Linux
date: 2025-11-13 00:00:00
updated: 2025-11-13 00:00:00
index_img: https://dl.winehq.org/share/images/winehq_logo_glass.png
---


# TL;DR
一时兴起，想搭个云游戏平台。尝试了`solarkennedy/wine-x11-novnc-docker`等几个，要么是都没达到我的要求，有的停更好几年了。


于是想构建一个纯净的，带最新wine的。于是计划用Debian sid，因为这东西更新起来很像Arch，是滚动的，软件也是最新的，很适合。

> ⚠️注意
> 该教程搭建的没有硬件加速，因为宿主机是云服务器厂商的虚拟机vps，没有显卡。


# 搭建基础环境
> ⚠️注意
> 接下来默认你在root中执行，因为需要操作docker命令。


拉取debian-sid镜像：
``` shell
docker pull debian:sid
```


假设你给wine容器的/root目录要映射到宿主机的`/your/host/path/to/wine_novnc/root`，这里存着你要运行的exe文件，并要在宿主机的`5999`端口监听一个novnc的网页端口，运行这段创建的命令：
``` shell
docker run -d --name wine_novnc -p 5999:5901 -v /your/host/path/to/wine_novnc/root:/root -v /etc/localtime:/etc/localtime -dit debian:sid
```


随后进入容器：
``` shell
# 手动重启docker后需先启动容器才能进入
docker start wine_novnc
# 进入
docker exec -it wine_novnc /bin/bash
```

接下来在容器里，先换源：
``` shell
tee /etc/apt/sources.list.d/debian.sources > /dev/null << 'EOF'
Types: deb
URIs: https://mirrors.tuna.tsinghua.edu.cn/debian
Suites: sid
Components: main contrib non-free non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg

# 默认取消注释了源码镜像，如有需要可自行注释
Types: deb-src
URIs: https://mirrors.tuna.tsinghua.edu.cn/debian
Suites: sid
Components: main contrib non-free non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg
EOF
```


安装~~*虎哥*~~VNC Server：
``` shell
apt install tigervnc-standalone-server tigervnc-common tightvncserver
```


首次启动vnc服务需要设置一个密码：
``` shell
vncpasswd
```


安装`flixbox`这个十分轻量化的桌面：
``` shell
apt install fluxbox
```


安装`novnc`：
``` shell
apt install novnc
```


手动启动一下vnc server：
``` shell
vncserver -localhost no -geometry 1280x768
```


然后把vnc server关掉
``` shell
vncserver -kill :1
```


编辑`~/.config/tigervnc/config`文件，第一行是默认启动的桌面，我们把它换成`fluxbox`，像这样：
``` config
#session=lxqt
session=fluxbox
geometry=1920x1080 # 这里为什么分辨率变了我也不知道
localhost
alwaysshared
```

接下来在`~`目录写一个shell脚本`run.sh`，用于每次一键启动：
``` shell
export DISPLAY=:1

rm -r /tmp/.X*
rm /root/.config/tigervnc/*.pid
rm /root/.config/tigervnc/*.log

vncserver -localhost no -geometry 1280x768
sleep 5

websockify -D --web=/usr/share/novnc/ 5999 localhost:5901
sleep 5

wine explorer
```


# 安装Wine
直接安装这些包即可：
``` shell
apt install wine wine64 libwine fonts-wine
# 32位软件支持
dpkg --add-architecture i386 && apt update
apt install ​wine wine32 wine64 libwine libwine:i386 fonts-wine
```


接下来，就和正常在电脑上开wine一样方便，直接`wine program.exe`即可。


# 开玩！
进入容器的`~`目录，运行`run.sh`，接下来就可以在浏览器打开`http://你的服务器ip:5999`开玩了！



# 维护用的信息
下面是一些可能需要的命令。

查看vnc服务信息：
``` shell
vncserver -list
```
关闭某个vnc服务：
``` shell
vncserver -kill :1
```

查看websockify的进程：
``` shell
ps aux | grep websockify
```



# 参考的资料
[Debian12安装VNC及novnc](https://www.cnblogs.com/ahlxjg/p/18194039)
[Wine - Debian Wiki](https://wiki.debian.org/Wine)

