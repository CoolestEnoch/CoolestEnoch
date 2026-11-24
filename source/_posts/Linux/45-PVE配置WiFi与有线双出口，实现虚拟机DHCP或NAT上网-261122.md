---
title: PVE配置WiFi与有线双出口，实现虚拟机DHCP或NAT上网
category: Linux
date: 2026-11-22 18:00:00
---


# ***⚠️万字长文预警***


# TL;DR
项目需求，需要一个PVE来配测试环境，正好来补全之前没玩过PVE的这块拼图。



# 需求背景

最初安装 PVE 时，电脑通过***网线***连接到家里的路由器，网络参数如下：

| 配置项 | 初始配置 |
|---|---|
| 物理网卡 | nic0 |
| PVE 管理 IP | 192.168.1.14 |
| 子网掩码 | 255.255.255.0 |
| 默认网关 | 192.168.1.1 |
| 网络地址 | 192.168.1.0/24 |

安装完成后，我在 PVE 上安装了 KDE 桌面环境，并创建了几台虚拟机。

最初，所有虚拟机都通过 PVE 的 `vmbr0` 网桥连接到物理局域网，可以正常上网。

后来，我希望实现以下功能：

1. PVE 主机可以通过无线网卡连接手机热点上网。
2. 虚拟机不直接桥接到 Wi-Fi，而是通过 PVE 主机 NAT 上网。
3. 虚拟机可以自动获取 IP、网关和 DNS，不需要手动配置静态 IP。
4. 手机热点关闭后，虚拟机可以自动切换到有线网络上网。
5. 将来更换有线路由器，即使网段从 `192.168.1.0/24` 变成 `10.20.0.0/16`，也不需要重新配置虚拟机。
6. 所有网络配置在 PVE 重启后能够自动恢复。

最终采用的方案是：

**NetworkManager 管理 Wi-Fi，PVE ifupdown2 管理网桥，dnsmasq 提供 DHCP，iptables 提供 NAT，Linux 路由表负责选择互联网出口。**

---

# 为什么不直接把 Wi-Fi 网卡桥接到 vmbr0？

一开始考虑过将 `vmbr0` 的物理上级从有线网卡 `nic0` 改成无线网卡 `wlan0`。

但是普通 Wi-Fi 客户端模式并不适合直接作为传统 Linux Bridge 的透明二层上级。

传统网桥需要透明转发其他设备的 MAC 地址，而常规 Wi-Fi 客户端连接热点时通常采用三地址模式，AP 和客户端不一定支持这种桥接所需的四地址模式。

因此，更合适的方式是：

- PVE 使用 Wi-Fi 连接手机热点。
- 创建独立的虚拟机内部网桥。
- PVE 负责 IP 转发和 NAT。
- 虚拟机通过 PVE 访问互联网。

这样不需要手机热点支持特殊的 Wi-Fi 桥接模式。

# 最终网络架构

规划两个 Linux Bridge：

- `vmbr0`：连接物理有线网卡，负责 PVE 管理网络和有线互联网出口。
- `vmbr1`：不连接物理网卡，专门给虚拟机使用。

PVE 同时拥有一张无线网卡 `wlan0`。

网络拓扑如下：

``` text
                   手机热点
                       |
                       | Wi-Fi
                       |
                    wlan0
                       |
              +----------------+
              |    PVE 主机     |
              |                |
              | IP Forwarding  |
              | iptables NAT   |
              |                |
              +----------------+
                       |
                     vmbr1
                  10.77.77.1/24
                       |
              +--------+--------+
              |                 |
          Windows VM         Linux VM
          DHCP 获取 IP       DHCP 获取 IP
          10.77.77.x         10.77.77.x
```

``` mermaid
flowchart TB
    hotspot["手机热点"] -->|Wi-Fi| wlan0["wlan0"]
    wlan0 --> pve["PVE 主机<br/>IP Forwarding<br/>iptables NAT"]
    pve --> vmbr1["vmbr1<br/>10.77.77.1/24"]

    vmbr1 --> win["Windows VM<br/>DHCP 获取 IP<br/>10.77.77.x"]
    vmbr1 --> linux["Linux VM<br/>DHCP 获取 IP<br/>10.77.77.x"]
```

同时保留原有有线网络：

``` text
物理路由器
192.168.1.1
      |
    nic0
      |
    vmbr0
      |
   PVE 主机
192.168.1.14
```

``` mermaid
flowchart TB
    router["物理路由器<br/>192.168.1.1"] --> nic0["nic0"]
    nic0 --> vmbr0["vmbr0"]
    vmbr0 --> pve["PVE 主机<br/>192.168.1.14"]
```

这里需要区分：

- `vmbr0` 和 `vmbr1` 本身都是 Linux Bridge。
- `vmbr0` 是连接物理局域网的桥接网络。
- `vmbr1` 是虚拟机内部交换网络。
- `vmbr1` 上的虚拟机通过 PVE 的 IP 转发和 NAT 访问外网。

---

# PVE 网络接口规划

当前物理网卡设备：

``` bash
ip link
```

主要设备：

``` text
lo
nic0
wlan0
vmbr0
```

其中：

| 设备 | 用途 |
|---|---|
| nic0 | 有线物理网卡 |
| wlan0 | 无线物理网卡 |
| vmbr0 | 有线网络桥接 |
| vmbr1 | 虚拟机内部网络 |
| lo | 本地回环接口 |

## NetworkManager配置：防止接管有线网卡

由于 PVE 使用 ifupdown2 管理网络桥接，而 KDE 使用 NetworkManager 管理无线网络，因此需要防止 NetworkManager 接管 PVE 创建的网桥和虚拟网卡。

创建配置：

``` bash
sudo vim /etc/NetworkManager/conf.d/10-pve-wifi-only.conf
```

内容：

``` ini
[main]
plugins=ifupdown,keyfile

[ifupdown]
managed=false

[keyfile]
unmanaged-devices=interface-name:nic*;interface-name:vmbr*;interface-name:tap*;interface-name:fwbr*;interface-name:fwpr*;interface-name:fwln*;interface-name:veth*
```

这样：
- `wlan0` 由 NetworkManager 管理。
- `nic0`、`vmbr0`、`vmbr1` 等由 PVE 网络配置管理。

通过 KDE 右下角的网络管理器即可连接手机热点。

检查：

``` bash
nmcli device status
```

预期：

``` text
DEVICE  TYPE      STATE       CONNECTION
wlan0  wifi      connected   手机热点
lo      loopback  connected   lo
vmbr0   bridge    unmanaged   --
nic0    ethernet  unmanaged   --
```

---

# 配置 vmbr0 和 vmbr1

PVE 的网络配置文件：

``` bash
/etc/network/interfaces
```

## vmbr0：有线网络桥接

最初安装 PVE 时，vmbr0 使用静态 IP：

``` ini
auto vmbr0
iface vmbr0 inet static
        address 192.168.1.14/24
        gateway 192.168.1.1
        bridge-ports nic0
        bridge-stp off
        bridge-fd 0
```

这也是目前已经验证可正常工作的基础配置。

如果经常更换上游路由器，可以进一步改为 DHCP：

``` ini
auto vmbr0
iface vmbr0 inet dhcp
        metric 700
        bridge-ports nic0
        bridge-stp off
        bridge-fd 0
```

这样 PVE 插到不同路由器后，就能自动获得对应的 IP、子网掩码和网关。

例如：

原来的路由器：

``` text
网络：192.168.1.0/24
网关：192.168.1.1
PVE：DHCP 自动获取 192.168.1.x
```

另一台路由器：

``` text
网络：10.20.0.0/16
网关：由 DHCP 下发
PVE：DHCP 自动获取 10.20.x.x
```

这里的 `metric 700` 用来设置有线默认路由的优先级，让机器优先走WiFi上网。

注意：DHCP 路由 metric 的具体应用取决于 DHCP 客户端，需要通过 `ip route` 验证。修改前应备份配置，并在本机控制台操作。

## vmbr1：创建虚拟机专用内部网桥

在 `/etc/network/interfaces` 中增加：

``` ini
auto vmbr1
iface vmbr1 inet static
        address 10.77.77.1/24
        bridge-ports none
        bridge-stp off
        bridge-fd 0
```

重点：

``` ini
bridge-ports none
```

表示这个网桥不连接任何物理网卡。

`10.77.77.1` 是 PVE 在虚拟机内部网络中的网关地址。

以后所有通过 vmbr1 上网的虚拟机，都使用：

``` text
默认网关：10.77.77.1
```

## 应用配置

修改之前先备份：

``` bash
sudo cp -a /etc/network/interfaces /etc/network/interfaces.bak
```

应用配置：

``` bash
sudo ifreload -a
```

检查：

``` bash
ip -4 addr show vmbr1
ip route
```

预期：

``` text
inet 10.77.77.1/24
```

以及：

``` text
10.77.77.0/24 dev vmbr1
```

---

# 配置双出口路由优先级

目前有两个互联网出口：

| 网卡 | 作用 | 路由优先级 |
|---|---|---:|
| wlan0 | 手机热点 | 600 |
| vmbr0 | 有线路由器 | 700 |

Linux 路由规则中，metric 数值越小，优先级越高。

因此：

``` text
Wi-Fi：600
有线：700
```

当手机热点正常连接时，系统优先通过 wlan0 上网。

当 Wi-Fi 连接断开，且相应 DHCP 默认路由被移除时，系统可以使用 vmbr0 上的备用默认路由。

检查：

``` bash
ip route
```

理想状态：

``` text
default via <Wi-Fi网关> dev wlan0 metric 600
default via <有线网关> dev vmbr0 metric 700
```

查看实际出口：

``` bash
ip route get 1.1.1.1
```

正常情况下应该显示：

``` text
dev wlan0
```

关闭手机热点后，再次检查应该变成：

``` text
dev vmbr0
```

注意：metric 只能根据路由是否存在以及路由优先级选择出口。若 Wi-Fi 仍然显示连接，但手机热点已经无法访问互联网，单靠 metric 不会自动识别这种故障。需要额外的网络连通性检测机制。

---

# 开启 Linux IPv4 转发

虚拟机使用 vmbr1，而互联网出口可能是 wlan0 或 vmbr0。

PVE 主机需要允许不同网络接口之间进行 IP 转发。

立即开启：

``` bash
sudo sysctl -w net.ipv4.ip_forward=1
```

验证：

``` bash
sysctl net.ipv4.ip_forward
```

预期：

``` text
net.ipv4.ip_forward = 1
```

## 设置永久生效

创建：

``` bash
sudo vim /etc/sysctl.d/99-pve-vm-nat.conf
```

内容：

``` ini
net.ipv4.ip_forward=1
```

应用：

``` bash
sudo sysctl --system
```

这样 PVE 重启后也会启用 IPv4 转发。

---

# 配置 NAT（MASQUERADE）

这是整个架构最重要的部分，也是本次排查过程中发现的一个关键问题。

虚拟机使用的是：

``` text
10.77.77.0/24
```

但上游手机热点或有线路由器并不知道这个内部网段。

因此，需要使用 NAT 把虚拟机的源 IP 转换成 PVE 实际出口网卡的 IP。

**由于有两个可能的互联网出口，所以必须分别为 Wi-Fi 和有线网络配置 NAT 规则。**

## 无线出口 NAT

执行：

``` bash
sudo iptables -t nat -A POSTROUTING -s 10.77.77.0/24 -o wlan0 -j MASQUERADE
```

含义：

当源地址属于 `10.77.77.0/24`，并且流量需要从 wlan0 出去时，自动执行源地址转换。

## 有线出口 NAT

为了让手机热点关闭后虚拟机仍然可以通过有线网络上网，还必须增加另一条规则：

``` bash
sudo iptables -t nat -A POSTROUTING -s 10.77.77.0/24 -o vmbr0 -j MASQUERADE
```

这条规则非常重要，不能遗漏。

最终必须有两条 NAT 规则：

``` text
10.77.77.0/24 -> wlan0 -> MASQUERADE

10.77.77.0/24 -> vmbr0 -> MASQUERADE
```

Linux 根据路由表选择实际出口。

**实际排查中曾经遇到一个问题：**

手机热点连接时，虚拟机可以正常上网；但断开手机热点、只保留有线网络时，PVE 宿主机可以上网，虚拟机却无法上网。

检查 NAT 规则发现，只有：

``` text
MASQUERADE  all  --  *  wlan0
10.77.77.0/24  0.0.0.0/0
```

缺少：

``` text
MASQUERADE  all  --  *  vmbr0
10.77.77.0/24  0.0.0.0/0
```

最终执行：

``` bash
sudo iptables -t nat -A POSTROUTING -s 10.77.77.0/24 -o vmbr0 -j MASQUERADE
```

虚拟机立即恢复了有线网络上网能力。

这也说明：**宿主机能够上网，并不代表虚拟机的 NAT 转发也一定正常。**

## 避免重复添加规则

建议使用 `-C` 先检查规则是否存在，再决定是否添加。

无线出口：

``` bash
sudo iptables -t nat -C POSTROUTING -s 10.77.77.0/24 -o wlan0 -j MASQUERADE

sudo iptables -t nat -A POSTROUTING -s 10.77.77.0/24 -o wlan0 -j MASQUERADE
```

有线出口：

``` bash
sudo iptables -t nat -C POSTROUTING -s 10.77.77.0/24 -o vmbr0 -j MASQUERADE

sudo iptables -t nat -A POSTROUTING -s 10.77.77.0/24 -o vmbr0 -j MASQUERADE
```

## 检查 NAT 规则

``` bash
sudo iptables -t nat -vnL POSTROUTING
```

预期能够看到两条 MASQUERADE 规则：

``` text
MASQUERADE  all  --  *  wlan0
10.77.77.0/24  0.0.0.0/0

MASQUERADE  all  --  *  vmbr0
10.77.77.0/24  0.0.0.0/0
```

---

# 配置 dnsmasq，为虚拟机提供 DHCP

前面创建 vmbr1 后，虚拟机还需要 IP、网关和 DNS。

如果每台虚拟机都手动配置静态 IP，会比较麻烦。

因此使用 dnsmasq 提供 DHCP 服务。

## 安装 dnsmasq

执行：

``` bash
sudo apt update
sudo apt install dnsmasq
```

在这次环境中，最初只有 `dnsmasq-base`，没有完整的 `dnsmasq.service`，安装完整软件包后才获得 systemd 服务。

安装后先暂停默认服务，完成专用配置后再启用：

``` bash
sudo systemctl disable --now dnsmasq
```

## 创建专用 DHCP 配置文件

创建：

``` bash
sudo vim /etc/dnsmasq.d/vmbr1.conf
```

内容：

``` ini
# 只为虚拟机网桥提供 DHCP

# 禁用 DNS 服务，只提供 DHCP
port=0

# 只在 vmbr1 上工作
interface=vmbr1
bind-dynamic

# DHCP 地址池
dhcp-range=10.77.77.100,10.77.77.200,255.255.255.0,12h

# 默认网关
dhcp-option=option:router,10.77.77.1

# DNS
dhcp-option=option:dns-server,1.1.1.1,8.8.8.8

# 本网络只有一个 DHCP 服务器
dhcp-authoritative
```

几个关键参数：

| 配置 | 作用 |
|---|---|
| port=0 | 禁止 dnsmasq 提供 DNS 服务 |
| interface=vmbr1 | 只服务虚拟机内部网桥 |
| bind-dynamic | 支持动态接口出现 |
| dhcp-range | 指定 DHCP 地址池 |
| dhcp-option router | 下发默认网关 |
| dhcp-option dns-server | 下发 DNS 服务器 |
| dhcp-authoritative | 声明这是当前网络的权威 DHCP 服务器 |

这里非常重要：

`vmbr1` 是隔离网络，因此 dnsmasq 不应该给 vmbr0 或 wlan0 提供 DHCP。

这样不会干扰家里路由器或者手机热点自身的 DHCP 服务。

## 检查配置

``` bash
sudo dnsmasq --test
```

预期：

``` text
dnsmasq: syntax check OK.
```

## 启动 DHCP 服务

``` bash
sudo systemctl enable --now dnsmasq
```

检查：

``` bash
systemctl status dnsmasq --no-pager
```

预期：

``` text
Active: active (running)
```

检查 UDP 67 端口：

``` bash
sudo ss -lunp | grep ':67 '
```

检查日志：

``` bash
sudo journalctl -u dnsmasq -n 30 --no-pager
```

---

# Windows Server 虚拟机配置

以 Windows Server 2012（非 R2）为例。

在 PVE Web 管理页面：

``` text
Windows Server
    |
Hardware
    |
Network Device
    |
Edit
```

``` mermaid
flowchart TB
    windows["Windows Server"] --> hardware["Hardware"]
    hardware --> network["Network Device"]
    network --> edit["Edit"]
```

将网卡桥接设置为：

``` text
Bridge: vmbr1

Model: VirtIO (paravirtualized)
```

保留原 MAC 地址即可。

## 最初使用静态 IP 测试

初次测试时，可以手动填写：

``` text
IP：       10.77.77.10
Mask：     255.255.255.0
Gateway：  10.77.77.1
DNS：      1.1.1.1
备用 DNS： 8.8.8.8
```

Windows Server 成功通过 IE 打开 Google，说明：

- vmbr1 内部网络正常。
- Windows 可以访问 PVE 网关。
- PVE 的 IPv4 转发正常。
- NAT 地址转换正常。
- 手机热点能够提供互联网连接。

## 改成 DHCP 自动获取

在 Windows Server 中按下`Win + R`，输入：

``` text
ncpa.cpl
```

找到 Ethernet 网卡：

``` text
Properties
    |
Internet Protocol Version 4 (TCP/IPv4)
```

``` mermaid
flowchart TB
    properties["Properties"] --> ipv4["Internet Protocol Version 4 (TCP/IPv4)"]
```

选择：

``` text
Obtain an IP address automatically

Obtain DNS server address automatically
```

保存后，以管理员身份打开命令行：

``` cmd
ipconfig /release
ipconfig /renew
ipconfig /all
```

预期获得：

``` text
IPv4 Address：10.77.77.100 ~ 10.77.77.200

Subnet Mask：255.255.255.0

Default Gateway：10.77.77.1

DNS Server：1.1.1.1
             8.8.8.8
```

以后新建虚拟机，只需要把网卡连接到 vmbr1，并设置为 DHCP，就可以自动获取网络参数。

## Windows Server 2012 特别说明

Windows Server 2012 非 R2 没有这个命令：

``` powershell
Test-NetConnection
```

因此不能使用这个 PowerShell 命令测试 TCP 443 端口。

可以使用：

``` cmd
ipconfig /all
nslookup www.google.com
ping 10.77.77.1
ping 1.1.1.1
```

也可以直接使用 IE 打开：

``` text
https://www.google.com
```

本次实际测试中，Windows Server 2012 已经能够通过 IE 正常打开 Google Search，验证了 DHCP + NAT 网络可以正常工作。

另外，单纯 ping 不通 Google 并不一定说明网络故障，因为某些网络会屏蔽 ICMP。

---

# 实现手机热点和有线网络自动切换

我们希望达到：

| 网络情况 | PVE 出口 |
|---|---|
| 手机热点正常连接 | wlan0 |
| 手机热点断开 | vmbr0 |
| 手机热点重新连接 | wlan0 |
| 更换有线路由器 | vmbr0 自动获取新网络参数 |

核心是两条默认路由：

``` text
Wi-Fi：metric 600

有线：metric 700
```

加上两条对应的 NAT 规则。

## 测试无线优先

查看：

``` bash
ip route get 1.1.1.1
```

预期：

``` text
1.1.1.1 via <Wi-Fi网关> dev wlan0
```

## 测试有线备用

断开手机热点连接：

``` bash
nmcli connection down "手机热点连接名称"
```

检查：

``` bash
ip route
ip route get 1.1.1.1
```

预期改为：

``` text
1.1.1.1 via <有线网关> dev vmbr0
```

然后测试：

``` bash
ping -c 3 1.1.1.1
curl -I --max-time 10 https://www.google.com
```

如果 PVE 主机有线网络正常，再进入 Windows Server，直接使用 IE 打开 Google。

恢复 Wi-Fi：

``` bash
nmcli connection up "手机热点连接名称"
```

路由应重新优先选择 wlan0。

注意：这里的自动切换主要适用于 Wi-Fi 断开、无线默认路由被移除的情况。如果无线仍然关联，但无法访问互联网，则需要另外配置网络健康检查，不能仅依赖 metric。

---

# 手机热点更换网段，是否需要修改 NAT？

不需要。

这是采用 MASQUERADE 的一个重要优势。

例如当前手机热点：

``` text
无线 IP：10.212.122.211

网关：10.212.122.199

网络：10.212.122.0/24
```

换一个手机热点后：

``` text
无线 IP：192.168.43.105

网关：192.168.43.1

网络：192.168.43.0/24
```

原来的 NAT 规则仍然可以使用：

``` bash
iptables -t nat -A POSTROUTING -s 10.77.77.0/24 -o wlan0 -j MASQUERADE
```

因为 MASQUERADE 自动使用出口网卡当前的 IP 地址，不需要写死手机热点的 IP 或网关。

虚拟机内部网络不变：

``` text
10.77.77.0/24
```

唯一需要注意的是，新的上游网络不能与 vmbr1 的内部网段冲突。

---

# 将 NAT 规则设置为永久生效

前面通过 iptables 手动添加的规则默认不会自动持久化。

可以在 `/etc/network/interfaces` 的 vmbr1 配置段中加入 post-up 和 post-down。

最终推荐的 vmbr1 配置：

``` ini
auto vmbr1
iface vmbr1 inet static
        address 10.77.77.1/24
        bridge-ports none
        bridge-stp off
        bridge-fd 0

        # Wi-Fi NAT
        post-up iptables -t nat -C POSTROUTING -s 10.77.77.0/24 -o wlan0 -j MASQUERADE 2>/dev/null || iptables -t nat -A POSTROUTING -s 10.77.77.0/24 -o wlan0 -j MASQUERADE

        # 有线 NAT
        post-up iptables -t nat -C POSTROUTING -s 10.77.77.0/24 -o vmbr0 -j MASQUERADE 2>/dev/null || iptables -t nat -A POSTROUTING -s 10.77.77.0/24 -o vmbr0 -j MASQUERADE

        # 清理 Wi-Fi NAT
        post-down iptables -t nat -D POSTROUTING -s 10.77.77.0/24 -o wlan0 -j MASQUERADE 2>/dev/null || true

        # 清理有线 NAT
        post-down iptables -t nat -D POSTROUTING -s 10.77.77.0/24 -o vmbr0 -j MASQUERADE 2>/dev/null || true
```

这里使用：

``` bash
iptables -C
```

先检查规则是否存在，避免反复执行网络重载时重复添加。

IPv4 转发则通过之前的：

``` text
/etc/sysctl.d/99-pve-vm-nat.conf
```

永久开启。

应用配置：

``` bash
sudo ifreload -a
```

检查：

``` bash
sudo iptables -t nat -vnL POSTROUTING
sysctl net.ipv4.ip_forward
systemctl is-enabled dnsmasq
systemctl is-active dnsmasq
```

注意：

1. 如果当前已经有手动添加的 NAT 规则，确认使用的规则相同，避免重复添加。
2. 如果未来启用 PVE Firewall，需要重新检查虚拟机转发和防火墙放行规则。
3. 上述 post-up 配置需要在实际重启后验证，确认两条 NAT 规则都能自动恢复。
4. PVE 的网络管理和防火墙配置可能影响 iptables 规则的生命周期，正式使用前应检查实际启动顺序和规则状态。

---

# 最终网络配置汇总

## PVE 主机网络

| 设备 | IP 配置 | 用途 |
|---|---|---|
| wlan0 | DHCP | 手机热点 |
| nic0 | manual | 有线物理网卡 |
| vmbr0 | 静态或 DHCP | 有线网络桥接 |
| vmbr1 | 10.77.77.1/24 | 虚拟机内部网络 |

## 虚拟机网络

| 配置 | 参数 |
|---|---|
| Bridge | vmbr1 |
| IP 获取 | DHCP |
| IP 地址范围 | 10.77.77.100 - 10.77.77.200 |
| 子网掩码 | 255.255.255.0 |
| 网关 | 10.77.77.1 |
| DNS | 1.1.1.1、8.8.8.8 |

## 网络服务

| 服务 | 功能 |
|---|---|
| NetworkManager | 管理 Wi-Fi |
| ifupdown2 | 管理 PVE 网卡和网桥 |
| dnsmasq | 为虚拟机提供 DHCP |
| iptables | NAT 地址转换 |
| sysctl | 开启 IPv4 转发 |

---

# 常用排查命令

## 查看所有网络接口

``` bash
ip link
ip -4 addr
```

## 查看路由表

``` bash
ip route
```

## 查看实际互联网出口

``` bash
ip route get 1.1.1.1
```

## 查看 NAT 规则

``` bash
iptables -t nat -vnL POSTROUTING
```

## 查看 FORWARD 链

``` bash
iptables -vnL FORWARD
```

## 查看 IP 转发

``` bash
sysctl net.ipv4.ip_forward
```

## 查看 DHCP 服务

``` bash
systemctl status dnsmasq --no-pager
```

## 查看 DHCP 服务日志

``` bash
journalctl -u dnsmasq -n 50 --no-pager
```

## 查看 DHCP 客户端地址

``` bash
ip -4 addr show vmbr0
```

## 查看无线连接

``` bash
nmcli device status
nmcli connection show --active
```

## 测试 PVE 互联网访问

``` bash
ping -c 3 1.1.1.1
curl -I https://www.google.com
```

---

# 总结

整个方案最重要的设计思想是：

**将虚拟机内部网络与物理上游网络解耦。**

虚拟机不再直接依赖手机热点或者某台物理路由器的 IP 网段。

它们只需要连接到 PVE 的 vmbr1：

``` text
虚拟机
   |
 vmbr1
   |
10.77.77.1
   |
PVE NAT
   |
   +---- wlan0（Wi-Fi 优先）
   |
   +---- vmbr0（有线备用）
```

``` mermaid
flowchart TB
    vm["虚拟机"] --> vmbr1["vmbr1"] --> gateway["10.77.77.1"] --> nat["PVE NAT"]
    nat -->|Wi-Fi 优先| wlan0["wlan0"]
    nat -->|有线备用| vmbr0["vmbr0"]
```

这样做带来了几个好处：

1. 手机热点更换网段，不需要修改虚拟机网络。
2. 更换有线路由器，不需要修改虚拟机网络。
3. 虚拟机可以通过 DHCP 自动获取 IP。
4. 多台虚拟机共享 PVE 的互联网出口。
5. 虚拟机之间仍然可以在 vmbr1 内部直接通信。
6. 需要直接加入物理局域网的虚拟机，仍然可以单独选择 vmbr0。

最终，PVE 既可以作为虚拟化平台，也可以承担一个轻量级的虚拟机 NAT 网关角色。

对于经常更换上游网络、使用手机热点或者需要让多台虚拟机共享互联网连接的环境，这种设计非常实用。

**核心原则：上游网络可以变化，但虚拟机内部网络保持稳定。**
