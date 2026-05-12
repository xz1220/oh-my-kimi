# Skill 目录说明

本目录下的 skill 面向 Kimi CLI 的 Agent Skills 格式：

- 目录布局：`skills/<name>/SKILL.md`
- frontmatter：小写带连字符的 `name`，简练的 `description`
- 内容：边界清晰的工作流指令，不依赖未提供的宿主运行时命令

保持 skill 可移植、贴近 Kimi 原生。如果某个工作流需要辅助脚本，把脚本放在该 skill 目录内，或在文档里显式引用仓库内的脚本路径。
