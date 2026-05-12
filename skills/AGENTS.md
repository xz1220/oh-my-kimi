# Skill Catalog Notes

Skills in this directory target Kimi CLI's Agent Skills format:

- Directory layout: `skills/<name>/SKILL.md`
- Frontmatter: lowercase hyphenated `name`, concise `description`
- Content: bounded workflow instructions, no dependency on unavailable host
  runtime commands

Keep skills portable and Kimi-native. If a workflow requires a helper script,
place it inside the skill directory or reference a repository script explicitly.
