---
name: ralplan
description: $plan --consensus 的别名
---

# Ralplan（共识式规划别名）

Ralplan 是 `$plan --consensus` 的简写别名。它会触发 Planner、Architect、Critic 三个 agent 的迭代规划，直到达成共识，并使用 **RALPLAN-DR 结构化审议**（默认 short 模式，高风险工作走 deliberate 模式）。

## 用法

```
$ralplan "task description"
```

## Flags

- `--interactive`：在关键决策点开启用户提示（步骤 2 的草案评审与步骤 6 的最终批准）。不加该 flag 时工作流全自动跑 —— Planner → Architect → Critic 循环 —— 直接输出最终计划，不再请求确认。
- `--deliberate`：为高风险工作强制 deliberate 模式。会加上 pre-mortem（3 个场景）与扩展测试规划（unit/integration/e2e/observability）。不加该 flag 时，如果请求明确暗示高风险（鉴权/安全、迁移、破坏性改动、生产事故、合规/PII、公开 API 破坏），deliberate 模式仍可能自动开启。

## interactive 模式用法

```
$ralplan --interactive "task description"
```

## 行为

## 与 GPT-5.5 指引对齐

采用共享的工作流指引模式：结果优先表述、对多步规划给出简洁可见的更新、把新指令当作当前工作流分支的本地覆盖、证据支撑的规划与验证预期、显式停止规则、合身的实现 / PRD 形态，以及对安全可逆步骤的自动延续。只在涉及实质性、破坏性、需要凭据、外部生产或依赖偏好的分支时才询问。

本 skill 在共识模式下调用 Plan skill：

```
$plan --consensus <arguments>
$plan --consensus --interactive <arguments>
```

共识工作流：
1. **Planner** 制定自适应计划（按任务规模合身，不必非要正好五步），并在评审前给出一份紧凑的 **RALPLAN-DR 摘要**：
   - Principles（3-5 条）
   - Decision Drivers（前 3）
   - Viable Options（>=2），含有界的 pros/cons
   - 若只剩一个可行方案，需显式给出对替代方案的失效理由
   - 仅 deliberate 模式：pre-mortem（3 个场景）+ 扩展测试计划（unit/integration/e2e/observability）
2. **用户反馈** *(仅 --interactive)*：如果设置了 `--interactive`，在评审前用结构化提问 UI（在已 attach 的 tmux 里用 `omk question`；在 tmux 之外可用时用原生结构化输入）呈现草案计划 **以及 Principles / Drivers / Options 摘要**（Proceed to review / Request changes / Skip review）。否则自动进入评审。
3. **Architect** 评审架构合理性，必须给出最强的反方稻草人（steelman antithesis）、至少一个真实的权衡张力，并尽可能给出综合（synthesis）—— **等它完成再进入步骤 4**。在 deliberate 模式下，Architect 应显式标记原则违反。
4. **Critic** 按质量标准评估 —— 仅在步骤 3 完成后运行。Critic 必须强制要求 principle-option 一致性、公平的替代方案、风险缓解的清晰度、可测试的验收标准与具体的验证步骤。在 deliberate 模式下，Critic 必须拒绝缺失或薄弱的 pre-mortem 或扩展测试计划。
5. **重审循环**（最多 5 次迭代）：Critic 给出任何非 `APPROVE` 的判定（`ITERATE` 或 `REJECT`）都**必须**跑同一条完整闭环：
   a. 收集 Architect + Critic 反馈
   b. 让 Planner 修订计划
   c. 回到 Architect 评审
   d. 回到 Critic 评估
   e. 重复本循环，直到 Critic 返回 `APPROVE` 或达到 5 次迭代
   f. 若 5 次迭代仍未 `APPROVE`，把最好的版本呈现给用户
6. Critic 批准时 *(仅 --interactive)*：如果设置了 `--interactive`，用结构化提问 UI 呈现计划与批准选项（Approve and execute via ralph / Approve and implement via team / Start a goal-mode follow-up / Request changes / Reject）。最终计划必须包含 ADR（Decision、Drivers、Alternatives considered、Why chosen、Consequences、Follow-ups）、显式的 available-agent-types 名单、针对 `ralph` 与 `team` 的具体后续人员配置建议、按通道建议的 reasoning 等级、显式的 `omk team` / `$team` 启动提示、具体的 **team verification** 路径，以及面向产品的 **Goal-Mode Follow-up Suggestions** 段。默认推荐 `$ultragoal` 作为目标模式后续；当上下文是研究项目时改为 `$autoresearch-goal`；当上下文是优化或性能项目时改为 `$performance-goal`。其他情况下，输出最终计划并停止。
7. *(仅 --interactive)* 用户选择：Approve（ralph、team 或某个 goal-mode 后续）、Request changes 或 Reject。
8. *(仅 --interactive)* 批准时：用已批准计划与匹配的成功 / 评估上下文调用 `$ralph` 做顺序执行、`$team` 做并行团队执行，或选中的 goal-mode 后续（`$ultragoal`、`$autoresearch-goal` 或 `$performance-goal`）—— 永远不要直接实现。对 Ralph / team 路径，保留已批准计划中的显式 available-agent-types 名单、按通道的 reasoning 指引、角色 / 人员分配指引、启动提示与验证路径指引。

> **重要：** 步骤 3 与步骤 4 **必须**顺序执行。**不要**在同一个并行批次里同时发出两次 agent 调用。在调用 Critic 之前，始终等待 Architect 结果。

共识模式的详情请参考 Plan skill 的完整文档。

## Goal-Mode Follow-up Suggestions

当 ralplan 输出最终移交或请用户选择下一条通道时，在已有的 Ralph 与 team 选项旁边附上面向产品的目标模式建议：

- `$ultragoal` —— 用于实现或一般目标导向后续计划的**默认目标模式后续**，把它沉淀为持久的 Codex / oh-my-kimi 目标，按顺序跟踪完成情况。
- `$autoresearch-goal` —— 计划以一个问题、文献 / 参考收集、评估器支撑的研究或类似教授 / 评论家风格的研究交付物为核心时的研究项目后续。
- `$performance-goal` —— 计划以速度、延迟、吞吐、内存、benchmark 或其他可测量的性能工作为核心时的优化 / 性能后续。

在合适场景下，保留 `$ralph` 与 `$team` 作为一等执行选项：Ralph 用于单 owner 的持久完成 / 验证压力，team 用于协调式并行实现。当任务主要是实现交付时，**不要**把目标模式选项呈现为 Ralph / team 的替代品；当持久目标跟踪、研究验证或性能评估器才是主要需求时，再把它们作为更合适的选择呈现。

## 预上下文采集

在共识规划或执行移交之前，确保存在一份落地的上下文快照：

1. 从请求中派生一个 task slug。
2. 如果 `.omk/context/{slug}-*.md` 中已存在最新的相关快照，复用它。
3. 如果都没有，创建 `.omk/context/{slug}-{timestamp}.md`（UTC `YYYYMMDDTHHMMSSZ`），包含：
   - 任务陈述
   - 目标产出
   - 已知事实 / 证据
   - 约束
   - 未知 / 待解决问题
   - 代码库可能涉及的接触点
4. 如果歧义仍然很大，先收集 brownfield 事实。当会话指引启用了 `USE_OMX_EXPLORE_CMD` 时，对简单只读的仓库查找优先使用 `omk explore`，给出窄而具体的 prompt；否则使用更完整的常规 explore 路径。然后在继续前跑 `$deep-interview --quick <task>`。
5. 如果计划依赖官方文档、版本敏感的框架指引、最佳实践或外部依赖行为，在最终规划移交前自动委派 `researcher`，以免执行只依赖仓库本地的回忆。

在采集完成之前不要移交到执行模式；如果紧迫性强制推进，显式记录风险权衡。

## 执行前门

### 为什么需要这道门

执行模式（ralph、autopilot、team、ultrawork）会拉起重量级的多 agent 编排。当被「ralph improve the app」这样的模糊请求触发时，agent 没有清晰目标 —— 会把本该在规划时完成的范围发现浪费在执行周期上，最终交付的工作往往不完整或方向跑偏，需要返工。

ralplan-first 门拦截欠规格的执行请求，把它们重路由到 ralplan 共识规划工作流。这能确保：
- **显式范围**：PRD 精确定义要构建什么
- **测试规格**：验收标准在写代码之前就可测试
- **共识**：Planner、Architect、Critic 在方案上达成一致
- **不做无谓执行**：agent 从清晰、有边界的任务起步

### 好与坏的提示对照

**通过门**（足够具体，可直接执行）：
- `ralph fix the null check in src/hooks/bridge.ts:326`
- `autopilot implement issue #42`
- `team add validation to function processKeywordDetector`
- `ralph do:\n1. Add input validation\n2. Write tests\n3. Update README`
- `ultrawork add the user model in src/models/user.ts`

**被拦截 —— 重路由到 ralplan**（需要先定范围）：
- `ralph fix this`
- `autopilot build the app`
- `team improve performance`
- `ralph add authentication`
- `ultrawork make it better`

**绕过门**（你确定自己要什么时）：
- `force: ralph refactor the auth module`
- `! autopilot optimize everything`

### 门什么时候**不会**触发

只要检测到**任意一个**具体信号，门会自动放行。不需要全部满足 —— 一个就够：

| 信号类型 | 示例 prompt | 为什么通过 |
|---|---|---|
| 文件路径 | `ralph fix src/hooks/bridge.ts` | 引用了具体文件 |
| Issue / PR 编号 | `ralph implement #42` | 有具体工作项 |
| camelCase 符号 | `ralph fix processKeywordDetector` | 命名了具体函数 |
| PascalCase 符号 | `ralph update UserModel` | 命名了具体类 |
| snake_case 符号 | `team fix user_model` | 命名了具体标识符 |
| 测试 runner | `ralph npm test && fix failures` | 有显式测试目标 |
| 编号步骤 | `ralph do:\n1. Add X\n2. Test Y` | 结构化交付物 |
| 验收标准 | `ralph add login - acceptance criteria: ...` | 显式成功定义 |
| 错误引用 | `ralph fix TypeError in auth` | 具体错误 |
| 代码块 | `ralph add: \`\`\`ts ... \`\`\`` | 提供了具体代码 |
| 转义前缀 | `force: ralph do it` 或 `! ralph do it` | 用户显式覆盖 |

### 端到端流程示例

1. 用户输入：`ralph add user authentication`
2. 门检测到：执行关键词（`ralph`）+ 欠规格 prompt（无文件、函数或测试规格）
3. 门重路由到 **ralplan**，附消息说明本次重路由
4. Ralplan 共识运行：
   - **Planner** 生成初始计划（哪些文件、什么鉴权方式、哪些测试）
   - **Architect** 评审合理性
   - **Critic** 校验质量与可测试性
5. 共识通过后，用户选择执行路径：
   - **ralph**：顺序执行 + 验证
   - **team**：并行协调的多 agent
6. 执行从一个清晰、有边界的计划开始

### 排错

| 问题 | 解决 |
|-------|----------|
| 门对一个写得很清晰的 prompt 触发了 | 加上文件引用、函数名或 issue 编号锚定请求 |
| 想绕过门 | 用 `force:` 或 `!` 前缀（例如 `force: ralph fix it`） |
| 门对一个模糊 prompt 没触发 | 门只捕获 <=15 个有效词且没有具体锚点的 prompt；要么加更多细节，要么显式调用 `$ralplan` |
| 被重路由到 ralplan，但想跳过规划 | 在 ralplan 工作流里说「just do it」或「skip planning」直接进入执行 |

## 场景示例

**Good：** 工作流已经有明确的下一步，用户说 `continue`。继续当前工作分支，而不是重启或重新询问同一个问题。

**Good：** 用户只改输出形态或下游交付步骤（例如 `make a PR`）。保留更早期、不冲突的工作流约束，并在本地应用更新。

**Bad：** 用户说 `continue`，工作流却重启发现流程，或在缺失的验证 / 证据被收集之前就停下。
