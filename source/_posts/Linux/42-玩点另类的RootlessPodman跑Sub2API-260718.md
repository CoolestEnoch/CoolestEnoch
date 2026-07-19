---
title: 玩点另类的，Rootless Podman跑Sub2API
category: Linux
date: 2026-07-18 18:00:00
---


# TL;DR
最近看到好几个AI厂提供白嫖活动，那怎么能不上呢！但这样一来，账号多了不好管理。CC Switch只能管本机的，没法管我远程服务器上的，这就很麻烦，看蓝点网用的是Sub2API，我也打算搭一个自用，但不走官方的docker教程，用podman来跑。
> 为什么不用docker跑？因为之前看到个AI笑话：
> 主人没给coding agent root权限，但coding agent发现他所在账户在`docker`组里，于是就建了一个容器，把`/`映射进去开始删东西（


他的架构是，你电脑提供一个OpenAI或者Anthropic兼容的API入口，然后给不同用户签发一个api key，这样局域网服务器只要把base url写到你电脑上、API key用自己签发的，然后电脑这边在webui里统一管理第三方账号/API就行了，这样切换也很方便，只要在webui里操作，完全不用去动服务器上的coding agent配置文件。



# 安装Podman
先安装：
``` shell
sudo pacman -S --needed podman podman-compose aardvark-dns crun
```


确认安装成功：
``` shell
podman --version
podman-compose --version
```

Rootless Podman 会为当前用户创建独立的用户命名空间。容器里的多个 UID 和 GID，需要通过下面两个文件映射到宿主机上的 subordinate UID/GID：
``` shell
/etc/subuid
/etc/subgid
```


## 检查当前用户是否已有映射
执行：
``` shell
grep "^${USER}:" /etc/subuid || true
grep "^${USER}:" /etc/subgid || true
```
正常情况下会看到类似：
``` shell
yourname:100000:65536
yourname:100000:65536
```
三段内容分别表示：
``` shell
用户名:起始ID:可使用的ID数量
```
这样就说明你有映射了，可以跳过这一步


## 添加SubUIDs映射
``` shell
sudo usermod --add-subuids 100000-165535 --add-subgids 100000-165535 "$USER"
```
再次检查：
``` shell
grep "^${USER}:" /etc/subuid
grep "^${USER}:" /etc/subgid
```
然后**注销当前桌面会话并重新登录**。


## 验证 Podman 正在 Rootless 模式运行
重新登录系统后执行：
``` shell
podman info --format 'rootless={{.Host.Security.Rootless}}'
```
正常输出：
``` shell
rootless=true
```
再运行一个测试容器：
``` shell
podman run --rm docker.io/library/alpine:latest id
```
正常会输出类似：
``` shell
uid=0(root) gid=0(root) groups=0(root)
```
这里的 `root` 只是容器用户命名空间中的 root，并不等于宿主机真正的 UID 0。


# 部署Sub2API
> 本文把Sub2API放在`/path/to/sub2api`。
> 继续操作即代表你已经`mkdir`并`cd`进入此文件夹。


运行Sub2API官方部署脚本，初始化`compose`配置文件：
``` shell
curl -sSL https://raw.githubusercontent.com/Wei-Shaw/sub2api/main/deploy/docker-deploy.sh | bash
```

## 修复 Podman 无法解析短镜像名的问题
Sub2API 的 Compose 文件可能使用下面这些 Docker 风格短镜像名：
``` shell
image: redis:8-alpine
image: postgres:18-alpine
image: weishaw/sub2api:latest
```
在没有配置默认镜像仓库的 Podman 环境中，启动时可能出现：
``` shell
Error: short-name "redis:8-alpine" did not resolve to an alias
Error: short-name "postgres:18-alpine" did not resolve to an alias
Error: short-name "weishaw/sub2api:latest" did not resolve to an alias
```
这是因为 Podman 无法确定这些镜像应该从哪个注册表拉取。Podman 官方建议尽量使用带注册表域名的完整镜像名，因为短名称可能产生歧义或命名空间冒用风险。

将镜像名改为完整地址。执行：
``` shell
sed -Ei -e 's#(^[[:space:]]*image:[[:space:]]*)weishaw/sub2api:latest#\1docker.io/weishaw/sub2api:latest#g' -e 's#(^[[:space:]]*image:[[:space:]]*)postgres:18-alpine#\1docker.io/library/postgres:18-alpine#g' -e 's#(^[[:space:]]*image:[[:space:]]*)redis:8-alpine#\1docker.io/library/redis:8-alpine#g' docker-compose.yml
```


## 开始部署和启动
先拉取镜像：
``` shell
podman compose -f ./docker-compose.yml pull
```

首次启动：
``` shell
podman compose -f ./docker-compose.yml up -d
```

停止容器：
``` shell
podman compose -f ./docker-compose.yml down
```

首次登录需要你的管理员账号和密码。管理员账号是固定的`admin@sub2api.local`，管理员初始密码可通过这个命令获取：
``` shell
podman compose -f ./docker-compose.yml logs sub2api | grep -i "admin password"
```


# 管理员密码忘了怎么办
在 `docker-compose.yml` 所在目录执行：
``` shell
podman exec -it sub2api-postgres \
  psql -U sub2api -d sub2api
```
进入 PostgreSQL 后，依次执行：
``` shell
CREATE EXTENSION IF NOT EXISTS pgcrypto;

UPDATE users
SET password_hash = crypt(
    '这里换成你的新密码',
    gen_salt('bf', 10)
)
WHERE email = 'admin@sub2api.local';
```
正常应显示：
``` shell
CREATE EXTENSION
UPDATE 1
```
然后退出：
``` shell
\q
```
现在直接使用这个登录：
``` text
账号：admin@sub2api.local
密码：你刚设置的新密码
```
不需要重启 Sub2API。

**如果显示 `UPDATE 0`**：
说明管理员邮箱不是 `admin@sub2api.local`。重新进入数据库后查询：
``` shell
SELECT id, email, role FROM users ORDER BY id;
```
找到实际邮箱，再执行：
``` shell
UPDATE users
SET password_hash = crypt(
    '这里换成你的新密码',
    gen_salt('bf', 10)
)
WHERE email = '实际邮箱';
```


# 迁移
只要把`/path/to/sub2api`带走，在另一台有podman的机器上直接`podman compose -f ./docker-compose.yml pull`然后`podman compose -f ./docker-compose.yml up -d`就行了。十分的简单！
