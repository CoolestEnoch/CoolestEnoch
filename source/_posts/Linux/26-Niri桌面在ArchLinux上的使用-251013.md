---
title: Niri桌面在ArchLinux上的使用
category: Linux
date: 2025-10-13 00:00:00
updated: 2025-10-13 00:00:00
index_img: https://yalter.github.io/niri/_assets/icons/logo.svg
---


 ![封面](https://yalter.github.io/niri/_assets/icons/logo.svg)
(封面图源[Niri@Github](https://github.com/YaLTeR/niri))



# TL;DR
在用了KDE和Gnome后，感觉有点索然无味了。KDE确实好看，但太重了；Gnome的平铺动态多工作区模式确实效率高，但~~*果味十足*~~可自定义性没KDE强。那怎么办呢，不如来看看`niri`吧！这是一个用RUST写的桌面合成器，我配好桌面+附加组建后开机空载就只吃1.3G内存！老机狂喜！


![Rust Meme](https://tse2.mm.bing.net/th/id/OIP.HQ5ZqfbrekQ_gZ6TdS4KdgHaH7?cb=12&rs=1&pid=ImgDetMain&o=7&rm=3)



当然，它***只***是个***桌面合成器***而已，***仅此而已***，所以你还需要自己安装状态栏、锁屏界面、通知栏等一系列工具。

# 安装基础软件包
这是`niri`桌面和依赖的一些组建。
``` shell
sudo pacman -S --needed niri alacritty fuzzel swaylock swayidle waybar swaybg xwayland-satellite swaync
```
`alacritty`: 终端命令行。
`fuzzel`: 相当于`krunner`，是个应用程序启动器。
`swaylock`: 锁屏界面。
`swayidle`: 负责处理超时自动休眠。
`waybar`: 系统顶部的状态栏。
`swaybg`: 壁纸组件。
`xwayland-satellite`: 用于兼容运行旧式`X11`软件。
`swaync`: 通知栏组件。



# 安装字体
``` shell
sudo pacman -S  noto-fonts-emoji  otf-font-awesome

# 搜索可用的 CaskaydiaCove 相关包，这是waybar配置文件中的首选字体
paru -Ss caskaydia
paru -Ss cascadia
paru -S ttf-cascadia-code-nerd

sudo pacman -S  ttf-fira-code

# 更新字体缓存
fc-cache -fv
```


# 添加`swaybg`作为服务运行
``` shell
systemctl --user add-wants niri.service waybar.service
systemctl --user add-wants niri.service swaybg.service
```


# 添加配置文件
将[我的仓库](https://github.com/CoolestEnoch/niriconfig)克隆下来，运行`deploy.sh`即可。
> ⚠️注
> 如您使用的是我的配置文件，均包含后文所述修改和问题的解决方案，并且自动化部署脚本`deploy.sh`都会帮你去做好，您只需手动安装对应的软件包即可。


# 鼠标指针
修改`deploy.sh`中`THEME_CURSOR`和`THEME_CURSOR_SIZE`两个变量的值，第一个设置成你的主题名，第二个设置成大小（默认是24），改完运行`deploy.sh`可动态应用指针修改。如果有些软件（如vscode）没能更改过来，把软件关了重启即可。


主题名可在`~/.icons`里找到，这里面每个文件夹名都是主题名。主题可以在KDE设置里直接下载，或者用浏览器下载好了解压进去。


# 状态栏
我采用的是`waybar`，配置文件见`dotconfig/waybar/config.jsonc`和`dotconfig/waybar/style.css`。我是基于[woioeow/hyprland-dotfiles GitHub仓库](https://github.com/woioeow/hyprland-dotfiles)二改的，所以和他的样子大差不差，但也有些不同。做了修改后记得运行`deploy.sh`更新配置。
详细配置教程可看[官方文档](https://github.com/Alexays/Waybar/wiki)。

## 配置文件结构
前面三个节点`"modules-left"`、`"modules-center"`、`"modules-right"`用于声明左中右三个方位的内容，后面就是对每个节点的详细配置。

## 状态栏天气
你需要添加`dotconfig/waybar/weather.sh`这个脚本，保证脚本最后返回值是你的天气内容。比如`广州 晴 11.4-5.14°C`，它会显示在屏幕右上角通知和时间图标的中间。默认触发查询间隔是`1小时`，你可以修改`dotconfig/waybar/config.jsonc`进行修改，位于`"custom/weather"`节点。

## 蓝牙控制
我采用的是`bluetoothctl`进行命令管理操作，使用`blueman`作为界面前端，你需要保证安装了这两个包。
``` shell
sudo pacman -S bluez-utils blueman
```

## `ZRAMSWAP`监控
我的电脑配置了[`ZRAMSWAP`](https://wiki.archlinux.org/title/Zram#Using_zramswap)，想要在状态栏监视其用量状态。
在`dotconfig/waybar/config.jsonc`里添加节点`"custom/zramswap"`即可。


# 系统壁纸和锁屏配置
## 系统壁纸
分为桌面壁纸和锁屏壁纸，默认壁纸位置是：
桌面壁纸（或者修改我的配置文件仓库里`dotfiles/systemd/user/swaybg.service`，然后重新运行`deploy.sh`即可刷新）：
``` shell
~/Pictures/wallpaper/wallpaper_desktop.png
```
锁屏壁纸（或者修改我的配置文件仓库里`dotconfig/swaylock/config`，然后重新运行`deploy.sh`即可刷新）：
``` shell
~/Pictures/wallpaper/wallpaper_lock.png
```
## 锁屏配置
锁屏界面采用的是`swaylock`，详细可看[官方文档](https://github.com/swaywm/swaylock/blob/master/swaylock.1.scd)。
> 修改我的配置文件仓库里`dotconfig/swaylock/config`，然后重新运行`deploy.sh`即可刷新


# 通知栏
采用的是`swaync`，可高度自定义主题界面。我的配置文件位于`dotconfig/swaync/config.json`和`dotconfig/swaync/style.css`。
其实你可以去下载大家分享的主题，详见[`swaync`的这个issues](https://github.com/ErikReider/SwayNotificationCenter/discussions/183)。


# `Dolphin`相关问题
## 没法选择文件打开方式怎么办？
安装`archlinux-xdg-menu`然后在终端运行
``` shell
XDG_MENU_PREFIX=arch- kbuildsycoca6
```
即可。


## 没法弹出挂载授权认证界面怎么办？
在`config.kdl`中添加如下语句：
``` kdl
// 开机启动KDE polkit防止dolphin挂载磁盘的弹窗弹不出来
spawn-sh-at-startup "/usr/lib/polkit-kde-authentication-agent-1 &"
```



# 剪贴板历史记录怎么办
我使用的`vicinae`来解决这个问题，并绑定了`Super+X`这个快捷键（不像`KDE`和`Windows`绑`Super+V`是因为这个键默认绑到了切换浮窗上，虽然你可以去配置文件里改绑，但我不太想动这些默认的习惯设置）。
安装`vicinae`：
``` shell
paru -S vicinae-bin
```
添加到`~/.config/niri/config.kdl`：
``` kdl
// vicinae剪贴板历史记录
Super+X { spawn-sh "vicinae toggle"; }
```
如果你坚持修改默认的习惯设置，在`~/.config/niri/config.kdl`里找到这行，然后修改即可。将大括号里的像上面的一样换成`spawn-sh "vicinae toggle";`即可：
``` kdl
// Move the focused window between the floating and the tiling layout.
Mod+V       { toggle-window-floating; }
```



# 微信右键消息没法弹出菜单、表情等小弹窗乱飞怎么办
用`gamescope`，具体可参考[这个WiKi](https://wiki.archlinux.org/title/Gamescope)。它需要你安装好了`mesa`驱动组建，具体可以看[这个WiKi](https://wiki.archlinux.org/title/Intel_graphics)。
总的来说，你只需要安装这三个包就行（对于像我一样的`Intel`核显机器）：
``` shell
sudo pacman -S gamescope mesa vulkan-intel
```
然后用`gamescope`运行你的应用程序`your_progrom`即可。就像这样：
``` shell
# 直接运行
gamescope -- your_progrom
# 使用特定分辨率和帧率运行
gamescope -W 1920 -H 1080 -r 60 -- your_program
```
如果你的软件和`wayland`有兼容性问题，给`gamescope`添加这个参数:
``` shell
--expose-wayland
```
这时，你只需要去修改微信的启动脚本，在前面添加`gamescope`即可


# 引用的文档和页面
[Niri GitHub 仓库](https://github.com/YaLTeR/niri)
****
[kznleaf - 无限平铺窗口管理器——niri在 ArchLinux 上的安装与配置](https://kznleaf.top/2025/09/18/niri%E5%AE%89%E8%A3%85%E4%B8%8E%E9%85%8D%E7%BD%AE)
[woioeow/hyprland-dotfiles GitHub仓库](https://github.com/woioeow/hyprland-dotfiles)
[Archlinux Forums - How to set up Polkit to allow Dolphin to mount different Partitions?](https://bbs.archlinux.org/viewtopic.php?id=288823)
[ArchWiki - polkit](https://wiki.archlinux.org/title/Polkit#Authentication_agents)
[ArchWiki - XDG MIME Applications](https://wiki.archlinux.org/title/XDG_MIME_Applications#Empty_MIME_associations_/_open_with_menu_in_KDE)
[Swaylock GitHub 仓库](https://github.com/swaywm/swaylock)
[Swaylock 参数解释 GitHub 仓库](https://github.com/swaywm/swaylock/blob/master/swaylock.1.scd)
