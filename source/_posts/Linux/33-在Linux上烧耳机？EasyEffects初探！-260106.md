---
title: 在Linux上烧耳机？EasyEffects初探！
category: Linux
date: 2026-01-06 00:00:00
updated: 2026-01-06 00:00:00
index_img: https://wwmm.github.io/easyeffects/images/com.github.wwmm.easyeffects.svg
---


 ![封面](https://wwmm.github.io/easyeffects/images/com.github.wwmm.easyeffects.svg)
(封面图源[EasyEffects主页](https://wwmm.github.io/easyeffects/))


# ~~*这是一篇大水文*~~
~~*一入耳机深似海，早知当初买原道*~~


[这是项目官方的仓库](https://github.com/wwmm/easyeffects)。


# 安装
安装起来十分简单啊，直接一行命令就行了：
``` shell
sudo pacman -S easyeffects ladspa-plugins lsp-plugins calf mda.lv2
```
后面几个都是调音效要用的的插件，`ladspa-plugins`和`lsp-plugins`是给`Equalizer`用的，`calf`和`mda.lv2`是给低音增强用的。

