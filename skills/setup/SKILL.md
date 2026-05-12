---
name: setup
description: 在本地 Kimi CLI 机器上安装、刷新或验证 oh-my-kimi。
argument-hint: "[--no-hooks] [--with-mcp]"
---

# Setup

当用户希望安装或修复 oh-my-kimi 时使用本 skill。

## 命令

从 checkout 目录：

```bash
bash scripts/install.sh
```

不安装 hooks：

```bash
bash scripts/install.sh --no-hooks
```

附带推荐的 MCP 配置：

```bash
bash scripts/install.sh --with-mcp
```

卸载：

```bash
bash scripts/uninstall.sh
```

## 验证

```bash
kimi-omk --version
ls ~/.kimi/skills/ralph/SKILL.md
grep -n "oh-my-kimi" ~/.kimi/config.toml
```
