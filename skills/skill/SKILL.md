---
name: skill
description: 管理本地 skills —— list、add、remove、search、edit、setup 向导
argument-hint: "<command> [args]"
level: 2
---

# Skill 管理 CLI

通过类 CLI 命令管理 oh-my-kimi skills 的元 skill。

## 子命令

### /skill list

按作用域分组展示所有可用的 skill。

**行为：**
1. 扫描插件 `skills/` 目录里随包发布的内置 skill（只读）
2. 扫描 `${KIMI_CONFIG_DIR:-~/.claude}/skills/omc-learned/` 下的用户 skill
3. 扫描 `.omk/skills/` 下的项目 skill
4. 解析 YAML frontmatter 获取元数据
5. 用整齐的表格展示：

```
BUILT-IN SKILLS (bundled with oh-my-kimi):
| Name              | Description                    | Scope    |
|-------------------|--------------------------------|----------|
| visual-verdict    | Structured visual QA verdicts  | built-in |
| ralph             | Persistence loop               | built-in |

USER SKILLS (~/.claude/skills/omc-learned/):
| Name              | Triggers           | Quality | Usage | Scope |
|-------------------|--------------------|---------|-------|-------|
| error-handler     | fix, error         | 95%     | 42    | user  |
| api-builder       | api, endpoint      | 88%     | 23    | user  |

PROJECT SKILLS (.omk/skills/):
| Name              | Triggers           | Quality | Usage | Scope   |
|-------------------|--------------------|---------|-------|---------|
| test-runner       | test, run          | 92%     | 15    | project |
```

**回退：** 没有 quality / usage 统计时，显示「N/A」。

**内置 skill 说明：** 内置 skill 随 oh-my-kimi 发布，可被发现 / 读取，但**不**能通过 `/skill remove` 或 `/skill edit` 删除 / 编辑。

---

### /skill add [name]

创建新 skill 的交互式向导。

**行为：**
1. **询问 skill 名**（命令未提供时）
   - 校验：仅小写、仅连字符、无空格
2. **询问 description**
   - 一行清晰简洁的描述
3. **询问 triggers**（逗号分隔的关键词）
   - 示例："error, fix, debug"
4. **询问 argument hint**（可选）
   - 示例："<file> [options]"
5. **询问作用域：**
   - `user` → `${KIMI_CONFIG_DIR:-~/.claude}/skills/omc-learned/<name>/SKILL.md`
   - `project` → `.omk/skills/<name>/SKILL.md`
6. **按模板创建 skill 文件：**

```yaml
---
name: <name>
description: <description>
triggers:
  - <trigger1>
  - <trigger2>
argument-hint: "<args>"
---

# <Name> Skill

## Purpose

[描述本 skill 做什么]

## When to Activate

[描述 triggers 与条件]

## Workflow

1. [步骤 1]
2. [步骤 2]
3. [步骤 3]

## Examples

```
/oh-my-kimi:<name> example-arg
```

## Notes

[附加上下文、边界条件、坑]
```

7. **报告成功**，带上文件路径
8. **建议：** 「用 `/skill edit <name>` 自定义内容」

**示例：**
```
User: /skill add custom-logger
Assistant: Creating new skill 'custom-logger'...

Description: Enhanced logging with structured output
Triggers (comma-separated): log, logger, logging
Argument hint (optional): <level> [message]
Scope (user/project): user

✓ Created skill at ~/.claude/skills/omc-learned/custom-logger/SKILL.md
→ Edit with: /skill edit custom-logger
```

---

### /skill remove <name>

按名字删除一个 skill。

**行为：**
1. **在两个作用域中查找 skill：**
   - `${KIMI_CONFIG_DIR:-~/.claude}/skills/omc-learned/<name>/SKILL.md`
   - `.omk/skills/<name>/SKILL.md`
2. **找到时：**
   - 显示 skill 信息（name、description、作用域）
   - **请求确认：** "Delete '<name>' skill from <scope>? (yes/no)"
3. **确认后：**
   - 删除整个 skill 目录（例如 `${KIMI_CONFIG_DIR:-~/.claude}/skills/omc-learned/<name>/`）
   - 报告："✓ Removed skill '<name>' from <scope>"
4. **未找到时：**
   - 报告："✗ Skill '<name>' not found in user or project scope"

**安全：** 没有显式用户确认，永远不要删除。

**示例：**
```
User: /skill remove old-logger
Assistant: Found skill 'old-logger' in user scope:
  Description: Legacy logging utility
  Scope: user (~/.claude/skills/omc-learned/)

Delete 'old-logger' skill? (yes/no)

User: yes
Assistant: ✓ Removed skill 'old-logger' from user scope
```

---

### /skill edit <name>

交互式编辑已有 skill。

**行为：**
1. **按名字查找 skill**（搜索两个作用域）
2. **用 Read 工具读取当前内容**
3. **展示当前值：**
   ```
   Current skill 'custom-logger':
   - Description: Enhanced logging with structured output
   - Triggers: log, logger, logging
   - Argument hint: <level> [message]
   - Scope: user
   ```
4. **询问改什么：**
   - `description` —— 更新描述
   - `triggers` —— 更新 trigger 关键词
   - `argument-hint` —— 更新 argument hint
   - `content` —— 编辑完整 markdown 内容
   - `rename` —— 重命名 skill（移动文件）
   - `cancel` —— 不改动退出
5. **对所选字段：**
   - 显示当前值
   - 询问新值
   - 更新 YAML frontmatter 或内容
   - 写回文件
6. **报告成功**，附改动摘要

**示例：**
```
User: /skill edit custom-logger
Assistant: Current skill 'custom-logger':
  - Description: Enhanced logging with structured output
  - Triggers: log, logger, logging
  - Argument hint: <level> [message]

What would you like to edit? (description/triggers/argument-hint/content/rename/cancel)

User: triggers
Assistant: Current triggers: log, logger, logging
New triggers (comma-separated): log, logger, logging, trace

✓ Updated triggers for 'custom-logger'
```

---

### /skill search <query>

按内容、triggers、name 或 description 搜索 skill。

**行为：**
1. **扫描两个作用域里的所有 skill**
2. **不区分大小写匹配 query** 到：
   - skill 名
   - description
   - triggers
   - 完整 markdown 内容
3. **按上下文展示匹配：**

```
Found 3 skills matching "typescript error":

1. typescript-fixer (user)
   Description: Fix common TypeScript errors
   Match: "typescript error handling patterns"

2. error-handler (user)
   Description: Generic error handling utilities
   Match: "Supports TypeScript and JavaScript errors"

3. lint-fix (project)
   Description: Auto-fix linting errors
   Match: "TypeScript ESLint error resolution"
```

**排序：** name / triggers 上的命中优先于内容命中。

**示例：**
```
User: /skill search api endpoint
Assistant: Found 2 skills matching "api endpoint":

1. api-builder (user)
   Description: Generate REST API endpoints
   Triggers: api, endpoint, rest

2. backend-scaffold (project)
   Description: Scaffold backend services
   Match: "Creates API endpoint boilerplate"
```

---

### /skill info <name>

展示一个 skill 的详细信息。

**行为：**
1. **按名字查找 skill**（搜索两个作用域）
2. **解析 YAML frontmatter 与内容**
3. **展示完整详情：**

```
Skill: custom-logger
Scope: user (~/.claude/skills/omc-learned/custom-logger/)
Description: Enhanced logging with structured output
Triggers: log, logger, logging
Argument Hint: <level> [message]
Quality: 95% (if available)
Usage Count: 42 times (if available)
File Path: /home/user/.claude/skills/omc-learned/custom-logger/SKILL.md

--- FULL CONTENT ---
[完整 markdown 内容]
```

**未找到时：** 报错，建议用 `/skill search`。

**示例：**
```
User: /skill info custom-logger
Assistant: Skill: custom-logger
Scope: user
Description: Enhanced logging with structured output
Triggers: log, logger, logging
File: ~/.claude/skills/omc-learned/custom-logger/SKILL.md

--- CONTENT ---
# Custom Logger Skill

## Purpose
Enhanced logging with structured JSON output...
[剩余内容]
```

---

### /skill sync

在用户与项目作用域之间同步 skill。

**行为：**
1. **扫描两个作用域：**
   - 用户 skill：`${KIMI_CONFIG_DIR:-~/.claude}/skills/omc-learned/`
   - 项目 skill：`.omk/skills/`
2. **比较并分类：**
   - 仅用户有（项目没有）
   - 仅项目有（用户没有）
   - 两边都有
3. **展示同步机会：**

```
SYNC REPORT:

User-only skills (5):
  - error-handler
  - api-builder
  - custom-logger
  - test-generator
  - deploy-helper

Project-only skills (2):
  - test-runner
  - backend-scaffold

Common skills (3):
  - frontend-ui-ux
  - git-master
  - planner

Options:
  [1] Copy user skill to project
  [2] Copy project skill to user
  [3] View differences
  [4] Cancel
```

4. **处理用户选择：**
   - 选项 1：选要拷到项目的 skill
   - 选项 2：选要拷到用户的 skill
   - 选项 3：对共有 skill 做并排 diff
   - 选项 4：退出

**安全：** 没有确认绝不覆盖。

**示例：**
```
User: /skill sync
Assistant: Found 5 user-only skills and 2 project-only skills.

Copy 'error-handler' from user to project? (yes/no/skip)
User: yes
Assistant: ✓ Copied 'error-handler' to .omk/skills/

Copy 'api-builder' from user to project? (yes/no/skip)
User: skip
...
```

---

### /skill setup

配置与管理本地 skill 的交互式向导（前身为 local-skills-setup）。

**行为：**

#### 步骤 1：目录检查与设置

先检查 skill 目录是否存在，必要时创建：

```bash
# 检查并创建用户级 skill 目录
USER_SKILLS_DIR="${KIMI_CONFIG_DIR:-$HOME/.claude}/skills/omc-learned"
if [ -d "$USER_SKILLS_DIR" ]; then
  echo "User skills directory exists: $USER_SKILLS_DIR"
else
  mkdir -p "$USER_SKILLS_DIR"
  echo "Created user skills directory: $USER_SKILLS_DIR"
fi

# 检查并创建项目级 skill 目录
PROJECT_SKILLS_DIR=".omk/skills"
if [ -d "$PROJECT_SKILLS_DIR" ]; then
  echo "Project skills directory exists: $PROJECT_SKILLS_DIR"
else
  mkdir -p "$PROJECT_SKILLS_DIR"
  echo "Created project skills directory: $PROJECT_SKILLS_DIR"
fi
```

#### 步骤 2：skill 扫描与清点

扫描两个目录并给出完整清单：

```bash
# 扫描用户级 skill
echo "=== USER-LEVEL SKILLS (~/.claude/skills/omc-learned/) ==="
if [ -d "${KIMI_CONFIG_DIR:-$HOME/.claude}/skills/omc-learned" ]; then
  USER_COUNT=$(find "${KIMI_CONFIG_DIR:-$HOME/.claude}/skills/omc-learned" -name "*.md" 2>/dev/null | wc -l)
  echo "Total skills: $USER_COUNT"

  if [ $USER_COUNT -gt 0 ]; then
    echo ""
    echo "Skills found:"
    find "${KIMI_CONFIG_DIR:-$HOME/.claude}/skills/omc-learned" -name "*.md" -type f -exec sh -c '
      FILE="$1"
      NAME=$(grep -m1 "^name:" "$FILE" 2>/dev/null | sed "s/name: //")
      DESC=$(grep -m1 "^description:" "$FILE" 2>/dev/null | sed "s/description: //")
      MODIFIED=$(stat -c "%y" "$FILE" 2>/dev/null || stat -f "%Sm" "$FILE" 2>/dev/null)
      echo "  - $NAME"
      [ -n "$DESC" ] && echo "    Description: $DESC"
      echo "    Modified: $MODIFIED"
      echo ""
    ' sh {} \;
  fi
else
  echo "Directory not found"
fi

echo ""
echo "=== PROJECT-LEVEL SKILLS (.omk/skills/) ==="
if [ -d ".omk/skills" ]; then
  PROJECT_COUNT=$(find ".omk/skills" -name "*.md" 2>/dev/null | wc -l)
  echo "Total skills: $PROJECT_COUNT"

  if [ $PROJECT_COUNT -gt 0 ]; then
    echo ""
    echo "Skills found:"
    find ".omk/skills" -name "*.md" -type f -exec sh -c '
      FILE="$1"
      NAME=$(grep -m1 "^name:" "$FILE" 2>/dev/null | sed "s/name: //")
      DESC=$(grep -m1 "^description:" "$FILE" 2>/dev/null | sed "s/description: //")
      MODIFIED=$(stat -c "%y" "$FILE" 2>/dev/null || stat -f "%Sm" "$FILE" 2>/dev/null)
      echo "  - $NAME"
      [ -n "$DESC" ] && echo "    Description: $DESC"
      echo "    Modified: $MODIFIED"
      echo ""
    ' sh {} \;
  fi
else
  echo "Directory not found"
fi

# 汇总
TOTAL=$((USER_COUNT + PROJECT_COUNT))
echo "=== SUMMARY ==="
echo "Total skills across all directories: $TOTAL"
```

#### 步骤 3：快捷操作菜单

扫描后，用 AskUserQuestion 工具给出这些选项：

**问题：** 「想对本地 skill 做什么？」

**选项：**
1. **添加新 skill** —— 启动 skill 创建向导（调用 `/skill add`）
2. **列出所有 skill 详情** —— 展示完整清单（调用 `/skill list`）
3. **扫描对话中的模式** —— 分析当前对话里值得做成 skill 的模式
4. **导入 skill** —— 从 URL 或粘贴内容导入
5. **完成** —— 退出向导

**选项 3：扫描对话中的模式**

分析当前对话上下文，识别可能值得做成 skill 的模式。重点关注：
- 含有非显然解决方案的近期调试会话
- 需要侦查的棘手 bug
- 代码库特有的 workaround
- 花了时间才解决的错误模式

报告发现并询问用户是否要把其中某些抽成 skill（调用 `/skillify`；`/learner` 是已弃用兼容名）。

**选项 4：导入 skill**

请用户提供：
- **URL**：从 URL 下载 skill（例如 GitHub gist）
- **粘贴内容**：直接粘贴 skill markdown 内容

然后询问作用域：
- **用户级**（~/.claude/skills/omc-learned/）—— 所有项目可用
- **项目级**（.omk/skills/）—— 仅本项目

校验 skill 格式并保存到所选位置。

---

### /skill scan

快速扫描两个 skill 目录的命令（`/skill setup` 的子集）。

**行为：**
执行 `/skill setup` 步骤 2 的扫描，不进入交互向导。

---

## Skill 模板

通过 `/skill add` 或 `/skill setup` 创建 skill 时，针对常见类型提供快速模板：

### 错误解决模板

```markdown
---
id: error-[unique-id]
name: [Error Name]
description: Solution for [specific error in specific context]
source: conversation
triggers: ["error message fragment", "file path", "symptom"]
quality: high
---

# [Error Name]

## The Insight
这个错误的根因是什么？你发现了什么原则？

## Why This Matters
不知道这点会出什么问题？是什么症状把你引到这里？

## Recognition Pattern
怎么识别这个模式？有哪些信号？
- Error message: "[exact error]"
- File: [specific file path]
- Context: [when does this occur]

## The Approach
分步解决方案：
1. [带文件 / 行号引用的具体操作]
2. [带文件 / 行号引用的具体操作]
3. [验证步骤]

## Example
\`\`\`typescript
// Before (broken)
[problematic code]

// After (fixed)
[corrected code]
\`\`\`
```

### 工作流 Skill 模板

```markdown
---
id: workflow-[unique-id]
name: [Workflow Name]
description: Process for [specific task in this codebase]
source: conversation
triggers: ["task description", "file pattern", "goal keyword"]
quality: high
---

# [Workflow Name]

## The Insight
这个工作流与显而易见的做法有什么不同？

## Why This Matters
不按这个流程走会失败在哪里？

## Recognition Pattern
什么时候该用这个工作流？
- Task type: [specific task]
- Files involved: [specific patterns]
- Indicators: [how to recognize]

## The Approach
1. [带具体命令 / 文件的步骤]
2. [带具体命令 / 文件的步骤]
3. [验证]

## Gotchas
- [常见错误及如何避免]
- [边界情况及如何处理]
```

### 代码模式模板

```markdown
---
id: pattern-[unique-id]
name: [Pattern Name]
description: Pattern for [specific use case in this codebase]
source: conversation
triggers: ["code pattern", "file type", "problem domain"]
quality: high
---

# [Pattern Name]

## The Insight
这个模式背后的关键原则是什么？

## Why This Matters
这个模式在**本**代码库里解决了什么问题？

## Recognition Pattern
什么时候应用这个模式？
- File types: [specific files]
- Problem: [specific problem]
- Context: [codebase-specific context]

## The Approach
决策启发式，不只是代码：
1. [基于原则的步骤]
2. [基于原则的步骤]

## Example
\`\`\`typescript
[展示该原则的示例]
\`\`\`

## Anti-Pattern
**不该**做什么，以及为什么：
\`\`\`typescript
[常见错误]
\`\`\`
```

### 集成 Skill 模板

```markdown
---
id: integration-[unique-id]
name: [Integration Name]
description: How [system A] integrates with [system B] in this codebase
source: conversation
triggers: ["system name", "integration point", "config file"]
quality: high
---

# [Integration Name]

## The Insight
这两个系统的连接方式有什么非显然之处？

## Why This Matters
不理解这个集成会有什么坏？

## Recognition Pattern
什么时候你在和这个集成打交道？
- Files: [specific integration files]
- Config: [specific config locations]
- Symptoms: [what indicates integration issues]

## The Approach
如何正确地和这个集成打交道：
1. [带文件路径的配置步骤]
2. [带具体细节的设置步骤]
3. [验证步骤]

## Gotchas
- [集成特有的坑 #1]
- [集成特有的坑 #2]
```

---

## 错误处理

**所有命令都必须处理：**
- 文件 / 目录不存在
- 权限错误
- 不合法的 YAML frontmatter
- 重名 skill
- 不合法的 skill 名（空格、特殊字符）

**错误格式：**
```
✗ Error: <清晰的消息>
→ Suggestion: <有帮助的下一步>
```

---

## 用法示例

```bash
# 列出所有 skill
/skill list

# 创建新 skill
/skill add my-custom-skill

# 删除 skill
/skill remove old-skill

# 编辑已有 skill
/skill edit error-handler

# 搜索 skill
/skill search typescript error

# 查看详情
/skill info my-custom-skill

# 在作用域之间同步
/skill sync

# 启动配置向导
/skill setup

# 快速扫描
/skill scan
```

## 用法模式

### 直接命令模式

带参数调用时，跳过交互向导：

- `/oh-my-kimi:skill list` —— 展示详细的 skill 清单
- `/oh-my-kimi:skill add` —— 开始 skill 创建（调用 skillify）
- `/oh-my-kimi:skill scan` —— 扫描两个 skill 目录

### 交互模式

无参数调用时，跑完整的引导向导。

---

## 本地 Skill 的好处

**自动应用**：Claude 检测到 trigger 时自动应用 skill —— 不用记忆或搜索解决方案。

**版本控制**：项目级 skill（`.omk/skills/`）按设计是要随代码一起 commit 的，让整个团队都能受益。在 linked worktree 中，未提交的 skill 仅限该 worktree，worktree 被移除时一并消失。

**演进知识**：当你发现更好的方法、细化 trigger 时，skill 会随时间改进。

**减少 token 使用**：与其反复求解同样的问题，Claude 会高效地应用已知模式。

**代码库记忆**：保留本会被埋没在对话历史里的机构知识。

---

## Skill 质量指南

好的 skill 应该是：

1. **不可 Google** —— 搜索找不到
   - BAD："How to read files in TypeScript"
   - GOOD："This codebase uses custom path resolution requiring fileURLToPath"

2. **上下文特化** —— 引用**本**代码库的真实文件 / 错误
   - BAD："Use try/catch for error handling"
   - GOOD："The aiohttp proxy in server.py:42 crashes on ClientDisconnectedError"

3. **精确可执行** —— 告诉你具体做什么、在哪做
   - BAD："Handle edge cases"
   - GOOD："When seeing 'Cannot find module' in dist/, check tsconfig.json moduleResolution"

4. **来之不易** —— 需要相当的调试努力才得到
   - BAD：通用编程模式
   - GOOD："Race condition in worker.ts - Promise.all at line 89 needs await"

---

## 相关 Skill

- `/oh-my-kimi:skillify` —— 从当前对话抽取一个 skill（`/oh-my-kimi:learner` 是已弃用别名）
- `/oh-my-kimi:note` —— 保存快速笔记（比 skill 更非正式）
- `/oh-my-kimi:deepinit` —— 生成 AGENTS.md 代码库层级

---

## 示例会话

```
> /oh-my-kimi:skill list

Checking skill directories...
✓ User skills directory exists: ~/.claude/skills/omc-learned/
✓ Project skills directory exists: .omk/skills/

Scanning for skills...

=== USER-LEVEL SKILLS ===
Total skills: 3
  - async-network-error-handling
    Description: Pattern for handling independent I/O failures in async network code
    Modified: 2026-01-20 14:32:15

  - esm-path-resolution
    Description: Custom path resolution in ESM requiring fileURLToPath
    Modified: 2026-01-19 09:15:42

=== PROJECT-LEVEL SKILLS ===
Total skills: 5
  - session-timeout-fix
    Description: Fix for sessionId undefined after restart in session.ts
    Modified: 2026-01-22 16:45:23

  - build-cache-invalidation
    Description: When to clear TypeScript build cache to fix phantom errors
    Modified: 2026-01-21 11:28:37

=== SUMMARY ===
Total skills: 8

What would you like to do?
1. Add new skill
2. List all skills with details
3. Scan conversation for patterns
4. Import skill
5. Done
```

---

## 用户提示

- 定期跑 `/oh-my-kimi:skill list` 回顾你的 skill 库
- 解决完棘手 bug 后立刻跑 skillify 抓下来
- 用项目级 skill 存放代码库特定知识
- 用用户级 skill 存放可跨项目复用的通用模式
- 随时间回顾并精修 trigger，提升匹配准确度

---

## 实现注意

1. **YAML 解析：** 用 frontmatter 抽取元数据
2. **文件操作：** 用 Read / Write 工具；新文件**不**用 Edit
3. **用户确认：** 破坏性操作始终确认
4. **清晰反馈：** 用对勾（✓）、叉号（✗）、箭头（→）增强可读性
5. **作用域解析：** 始终同时检查用户与项目作用域
6. **校验：** 强制命名约定（仅小写、仅连字符）

---

## 相关 Skill

- `/oh-my-kimi:skillify` —— 从当前对话抽取一个 skill（`/oh-my-kimi:learner` 是已弃用别名）
- `/oh-my-kimi:note` —— 保存快速笔记（比 skill 更非正式）
- `/oh-my-kimi:deepinit` —— 生成 AGENTS.md 代码库层级

---

## 未来增强

- `/skill export <name>` —— 导出 skill 为可分享文件
- `/skill import <file>` —— 从文件导入 skill
- `/skill stats` —— 展示所有 skill 的使用统计
- `/skill validate` —— 检查所有 skill 的格式错误
- `/skill template <type>` —— 从预定义模板创建
