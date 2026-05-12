---
name: code-review
description: 跑一次全面的代码评审
---

# Code Review Skill

带严重程度评级地做一次质量、安全、可维护性的彻底代码评审。

## 何时使用

下列情形触发该 skill：
- 用户说 "review this code"、"code review"
- 合并 PR 之前
- 实现完一个大功能之后
- 用户想要质量评估

## GPT-5.5 指引对齐

- 默认采取「outcome-first」的推进与完成汇报：先给出目标结果、证据、校验状态与停止条件，再补流程细节。
- 把用户的新任务更新当作当前工作流分支的本地覆盖，同时保留此前不冲突的约束。
- 如果正确性依赖更多检查、检索、执行或校验，就持续使用相关工具，直到评审有据可依；证据足够时就停。
- 对清晰、低风险、可逆的下一步自动推进；只有当下一步会带来实质分支、有破坏性、需要凭证、对接外部生产或依赖偏好时才询问。

并行委派给 `code-reviewer` 与 `architect` 两条 lane 做双线评审：

1. **识别变更**
   - 跑 `git diff` 找出变更文件
   - 确定评审范围（特定文件或整个 PR）

2. **启动并行评审 lane**
   - **`code-reviewer` lane** —— 负责规格符合、安全、代码质量、性能、可维护性方面的发现
   - **`architect` lane** —— 负责 devil's-advocate / 设计权衡视角
   - 两条 lane 并行跑，在最终综合之前各自产出独立结果

3. **评审类别**
   - **Security** —— 硬编码 secret、注入风险、XSS、CSRF
   - **Code Quality** —— 函数大小、复杂度、嵌套深度
   - **Performance** —— 算法效率、N+1 查询、缓存
   - **Best Practices** —— 命名、文档、错误处理
   - **Maintainability** —— 重复、耦合、可测性

4. **严重程度评级**
   - **CRITICAL** —— 安全漏洞（合并前必须修）
   - **HIGH** —— bug 或重大代码 smell（合并前应修）
   - **MEDIUM** —— 较小问题（有空就修）
   - **LOW** —— 风格 / 建议（看情况修）

5. **架构状态契约**
   - **CLEAR** —— 未发现未解决的架构性阻塞
   - **WATCH** —— 非阻塞的设计 / 权衡顾虑，必须出现在最终综合里
   - **BLOCK** —— 未解决的设计顾虑，阻止给出可合并结论

6. **具体建议**
   - 每条问题给出 file:line 定位
   - 给出具体修复建议
   - 适用时给代码示例

7. **最终综合**
   - 把 `code-reviewer` 的建议与 architect 状态合成一条最终结论
   - 确定性的合并闸门规则：
     - 若 architect 状态为 **BLOCK**，最终建议为 **REQUEST CHANGES**
     - 否则若 `code-reviewer` 建议为 **REQUEST CHANGES**，最终建议为 **REQUEST CHANGES**
     - 否则若 architect 状态为 **WATCH**，最终建议为 **COMMENT**
     - 否则最终建议跟随 `code-reviewer` lane
   - 最终报告必须让 architect blocker 一眼可见

## Agent 委派

```
delegate(
  role="code-reviewer",
  tier="THOROUGH",
  prompt="CODE REVIEW TASK

Review code changes for quality, security, and maintainability.

This is the code/spec/security lane. Do not absorb architectural ownership.

Scope: [git diff or specific files]

Review Checklist:
- Security vulnerabilities (OWASP Top 10)
- Code quality (complexity, duplication)
- Performance issues (N+1, inefficient algorithms)
- Best practices (naming, documentation, error handling)
- Maintainability (coupling, testability)

Output: Code review report with:
- Files reviewed count
- Issues by severity (CRITICAL, HIGH, MEDIUM, LOW)
- Specific file:line locations
- Fix recommendations
- Approval recommendation (APPROVE / REQUEST CHANGES / COMMENT)"
)

delegate(
  role="architect",
  tier="THOROUGH",
  prompt="ARCHITECTURE / DEVIL'S-ADVOCATE REVIEW TASK

Review the same code changes from the architecture/tradeoff perspective.

Scope: [git diff or specific files]

Focus:
- System boundaries and interfaces
- Hidden coupling or long-term maintainability risks
- Tradeoff tension the main reviewer might miss
- Strongest counterargument against approving as-is

Output:
- Architectural Status: CLEAR / WATCH / BLOCK
- File:line evidence for each concern
- Concrete tradeoff or design recommendation"
)

Run both lanes in parallel, then synthesize them with the deterministic rules above.
```

## 外部模型咨询（建议）

code-reviewer agent 应当咨询 Codex 做交叉验证。

### 协议
1. **先形成自己的评审** —— 独立完成一次评审
2. **咨询以做验证** —— 用 Codex 交叉核对发现
3. **批判性评估** —— 永远不要盲目采纳外部发现
4. **优雅回退** —— 工具不可用时绝不阻塞

### 何时咨询
- 安全敏感的代码改动
- 复杂的架构模式
- 不熟悉的代码库或语言
- 高风险的生产代码

### 何时跳过
- 简单重构
- 已经熟悉的模式
- 时效紧迫的评审
- 小且孤立的改动

### 工具使用
优先用 native `code-reviewer` agent 咨询，或 CLI 支持的 `ask_codex` 接口。仅当已启用时才用可选的 MCP 兼容 ask 工具。咨询工具不可用时回退到 `code-reviewer` agent。

**注意：** Codex 调用最长可能耗时 1 小时，咨询前请考虑评审时限。

## Output Format

```
CODE REVIEW REPORT
==================

Files Reviewed: 8
Total Issues: 12
Architectural Status: WATCH

CRITICAL (0)
-----------
(none)

HIGH (0)
--------
(none)

MEDIUM (7)
----------
1. src/api/auth.ts:42
   Issue: Email normalization logic is duplicated instead of reusing the shared helper
   Risk: Validation rules can drift between authentication paths
   Fix: Route both paths through the shared normalization helper

2. src/components/UserProfile.tsx:89
   Issue: Derived permissions are recalculated on every render
   Risk: Avoidable work during profile refreshes
   Fix: Memoize the derived permissions list or compute it upstream

3. src/utils/validation.ts:15
   Issue: Form-layer and server-layer validation messages are defined separately
   Risk: User-facing validation guidance can become inconsistent
   Fix: Share one validation message helper across both call sites

LOW (5)
-------
...

ARCHITECTURE WATCHLIST
----------------------
- src/review/orchestrator.ts:88
  Concern: Review result synthesis relies on implicit ordering rather than an explicit blocker contract
  Status: WATCH
  Recommendation: Define deterministic merge gating before expanding reviewers

SYNTHESIS
---------
- code-reviewer recommendation: COMMENT
- architect status: WATCH
- final recommendation: COMMENT

RECOMMENDATION: COMMENT

Address any WATCH concerns before treating the change as merge-ready.
```

## 评审清单

`code-reviewer` lane 检查项：

### Security
- [ ] 无硬编码 secret（API key、密码、token）
- [ ] 所有用户输入都做了 sanitize
- [ ] 防 SQL/NoSQL 注入
- [ ] 防 XSS（输出已转义）
- [ ] 状态变更操作有 CSRF 防护
- [ ] 鉴权 / 授权落实到位

### Code Quality
- [ ] 函数 < 50 行（参考）
- [ ] 圈复杂度 < 10
- [ ] 无深层嵌套（> 4 层）
- [ ] 无重复逻辑（DRY 原则）
- [ ] 命名清晰、描述性

### Performance
- [ ] 没有 N+1 查询模式
- [ ] 该用缓存的地方用了缓存
- [ ] 算法高效（能 O(n) 就别 O(n²)）
- [ ] 没有不必要的重渲染（React/Vue）

### Best Practices
- [ ] 错误处理存在且合理
- [ ] 日志级别合理
- [ ] 公开 API 有文档
- [ ] 关键路径有测试
- [ ] 没有注释掉的代码

## Architect Lane 清单

`architect` lane 检查项：

- [ ] 边界 / 接口的变化是显式的
- [ ] 新的耦合 / 权衡风险被显式提出
- [ ] 长期可维护性顾虑有证据支撑
- [ ] 架构状态在 `CLEAR`、`WATCH` 或 `BLOCK` 之中
- [ ] 任何 `BLOCK` 顾虑都说明了为什么不能给出可合并结论

## 审批标准

**APPROVE** —— `code-reviewer` 返回 APPROVE 且 architect 状态为 `CLEAR`
**REQUEST CHANGES** —— `code-reviewer` 返回 REQUEST CHANGES 或 architect 状态为 `BLOCK`
**COMMENT** —— `code-reviewer` 返回 COMMENT 且 architect 状态为 `CLEAR`，或 architect 状态为 `WATCH`，或仅剩 LOW/MEDIUM 的改进项


## 场景示例

**Good：** 工作流已经有清晰的下一步，用户说 `continue`。沿着当前分支继续，而不是重启或重复同一个问题。

**Good：** 用户只改变输出形态或下游交付步骤（例如 `make a PR`）。保留此前不冲突的工作流约束，把更新在局部应用。

**Bad：** 用户说 `continue`，工作流却重启发现流程，或在缺失校验 / 证据被收集之前就停下。

## 与其他 skill 配合

**与 Team：**
```
/team "review recent auth changes and report findings"
```
跨多个专精 agent 协同执行评审。

**与 Ralph：**
```
/ralph code-review then fix all issues
```
在显式 Ralph 路径上，评审发现应直接流向自动修复跟进，无需再问权限。普通的 `code-review` 本身保持只读，**不**承诺自动修复。

**与 Ultrawork：**
```
/ultrawork review all files in src/
```
跨多文件并行代码评审。

## 最佳实践

- **早评审** —— 在问题复利前抓住它
- **常评审** —— 小而频繁的评审胜过一次性巨型评审
- **优先处理 CRITICAL/HIGH** —— 安全与 bug 立刻修
- **考虑上下文** —— 有些「问题」可能是有意的取舍
- **从评审中学习** —— 用反馈改进编码习惯
