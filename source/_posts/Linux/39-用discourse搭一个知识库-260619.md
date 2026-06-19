---
title: 用discourse搭一个知识库
category: Linux
date: 2026-06-19 18:00:00
index_img: https://www.discourse.org/a/img/logo.svg
---


# TL;DR
本文记录一次基于官方 `discourse_docker + launcher` 的 Discourse 内网知识库部署过程。目标不是搭建一个面向公网的论坛，而是把 Discourse 改造成一个适合实验室内部使用的知识库系统：

* 仅内网访问；
* 不使用宿主机 80/443 端口；
* 不使用 Nginx 反代；
* 不配置邮件系统；
* 管理员预注册实验室账号；
* 本地 Markdown 文档批量导入；
* 支持 Markdown、图片、LaTeX 公式；
* 后续可以接入 Discourse AI。

最终访问形式示例：

```text
http://10.1.2.3:1145
```


# 开始部署
装依赖：
``` shell
apt install -y git curl wget ca-certificates gnupg lsb-release lsof nano
```

假设部署根目录为：

```bash
/path/to/KnowledgeBase
```

目录结构如下：

```text
/path/to/KnowledgeBase/
├── discourse_docker/       # 官方 discourse_docker 仓库
├── discourse_shared/       # Discourse 数据、上传文件、日志、备份
└── docker_data/            # 可选：Docker daemon 数据目录
```

下载构建脚本并进入：
``` shell
git clone https://github.com/discourse/discourse_docker.git /path/to/KnowledgeBase/discourse_docker
cd discourse_docker  
cp samples/standalone.yml containers/app.yml
```

核心配置文件为：

```bash
/path/to/KnowledgeBase/containers/app.yml
```


## 数据挂载配置

在 `containers/app.yml` 中，建议把 `/shared` 和日志目录挂载到自己的知识库目录下：

```yaml
volumes:
- volume:
    host: /path/to/KnowledgeBase/discourse_shared/standalone
    guest: /shared
- volume:
    host: /path/to/KnowledgeBase/discourse_shared/standalone/log/var-log
    guest: /var/log
```

这样 Discourse 的数据库、上传文件、备份、日志都会集中在：

```bash
/path/to/KnowledgeBase/discourse_shared/standalone
```

后续迁移时，重点备份这个目录即可。


## 端口配置（如果用80/443则可跳过这段）

因为不使用宿主机 80 端口，所以在 `app.yml` 中使用非标准端口映射：

```yaml
expose:
- "1145:80"
```

最终访问地址为：

```text
http://10.1.2.3:1145
```

注意，`DISCOURSE_HOSTNAME` 不要写成带端口的形式。

错误示例：

```yaml
DISCOURSE_HOSTNAME: "10.1.2.3:1145"
```

这样容易导致 Discourse 在生成某些静态资源路径时把端口错误地拼进去，出现类似资源加载失败、MIME type mismatch 等问题。比如页面里的链接会被生成成：

```text
http://10.1.2.3/...
```

导致跳转时丢失端口。对于自定义端口问题，我们还要做以下修改。

在宿主机执行：

```bash
docker exec app bash -lc 'cd /var/www/discourse && rails runner '\''SiteSetting.force_hostname="10.1.2.3"; SiteSetting.port=1145; SiteSetting.force_https=false'\'''
```

然后重启容器：

```bash
cd /path/to/KnowledgeBase
sudo ./launcher restart app
```

也可以进入 Rails console 手动敲三行。

进入容器：

```bash
cd /path/to/KnowledgeBase
sudo ./launcher enter app
```

进入 Rails console：

```bash
rails c
```

手动输入这三行：

```ruby
SiteSetting.force_hostname = "10.1.2.3"
SiteSetting.port = 1145
SiteSetting.force_https = false
```

随后退出容器并重启 Discourse：

```bash
sudo ./launcher restart app
```

检查当前 base url：

```bash
docker exec app bash -lc 'cd /var/www/discourse && rails runner '\''puts Discourse.base_url'\'''
```

期望输出：

```text
http://10.1.2.3:1145
```

## 无邮件系统的配置

本方案不配置 SMTP，不依赖邮件激活、不依赖邮件找回密码。在 `app.yml` 中直接把邮件相关的都注释掉就行。

不过需要注意：Discourse 本身是一个默认围绕邮件系统设计的论坛系统。即使不配置 SMTP，它的很多用户流程仍然会默认走邮件，例如：

```text
用户注册激活
找回密码
普通用户自助修改密码
邮箱确认
```

因此，在无邮件系统部署中，推荐采用：

```text
管理员预注册用户
管理员统一分配初始密码
普通用户不自助改密码
用户忘记密码后找管理员重置
```

## 管理员账号创建（单次，不是批量）

用容器内命令行创建管理员账号：

```bash
cd /path/to/KnowledgeBase
sudo ./launcher enter app
rake admin:create
```

随后按提示填写即可，比如：

```text
Email: cxk1145@wobuzhi.dao
Password: 管理员强密码
Username: cxk1145
Name: cxk1145
Grant Admin? y
Activate Account? y
```

## 后台基础设置

进入后台后，建议调整以下设置。

后台路径（浏览器直接加到地址后面）：

```text
/admin/site_settings
```

建议搜索并设置：

```text
login required = true
invite only = true
must approve users = true
enable local logins = true
enable local logins via email = false
email editable = false
Allow new registrations = false
Enable signup CTA = false
```

含义：

```text
login required              -> 必须登录才能看内容
invite only                 -> 不开放公开注册
must approve users          -> 新用户需要批准
enable local logins         -> 允许本地账号密码登录
enable local logins via email -> 不用邮箱登录
email editable              -> 普通用户不能自己改邮箱
Allow new registrations     -> 禁止新用户注册
Enable signup CTA           -> 禁用向回访匿名用户显示通知，提示他们注册帐户
```

## Markdown 与 LaTeX 支持

Discourse 默认支持 Markdown，不需要额外安装插件。

LaTeX 公式需要启用 Discourse Math。

后台搜索：

```text
math
```

建议开启：

```text
discourse math enabled = true
discourse math provider = mathjax
discourse math enable latex delimiters = true
```

公式建议使用：

```markdown
$$
s^*(v,\Delta v)
=
s_0 + vT + \frac{v\Delta v}{2\sqrt{a_{\max}b}}
$$
```

不建议使用单独一行的 `$` 包裹多行公式，因为兼容性不稳定。

---

## 批量导入 Markdown 知识库

本方案中，本地 Markdown 文档会被导入为 Discourse topic。

目录映射规则可以设计为：

```text
ROOT/A/file.md       -> category A
ROOT/A/B/file.md     -> category A / subcategory B
ROOT/A/B/C/file.md   -> category A / subcategory B，深层目录写进标题或正文路径
```

例如：

```text
自动驾驶入门/
├── 1.基础知识/
│   ├── index.md
│   └── 1.1感知基础.md
├── 2.规划控制/
│   ├── index.md
│   └── 2.1规划基础.md
└── 3.World Model.md
```

导入后大致变成：

```text
category: 自动驾驶入门
subcategory: 1.基础知识
topic: index
topic: 1.1感知基础

category: 自动驾驶入门
subcategory: 2.规划控制
topic: index
topic: 2.1规划基础

category: 自动驾驶入门
topic: 3.World Model
```

导入命令示例：

```bash
BASE="http://10.1.2.3:1145"
API_USER="cxk1145"
API_KEY="你的_API_KEY"

python3 import_md_tree_to_discourse.py \
  --base-url "$BASE" \
  --api-key "$API_KEY" \
  --api-username "$API_USER" \
  --root "." \
  --fix-single-dollar-blocks \
  --sleep 2 \
  --timeout 180
```

其中：

```text
--fix-single-dollar-blocks
```

用于把 Markdown 中独占一行的 `$` 尝试修正为 `$$`，改善 LaTeX 公式显示。

导入记录会保存在：

```text
.discourse_import_log.json
```

默认行为：

```text
log 中已有且 sha256 没变 -> 跳过
文件变了 -> 默认新建 topic
加 --force -> 强制新建，可能重复
```

如果希望本地 Markdown 修改后覆盖原 topic，需要额外实现 update 模式：读取 log 里的 `post_id`，然后调用 Discourse 的编辑帖子接口更新原帖。

> 导入用的脚本见文末。


## 导入时的 429 限流问题

批量导入时可能遇到 429。

### Nginx限流

如果 `app.yml` 中启用了：

```yaml
- "templates/web.ratelimited.template.yml"
```

批量导入时可能触发 Nginx 层限流。

可以临时注释掉：

```yaml
# - "templates/web.ratelimited.template.yml"
```

然后 rebuild：

```bash
cd /path/to/KnowledgeBase
sudo ./launcher rebuild app
```

导入完成后可以再恢复。

### Discourse 应用层限流

如果返回内容类似：

```json
{
  "errors": ["您执行此操作的次数过多。请等待 14 秒后再试。"],
  "error_type": "rate_limit"
}
```

这说明是 Discourse 应用层限流。

可以在 `app.yml` 的 `env:` 中临时提高限制：

```yaml
DISCOURSE_MAX_ADMIN_API_REQS_PER_MINUTE: 10000
DISCOURSE_MAX_USER_API_REQS_PER_MINUTE: 10000
DISCOURSE_MAX_USER_API_REQS_PER_DAY: 100000
DISCOURSE_MAX_REQS_PER_IP_MODE: none
DISCOURSE_MAX_REQS_PER_IP_PER_MINUTE: 10000
DISCOURSE_MAX_REQS_PER_IP_PER_10_SECONDS: 10000
```

然后 rebuild：

```bash
cd /path/to/KnowledgeBase
sudo ./launcher rebuild app
```

导入完成后，建议恢复较保守的限流设置。

## 批量创建普通用户

由于不使用邮件系统，普通用户建议由管理员批量预注册。

账号示例：

```text
cxk1145
```

邮箱使用假邮箱即可：

```text
cxk1145@wobuzhi.dao
```

注意：Discourse 用户模型仍然需要 email 字段，即使这个邮箱不真实可用。

### 密码规则

在`/admin/users/settings`里修改：
``` text
Password unique characters = 1
Block common passwords = false
```

在`/admin/site_settings/category/all_results?filter=min%20password%20length`里修改：
``` text
Min password length = 8
Min admin password length = 8
```

## 批量导入用户

准备用户列表：

```bash
vim lab_users.txt
```

内容示例：

```text
cxk1145
lbw8848
```

批量创建脚本见文末。

## 批量删除普通用户

脚本见文末。

注意：这个脚本会跳过管理员和版主，避免误删管理账号。


## 删除单个管理员账户
假设要删的管理员用户名是`oldadmin`：
``` bash
docker exec -e TARGET_USERNAME="oldadmin" app bash -lc 'cd /var/www/discourse && rails runner '\''target=ENV.fetch("TARGET_USERNAME").strip.downcase; u=User.where(username_lower: target).first; if u.nil?; puts "[MISS] #{target}"; elsif User.where(admin: true).where.not(id: u.id).count==0; puts "[SKIP] refuse to delete last admin"; else; name=u.username; id=u.id; u.admin=false; u.moderator=false; u.save!; UserDestroyer.new(Discourse.system_user).destroy(u, delete_posts: false); puts "[DELETED] #{name} id=#{id}"; end'\'''
```

## 重置指定用户密码
> 可重置普通用户也可重置管理员！

脚本见文末。

## Discourse AI 接入思路

后续如果要接入 AI，可以使用 Discourse AI 插件。

进入`/admin/plugins`后，搜索并启用`AI`，然后点右边的`设置-LLM`，按提示接入你的大模型即可。***然后再***到AI设置页开启：
```text
discourse ai enabled = true
ai bot enabled = true
ai bot add to header = true
```
然后按你的需求设置下面几个字段：
``` text
AI default LLM model
AI bot enabled LLMs
AI bot debugging allowed groups
```



如果容器访问公网需要代理，可以在 `app.yml` 的 `env:` 中加入：

```yaml
HTTP_PROXY: "http://ip:port"
HTTPS_PROXY: "http://ip:port"
http_proxy: "http://ip:port"
https_proxy: "http://ip:port"
NO_PROXY: "localhost,127.0.0.1,::1,postgres,redis"
no_proxy: "localhost,127.0.0.1,::1,postgres,redis"
```


# 几个脚本
## 批量导入文章
> 依赖`requests`
``` python
#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Import a local multi-level Markdown knowledge base into Discourse.

Mapping rule:
- First-level folder  -> Discourse top-level category
- Second-level folder -> Discourse subcategory under the first-level category
- Markdown files directly under first-level folder -> posted to top-level category
- Markdown files under second-level or deeper folders -> posted to second-level subcategory
- Deeper folders are preserved in title prefix and import footer

Example:
ROOT/
  二维入门相关/
    index.md                                  -> category: 二维入门相关
    1.基础知识与PyTorch基础/
      index.md                                -> subcategory: 二维入门相关 / 1.基础知识与PyTorch基础
      1.1物体检测基础知识.md                   -> same subcategory
    2.网络骨架：Backbone/
      2.1神经网络基本组成.md                   -> subcategory: 二维入门相关 / 2.网络骨架：Backbone

Supported local image references:
- Markdown image: ![](path/to/img.png)
- Markdown image: ![alt](path/to/img.png "title")
- HTML image: <img src="path/to/img.png">
- Obsidian image: ![[path/to/img.png]]
- Obsidian image with alias: ![[path/to/img.png|caption]]

Usage:
  python3 import_md_tree_to_discourse.py \
    --base-url "http://your.domain:59462" \
    --api-key "YOUR_API_KEY" \
    --api-username "admin" \
    --root "." \
    --fix-single-dollar-blocks \
    --dry-run

Then remove --dry-run to really import.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import mimetypes
import re
import sys
import time
import unicodedata
from pathlib import Path
from typing import Dict, Iterable, List, Optional, Tuple
from urllib.parse import unquote

import requests


MD_IMAGE_RE = re.compile(r'!\[([^\]]*)\]\(([^)]+)\)')
OBSIDIAN_IMAGE_RE = re.compile(r'!\[\[([^\]]+)\]\]')
HTML_IMG_RE = re.compile(
    r'(<img\b[^>]*?\bsrc\s*=\s*["\'])([^"\']+)(["\'][^>]*?>)',
    flags=re.IGNORECASE,
)
H1_RE = re.compile(r'^\s*#\s+(.+?)\s*#*\s*$', flags=re.MULTILINE)
FRONT_MATTER_RE = re.compile(r'\A---\s*\n(.*?)\n---\s*\n?', flags=re.DOTALL)

IMAGE_EXTS = {
    ".png", ".jpg", ".jpeg", ".gif", ".webp", ".svg", ".bmp", ".tif", ".tiff", ".avif"
}

DEFAULT_IGNORE_DIRS = {
    ".git",
    ".svn",
    ".hg",
    "__pycache__",
    ".obsidian",
    ".vscode",
    ".idea",
    "node_modules",
    ".venv",
    ".venv-discourse-import",
}


def eprint(*args, **kwargs) -> None:
    print(*args, file=sys.stderr, **kwargs)


def normalize_base_url(url: str) -> str:
    return url.rstrip("/")


def request_headers(api_key: str, api_username: str) -> Dict[str, str]:
    return {
        "Api-Key": api_key,
        "Api-Username": api_username,
        "Accept": "application/json",
    }


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def load_json(path: Path) -> dict:
    if not path.exists():
        return {}
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except Exception:
        return {}


def save_json(path: Path, obj: dict) -> None:
    path.write_text(json.dumps(obj, ensure_ascii=False, indent=2), encoding="utf-8")


def parse_front_matter(text: str) -> Tuple[Dict[str, str], str]:
    m = FRONT_MATTER_RE.match(text)
    if not m:
        return {}, text

    raw = m.group(1)
    body = text[m.end():]

    meta: Dict[str, str] = {}
    for line in raw.splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        if ":" not in line:
            continue
        k, v = line.split(":", 1)
        meta[k.strip().lower()] = v.strip().strip('"').strip("'")

    return meta, body


def clean_title(s: str) -> str:
    s = s.strip()
    s = re.sub(r'[`*_~]', '', s)
    s = " ".join(s.split())
    return s


def title_from_md(meta: Dict[str, str], body: str, md_path: Path) -> str:
    if meta.get("title"):
        title = meta["title"].strip()
    else:
        m = H1_RE.search(body)
        if m:
            title = m.group(1).strip()
        else:
            title = md_path.stem.replace("_", " ").replace("-", " ").strip()

    title = clean_title(title)
    if not title:
        title = md_path.stem

    if len(title) > 220:
        title = title[:220].rstrip()

    return title


def ensure_title_length(title: str, min_len: int) -> str:
    title = title.strip()
    while len(title) < min_len:
        title += " 知识库"
    return title


def parse_tags(meta: Dict[str, str], default_tags: List[str]) -> List[str]:
    tags = list(default_tags)

    raw = meta.get("tags", "").strip()
    if raw:
        raw = raw.strip("[]")
        for item in raw.split(","):
            t = item.strip().strip('"').strip("'")
            if t:
                tags.append(t)

    out = []
    seen = set()
    for t in tags:
        t = t.strip()
        if not t:
            continue
        if t not in seen:
            seen.add(t)
            out.append(t)

    return out


def fix_single_dollar_math_blocks(text: str) -> str:
    lines = text.splitlines()
    out = []
    for line in lines:
        if line.strip() == "$":
            out.append("$$")
        else:
            out.append(line)
    return "\n".join(out) + ("\n" if text.endswith("\n") else "")


def is_external_ref(ref: str) -> bool:
    r = ref.strip().lower()
    return (
        r.startswith("http://")
        or r.startswith("https://")
        or r.startswith("data:")
        or r.startswith("mailto:")
        or r.startswith("#")
    )


def strip_markdown_link_title(target: str) -> str:
    t = target.strip()

    if t.startswith("<") and ">" in t:
        return t[1:t.index(">")].strip()

    if '"' in t:
        before = t.split('"', 1)[0].strip()
        if before:
            return before

    if "'" in t:
        before = t.split("'", 1)[0].strip()
        if before:
            return before

    return t.strip()


def normalize_asset_ref(ref: str) -> str:
    ref = strip_markdown_link_title(ref)
    ref = unquote(ref)
    ref = ref.split("#", 1)[0].split("?", 1)[0].strip()
    return ref


def resolve_asset_path(md_file: Path, ref: str, root: Path) -> Optional[Path]:
    ref = normalize_asset_ref(ref)

    if not ref or is_external_ref(ref):
        return None

    raw_path = Path(ref)
    candidates: List[Path] = []

    if raw_path.is_absolute():
        candidates.append(raw_path)
    else:
        candidates.append((md_file.parent / raw_path).resolve())
        candidates.append((root / raw_path).resolve())

    if raw_path.suffix == "":
        for ext in IMAGE_EXTS:
            if raw_path.is_absolute():
                candidates.append(raw_path.with_suffix(ext))
            else:
                candidates.append((md_file.parent / raw_path).with_suffix(ext).resolve())
                candidates.append((root / raw_path).with_suffix(ext).resolve())

    for p in candidates:
        try:
            if p.exists() and p.is_file() and p.suffix.lower() in IMAGE_EXTS:
                return p
        except OSError:
            continue

    return None


def upload_file(
    base_url: str,
    headers: Dict[str, str],
    file_path: Path,
    timeout: int,
) -> str:
    url = f"{base_url}/uploads.json"

    mime_type, _ = mimetypes.guess_type(str(file_path))
    mime_type = mime_type or "application/octet-stream"

    with file_path.open("rb") as f:
        files = {
            "file": (file_path.name, f, mime_type),
        }
        data = {
            "type": "composer",
            "synchronous": "true",
        }
        resp = requests.post(url, headers=headers, data=data, files=files, timeout=timeout)

    if resp.status_code not in (200, 201):
        raise RuntimeError(
            f"Upload failed: {file_path} -> HTTP {resp.status_code}: {resp.text[:800]}"
        )

    js = resp.json()

    uploaded_url = js.get("short_url") or js.get("url")
    if not uploaded_url or not isinstance(uploaded_url, str):
        raise RuntimeError(f"Upload response has no usable URL: {js}")

    return uploaded_url


def replace_image_refs(
    text: str,
    md_file: Path,
    root: Path,
    base_url: str,
    headers: Dict[str, str],
    upload_cache: Dict[str, str],
    timeout: int,
    dry_run: bool,
) -> str:
    def get_uploaded_url(ref: str) -> Optional[str]:
        asset_path = resolve_asset_path(md_file, ref, root)
        if not asset_path:
            return None

        key = str(asset_path)
        if key in upload_cache:
            return upload_cache[key]

        if dry_run:
            fake_url = f"/uploads/dry-run/{asset_path.name}"
            upload_cache[key] = fake_url
            return fake_url

        uploaded = upload_file(base_url, headers, asset_path, timeout)
        upload_cache[key] = uploaded
        print(f"      [IMG] {asset_path} -> {uploaded}")
        return uploaded

    def repl_obsidian(match: re.Match) -> str:
        target = match.group(1).strip()
        if "|" in target:
            ref, alt = target.split("|", 1)
            ref = ref.strip()
            alt = alt.strip()
        else:
            ref = target
            alt = Path(normalize_asset_ref(target)).stem

        uploaded = get_uploaded_url(ref)
        if not uploaded:
            return match.group(0)

        return f"![{alt}]({uploaded})"

    def repl_md(match: re.Match) -> str:
        alt = match.group(1)
        target = match.group(2)
        uploaded = get_uploaded_url(target)
        if not uploaded:
            return match.group(0)

        return f"![{alt}]({uploaded})"

    def repl_html(match: re.Match) -> str:
        prefix = match.group(1)
        target = match.group(2)
        suffix = match.group(3)

        uploaded = get_uploaded_url(target)
        if not uploaded:
            return match.group(0)

        return f"{prefix}{uploaded}{suffix}"

    text = OBSIDIAN_IMAGE_RE.sub(repl_obsidian, text)
    text = MD_IMAGE_RE.sub(repl_md, text)
    text = HTML_IMG_RE.sub(repl_html, text)
    return text


def color_for_name(name: str) -> str:
    digest = hashlib.md5(name.encode("utf-8")).hexdigest()
    r = (int(digest[0:2], 16) + 80) % 256
    g = (int(digest[2:4], 16) + 120) % 256
    b = (int(digest[4:6], 16) + 160) % 256
    return f"{r:02X}{g:02X}{b:02X}"


def get_categories(base_url: str, headers: Dict[str, str], timeout: int) -> List[dict]:
    url = f"{base_url}/categories.json?include_subcategories=true"
    resp = requests.get(url, headers=headers, timeout=timeout)
    if resp.status_code != 200:
        raise RuntimeError(f"Failed to list categories: {resp.status_code}: {resp.text[:800]}")
    js = resp.json()
    return js.get("category_list", {}).get("categories", [])


def find_category(categories: List[dict], name: str, parent_id: Optional[int]) -> Optional[dict]:
    for c in categories:
        if c.get("name") != name:
            continue

        c_parent = c.get("parent_category_id")
        if parent_id is None and c_parent is None:
            return c
        if parent_id is not None and c_parent == parent_id:
            return c

    return None


def create_category(
    base_url: str,
    headers: Dict[str, str],
    name: str,
    parent_id: Optional[int],
    timeout: int,
    dry_run: bool,
) -> dict:
    if dry_run:
        # stable fake id
        fake_key = f"{parent_id or 0}/{name}"
        fake_id = int(hashlib.md5(fake_key.encode("utf-8")).hexdigest()[:8], 16) % 900000 + 10000
        return {
            "id": fake_id,
            "name": name,
            "slug": name,
            "parent_category_id": parent_id,
            "dry_run": True,
        }

    url = f"{base_url}/categories.json"
    payload = {
        "name": name,
        "color": color_for_name(name),
        "text_color": "FFFFFF",
    }

    if parent_id is not None:
        payload["parent_category_id"] = parent_id

    resp = requests.post(
        url,
        headers={**headers, "Content-Type": "application/json"},
        json=payload,
        timeout=timeout,
    )

    if resp.status_code not in (200, 201):
        raise RuntimeError(
            f"Failed to create category {name!r} parent_id={parent_id}: "
            f"HTTP {resp.status_code}: {resp.text[:1000]}"
        )

    js = resp.json()
    return js.get("category", js)


def get_or_create_category(
    base_url: str,
    headers: Dict[str, str],
    name: str,
    parent_id: Optional[int],
    timeout: int,
    dry_run: bool,
    category_cache: Dict[Tuple[Optional[int], str], dict],
) -> dict:
    key = (parent_id, name)

    if key in category_cache:
        return category_cache[key]

    if parent_id is None:
        print(f"[CATEGORY] create top: {name}")
    else:
        print(f"[CATEGORY] create sub: parent={parent_id}, name={name}")

    created = create_category(base_url, headers, name, parent_id, timeout, dry_run)
    category_cache[key] = created
    return created


def create_topic(
    base_url: str,
    headers: Dict[str, str],
    title: str,
    raw: str,
    category_id: int,
    tags: List[str],
    timeout: int,
    dry_run: bool,
) -> dict:
    if dry_run:
        return {
            "id": -1,
            "topic_id": -1,
            "topic_slug": "dry-run",
        }

    url = f"{base_url}/posts.json"
    payload = {
        "title": title,
        "raw": raw,
        "category": category_id,
    }

    if tags:
        payload["tags"] = tags

    resp = requests.post(
        url,
        headers={**headers, "Content-Type": "application/json"},
        json=payload,
        timeout=timeout,
    )

    if resp.status_code >= 400 and tags and "tag" in resp.text.lower():
        eprint(f"      [WARN] tags rejected for {title!r}; retrying without tags")
        payload.pop("tags", None)
        resp = requests.post(
            url,
            headers={**headers, "Content-Type": "application/json"},
            json=payload,
            timeout=timeout,
        )

    if resp.status_code not in (200, 201):
        raise RuntimeError(
            f"Failed to create topic {title!r}: HTTP {resp.status_code}: {resp.text[:1200]}"
        )

    return resp.json()


def iter_markdown_files(root: Path, ignore_dirs: set[str]) -> Iterable[Path]:
    for p in sorted(root.rglob("*"), key=lambda x: str(x).lower()):
        if not p.is_file():
            continue
        if p.suffix.lower() not in {".md", ".markdown"}:
            continue
        rel_parts = p.relative_to(root).parts
        if any(part in ignore_dirs for part in rel_parts):
            continue
        if any(part.startswith(".") for part in rel_parts):
            continue
        yield p


def normalized_dir_name(s: str) -> str:
    return unicodedata.normalize("NFC", s.strip())


def classify_markdown_file(root: Path, md_file: Path) -> Tuple[str, Optional[str], List[str]]:
    """
    Returns:
      top_category_name, subcategory_name_or_none, deeper_dirs

    Example:
      root/A/file.md             -> A, None, []
      root/A/B/file.md           -> A, B, []
      root/A/B/C/file.md         -> A, B, ["C"]
      root/A/B/C/D/file.md       -> A, B, ["C", "D"]
    """
    rel = md_file.relative_to(root)
    parts = rel.parts

    if len(parts) < 2:
        raise ValueError(f"Markdown file must be inside a category folder: {rel}")

    top = normalized_dir_name(parts[0])

    if len(parts) >= 3:
        sub = normalized_dir_name(parts[1])
        deeper = [normalized_dir_name(x) for x in parts[2:-1]]
    else:
        sub = None
        deeper = []

    return top, sub, deeper


def build_title(
    base_title: str,
    deeper_dirs: List[str],
    prefix_deeper_path: bool,
    min_title_len: int,
) -> str:
    title = base_title

    if prefix_deeper_path and deeper_dirs:
        prefix = " / ".join(deeper_dirs)
        # Avoid duplicating index title like C / C
        if title not in deeper_dirs:
            title = f"{prefix} / {title}"

    title = ensure_title_length(title, min_title_len)

    if len(title) > 250:
        title = title[:250].rstrip()

    return title


def make_raw_post(
    body: str,
    rel_path: str,
    top_category: str,
    subcategory: Optional[str],
    deeper_dirs: List[str],
    add_import_footer: bool,
) -> str:
    raw = body.rstrip()

    if add_import_footer:
        path_lines = [
            "",
            "---",
            "",
            f"> Imported from `{rel_path}`",
            f"> Category: `{top_category}`",
        ]
        if subcategory:
            path_lines.append(f"> Subcategory: `{subcategory}`")
        if deeper_dirs:
            path_lines.append(f"> Path: `{' / '.join(deeper_dirs)}`")

        raw += "\n" + "\n".join(path_lines)

    return raw + "\n"


def main() -> int:
    parser = argparse.ArgumentParser(description="Import multi-level Markdown tree into Discourse categories/subcategories.")
    parser.add_argument("--base-url", required=True, help="Example: http://domain:59462")
    parser.add_argument("--api-key", required=True, help="Discourse API key")
    parser.add_argument("--api-username", default="admin", help="Discourse API username")
    parser.add_argument("--root", default=".", help="Root dir. First-level folders become categories.")
    parser.add_argument("--default-tag", action="append", default=[], help="Default tag; can repeat")
    parser.add_argument("--tag-deeper-dirs", action="store_true", help="Add deeper directory names as tags")
    parser.add_argument("--min-title-length", type=int, default=1, help="Pad title to this length")
    parser.add_argument("--timeout", type=int, default=120, help="HTTP timeout seconds")
    parser.add_argument("--sleep", type=float, default=0.8, help="Sleep between topics")
    parser.add_argument("--dry-run", action="store_true", help="Preview without creating/uploading")
    parser.add_argument("--force", action="store_true", help="Import again even if already logged")
    parser.add_argument("--fix-single-dollar-blocks", action="store_true", help="Convert single-line $ delimiters to $$")
    parser.add_argument("--no-footer", action="store_true", help="Do not add imported-from footer")
    parser.add_argument("--no-prefix-deeper-path", action="store_true", help="Do not prefix titles with deeper directory path")
    parser.add_argument("--ignore-dir", action="append", default=[], help="Directory name to ignore; can repeat")
    parser.add_argument("--log-file", default=".discourse_import_log.json", help="Import log file under root")
    args = parser.parse_args()

    base_url = normalize_base_url(args.base_url)
    root = Path(args.root).expanduser().resolve()

    if not root.exists() or not root.is_dir():
        eprint(f"ERROR: root does not exist or is not a directory: {root}")
        return 2

    headers = request_headers(args.api_key, args.api_username)

    ignore_dirs = set(DEFAULT_IGNORE_DIRS)
    ignore_dirs.update(args.ignore_dir)

    log_path = root / args.log_file
    import_log = load_json(log_path)
    upload_cache: Dict[str, str] = {}
    category_cache: Dict[Tuple[Optional[int], str], dict] = {}
    if not args.dry_run:
        print("[INIT] loading existing categories once...")
        for c in get_categories(base_url, headers, args.timeout):
            key = (c.get("parent_category_id"), c.get("name"))
            category_cache[key] = c
        print(f"[INIT] loaded {len(category_cache)} categories.")

    print(f"Root: {root}")
    print(f"Base URL: {base_url}")
    print(f"Dry run: {args.dry_run}")
    print()

    md_files = list(iter_markdown_files(root, ignore_dirs))
    if not md_files:
        print("No Markdown files found.")
        return 0

    print(f"Found {len(md_files)} markdown files.")
    print()

    imported = 0
    skipped = 0
    failed = 0

    for md_file in md_files:
        rel_path = str(md_file.relative_to(root))

        try:
            top_name, sub_name, deeper_dirs = classify_markdown_file(root, md_file)
        except Exception as exc:
            failed += 1
            eprint(f"[FAIL] {rel_path}: {exc}")
            continue

        file_hash = sha256_file(md_file)

        if (
            not args.force
            and rel_path in import_log
            and import_log[rel_path].get("sha256") == file_hash
        ):
            print(f"[SKIP] {rel_path}")
            skipped += 1
            continue

        try:
            top_category = get_or_create_category(
                base_url=base_url,
                headers=headers,
                name=top_name,
                parent_id=None,
                timeout=args.timeout,
                dry_run=args.dry_run,
                category_cache=category_cache,
            )
            top_id = int(top_category["id"])

            final_category = top_category
            final_category_name = top_name
            final_category_id = top_id

            if sub_name:
                subcategory = get_or_create_category(
                    base_url=base_url,
                    headers=headers,
                    name=sub_name,
                    parent_id=top_id,
                    timeout=args.timeout,
                    dry_run=args.dry_run,
                    category_cache=category_cache,
                )
                final_category = subcategory
                final_category_name = f"{top_name} / {sub_name}"
                final_category_id = int(subcategory["id"])

            text = md_file.read_text(encoding="utf-8", errors="replace")
            meta, body = parse_front_matter(text)

            base_title = title_from_md(meta, body, md_file)
            title = build_title(
                base_title=base_title,
                deeper_dirs=deeper_dirs,
                prefix_deeper_path=not args.no_prefix_deeper_path,
                min_title_len=args.min_title_length,
            )

            tags = parse_tags(meta, args.default_tag)
            if args.tag_deeper_dirs:
                for d in deeper_dirs:
                    if d and d not in tags:
                        tags.append(d)

            if args.fix_single_dollar_blocks:
                body = fix_single_dollar_math_blocks(body)

            body = replace_image_refs(
                text=body,
                md_file=md_file,
                root=root,
                base_url=base_url,
                headers=headers,
                upload_cache=upload_cache,
                timeout=args.timeout,
                dry_run=args.dry_run,
            )

            raw = make_raw_post(
                body=body,
                rel_path=rel_path,
                top_category=top_name,
                subcategory=sub_name,
                deeper_dirs=deeper_dirs,
                add_import_footer=not args.no_footer,
            )

            print(f"[POST] {rel_path}")
            print(f"       -> category={final_category_name} id={final_category_id}")
            print(f"       -> title={title!r}")

            result = create_topic(
                base_url=base_url,
                headers=headers,
                title=title,
                raw=raw,
                category_id=final_category_id,
                tags=tags,
                timeout=args.timeout,
                dry_run=args.dry_run,
            )

            topic_id = result.get("topic_id")
            post_id = result.get("id")
            topic_slug = result.get("topic_slug")

            topic_url = None
            if topic_id and topic_slug:
                topic_url = f"{base_url}/t/{topic_slug}/{topic_id}"

            import_log[rel_path] = {
                "sha256": file_hash,
                "top_category": top_name,
                "top_category_id": top_id,
                "subcategory": sub_name,
                "final_category_id": final_category_id,
                "deeper_dirs": deeper_dirs,
                "title": title,
                "tags": tags,
                "topic_id": topic_id,
                "post_id": post_id,
                "topic_url": topic_url,
                "imported_at": time.strftime("%Y-%m-%d %H:%M:%S"),
            }
            save_json(log_path, import_log)

            if topic_url:
                print(f"       OK: {topic_url}")
            else:
                print(f"       OK: topic_id={topic_id}, post_id={post_id}")

            imported += 1
            time.sleep(args.sleep)

        except Exception as exc:
            failed += 1
            eprint(f"[FAIL] {rel_path}: {exc}")

    print()
    print("Done.")
    print(f"Total markdown: {len(md_files)}")
    print(f"Imported:       {imported}")
    print(f"Skipped:        {skipped}")
    print(f"Failed:         {failed}")
    print(f"Log file:       {log_path}")

    if args.dry_run:
        print()
        print("Dry-run mode: no categories/topics/uploads were actually created.")

    return 0 if failed == 0 else 1


if __name__ == "__main__":
    raise SystemExit(main())

```


## 批量导入用户
``` bash
#!/bin/bash

while IFS= read -r line || [ -n "$line" ]; do
    username="$(printf '%s' "$line" | tr -d '\r' | xargs)"

    if [ -z "$username" ] || [[ "$username" == \#* ]]; then
        continue
    fi

    echo "create: $username"
    password="somethinghere!$(echo username | rev)2026"

    docker exec \
        -e LAB_USERNAME="$username" \
        -e LAB_PASSWORD="$password" \
        app bash -lc 'cd /var/www/discourse && rails runner '"'"'
username = ENV.fetch("LAB_USERNAME").strip
password = ENV.fetch("LAB_PASSWORD").strip

unless username.match?(/\A[a-zA-Z0-9_]+\z/)
  puts "[FAIL] username=#{username} reason=invalid_username"
  exit 0
end

email = "#{username}@wobuzhi.dao"

u = User.where(username_lower: username.downcase).first

if u
  puts "[SKIP] username=#{username} already exists id=#{u.id}"
  exit 0
end

u = User.new(
  username: username,
  name: username,
  active: false,
  approved: true,
  admin: false,
  moderator: false,
  staged: false
)

u.email = email
u.password = password
u.save!

u.activate
u.approved = true
u.active = true
u.save!

puts "[OK] username=#{username} password=#{password} email=#{email} active=#{u.active} approved=#{u.approved} id=#{u.id}"
'"'"''

done < lab_users.txt

echo "密码格式：somethinghere! + 用户名反转 + 2026"
echo "例如：用户名 cxk1145 对应密码 somethinghere!5411kxc2026"

```


## 批量删除普通用户
``` bash
#!/bin/bash

while IFS= read -r line || [ -n "$line" ]; do
    username="$(printf '%s' "$line" | tr -d '\r' | xargs)"

    if [ -z "$username" ] || [[ "$username" == \#* ]]; then
        continue
    fi

    echo "delete: $username"

    docker exec \
        -e LAB_USERNAME="$username" \
        app bash -lc 'cd /var/www/discourse && rails runner '"'"'
username = ENV.fetch("LAB_USERNAME").strip
u = User.where(username_lower: username.downcase).first

unless u
  puts "[MISS] username=#{username} not found"
  exit 0
end

if u.admin? || u.moderator?
  puts "[SKIP] username=#{username} is staff, not deleting"
  exit 0
end

UserDestroyer.new(Discourse.system_user).destroy(u, delete_posts: true)
puts "[DELETED] username=#{username} id=#{u.id}"
'"'"''

done < lab_users.txt

```


## 理员重置普通用户密码
``` bash
#!/bin/bash

read -p "请输入要重置密码的用户名: " username

while true; do
    read -p "请输入新密码（至少 8 位）: " password
    if [ ${#password} -ge 8 ]; then
        break
    else
        echo "密码长度不足 8 位，请重新输入。"
    fi
done

docker exec \
  -e LAB_USERNAME="$username" \
  -e LAB_PASSWORD="$password" \
  app bash -lc 'cd /var/www/discourse && rails runner '"'"'
username = ENV.fetch("LAB_USERNAME").strip
password = ENV.fetch("LAB_PASSWORD").strip

u = User.where(username_lower: username.downcase).first

unless u
  puts "[MISS] username=#{username} not found"
  exit 1
end

u.password = password
u.active = true
u.approved = true
u.staged = false
u.save!

begin
  u.activate
rescue => e
  puts "[WARN] activate failed: #{e.class}: #{e.message}"
end

u.active = true
u.approved = true
u.save!

puts "[OK] username=#{username} password=#{password} id=#{u.id} active=#{u.active} approved=#{u.approved}"
'"'"''

```

