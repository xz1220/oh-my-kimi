---
name: oh-my-kimi
description: Catalog entry for oh-my-kimi, a Kimi CLI agent, skill, hook, and MCP bundle derived from the oh-my-* lineage.
license: Apache-2.0; includes MIT-derived prompt material attributed in NOTICE
---

# oh-my-kimi

Use this skill when you need to understand or activate the oh-my-kimi catalog inside Kimi CLI.

## What Is Installed

- Agents live in `agents/` and are loaded with `kimi --agent-file <repo>/agents/oh-my-kimi.yaml` or the `kimi-omk` wrapper.
- Skills live in `skills/<name>/SKILL.md` and are available as `/skill:<name>` after running `scripts/install.sh`.
- Hook templates live in `hooks/` and are appended to `~/.kimi/config.toml` by the full installer.
- MCP helper scripts live in `mcp/` and can be run separately when those integrations are wanted.

## Recommended Workflow

1. Use `/skill:deep-interview` when the requirement is vague.
2. Use `/skill:ralplan` when the requirement needs a committed plan before implementation.
3. Use `/skill:ralph` for persistent execution until verification passes.
4. Use `/skill:team` when parallel specialist work is valuable.
5. Use `/skill:verify` or `/skill:visual-verdict` as a final quality gate.

## Agent Routing

Prefer direct work for small edits. Use Agent subagents only when the task benefits from isolated context or parallel investigation:

- `explore` for read-only code search.
- `planner` or `architect` for design plans.
- `executor` for implementation.
- `critic`, `verifier`, `code-reviewer`, `security-reviewer`, `qa-tester`, or `test-engineer` for review and validation.
