---
name: ai-slop-cleaner
description: 跑反 slop 的清理 / 重构 / 去 slop 工作流
---

# AI Slop Cleaner Skill

用「回归测试先行、按 smell 逐一清理」的工作流减少 AI 生成的 slop，在保留行为的同时提升信号质量。

## 何时使用

下列情形使用该 skill：
- 一段代码路径能跑通，但臃肿、嘈杂、重复或过度抽象
- 用户要求 “cleanup”、“refactor” 或 “deslop” AI 生成的产物
- 后续实现留下了重复代码、死代码、薄弱边界、缺失测试、fallback 类代码或不必要的包装层
- 你需要一套有纪律的清理工作流，但不希望进行大范围重写

## Kimi 工作流指引对齐

- 输出保持简洁且信息密度高，除非有风险或用户要求更详细。
- 把用户的新指令当作本地工作流更新，但不丢弃此前不冲突的约束。
- 持续使用检查、测试、diagnostics 与验证，直到清理工作有据可依。
- 在清晰、可逆的清理步骤上自动推进；只在选择会实质改变范围或行为时才询问。

## Scoped 文件清单与 Ralph 工作流

- 该 skill 可以接受一份**文件清单 scope**，而不是整个功能区域。
- 当调用方提供一份变更文件列表（例如 Ralph 会话拥有的变更）时，把清理严格限制在这些文件内。
- 在 **Ralph 工作流**中，强制的 deslop pass 应只对 Ralph 的变更文件运行该 skill，除非调用方明确要求否则使用标准模式。

## 流程

1. **先用回归测试锁定行为**
   - 识别绝对不能改变的行为
   - 在编辑清理候选之前，先添加或运行有针对性的回归测试
   - 如果当前没有测试覆盖，先做最小必要的测试覆盖
   - 对 fallback 类代码，清理前要覆盖主路径以及任何被保留的兼容性 / fail-safe fallback

2. **写代码前先做清理计划**
   - 列出要消除的具体 smell
   - 把这一遍的范围限定在请求的文件 / scope
   - 如果提供了文件清单 scope，就把这一遍限制在该变更文件清单上
   - 在计划里包含 fallback 的发现、分类与升级状态
   - 把修复顺序从最安全 / 信号最高排到最有风险
   - 清理计划没有显式之前不要动代码

3. **编辑前先盘点 fallback 类代码**
   - 在请求 scope 内搜索 fallback 类的检测信号：quick hacks、temporary workaround、temporary fallback、just bypass、just skip、fallback if it fails、被吞掉的错误、silent defaults、宽泛的兼容性 shim、重复的备用执行路径
   - 改之前先给每个发现分类：
     - **Masking fallback slop** —— 隐藏错误或证据、绕过主契约、压制测试或校验、吞掉失败、silent default，或新增未经测试的备用路径
     - **Grounded compatibility/fail-safe fallback** —— 限定在外部 / 版本 / fail-safe 边界，记录了原因，保留了失败证据，并且对主路径与 fallback 行为都有回归测试
   - 在保留 fallback 路径之前，优先选根因修复、删除、边界修复或显式失败行为
   - 对于宽泛、模糊、跨层或带架构性的 fallback 类代码，在编辑前用 `$ralplan` 走共识决议
   - 递归保护：如果你已经在 ralplan、ralph、team 或其他 oh-my-kimi 工作流里，不要再嵌套派出 `$ralplan`；把发现记录下来挂到当前的 ralplan、leader 或 plan 交接上即可

4. **编辑前对问题分类**
   - **Fallback 类代码** —— masking fallback、workaround 分支、bypass、被吞错误、silent default、宽泛 shim、备用执行路径
   - **重复** —— 重复逻辑、复制粘贴的分支、冗余 helper
   - **死代码** —— 未使用代码、不可达分支、过期 flag、调试残留
   - **不必要的抽象** —— 直通包装、推测性间接层、一次性使用的 helper 层
   - **边界违例** —— 隐藏耦合、责任泄漏、错层的导入或副作用
   - **UI / 设计 slop** —— 把视觉输出当作上下文敏感的信号，而不是绝对禁令；当原因清楚时保留有意为之的品牌、设计系统、可访问性或产品上下文例外
     - 韩语正文过小：质疑 11-12px 的正文字号；韩语正文一般需要 14px 或更大，除非有面向密集且可访问的系统明确支持更小字号
     - 无意义的层次堆叠：避免在每个 logo、面板、卡片、图标、背景与 step block 上都加 box shadow，特别是层级或交互暗示并不需要时
     - 重复的内容脚手架：精简反复堆叠的 eyebrow + 标题 + 描述 + 段落，以及填充式解释文字、毫无意义的通用 emoji 徽章
     - 默认 AI 调色板：当不存在品牌、语义或系统上的理由时，质疑像 #3B82F6 这种蓝紫默认色
     - 过度完美的网格：当产品上下文更适合节奏感、非对称、轮播切分、bento 构图或重点对比时，避免下意识地用整齐的 3 列 / 4 列卡片网格
     - 极端渐变：除非品牌或活动有意为之，否则把那种「AI demo」级的渐变收一收
   - **缺失测试** —— 行为没被锁定、回归覆盖薄弱、边界情况有缺口

5. **一次只处理一种 smell**
   - **Fallback 类代码决议闸口** —— 在继续之前移除 masking fallback slop、修复根因，或对模糊情况进行升级
   - **Pass 1：删除死代码**
   - **Pass 2：去除重复**
   - **Pass 3：命名 / 错误处理清理**
   - **Pass 4：测试加固**
   - 每一遍之后重新跑定向验证
   - 不要把无关的重构捆进同一组编辑

6. **跑质量闸口**
   - 回归测试保持绿
   - Lint 通过
   - Typecheck 通过
   - 相关单元 / 集成测试通过
   - 当可用时跑静态 / 安全扫描
   - diff 保持最小、范围受控
   - 不引入新的抽象或依赖，除非明确要求

7. **以信息密集的报告收尾**
   - 变更文件
   - 做了哪些简化
   - Fallback 发现、分类与升级状态
   - 跑过的测试 / diagnostics / 构建检查
   - 若 scope 含视觉 / UI 文件，给出 UI / 设计审查清单的发现
   - 剩余风险
   - 残留的后续项或有意推迟的清理

## Output Format

```text
AI SLOP CLEANUP REPORT
======================

Scope: [files or feature area]
Behavior Lock: [targeted regression tests added/run]
Cleanup Plan: [bounded smells and order]
Fallback Findings: [none, or finding -> masking fallback slop / grounded compatibility/fail-safe fallback -> escalation status]
UI/Design Findings: [none/N/A, or signal -> action taken/deferred -> intentional exception rationale]

Passes Completed:
- Fallback-like code resolution gate - [root-cause repair, explicit failure behavior, preserved grounded fallback, or ralplan handoff]
1. Pass 1: Dead code deletion - [concise fix]
2. Pass 2: Duplicate removal - [concise fix]
3. Pass 3: Naming/error handling cleanup - [concise fix]
4. Pass 4: Test reinforcement - [concise fix]

Quality Gates:
- Regression tests: PASS/FAIL
- Lint: PASS/FAIL
- Typecheck: PASS/FAIL
- Tests: PASS/FAIL
- Static/security scan: PASS/FAIL or N/A

Changed Files:
- [path] - [simplification]

Fallback Review:
- Findings: [fallback-like findings detected]
- Classification: [masking fallback slop | grounded fallback]
- Escalation Status: [none | raised to leader/ralplan | no escalation]

Remaining Risks:
- [none or short deferred item]
```

## 场景示例

**Good：** 在测试已经锁定行为、下一遍 smell pass 也清楚的情况下，用户说 `continue`。继续做下一遍受限范围的清理 pass。

**Good：** 规划完成后用户把范围缩到具体文件。保留「回归测试先行」的工作流，但在新的局部范围内执行。

**Bad：** 在用测试保护行为之前就开始重写架构。

**Bad：** 把多个 smell 类别揉成一次大重构，期间没有任何中间验证。

**Bad：** 保留一条 `fallback if it fails` 的分支，在吞掉错误后 silent default，而不是修根因或让失败显式化。

**Good：** 一个版本相关的兼容 shim 范围窄、有文档、保留错误证据、对主路径和 fallback 都有回归测试，并被报告为 grounded compatibility/fail-safe fallback。
