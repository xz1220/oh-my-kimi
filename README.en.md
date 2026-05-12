# oh-my-kimi

[![Kimi CLI](https://img.shields.io/badge/Kimi%20CLI-1.37%2B-111827)](https://github.com/MoonshotAI/kimi-cli)
[![Validate](https://github.com/xz1220/oh-my-kimi/actions/workflows/validate.yml/badge.svg)](https://github.com/xz1220/oh-my-kimi/actions/workflows/validate.yml)
[![License](https://img.shields.io/badge/license-Apache--2.0-blue)](LICENSE)

[中文](README.md) ｜ **English**

A port of the `oh-my-*` multi-agent workflow lineage to Moonshot Kimi CLI: curated subagents, Agent Skills, hook templates, and MCP server recommendations. One command turns Kimi into a full engineering workflow.

> The value is not "let you use Kimi the model" — it's "let you use Kimi CLI the host": Chinese-first prompts, better connectivity from inside China, Kimi-native Agent/Skill/Hook/MCP extension surfaces, and a path to integrate Feishu/DingTalk/WeCom and other local workflows.

## 🙏 Acknowledgments / Standing on Shoulders

oh-my-kimi is a downstream port of and is deeply indebted to two MIT-licensed projects. All role definitions, skill catalogs, and workflow names trace back to upstream design; the engineering value of this project lies in "the adapter layer for Kimi CLI as a host".

- **[Yeachan-Heo/oh-my-claudecode](https://github.com/Yeachan-Heo/oh-my-claudecode)** — A multi-agent orchestration plugin for Claude Code (19 agents + 36 skills). The primary source for this repo's `agents/` and `skills/`.
- **[Yeachan-Heo/oh-my-codex](https://github.com/Yeachan-Heo/oh-my-codex)** — The OpenAI Codex CLI variant. Origin of the `ralph / ralplan / team / deep-interview` workflow naming.

Special thanks to [Yeachan-Heo](https://github.com/Yeachan-Heo) for extending the `oh-my-*` agent harness lineage — originally [`code-yeongyu/oh-my-openagent`](https://github.com/code-yeongyu/oh-my-openagent) — to multiple hosts. oh-my-kimi is the first link of this lineage on a Chinese host. Full attribution lives in [NOTICE](NOTICE).

## Install

```bash
git clone https://github.com/xz1220/oh-my-kimi.git ~/.oh-my-kimi
bash ~/.oh-my-kimi/scripts/install.sh
```

Then start Kimi with the full agent bundle:

```bash
kimi-omk
```

Use skills inside Kimi (type these inside the TUI input box, not the shell):

```text
/skill:deep-interview I want to build a browser automation tool
/skill:ralplan turn the requirement into acceptance criteria
/skill:ralph implement the plan and run verification to completion
/skill:team 3:executor work on three independent modules in parallel
```

## What You Get

| Surface | Included |
|---|---|
| Agents | 19 Kimi YAML subagents: `executor`, `architect`, `critic`, `debugger`, `security-reviewer`, `test-engineer`, `writer`, etc. |
| Skills | 28 Kimi Agent Skills: `deep-interview`, `plan`, `ralplan`, `ralph`, `team`, `verify`, `visual-verdict`, `ai-slop-cleaner`, etc. |
| Hooks | Optional `config.toml` snippets for secret protection, best-effort formatting, stop notifications, and verification reminders. |
| MCP | Helper scripts for Context7, Chrome DevTools, and sequential-thinking MCP servers. |
| Tests | Pytest suite covering manifests, Kimi agent specs, skills, hooks, and install/uninstall behavior. |

## Install Options

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

```
code-yeongyu/oh-my-opencode-lite  (2026-01-06, OpenCode harness)
   │
   ├─→ Yeachan-Heo/oh-my-claudecode  (2026-01-09, Claude Code)
   ├─→ Yeachan-Heo/oh-my-codex       (2026-02-02, OpenAI Codex CLI)
   └─→ Yeachan-Heo/oh-my-gemini      (2026-03-05, Google Gemini CLI)
   │
   └─→ xz1220/oh-my-kimi             (2026-05-12, Moonshot Kimi CLI)  ← this repo
```

All upstream projects are MIT-licensed. This project uses Apache-2.0 (aligned with Kimi CLI upstream), which is compatible with MIT under the "explicit attribution + same-or-more-permissive license" rule for derivative works. See [NOTICE](NOTICE) and [docs/attribution.md](docs/attribution.md).
