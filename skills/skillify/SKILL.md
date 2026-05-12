---
name: skillify
aliases: [learner]
description: 把当前会话里的一个可复用工作流，沉淀为一个可重用的 oh-my-kimi skill 草稿
---

# Skillify

当当前会话里发现一个可复用的工作流、应该变成一个可重用的 oh-my-kimi skill 时，使用本 skill。

> 兼容性：`/oh-my-kimi:learner` 是本 skill 的已弃用别名。在文档、提示与新工作流里优先使用 `/oh-my-kimi:skillify`。内部实现模块可能仍在使用 learner 这个名字。

## 目标
把一个成功完成的多步骤工作流抓成具体的 skill 草稿，避免以后再次重新发现。

## 质量门
在抽取一个 skill 之前，下面三点都应该为真：
- 「这个 5 分钟之内能搜到吗？」→ 否。
- 「它是不是这套代码库、项目或工作流特有的？」→ 是。
- 「发现它是否真的花了相当的调试、设计或运维成本？」→ 是。

优先沉淀承载决策启发、约束、坑、验证步骤的 skill。避免把通用片段、模板代码或库用法示例做成 skill —— 这些属于普通文档。

## 工作流
1. 识别本次会话所完成的可复用任务。
2. 抽取：
   - 输入
   - 有序步骤
   - 成功标准
   - 约束 / 坑
   - 验证证据
   - skill 最合适的存放位置
3. 决定这个工作流该归为：
   - 仓库内置 skill
   - 用户/项目级 learned skill
   - 只做成文档
4. 起草 learned skill 文件时，输出一个**完整的** skill 文件，以 YAML frontmatter 开头。
   - 永远不要只输出纯 markdown 的 skill 文件。
   - **不要**写不带 frontmatter 的纯 markdown。
   - 最小 frontmatter：
     ```yaml
     ---
     name: <skill-name>
     description: <一行描述>
     triggers:
       - <trigger-1>
       - <trigger-2>
     ---
     ```
   - 把 learned / user / project 类型的 skill 写到扁平的、文件支撑的路径下：
     - `${KIMI_CONFIG_DIR:-~/.claude}/skills/omc-learned/<skill-name>.md`
     - `.omk/skills/<skill-name>.md`
   - 记住：未提交的 skill 在被 commit 或拷贝到用户级目录之前，仍然是 worktree-local 的。
5. 草拟 skill 文件的其余部分：清晰的 triggers、步骤、成功标准、坑。
6. 指出仍然太模糊、不宜直接编码进去的内容。

## 规则
- 只抓真正可复用的工作流。
- 让 skill 保持实用、有边界。
- 优先用显式的成功标准，而不是模糊的描述。
- 如果工作流仍有未解决的分支决策，先在起草前注明。
- 出于兼容性保留 `omc-learned` 作为存储目录名；不要把它当作公开调用名展示。

## 输出
- 建议的 skill 名
- 目标位置
- 草稿工作流结构或完整的 skill 文件
- 验证或质量门的备注
- 仍有疑问的开放问题（若有）
