---
title: 折腾一番CloudFlare DDNS
category: Linux
date: 2024-03-02 18:00:00
index_img: https://tse3-mm.cn.bing.net/th/id/OIP-C.UQu4ACZzLR3a2dAmE7iYyQHaEK?rs=1&pid=ImgDetMain
---

![封面](https://tse3-mm.cn.bing.net/th/id/OIP-C.UQu4ACZzLR3a2dAmE7iYyQHaEK?rs=1&pid=ImgDetMain)

# TL;DR
今年一开年，Surprise！ipv4家宽开服全寄！
趁着过年走亲戚的时候拿[Natter](https://github.com/MikeWang000000/Natter)测了一下，我家、亲戚家的网络都是`NAT 4`类型的。好，好，太好了。

开学回校后，恰逢校园网基础设施更新，听门口大爷说是上个学期换的一批网络设备坏了返厂维修，开学这段时间到货学校里。
我说呢回校第一天怎么宿舍里没WiFi但是图书馆WiFi一切正常，过两天就有WiFi了***而且还是WiFi6！***~~*天翼3G太快辣！！！*~~
继续拿`Natter`测了一下，还是`NAT 4`，🆗。
出寝室买饭还能看到几个技术员在一楼开柜子弄交换机，不过这几天似乎没动静了，但有线网口还是获取不到ip地址，~~*所以有线宽带什么时候恢复*~~。


# 前期探索
在上个学期，同学送我了个~~*中国电信4K超高清*~~机顶盒，芯片是晶晨的`Amlogic S905X`，内存`1GB`，~~*外存*~~硬盘`6Gb`，刷了个`ArmBian`系统。
``` bash
    _    ____  __  __        __   _  _
   / \  |  _ \|  \/  |      / /_ | || |
  / _ \ | |_) | |\/| |_____| '_ \| || |_
 / ___ \|  _ <| |  | |_____| (_) |__   _|
/_/   \_\_| \_\_|  |_|      \___/   |_|

Welcome to Ubuntu 20.04.5 LTS with Linux 5.9.0-arm-64

No end-user support: built from trunk

System load:   3%               Up time:       2 min
Memory usage:  14% of 924M      IP:            192.168.1.102
CPU temp:      43°C             Usage of /:    30% of 5.8G

Last login: Sun Feb 25 13:17:07 2024
root@arm-64:~# neofetch
                                 root@arm-64
                                 -----------
      █ █ █ █ █ █ █ █ █ █ █      OS: Armbian focal (20.10) aarch64
     ███████████████████████     Host: Amlogic Meson GXL (S905X) P212 Development Board
   ▄▄██                   ██▄▄   Kernel: 5.9.0-arm-64
   ▄▄██    ███████████    ██▄▄   Uptime: 2 mins
   ▄▄██   ██         ██   ██▄▄   Packages: 515 (dpkg)
   ▄▄██   ██         ██   ██▄▄   Shell: bash 5.0.17
   ▄▄██   ██         ██   ██▄▄   Resolution: 720x576i
   ▄▄██   █████████████   ██▄▄   Terminal: /dev/pts/0
   ▄▄██   ██         ██   ██▄▄   CPU: (4) @ 2.016GHz
   ▄▄██   ██         ██   ██▄▄   Memory: 132MiB / 924MiB
   ▄▄██   ██         ██   ██▄▄
   ▄▄██                   ██▄▄
     ███████████████████████
      █ █ █ █ █ █ █ █ █ █ █
```

上个学期我拿它配置了一个`FRP`连到我国内公网VPS，把寝室环境暴露出去然后方便远程办公。大概细节是，这台~~*中国电信4K超高清*~~机顶盒充当跳板机，寝室路由器只开放一个端口供我在图书馆通过校园大内网连回寝室跳板机，然后访问位于宿舍的电脑。但是这只解决了校内的互联，还要处理校外公网环境以及回家后怎么办。于是我在跳板机里部署了一个代理软件的服务端，并在后台使用`systemd`对其进行保活，再用`ssh`的端口映射将代理软件监听的tcp端口映射到国内公网的VPS上。人在校外，通过手机上或者~~*苏菲*~~Surface上的代理软件连到国内公网VPS的映射端口，这个时候流量会回到跳板机，再访问内网资源。

<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" version="1.1" width="599px" height="501px" viewBox="-0.5 -0.5 599 501" content="&lt;mxfile host=&quot;app.diagrams.net&quot; modified=&quot;2024-03-02T08:12:03.100Z&quot; agent=&quot;Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36 &quot; etag=&quot;_iHpd9Tzzn-96WI1j-Py&quot; version=&quot;24.0.0&quot; type=&quot;device&quot;&gt;&#10;  &lt;diagram name=&quot;Page-1&quot; id=&quot;qOIfiBnbt-_uR34WX2cL&quot;&gt;&#10;    &lt;mxGraphModel dx=&quot;1050&quot; dy=&quot;564&quot; grid=&quot;1&quot; gridSize=&quot;10&quot; guides=&quot;1&quot; tooltips=&quot;1&quot; connect=&quot;1&quot; arrows=&quot;1&quot; fold=&quot;1&quot; page=&quot;1&quot; pageScale=&quot;1&quot; pageWidth=&quot;850&quot; pageHeight=&quot;1100&quot; math=&quot;0&quot; shadow=&quot;0&quot;&gt;&#10;      &lt;root&gt;&#10;        &lt;mxCell id=&quot;0&quot; /&gt;&#10;        &lt;mxCell id=&quot;1&quot; parent=&quot;0&quot; /&gt;&#10;        &lt;mxCell id=&quot;j0mtV--DJc_brgJgEW1E-40&quot; value=&quot;&quot; style=&quot;rounded=0;whiteSpace=wrap;html=1;&quot; parent=&quot;1&quot; vertex=&quot;1&quot;&gt;&#10;          &lt;mxGeometry x=&quot;54.5&quot; y=&quot;58&quot; width=&quot;595.5&quot; height=&quot;500&quot; as=&quot;geometry&quot; /&gt;&#10;        &lt;/mxCell&gt;&#10;        &lt;mxCell id=&quot;j0mtV--DJc_brgJgEW1E-2&quot; value=&quot;&quot; style=&quot;image;html=1;image=img/lib/clip_art/networking/Router_Icon_128x128.png&quot; parent=&quot;1&quot; vertex=&quot;1&quot;&gt;&#10;          &lt;mxGeometry x=&quot;204&quot; y=&quot;320&quot; width=&quot;80&quot; height=&quot;80&quot; as=&quot;geometry&quot; /&gt;&#10;        &lt;/mxCell&gt;&#10;        &lt;mxCell id=&quot;j0mtV--DJc_brgJgEW1E-4&quot; value=&quot;&quot; style=&quot;shape=image;html=1;verticalAlign=top;verticalLabelPosition=bottom;labelBackgroundColor=#ffffff;imageAspect=0;aspect=fixed;image=https://cdn2.iconfinder.com/data/icons/boxicons-regular-vol-3/24/bx-server-128.png&quot; parent=&quot;1&quot; vertex=&quot;1&quot;&gt;&#10;          &lt;mxGeometry x=&quot;64&quot; y=&quot;470&quot; width=&quot;48&quot; height=&quot;48&quot; as=&quot;geometry&quot; /&gt;&#10;        &lt;/mxCell&gt;&#10;        &lt;mxCell id=&quot;j0mtV--DJc_brgJgEW1E-5&quot; value=&quot;&quot; style=&quot;verticalLabelPosition=bottom;html=1;verticalAlign=top;align=center;strokeColor=none;fillColor=#00BEF2;shape=mxgraph.azure.laptop;pointerEvents=1;&quot; parent=&quot;1&quot; vertex=&quot;1&quot;&gt;&#10;          &lt;mxGeometry x=&quot;164&quot; y=&quot;473.5&quot; width=&quot;60&quot; height=&quot;41&quot; as=&quot;geometry&quot; /&gt;&#10;        &lt;/mxCell&gt;&#10;        &lt;mxCell id=&quot;j0mtV--DJc_brgJgEW1E-6&quot; value=&quot;&quot; style=&quot;sketch=0;pointerEvents=1;shadow=0;dashed=0;html=1;strokeColor=none;fillColor=#505050;labelPosition=center;verticalLabelPosition=bottom;verticalAlign=top;outlineConnect=0;align=center;shape=mxgraph.office.devices.tablet_ipad;&quot; parent=&quot;1&quot; vertex=&quot;1&quot;&gt;&#10;          &lt;mxGeometry x=&quot;274&quot; y=&quot;468&quot; width=&quot;39&quot; height=&quot;52&quot; as=&quot;geometry&quot; /&gt;&#10;        &lt;/mxCell&gt;&#10;        &lt;mxCell id=&quot;j0mtV--DJc_brgJgEW1E-7&quot; value=&quot;&quot; style=&quot;image;aspect=fixed;perimeter=ellipsePerimeter;html=1;align=center;shadow=0;dashed=0;spacingTop=3;image=img/lib/active_directory/windows_server.svg;&quot; parent=&quot;1&quot; vertex=&quot;1&quot;&gt;&#10;          &lt;mxGeometry x=&quot;384&quot; y=&quot;469&quot; width=&quot;41&quot; height=&quot;50&quot; as=&quot;geometry&quot; /&gt;&#10;        &lt;/mxCell&gt;&#10;        &lt;mxCell id=&quot;j0mtV--DJc_brgJgEW1E-8&quot; value=&quot;&quot; style=&quot;endArrow=none;html=1;rounded=0;entryX=0;entryY=1;entryDx=0;entryDy=0;&quot; parent=&quot;1&quot; target=&quot;j0mtV--DJc_brgJgEW1E-2&quot; edge=&quot;1&quot;&gt;&#10;          &lt;mxGeometry width=&quot;50&quot; height=&quot;50&quot; relative=&quot;1&quot; as=&quot;geometry&quot;&gt;&#10;            &lt;mxPoint x=&quot;94&quot; y=&quot;460&quot; as=&quot;sourcePoint&quot; /&gt;&#10;            &lt;mxPoint x=&quot;154&quot; y=&quot;380&quot; as=&quot;targetPoint&quot; /&gt;&#10;          &lt;/mxGeometry&gt;&#10;        &lt;/mxCell&gt;&#10;        &lt;mxCell id=&quot;j0mtV--DJc_brgJgEW1E-9&quot; value=&quot;&quot; style=&quot;endArrow=none;html=1;rounded=0;entryX=0.25;entryY=1;entryDx=0;entryDy=0;&quot; parent=&quot;1&quot; target=&quot;j0mtV--DJc_brgJgEW1E-2&quot; edge=&quot;1&quot;&gt;&#10;          &lt;mxGeometry width=&quot;50&quot; height=&quot;50&quot; relative=&quot;1&quot; as=&quot;geometry&quot;&gt;&#10;            &lt;mxPoint x=&quot;190&quot; y=&quot;470&quot; as=&quot;sourcePoint&quot; /&gt;&#10;            &lt;mxPoint x=&quot;344&quot; y=&quot;320&quot; as=&quot;targetPoint&quot; /&gt;&#10;          &lt;/mxGeometry&gt;&#10;        &lt;/mxCell&gt;&#10;        &lt;mxCell id=&quot;j0mtV--DJc_brgJgEW1E-10&quot; value=&quot;&quot; style=&quot;endArrow=none;html=1;rounded=0;entryX=0.75;entryY=1;entryDx=0;entryDy=0;&quot; parent=&quot;1&quot; target=&quot;j0mtV--DJc_brgJgEW1E-2&quot; edge=&quot;1&quot;&gt;&#10;          &lt;mxGeometry width=&quot;50&quot; height=&quot;50&quot; relative=&quot;1&quot; as=&quot;geometry&quot;&gt;&#10;            &lt;mxPoint x=&quot;294&quot; y=&quot;460&quot; as=&quot;sourcePoint&quot; /&gt;&#10;            &lt;mxPoint x=&quot;344&quot; y=&quot;320&quot; as=&quot;targetPoint&quot; /&gt;&#10;          &lt;/mxGeometry&gt;&#10;        &lt;/mxCell&gt;&#10;        &lt;mxCell id=&quot;j0mtV--DJc_brgJgEW1E-11&quot; value=&quot;&quot; style=&quot;endArrow=none;html=1;rounded=0;entryX=1;entryY=1;entryDx=0;entryDy=0;&quot; parent=&quot;1&quot; target=&quot;j0mtV--DJc_brgJgEW1E-2&quot; edge=&quot;1&quot;&gt;&#10;          &lt;mxGeometry width=&quot;50&quot; height=&quot;50&quot; relative=&quot;1&quot; as=&quot;geometry&quot;&gt;&#10;            &lt;mxPoint x=&quot;384&quot; y=&quot;460&quot; as=&quot;sourcePoint&quot; /&gt;&#10;            &lt;mxPoint x=&quot;274&quot; y=&quot;400&quot; as=&quot;targetPoint&quot; /&gt;&#10;          &lt;/mxGeometry&gt;&#10;        &lt;/mxCell&gt;&#10;        &lt;mxCell id=&quot;j0mtV--DJc_brgJgEW1E-12&quot; value=&quot;跳板机&quot; style=&quot;text;strokeColor=none;align=center;fillColor=none;html=1;verticalAlign=middle;whiteSpace=wrap;rounded=0;&quot; parent=&quot;1&quot; vertex=&quot;1&quot;&gt;&#10;          &lt;mxGeometry x=&quot;52&quot; y=&quot;520&quot; width=&quot;60&quot; height=&quot;30&quot; as=&quot;geometry&quot; /&gt;&#10;        &lt;/mxCell&gt;&#10;        &lt;mxCell id=&quot;j0mtV--DJc_brgJgEW1E-13&quot; value=&quot;笔记本电脑&quot; style=&quot;text;html=1;align=center;verticalAlign=middle;resizable=0;points=[];autosize=1;strokeColor=none;fillColor=none;&quot; parent=&quot;1&quot; vertex=&quot;1&quot;&gt;&#10;          &lt;mxGeometry x=&quot;154&quot; y=&quot;528&quot; width=&quot;80&quot; height=&quot;30&quot; as=&quot;geometry&quot; /&gt;&#10;        &lt;/mxCell&gt;&#10;        &lt;mxCell id=&quot;j0mtV--DJc_brgJgEW1E-14&quot; value=&quot;别的电子设备&quot; style=&quot;text;html=1;align=center;verticalAlign=middle;resizable=0;points=[];autosize=1;strokeColor=none;fillColor=none;&quot; parent=&quot;1&quot; vertex=&quot;1&quot;&gt;&#10;          &lt;mxGeometry x=&quot;250&quot; y=&quot;528&quot; width=&quot;100&quot; height=&quot;30&quot; as=&quot;geometry&quot; /&gt;&#10;        &lt;/mxCell&gt;&#10;        &lt;mxCell id=&quot;j0mtV--DJc_brgJgEW1E-15&quot; value=&quot;宿舍服务器&quot; style=&quot;text;html=1;align=center;verticalAlign=middle;resizable=0;points=[];autosize=1;strokeColor=none;fillColor=none;&quot; parent=&quot;1&quot; vertex=&quot;1&quot;&gt;&#10;          &lt;mxGeometry x=&quot;380&quot; y=&quot;528&quot; width=&quot;80&quot; height=&quot;30&quot; as=&quot;geometry&quot; /&gt;&#10;        &lt;/mxCell&gt;&#10;        &lt;mxCell id=&quot;j0mtV--DJc_brgJgEW1E-18&quot; value=&quot;&quot; style=&quot;sketch=0;aspect=fixed;pointerEvents=1;shadow=0;dashed=0;html=1;strokeColor=none;labelPosition=center;verticalLabelPosition=bottom;verticalAlign=top;align=center;fillColor=#00188D;shape=mxgraph.azure.tablet;&quot; parent=&quot;1&quot; vertex=&quot;1&quot;&gt;&#10;          &lt;mxGeometry x=&quot;590&quot; y=&quot;338&quot; width=&quot;50&quot; height=&quot;37&quot; as=&quot;geometry&quot; /&gt;&#10;        &lt;/mxCell&gt;&#10;        &lt;mxCell id=&quot;j0mtV--DJc_brgJgEW1E-20&quot; value=&quot;苏菲&quot; style=&quot;text;html=1;align=center;verticalAlign=middle;resizable=0;points=[];autosize=1;strokeColor=none;fillColor=none;&quot; parent=&quot;1&quot; vertex=&quot;1&quot;&gt;&#10;          &lt;mxGeometry x=&quot;590&quot; y=&quot;375&quot; width=&quot;50&quot; height=&quot;30&quot; as=&quot;geometry&quot; /&gt;&#10;        &lt;/mxCell&gt;&#10;        &lt;mxCell id=&quot;j0mtV--DJc_brgJgEW1E-28&quot; value=&quot;宿舍路由器&quot; style=&quot;text;html=1;align=center;verticalAlign=middle;resizable=0;points=[];autosize=1;strokeColor=none;fillColor=none;&quot; parent=&quot;1&quot; vertex=&quot;1&quot;&gt;&#10;          &lt;mxGeometry x=&quot;290&quot; y=&quot;338&quot; width=&quot;80&quot; height=&quot;30&quot; as=&quot;geometry&quot; /&gt;&#10;        &lt;/mxCell&gt;&#10;        &lt;mxCell id=&quot;j0mtV--DJc_brgJgEW1E-33&quot; value=&quot;校内访问&quot; style=&quot;text;html=1;align=center;verticalAlign=middle;resizable=0;points=[];autosize=1;strokeColor=none;fillColor=none;fontSize=39;&quot; parent=&quot;1&quot; vertex=&quot;1&quot;&gt;&#10;          &lt;mxGeometry x=&quot;460&quot; y=&quot;413.5&quot; width=&quot;180&quot; height=&quot;60&quot; as=&quot;geometry&quot; /&gt;&#10;        &lt;/mxCell&gt;&#10;        &lt;mxCell id=&quot;j0mtV--DJc_brgJgEW1E-34&quot; value=&quot;&quot; style=&quot;verticalLabelPosition=bottom;html=1;verticalAlign=top;align=center;strokeColor=none;fillColor=#00BEF2;shape=mxgraph.azure.cloud;&quot; parent=&quot;1&quot; vertex=&quot;1&quot;&gt;&#10;          &lt;mxGeometry x=&quot;250&quot; y=&quot;60&quot; width=&quot;287&quot; height=&quot;160&quot; as=&quot;geometry&quot; /&gt;&#10;        &lt;/mxCell&gt;&#10;        &lt;mxCell id=&quot;j0mtV--DJc_brgJgEW1E-29&quot; value=&quot;&quot; style=&quot;image;html=1;image=img/lib/clip_art/networking/Router_Icon_128x128.png&quot; parent=&quot;1&quot; vertex=&quot;1&quot;&gt;&#10;          &lt;mxGeometry x=&quot;353.5&quot; y=&quot;110&quot; width=&quot;80&quot; height=&quot;80&quot; as=&quot;geometry&quot; /&gt;&#10;        &lt;/mxCell&gt;&#10;        &lt;mxCell id=&quot;j0mtV--DJc_brgJgEW1E-30&quot; value=&quot;校园网&quot; style=&quot;text;html=1;align=center;verticalAlign=middle;resizable=0;points=[];autosize=1;strokeColor=none;fillColor=none;&quot; parent=&quot;1&quot; vertex=&quot;1&quot;&gt;&#10;          &lt;mxGeometry x=&quot;363.5&quot; y=&quot;180&quot; width=&quot;60&quot; height=&quot;30&quot; as=&quot;geometry&quot; /&gt;&#10;        &lt;/mxCell&gt;&#10;        &lt;mxCell id=&quot;j0mtV--DJc_brgJgEW1E-36&quot; value=&quot;&quot; style=&quot;endArrow=none;html=1;rounded=0;exitX=0.5;exitY=0;exitDx=0;exitDy=0;entryX=0.2;entryY=1;entryDx=0;entryDy=0;entryPerimeter=0;&quot; parent=&quot;1&quot; source=&quot;j0mtV--DJc_brgJgEW1E-2&quot; target=&quot;j0mtV--DJc_brgJgEW1E-34&quot; edge=&quot;1&quot;&gt;&#10;          &lt;mxGeometry width=&quot;50&quot; height=&quot;50&quot; relative=&quot;1&quot; as=&quot;geometry&quot;&gt;&#10;            &lt;mxPoint x=&quot;400&quot; y=&quot;310&quot; as=&quot;sourcePoint&quot; /&gt;&#10;            &lt;mxPoint x=&quot;450&quot; y=&quot;260&quot; as=&quot;targetPoint&quot; /&gt;&#10;          &lt;/mxGeometry&gt;&#10;        &lt;/mxCell&gt;&#10;        &lt;mxCell id=&quot;j0mtV--DJc_brgJgEW1E-37&quot; value=&quot;&quot; style=&quot;endArrow=none;html=1;rounded=0;entryX=0.9;entryY=1;entryDx=0;entryDy=0;entryPerimeter=0;exitX=0.02;exitY=0.02;exitDx=0;exitDy=0;exitPerimeter=0;&quot; parent=&quot;1&quot; source=&quot;j0mtV--DJc_brgJgEW1E-18&quot; target=&quot;j0mtV--DJc_brgJgEW1E-34&quot; edge=&quot;1&quot;&gt;&#10;          &lt;mxGeometry width=&quot;50&quot; height=&quot;50&quot; relative=&quot;1&quot; as=&quot;geometry&quot;&gt;&#10;            &lt;mxPoint x=&quot;610&quot; y=&quot;300&quot; as=&quot;sourcePoint&quot; /&gt;&#10;            &lt;mxPoint x=&quot;450&quot; y=&quot;240&quot; as=&quot;targetPoint&quot; /&gt;&#10;          &lt;/mxGeometry&gt;&#10;        &lt;/mxCell&gt;&#10;        &lt;mxCell id=&quot;j0mtV--DJc_brgJgEW1E-38&quot; value=&quot;&quot; style=&quot;curved=1;endArrow=classic;html=1;rounded=0;exitX=0;exitY=0.5;exitDx=0;exitDy=0;exitPerimeter=0;&quot; parent=&quot;1&quot; edge=&quot;1&quot; source=&quot;j0mtV--DJc_brgJgEW1E-18&quot;&gt;&#10;          &lt;mxGeometry width=&quot;50&quot; height=&quot;50&quot; relative=&quot;1&quot; as=&quot;geometry&quot;&gt;&#10;            &lt;mxPoint x=&quot;640&quot; y=&quot;350&quot; as=&quot;sourcePoint&quot; /&gt;&#10;            &lt;mxPoint x=&quot;240&quot; y=&quot;470&quot; as=&quot;targetPoint&quot; /&gt;&#10;            &lt;Array as=&quot;points&quot;&gt;&#10;              &lt;mxPoint x=&quot;530&quot; y=&quot;250&quot; /&gt;&#10;              &lt;mxPoint x=&quot;240&quot; y=&quot;240&quot; /&gt;&#10;              &lt;mxPoint x=&quot;60&quot; y=&quot;460&quot; /&gt;&#10;              &lt;mxPoint x=&quot;240&quot; y=&quot;370&quot; /&gt;&#10;            &lt;/Array&gt;&#10;          &lt;/mxGeometry&gt;&#10;        &lt;/mxCell&gt;&#10;        &lt;mxCell id=&quot;j0mtV--DJc_brgJgEW1E-41&quot; value=&quot;数据访问通路&quot; style=&quot;text;html=1;align=center;verticalAlign=middle;resizable=0;points=[];autosize=1;strokeColor=none;fillColor=none;&quot; parent=&quot;1&quot; vertex=&quot;1&quot;&gt;&#10;          &lt;mxGeometry x=&quot;337.25&quot; y=&quot;250&quot; width=&quot;100&quot; height=&quot;30&quot; as=&quot;geometry&quot; /&gt;&#10;        &lt;/mxCell&gt;&#10;      &lt;/root&gt;&#10;    &lt;/mxGraphModel&gt;&#10;  &lt;/diagram&gt;&#10;&lt;/mxfile&gt;&#10;"><defs/><g><g><rect x="2.5" y="0" width="595.5" height="500" fill="rgb(255, 255, 255)" stroke="rgb(0, 0, 0)" pointer-events="all"/></g><g><image x="151.5" y="261.5" width="80" height="80" xlink:href="https://app.diagrams.net/img/lib/clip_art/networking/Router_Icon_128x128.png"/></g><g><image x="11.5" y="411.5" width="48" height="48" xlink:href="https://cdn2.iconfinder.com/data/icons/boxicons-regular-vol-3/24/bx-server-128.png" preserveAspectRatio="none"/></g><g><rect x="112" y="415.5" width="60" height="41" fill="none" stroke="none" pointer-events="all"/><path d="M 117.09 447.31 L 117.09 417.34 C 117.45 416.35 118.25 415.65 119.19 415.5 L 164.63 415.5 C 165.78 415.64 166.72 416.6 166.97 417.88 L 166.97 447.31 L 171.79 453.23 C 172 453.97 171.8 454.74 171.23 455.36 C 170.65 455.98 169.77 456.39 168.78 456.5 L 115.28 456.5 C 114.28 456.4 113.38 455.99 112.8 455.37 C 112.21 454.75 112 453.98 112.21 453.23 Z M 119.07 447.31 L 165.17 447.37 L 165.17 418.5 C 164.95 417.77 164.39 417.25 163.73 417.13 L 120.27 417.13 C 119.62 417.39 119.15 418.05 119.07 418.84 Z M 137.37 451.32 L 135.74 453.98 L 147.06 453.98 L 145.79 451.32 Z" fill="#00bef2" stroke="none" pointer-events="all"/></g><g><rect x="222" y="410" width="39" height="52" fill="none" stroke="none" pointer-events="all"/><path d="M 241.5 413.72 C 241.93 413.72 242.25 413.38 242.25 412.98 C 242.25 412.66 242.01 412.23 241.5 412.23 C 241.05 412.23 240.75 412.61 240.75 412.98 C 240.75 413.46 241.17 413.72 241.5 413.72 Z M 225.75 456.07 L 257.25 456.07 L 257.25 415.94 L 225.75 415.94 Z M 241.57 460.51 C 242.2 460.51 243 459.95 243 459.06 C 243 458.16 242.26 457.55 241.51 457.55 C 240.52 457.55 240 458.38 240 458.98 C 240 459.85 240.62 460.51 241.57 460.51 Z M 224.9 462 C 223.39 462 222 460.63 222 459.13 L 222 412.88 C 222 411.5 223.24 410 224.97 410 L 257.96 410 C 259.77 410 261 411.45 261 412.98 L 261 459.01 C 261 460.75 259.51 462 258.09 462 Z" fill="#505050" stroke="none" pointer-events="all"/></g><g><image x="331.5" y="410.5" width="41" height="50" xlink:href="https://app.diagrams.net/img/lib/active_directory/windows_server.svg"/></g><g><path d="M 42 402 L 152 342" fill="none" stroke="rgb(0, 0, 0)" stroke-miterlimit="10" pointer-events="stroke"/></g><g><path d="M 138 412 L 172 342" fill="none" stroke="rgb(0, 0, 0)" stroke-miterlimit="10" pointer-events="stroke"/></g><g><path d="M 242 402 L 212 342" fill="none" stroke="rgb(0, 0, 0)" stroke-miterlimit="10" pointer-events="stroke"/></g><g><path d="M 332 402 L 232 342" fill="none" stroke="rgb(0, 0, 0)" stroke-miterlimit="10" pointer-events="stroke"/></g><g><rect x="0" y="462" width="60" height="30" fill="none" stroke="none" pointer-events="all"/></g><g><g transform="translate(-0.5 -0.5)"><switch><foreignObject pointer-events="none" width="100%" height="100%" requiredFeatures="http://www.w3.org/TR/SVG11/feature#Extensibility" style="overflow: visible; text-align: left;"><div xmlns="http://www.w3.org/1999/xhtml" style="display: flex; align-items: unsafe center; justify-content: unsafe center; width: 58px; height: 1px; padding-top: 477px; margin-left: 1px;"><div data-drawio-colors="color: rgb(0, 0, 0); " style="box-sizing: border-box; font-size: 0px; text-align: center;"><div style="display: inline-block; font-size: 12px; font-family: Helvetica; color: rgb(0, 0, 0); line-height: 1.2; pointer-events: all; white-space: normal; overflow-wrap: normal;">跳板机</div></div></div></foreignObject><text x="30" y="481" fill="rgb(0, 0, 0)" font-family="Helvetica" font-size="12px" text-anchor="middle">跳板机</text></switch></g></g><g><rect x="102" y="470" width="80" height="30" fill="none" stroke="none" pointer-events="all"/></g><g><g transform="translate(-0.5 -0.5)"><switch><foreignObject pointer-events="none" width="100%" height="100%" requiredFeatures="http://www.w3.org/TR/SVG11/feature#Extensibility" style="overflow: visible; text-align: left;"><div xmlns="http://www.w3.org/1999/xhtml" style="display: flex; align-items: unsafe center; justify-content: unsafe center; width: 1px; height: 1px; padding-top: 485px; margin-left: 142px;"><div data-drawio-colors="color: rgb(0, 0, 0); " style="box-sizing: border-box; font-size: 0px; text-align: center;"><div style="display: inline-block; font-size: 12px; font-family: Helvetica; color: rgb(0, 0, 0); line-height: 1.2; pointer-events: all; white-space: nowrap;">笔记本电脑</div></div></div></foreignObject><text x="142" y="489" fill="rgb(0, 0, 0)" font-family="Helvetica" font-size="12px" text-anchor="middle">笔记本电脑</text></switch></g></g><g><rect x="198" y="470" width="100" height="30" fill="none" stroke="none" pointer-events="all"/></g><g><g transform="translate(-0.5 -0.5)"><switch><foreignObject pointer-events="none" width="100%" height="100%" requiredFeatures="http://www.w3.org/TR/SVG11/feature#Extensibility" style="overflow: visible; text-align: left;"><div xmlns="http://www.w3.org/1999/xhtml" style="display: flex; align-items: unsafe center; justify-content: unsafe center; width: 1px; height: 1px; padding-top: 485px; margin-left: 248px;"><div data-drawio-colors="color: rgb(0, 0, 0); " style="box-sizing: border-box; font-size: 0px; text-align: center;"><div style="display: inline-block; font-size: 12px; font-family: Helvetica; color: rgb(0, 0, 0); line-height: 1.2; pointer-events: all; white-space: nowrap;">别的电子设备</div></div></div></foreignObject><text x="248" y="489" fill="rgb(0, 0, 0)" font-family="Helvetica" font-size="12px" text-anchor="middle">别的电子设备</text></switch></g></g><g><rect x="328" y="470" width="80" height="30" fill="none" stroke="none" pointer-events="all"/></g><g><g transform="translate(-0.5 -0.5)"><switch><foreignObject pointer-events="none" width="100%" height="100%" requiredFeatures="http://www.w3.org/TR/SVG11/feature#Extensibility" style="overflow: visible; text-align: left;"><div xmlns="http://www.w3.org/1999/xhtml" style="display: flex; align-items: unsafe center; justify-content: unsafe center; width: 1px; height: 1px; padding-top: 485px; margin-left: 368px;"><div data-drawio-colors="color: rgb(0, 0, 0); " style="box-sizing: border-box; font-size: 0px; text-align: center;"><div style="display: inline-block; font-size: 12px; font-family: Helvetica; color: rgb(0, 0, 0); line-height: 1.2; pointer-events: all; white-space: nowrap;">宿舍服务器</div></div></div></foreignObject><text x="368" y="489" fill="rgb(0, 0, 0)" font-family="Helvetica" font-size="12px" text-anchor="middle">宿舍服务器</text></switch></g></g><g><rect x="538" y="280" width="50" height="37" fill="none" stroke="none" pointer-events="all"/><path d="M 538.12 282.76 C 538 281.37 539.01 280.13 540.38 280 L 585.6 280 C 586.27 280.05 586.89 280.37 587.32 280.89 C 587.76 281.41 587.97 282.08 587.91 282.76 L 587.91 314.29 C 588 315.68 586.97 316.89 585.6 317 L 540.33 317 C 539 316.84 538.03 315.65 538.12 314.29 Z M 541.79 313.17 L 584.09 313.17 L 584.09 283.83 L 541.79 283.83 Z M 566.39 315.93 C 566.77 315.79 567.04 315.42 567.04 315.01 C 567.04 314.59 566.77 314.22 566.39 314.09 L 559.44 314.09 C 559.06 314.22 558.79 314.59 558.79 315.01 C 558.79 315.42 559.06 315.79 559.44 315.93 Z" fill="#00188d" stroke="none" pointer-events="all"/></g><g><rect x="538" y="317" width="50" height="30" fill="none" stroke="none" pointer-events="all"/></g><g><g transform="translate(-0.5 -0.5)"><switch><foreignObject pointer-events="none" width="100%" height="100%" requiredFeatures="http://www.w3.org/TR/SVG11/feature#Extensibility" style="overflow: visible; text-align: left;"><div xmlns="http://www.w3.org/1999/xhtml" style="display: flex; align-items: unsafe center; justify-content: unsafe center; width: 1px; height: 1px; padding-top: 332px; margin-left: 563px;"><div data-drawio-colors="color: rgb(0, 0, 0); " style="box-sizing: border-box; font-size: 0px; text-align: center;"><div style="display: inline-block; font-size: 12px; font-family: Helvetica; color: rgb(0, 0, 0); line-height: 1.2; pointer-events: all; white-space: nowrap;">苏菲</div></div></div></foreignObject><text x="563" y="336" fill="rgb(0, 0, 0)" font-family="Helvetica" font-size="12px" text-anchor="middle">苏菲</text></switch></g></g><g><rect x="238" y="280" width="80" height="30" fill="none" stroke="none" pointer-events="all"/></g><g><g transform="translate(-0.5 -0.5)"><switch><foreignObject pointer-events="none" width="100%" height="100%" requiredFeatures="http://www.w3.org/TR/SVG11/feature#Extensibility" style="overflow: visible; text-align: left;"><div xmlns="http://www.w3.org/1999/xhtml" style="display: flex; align-items: unsafe center; justify-content: unsafe center; width: 1px; height: 1px; padding-top: 295px; margin-left: 278px;"><div data-drawio-colors="color: rgb(0, 0, 0); " style="box-sizing: border-box; font-size: 0px; text-align: center;"><div style="display: inline-block; font-size: 12px; font-family: Helvetica; color: rgb(0, 0, 0); line-height: 1.2; pointer-events: all; white-space: nowrap;">宿舍路由器</div></div></div></foreignObject><text x="278" y="299" fill="rgb(0, 0, 0)" font-family="Helvetica" font-size="12px" text-anchor="middle">宿舍路由器</text></switch></g></g><g><rect x="408" y="355.5" width="180" height="60" fill="none" stroke="none" pointer-events="all"/></g><g><g transform="translate(-0.5 -0.5)"><switch><foreignObject pointer-events="none" width="100%" height="100%" requiredFeatures="http://www.w3.org/TR/SVG11/feature#Extensibility" style="overflow: visible; text-align: left;"><div xmlns="http://www.w3.org/1999/xhtml" style="display: flex; align-items: unsafe center; justify-content: unsafe center; width: 1px; height: 1px; padding-top: 386px; margin-left: 498px;"><div data-drawio-colors="color: rgb(0, 0, 0); " style="box-sizing: border-box; font-size: 0px; text-align: center;"><div style="display: inline-block; font-size: 39px; font-family: Helvetica; color: rgb(0, 0, 0); line-height: 1.2; pointer-events: all; white-space: nowrap;">校内访问</div></div></div></foreignObject><text x="498" y="397" fill="rgb(0, 0, 0)" font-family="Helvetica" font-size="39px" text-anchor="middle">校内访问</text></switch></g></g><g><path d="M 255.35 161.59 C 232.62 159.42 213.35 146.46 205.71 128.21 C 198.07 109.97 203.4 89.63 219.44 75.83 C 235.47 62.03 259.41 57.18 281.09 63.35 C 290.12 38 314.44 18.67 344.89 12.62 C 375.34 6.57 407.28 14.73 428.7 34.02 C 450.11 53.31 457.74 80.81 448.7 106.15 C 465.8 105.64 480.55 116.21 482.78 130.57 C 485 144.92 473.96 158.36 457.28 161.59 C 457.37 161.39 255.01 162 255.01 162 Z" fill="#00bef2" stroke="none" pointer-events="all"/></g><g><image x="301" y="51.5" width="80" height="80" xlink:href="https://app.diagrams.net/img/lib/clip_art/networking/Router_Icon_128x128.png"/></g><g><rect x="311.5" y="122" width="60" height="30" fill="none" stroke="none" pointer-events="all"/></g><g><g transform="translate(-0.5 -0.5)"><switch><foreignObject pointer-events="none" width="100%" height="100%" requiredFeatures="http://www.w3.org/TR/SVG11/feature#Extensibility" style="overflow: visible; text-align: left;"><div xmlns="http://www.w3.org/1999/xhtml" style="display: flex; align-items: unsafe center; justify-content: unsafe center; width: 1px; height: 1px; padding-top: 137px; margin-left: 342px;"><div data-drawio-colors="color: rgb(0, 0, 0); " style="box-sizing: border-box; font-size: 0px; text-align: center;"><div style="display: inline-block; font-size: 12px; font-family: Helvetica; color: rgb(0, 0, 0); line-height: 1.2; pointer-events: all; white-space: nowrap;">校园网</div></div></div></foreignObject><text x="342" y="141" fill="rgb(0, 0, 0)" font-family="Helvetica" font-size="12px" text-anchor="middle">校园网</text></switch></g></g><g><path d="M 192 262 L 255.4 162" fill="none" stroke="rgb(0, 0, 0)" stroke-miterlimit="10" pointer-events="stroke"/></g><g><path d="M 539 280.74 L 456.3 162" fill="none" stroke="rgb(0, 0, 0)" stroke-miterlimit="10" pointer-events="stroke"/></g><g><path d="M 538 298.5 Q 478 192 333 187 Q 188 182 98 292 Q 8 402 98 357 Q 188 312 188 405.63" fill="none" stroke="rgb(0, 0, 0)" stroke-miterlimit="10" pointer-events="stroke"/><path d="M 188 410.88 L 184.5 403.88 L 188 405.63 L 191.5 403.88 Z" fill="rgb(0, 0, 0)" stroke="rgb(0, 0, 0)" stroke-miterlimit="10" pointer-events="all"/></g><g><rect x="285.25" y="192" width="100" height="30" fill="none" stroke="none" pointer-events="all"/></g><g><g transform="translate(-0.5 -0.5)"><switch><foreignObject pointer-events="none" width="100%" height="100%" requiredFeatures="http://www.w3.org/TR/SVG11/feature#Extensibility" style="overflow: visible; text-align: left;"><div xmlns="http://www.w3.org/1999/xhtml" style="display: flex; align-items: unsafe center; justify-content: unsafe center; width: 1px; height: 1px; padding-top: 207px; margin-left: 335px;"><div data-drawio-colors="color: rgb(0, 0, 0); " style="box-sizing: border-box; font-size: 0px; text-align: center;"><div style="display: inline-block; font-size: 12px; font-family: Helvetica; color: rgb(0, 0, 0); line-height: 1.2; pointer-events: all; white-space: nowrap;">数据访问通路</div></div></div></foreignObject><text x="335" y="211" fill="rgb(0, 0, 0)" font-family="Helvetica" font-size="12px" text-anchor="middle">数据访问通路</text></switch></g></g></g><switch><g requiredFeatures="http://www.w3.org/TR/SVG11/feature#Extensibility"/><a transform="translate(0,-5)" xlink:href="https://www.drawio.com/doc/faq/svg-export-text-problems" target="_blank"><text text-anchor="middle" font-size="10px" x="50%" y="100%">Text is not SVG - cannot display</text></a></switch></svg>

<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" version="1.1" width="649px" height="529px" viewBox="-0.5 -0.5 649 529" content="&lt;mxfile host=&quot;app.diagrams.net&quot; modified=&quot;2024-03-02T08:13:34.141Z&quot; agent=&quot;Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36 &quot; etag=&quot;yR38gaVAreyUvvZ6bsVm&quot; version=&quot;24.0.0&quot; type=&quot;device&quot;&gt;&#10;  &lt;diagram name=&quot;Page-1&quot; id=&quot;dI_hwNI-IPbiKV3huhqv&quot;&gt;&#10;    &lt;mxGraphModel dx=&quot;1050&quot; dy=&quot;564&quot; grid=&quot;1&quot; gridSize=&quot;10&quot; guides=&quot;1&quot; tooltips=&quot;1&quot; connect=&quot;1&quot; arrows=&quot;1&quot; fold=&quot;1&quot; page=&quot;1&quot; pageScale=&quot;1&quot; pageWidth=&quot;850&quot; pageHeight=&quot;1100&quot; math=&quot;0&quot; shadow=&quot;0&quot;&gt;&#10;      &lt;root&gt;&#10;        &lt;mxCell id=&quot;0&quot; /&gt;&#10;        &lt;mxCell id=&quot;1&quot; parent=&quot;0&quot; /&gt;&#10;        &lt;mxCell id=&quot;XMfhzKKKdkuSQOpPAiJ0-55&quot; value=&quot;&quot; style=&quot;rounded=0;whiteSpace=wrap;html=1;&quot; parent=&quot;1&quot; vertex=&quot;1&quot;&gt;&#10;          &lt;mxGeometry x=&quot;60&quot; y=&quot;30&quot; width=&quot;640&quot; height=&quot;520&quot; as=&quot;geometry&quot; /&gt;&#10;        &lt;/mxCell&gt;&#10;        &lt;mxCell id=&quot;XMfhzKKKdkuSQOpPAiJ0-1&quot; value=&quot;&quot; style=&quot;image;html=1;image=img/lib/clip_art/networking/Router_Icon_128x128.png&quot; parent=&quot;1&quot; vertex=&quot;1&quot;&gt;&#10;          &lt;mxGeometry x=&quot;204&quot; y=&quot;320&quot; width=&quot;80&quot; height=&quot;80&quot; as=&quot;geometry&quot; /&gt;&#10;        &lt;/mxCell&gt;&#10;        &lt;mxCell id=&quot;XMfhzKKKdkuSQOpPAiJ0-3&quot; value=&quot;&quot; style=&quot;shape=image;html=1;verticalAlign=top;verticalLabelPosition=bottom;labelBackgroundColor=#ffffff;imageAspect=0;aspect=fixed;image=https://cdn0.iconfinder.com/data/icons/social-network-8/50/37-128.png&quot; parent=&quot;1&quot; vertex=&quot;1&quot;&gt;&#10;          &lt;mxGeometry x=&quot;204&quot; y=&quot;30&quot; width=&quot;80&quot; height=&quot;80&quot; as=&quot;geometry&quot; /&gt;&#10;        &lt;/mxCell&gt;&#10;        &lt;mxCell id=&quot;XMfhzKKKdkuSQOpPAiJ0-4&quot; value=&quot;&quot; style=&quot;shape=image;html=1;verticalAlign=top;verticalLabelPosition=bottom;labelBackgroundColor=#ffffff;imageAspect=0;aspect=fixed;image=https://cdn2.iconfinder.com/data/icons/boxicons-regular-vol-3/24/bx-server-128.png&quot; parent=&quot;1&quot; vertex=&quot;1&quot;&gt;&#10;          &lt;mxGeometry x=&quot;64&quot; y=&quot;470&quot; width=&quot;48&quot; height=&quot;48&quot; as=&quot;geometry&quot; /&gt;&#10;        &lt;/mxCell&gt;&#10;        &lt;mxCell id=&quot;XMfhzKKKdkuSQOpPAiJ0-5&quot; value=&quot;&quot; style=&quot;verticalLabelPosition=bottom;html=1;verticalAlign=top;align=center;strokeColor=none;fillColor=#00BEF2;shape=mxgraph.azure.laptop;pointerEvents=1;&quot; parent=&quot;1&quot; vertex=&quot;1&quot;&gt;&#10;          &lt;mxGeometry x=&quot;164&quot; y=&quot;473.5&quot; width=&quot;60&quot; height=&quot;41&quot; as=&quot;geometry&quot; /&gt;&#10;        &lt;/mxCell&gt;&#10;        &lt;mxCell id=&quot;XMfhzKKKdkuSQOpPAiJ0-6&quot; value=&quot;&quot; style=&quot;sketch=0;pointerEvents=1;shadow=0;dashed=0;html=1;strokeColor=none;fillColor=#505050;labelPosition=center;verticalLabelPosition=bottom;verticalAlign=top;outlineConnect=0;align=center;shape=mxgraph.office.devices.tablet_ipad;&quot; parent=&quot;1&quot; vertex=&quot;1&quot;&gt;&#10;          &lt;mxGeometry x=&quot;274&quot; y=&quot;468&quot; width=&quot;39&quot; height=&quot;52&quot; as=&quot;geometry&quot; /&gt;&#10;        &lt;/mxCell&gt;&#10;        &lt;mxCell id=&quot;XMfhzKKKdkuSQOpPAiJ0-7&quot; value=&quot;&quot; style=&quot;image;aspect=fixed;perimeter=ellipsePerimeter;html=1;align=center;shadow=0;dashed=0;spacingTop=3;image=img/lib/active_directory/windows_server.svg;&quot; parent=&quot;1&quot; vertex=&quot;1&quot;&gt;&#10;          &lt;mxGeometry x=&quot;384&quot; y=&quot;469&quot; width=&quot;41&quot; height=&quot;50&quot; as=&quot;geometry&quot; /&gt;&#10;        &lt;/mxCell&gt;&#10;        &lt;mxCell id=&quot;XMfhzKKKdkuSQOpPAiJ0-8&quot; value=&quot;&quot; style=&quot;endArrow=none;html=1;rounded=0;entryX=0;entryY=1;entryDx=0;entryDy=0;&quot; parent=&quot;1&quot; target=&quot;XMfhzKKKdkuSQOpPAiJ0-1&quot; edge=&quot;1&quot;&gt;&#10;          &lt;mxGeometry width=&quot;50&quot; height=&quot;50&quot; relative=&quot;1&quot; as=&quot;geometry&quot;&gt;&#10;            &lt;mxPoint x=&quot;94&quot; y=&quot;460&quot; as=&quot;sourcePoint&quot; /&gt;&#10;            &lt;mxPoint x=&quot;154&quot; y=&quot;380&quot; as=&quot;targetPoint&quot; /&gt;&#10;          &lt;/mxGeometry&gt;&#10;        &lt;/mxCell&gt;&#10;        &lt;mxCell id=&quot;XMfhzKKKdkuSQOpPAiJ0-9&quot; value=&quot;&quot; style=&quot;endArrow=none;html=1;rounded=0;entryX=0.25;entryY=1;entryDx=0;entryDy=0;&quot; parent=&quot;1&quot; target=&quot;XMfhzKKKdkuSQOpPAiJ0-1&quot; edge=&quot;1&quot;&gt;&#10;          &lt;mxGeometry width=&quot;50&quot; height=&quot;50&quot; relative=&quot;1&quot; as=&quot;geometry&quot;&gt;&#10;            &lt;mxPoint x=&quot;190&quot; y=&quot;470&quot; as=&quot;sourcePoint&quot; /&gt;&#10;            &lt;mxPoint x=&quot;344&quot; y=&quot;320&quot; as=&quot;targetPoint&quot; /&gt;&#10;          &lt;/mxGeometry&gt;&#10;        &lt;/mxCell&gt;&#10;        &lt;mxCell id=&quot;XMfhzKKKdkuSQOpPAiJ0-10&quot; value=&quot;&quot; style=&quot;endArrow=none;html=1;rounded=0;entryX=0.75;entryY=1;entryDx=0;entryDy=0;&quot; parent=&quot;1&quot; target=&quot;XMfhzKKKdkuSQOpPAiJ0-1&quot; edge=&quot;1&quot;&gt;&#10;          &lt;mxGeometry width=&quot;50&quot; height=&quot;50&quot; relative=&quot;1&quot; as=&quot;geometry&quot;&gt;&#10;            &lt;mxPoint x=&quot;294&quot; y=&quot;460&quot; as=&quot;sourcePoint&quot; /&gt;&#10;            &lt;mxPoint x=&quot;344&quot; y=&quot;320&quot; as=&quot;targetPoint&quot; /&gt;&#10;          &lt;/mxGeometry&gt;&#10;        &lt;/mxCell&gt;&#10;        &lt;mxCell id=&quot;XMfhzKKKdkuSQOpPAiJ0-12&quot; value=&quot;&quot; style=&quot;endArrow=none;html=1;rounded=0;entryX=1;entryY=1;entryDx=0;entryDy=0;&quot; parent=&quot;1&quot; target=&quot;XMfhzKKKdkuSQOpPAiJ0-1&quot; edge=&quot;1&quot;&gt;&#10;          &lt;mxGeometry width=&quot;50&quot; height=&quot;50&quot; relative=&quot;1&quot; as=&quot;geometry&quot;&gt;&#10;            &lt;mxPoint x=&quot;384&quot; y=&quot;460&quot; as=&quot;sourcePoint&quot; /&gt;&#10;            &lt;mxPoint x=&quot;274&quot; y=&quot;400&quot; as=&quot;targetPoint&quot; /&gt;&#10;          &lt;/mxGeometry&gt;&#10;        &lt;/mxCell&gt;&#10;        &lt;mxCell id=&quot;XMfhzKKKdkuSQOpPAiJ0-15&quot; value=&quot;跳板机&quot; style=&quot;text;strokeColor=none;align=center;fillColor=none;html=1;verticalAlign=middle;whiteSpace=wrap;rounded=0;&quot; parent=&quot;1&quot; vertex=&quot;1&quot;&gt;&#10;          &lt;mxGeometry x=&quot;52&quot; y=&quot;520&quot; width=&quot;60&quot; height=&quot;30&quot; as=&quot;geometry&quot; /&gt;&#10;        &lt;/mxCell&gt;&#10;        &lt;mxCell id=&quot;XMfhzKKKdkuSQOpPAiJ0-16&quot; value=&quot;笔记本电脑&quot; style=&quot;text;html=1;align=center;verticalAlign=middle;resizable=0;points=[];autosize=1;strokeColor=none;fillColor=none;&quot; parent=&quot;1&quot; vertex=&quot;1&quot;&gt;&#10;          &lt;mxGeometry x=&quot;154&quot; y=&quot;528&quot; width=&quot;80&quot; height=&quot;30&quot; as=&quot;geometry&quot; /&gt;&#10;        &lt;/mxCell&gt;&#10;        &lt;mxCell id=&quot;XMfhzKKKdkuSQOpPAiJ0-17&quot; value=&quot;别的电子设备&quot; style=&quot;text;html=1;align=center;verticalAlign=middle;resizable=0;points=[];autosize=1;strokeColor=none;fillColor=none;&quot; parent=&quot;1&quot; vertex=&quot;1&quot;&gt;&#10;          &lt;mxGeometry x=&quot;250&quot; y=&quot;528&quot; width=&quot;100&quot; height=&quot;30&quot; as=&quot;geometry&quot; /&gt;&#10;        &lt;/mxCell&gt;&#10;        &lt;mxCell id=&quot;XMfhzKKKdkuSQOpPAiJ0-18&quot; value=&quot;宿舍服务器&quot; style=&quot;text;html=1;align=center;verticalAlign=middle;resizable=0;points=[];autosize=1;strokeColor=none;fillColor=none;&quot; parent=&quot;1&quot; vertex=&quot;1&quot;&gt;&#10;          &lt;mxGeometry x=&quot;380&quot; y=&quot;528&quot; width=&quot;80&quot; height=&quot;30&quot; as=&quot;geometry&quot; /&gt;&#10;        &lt;/mxCell&gt;&#10;        &lt;mxCell id=&quot;XMfhzKKKdkuSQOpPAiJ0-19&quot; value=&quot;国内VPS&quot; style=&quot;text;html=1;align=center;verticalAlign=middle;resizable=0;points=[];autosize=1;strokeColor=none;fillColor=none;&quot; parent=&quot;1&quot; vertex=&quot;1&quot;&gt;&#10;          &lt;mxGeometry x=&quot;140&quot; y=&quot;55&quot; width=&quot;70&quot; height=&quot;30&quot; as=&quot;geometry&quot; /&gt;&#10;        &lt;/mxCell&gt;&#10;        &lt;mxCell id=&quot;XMfhzKKKdkuSQOpPAiJ0-21&quot; value=&quot;&quot; style=&quot;sketch=0;pointerEvents=1;shadow=0;dashed=0;html=1;strokeColor=none;fillColor=#505050;labelPosition=center;verticalLabelPosition=bottom;verticalAlign=top;outlineConnect=0;align=center;shape=mxgraph.office.devices.cell_phone_iphone_proportional;&quot; parent=&quot;1&quot; vertex=&quot;1&quot;&gt;&#10;          &lt;mxGeometry x=&quot;610&quot; y=&quot;221&quot; width=&quot;20&quot; height=&quot;43&quot; as=&quot;geometry&quot; /&gt;&#10;        &lt;/mxCell&gt;&#10;        &lt;mxCell id=&quot;XMfhzKKKdkuSQOpPAiJ0-22&quot; value=&quot;&quot; style=&quot;sketch=0;aspect=fixed;pointerEvents=1;shadow=0;dashed=0;html=1;strokeColor=none;labelPosition=center;verticalLabelPosition=bottom;verticalAlign=top;align=center;fillColor=#00188D;shape=mxgraph.azure.tablet;&quot; parent=&quot;1&quot; vertex=&quot;1&quot;&gt;&#10;          &lt;mxGeometry x=&quot;620&quot; y=&quot;316.5&quot; width=&quot;50&quot; height=&quot;37&quot; as=&quot;geometry&quot; /&gt;&#10;        &lt;/mxCell&gt;&#10;        &lt;mxCell id=&quot;XMfhzKKKdkuSQOpPAiJ0-23&quot; value=&quot;手机热点&quot; style=&quot;text;html=1;align=center;verticalAlign=middle;resizable=0;points=[];autosize=1;strokeColor=none;fillColor=none;&quot; parent=&quot;1&quot; vertex=&quot;1&quot;&gt;&#10;          &lt;mxGeometry x=&quot;630&quot; y=&quot;227.5&quot; width=&quot;70&quot; height=&quot;30&quot; as=&quot;geometry&quot; /&gt;&#10;        &lt;/mxCell&gt;&#10;        &lt;mxCell id=&quot;XMfhzKKKdkuSQOpPAiJ0-24&quot; value=&quot;苏菲&quot; style=&quot;text;html=1;align=center;verticalAlign=middle;resizable=0;points=[];autosize=1;strokeColor=none;fillColor=none;&quot; parent=&quot;1&quot; vertex=&quot;1&quot;&gt;&#10;          &lt;mxGeometry x=&quot;620&quot; y=&quot;359.5&quot; width=&quot;50&quot; height=&quot;30&quot; as=&quot;geometry&quot; /&gt;&#10;        &lt;/mxCell&gt;&#10;        &lt;mxCell id=&quot;XMfhzKKKdkuSQOpPAiJ0-25&quot; value=&quot;&quot; style=&quot;fontColor=#0066CC;verticalAlign=top;verticalLabelPosition=bottom;labelPosition=center;align=center;html=1;outlineConnect=0;fillColor=#CCCCCC;strokeColor=#6881B3;gradientColor=none;gradientDirection=north;strokeWidth=2;shape=mxgraph.networks.radio_tower;&quot; parent=&quot;1&quot; vertex=&quot;1&quot;&gt;&#10;          &lt;mxGeometry x=&quot;590&quot; y=&quot;30&quot; width=&quot;55&quot; height=&quot;100&quot; as=&quot;geometry&quot; /&gt;&#10;        &lt;/mxCell&gt;&#10;        &lt;mxCell id=&quot;XMfhzKKKdkuSQOpPAiJ0-26&quot; value=&quot;流量卡基站&quot; style=&quot;text;html=1;align=center;verticalAlign=middle;resizable=0;points=[];autosize=1;strokeColor=none;fillColor=none;&quot; parent=&quot;1&quot; vertex=&quot;1&quot;&gt;&#10;          &lt;mxGeometry x=&quot;580&quot; y=&quot;130&quot; width=&quot;80&quot; height=&quot;30&quot; as=&quot;geometry&quot; /&gt;&#10;        &lt;/mxCell&gt;&#10;        &lt;mxCell id=&quot;XMfhzKKKdkuSQOpPAiJ0-27&quot; value=&quot;&quot; style=&quot;endArrow=none;html=1;rounded=0;exitX=0.02;exitY=0.02;exitDx=0;exitDy=0;exitPerimeter=0;&quot; parent=&quot;1&quot; target=&quot;XMfhzKKKdkuSQOpPAiJ0-21&quot; edge=&quot;1&quot; source=&quot;XMfhzKKKdkuSQOpPAiJ0-22&quot;&gt;&#10;          &lt;mxGeometry width=&quot;50&quot; height=&quot;50&quot; relative=&quot;1&quot; as=&quot;geometry&quot;&gt;&#10;            &lt;mxPoint x=&quot;740&quot; y=&quot;320&quot; as=&quot;sourcePoint&quot; /&gt;&#10;            &lt;mxPoint x=&quot;420&quot; y=&quot;270&quot; as=&quot;targetPoint&quot; /&gt;&#10;          &lt;/mxGeometry&gt;&#10;        &lt;/mxCell&gt;&#10;        &lt;mxCell id=&quot;XMfhzKKKdkuSQOpPAiJ0-28&quot; value=&quot;&quot; style=&quot;endArrow=none;html=1;rounded=0;&quot; parent=&quot;1&quot; source=&quot;XMfhzKKKdkuSQOpPAiJ0-21&quot; target=&quot;XMfhzKKKdkuSQOpPAiJ0-26&quot; edge=&quot;1&quot;&gt;&#10;          &lt;mxGeometry width=&quot;50&quot; height=&quot;50&quot; relative=&quot;1&quot; as=&quot;geometry&quot;&gt;&#10;            &lt;mxPoint x=&quot;700&quot; y=&quot;240&quot; as=&quot;sourcePoint&quot; /&gt;&#10;            &lt;mxPoint x=&quot;750&quot; y=&quot;190&quot; as=&quot;targetPoint&quot; /&gt;&#10;          &lt;/mxGeometry&gt;&#10;        &lt;/mxCell&gt;&#10;        &lt;mxCell id=&quot;XMfhzKKKdkuSQOpPAiJ0-29&quot; value=&quot;&quot; style=&quot;endArrow=none;html=1;rounded=0;exitX=1;exitY=0.5;exitDx=0;exitDy=0;&quot; parent=&quot;1&quot; source=&quot;XMfhzKKKdkuSQOpPAiJ0-3&quot; target=&quot;XMfhzKKKdkuSQOpPAiJ0-25&quot; edge=&quot;1&quot;&gt;&#10;          &lt;mxGeometry width=&quot;50&quot; height=&quot;50&quot; relative=&quot;1&quot; as=&quot;geometry&quot;&gt;&#10;            &lt;mxPoint x=&quot;370&quot; y=&quot;320&quot; as=&quot;sourcePoint&quot; /&gt;&#10;            &lt;mxPoint x=&quot;420&quot; y=&quot;270&quot; as=&quot;targetPoint&quot; /&gt;&#10;          &lt;/mxGeometry&gt;&#10;        &lt;/mxCell&gt;&#10;        &lt;mxCell id=&quot;XMfhzKKKdkuSQOpPAiJ0-30&quot; value=&quot;&quot; style=&quot;curved=1;endArrow=classic;html=1;rounded=0;exitX=0;exitY=0.5;exitDx=0;exitDy=0;exitPerimeter=0;&quot; parent=&quot;1&quot; edge=&quot;1&quot; source=&quot;XMfhzKKKdkuSQOpPAiJ0-22&quot;&gt;&#10;          &lt;mxGeometry width=&quot;50&quot; height=&quot;50&quot; relative=&quot;1&quot; as=&quot;geometry&quot;&gt;&#10;            &lt;mxPoint x=&quot;740&quot; y=&quot;340&quot; as=&quot;sourcePoint&quot; /&gt;&#10;            &lt;mxPoint x=&quot;170&quot; y=&quot;460&quot; as=&quot;targetPoint&quot; /&gt;&#10;            &lt;Array as=&quot;points&quot;&gt;&#10;              &lt;mxPoint x=&quot;560&quot; y=&quot;290&quot; /&gt;&#10;              &lt;mxPoint x=&quot;570&quot; y=&quot;100&quot; /&gt;&#10;              &lt;mxPoint x=&quot;230&quot; y=&quot;70&quot; /&gt;&#10;              &lt;mxPoint x=&quot;160&quot; y=&quot;170&quot; /&gt;&#10;              &lt;mxPoint x=&quot;130&quot; y=&quot;280&quot; /&gt;&#10;              &lt;mxPoint x=&quot;50&quot; y=&quot;490&quot; /&gt;&#10;              &lt;mxPoint x=&quot;210&quot; y=&quot;360&quot; /&gt;&#10;            &lt;/Array&gt;&#10;          &lt;/mxGeometry&gt;&#10;        &lt;/mxCell&gt;&#10;        &lt;mxCell id=&quot;XMfhzKKKdkuSQOpPAiJ0-31&quot; value=&quot;数据访问通路&quot; style=&quot;text;html=1;align=center;verticalAlign=middle;resizable=0;points=[];autosize=1;strokeColor=none;fillColor=none;&quot; parent=&quot;1&quot; vertex=&quot;1&quot;&gt;&#10;          &lt;mxGeometry x=&quot;354.5&quot; y=&quot;100&quot; width=&quot;100&quot; height=&quot;30&quot; as=&quot;geometry&quot; /&gt;&#10;        &lt;/mxCell&gt;&#10;        &lt;mxCell id=&quot;XMfhzKKKdkuSQOpPAiJ0-32&quot; value=&quot;宿舍路由器&quot; style=&quot;text;html=1;align=center;verticalAlign=middle;resizable=0;points=[];autosize=1;strokeColor=none;fillColor=none;&quot; parent=&quot;1&quot; vertex=&quot;1&quot;&gt;&#10;          &lt;mxGeometry x=&quot;290&quot; y=&quot;338&quot; width=&quot;80&quot; height=&quot;30&quot; as=&quot;geometry&quot; /&gt;&#10;        &lt;/mxCell&gt;&#10;        &lt;mxCell id=&quot;XMfhzKKKdkuSQOpPAiJ0-33&quot; value=&quot;&quot; style=&quot;image;html=1;image=img/lib/clip_art/networking/Router_Icon_128x128.png&quot; parent=&quot;1&quot; vertex=&quot;1&quot;&gt;&#10;          &lt;mxGeometry x=&quot;204&quot; y=&quot;190&quot; width=&quot;80&quot; height=&quot;80&quot; as=&quot;geometry&quot; /&gt;&#10;        &lt;/mxCell&gt;&#10;        &lt;mxCell id=&quot;XMfhzKKKdkuSQOpPAiJ0-34&quot; value=&quot;校园网路由器&quot; style=&quot;text;html=1;align=center;verticalAlign=middle;resizable=0;points=[];autosize=1;strokeColor=none;fillColor=none;&quot; parent=&quot;1&quot; vertex=&quot;1&quot;&gt;&#10;          &lt;mxGeometry x=&quot;284&quot; y=&quot;210&quot; width=&quot;100&quot; height=&quot;30&quot; as=&quot;geometry&quot; /&gt;&#10;        &lt;/mxCell&gt;&#10;        &lt;mxCell id=&quot;XMfhzKKKdkuSQOpPAiJ0-35&quot; value=&quot;&quot; style=&quot;endArrow=none;html=1;rounded=0;entryX=0.5;entryY=1;entryDx=0;entryDy=0;exitX=0.5;exitY=0;exitDx=0;exitDy=0;&quot; parent=&quot;1&quot; source=&quot;XMfhzKKKdkuSQOpPAiJ0-33&quot; target=&quot;XMfhzKKKdkuSQOpPAiJ0-3&quot; edge=&quot;1&quot;&gt;&#10;          &lt;mxGeometry width=&quot;50&quot; height=&quot;50&quot; relative=&quot;1&quot; as=&quot;geometry&quot;&gt;&#10;            &lt;mxPoint x=&quot;370&quot; y=&quot;320&quot; as=&quot;sourcePoint&quot; /&gt;&#10;            &lt;mxPoint x=&quot;420&quot; y=&quot;270&quot; as=&quot;targetPoint&quot; /&gt;&#10;          &lt;/mxGeometry&gt;&#10;        &lt;/mxCell&gt;&#10;        &lt;mxCell id=&quot;XMfhzKKKdkuSQOpPAiJ0-36&quot; value=&quot;&quot; style=&quot;endArrow=none;html=1;rounded=0;entryX=0.5;entryY=1;entryDx=0;entryDy=0;exitX=0.5;exitY=0;exitDx=0;exitDy=0;&quot; parent=&quot;1&quot; source=&quot;XMfhzKKKdkuSQOpPAiJ0-1&quot; target=&quot;XMfhzKKKdkuSQOpPAiJ0-33&quot; edge=&quot;1&quot;&gt;&#10;          &lt;mxGeometry width=&quot;50&quot; height=&quot;50&quot; relative=&quot;1&quot; as=&quot;geometry&quot;&gt;&#10;            &lt;mxPoint x=&quot;310&quot; y=&quot;344&quot; as=&quot;sourcePoint&quot; /&gt;&#10;            &lt;mxPoint x=&quot;310&quot; y=&quot;264&quot; as=&quot;targetPoint&quot; /&gt;&#10;          &lt;/mxGeometry&gt;&#10;        &lt;/mxCell&gt;&#10;        &lt;mxCell id=&quot;XMfhzKKKdkuSQOpPAiJ0-56&quot; value=&quot;校外访问&quot; style=&quot;text;html=1;align=center;verticalAlign=middle;resizable=0;points=[];autosize=1;strokeColor=none;fillColor=none;fontSize=39;&quot; parent=&quot;1&quot; vertex=&quot;1&quot;&gt;&#10;          &lt;mxGeometry x=&quot;505&quot; y=&quot;393&quot; width=&quot;180&quot; height=&quot;60&quot; as=&quot;geometry&quot; /&gt;&#10;        &lt;/mxCell&gt;&#10;      &lt;/root&gt;&#10;    &lt;/mxGraphModel&gt;&#10;  &lt;/diagram&gt;&#10;&lt;/mxfile&gt;&#10;"><defs/><g><g><rect x="8" y="1" width="640" height="520" fill="rgb(255, 255, 255)" stroke="rgb(0, 0, 0)" pointer-events="all"/></g><g><image x="151.5" y="290.5" width="80" height="80" xlink:href="https://app.diagrams.net/img/lib/clip_art/networking/Router_Icon_128x128.png"/></g><g><image x="151.5" y="0.5" width="80" height="80" xlink:href="https://cdn0.iconfinder.com/data/icons/social-network-8/50/37-128.png" preserveAspectRatio="none"/></g><g><image x="11.5" y="440.5" width="48" height="48" xlink:href="https://cdn2.iconfinder.com/data/icons/boxicons-regular-vol-3/24/bx-server-128.png" preserveAspectRatio="none"/></g><g><rect x="112" y="444.5" width="60" height="41" fill="none" stroke="none" pointer-events="all"/><path d="M 117.09 476.31 L 117.09 446.34 C 117.45 445.35 118.25 444.65 119.19 444.5 L 164.63 444.5 C 165.78 444.64 166.72 445.6 166.97 446.88 L 166.97 476.31 L 171.79 482.23 C 172 482.97 171.8 483.74 171.23 484.36 C 170.65 484.98 169.77 485.39 168.78 485.5 L 115.28 485.5 C 114.28 485.4 113.38 484.99 112.8 484.37 C 112.21 483.75 112 482.98 112.21 482.23 Z M 119.07 476.31 L 165.17 476.37 L 165.17 447.5 C 164.95 446.77 164.39 446.25 163.73 446.13 L 120.27 446.13 C 119.62 446.39 119.15 447.05 119.07 447.84 Z M 137.37 480.32 L 135.74 482.98 L 147.06 482.98 L 145.79 480.32 Z" fill="#00bef2" stroke="none" pointer-events="all"/></g><g><rect x="222" y="439" width="39" height="52" fill="none" stroke="none" pointer-events="all"/><path d="M 241.5 442.72 C 241.93 442.72 242.25 442.38 242.25 441.98 C 242.25 441.66 242.01 441.23 241.5 441.23 C 241.05 441.23 240.75 441.61 240.75 441.98 C 240.75 442.46 241.17 442.72 241.5 442.72 Z M 225.75 485.07 L 257.25 485.07 L 257.25 444.94 L 225.75 444.94 Z M 241.57 489.51 C 242.2 489.51 243 488.95 243 488.06 C 243 487.16 242.26 486.55 241.51 486.55 C 240.52 486.55 240 487.38 240 487.98 C 240 488.85 240.62 489.51 241.57 489.51 Z M 224.9 491 C 223.39 491 222 489.63 222 488.13 L 222 441.88 C 222 440.5 223.24 439 224.97 439 L 257.96 439 C 259.77 439 261 440.45 261 441.98 L 261 488.01 C 261 489.75 259.51 491 258.09 491 Z" fill="#505050" stroke="none" pointer-events="all"/></g><g><image x="331.5" y="439.5" width="41" height="50" xlink:href="https://app.diagrams.net/img/lib/active_directory/windows_server.svg"/></g><g><path d="M 42 431 L 152 371" fill="none" stroke="rgb(0, 0, 0)" stroke-miterlimit="10" pointer-events="stroke"/></g><g><path d="M 138 441 L 172 371" fill="none" stroke="rgb(0, 0, 0)" stroke-miterlimit="10" pointer-events="stroke"/></g><g><path d="M 242 431 L 212 371" fill="none" stroke="rgb(0, 0, 0)" stroke-miterlimit="10" pointer-events="stroke"/></g><g><path d="M 332 431 L 232 371" fill="none" stroke="rgb(0, 0, 0)" stroke-miterlimit="10" pointer-events="stroke"/></g><g><rect x="0" y="491" width="60" height="30" fill="none" stroke="none" pointer-events="all"/></g><g><g transform="translate(-0.5 -0.5)"><switch><foreignObject pointer-events="none" width="100%" height="100%" requiredFeatures="http://www.w3.org/TR/SVG11/feature#Extensibility" style="overflow: visible; text-align: left;"><div xmlns="http://www.w3.org/1999/xhtml" style="display: flex; align-items: unsafe center; justify-content: unsafe center; width: 58px; height: 1px; padding-top: 506px; margin-left: 1px;"><div data-drawio-colors="color: rgb(0, 0, 0); " style="box-sizing: border-box; font-size: 0px; text-align: center;"><div style="display: inline-block; font-size: 12px; font-family: Helvetica; color: rgb(0, 0, 0); line-height: 1.2; pointer-events: all; white-space: normal; overflow-wrap: normal;">跳板机</div></div></div></foreignObject><text x="30" y="510" fill="rgb(0, 0, 0)" font-family="Helvetica" font-size="12px" text-anchor="middle">跳板机</text></switch></g></g><g><rect x="102" y="499" width="80" height="30" fill="none" stroke="none" pointer-events="all"/></g><g><g transform="translate(-0.5 -0.5)"><switch><foreignObject pointer-events="none" width="100%" height="100%" requiredFeatures="http://www.w3.org/TR/SVG11/feature#Extensibility" style="overflow: visible; text-align: left;"><div xmlns="http://www.w3.org/1999/xhtml" style="display: flex; align-items: unsafe center; justify-content: unsafe center; width: 1px; height: 1px; padding-top: 514px; margin-left: 142px;"><div data-drawio-colors="color: rgb(0, 0, 0); " style="box-sizing: border-box; font-size: 0px; text-align: center;"><div style="display: inline-block; font-size: 12px; font-family: Helvetica; color: rgb(0, 0, 0); line-height: 1.2; pointer-events: all; white-space: nowrap;">笔记本电脑</div></div></div></foreignObject><text x="142" y="518" fill="rgb(0, 0, 0)" font-family="Helvetica" font-size="12px" text-anchor="middle">笔记本电脑</text></switch></g></g><g><rect x="198" y="499" width="100" height="30" fill="none" stroke="none" pointer-events="all"/></g><g><g transform="translate(-0.5 -0.5)"><switch><foreignObject pointer-events="none" width="100%" height="100%" requiredFeatures="http://www.w3.org/TR/SVG11/feature#Extensibility" style="overflow: visible; text-align: left;"><div xmlns="http://www.w3.org/1999/xhtml" style="display: flex; align-items: unsafe center; justify-content: unsafe center; width: 1px; height: 1px; padding-top: 514px; margin-left: 248px;"><div data-drawio-colors="color: rgb(0, 0, 0); " style="box-sizing: border-box; font-size: 0px; text-align: center;"><div style="display: inline-block; font-size: 12px; font-family: Helvetica; color: rgb(0, 0, 0); line-height: 1.2; pointer-events: all; white-space: nowrap;">别的电子设备</div></div></div></foreignObject><text x="248" y="518" fill="rgb(0, 0, 0)" font-family="Helvetica" font-size="12px" text-anchor="middle">别的电子设备</text></switch></g></g><g><rect x="328" y="499" width="80" height="30" fill="none" stroke="none" pointer-events="all"/></g><g><g transform="translate(-0.5 -0.5)"><switch><foreignObject pointer-events="none" width="100%" height="100%" requiredFeatures="http://www.w3.org/TR/SVG11/feature#Extensibility" style="overflow: visible; text-align: left;"><div xmlns="http://www.w3.org/1999/xhtml" style="display: flex; align-items: unsafe center; justify-content: unsafe center; width: 1px; height: 1px; padding-top: 514px; margin-left: 368px;"><div data-drawio-colors="color: rgb(0, 0, 0); " style="box-sizing: border-box; font-size: 0px; text-align: center;"><div style="display: inline-block; font-size: 12px; font-family: Helvetica; color: rgb(0, 0, 0); line-height: 1.2; pointer-events: all; white-space: nowrap;">宿舍服务器</div></div></div></foreignObject><text x="368" y="518" fill="rgb(0, 0, 0)" font-family="Helvetica" font-size="12px" text-anchor="middle">宿舍服务器</text></switch></g></g><g><rect x="88" y="26" width="70" height="30" fill="none" stroke="none" pointer-events="all"/></g><g><g transform="translate(-0.5 -0.5)"><switch><foreignObject pointer-events="none" width="100%" height="100%" requiredFeatures="http://www.w3.org/TR/SVG11/feature#Extensibility" style="overflow: visible; text-align: left;"><div xmlns="http://www.w3.org/1999/xhtml" style="display: flex; align-items: unsafe center; justify-content: unsafe center; width: 1px; height: 1px; padding-top: 41px; margin-left: 123px;"><div data-drawio-colors="color: rgb(0, 0, 0); " style="box-sizing: border-box; font-size: 0px; text-align: center;"><div style="display: inline-block; font-size: 12px; font-family: Helvetica; color: rgb(0, 0, 0); line-height: 1.2; pointer-events: all; white-space: nowrap;">国内VPS</div></div></div></foreignObject><text x="123" y="45" fill="rgb(0, 0, 0)" font-family="Helvetica" font-size="12px" text-anchor="middle">国内VPS</text></switch></g></g><g><rect x="558" y="192" width="20" height="43" fill="none" stroke="none" pointer-events="all"/><path d="M 570.14 195.2 C 570.32 195.2 570.41 195.1 570.41 194.87 C 570.41 194.66 570.3 194.54 570.14 194.54 L 565.93 194.54 C 565.75 194.54 565.69 194.75 565.69 194.87 C 565.69 195.01 565.79 195.2 565.93 195.2 Z M 575.47 227.28 L 575.47 198.62 L 560.62 198.62 L 560.62 227.28 Z M 568.06 232.81 C 568.58 232.81 569.36 232.3 569.36 231.1 C 569.36 230.27 568.77 229.5 568.06 229.5 C 567.26 229.5 566.74 230.34 566.74 231.1 C 566.74 232.28 567.5 232.81 568.06 232.81 Z M 560.57 235 C 559.25 235 558 233.71 558 231.71 L 558 195.31 C 558 193.47 559.13 192 560.59 192 L 575.33 192 C 576.91 192 578 193.6 578 195.26 L 578 231.68 C 578 233.84 576.63 235 575.47 235 Z" fill="#505050" stroke="none" pointer-events="all"/></g><g><rect x="568" y="287.5" width="50" height="37" fill="none" stroke="none" pointer-events="all"/><path d="M 568.12 290.26 C 568 288.87 569.01 287.63 570.38 287.5 L 615.6 287.5 C 616.27 287.55 616.89 287.87 617.32 288.39 C 617.76 288.91 617.97 289.58 617.91 290.26 L 617.91 321.79 C 618 323.18 616.97 324.39 615.6 324.5 L 570.33 324.5 C 569 324.34 568.03 323.15 568.12 321.79 Z M 571.79 320.67 L 614.09 320.67 L 614.09 291.33 L 571.79 291.33 Z M 596.39 323.43 C 596.77 323.29 597.04 322.92 597.04 322.51 C 597.04 322.09 596.77 321.72 596.39 321.59 L 589.44 321.59 C 589.06 321.72 588.79 322.09 588.79 322.51 C 588.79 322.92 589.06 323.29 589.44 323.43 Z" fill="#00188d" stroke="none" pointer-events="all"/></g><g><rect x="578" y="198.5" width="70" height="30" fill="none" stroke="none" pointer-events="all"/></g><g><g transform="translate(-0.5 -0.5)"><switch><foreignObject pointer-events="none" width="100%" height="100%" requiredFeatures="http://www.w3.org/TR/SVG11/feature#Extensibility" style="overflow: visible; text-align: left;"><div xmlns="http://www.w3.org/1999/xhtml" style="display: flex; align-items: unsafe center; justify-content: unsafe center; width: 1px; height: 1px; padding-top: 214px; margin-left: 613px;"><div data-drawio-colors="color: rgb(0, 0, 0); " style="box-sizing: border-box; font-size: 0px; text-align: center;"><div style="display: inline-block; font-size: 12px; font-family: Helvetica; color: rgb(0, 0, 0); line-height: 1.2; pointer-events: all; white-space: nowrap;">手机热点</div></div></div></foreignObject><text x="613" y="217" fill="rgb(0, 0, 0)" font-family="Helvetica" font-size="12px" text-anchor="middle">手机热点</text></switch></g></g><g><rect x="568" y="330.5" width="50" height="30" fill="none" stroke="none" pointer-events="all"/></g><g><g transform="translate(-0.5 -0.5)"><switch><foreignObject pointer-events="none" width="100%" height="100%" requiredFeatures="http://www.w3.org/TR/SVG11/feature#Extensibility" style="overflow: visible; text-align: left;"><div xmlns="http://www.w3.org/1999/xhtml" style="display: flex; align-items: unsafe center; justify-content: unsafe center; width: 1px; height: 1px; padding-top: 346px; margin-left: 593px;"><div data-drawio-colors="color: rgb(0, 0, 0); " style="box-sizing: border-box; font-size: 0px; text-align: center;"><div style="display: inline-block; font-size: 12px; font-family: Helvetica; color: rgb(0, 0, 0); line-height: 1.2; pointer-events: all; white-space: nowrap;">苏菲</div></div></div></foreignObject><text x="593" y="349" fill="rgb(0, 0, 0)" font-family="Helvetica" font-size="12px" text-anchor="middle">苏菲</text></switch></g></g><g><path d="M 542.82 101 L 565.5 17.5 L 588.18 101" fill="none" stroke="#6881b3" stroke-width="2.02" stroke-linejoin="round" stroke-miterlimit="10" pointer-events="all"/><path d="M 587.15 95.43 L 549 78.73 L 578.9 67.6 L 555.7 56.47 L 572.72 45.84 L 560.86 36.22" fill="none" stroke="#6881b3" stroke-width="2.02" stroke-linejoin="round" stroke-miterlimit="10" pointer-events="all"/><rect x="538" y="1" width="0" height="0" fill="none" stroke="#6881b3" stroke-width="2.02" pointer-events="all"/><ellipse cx="565.5" cy="19.52" rx="4.1244844394450695" ry="4.048582995951417" fill="#cccccc" stroke="#6881b3" stroke-width="2.02" pointer-events="all"/><path d="M 572.51 12.64 L 573.96 10.92 C 578.67 15.64 578.67 23.2 573.96 27.92 L 572.51 26.3 C 576.12 22.44 576.12 16.51 572.51 12.64 Z M 577.67 7.58 L 579.11 6.16 C 586.44 13.61 586.44 25.43 579.11 32.88 L 577.67 31.47 C 584.21 24.8 584.21 14.24 577.67 7.58 Z M 582.82 2.52 L 584.27 1 C 589.81 5.62 593 12.39 593 19.52 C 593 26.66 589.81 33.43 584.27 38.04 L 582.82 36.53 C 588.09 32.4 591.16 26.14 591.16 19.52 C 591.16 12.91 588.09 6.65 582.82 2.52 Z M 558.49 12.64 L 557.04 10.92 C 552.33 15.64 552.33 23.2 557.04 27.92 L 558.49 26.3 C 554.88 22.44 554.88 16.51 558.49 12.64 Z M 553.33 7.58 L 551.89 6.16 C 544.56 13.61 544.56 25.43 551.89 32.88 L 553.33 31.47 C 546.79 24.8 546.79 14.24 553.33 7.58 Z M 548.18 2.52 L 546.73 1 C 541.19 5.62 538 12.39 538 19.52 C 538 26.66 541.19 33.43 546.73 38.04 L 548.18 36.53 C 542.91 32.4 539.84 26.14 539.84 19.52 C 539.84 12.91 542.91 6.65 548.18 2.52 Z" fill="#cccccc" stroke="#6881b3" stroke-width="2.02" stroke-miterlimit="10" pointer-events="all"/></g><g><rect x="528" y="101" width="80" height="30" fill="none" stroke="none" pointer-events="all"/></g><g><g transform="translate(-0.5 -0.5)"><switch><foreignObject pointer-events="none" width="100%" height="100%" requiredFeatures="http://www.w3.org/TR/SVG11/feature#Extensibility" style="overflow: visible; text-align: left;"><div xmlns="http://www.w3.org/1999/xhtml" style="display: flex; align-items: unsafe center; justify-content: unsafe center; width: 1px; height: 1px; padding-top: 116px; margin-left: 568px;"><div data-drawio-colors="color: rgb(0, 0, 0); " style="box-sizing: border-box; font-size: 0px; text-align: center;"><div style="display: inline-block; font-size: 12px; font-family: Helvetica; color: rgb(0, 0, 0); line-height: 1.2; pointer-events: all; white-space: nowrap;">流量卡基站</div></div></div></foreignObject><text x="568" y="120" fill="rgb(0, 0, 0)" font-family="Helvetica" font-size="12px" text-anchor="middle">流量卡基站</text></switch></g></g><g><path d="M 569 288.24 L 568.29 235" fill="none" stroke="rgb(0, 0, 0)" stroke-miterlimit="10" pointer-events="stroke"/></g><g><path d="M 568 192 L 568 131" fill="none" stroke="rgb(0, 0, 0)" stroke-miterlimit="10" pointer-events="stroke"/></g><g><path d="M 232 41 L 538 50.18" fill="none" stroke="rgb(0, 0, 0)" stroke-miterlimit="10" pointer-events="stroke"/></g><g><path d="M 568 306 Q 508 261 513 166 Q 518 71 348 56 Q 178 41 143 91 Q 108 141 93 196 Q 78 251 38 356 Q -2 461 78 396 Q 158 331 120.37 425.09" fill="none" stroke="rgb(0, 0, 0)" stroke-miterlimit="10" pointer-events="stroke"/><path d="M 118.42 429.96 L 117.77 422.16 L 120.37 425.09 L 124.26 424.76 Z" fill="rgb(0, 0, 0)" stroke="rgb(0, 0, 0)" stroke-miterlimit="10" pointer-events="all"/></g><g><rect x="302.5" y="71" width="100" height="30" fill="none" stroke="none" pointer-events="all"/></g><g><g transform="translate(-0.5 -0.5)"><switch><foreignObject pointer-events="none" width="100%" height="100%" requiredFeatures="http://www.w3.org/TR/SVG11/feature#Extensibility" style="overflow: visible; text-align: left;"><div xmlns="http://www.w3.org/1999/xhtml" style="display: flex; align-items: unsafe center; justify-content: unsafe center; width: 1px; height: 1px; padding-top: 86px; margin-left: 353px;"><div data-drawio-colors="color: rgb(0, 0, 0); " style="box-sizing: border-box; font-size: 0px; text-align: center;"><div style="display: inline-block; font-size: 12px; font-family: Helvetica; color: rgb(0, 0, 0); line-height: 1.2; pointer-events: all; white-space: nowrap;">数据访问通路</div></div></div></foreignObject><text x="353" y="90" fill="rgb(0, 0, 0)" font-family="Helvetica" font-size="12px" text-anchor="middle">数据访问通路</text></switch></g></g><g><rect x="238" y="309" width="80" height="30" fill="none" stroke="none" pointer-events="all"/></g><g><g transform="translate(-0.5 -0.5)"><switch><foreignObject pointer-events="none" width="100%" height="100%" requiredFeatures="http://www.w3.org/TR/SVG11/feature#Extensibility" style="overflow: visible; text-align: left;"><div xmlns="http://www.w3.org/1999/xhtml" style="display: flex; align-items: unsafe center; justify-content: unsafe center; width: 1px; height: 1px; padding-top: 324px; margin-left: 278px;"><div data-drawio-colors="color: rgb(0, 0, 0); " style="box-sizing: border-box; font-size: 0px; text-align: center;"><div style="display: inline-block; font-size: 12px; font-family: Helvetica; color: rgb(0, 0, 0); line-height: 1.2; pointer-events: all; white-space: nowrap;">宿舍路由器</div></div></div></foreignObject><text x="278" y="328" fill="rgb(0, 0, 0)" font-family="Helvetica" font-size="12px" text-anchor="middle">宿舍路由器</text></switch></g></g><g><image x="151.5" y="160.5" width="80" height="80" xlink:href="https://app.diagrams.net/img/lib/clip_art/networking/Router_Icon_128x128.png"/></g><g><rect x="232" y="181" width="100" height="30" fill="none" stroke="none" pointer-events="all"/></g><g><g transform="translate(-0.5 -0.5)"><switch><foreignObject pointer-events="none" width="100%" height="100%" requiredFeatures="http://www.w3.org/TR/SVG11/feature#Extensibility" style="overflow: visible; text-align: left;"><div xmlns="http://www.w3.org/1999/xhtml" style="display: flex; align-items: unsafe center; justify-content: unsafe center; width: 1px; height: 1px; padding-top: 196px; margin-left: 282px;"><div data-drawio-colors="color: rgb(0, 0, 0); " style="box-sizing: border-box; font-size: 0px; text-align: center;"><div style="display: inline-block; font-size: 12px; font-family: Helvetica; color: rgb(0, 0, 0); line-height: 1.2; pointer-events: all; white-space: nowrap;">校园网路由器</div></div></div></foreignObject><text x="282" y="200" fill="rgb(0, 0, 0)" font-family="Helvetica" font-size="12px" text-anchor="middle">校园网路由器</text></switch></g></g><g><path d="M 192 161 L 192 81" fill="none" stroke="rgb(0, 0, 0)" stroke-miterlimit="10" pointer-events="stroke"/></g><g><path d="M 192 291 L 192 241" fill="none" stroke="rgb(0, 0, 0)" stroke-miterlimit="10" pointer-events="stroke"/></g><g><rect x="453" y="364" width="180" height="60" fill="none" stroke="none" pointer-events="all"/></g><g><g transform="translate(-0.5 -0.5)"><switch><foreignObject pointer-events="none" width="100%" height="100%" requiredFeatures="http://www.w3.org/TR/SVG11/feature#Extensibility" style="overflow: visible; text-align: left;"><div xmlns="http://www.w3.org/1999/xhtml" style="display: flex; align-items: unsafe center; justify-content: unsafe center; width: 1px; height: 1px; padding-top: 394px; margin-left: 543px;"><div data-drawio-colors="color: rgb(0, 0, 0); " style="box-sizing: border-box; font-size: 0px; text-align: center;"><div style="display: inline-block; font-size: 39px; font-family: Helvetica; color: rgb(0, 0, 0); line-height: 1.2; pointer-events: all; white-space: nowrap;">校外访问</div></div></div></foreignObject><text x="543" y="406" fill="rgb(0, 0, 0)" font-family="Helvetica" font-size="39px" text-anchor="middle">校外访问</text></switch></g></g></g><switch><g requiredFeatures="http://www.w3.org/TR/SVG11/feature#Extensibility"/><a transform="translate(0,-5)" xlink:href="https://www.drawio.com/doc/faq/svg-export-text-problems" target="_blank"><text text-anchor="middle" font-size="10px" x="50%" y="100%">Text is not SVG - cannot display</text></a></switch></svg>

(图片使用[Draw IO](https://app.diagrams.net/)绘制svg)

这么做确实挺方便，我在去年考研期间就是全程这样操作的，因为实在不想把游戏本带到图书馆，不仅电源大还重，还不支持充电宝供电，而且这电脑在买来一年不到的时候因内存条虚焊而跟售后扯皮一个月才同意给我保内换主板。

**这么做的问题在于，需要一个有线的网络环境，最差情况就是路由器要支持无线桥接。** 但是我宿舍里的路由器是2010年代的上古TP-Link，而且截至今天写稿，已回校一周，宿舍有线宽带依旧没恢复，怎么办呢？~~*重买解决100%问题*~~

我开始考虑`CloudFlare`的`DDNS`服务了。恰好大一办的校园流量卡一个月能有150GB校内流量，反正用不完何不用来给电脑搞个`ipv6`的ddns呢？甚至还能有全球的公网ip，一举两得！


# CloudFlare DDNS的配置
上网找了一圈，全是用第三方集成式的开源项目或者`OpenWRT`里的DDNS模块。
我的需求是：
> 能在`Windows`、`Linux`平台下通跑。
> 无视`CPU`平台限制。
> 强调在低性能的`Linux`平台下的高运行效率。
> 使用配置文件进行`DDNS`，不能把用户信息写死进脚本里。

最终决定使用`Shell`和`Python`各编写一份，`Linux`平台下用`Shell`，`Windows`下用`Python`。
在编写时参考了[wherelse/cloudflare-ddns-script](https://github.com/wherelse/cloudflare-ddns-script)的脚本。

第一次运行时，会在脚本同级目录下生成`config.txt`，向里面填写你的个人信息，然后重新运行即可。**`Python`版和`Shell`版的配置文件通用！**

配置文件填写参考这里:
``` Text
cf_email_addr=a@b.c  # cloudFlare注册账户邮箱
cf_global_api_key=1145141919810   # 你的cloudflare账户Globel API Key
domain_main=example.com   # 你的主域名, 如example.com
domain_full_ddns=ddnsv6.example.com # ddns用的完整域名, 如ddns.example.com
record_type=AAAA             # A or AAAA,ipv4 或 ipv6解析
eth_card=eth0             # 使用本地方式获取ip绑定的网卡, 如eth0
ip_index=local            # use "internet" or "local",使用本地方式还是网络方式获取地址
reset_ip=0 # 1为将ddns的ip改为localhost，2为手动输入ip，其他任意值为不是
enable_cache=0              # 1为保存缓存文件,其他任意值为不保存。保存缓存文件可让下次ddns更新速度更快，但缓存文件泄漏需要你去把cf_global_api_key重新revoke一次，不然会造成隐私泄漏
skip_connectivity_check=0 # 0为不跳过脚本最开始运行的时候的检查连接
ip_file=ip.txt            # 保存地址信息
id_file=cloudflare.ids
log_file=cloudflare.log
```

这是最终的`Shell`脚本：
``` Shell
#!/bin/bash

# CHANGE THESE
cf_email_addr=""  # cloudFlare注册账户邮箱
cf_global_api_key=""   # 你的cloudflare账户Globel API Key
domain_main=""   # 你的主域名, 如google.com
domain_full_ddns="" # ddns用的完整域名, 如ddns.google.com
record_type=""             # A or AAAA,ipv4 或 ipv6解析

eth_card=""             # 使用本地方式获取ip绑定的网卡, 如eth0
ip_index="local"            # use "internet" or "local",使用本地方式还是网络方式获取地址

reset_ip=0 # 1为将ddns的ip改为localhost，2为手动输入ip，其他任意值为不是
enable_cache="0"              # 1为保存缓存文件,其他任意值为不保存。保存缓存文件可让下次ddns更新速度更快，但缓存文件泄漏需要你去把cf_global_api_key重新revoke一次，不然会造成隐私泄漏
skip_connectivity_check="0" # 0为不跳过脚本最开始运行的时候的检查连接
ip_file="ip.txt"            # 保存地址信息
id_file="cloudflare.ids"
log_file="cloudflare.log"

# 默认配置。需要和上面的变量顺序相同
default_config_arr=("","","","","","","local","0","0","0","ip.txt","cloudflare.ids","cloudflare.log")
config_file="config.txt"

create_default_config_file() {
    echo "cf_email_addr=" >> $config_file
    echo "cf_global_api_key=" >> $config_file
    echo "domain_main=" >> $config_file
    echo "domain_full_ddns=" >> $config_file
    echo "record_type=" >> $config_file
    echo "eth_card=" >> $config_file
    echo "ip_index=local" >> $config_file
    echo "reset_ip=0" >> $config_file
    echo "enable_cache=0" >> $config_file
    echo "skip_connectivity_check" >> $config_file
    echo "ip_file=ip.txt" >> $config_file
    echo "id_file=cloudflare.ids" >> $config_file
    echo "log_file=cloudflare.log" >> $config_file
}



# 声明日志函数
log() {
    if [ "$1" ]; then
        if [ "$enable_cache" -eq "1" ]; then
            echo -e "[$(date)] - $1" >> $log_file
        fi
        echo "[$(date)] - $1"
    fi
}
log "Init config"


# 初始化配置文件

if [ -e "$config_file" ]; then
    log "File $config_file exists."
else
    log "File $config_file does not exist."
    create_default_config_file
    log "请将该配置文件填写完成:${config_file}"
    exit 1
fi

read_config_key() {
    key=$1
    value=$(grep "^${key}=" $config_file | cut -d'=' -f2)
    echo $value
}

cf_email_addr=$(read_config_key "cf_email_addr")
cf_global_api_key=$(read_config_key "cf_global_api_key")
domain_main=$(read_config_key "domain_main")
domain_full_ddns=$(read_config_key "domain_full_ddns")
record_type=$(read_config_key "record_type")
eth_card=$(read_config_key "eth_card")
ip_index=$(read_config_key "ip_index")
reset_ip=$(read_config_key "reset_ip")
enable_cache=$(read_config_key "enable_cache")
skip_connectivity_check=$(read_config_key "skip_connectivity_check")
ip_file=$(read_config_key "ip_file")
id_file=$(read_config_key "id_file")
log_file=$(read_config_key "log_file")


# 检查配置文件是否存在以及是否有进行填写
got_config=()
got_config+=${cf_email_addr}
got_config+=${cf_global_api_key}
got_config+=${domain_main}
got_config+=${domain_full_ddns}
got_config+=${record_type}
got_config+=${eth_card}
got_config+=${ip_index}
got_config+=${reset_ip}
got_config+=${enable_cache}
got_config+=${skip_connectivity_check}
got_config+=${ip_file}
got_config+=${id_file}
got_config+=${log_file}


# 将数组默认配置连接成字符串
def_str=""
for element in "${default_config_arr[@]}"
do
    def_str="$def_str$element"
done

# 将获取到的配置连接成字符串
got_str=""
for element in "${got_config[@]}"
do
    got_str="$got_str$element"
done

# 判断字符串是否相等,即用户是否填写了配置文件
if [ "$def_str" = "$got_str" ]; then
    create_default_config_file
    log "请将该配置文件填写完成:${config_file}"
fi

# 检查连接
if [ "$skip_connectivity_check" -eq "0" ]; then
    log "Checking connectivity to Cloudflare"
    # 检查和api.cloudflare.com的连接性
    if curl --connect-timeout 30 -s --head https://api.cloudflare.com/ > /dev/null; then
        log "Successfully connected to api.cloudflare.com"
        # 连接成功，可以在这里继续后续的命令
    else
        log "Error connecting to api.cloudflare.com. Stopping script execution."
        exit 1
    fi
else
    log "Skipping check connectivity to Cloudflare"
fi


# 开始根据读取到的配置进行ddns设置
log "Starting DDNS"
if [ $record_type = "AAAA" ];then
	if [ "$reset_ip" -eq "1" ]; then
		ip="::1"
		log "Reset DDNS address to loopback..."
	elif [ "$reset_ip" -eq "2" ]; then
		read -p "Please enter an AAAA record IP:\n" ip
		log "Got it, now setting DDNS..."
	else
		if [ $ip_index = "internet" ];then
			ip=$(curl -6 ip.sb)
		elif [ $ip_index = "local" ];then
			if [ "$user" = "root" ];then
				ip=$(ifconfig $eth_card | grep 'inet6'| grep -v '::1'|grep -v 'fe80' | cut -f2 | awk '{ print $2}' | head -1)
			else
				ip=$(/sbin/ifconfig $eth_card | grep 'inet6'| grep -v '::1'|grep -v 'fe80' | cut -f2 | awk '{ print $2}' | head -1)
			fi
		else
			log "Error IP index, please input the right type"
			exit 0
		fi
	fi
elif [ $record_type = "A" ];then
	if [ "$enable_cache" -eq "1" ]; then
		ip="127.0.0.1"
		log "Reset DDNS address to loopback..."
	elif [ "$reset_ip" -eq "2" ]; then
		read -p "Please enter an A record IP:\n" ip
		log "Got it, now setting DDNS..."
	else
		if [ $ip_index = "internet" ];then
			ip=$(curl -4 ip.sb)
		elif [ $ip_index = "local" ];then
			if [ "$user" = "root" ];then
				ip=$(ifconfig $eth_card | grep 'inet'| grep -v '127.0.0.1' | grep -v 'inet6'|cut -f2 | awk '{ print $2}')
			else
				ip=$(/sbin/ifconfig $eth_card | grep 'inet'| grep -v '127.0.0.1' | grep -v 'inet6'|cut -f2 | awk '{ print $2}')
			fi
		else
			log "Error IP index, please input the right type"
			exit 0
		fi
	fi
else
    log "Error DNS type"
    exit 0
fi

# SCRIPT START
log "Check Initiated"
log "Your ip is:    ${ip}"

# 判断ip是否发生变化
if [ "$enable_cache" -eq "1" ]; then
    if [ -f $ip_file ]; then
        old_ip=$(cat $ip_file)
        if [ $ip == $old_ip ]; then
            log "IP has not changed."
            exit 0
        fi
    fi
fi


# 获取域名和授权

if [ "$enable_cache" -eq "1" ]; then
    if [ -f $id_file ] && [ $(wc -l $id_file | cut -d " " -f 1) == 2 ]; then
        zone_identifier=$(head -1 $id_file)
        record_identifier=$(tail -1 $id_file)
    else
        zone_identifier=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$domain_main" \
            -H "X-Auth-Email: $cf_email_addr" \
            -H "X-Auth-Key: $cf_global_api_key" \
            -H "Content-Type: application/json" | grep -Po '(?<="id":")[^"]*' | head -1 )
        record_identifier=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$zone_identifier/dns_records?type=${record_type}&name=$domain_full_ddns" \
            -H "X-Auth-Email: $cf_email_addr" \
            -H "X-Auth-Key: $cf_global_api_key" \
            -H "Content-Type: application/json"  | grep -Po '(?<="id":")[^"]*')
        log "$zone_identifier" > $id_file
        log "$record_identifier" >> $id_file
    fi
else
    zone_identifier=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$domain_main" \
        -H "X-Auth-Email: $cf_email_addr" \
        -H "X-Auth-Key: $cf_global_api_key" \
        -H "Content-Type: application/json" | grep -Po '(?<="id":")[^"]*' | head -1 )
    record_identifier=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$zone_identifier/dns_records?type=${record_type}&name=$domain_full_ddns" \
        -H "X-Auth-Email: $cf_email_addr" \
        -H "X-Auth-Key: $cf_global_api_key" \
        -H "Content-Type: application/json"  | grep -Po '(?<="id":")[^"]*')
fi



# 更新DNS记录
update=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$zone_identifier/dns_records/$record_identifier" \
    -H "X-Auth-Email: $cf_email_addr" \
    -H "X-Auth-Key: $cf_global_api_key" \
    -H "Content-Type: application/json" \
    --data "{\"type\":\"$record_type\",\"name\":\"$domain_full_ddns\",\"content\":\"$ip\",\"ttl\":1,\"proxied\":false}")


# 输出DDNS更新情况
if [[ $update == *"\"success\":true"* ]]; then
    message="$domain_full_ddns -> $ip"
    if [ "$enable_cache" -eq "1" ]; then
        echo "$message" > $ip_file
    fi
    log message
else
    message="API UPDATE FAILED. DUMPING RESULTS:\n$update"
    log "$message"
    exit 1
fi
```


``` Python
import requests
import os
import sys
import datetime
import platform
import subprocess
import re

# 需要先安装以下pip包才能运行:
# requests

# 配置变量
cf_email_addr = ""  # CloudFlare注册账户邮箱
cf_global_api_key = ""  # 你的Cloudflare账户Global API Key
domain_main = ""  # 你的主域名, 如google.com
domain_full_ddns = ""  # ddns用的完整域名, 如ddns.google.com
record_type = "AAAA"  # A or AAAA, ipv4 或 ipv6解析

eth_card = ""  # 使用本地方式获取IP绑定的网卡, 如eth0。此设置项只在linux上生效
ip_index = "local"  # 使用 "internet" 或 "local", 获取地址的方式

reset_ip = 0 # 1为将ddns的ip改为localhost，2为手动输入ip，其他任意值为不是
enable_cache = 0  # 1为保存缓存文件，其他任意值为不保存缓存文件
skip_connectivity_check = 0 # 0为不跳过脚本最开始运行的时候的检查连接
ip_file = "ip.txt"  # 保存地址信息的文件
id_file = "cloudflare.ids"
log_file = "cloudflare.log"


# 按照这个格式填入config.txt
example_config_file = {
  "cf_email_addr": "", # CloudFlare注册账户邮箱
  "cf_global_api_key": "", # 你的Cloudflare账户Global API Key
  "domain_main": "", # 你的主域名, 如google.com
  "domain_full_ddns": "", # ddns用的完整域名, 如ddns.google.com
  "record_type": "", # A or AAAA, ipv4 或 ipv6解析
  "eth_card": "", # 使用本地方式获取IP绑定的网卡, 如eth0。此设置项只在linux上生效
  "ip_index": "local", # 使用 "internet" 或 "local", 获取地址的方式。internal不支持获取ipv4地址
  "reset_ip": 0, # 1为将ddns的ip改为localhost，其他任意值为不是
  "enable_cache": 0, # 1为保存缓存文件，其他任意值为不保存缓存文件
  "skip_connectivity_check": 0,# 0为不跳过脚本最开始运行的时候的检查连接
  "ip_file": "ip.txt", # 不需要填写
  "id_file": "cloudflare.ids", # 不需要填写
  "log_file": "cloudflare.log" # 不需要填写
}

def log(message):
    """日志函数"""
    if message:
        if enable_cache == 1:
            with open(log_file, 'a') as f:
                f.write(f"[{datetime.datetime.now()}] - {message}\n")
        else:
            print(f"[{datetime.datetime.now()}] - {message}")


def init_value():
    global cf_email_addr, cf_global_api_key, domain_main, domain_full_ddns, record_type, eth_card, skip_connectivity_check, ip_index, reset_ip, enable_cache, ip_file, id_file, og_file
    config_dict = {}
    script_dir = os.path.dirname(os.path.abspath(__file__))
    config_path = os.path.join(script_dir, "config.txt")
    try:
        with open(config_path, 'r', encoding='utf-8') as file:
            for line in file:
                line = line.strip()
                if line and '=' in line:
                    key, value = line.split('=', 1)
                    config_dict[key] = value
            common_keys = set(config_dict.keys()) & set(example_config_file.keys())
            different_values = {}
            for key in common_keys:
                if config_dict[key] != example_config_file[key]:
                    different_values[key] = (config_dict[key], example_config_file[key])
            if len(different_values) == 0:
                print(f"请将该配置文件填写完成:{config_path}")
                sys.exit()
            log("File config.txt exists.")
            cf_email_addr = config_dict.get('cf_email_addr')
            cf_global_api_key = config_dict.get('cf_global_api_key')
            domain_main = config_dict.get('domain_main')
            domain_full_ddns = config_dict.get('domain_full_ddns')
            record_type = config_dict.get('record_type')
            eth_card = config_dict.get('eth_card')
            ip_index = config_dict.get('ip_index')
            reset_ip = int(config_dict.get('reset_ip'))
            enable_cache = int(config_dict.get('enable_cache'))
            skip_connectivity_check = int(config_dict.get('skip_connectivity_check'))
            ip_file = config_dict.get('ip_file')
            id_file = config_dict.get('id_file')
            log_file = config_dict.get('log_file')
    except FileNotFoundError:
        with open(config_path, 'w', encoding='utf-8') as file:
            for key, value in example_config_file.items():
                file.write(f'{key}={value}\n')
            #json.dump(example_config_file, file, ensure_ascii=False, indent=4)
        print(f"请将该配置文件填写完成:{config_path}")
        sys.exit()

def get_ipv6_address_windows():
    """在Windows上获取临时IPv6地址"""
    try:
        # 执行ipconfig命令并捕获输出
        output = subprocess.check_output(["ipconfig"], text=True)
        # 使用正则表达式查找临时IPv6地址
        match = re.search(r"临时 IPv6 地址.*: ([a-fA-F0-9:]+)", output)
        if match:
            return match.group(1)
        else:
            return None
    except Exception as e:
        print(f"Error: {e}")
        return None

def get_ipv6_address_linux():
    """在Linux上获取Global IPv6地址"""
    try:
        # 执行ip -6 addr show命令并捕获输出
        output = subprocess.check_output(["ip", "-6", "addr", "show", eth_card], text=True)
        # 使用正则表达式查找global scope的IPv6地址
        match = re.search(r"inet6\s+([a-fA-F0-9:]+)/\d+\s+scope global", output)
        if match:
            return match.group(1)
        else:
            return None
    except Exception as e:
        print(f"Error: {e}")
        return None

def get_ipv6_platform():
    if platform.system() == "Windows":
        return get_ipv6_address_windows()
    elif platform.system() == "Linux":
        return get_ipv6_address_linux()
    else:
        return None

def get_ip():
    """获取IP地址"""
    if record_type == "AAAA":
        if reset_ip == 1:
            log("Reset DDNS address to loopback...")
            return "::1"
        elif reset_ip == 2:
            ip = input("Please enter an AAAA record IP:\n")
            log("Got it, now setting DDNS...")
            return ip
        else:
            if ip_index == "internet":
                return requests.get('https://api64.ipify.org?format=json').json()['ip']
            elif ip_index == "local":
                return get_ipv6_platform()
                pass
    elif record_type == "A":
        if reset_ip == 1:
            log("Reset DDNS address to loopback...")
            return "127.0.0.1"
        elif reset_ip == 2:
            ip = input("Please enter an A record IP:\n")
            log("Got it, now setting DDNS...")
            return ip
        else:
            if ip_index == "internet":
                return requests.get('https://api.ipify.org?format=json').json()['ip']
            elif ip_index == "local":
                # 这里需要自行实现本地获取IPv4地址的逻辑
                pass
    else:
        log("Error DNS type")
        exit(0)

def update_cloudflare_dns(ip):
    """更新Cloudflare DNS记录"""
    headers = {
        "X-Auth-Email": cf_email_addr,
        "X-Auth-Key": cf_global_api_key,
        "Content-Type": "application/json",
    }
    # 获取Zone ID
    zone_response = requests.get(f"https://api.cloudflare.com/client/v4/zones?name={domain_main}", headers=headers)
    zone_id = zone_response.json()['result'][0]['id']

    # 获取DNS记录ID
    dns_response = requests.get(f"https://api.cloudflare.com/client/v4/zones/{zone_id}/dns_records?type={record_type}&name={domain_full_ddns}", headers=headers)
    dns_record_id = dns_response.json()['result'][0]['id']

    # 更新DNS记录
    data = {
        "type": record_type,
        "name": domain_full_ddns,
        "content": ip,
        "ttl": 1,
        "proxied": False
    }
    update_response = requests.put(f"https://api.cloudflare.com/client/v4/zones/{zone_id}/dns_records/{dns_record_id}", headers=headers, json=data)
    return update_response.json()



# 主逻辑
log("Init config")
init_value()
log("Starting DDNS")
if skip_connectivity_check == 0:
    # 检查连接性
    log("Checking connectivity to cloudflare")
    try:
        response = requests.get("https://api.cloudflare.com", timeout=30)
        # 如果请求成功，状态码为200
        if response.ok:
            log("Successfully connected to https://api.cloudflare.com")
        else:
            log("Connected to https://api.cloudflare.com but received a non-success status code:", response.status_code)
    except requests.exceptions.RequestException as e:
        # 处理连接错误
        log("Error connecting to https://api.cloudflare.com")
        log(e)
        sys.exit()
    except requests.exceptions.Timeout:
        # 处理连接超时
        log("Timeout connecting to https://api.cloudflare.com")
        log(e)
        sys.exit()
    log("Check Initiated")
else:
    log("Skipping check connectivity to Cloudflare")

# 获取IP地址
ip = get_ip()
log(f"Your ip is:    {ip}")

# 判断IP是否发生变化
old_ip = None
if enable_cache == 1 and os.path.exists(ip_file):
    with open(ip_file) as f:
        old_ip = f.read().strip()
if ip == old_ip:
    if ip == None:
        log("Check your Internet connection.")
    else:
        log("IP has not changed.")
    exit(0)

# 更新DNS记录
update_result = update_cloudflare_dns(ip)
if update_result['success']:
    message = f"Now {domain_full_ddns} -> {ip}"
    if enable_cache == 1:
        with open(ip_file, 'w') as f:
            f.write(message)
    log(message)
else:
    message = f"API UPDATE FAILED. DUMPING RESULTS:\n{update_result}"
    log(message)
    exit(1)
```



# Linux设备上的防火墙
既然有了公网`ipv6`地址，则不需要跳板机了，需要在终端上配置防火墙。


我用的是`UFW`作为我的防火墙。相关的教程直接上[ArchWiki](https://wiki.archlinux.org/title/Uncomplicated_Firewall)翻，写的很详细。
先启用`ipv6`下的`ufw`：将`/etc/default/ufw`下的`IPV6`值改为`yes`
基操，先禁个`Ping`：
`ipv6`的`Ping`：将`/etc/ufw/before6.rules`中的`-A ufw6-before-input -p icmpv6 --icmpv6-type echo-request -j ACCEPT`最后改为`DROP`
`ipv4`的`Ping`：将`/etc/ufw/before.rules`中的`-A ufw-before-input -p icmp --icmp-type echo-request -j ACCEPT`最后改为`DROP`
~~*无脑方法：把配置文件中所有有关`icmp`的`echo-request`全改成`DROP`*~~

放通`KDE Connect`:
根据官方[文档](https://userbase.kde.org/KDEConnect)所写，需要放通1714-1764的`UDP`和`TCP`端口。
``` Shell
sudo ufw allow 1714:1764/udp
sudo ufw allow 1714:1764/tcp
```

放通`Syncthing`:
直接把软件添加到白名单即可。
``` Shell
sudo ufw allow syncthing
```

