---
name: skill
description: Inspect, explain, or lightly edit Agent Skills in Kimi-compatible SKILL.md format.
argument-hint: "[list|show|create|review] <name>"
---

# Skill

Use this when working with Kimi-compatible Agent Skills.

## Common Tasks

- List skills: inspect `skills/*/SKILL.md` in the current repo or
  `~/.kimi/skills`.
- Show a skill: read the target `SKILL.md` and summarize trigger, workflow, and
  dependencies.
- Create a skill: make `<name>/SKILL.md` with YAML frontmatter and clear
  instructions.
- Review a skill: check that it has a lowercase hyphenated name, useful
  description, bounded workflow, and no stale tool references.

Keep skills short. Put large examples or scripts in sibling files and reference
them from `SKILL.md`.
