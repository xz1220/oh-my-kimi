---
name: ask
description: 询问本地外部顾问 CLI（Claude 或 Gemini），并产出可复用的工件
---

# Ask（Local Advisor CLI）

用一个本地安装的外部顾问 CLI 做聚焦提问、审查、头脑风暴或第二意见。该 skill 取代单独的 `ask-claude` 与 `ask-gemini` skill。

## 用法

```bash
claude -p <question or task>
gemini -p <question or task>
claude -p "<question or task>"
gemini -p "<question or task>"
```

## 后端选择

- 用户要 Claude、Anthropic 或先前的 `$ask-claude` 行为时使用 `claude`。
- 用户要 Gemini 或先前的 `$ask-gemini` 行为时使用 `gemini`。
- 如果没有指定后端，挑选已安装且最匹配请求的后端；如果两者都不明显可用，说明需要本地 CLI。

## 本地 CLI 命令

Claude：

```bash
claude -p "{{ARGUMENTS}}"
claude -p "{{ARGUMENTS}}"
```

Gemini：

```bash
gemini -p "{{ARGUMENTS}}"
gemini -p "{{ARGUMENTS}}"
```

必要时按用户安装的 CLI 变体调整，但保持「本地执行」为默认路径。本地二进制缺失时不要悄悄切换到 MCP 或远端 provider。

## 工件要求

本地执行后把 markdown 工件保存到：

```text
.omk/artifacts/ask-<backend>-<slug>-<timestamp>.md
```

工件至少包含以下段落：
1. 原始用户任务
2. 后端与最终发给 CLI 的 prompt
3. CLI 原始输出
4. 简要总结
5. Action items / next steps

Task: {{ARGUMENTS}}
