---
title: 如何在sshfs上手搓一个venv
category: Linux
date: 2026-04-30 18:00:00
---


# TL;DR
想跑一个基于python 3.8的代码，但算力空闲的服务器没空间了、硬盘大的服务器被大家占满算力，怎么办呢？把硬盘大的那个机器用sshfs挂载到这台服务器上。


# 开始挂载
好吧其实就一句话的事儿：
``` shell
# 其中 name@ip 可以换成你的服务器别名
sshfs -o follow_symlinks,reconnect,idmap=user name@ip:/path/to/folder ./folder
```


# 开始搓venv
进入`folder`，但别急着`uv init --python 3.8`，也别急着`/home/myname/.local/share/uv/python/cpython-3.8.20-linux-x86_64-gnu/bin/python3.8 -m venv --copies .venv`，因为这些操作都会在文件夹下创建软链接，但sshfs是不支持链接的，宿主机上所有的链接都会被映射为普通文件夹。

首先`uv python find 3.8`看看你的解释器在哪，然后创建`.venv`文件夹，再执行下面的操作：
``` shell
mkdir -p .venv/bin  
mkdir -p .venv/lib/python3.8/site-packages  
mkdir -p .venv/include/python3.8

# 比如 uv python find 3.8 输出目录是 /home/myname/.local/share/uv/python/cpython-3.8.20-linux-x86_64-gnu/bin/python3.8
PY_BASE="/home/myname/.local/share/uv/python/cpython-3.8.20-linux-x86_64-gnu"  
PY_BIN="$PY_BASE/bin/python3.8"  
  
mkdir -p .venv/bin  
mkdir -p .venv/lib/python3.8/site-packages  
mkdir -p .venv/include/python3.8

# 注意，libpython3.8.so.1.0 一定要复制
cp -L "$PY_BASE/lib" .venv/lib/
  
cp "$PY_BIN" .venv/bin/python  
cp "$PY_BIN" .venv/bin/python3  
cp "$PY_BIN" .venv/bin/python3.8  
chmod +x .venv/bin/python .venv/bin/python3 .venv/bin/python3.8

cat > .venv/pyvenv.cfg <<EOF  
home = $PY_BASE/bin  
include-system-site-packages = false  
version = 3.8.20  
executable = $PY_BIN  
command = $PY_BIN -m venv --copies /home/myname/ysuproj/VAD/.venv  
EOF

# 创建 activate 脚本
cat > .venv/bin/activate <<'EOF'
# This file must be used with "source .venv/bin/activate"

deactivate () {
    if [ -n "${_OLD_VIRTUAL_PATH:-}" ]; then
        PATH="${_OLD_VIRTUAL_PATH}"
        export PATH
        unset _OLD_VIRTUAL_PATH
    fi

    if [ -n "${_OLD_VIRTUAL_PS1:-}" ]; then
        PS1="${_OLD_VIRTUAL_PS1}"
        export PS1
        unset _OLD_VIRTUAL_PS1
    fi

    unset VIRTUAL_ENV
    unset VIRTUAL_ENV_PROMPT

    if [ "${1:-}" != "nondestructive" ]; then
        unset -f deactivate
    fi
}

deactivate nondestructive

VIRTUAL_ENV="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")/.." && pwd)"
export VIRTUAL_ENV

_OLD_VIRTUAL_PATH="$PATH"
PATH="$VIRTUAL_ENV/bin:$PATH"
export PATH

VIRTUAL_ENV_PROMPT="(.venv) "
export VIRTUAL_ENV_PROMPT

if [ -z "${VIRTUAL_ENV_DISABLE_PROMPT:-}" ]; then
    _OLD_VIRTUAL_PS1="${PS1:-}"
    PS1="(.venv) ${PS1:-}"
    export PS1
fi

hash -r 2>/dev/null
EOF
```

最后，再`uv sync`一下就好啦！


# 其他踩坑
## mmdetection3d
对于`mmdetection3d`这种依赖如下安装方式的库：
``` shell
conda activate vad
git clone https://github.com/open-mmlab/mmdetection3d.git
cd /path/to/mmdetection3d
git checkout -f v0.17.1
python setup.py develop
```

我们只需要做如下操作即可：
``` shell
git clone https://github.com/open-mmlab/mmdetection3d.git
cd /path/to/mmdetection3d
git checkout -f v0.17.1
uv pip install -v --no-build-isolation -e .
```

然后编辑`pyproject.toml`，添加以下内容到`[tool.uv.sources]`：
``` toml
[tool.uv.sources]
# 进入mmdet3d文件夹并uv pip install -v --no-build-isolation -e .然后再添加下面一行  
mmdet3d = { path = "./mmdetection3d", editable = true }
```


## nvcc版本问题
这台机器上有两个`nvcc`，一个是`10.x`一个是`12.8`，这样可以强制用`12.8`
``` shell
export CUDA_HOME=/usr/local/cuda  
export CUDA_PATH=/usr/local/cuda  
export PATH="$CUDA_HOME/bin:$PATH"  
export LD_LIBRARY_PATH="$CUDA_HOME/lib64:${LD_LIBRARY_PATH:-}"  
  
# zsh/bash 刷新命令缓存  
hash -r 2>/dev/null || true  
rehash 2>/dev/null || true
```

