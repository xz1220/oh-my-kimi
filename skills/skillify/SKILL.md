---
name: skillify
description: Convert a repeated workflow, prompt, or checklist into a reusable Kimi Agent Skill.
argument-hint: "<workflow or source material>"
---

# Skillify

## Workflow

1. Identify the repeatable trigger: when should the skill be used?
2. Distill the workflow into concrete steps.
3. Remove one-off project details unless they are essential.
4. Create a lowercase hyphenated skill directory with `SKILL.md`.
5. Add YAML frontmatter:
   - `name`
   - `description`
   - optional `argument-hint`
6. Validate that the skill is useful from its description alone.

Avoid turning every note into a skill. Skillify only workflows that will be
reused.
