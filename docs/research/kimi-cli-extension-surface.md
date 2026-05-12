# Kimi CLI Extension Surface

Research date: 2026-05-12.

Observed from Kimi CLI 1.37.0 source and docs:

- Agent files use `version: 1` YAML with `agent.system_prompt_path`,
  `tools`, `allowed_tools`, `exclude_tools`, and `subagents`.
- Skill discovery supports `~/.kimi/skills`, `~/.claude/skills`,
  `~/.codex/skills`, generic agent skill paths, project skills, extra dirs, and
  installed plugin roots.
- Hooks are configured with `[[hooks]]` in `~/.kimi/config.toml`.
- Hook events include `PreToolUse`, `PostToolUse`, `Stop`, `SubagentStart`,
  `SubagentStop`, and others.
- Plugins require `plugin.json` with `name` and `version`.

Implementation consequence: full oh-my-kimi install symlinks the skill catalog
into `~/.kimi/skills` instead of relying only on plugin root discovery.
