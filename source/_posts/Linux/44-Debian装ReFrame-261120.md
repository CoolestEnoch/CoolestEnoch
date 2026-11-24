---
title: Debian装reframe
category: Linux
date: 2026-11-20 18:00:00
---


# TL;DR
书接上回，继续在debian上折腾这个直接抓取DRM的远程桌面。



# 安装依赖并编译

Debian 13 上安装编译依赖时，也装上 `systemd-dev`，这样 Meson 能检测到 systemd 支持。项目默认使用 `libvncserver`；源码构建方法如下。

```bash
sudo apt update
sudo apt install -y git build-essential meson ninja-build pkg-config libglib2.0-dev libgtk-4-dev libdrm-dev libepoxy-dev libvncserver-dev libxkbcommon-dev libsystemd-dev systemd-dev

git clone --recurse-submodules https://github.com/AlynxZhou/reframe.git
cd reframe
meson setup --prefix=/usr build
meson compile -C build
sudo meson install -C build
```

# 配置 HDMI 显示器和多屏桌面

复制示例配置，再编辑：

```bash
sudo cp /etc/reframe/example.conf /etc/reframe/hdmi.conf
sudo vim /etc/reframe/hdmi.conf
```

将对应配置设为：

```ini
card=card1
connector=HDMI-A-1
desktop-width=3000
desktop-height=1920
monitor-x=0
monitor-y=0
default-width=1920
default-height=1080
```

`card` 和 `connector` 用来指定 DRM 显卡与显示器接口。多屏时，桌面宽高和目标显示器偏移也要与桌面布局一致；我的布局总范围是 `3000×1920`，HDMI 屏左上角偏移为 `(0, 0)`。`default-width` 和 `default-height` 则设定 VNC 客户端默认尺寸。

# 授予服务访问显卡设备的权限

我的 `/dev/dri/card1` 属于 `video` 组，`/dev/dri/renderD128` 属于 `render` 组。给 ReFrame Server 服务添加这两个附加组：

```bash
sudo systemctl edit reframe-server@hdmi.service
```

在编辑器里写入并保存：

```ini
[Service]
SupplementaryGroups=video render
```

然后加载配置并启动服务和 socket：

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now reframe@hdmi.socket
sudo systemctl enable --now reframe-server@hdmi.service
```

socket 会按需启动 `reframe-streamer@hdmi.service`；通常不需要单独启用 streamer。若画面正常但键盘鼠标无法操作，再加载 `uinput`：

```bash
sudo modprobe uinput
```

# 连接并验证

在 VNC 客户端连接服务器 IP 的 **5933 端口**。

检查服务状态和监听端口：

```bash
systemctl status reframe-server@hdmi.service reframe@hdmi.socket --no-pager
sudo ss -lntp | grep 5933
```

修改显示器或桌面布局后，先断开 VNC 客户端，再重启服务：

```bash
sudo systemctl restart reframe-server@hdmi.service
```

如果之后只接一台显示器，或者显示器布局发生变化，记得重新核对 `card`、`connector` 以及多屏尺寸和偏移。
