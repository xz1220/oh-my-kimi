---
name: deepinit
description: 用分层 AGENTS.md 文档对代码库做深度初始化
level: 4
---

# Deep Init Skill

跨整个代码库创建全面、分层的 AGENTS.md 文档。

## 核心概念

AGENTS.md 文件作为 **AI 可读文档**，帮助 agent 理解：
- 每个目录里有什么
- 各组件之间如何关联
- 在该区域工作时的特殊说明
- 依赖与关系

## 分层标签系统

每个 AGENTS.md（除根目录外）都包含一个 parent 引用标签：

```markdown
<!-- Parent: ../AGENTS.md -->
```

这构成可导航的层级：
```
/AGENTS.md                          ← Root (no parent tag)
├── src/AGENTS.md                   ← <!-- Parent: ../AGENTS.md -->
│   ├── src/components/AGENTS.md    ← <!-- Parent: ../AGENTS.md -->
│   └── src/utils/AGENTS.md         ← <!-- Parent: ../AGENTS.md -->
└── docs/AGENTS.md                  ← <!-- Parent: ../AGENTS.md -->
```

## AGENTS.md 模板

```markdown
<!-- Parent: {relative_path_to_parent}/AGENTS.md -->
<!-- Generated: {timestamp} | Updated: {timestamp} -->

# {Directory Name}

## 用途
{One-paragraph description of what this directory contains and its role}

## 关键文件
{List each significant file with a one-line description}

| File | Description |
|------|-------------|
| `file.ts` | Brief description of purpose |

## 子目录
{List each subdirectory with brief purpose}

| Directory | Purpose |
|-----------|---------|
| `subdir/` | What it contains (see `subdir/AGENTS.md`) |

## 面向 AI Agents

### 在此目录工作
{Special instructions for AI agents modifying files here}

### 测试要求
{How to test changes in this directory}

### 常见模式
{Code patterns or conventions used here}

## 依赖

### 内部
{References to other parts of the codebase this depends on}

### 外部
{Key external packages/libraries used}

<!-- MANUAL: Any manually added notes below this line are preserved on regeneration -->
```

## 执行工作流

### Step 1：绘制目录结构

```
Agent(subagent_type="explore", model="haiku",
  prompt="List all directories recursively. Exclude: node_modules, .git, dist, build, __pycache__, .venv, coverage, .next, .nuxt")
```

### Step 2：制定工作计划

按深度层级为每个目录生成 todo 项：

```
Level 0: / (root)
Level 1: /src, /docs, /tests
Level 2: /src/components, /src/utils, /docs/api
...
```

### Step 3：逐层生成

**IMPORTANT**：先生成父层级再生成子层级，确保 parent 引用有效。

对每个目录：
1. 读取该目录下所有文件
2. 分析用途与关系
3. 生成 AGENTS.md 内容
4. 写入文件，带正确的 parent 引用

### Step 4：比较并更新（若已存在）

当 AGENTS.md 已存在时：

1. **读取已有内容**
2. **识别段落**：
   - 自动生成段（可更新）
   - 手工段（`<!-- MANUAL -->` 保留）
3. **比较**：
   - 是否新增文件？
   - 是否删除文件？
   - 结构是否变化？
4. **合并**：
   - 更新自动生成内容
   - 保留手工注释
   - 更新时间戳

### Step 5：验证层级

生成后跑校验：

| Check | How to Verify | Corrective Action |
|-------|--------------|-------------------|
| Parent references resolve | Read each AGENTS.md, check `<!-- Parent: -->` path exists | Fix path or remove orphan |
| No orphaned AGENTS.md | Compare AGENTS.md locations to directory structure | Delete orphaned files |
| Completeness | List all directories, check for AGENTS.md | Generate missing files |
| Timestamps current | Check `<!-- Generated: -->` dates | Regenerate outdated files |

校验脚本模式：
```bash
# Find all AGENTS.md files
find . -name "AGENTS.md" -type f

# Check parent references
grep -r "<!-- Parent:" --include="AGENTS.md" .
```

## 智能委派

| Task | Agent |
|------|-------|
| Directory mapping | `explore` |
| File analysis | `architect` |
| Content generation | `writer` |
| AGENTS.md writes | `writer` |

## 空目录处理

遇到空或近空目录时：

| Condition | Action |
|-----------|--------|
| No files, no subdirectories | **Skip** - do not create AGENTS.md |
| No files, has subdirectories | Create minimal AGENTS.md with subdirectory listing only |
| Has only generated files (*.min.js, *.map) | Skip or minimal AGENTS.md |
| Has only config files | Create AGENTS.md describing configuration purpose |

仅含目录的容器的最小 AGENTS.md 示例：
```markdown
<!-- Parent: ../AGENTS.md -->
# {Directory Name}

## 用途
Container directory for organizing related modules.

## 子目录
| Directory | Purpose |
|-----------|---------|
| `subdir/` | Description (see `subdir/AGENTS.md`) |
```

## 并行化规则

1. **同层目录**：并行处理
2. **不同层级**：串行（先父后子）
3. **大目录**：每个目录派一个专用 agent
4. **小目录**：把多个合并到一个 agent

## 质量标准

### 必须包含
- [ ] 准确的文件描述
- [ ] 正确的 parent 引用
- [ ] 子目录链接
- [ ] AI agent 指令

### 必须避免
- [ ] 泛泛的 boilerplate
- [ ] 错误的文件名
- [ ] 损坏的 parent 引用
- [ ] 漏掉重要文件

## 输出示例

### 根 AGENTS.md
```markdown
<!-- Generated: 2024-01-15 | Updated: 2024-01-15 -->

# my-project

## 用途
A web application for managing user tasks with real-time collaboration features.

## 关键文件
| File | Description |
|------|-------------|
| `package.json` | Project dependencies and scripts |
| `tsconfig.json` | TypeScript configuration |
| `.env.example` | Environment variable template |

## 子目录
| Directory | Purpose |
|-----------|---------|
| `src/` | Application source code (see `src/AGENTS.md`) |
| `docs/` | Documentation (see `docs/AGENTS.md`) |
| `tests/` | Test suites (see `tests/AGENTS.md`) |

## 面向 AI Agents

### 在此目录工作
- Always install dependencies after modifying the project manifest
- Use TypeScript strict mode
- Follow ESLint rules

### 测试要求
- Run tests before committing
- Ensure >80% coverage

### 常见模式
- Use barrel exports (index.ts)
- Prefer functional components

## 依赖

### 外部
- React 18.x - UI framework
- TypeScript 5.x - Type safety
- Vite - Build tool

<!-- MANUAL: Custom project notes can be added below -->
```

### 嵌套 AGENTS.md
```markdown
<!-- Parent: ../AGENTS.md -->
<!-- Generated: 2024-01-15 | Updated: 2024-01-15 -->

# components

## 用途
Reusable React components organized by feature and complexity.

## 关键文件
| File | Description |
|------|-------------|
| `index.ts` | Barrel export for all components |
| `Button.tsx` | Primary button component |
| `Modal.tsx` | Modal dialog component |

## 子目录
| Directory | Purpose |
|-----------|---------|
| `forms/` | Form-related components (see `forms/AGENTS.md`) |
| `layout/` | Layout components (see `layout/AGENTS.md`) |

## 面向 AI Agents

### 在此目录工作
- Each component has its own file
- Use CSS modules for styling
- Export via index.ts

### 测试要求
- Unit tests in `__tests__/` subdirectory
- Use React Testing Library

### 常见模式
- Props interfaces defined above component
- Use forwardRef for DOM-exposing components

## 依赖

### 内部
- `src/hooks/` - Custom hooks used by components
- `src/utils/` - Utility functions

### 外部
- `clsx` - Conditional class names
- `lucide-react` - Icons

<!-- MANUAL: -->
```

## 触发更新模式

在已经有 AGENTS.md 文件的代码库上运行时：

1. 先检测已有文件
2. 读取并解析已有内容
3. 分析当前目录状态
4. 计算已有内容与当前的 diff
5. 在保留手工段的同时应用更新

## 性能考虑

- **缓存目录列表** —— 不要重复扫描同一目录
- **批量处理小目录** —— 一次处理多个
- **跳过未变更** —— 目录无变化就跳过重新生成
- **并行写入** —— 多个 agent 同时写不同文件
