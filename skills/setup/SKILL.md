---
name: setup
description: Install, refresh, or verify oh-my-kimi on a local Kimi CLI machine.
argument-hint: "[--no-hooks] [--with-mcp]"
---

# Setup

Use this when the user wants oh-my-kimi installed or repaired.

## Commands

From a checkout:

```bash
bash scripts/install.sh
```

Without hooks:

```bash
bash scripts/install.sh --no-hooks
```

With recommended MCP setup:

```bash
bash scripts/install.sh --with-mcp
```

Uninstall:

```bash
bash scripts/uninstall.sh
```

## Verify

```bash
kimi-omk --version
ls ~/.kimi/skills/ralph/SKILL.md
grep -n "oh-my-kimi" ~/.kimi/config.toml
```
