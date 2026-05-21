---
title: 让codex和claude一起工作
category: 其他的开发杂记
date: 2026-05-15 18:00:00
---


# 安装
安装Claude-cli：
``` shell
npm install -g @anthropic-ai/claude-code
```

安装Codex-cli：
``` shell
npm install -g @openai/codex@latest
```


# 接入DeepSeek
> 如果你用的是官方API或其他中转站，请参考他们提供的教程。

## Claude
增加如下环境变量：
``` shell
export ANTHROPIC_BASE_URL=https://api.deepseek.com/anthropic
export ANTHROPIC_AUTH_TOKEN=<你的 DeepSeek API Key>
export ANTHROPIC_MODEL=deepseek-v4-pro[1m]
export ANTHROPIC_DEFAULT_OPUS_MODEL=deepseek-v4-pro[1m]
export ANTHROPIC_DEFAULT_SONNET_MODEL=deepseek-v4-pro[1m]
export ANTHROPIC_DEFAULT_HAIKU_MODEL=deepseek-v4-flash
export CLAUDE_CODE_SUBAGENT_MODEL=deepseek-v4-flash
export CLAUDE_CODE_EFFORT_LEVEL=max
```
然后再在你的工程目录里运行：
``` shell
claude
```


## Codex
编辑`~/.codex/config.toml`：
``` toml
[model_providers.deepseek]
name = "DeepSeek"
base_url = "https://api.deepseek.com/v1"
wire_api = "responses"
env_key = "DEEPSEEK_API_KEY"

[profiles.deepseek-chat]
model_provider = "deepseek"
model = "deepseek-v4-pro"
```


然后在你的工程文件夹里运行：
``` shell
export DEEPSEEK_API_KEY="你的API_KEY"
codex --profile deepseek-chat
```


# 智能体协作
编辑`~/.codex/config.toml`，添加如下内容，以启动多Agent模式：
``` toml
[features]  
multi_agent = true  
  
[agents.code_reviewer]  
description = "代码审查专家，检测安全漏洞、逻辑错误和代码质量问题"  
model = "deepseek-chat"  
model_provider = "deepseek"  
sandbox_mode = "read-only"     # 仅读取，不修改  
approval_policy = "never"      # 不自动批准任何修改
```


启动claude，依次运行以下命令完成和codex的对接：
``` text
/plugin marketplace add openai/codex-plugin-cc
/plugin install codex@openai-codex
/reload-plugins
/codex:setup
```

随后就能在claude里通过`/codex:`让它们一起工作了。

