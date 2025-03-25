---
title: macOS安装Homebrew记录
category: Linux
date: 2024-06-11 18:00:00
index_img: https://brew.sh/assets/img/homebrew.svg
---

![封面](https://brew.sh/assets/img/homebrew.svg)

我是先装了个`oh-my-zsh`然后进行操作的，安装步骤参考上一篇文章，和Linux下的安装过程可以说是几乎一模一样。

先换源：添加环境变量
``` shell
export HOMEBREW_INSTALL_FROM_API=1
export HOMEBREW_API_DOMAIN="https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles/api"
export HOMEBREW_BOTTLE_DOMAIN="https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles"
export HOMEBREW_BREW_GIT_REMOTE="https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/brew.git"
export HOMEBREW_CORE_GIT_REMOTE="https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/homebrew-core.git"
```

然后通过清华源进行安装：
``` shell
git clone --depth=1 https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/install.git brew-install
./brew-install/install.sh
```

然后`brew-install`文件夹可以删除了，用不上了。

后续如果要用清华源来下载的话，把上面的环境变量添加到`.zshrc`里就行了。