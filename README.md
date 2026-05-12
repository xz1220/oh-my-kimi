# oh-my-kimi

[![Kimi CLI](https://img.shields.io/badge/Kimi%20CLI-1.37%2B-111827)](https://github.com/MoonshotAI/kimi-cli)
[![Validate](https://github.com/xz1220/oh-my-kimi/actions/workflows/validate.yml/badge.svg)](https://github.com/xz1220/oh-my-kimi/actions/workflows/validate.yml)
[![License](https://img.shields.io/badge/license-Apache--2.0-blue)](LICENSE)

**中文** ｜ [English](README.en.md)

把 `oh-my-*` 多 agent 工作流移植到 Moonshot Kimi CLI：精选 subagents、Agent Skills、hook 模板和 MCP 推荐，一条命令给 Kimi 装上可执行的工程工作流。

> 价值不在「让你用 Kimi 模型」，而在「让你用 Kimi CLI 这个 host」：中文优先、国内网络更友好、Kimi 原生 Agent/Skill/Hook/MCP 扩展面，以及可继续接入飞书、钉钉、企业微信等本土工作流。

## 🙏 致谢 / Standing on Shoulders

oh-my-kimi 是受到下面两个 MIT 许可的项目启发并移植而来。所有角色定义、技能目录、工作流命名都源自上游设计，本项目的工程价值在于「Kimi CLI 这个 host 的适配层」。

- **[Yeachan-Heo/oh-my-claudecode](https://github.com/Yeachan-Heo/oh-my-claudecode)** —— Claude Code 的多 agent 编排插件（19 agents + 36 skills），本仓库 `agents/` 与 `skills/` 的主要范式来源。
- **[Yeachan-Heo/oh-my-codex](https://github.com/Yeachan-Heo/oh-my-codex)** —— OpenAI Codex CLI 版本，贡献了 `ralph / ralplan / team / deep-interview` 这套工作流命名。

特别感谢 [Yeachan-Heo](https://github.com/Yeachan-Heo) 把 `oh-my-*` agent harness 谱系从 [`code-yeongyu/oh-my-openagent`](https://github.com/code-yeongyu/oh-my-openagent) 扩展到多个 host —— oh-my-kimi 是这条谱系在国产 host 上的第一环。完整 attribution 见 [NOTICE](NOTICE)。

## 安装

```bash
git clone https://github.com/xz1220/oh-my-kimi.git ~/.oh-my-kimi
bash ~/.oh-my-kimi/scripts/install.sh
```

启动带完整 agent 套件的 Kimi：

```bash
kimi-omk
```

在 Kimi 中使用技能（在 TUI 输入框里，不是 shell）：

```text
/skill:deep-interview 我想做一个浏览器自动化工具
/skill:ralplan 给这个需求拆验收标准
/skill:ralph 按计划实现并跑完验证
/skill:team 3:executor 并行处理三个互不冲突的模块
```

## 你获得了什么

| 层 | 内容 |
|---|---|
| Agents | 19 个 Kimi YAML subagents：`executor`、`architect`、`critic`、`debugger`、`security-reviewer`、`test-engineer`、`writer` 等 |
| Skills | 28 个 Kimi Agent Skills：`deep-interview`、`plan`、`ralplan`、`ralph`、`team`、`verify`、`visual-verdict`、`ai-slop-cleaner` 等 |
| Hooks | 可选 `config.toml` 片段：保护 `.env`、自动格式化、停止通知、验证提醒 |
| MCP | Context7、Chrome DevTools、sequential-thinking 等 MCP server 一键安装脚本 |
| Tests | Pytest 套件覆盖 manifest、Kimi agent spec、skills、hooks、install/uninstall 行为 |

## 安装选项

```bash
bash scripts/install.sh --no-hooks      # 只装 skills + kimi-omk wrapper
bash scripts/install.sh --with-mcp      # 同时添加推荐的 MCP servers
bash scripts/uninstall.sh               # 撤销所有改动（symlink、wrapper、managed hook 块）
bash scripts/validate.sh                # 本地跑全部验证测试
```

## 为什么不直接用 Claude Code + Kimi 后端？

那条路也可以走，前提是你想用 Claude Code 作为 host。`oh-my-kimi` 是给想用 Kimi CLI 本身这个 host 的人用的：原生 Kimi YAML agents、Kimi Skills 发现、Kimi hooks、Kimi MCP 命令，以及一个中文优先的工作流目录。

## 文档

- [安装指南](docs/install.md)
- [Skill 目录](docs/skills.md)
- [Agent 套件](docs/agents.md)
- [架构说明](docs/architecture.md)
- [致谢与归属](docs/attribution.md)

## 谱系

```
code-yeongyu/oh-my-opencode-lite  (2026-01-06, OpenCode harness)
   │
   ├─→ Yeachan-Heo/oh-my-claudecode  (2026-01-09, Claude Code)
   ├─→ Yeachan-Heo/oh-my-codex       (2026-02-02, OpenAI Codex CLI)
   └─→ Yeachan-Heo/oh-my-gemini      (2026-03-05, Google Gemini CLI)
   │
   └─→ xz1220/oh-my-kimi             (2026-05-12, Moonshot Kimi CLI)  ← 本仓库
```

所有上游项目均为 MIT 许可。本项目使用 Apache-2.0（与 Kimi CLI 上游一致），与 MIT 兼容，符合「显式署名 + 许可证宽松度相同或更宽松」的衍生作品规则。详见 [NOTICE](NOTICE) 与 [docs/attribution.md](docs/attribution.md)。
