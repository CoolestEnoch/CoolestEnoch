---
title: 如何在Windows上为PyTorch配置CUDA加速
category: 其他的开发杂记
date: 2025-05-23 00:00:00
index_img: https://pic1.zhimg.com/v2-4f012cc71dad073eb27f14c5fdac4dac_r.jpg
---


 ![封面](https://pic1.zhimg.com/v2-4f012cc71dad073eb27f14c5fdac4dac_r.jpg)

# TL;DR
~~*不要问我为什么封面和上一期一样，问就是依旧贴合主题*~~
~~*这是一篇水文*~~


# 安装CUDA
在cmd里运行`nvidia-smi`，看输出的`CUDA Version`是多少：
``` text
C:\Users\admin> nvidia-smi
Thu Jan 14 11:45:14 2025
+-----------------------------------------------------------------------------------------+
| NVIDIA-SMI 566.41                 Driver Version: 566.41         CUDA Version: 12.7     |
|-----------------------------------------+------------------------+----------------------+
| GPU  Name                  Driver-Model | Bus-Id          Disp.A | Volatile Uncorr. ECC |
| Fan  Temp   Perf          Pwr:Usage/Cap |           Memory-Usage | GPU-Util  Compute M. |
|                                         |                        |               MIG M. |
|=========================================+========================+======================|
|   0  NVIDIA GeForce GTX 1650 Ti   WDDM  |   00000000:01:00.0 Off |                  N/A |
| N/A   57C    P0             15W /   50W |    1883MiB /   4096MiB |     28%      Default |
|                                         |                        |                  N/A |
+-----------------------------------------+------------------------+----------------------+

+-----------------------------------------------------------------------------------------+
| Processes:                                                                              |
|  GPU   GI   CI        PID   Type   Process name                              GPU Memory |
|        ID   ID                                                               Usage      |
|=========================================================================================|
|    0   N/A  N/A      3732    C+G   ...)\Some\Program\ThisIsTheExeFile.exe      N/A      |
+-----------------------------------------------------------------------------------------+
```

我这里是`12.7`，代表着CUDA最高支持版本是12.7，所以在下载的时候选择≤这个版本。
[进入老黄CUDA下载站！](https://developer.nvidia.com/cuda-toolkit-archive)
安装完成后，看看`nvcc -V`有没有输出，系统环境变量是否多了`CUDA_PATH`和`CUDA_PATH_V12_6`这两个环境变量。
> 我下载的是12.6版的驱动，所以第二个环境变量结尾是12_6


# 安装cuDNN
[进入老黄cuDNN下载站！](https://developer.nvidia.com/rdp/cudnn-archive)
可能要你注册账号再下载，注册一个就行，下载对应你CUDA版本的最新版本zip。
将压缩包里的`bin`、`include`、`lib`文件夹解压到CUDA对应版本安装目录，比如`C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v12.6`。
然后将以下两个目录添加到系统`PATH`中：
``` text
C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v12.6\bin
C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v12.6\libnvvp
```

# 使用YOLO验证
打开[PyTorch.org](https://pytorch.org/)，往下拉，根据你的环境，配置好`Run this Command`，进入PyCharm的终端里黏贴运行，安装带CUDA加速的PyTorch，写稿时我的命令是：
``` shell
pip3 install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu126
```
> 过程会消耗大约3GB流量，请注意你的网络资费。

安装YOLO：
``` shell
pip install ultralytics
```

然后我使用的是如下程序，在任务管理器里可以看到程序主要使用GPU进行运算，而非CPU：
``` python
from ultralytics import YOLO  
  
if __name__ == "__main__":  
    a1 = YOLO('yolov8n.pt')  # 若无此文件, 首次运行会自动下载
    a1('van.mp4', show=True, save=False) # van.mp4为相对本python脚本的相对路径，可以替换为其他图片文件，save改为True后会在本地保存带框的识别结果。
```
