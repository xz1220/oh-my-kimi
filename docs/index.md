# oh-my-kimi

`oh-my-kimi` brings the `oh-my-*` multi-agent workflow style to Moonshot Kimi
CLI.

It ships four surfaces:

| Surface | What it does |
|---|---|
| Agents | Kimi YAML subagents for implementation, review, security, testing, writing, and debugging |
| Skills | Reusable `/skill:<name>` workflows for planning, Ralph-style execution, team coordination, and verification |
| Hooks | Optional lifecycle automation for formatting, secret protection, notifications, and final reminders |
| MCP | Helper scripts for recommended MCP servers |

## Quick Start

```bash
git clone https://github.com/xz1220/oh-my-kimi.git ~/.oh-my-kimi
bash ~/.oh-my-kimi/scripts/install.sh
kimi-omk
```

Inside Kimi:

```text
/skill:deep-interview clarify this product idea
/skill:ralplan turn it into verifiable stories
/skill:ralph implement it and keep fixing until tests pass
```

## Positioning

This project is not a model wrapper. It configures Kimi CLI as the host: Kimi
agents, Kimi skills, Kimi hooks, and Kimi MCP commands.
