---
title: Surface3装Linux踩坑记录
category: Linux
date: 2023-10-31 18:00:00
index_img: https://tse4-mm.cn.bing.net/th/id/OIP-C.umuhtu_JjocMMbT7mMA4wgHaEK?pid=ImgDet&dpr=2.8
---

![封面](https://tse4-mm.cn.bing.net/th/id/OIP-C.umuhtu_JjocMMbT7mMA4wgHaEK?pid=ImgDet&dpr=2.8)

~~对没错，写完Surface Go 3的文又来Surface 3这里凑个热闹（~~

同学的老款苏菲装Linux重获新生！
``` text
4GB RAM,128GB EMMC
英特尔Atom Z8700处理器
4c4t,基频1.6GHz,睿频2.4GHz
最大TDP才2瓦！！！这么低！！！！！
```


> "卧槽你的苏菲怎么续航能撑一天？大佬怎么优化的教教我"
> “[英特尔Atom处理器](https://www.intel.cn/content/www/cn/zh/products/sku/85475/intel-atom-x7z8700-processor-2m-cache-up-to-2-40-ghz/specifications.html)，tdp两瓦”
> “啊那没事了”

但是这东西装好系统之后缺驱动怎么办？
换一个[linux-surface](https://github.com/linux-surface/linux-surface/)内核就行~
按照官方[教程](https://github.com/linux-surface/linux-surface/wiki/Installation-and-Setup)走就OK

# Debian
```bash
# 加仓库证书
wget -qO - https://raw.githubusercontent.com/linux-surface/linux-surface/master/pkg/keys/surface.asc \
    | gpg --dearmor | sudo dd of=/etc/apt/trusted.gpg.d/linux-surface.gpg
# 添加仓库
echo "deb [arch=amd64] https://pkg.surfacelinux.com/debian release main" \
	| sudo tee /etc/apt/sources.list.d/linux-surface.list
# 同步软件源
sudo apt update
# 安装内核及触碰驱动
sudo apt install linux-image-surface linux-headers-surface libwacom-surface iptsd
# 更新grub
sudo update-grub
```
WiFi驱动：安装`firmware-libertas`然后重启系统。（[来源](https://www.2foo.net/howto-surface-3-on-debian-linux/)）



# Arch Linux
加仓库证书
```bash
curl -s https://raw.githubusercontent.com/linux-surface/linux-surface/master/pkg/keys/surface.asc \
    | sudo pacman-key --add -
sudo pacman-key --finger 56C464BAAC421453
sudo pacman-key --lsign-key 56C464BAAC421453
```
在`/etc/pacman.conf`中添加仓库
```bash
[linux-surface]
Server = https://pkg.surfacelinux.com/arch/
```
更新源并安装内核和触屏驱动
```bash
sudo pacman -Syu
sudo pacman -S linux-surface linux-surface-headers iptsd
```
更新grub
```bash
sudo grub-mkconfig -o /boot/grub/grub.cfg
```

