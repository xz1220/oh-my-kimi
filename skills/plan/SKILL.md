---
name: plan
description: 战略性规划，可选搭配访谈工作流
argument-hint: "[--direct|--consensus|--review] [--interactive] [--deliberate] <task description>"
pipeline: [deep-interview]
handoff-policy: approval-required
handoff: .omk/plans/ralplan-*.md
level: 4
---

<Purpose>
Plan 通过智能交互产出全面、可执行的工作方案。它会自动判断该访谈用户（宽泛请求）还是直接规划（具体请求），并支持共识模式（Planner/Architect/Critic 迭代循环 + RALPLAN-DR 结构化讨论）与 review 模式（Critic 评估既有方案）。
</Purpose>

<Use_When>
- 用户希望在实现前先规划 —— "plan this"、"plan the"、"let's plan"
- 用户希望对模糊想法做结构化需求收集
- 用户希望对已有方案做 review —— "review this plan"、`--review`
- 用户希望对方案做多视角共识 —— `--consensus`、"ralplan"
- 任务宽泛或模糊，在写任何代码前需要圈定范围
</Use_When>

<Do_Not_Use_When>
- 用户希望端到端自主执行 —— 改用 `autopilot`
- 用户有清晰任务想立刻动手 —— 用 `ralph` 或委派给 executor
- 用户问的是可以直接回答的简单问题 —— 直接回答
- 任务是范围明显的单点修复 —— 用执行 skill 而不是从规划模块跑
</Do_Not_Use_When>

<Why_This_Exists>
不理解需求就动手会带来返工、范围蔓延与漏掉的边界情况。Plan 提供结构化的需求收集、专家分析与质量门控的方案，让执行从坚实基础起步。共识模式为高风险项目额外引入多视角校验。
</Why_This_Exists>

<Execution_Policy>
- 根据请求具体程度自动判断访谈 vs 直接模式
- 访谈期间每次只问一个问题 —— 永远不要 batch 多个问题
- 在向用户提问代码库相关问题之前，通过 `explore` agent 收集事实
- 方案必须满足质量标准：80%+ 主张引用 file/line、90%+ 验收标准可测试
- 共识模式默认完全自动；加 `--interactive` 在 draft 评审与终审步骤启用用户提示
- 共识模式默认走 RALPLAN-DR short；用 `--deliberate` 或请求明显高风险（auth/security、数据迁移、破坏性 / 不可逆改动、生产事故、合规 / PII、公开 API break）时切到 deliberate
- **规划 / 执行边界：** 规划模式只检视上下文并产出方案 / 规格 / 提案。除非用户在当前轮次或通过结构化审批 UI 显式同意执行，否则**必须**把工件标为 `pending approval`。在显式执行批准之前，规划模式**不得**跑变更性 shell 命令、编辑源文件、commit、push、开 PR、调用执行 skill 或委派实现任务。
</Execution_Policy>

<Steps>

### 模式选择

| Mode | Trigger | Behavior |
|------|---------|----------|
| Interview | 宽泛请求的默认 | 交互式需求收集 |
| Direct | `--direct`，或细节充分的请求 | 跳过访谈，直接生成方案 |
| Consensus | `--consensus`、"ralplan" | Planner -> Architect -> Critic 循环直到达成共识，使用 RALPLAN-DR 结构化讨论（默认 short，`--deliberate` 走高风险版）；`--interactive` 时在 draft 与审批步骤加上用户提示 |
| Review | `--review`、"review this plan" | Critic 评估既有方案 |

### Interview 模式（宽泛 / 模糊请求）

1. **请求分类**：宽泛（动词模糊、无具体文件、跨 3+ 区域）触发 interview 模式
2. **每次问一个有针对性的问题**，用 `AskUserQuestion` 收集偏好、范围与约束
3. **先收集代码库事实**：在问「你代码用什么模式？」之前，派一个 `explore` agent 弄清楚，再问有信息含量的后续问题
4. **在答案上递进**：每个问题都基于上一个答案
5. **请教 Analyst**：找出隐藏需求、边界情况与风险
6. **创建方案**：用户表示就绪时（"create the plan"、"I'm ready"、"make it a work plan"）生成方案

### Direct 模式（细节充分请求）

1. **快速分析**：可选的简短 Analyst 咨询
2. **创建方案**：立刻生成完整工作方案
3. **Review**（可选）：必要时跑 Critic review

### Consensus 模式（`--consensus` / "ralplan"）

**RALPLAN-DR 模式：** **Short**（默认，结构受限）与 **Deliberate**（用于 `--deliberate` 或明示高风险请求）。两种模式都保留同样的 Planner -> Architect -> Critic 序列与同样的 `AskUserQuestion` 闸门。

**Provider 覆盖（provider CLI 已安装时受支持）：**
- `--architect codex` —— 把 Claude Architect pass 替换为 `omk ask codex --agent-prompt architect "..."`，做面向实现的架构审查
- `--critic codex` —— 把 Claude Critic pass 替换为 `omk ask codex --agent-prompt critic "..."`，在执行前再加一次外部审查
- 如果指定的 provider 不可用，简短说明并继续用该阶段的默认 Claude Architect/Critic 步骤

**状态生命周期：** persistent-mode 的 stop hook 用 `ralplan-state.json` 在共识循环期间强制继续。skill **必须**管好这份状态：
- **进入时**：步骤 1 之前调 `state_write(mode="ralplan", active=true, session_id=<current_session_id>)`
- **交接到执行时**（approval → ralph/team）：调 `state_write(mode="ralplan", active=false, session_id=<current_session_id>)`。这里**不要**用 `state_clear` —— `state_clear` 会写一个 30 秒的取消信号，使所有模式的 stop-hook 强制都失效，让刚启动的执行模式失去保护。
- **真正的终态退出**（拒绝、非交互式方案输出、错误 / abort）：调 `state_clear(mode="ralplan", session_id=<current_session_id>)` —— 无后续执行模式，取消信号窗口无害。
- 中间步骤（如 Critic 通过、达到最大迭代数的展示）**不要**清理状态，因为用户仍可能选择 "Request changes"。

不做清理时，stop hook 会在共识工作流结束后仍用 `[RALPLAN - CONSENSUS PLANNING]` 强化消息阻塞所有后续 stop。始终传 `session_id`，避免清掉其他并发会话的状态。

1. **Planner** 在任何 Architect 评审之前先创建初始方案与一份紧凑的 **RALPLAN-DR summary**。该 summary **必须**含：
   - **Principles**（3-5 条）
   - **Decision Drivers**（最关键 3 条）
   - **Viable Options**（>=2 个）并对每个备选给出有边界的 pros/cons
   - 若仅剩一个 viable option，给出被拒备选的显式 **invalidation rationale**
   - **deliberate 模式**：含 **pre-mortem**（3 个失败场景）与覆盖 **unit / integration / e2e / observability** 的 **expanded test plan**
2. **用户反馈** *(仅 --interactive)*：用 `--interactive` 时**必须**用 `AskUserQuestion` 把 draft 方案 **加上 RALPLAN-DR Principles / Decision Drivers / Options summary** 一起呈现以便方向对齐，选项如下：
   - **Proceed to review** —— 交给 Architect 与 Critic 评估
   - **Request changes** —— 回步骤 1，把用户反馈纳入
   - **Skip review** —— 直接到终审（步骤 7）
   未使用 `--interactive` 时自动进入评审（步骤 3）。
3. **Architect** 用 `Agent(subagent_type="oh-my-kimi:architect", ...)` 做架构稳健性评审。Architect 评审**必须**包含：针对所选方案最强的 steelman 反驳（antithesis）、至少一条有意义的取舍张力，以及（可能时）一条 synthesis 路径。deliberate 模式下，Architect 应显式标出原则违例。**等本步完成后再进入步骤 4。** 不要让步骤 3 与 4 并行。
4. **Critic** 用 `Agent(subagent_type="oh-my-kimi:critic", ...)` 按质量标准评估。Critic **必须**校验原则—选项一致性、备选探索是否充分、风险缓解清晰度、可测试验收标准与具体验证步骤。Critic **必须**显式驳回浅薄备选、drivers 自相矛盾、模糊风险或薄弱验证。deliberate 模式下，Critic **必须**驳回缺失 / 弱 pre-mortem 或缺失 / 弱扩展测试计划。只有步骤 3 完成后才跑。
5. **再评审循环**（最多 5 次迭代）：Critic 驳回时，执行这条闭环：
   a. 收集 Architect + Critic 的全部驳回反馈
   b. 把反馈交给 Planner 出修订方案
   c. **回步骤 3** —— Architect 评审修订方案
   d. **回步骤 4** —— Critic 评估修订方案
   e. 重复直到 Critic 通过或达 5 次上限
   f. 达到上限仍未通过时，通过 `AskUserQuestion` 把最好版本呈现给用户，并标注未达成专家共识
6. **应用改进**：评审者通过且附带改进建议时，在进入下一步前把所有被接受的改进合入方案文件。共识最终输出**必须**含 **ADR** 段：**Decision**、**Drivers**、**Alternatives considered**、**Why chosen**、**Consequences**、**Follow-ups**。具体：
   a. 收集 Architect 与 Critic 回复里的所有改进建议
   b. 去重与归类
   c. 用接受的改进更新 `.omk/plans/` 中的方案文件（补缺失细节、精化步骤、强化验收标准、ADR 更新等）
   d. 在方案末尾的简短 changelog 段记录哪些改进被应用
7. Critic 通过（且已应用改进）后：除非已经记录显式执行批准，否则把方案状态标为 `pending approval`。*(仅 --interactive)* 用 `--interactive` 时用 `AskUserQuestion` 呈现方案，选项如下：
   - **Approve execution via team**（推荐）—— 显式同意通过协同并行 team agent（`/team`）推进。自 v4.1.7 起 team 是权威编排接口。
   - **Approve execution via ralph** —— 显式同意通过 ralph+ultrawork 推进（带验证的顺序执行）
   - **Approve execution after clearing context** —— 显式同意先压缩上下文窗口（规划后上下文大时推荐），再用保存的方案文件通过 ralph 重新启动实现
   - **Request changes** —— 回步骤 1，带上用户反馈
   - **Reject** —— 整份方案丢弃
   未使用 `--interactive` 时，输出标为 `pending approval` 的最终方案，调 `state_clear(mode="ralplan", session_id=<current_session_id>)`，然后停。**不要**自动执行。
8. *(仅 --interactive)* 用户通过结构化 `AskUserQuestion` UI 选择（永远不要在纯文本里问审批）。用户选 **Reject** 时调 `state_clear(mode="ralplan", session_id=<current_session_id>)` 并停下。
9. 用户批准时（仅 --interactive）：在调用执行 skill（ralph/team）**之前**调 `state_write(mode="ralplan", active=false, session_id=<current_session_id>)`，让 stop hook 不去干扰执行模式自身的强制。这里**不要**用 `state_clear` —— 它写的取消信号会让刚启动的模式失去强制。
   - **Approve execution via team**：**必须**用 `.omk/plans/` 下被批准的方案路径作为上下文调用 `Skill("oh-my-kimi:team")`。不要直接实现。team skill 跨分阶段 pipeline 协同并行 agent，对大任务执行更快。这是推荐的默认执行路径。
   - **Approve execution via ralph**：**必须**用 `.omk/plans/` 下被批准的方案路径作为上下文调用 `Skill("oh-my-kimi:ralph")`。不要直接实现。规划 agent 内不要编辑源代码。ralph skill 通过 ultrawork 并行 agent 处理执行。
   - **Approve execution after clearing context**：先调 `Skill("compact")` 压缩上下文（减小规划期间累积的 token 用量），再用 `.omk/plans/` 下批准的方案路径调 `Skill("oh-my-kimi:ralph")`。当规划会话结束时上下文窗口已用 50%+ 时推荐这条路径。

### Review 模式（`--review`）

1. 从 `.omk/plans/` 读方案文件
2. 用 `Agent(subagent_type="oh-my-kimi:critic", ...)` 经 Critic 评估
3. 返回结论：APPROVED、REVISE（带具体反馈）或 REJECT（需要重新规划）

### 方案输出格式

每份方案包含：
- Requirements Summary
- Acceptance Criteria（可测试）
- Implementation Steps（含文件引用）
- Risks and Mitigations
- Verification Steps
- 共识 / ralplan：**RALPLAN-DR summary**（Principles、Decision Drivers、Options）
- 共识 / ralplan 最终输出：**ADR**（Decision、Drivers、Alternatives considered、Why chosen、Consequences、Follow-ups）
- deliberate 共识模式：**Pre-mortem（3 个场景）** 与 **Expanded Test Plan**（unit/integration/e2e/observability）

方案保存到 `.omk/plans/`。Draft 放到 `.omk/drafts/`。
</Steps>

<Tool_Usage>
- 偏好类问题（范围、优先级、时间表、风险容忍度）用 `AskUserQuestion` —— 给出可点击 UI
- 需要具体值的问题（端口号、命名、追问澄清）用纯文本
- 用 `explore` agent（Haiku，30s 超时）在向用户提问前先收集代码库事实
- 对大范围方案用 `Agent(subagent_type="oh-my-kimi:planner", ...)` 做规划校验
- 用 `Agent(subagent_type="oh-my-kimi:analyst", ...)` 做需求分析
- 共识与 review 模式下用 `Agent(subagent_type="oh-my-kimi:critic", ...)` 做方案评审
- **CRITICAL —— 共识模式下 agent 调用必须串行，绝不并行。** 始终等 Architect Task 结果后再发 Critic Task。
- 共识模式默认 RALPLAN-DR short；`--deliberate` 或明示高风险信号（auth/security、迁移、破坏性改动、生产事故、合规 / PII、公开 API break）时启用 deliberate
- 共识模式 + `--interactive`：用户反馈步骤（步骤 2）与终审步骤（步骤 7）用 `AskUserQuestion` —— 永远不要在纯文本里求审批。未启用 `--interactive` 时跳过这两个 prompt、把方案标为 `pending approval`、输出最终方案并停下。
- 共识模式 + `--interactive`，用户显式批准后**必须**通过 `Skill("oh-my-kimi:ralph")` 或 `Skill("oh-my-kimi:team")` 执行（步骤 9）—— 规划 agent 内绝不直接实现
- 在显式执行批准之前，规划模式**不得**跑变更性 shell 命令、编辑文件、commit、push、开 PR、调用执行 skill 或委派实现任务；只能检视上下文并起草 / 更新方案 / 规格 / 提案工件。
- 当用户在步骤 7（仅 --interactive）选 "Approve execution after clearing context"：先调 `state_write(mode="ralplan", active=false, session_id=<current_session_id>)`，再调 `Skill("compact")` 压缩累积的规划上下文，然后立即用方案路径调 `Skill("oh-my-kimi:ralph")` —— compact 步骤至关重要，能在实现循环开始前腾出上下文
- **CRITICAL —— 共识模式状态生命周期**：在每个退出路径前都把 ralplan 状态置为非活跃。交接执行路径（approval → ralph/team）用 `state_write(active=false)`，真正终态退出（rejection、error）用 `state_clear`。在启动执行模式之前**绝不**用 `state_clear` —— 它的取消信号会让 stop-hook 强制失效 30 秒。
</Tool_Usage>

<Examples>
<Good>
自适应访谈（先收集事实再提问）：
```
Planner: [spawns explore agent: "find authentication implementation"]
Planner: [receives: "Auth is in src/auth/ using JWT with passport.js"]
Planner: "I see you're using JWT authentication with passport.js in src/auth/.
         For this new feature, should we extend the existing auth or add a separate auth flow?"
```
为什么好：先自答了代码库相关问题，再问有信息含量的偏好问题。
</Good>

<Good>
每次只问一个问题：
```
Q1: "What's the main goal?"
A1: "Improve performance"
Q2: "For performance, what matters more -- latency or throughput?"
A2: "Latency"
Q3: "For latency, are we optimizing for p50 or p99?"
```
为什么好：每个问题在上一个答案上递进。聚焦、渐进。
</Good>

<Bad>
追问能自己查到的事：
```
Planner: "Where is authentication implemented in your codebase?"
User: "Uh, somewhere in src/auth I think?"
```
为什么差：planner 应该派 explore agent 自己找到，而不是问用户。
</Bad>

<Bad>
batch 多个问题：
```
"What's the scope? And the timeline? And who's the audience?"
```
为什么差：一次三个问题导致浅层答复。每次一个。
</Bad>

<Bad>
一次性把所有设计选项摆出来：
```
"Here are 4 approaches: Option A... Option B... Option C... Option D... Which do you prefer?"
```
为什么差：决策疲劳。一次呈现一个选项 + 取舍，收到反应再上下一个。
</Bad>
</Examples>

<Escalation_And_Stop_Conditions>
- 需求清楚到可以规划时就停止访谈 —— 不要过度访谈
- 共识模式在 5 轮 Planner/Architect/Critic 迭代后停下，呈现最好版本。**不要**在这里清理 ralplan 状态 —— 用户仍可能在后续选 "Request changes"。状态只在用户的最终选择（approval/rejection）或非交互式输出方案时清理。
- 未带 `--interactive` 的共识模式输出标为 `pending approval` 的最终方案后停下；带 `--interactive` 时，在任何实现开始之前都需要用户显式批准。**始终**在停下前调 `state_clear(mode="ralplan", session_id=<current_session_id>)`。
- 如果用户说 "just do it" 或 "skip planning" 而没有显式给出执行路径，把它当作结束规划的请求：输出当前方案 / 规格 / 提案作为 `pending approval`，并通过结构化审批 UI 请求显式执行批准。在批准存在之前，**不要**从规划模块调用 `Skill("oh-my-kimi:ralph")`、变更文件、委派实现、commit、push 或开 PR。
- 当存在需要业务决策的不可调和取舍时，升级给用户
</Escalation_And_Stop_Conditions>

<Final_Checklist>
- [ ] 方案有可测试的验收标准（90%+ 具体）
- [ ] 方案在适用处引用具体文件 / 行（80%+ 主张）
- [ ] 所有风险都识别了缓解
- [ ] 没有未带指标的模糊用语（"fast" -> "p99 < 200ms"）
- [ ] 方案保存到 `.omk/plans/`
- [ ] 共识模式：RALPLAN-DR summary 含 3-5 条原则、最关键 3 条 drivers、>=2 个 viable options（或显式 invalidation rationale）
- [ ] 共识模式最终输出：含 ADR 段（Decision / Drivers / Alternatives considered / Why chosen / Consequences / Follow-ups）
- [ ] deliberate 共识模式：含 pre-mortem（3 个场景）+ 扩展测试计划（unit/integration/e2e/observability）
- [ ] 共识模式 + `--interactive`：任何执行前用户都显式批准；未带 `--interactive`：方案输出仅标 `pending approval`，无自动执行
- [ ] 共识模式：每条退出路径都把 ralplan 状态置为非活跃 —— 交接执行用 `state_write(active=false)`，终态退出（rejection、error、非交互停止）用 `state_clear`
</Final_Checklist>

<Advanced>
## 设计选项呈现

访谈中呈现设计选择时，分块给出：

1. **概述**（2-3 句）
2. **Option A** 含取舍
3. [等用户反应]
4. **Option B** 含取舍
5. [等用户反应]
6. **推荐**（只有在选项讨论后给出）

每个选项格式：
```
### Option A: [Name]
**Approach:** [1 sentence]
**Pros:** [bullets]
**Cons:** [bullets]

What's your reaction to this approach?
```

## 问题分类

问任何访谈问题前先分类：

| Type | Examples | Action |
|------|----------|--------|
| Codebase Fact | "What patterns exist?"、"Where is X?" | 先 explore，不要问用户 |
| User Preference | "Priority?"、"Timeline?" | 通过 AskUserQuestion 问用户 |
| Scope Decision | "Include feature Y?" | 问用户 |
| Requirement | "Performance constraints?" | 问用户 |

## 评审质量标准

| Criterion | Standard |
|-----------|----------|
| Clarity | 80%+ 主张引用 file/line |
| Testability | 90%+ 标准具体 |
| Verification | 所有文件引用均存在 |
| Specificity | 无模糊用语 |

## 弃用提示

独立的 `/planner`、`/ralplan`、`/review` skill 已并入 `/plan`。所有工作流（interview、direct、consensus、review）都通过 `/plan` 提供。
</Advanced>
