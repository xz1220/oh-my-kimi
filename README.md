# oh-my-kimi

[![Kimi CLI](https://img.shields.io/badge/Kimi%20CLI-1.37%2B-111827)](https://github.com/MoonshotAI/kimi-cli)
[![Validate](https://github.com/xz1220/oh-my-kimi/actions/workflows/validate.yml/badge.svg)](https://github.com/xz1220/oh-my-kimi/actions/workflows/validate.yml)
[![License](https://img.shields.io/badge/license-Apache--2.0-blue)](LICENSE)

把 `oh-my-*` 多 agent 工作流移植到 Moonshot Kimi CLI：精选 subagents、Agent Skills、hook 模板和 MCP 推荐，一条命令给 Kimi 装上可执行的工程工作流。

> 价值不在「让你用 Kimi 模型」，而在「让你用 Kimi CLI 这个 host」：中文优先、国内网络更友好、Kimi 原生 Agent/Skill/Hook/MCP 扩展面，以及可继续接入飞书、钉钉、企业微信等本土工作流。

## Install

```bash
git clone https://github.com/xz1220/oh-my-kimi.git ~/.oh-my-kimi
bash ~/.oh-my-kimi/scripts/install.sh
```

Then start Kimi with the full agent bundle:

```bash
kimi-omk
```

Use skills inside Kimi:

```text
/skill:deep-interview 我想做一个浏览器自动化工具
/skill:ralplan 给这个需求拆验收标准
/skill:ralph 按计划实现并跑完验证
/skill:team 3:executor 并行处理三个互不冲突的模块
```

## What You Get

| Surface | Included |
|---|---|
| Agents | 19 Kimi YAML subagents: `executor`, `architect`, `critic`, `debugger`, `security-reviewer`, `test-engineer`, `writer`, etc. |
| Skills | 28 Kimi Agent Skills: `deep-interview`, `plan`, `ralplan`, `ralph`, `team`, `verify`, `visual-verdict`, `ai-slop-cleaner`, etc. |
| Hooks | Optional `config.toml` snippets for secret protection, best-effort formatting, stop notifications, and verification reminders. |
| MCP | Helper scripts for Context7, Chrome DevTools, and sequential-thinking MCP servers. |
| Tests | Pytest suite covering manifests, Kimi agent specs, skills, hooks, and install/uninstall behavior. |

## Commands

```bash
bash scripts/install.sh --no-hooks      # install skills + kimi-omk wrapper only
bash scripts/install.sh --with-mcp      # also add recommended MCP servers
bash scripts/uninstall.sh               # remove symlinks, wrapper, managed hook block
bash scripts/validate.sh                # run local validation
```

## Why Not Just Claude Code + Kimi Backend?

That path is valid if you want Claude Code as the host. `oh-my-kimi` is for people who want the Kimi CLI host itself: Kimi-native YAML agents, Kimi Skills discovery, Kimi hooks, Kimi MCP commands, and a Chinese-first workflow catalog.

## Documentation

- [Install Guide](docs/install.md)
- [Skill Catalog](docs/skills.md)
- [Agent Bundle](docs/agents.md)
- [Architecture](docs/architecture.md)
- [Attribution](docs/attribution.md)

## Lineage

This project is a downstream port of the MIT-licensed `oh-my-*` lineage, especially [`Yeachan-Heo/oh-my-claudecode`](https://github.com/Yeachan-Heo/oh-my-claudecode), adapted for [`MoonshotAI/kimi-cli`](https://github.com/MoonshotAI/kimi-cli). See [NOTICE](NOTICE) and [docs/attribution.md](docs/attribution.md).
