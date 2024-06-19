---
title: 记一次未完成的Android编译....
category: 其他的开发杂记
date: 2024-01-25 18:00:00
index_img: https://tse1-mm.cn.bing.net/th/id/OIP-C.PXi-K-Ym4EAqkcjluImyBAHaD-?w=276&h=180&c=7&r=0&o=5&dpr=1.3&pid=1.7
---


![封面](https://tse1-mm.cn.bing.net/th/id/OIP-C.PXi-K-Ym4EAqkcjluImyBAHaD-?w=276&h=180&c=7&r=0&o=5&dpr=1.3&pid=1.7)


# 前情提要
这是一台“过时”的华为平板，搭载高通616处理器，3+16GB存储组合，10.1英尺1920x1200屏幕。
***⚠️万字长文预警***


# 硬件和软件环境
我用的是平时拿来干活的笔记本。硬件方面：`i5-10300H`的处理器，`16GB 2933MHz`的主存，编译环境用的硬盘是`Samsung Evo 870 1TB`；软件方面：采用`Debian 12`系统。~~*主要是Ubuntu太臃肿了*~~



# 装依赖
## Part 1: 下载和解压
第一个要装的就是`adb`和`fastboot`。
> ⚠️ 注意！不要去`apt`源里下载，那里的版本太老了。前往谷歌官方下载：`https://dl.google.com/android/repository/platform-tools-latest-linux.zip`

按照`Lineage`官方的[说法\(这一部分不分机型，都是通的，所以这个超链接指向了小米8的页面\)](https://wiki.lineageos.org/devices/dipper/build/#prepare-the-device-specific-code)，把他解压到`~`下吧：
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
然后，`source`它，然后`echo $PATH`一下看看环境变量里是否存在`~/platform-tools`，存在就可以进行下一步。


## Part 2: 从apt源安装
使用apt把这些都装进去：`bc bison build-essential ccache curl flex g++-multilib gcc-multilib git git-lfs gnupg gperf imagemagick lib32readline-dev lib32z1-dev libelf-dev liblz4-tool libsdl1.2-dev libssl-dev libxml2 libxml2-utils lzop pngcrush rsync schedtool squashfs-tools xsltproc zip zlib1g-dev`
对于我使用的`Debian 12`系统，再安装这些:`lib32ncurses-dev libncurses5 libncurses5-dev`

对于`Ubuntu`用户，请按照`Lineage`官网说法进行操作：
``` text
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
`OpenJDK`的版本取决于你想要编译的`Lineage OS`版本。
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



# 处理源码


## 初始化仓库
> ⚠️ 这个过程需要保证网络绝对畅通

``` bash
repo init -u https://mirrors.tuna.tsinghua.edu.cn/git/lineageOS/LineageOS/android.git -b lineage-20.0 --git-lfs
```
参数`-b`后面接的是系统版本，前往[这里](https://github.com/LineageOS/android/tree/lineage-20.0)查看可以选择哪些分支版本。其中`lineage-16.0`对应`Android 9`，后续`los`版本号整数加一对应`Android`版本号的整数加一，比如`lineage-17.0`对应`Android 10`。


## 将仓库源码地址设为国内镜像站
这里用清华源
打开.repo/manifests/default.xml，将
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


## 同步源码树
以后都使用这个来同步。这会从清华服务器上下载源码而非Lineage官网下载
``` bash
# Use default thread and branch parameters, which is "-j 4 -c" here.
repo sync
# Use custom parameters, which means use 2 threads to sync.
repo sync -j2
```
> 注意: 这个命令默认添加参数`-j 4 -c`。其中`-j 4`代表使用四线程进行同步。如果你遇到了服务器对线程的限制或性能问题，手动添加该参数以降低线程数，像第二行。
> `-c`代表着只克隆上一步选定的分支而非所有分支。**该参数不建议进行人为额外操作**。



## 处理设备配置文件
> ~~我要编译的设备不在`Lineage`的[官方维护列表](https://wiki.lineageos.org/devices/)内，所以需要自己配置配置文件。如果你的设备在官方维护列表内，可以跳过这一步。~~

在`~/android/lineage/.repo/local_manifests/`下创建文件`federer.xml`
> `federer`是我设备的代号，这里也可以填写别的名字作为代号，主要就是区分设备用

写入以下信息:
``` xml
<?xml version="1.0" encoding="UTF-8"?>
<manifest>
    <remote name="vendor" fetch="https://github.com" revision="la-17.1" />
    <remote name="device" fetch="https://github.com" revision="la-17.1"/>
    <remote name="device-common" fetch="https://github.com" revision="la-17.1"/>
    <remote name="kernel" fetch="https://github.com" revision="LaOS-15.1"/>
    <remote name="kernel-common" fetch="https://github.com" revision="la-17.1"/>
    <remote name="sepolicy_legacy" fetch="https://github.com" revision="lineage-20.0"/>
    <!-- Vendor folders -->
    <project path="vendor/huawei/federer" name="datenpanne/android_vendor_huawei_federer" remote="vendor" />
    <!--Device Trees-->
    <project path="device/huawei/federer" name="datenpanne/android_device_huawei_federer" remote="device" />
    <project path="device/huawei/t2-common" name="datenpanne/android_device_huawei_t2-common" remote="device-common" />
    <!--Kernel-->
    <project path="kernel/huawei/federer" name="datenpanne/android_kernel_huawei_federer" remote="kernel" />
    <project path="kernel/huawei/federer" name="datenpanne/android_kernel_huawei_t2-common" remote="kernel-common" />
    <!--SePolicy Legacy. I tried to compile but throw an error to me said about I don't have these files. I searched on Bing and found this repository, then I add it here. For other devices, you don't need to add this .-->
    <project path="device/qcom/sepolicy-legacy" name="LineageOS/android_device_qcom_sepolicy" remote="sepolicy_legacy" />
</manifest>
```
其中`remote`字段中的`fetch`字段意思是该代码托管的提供商名。如果你的代码也托管在`Github`上，则无需修改该字段。
其中`remote`字段中的`revision`字段意思是该代码在仓库里的分支名。
其中`project`字段中的`path`字段意为存放该源码的本地位置，。
其中`project`字段中的`name`字段意为仓库链接去掉`https://github.com`之后剩下的，即`作者/仓库名`。


然后再次进行`repo sync`一下，以下载设备树、内核源码等信息。
> ⚠️ 注意：如果提示sync失败，则多次使用`repo sync -j1 --fail-fast`重试。
> 注意xml的格式化问题，不然sync会报错。比如xml最开头的字符不是`<`而是空格时报如下错误:`error: in \`sync\`: error parsing manifest ~/android/lineage/.repo/local_manifests/federer.xml: XML or text declaration not at start of entity: line 1, column 1`


## 提取设备专属固件
插上已经root了的lineage设备(**一定要是你即将编译的设备，比如我的是华为Federer-A01w**)，终端前往`~/android/lineage/device/huawei/federer`文件夹，运行当前目录下的`./extract-files.sh`
> 如果提示`Unable to find helper script at ./../../../vendor/lineage/build/tools/extract_utils.sh`则前往`~/android/lineage/vendor/lineage/build/tools`，将`https://github.com/LineageOS/android_tools_extract-utils`下的所有文件全部下载到这个文件夹，保证`~/android/lineage/vendor/lineage/build/tools`文件夹下有`extract_utils.sh`脚本，再回去重新运行`./extract-files.sh`

> 如果一直没有弹出授权提示，并且手动`adb devices`提示`(missing udev rules? user is in the plugdev group); see [http://developer.android.com/tools/device.html]`，则先将你的用户组添加入`plugdev`然后安装`android-sdk-platform-tools-common`。具体操作如下：
``` bash
sudo usermod -aG plugdev $LOGNAME
sudo apt-get install android-sdk-platform-tools-common
```
然后**重启电脑**。再次`adb devices`，设备上就会弹出授权弹窗了。回到`~/android/lineage/device/huawei/federer`再次执行`./extract-files.sh`


# 编译

## 选择默认内核编译配置文件
在进行内核编译的时候，总要选择一个内核配置文件，也就是`defconfig`。通常在内核源码目录`/arch/arm64/configs`文件夹下，然后内核源码在lineage工程文件夹下的目录是`~/android/lineage/kernel/huawei/federer/`。
将你要用的`defconfig`记下，打开`device/huawei/federer/BoardConfig.mk`，找到(如果没有就新建)`TARGET_KERNEL_CONFIG`字段，将`defconfig`文件名作为字段值填入。最终可以找到这么一行信息：
``` makefile
TARGET_KERNEL_CONFIG := merge_hi6250_defconfig
```
同样的，设置`TARGET_KERNEL_SOURCE`指向内核源码所在目录：
``` makefile
TARGET_KERNEL_SOURCE := kernel/huawei/federer
```




## 准备开始编译
进入`~/android/lineage`文件夹。
进行最后的环境准备：`source build/envsetup.sh`
选择要编译的设备：`lunch`
然后会有一个设备列表，像这样：
``` text
     ...
     27. lineage_federer-eng
     28. lineage_federer-userdebug
     ...
     Which would you like? [aosp_arm-eng]
```
像我的设备，刚刚创建的是`federer`,那就选27或者28都行。


## 开始编译！
> ⚠️⚠️警告: 如果你的电脑和我一样只有`16GB`物理内存的话，请一定要**开启**`SWAP`，否则会编到一半爆内存卡死，等待你的只有强制重启。
> 我的电脑`SWAP`给了`16GB`, 启用了`ZRAM`

``` bash
croot
brunch federer
```






## 我遇到的一些问题

### Problem 1
> include path缺失：system/core/base/include/android-base/

我从~~咕噜咕噜~~Google的AOSP源仓库里下载了这个文件。访问[这里](https://android.googlesource.com/platform/system/core/+/c0e6e40/base/include/android-base)，然后你能在屏幕顶上看到一个`tgz`按钮，点它然后下载，再在你的本地los工作目录里创建这个文件夹：`~/android/lineage/system/core/base/include/android-base/`，把压缩包里的文件全丢进去，再重新编译~~等待下一个报错~~。


### Problem 2
> device/huawei/federer/sensors/Android.mk: error: sensors.msm8916: LOCAL_COPY_HEADERS is obsolete. See https://android.googlesource.com/platform/build/+/master/Changes.md#copy_headers

参见[此issue](https://github.com/crdroidandroid/android/issues/57)
这是makefile语法过时问题。打开`/home/android233/android/lineage/device/huawei/federer/BoardConfigCommon.mk`，在最前面添加`BUILD_BROKEN_USES_BUILD_COPY_HEADERS := true`
~~
打开`device/huawei/federer/sensors/Android.mk`，将以下部分
``` makefile
# Export calibration library needed dependency headers
LOCAL_COPY_HEADERS_TO := sensors/inc
LOCAL_COPY_HEADERS := 	\
		CalibrationModule.h \
		sensors_extension.h \
		sensors.h
```
替换为
```makefile
# Export calibration library needed dependency headers
LOCAL_COPY_HEADERS_TO := sensors/inc
LOCAL_EXPORT_C_INCLUDES := $(LOCAL_PATH)
```
~~


### Problem 3
> device/huawei/t2-common/camera/QCamera2/stack/mm-camera-interface/Android.mk: error: libmmcamera_interface: LOCAL_COPY_HEADERS is obsolete. See https://android.googlesource.com/platform/build/+/master/Changes.md#copy_headers

问题与[Problem 2](#problem-2)重复。这是makefile语法过时问题。打开`/home/android233/android/lineage/device/huawei/t2-common/BoardConfigCommon.mk`，在最前面添加`BUILD_BROKEN_USES_BUILD_COPY_HEADERS := true`
~~
打开`device/huawei/t2-common/camera/QCamera2/stack/mm-camera-interface/Android.mk`，将以下部分
``` makefile
LOCAL_COPY_HEADERS_TO := mm-camera-interface
LOCAL_COPY_HEADERS += ../common/cam_intf.h
LOCAL_COPY_HEADERS += ../common/cam_types.h
```
修改为
``` makefile
LOCAL_COPY_HEADERS_TO := mm-camera-interface
LOCAL_EXPORT_C_INCLUDES += $(LOCAL_PATH)/../common
```
~~


### Problem 4
> device/huawei/t2-common/gps/core/Android.mk: error: libloc_core: LOCAL_COPY_HEADERS is obsolete. See https://android.googlesource.com/platform/build/+/master/Changes.md#copy_headers

问题与[Problem 2](#problem-2)重复。打开`/home/android233/android/lineage/device/huawei/federer/BoardConfigCommon.mk`，在最前面添加`BUILD_BROKEN_USES_BUILD_COPY_HEADERS := true`
~~
这是makefile语法过时问题。
打开`device/huawei/t2-common/gps/core/Android.mk`，将以下部分
``` makefile
LOCAL_COPY_HEADERS:= \
    LocApiBase.h \
    LocAdapterBase.h \
    ContextBase.h \
    LocDualContext.h \
    LBSProxyBase.h \
    UlpProxyBase.h \
    gps_extended_c.h \
    gps_extended.h \
    loc_core_log.h \
    LocAdapterProxyBase.h
```
修改为
``` makefile
LOCAL_EXPORT_C_INCLUDES := $(LOCAL_PATH)
```
~~


### Problem 5
> device/huawei/t2-common/gps/loc_api/libloc_api_50001/Android.mk: error: libloc_eng: LOCAL_COPY_HEADERS is obsolete. See https://android.googlesource.com/platform/build/+/master/Changes.md#copy_headers

问题与[Problem 2](#problem-2)重复。打开`/home/android233/android/lineage/device/huawei/t2-common/BoardConfigCommon.mk`，在最前面添加`BUILD_BROKEN_USES_BUILD_COPY_HEADERS := true`
~~
这是makefile语法过时问题。
打开`device/huawei/t2-common/gps/loc_api/libloc_api_50001/Android.mk`，将以下部分
``` makefile
LOCAL_COPY_HEADERS:= \
   LocEngAdapter.h \
   loc.h \
   loc_eng.h \
   loc_eng_xtra.h \
   loc_eng_ni.h \
   loc_eng_agps.h \
   loc_eng_msg.h \
   loc_eng_log.h
```
修改为
``` makefile
LOCAL_EXPORT_C_INCLUDES := $(LOCAL_PATH)
```
~~


### Problem 6
> device/huawei/t2-common/gps/utils/Android.mk: error: libgps.utils: LOCAL_COPY_HEADERS is obsolete. See https://android.googlesource.com/platform/build/+/master/Changes.md#copy_headers

问题与[Problem 2](#problem-2)重复。打开`/home/android233/android/lineage/device/huawei/t2-common/BoardConfigCommon.mk`，在最前面添加`BUILD_BROKEN_USES_BUILD_COPY_HEADERS := true`
这是makefile语法过时问题。
打开`device/huawei/t2-common/gps/utils/Android.mk`，将以下部分
``` makefile
LOCAL_COPY_HEADERS:= \
   loc_log.h \
   loc_cfg.h \
   log_util.h \
   linked_list.h \
   msg_q.h \
   MsgTask.h \
   LocHeap.h \
   LocThread.h \
   LocTimer.h \
   loc_target.h \
   loc_timer.h \
   LocSharedLock.h \
   platform_lib_abstractions/platform_lib_includes.h \
   platform_lib_abstractions/platform_lib_time.h \
   platform_lib_abstractions/platform_lib_macros.h \
   loc_misc_utils.h
```
修改为
``` makefile
LOCAL_EXPORT_C_INCLUDES := $(LOCAL_PATH)
```


### Problem 7
> build/make/core/base_rules.mk:338: error: device/huawei/t2-common/gps/utils: MODULE.TARGET.SHARED_LIBRARIES.android.hidl.base@1.0 already defined by hardware/lineage/compat.

这是被多个makefile重定义的问题。
打开`build/make/core/base_rules.mk`将第338行注释掉，`make clean`一下然后重新编译：
``` makefile
#$(error $(LOCAL_PATH): $(module_id) already defined by $($(module_id)))
```


### Problem 8
> device/huawei/t2-common/mdm-helper/Android.mk: error: libmdmdetect: LOCAL_COPY_HEADERS is obsolete. See https://android.googlesource.com/platform/build/+/master/Changes.md#copy_headers

问题与[Problem 2](#problem-2)重复。这是makefile语法过时问题。打开`/home/android233/android/lineage/device/huawei/t2-common/BoardConfigCommon.mk`，在最前面添加`BUILD_BROKEN_USES_BUILD_COPY_HEADERS := true`
~~
打开`device/huawei/t2-common/mdm-helper/Android.mk`，将以下部分
``` makefile
LOCAL_COPY_HEADERS := libmdmdetect/mdm_detect.h
```
修改为
``` makefile
LOCAL_EXPORT_C_INCLUDES := $(LOCAL_PATH)/libmdmdetect
```
~~


### Problem 9
> device/huawei/t2-common/camera/QCamera2/HAL/Android.mk: error: "camera.msm8916 (SHARED_LIBRARIES android-arm) missing libqdMetaData (SHARED_LIBRARIES android-arm)"
> You can set ALLOW_MISSING_DEPENDENCIES=true in your environment if this is intentional, but that may defer real problems until later in the build.
> device/huawei/t2-common/camera/QCamera2/HAL/Android.mk: error: "camera.msm8916 (SHARED_LIBRARIES android-arm) missing libqservice (SHARED_LIBRARIES android-arm)"
> You can set ALLOW_MISSING_DEPENDENCIES=true in your environment if this is intentional, but that may defer real problems until later in the build.

~~
这是个HAL层高通QCAM2驱动依赖缺失。先按照提示，设置环境变量`export ALLOW_MISSING_DEPENDENCIES=true`忽略此类问题。
打开`device/huawei/t2-common/camera/QCamera2/HAL/Android.mk`，将以下部分
``` makefile
LOCAL_SHARED_LIBRARIES += libqdMetaData libqservice libbinder
```
修改为
``` makefile
LOCAL_SHARED_LIBRARIES += libbinder
```
~~
不能这么做！
经过核查，LineageOS在19.0开始从源码清单里将`msm8916`部分驱动删除了：我们可以从这个[文件](https://github.com/LineageOS/android/blob/lineage-19.0/snippets/lineage.xml)的`74、99、100、101`行看出。我们只需将其补充到`~/android/lineage/.repo/local_manifests/federer.xml`中，然后重新`repo sync`再跑编译即可。
在`/home/android233/android/lineage/hardware/qcom-caf/msm8916/display/libqdutils/Android.mk`的26行，证明了我的说法：
``` makefile
LOCAL_MODULE  := libqdMetaData
```
解决方法：直接往`~/android/lineage/.repo/local_manifests/federer.xml`中添加以下语句：
``` xml
    <linkfile src="os_pickup.mk" dest="hardware/qcom-caf/msm8916/Android.mk" />
    <project path="hardware/qcom-caf/msm8916/audio" name="LineageOS/android_hardware_qcom_audio" groups="qcom,qcom_audio,pdk-qcom" revision="lineage-19.0-caf-msm8916" />
    <project path="hardware/qcom-caf/msm8916/display" name="LineageOS/android_hardware_qcom_display" groups="pdk-qcom,qcom,qcom_display" revision="lineage-19.0-caf-msm8916" />
    <project path="hardware/qcom-caf/msm8916/media" name="LineageOS/android_hardware_qcom_media" groups="qcom,pdk-qcom" revision="lineage-19.0-caf-msm8916" />
```
解决方法：我是修补`~/android/lineage/.repo/manifests/snippets/lineage.xml`实现的：（已弃用，用上面那个方法去。）
108行后添加:
``` xml
<project path="hardware/qcom-caf/msm8916/audio" name="LineageOS/android_hardware_qcom_audio" groups="qcom,qcom_audio,pdk-qcom" revision="lineage-19.0-caf-msm8916" />
<project path="hardware/qcom-caf/msm8916/display" name="LineageOS/android_hardware_qcom_display" groups="pdk-qcom,qcom,qcom_display" revision="lineage-19.0-caf-msm8916" />
<project path="hardware/qcom-caf/msm8916/media" name="LineageOS/android_hardware_qcom_media" groups="qcom,pdk-qcom" revision="lineage-19.0-caf-msm8916" />
```
84行添加
``` xml
<linkfile src="os_pickup.mk" dest="hardware/qcom-caf/msm8916/Android.mk" />
```

**当前正在和作者确认....上面只是我的解决方法。 //TODO**



### Problem 10
> hardware/qcom-caf/msm8916/display/libhwcomposer/../common.mk: error: "hwcomposer.msm8916 (SHARED_LIBRARIES android-arm64) missing libbfqio (SHARED_LIBRARIES android-arm64)"
> You can set ALLOW_MISSING_DEPENDENCIES=true in your environment if this is intentional, but that may defer real problems until later in the build.
> hardware/qcom-caf/msm8916/display/libhwcomposer/../common.mk: error: "hwcomposer.msm8916 (SHARED_LIBRARIES android-arm) missing libbfqio (SHARED_LIBRARIES android-arm)"
> You can set ALLOW_MISSING_DEPENDENCIES=true in your environment if this is intentional, but that may defer real problems until later in the build.

果然，修补`lineage.xml`后出现了同样的错误：缺少~~*libFa♂Qio*~~`libbfqio`。
前往github下载legacy的依赖库，添加到`~/android/lineage/.repo/local_manifests/federer.xml`中：
``` xml
<!--libbfqio-->
<remote name="libbfqio" fetch="https://github.com" revision="android-9.0.0"/>
<project path="hardware/qcom-caf/msm8916/display/libbfqio" name="AOSP-Legacy-MSM8916/platform_external_libbfqio" remote="libbfqio" />
```





### Problem 11
> vendor/lineage/build/tasks/kernel.mk:139: warning: ***************************************************************
> vendor/lineage/build/tasks/kernel.mk:140: warning: * Using prebuilt kernel binary instead of source              *
> vendor/lineage/build/tasks/kernel.mk:141: warning: * THIS IS DEPRECATED, AND IS NOT ADVISED.                     *
> vendor/lineage/build/tasks/kernel.mk:142: warning: * Please configure your device to download the kernel         *
> vendor/lineage/build/tasks/kernel.mk:143: warning: * source repository to kernel/huawei/t2-common/
> vendor/lineage/build/tasks/kernel.mk:144: warning: * for more information                                        *
> vendor/lineage/build/tasks/kernel.mk:145: warning: ***************************************************************

啊这是个警告，就是说在编译vendor的时候一些东西直接拿之前编译好的二进制来用的话是不建议的。
后续补：诶卧槽不对，好像是我又下少东西了淦，就是上面配置`federer.xml`的地方，后来我多加了一行kernel-common。但是现在重新`repo sync`肯定是不行的，所以我们直接去`~/android/lineage/kernel/huawei`里将`t2-common`内核clone进来：
``` bash
git clone --depth=1 https://github.com/datenpanne/android_kernel_huawei_t2-common.git t2-common
```
这个步骤因机型而异！！不要因为我这么操作了，你也这么操作！！


### Problem 12
> FAILED: ninja: 'out/target/product/federer/kernel', needed by 'out/target/product/federer/recovery.img', missing and no known rule to make it

这是源码仓库提供的编译链里缺失了`dtbToolLineage`这个工具。我们只需要将其源码下载下来然后编译，再将其复制进去即可。具体操作如下：
前往`https://github.com/LineageOS/android_system_tools_dtbtool`仓库，将`dtbtool.c`文件直接下载到桌面，用gcc编译`gcc dtbtool.c -o dtbToolLineage`，生成的文件为`dtbToolLineage`，然后将它手动放到`~/android/lineage/out/host/linux-x86/bin/`下，重新运行`brunch federer`即可。
或者往`~/android/lineage/.repo/local_manifests/federer.xml`里添加如下内容：
``` xml
    <!--dtbtool-->
    <remote name="dtbtool" fetch="https://github.com" revision="lineage-18.1"/>
    <project path="system/tools/dtbtool" name="LineageOS/android_system_tools_dtbtool" remote="dtbtool" />
```


### Problem 13
> FAILED: ninja: 'external/ant-wireless/antradio-library/com.dsi.ant.antradio_library.xml', needed by 'out/target/product/federer/system/vendor/etc/permissions/com.dsi.ant.antradio_library.xml', missing and no known rule to make it

这是缺失`com.dsi.ant.antradio_library.xml`，我一看，好家伙这个目录下直接把它的父目录`antradio-library`整个弄丢了。我们只需要前往github将这个目录clone进去即可。
前往`~/android/lineage/external/ant-wireless/`执行
``` bash
git clone --depth=1 https://github.com/LineageOS/android_external_ant-wireless_antradio-library.git antradio-library
```


### Problem 14
> FAILED: ninja: 'vendor/huawei/federer/proprietary/vendor/bin/fm_qsoc_patches', needed by 'out/target/product/federer/system/vendor/bin/fm_qsoc_patches', missing and no known rule to make it

这是缺失`fm_qsoc_patches`，我去原始`vendor`仓库找了一遍确实找到了，但是有点奇怪的是为什么我的电脑上这个文件不存在了。先不管了，回到[github原始仓库](https://github.com/datenpanne/android_vendor_huawei_federer/blob/la-17.1/proprietary/vendor/bin/fm_qsoc_patches)里把这个文件下下来手动放进`~/android/lineage/vendor/huawei/federer/proprietary/vendor/bin`再继续吧。


### Problem 15
> FAILED: ninja: 'device/huawei/t2-common/configs/wpa_supplicant_overlay.conf', needed by 'out/target/product/federer/system/vendor/etc/wifi/wpa_supplicant_overlay.conf', missing and no known rule to make it

这是缺失`wpa_supplicant_overlay.conf`，我在原始仓库里找了一圈也没找到，但是在平板的`/vendor/etc/wifi/wpa_supplicant_overlay.conf`下找到了。
解决方法: 在`~/android/lineage/device/huawei/t2-common/configs`下创建文件`wpa_supplicant_overlay.conf`，内容填入如下:
``` text
disable_scan_offload=1
p2p_disabled=1
p2p_no_group_iface=1
tdls_external_control=1
interworking=1
hs20=1
auto_interworking=0
bss_max_count=512
bss_no_flush_when_down=1
driver_param=use_p2p_group_interface=1
```


### Problem 16
> FAILED: ninja: 'out/target/product/federer/obj_arm/SHARED_LIBRARIES/libqdMetaData_intermediates/libqdMetaData.so.toc', needed by 'out/target/product/federer/obj_arm/SHARED_LIBRARIES/camera.msm8916_intermediates/LINKED/camera.msm8916.so', missing and no known rule to make it

问题与[Problem 9](#problem-9)重复。把那个问题按照修补`~/android/lineage/.repo/local_manifests/federer.xml`的过程修补之后此报错就不会出现。



### Problem 17
> FAILED: build/make/core/main.mk:1312: warning:  device/huawei/federer/lineage_federer.mk includes non-existent modules in PRODUCT_PACKAGES
> Offending entries: Snap TimeKeep android.hardware.audio.effect@2.0-service android.hardware.bluetooth.a2dp@1.0-impl android.hardware.drm@1.2-service.widevine android.hardware.graphics.composer@2.1-impl android.hardware.power@1.2-service-qti android.hardware.renderscript@1.0-service android.hardware.wifi.offload@1.0-service android.hidl.manager@1.0-java copybit.msm8916 ebtables ethertypes keystore.msm8916 libOmxCore libOmxSwVencHevc libOmxVdecHevc libQWiFiSoftApCfg libbt-vendor libcnefeatureconfig libdashplayer libebtc libgenlock libmm-omxcore libmm-qcamera libqsap_sdk libstagefrighthw make_ext4fs thermal.msm8916 timekeep vendor.qti.hardware.cryptfshw@1.0-service-qti.qsee wifilogd
> build/make/core/main.mk:1312: error: Build failed.

参考前面的QCamera2问题，系统提示叫你加环境变量的那个，产生原因和他也相同，本处不再详细分析，具体参考`https://github.com/LineageOS/android`中不同分支下的`snippets/lineage.xml`差异。
解决方案：
打开`~/android/lineage/device/huawei/t2-common/t2.mk`，将这些内容所在行全部用`#`注释掉(将他们先拖到所在块的最后一行，如果上一行有`\\`字符，则也要把上一行的这个字符删了，然后再注释掉最后一行，要不然会导致`MakeFile`语法错误。直接删掉也不是不行~~*能注释就不要删*~~)：
``` makefile
android.hardware.audio.effect@2.0-service
android.hardware.bluetooth.a2dp@1.0-impl
android.hardware.drm@1.2-service.widevine
android.hardware.wifi.offload@1.0-service
android.hidl.manager@1.0-java
android.hardware.renderscript@1.0-service
```
还是上面那个文件，将以下内容进行替换：
``` makefile
android.hardware.graphics.composer@2.1-impl 替换为 android.hardware.graphics.composer3
android.hardware.power@1.2-service-qti 替换为 android.hardware.power@1.2
```
还是上面那个文件，将这几段注释掉：
``` makefile
PRODUCT_PACKAGES += \
    vendor.qti.hardware.cryptfshw@1.0-service-qti.qsee
还有
PRODUCT_PACKAGES += \
    libbt-vendor
还有
PRODUCT_PACKAGES += \
    keystore.msm8916
还有下面这些
    libOmxSwVencHevc \
    libOmxVdecHevc \
    libQWiFiSoftApCfg \
    libebtc
    libgenlock
    libqsap_sdk
    make_ext4fs
    thermal.msm8916
    wifilogd
```
~~
编辑`~/android/lineage/.repo/manifests/default.xml`将这一行注释掉：
``` xml
<project path="hardware/qcom/bt" name="platform/hardware/qcom/bt" groups="qcom,pdk-qcom" remote="aosp" />
```
此时`repo sync`如果失败提示说找不到这个branch(revision)，则进入`~/android/lineage/hardware/qcom`执行命令：
``` bash
rm -rf bt && git clone --depth=1 https://github.com/LineageOS/android_hardware_qcom_bt -b lineage-20.0-caf ~/hardware/qcom/bt
```
~~
再编辑`~/android/lineage/.repo/local_manifests/federer.xml`，直接添加以下语句：
``` xml
    <!--device/huawei/federer/lineage_federer.mk includes non-existent modules in PRODUCT_PACKAGES-->
    <remote name="Snap" fetch="https://github.com" revision="lineage-18.1"/>
    <project path="packages/apps/Snap" name="LineageOS/android_packages_apps_Snap" remote="Snap" />
    <remote name="timekeep" fetch="https://github.com" revision="lineage-20"/>
    <project path="packages/apps/timekeep" name="LineageOS/android_hardware_sony_timekeep" remote="timekeep" />
    <remote name="mm-audio" fetch="https://github.com" revision="cm-9.1.0" />
    <project path="vendor/qcom/opensource/omx/mm-audio" name="LineageOS/android_vendor_qcom_opensource_omx_mm-audio" remote="mm-audio" />
    <remote name="mm-video" fetch="https://github.com" revision="cm-9.1.0" />
    <project path="vendor/qcom/opensource/omx/mm-video" name="LineageOS/android_vendor_qcom_opensource_omx_mm-video" remote="mm-video" />
    <remote name="mm-core" fetch="https://github.com" revision="cm-9.1.0" />
    <project path="vendor/qcom/opensource/omx/mm-core" name="LineageOS/android_vendor_qcom_opensource_omx_mm-core" remote="mm-core" />
    <remote name="ebtables" fetch="https://github.com" revision="lineage-15.1" />
    <project path="external/ebtables" name="LineageOS/android_external_ebtables" remote="ebtables" />
    <remote name="mm-dash" fetch="https://github.com" revision="cm-11.0" />
    <project path="external/mm-dash" name="LineageOS/android_external_mm-dash" remote="mm-dash" />
    <remote name="cryptfs_hw" fetch="https://github.com" revision="lineage-19.1" />
    <project path="vendor/qcom/opensource/cryptfs_hw" name="LineageOS/android_vendor_qcom_opensource_cryptfs_hw" remote="cryptfs_hw" groups="qcom,pdk-qcom" />
```
然后再在26行添加以下语句，以让编译系统知道这来自老旧的仓库，这些文件是旧的格式而非最新格式，就不会因此而报错：
``` makefile
TARGET_DISABLE_EPPE := true
```
剩下这些丢失就会自动忽略：`copybit.msm8916 libdashplayer libmm-qcamera libstagefrighthw libcnefeatureconfig`,在[Lineage Gerrit](https://review.lineageos.org/c/LineageOS/android_device_motorola_msm8916-common/+/324283/6/msm8916.mk#313)中只保留了这两个：`libstagefrighthw libcnefeatureconfig`




### Problem 18
> vendor/qcom/opensource/omx/mm-core/omxcore/Android.mk: error: libOmxCore: LOCAL_COPY_HEADERS is obsolete. See https://android.googlesource.com/platform/build/+/master/Changes.md#copy_headers

问题与[Problem 2](#problem-2)重复。打开`/home/android233/android/lineage/vendor/qcom/opensource/omx/mm-core/omxcore/omxcore.mk`，在最前面添加`BUILD_BROKEN_USES_BUILD_COPY_HEADERS := true`
~~
这是makefile语法过时问题。
打开`vendor/qcom/opensource/omx/mm-core/omxcore/Android.mk`，将以下部分
``` makefile
LOCAL_COPY_HEADERS      := inc/OMX_Audio.h
LOCAL_COPY_HEADERS      += inc/OMX_Component.h
LOCAL_COPY_HEADERS      += inc/OMX_ContentPipe.h
LOCAL_COPY_HEADERS      += inc/OMX_Core.h
LOCAL_COPY_HEADERS      += inc/OMX_Image.h
LOCAL_COPY_HEADERS      += inc/OMX_Index.h
LOCAL_COPY_HEADERS      += inc/OMX_IVCommon.h
LOCAL_COPY_HEADERS      += inc/OMX_Other.h
LOCAL_COPY_HEADERS      += inc/OMX_QCOMExtns.h
LOCAL_COPY_HEADERS      += inc/OMX_Types.h
LOCAL_COPY_HEADERS      += inc/OMX_Video.h
LOCAL_COPY_HEADERS      += inc/qc_omx_common.h
LOCAL_COPY_HEADERS      += inc/qc_omx_component.h
LOCAL_COPY_HEADERS      += inc/qc_omx_msg.h
LOCAL_COPY_HEADERS      += inc/QOMX_AudioExtensions.h
LOCAL_COPY_HEADERS      += inc/QOMX_AudioIndexExtensions.h
LOCAL_COPY_HEADERS      += inc/OMX_CoreExt.h
LOCAL_COPY_HEADERS      += inc/QOMX_CoreExtensions.h
LOCAL_COPY_HEADERS      += inc/QOMX_FileFormatExtensions.h
LOCAL_COPY_HEADERS      += inc/QOMX_IVCommonExtensions.h
LOCAL_COPY_HEADERS      += inc/QOMX_SourceExtensions.h
LOCAL_COPY_HEADERS      += inc/QOMX_VideoExtensions.h
LOCAL_COPY_HEADERS      += inc/OMX_IndexExt.h
LOCAL_COPY_HEADERS      += inc/QOMX_StreamingExtensions.h
```
修改为
``` makefile
LOCAL_EXPORT_C_INCLUDES := $(LOCAL_PATH)/inc
```
~~

### Problem 19
> error: vendor/qcom/opensource/cryptfs_hw/Android.bp:14:1: "libcryptfs_hw" depends on undefined module "legacy_hw_disk_encryption_defaults"

打开`vendor/qcom/opensource/cryptfs_hw/Android.bp`，删除这个部分以及前面的一个逗号(Android13起不需要这个apex,所以可以移除)
``` makefile
"vendor.qti.hardware.cryptfshw@1.0",
```
和这个部分
``` makefile
    defaults: [
      "legacy_hw_disk_encryption_defaults",
    ],
```


### Problem 20
> build/make/core/tasks/platform_availability_check.mk:37: warning:  Following modules are requested to be installed. But are not available for platform because they do not have "//apex_available:platform" or they depend on other modules that are not available for platform
> Offending entries:
> audio.a2dp.default:packages/modules/Bluetooth/system/audio_a2dp_hw
> audio.a2dp.default_32:packages/modules/Bluetooth/system/audio_a2dp_hw
> In file included from build/make/core/main.mk:1456:
> In file included from build/make/core/Makefile:7030:
> build/make/core/tasks/platform_availability_check.mk:37: error: Build failed.

打开`~/home/android233/android/lineage/build/make/core/tasks/platform_availability_check`,将37行注释掉。


### Problem 21
> FAILED: ninja: 'vendor/huawei/federer/proprietary/vendor/bin/fm_qsoc_patches', needed by 'out/target/product/federer/system/vendor/bin/fm_qsoc_patches', missing and no known rule to make it

与 [Problem 14](#problem-14) 重复。


### Problem 22
> ccache: error: Failed to create directory /home/android233/.cache/ccache/tmp: Not a directory

在我电脑上，`~/.cache/ccache`居然是个大小`0B`的空文件？难怪阻止了在目录下创建`tmp`文件。将`ccache`文件删了，`ninja`会自动创建`tmp`文件。问题解决。


### Problem 23
> device/huawei/t2-common/gps/core/ContextBase.h:34:10: fatal error: 'MsgTask.h' file not found
> #include <MsgTask.h>
>          ^~~~~~~~~~~


~~
C/C++规定用尖括号包含的头文件是从系统目录中搜索的，而用引号包含的头文件是从当前目录中搜索的。后面就是根据报错日志修改C++源码的时候了。


### Problem 24
> found ELF prebuilt in PRODUCT_COPY_FILES, use cc_prebuilt_binary / cc_prebuilt_library_shared instead.

参考[此issue](https://github.com/remote-android/redroid-doc/issues/275)
打开`/home/android233/android/lineage/device/huawei/federer/BoardConfig.mk`，在`最顶上`添加：`BUILD_BROKEN_ELF_PREBUILT_PRODUCT_COPY_FILES := true`

或者这样也行(我用的上面那个方法):
打开`/home/android233/android/lineage/build/make/core/Makefile`,将以下几行注释或删除：
``` makefile
check_elf_prebuilt_product_copy_files := true
ifneq (,$(filter true,$(BUILD_BROKEN_ELF_PREBUILT_PRODUCT_COPY_FILES)))
check_elf_prebuilt_product_copy_files :=
endif
```


### Problem 25
> clang: error: unable to execute command: Executable "ld" doesn't exist!
> make[1]: *** [/home/android233/android/lineage/kernel/huawei/t2-common/Makefile:426: scripts_basic] Error 2

这个问题参见[reddit](https://www.reddit.com/r/LineageOS/comments/uarj83/help_building_lineage_171_for_porg_nvidia_jetson/)以及[Stack Overflow](https://stackoverflow.com/questions/67175341/build-error-with-clang-msm-3-18-kernel-android-q)
这个修复起来稍微有点复杂，要涉及到抓bug的操作。
第一步先去打开上面说的那个文件，找到报错所在行`426`，它附近的代码是这样的：
``` makefile
# Basic helpers built in scripts/
PHONY += scripts_basic
scripts_basic:
	$(Q)$(MAKE) $(build)=scripts/basic
	$(Q)rm -f .tmp_quiet_recordmcount
```
向上找到`LD`的定义位置(我这里是328行)：
``` makefile
LD		= $(CROSS_COMPILE)ld
```
回到`426`行那里，将那块代码修改为这样：
``` makefile
# Basic helpers built in scripts/
PHONY += scripts_basic
scripts_basic:
	@echo "============CROSS_COMPILE=$(CROSS_COMPILE)"
	@echo "============LD=$(LD)"
	$(Q)$(MAKE) $(build)=scripts/basic
	$(Q)rm -f .tmp_quiet_recordmcount
```
然后重新进行`brunch federer`编译工程，复现这个问题，将多出来的两行输出记下，重点关注多出来的第二行`LD`的输出。在我电脑上是这样的：
``` text
============CROSS_COMPILE=/home/android233/android/lineage/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/bin/aarch64-linux-android-
============LD=/home/android233/android/lineage/prebuilts/clang/host/linux-x86/clang-r450784d/bin/ld.lld
```
前往`LD`所在的目录，用`ls -al`查看目录下的详细结构。一般会发现缺少了`ld`这个文件，而且能看到有`lld`这个文件(或者软链接)。我的这个目录是这样的：
``` text
...
lrwxrwxrwx  1 android233 android233         3  1月22日 14:47 ld.lld -> lld
-rwxr-xr-x  1 android233 android233  56810672  1月22日 14:47 lld
...
```
我们可以看到，`lld`是个二进制文件，但`ld.lld`是个链接。我们只需要为`lld`再创建一个名为`ld`的链接到当前目录即可(当然复制也不是不行23333)。具体操作就是，这么执行命令：`ln -sf lld ld`(或者干脆`cp lld ld`)。
最后，重新编译项目`brunch federer`，解决！



### Problem 26
> device/huawei/federer/init/init_heap.cpp:74:5: error: use of undeclared identifier 'property_set'

经过核查，相比[安卓10](http://aospxref.com/android-10.0.0_r47/xref/system/core/init/property_service.h),自[安卓11](http://aospxref.com/android-11.0.0_r21/xref/system/core/init/property_service.h)开始，`property_set`已从命名空间`android::init::`下删除，并且同基线CPU的其他设备也弃用了这个参数初始化文件。此更改同步到了安卓13。打开`/home/android233/android/lineage/device/huawei/federer/init/init_heap.cpp`，将涉及到该命名空间的所有行全注释。


### Problem 27
> system/libbase/include/android-base/result.h:378:1: error: too many template parameters in template redeclaration
> template <typename T, typename E, bool include_message>

打开`system/libbase/include/android-base/result.h`，把378行所在的模板类定义及其结构体一整个删除



### Problem 28
> ld.lld: error: duplicate symbol: yylloc

打开`/home/android233/android/lineage/kernel/huawei/t2-common/scripts/dtc/dtc-lexer.lex.c_shipped`，将`extern YYLTYPE yylloc;`修改为`YYLTYPE yylloc;`




### Problem 29
> 一连串的devicetable-offsets.c:27:2: error: unexpected token at start of statement: DEVID_FIELD(hid_device_id, vendor);报错(同文件不同行)

打开`/home/android233/android/lineage/kernel/huawei/t2-common/Makefile`，将`KBUILD_CFLAGS	+= $(call cc-disable-warning,maybe-uninitialized,)`替换为`KBUILD_CFLAGS	+= $(call cc-disable-warning,uninitialized,)`
参见[此issue](https://github.com/MiCode/Xiaomi_Kernel_OpenSource/issues/2469),打开`/home/android233/android/lineage/kernel/huawei/t2-common/include/linux/kbuild.h`,将`asm volatile("\n->" #sym " %0 " #val : : "i" (val))`替换为`asm volatile("\n.ascii \"->" #sym " %0 " #val "\"" : : "i" (val))`


### Problem 30
> /bin/sh: 1: cd: can't cd to /home/android233/android/lineage/out/soong/.intermediates/vendor/lineage/build/soong/generated_kernel_includes/gen

进入`~/android/lineage/out/soong/.intermediates/vendor`执行`mkdir -p lineage/build/soong/generated_kernel_includes/gen`


### Problem 31
> scripts/mod/file2alias.c:176:2: error: use of undeclared identifier

。。。不修了，以后再说吧，太耗时间了，投入产出不成正比。




# 引用的文档和页面
[Lineage Wiki - Build LineageOS for Xiaomi Mi 8](https://wiki.lineageos.org/devices/dipper/build/#prepare-the-device-specific-code)
[LineageOS Gerrit](https://review.lineageos.org/c/LineageOS/android_device_motorola_msm8916-common/+/324283)
[Github - LineageOS](https://github.com/LineageOS/android/tree/lineage-19.1)
[Android Developers -  apps on a hardware device](http://developer.android.com/tools/device.html)
[Android Developers - Source control tools](https://source.android.google.cn/docs/setup/download)
[Android Developers - 适用于硬件混合渲染器 HAL 的 AIDL](https://source.android.google.cn/docs/core/graphics/aidl-hwc?hl=zh-cn)
[Stack Overflow - Build error with Clang + msm-3.18 Kernel Android Q](https://stackoverflow.com/questions/67175341/build-error-with-clang-msm-3-18-kernel-android-q)
[Reddit - \[help\] Building Lineage 17.1 for porg](https://www.reddit.com/r/LineageOS/comments/uarj83/help_building_lineage_171_for_porg_nvidia_jetson/)
[清华大学开源镜像站 - lineageOS 源代码镜像使用帮助](https://mirrors.tuna.tsinghua.edu.cn/help/lineageOS/)
[Sony - Build AOSP Android 14](https://developer.sony.com/open-source/aosp-on-xperia-open-devices/guides/aosp-build-instructions/build-aosp-android-14/)
[Github - LeCmnGend/How_to_build_ROM](https://github.com/LeCmnGend/How_to_build_ROM)
[CSDN - Android12之编译报错LOCAL_COPY_HEADERS is obsolete](https://blog.csdn.net/u010164190/article/details/131278747)
****
[cnblogs/luoyesiqiu - 自己动手编译Android(LineageOS)源码](https://www.cnblogs.com/luoyesiqiu/p/10701419.html)
[XDA Developers - \[GUIDE/HOW-TO\] Building LineageOS for an Unsupported Device](https://xdaforums.com/t/guide-how-to-building-lineageos-for-an-unsupported-device.4419263/)
[StackExchange - How to build lineageos for a device without official support](https://android.stackexchange.com/questions/216435/how-to-build-lineageos-for-a-device-without-official-support)
