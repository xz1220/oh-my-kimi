---
name: team
description: 基于 Kimi CLI 原生 team 能力，让 N 个 agent 协调工作在共享任务列表上
argument-hint: "[N:agent-type] [ralph] <task description>"
aliases: []
level: 4
---

# Team Skill

利用 Kimi CLI 的原生 team 工具，派出 N 个协调工作的 agent 共享同一个任务列表。它用内置的 team 管理、agent 之间消息传递与任务依赖替代了旧版 `/swarm` skill（基于 SQLite）—— 无需任何外部依赖。

`swarm` 兼容别名已在 #1131 中移除。

## 用法

```
/oh-my-kimi:team N:agent-type "task description"
/oh-my-kimi:team "task description"
/oh-my-kimi:team ralph "task description"
```

### 参数

- **N** —— 队友 agent 数量（1-20）。可选；默认基于任务分解自动定大小。
- **agent-type** —— `team-exec` 阶段要派的 oh-my-kimi agent（如 executor、debugger、designer、codex、gemini）。可选；默认按阶段路由。用 `codex` 派 Kimi CLI worker，或用 `gemini` 派 Gemini CLI worker（需要装对应 CLI）。详见下文「Stage Agent Routing」。
- **task** —— 待分解并分配给队友的高层任务
- **ralph** —— 可选修饰符。出现时把 team 流水线包进 Ralph 的持久化循环（失败重试、完成前 architect 验证）。详见下文「Team + Ralph 组合」。

### 示例

```bash
/team 5:executor "fix all TypeScript errors across the project"
/team 3:debugger "fix build errors in src/"
/team 4:designer "implement responsive layouts for all page components"
/team "refactor the auth module with security review"
/team ralph "build a complete REST API for user management"
# 使用 Kimi CLI worker（需要：npm install -g @openai/codex）
/team 2:codex "review architecture and suggest improvements"
# 使用 Gemini CLI worker（需要：npm install -g @google/gemini-cli）
/team 2:gemini "redesign the UI components"
# 混合：后端分析用 Codex、前端用 Gemini（这种场景请改用 /ccg）
```

## 架构

```
User: "/team 3:executor fix all TypeScript errors"
              |
              v
      [TEAM ORCHESTRATOR (Lead)]
              |
              +-- TeamCreate("fix-ts-errors")
              |       -> lead becomes team-lead@fix-ts-errors
              |
              +-- Analyze & decompose task into subtasks
              |       -> explore/architect produces subtask list
              |
              +-- TaskCreate x N (one per subtask)
              |       -> tasks #1, #2, #3 with dependencies
              |
              +-- TaskUpdate x N (pre-assign owners)
              |       -> task #1 owner=worker-1, etc.
              |
              +-- Task(team_name="fix-ts-errors", name="worker-1") x 3
              |       -> spawns teammates into the team
              |
              +-- Monitor loop
              |       <- SendMessage from teammates (auto-delivered)
              |       -> TaskList polling for progress
              |       -> SendMessage to unblock/coordinate
              |
              +-- Completion
                      -> SendMessage(shutdown_request) to each teammate
                      <- SendMessage(shutdown_response, approve: true)
                      -> TeamDelete("fix-ts-errors")
                      -> rm .omk/state/team-state.json
```

**存储布局（由 Kimi CLI 管理）：**
```
~/.claude/
  teams/fix-ts-errors/
    config.json          # team 元数据 + 成员列表
  tasks/fix-ts-errors/
    .lock                # 并发访问文件锁
    1.json               # 子任务 #1
    2.json               # 子任务 #2（可能是 internal）
    3.json               # 子任务 #3
    ...
```

## 阶段化流水线（规范化的 team 运行时）

team 执行遵循阶段化流水线：

`team-plan -> team-prd -> team-exec -> team-verify -> team-fix (loop)`

### Stage Agent Routing

每个流水线阶段使用**专门 agent** —— 不只是 executor。Lead 基于阶段与任务特征挑 agent。

| 阶段 | 必备 Agent | 可选 Agent | 选择标准 |
|-------|----------------|-----------------|-------------------|
| **team-plan** | `explore` (haiku)、`planner` (opus) | `analyst` (opus)、`architect` (opus) | 需求不清时用 `analyst`。系统边界复杂时用 `architect`。 |
| **team-prd** | `analyst` (opus) | `critic` (opus) | 用 `critic` 挑战范围。 |
| **team-exec** | `executor` (sonnet) | `executor` (opus)、`debugger` (sonnet)、`designer` (sonnet)、`writer` (haiku)、`test-engineer` (sonnet) | 按子任务类型匹配 agent。复杂自主工作用 `executor`（model=opus），UI 用 `designer`，编译问题用 `debugger`，文档用 `writer`，测试创建用 `test-engineer`。 |
| **team-verify** | `verifier` (sonnet) | `test-engineer` (sonnet)、`security-reviewer` (sonnet)、`code-reviewer` (opus) | 始终跑 `verifier`。鉴权 / 加密改动加 `security-reviewer`。改动 >20 个文件或架构性改动加 `code-reviewer`。`code-reviewer` 也覆盖风格 / 格式检查。 |
| **team-fix** | `executor` (sonnet) | `debugger` (sonnet)、`executor` (opus) | 类型 / 构建错误与回归隔离用 `debugger`。复杂多文件修复用 `executor`（model=opus）。 |

**路由规则：**

1. **Lead 按阶段挑 agent，不是用户挑。** 用户的 `N:agent-type` 参数只覆盖 `team-exec` 阶段的 worker 类型。其他阶段都用对应的专门 agent。
2. **专家 agent 补充 executor agent。** 把分析 / 评审路由到 architect / critic 这类 Kimi subagent，把 UI 工作路由到 designer agent。Tmux CLI worker 是一次性的，不参与 team 通信。
3. **Cost 模式影响模型等级。** 降级时：`opus` agent 降为 `sonnet`，`sonnet` 在质量允许时降为 `haiku`。`team-verify` 至少使用 `sonnet`。
4. **风险等级升级评审。** 安全敏感或 >20 个文件的改动必须在 `team-verify` 中包含 `security-reviewer` + `code-reviewer`（opus）。

### 阶段进入 / 退出标准

- **team-plan**
  - 进入：team 调用被解析、编排开始。
  - Agent：`explore` 扫代码库、`planner` 创建任务图，复杂任务可选 `analyst` / `architect`。
  - 退出：分解完成，可运行的任务图就绪。
- **team-prd**
  - 进入：范围模糊或验收标准缺失。
  - Agent：`analyst` 抽取需求，可选 `critic`。
  - 退出：验收标准与边界显式。
- **team-exec**
  - 进入：`TeamCreate`、`TaskCreate`、分配与 worker 启动完成。
  - Agent：按子任务类型派出合适的专家类型 worker（见路由表）。
  - 退出：本轮执行任务进入终态。
- **team-verify**
  - 进入：执行轮结束。
  - Agent：`verifier` + 任务相应的 reviewer（见路由表）。
  - 退出（pass）：验证门通过，无必需后续。
  - 退出（fail）：生成 fix 任务，控制权移交给 `team-fix`。
- **team-fix**
  - 进入：验证发现缺陷 / 回归 / 不完整标准。
  - Agent：按缺陷类型用 `executor` 或 `debugger`。
  - 退出：修复完成，流程回到 `team-exec`，再到 `team-verify`。

### Verify / Fix 循环与停止条件

继续 `team-exec -> team-verify -> team-fix`，直到：
1. 验证通过且没有必需的 fix 任务剩余，或
2. 工作到达显式终态 blocked / failed 并附证据。

`team-fix` 有最大尝试次数限制。如果 fix 尝试超过配置上限，转入终态 `failed`（不无限循环）。

### 阶段移交约定

阶段之间过渡时，重要上下文 —— 做出的决策、被驳回的替代方案、识别的风险 —— 只存在于 lead 的对话历史里。如果 lead 上下文被压缩或 agent 重启，这些知识就丢了。

**每个完成的阶段在过渡之前必须生成一份 handoff 文档。**

Lead 把 handoff 写到 `.omk/handoffs/<stage-name>.md`。

#### Handoff 格式

```markdown
## Handoff: <current-stage> → <next-stage>
- **Decided**: [本阶段做出的关键决策]
- **Rejected**: [被考虑但被驳回的替代方案及原因]
- **Risks**: [识别的下阶段风险]
- **Files**: [创建或修改的关键文件]
- **Remaining**: [留给下阶段处理的事项]
```

#### Handoff 规则

1. **Lead 在派下阶段 agent 之前先读上一个 handoff。** handoff 内容会被注入下阶段 agent 的 spawn prompt，确保 agent 带着完整上下文起步。
2. **Handoff 是累加的。** verify 阶段可以读取此前所有 handoff（plan → prd → exec）查看完整决策历史。
3. **team 取消时 handoff 仍保留**在 `.omk/handoffs/`，便于会话恢复。`TeamDelete` 不会删除它们。
4. **Handoff 是轻量的。** 最多 10-20 行。它记录决策与理由，不是完整规格（完整规格放在 DESIGN.md 这样的交付文件里）。

#### 示例

```markdown
## Handoff: team-plan → team-exec
- **Decided**: Microservice architecture with 3 services (auth, api, worker). PostgreSQL for persistence. JWT for auth tokens.
- **Rejected**: Monolith (scaling concerns), MongoDB (team expertise is SQL), session cookies (API-first design).
- **Risks**: Worker service needs Redis for job queue — not yet provisioned. Auth service has no rate limiting in initial design.
- **Files**: DESIGN.md, TEST_STRATEGY.md
- **Remaining**: Database migration scripts, CI/CD pipeline config, Redis provisioning.
```

### Resume 与 Cancel 语义

- **Resume：** 使用阶段化状态 + 实时任务状态从最近的非终态阶段重启。读 `.omk/handoffs/` 恢复阶段过渡上下文。
- **Cancel：** `/oh-my-kimi:cancel` 请求队友 shutdown，等待回应（尽力而为），把 phase 标 `cancelled` 并 `active=false`，记录取消元数据，然后删除 team 资源并按策略清理 / 保留 Team 状态。`.omk/handoffs/` 中的 handoff 文件保留以便恢复。
- 终态为 `complete`、`failed` 与 `cancelled`。

## 工作流

### Phase 1：解析输入

- 抽取 **N**（agent 数量），校验 1-20
- 抽取 **agent-type**，校验它映射到已知的 oh-my-kimi subagent
- 抽取 **task** 描述

### Phase 2：分析与分解

用 `explore` 或 `architect`（通过 MCP 或 agent）分析代码库，把任务拆成 N 个子任务：

- 每个子任务应当 **file-scoped** 或 **module-scoped**，避免冲突
- 子任务必须互相独立，或具有清晰的依赖顺序
- 每个子任务需要简洁的 `subject` 与详细的 `description`
- 识别子任务之间的依赖（例如「共享类型必须先修，消费者才能改」）

### Phase 3：创建 Team

用从任务派生的 slug 调用 `TeamCreate`：

```json
{
  "team_name": "fix-ts-errors",
  "description": "Fix all TypeScript errors across the project"
}
```

**响应：**
```json
{
  "team_name": "fix-ts-errors",
  "team_file_path": "~/.claude/teams/fix-ts-errors/config.json",
  "lead_agent_id": "team-lead@fix-ts-errors"
}
```

当前会话成为 team lead（`team-lead@fix-ts-errors`）。

用 `state_write` MCP 工具写入 oh-my-kimi 状态，做会话级持久化：

```
state_write(mode="team", active=true, current_phase="team-plan", state={
  "team_name": "fix-ts-errors",
  "agent_count": 3,
  "agent_types": "executor",
  "task": "fix all TypeScript errors",
  "fix_loop_count": 0,
  "max_fix_loops": 3,
  "linked_ralph": false,
  "stage_history": "team-plan"
})
```

> **注意：** MCP `state_write` 工具把所有值按字符串传输。消费者读取时必须把 `agent_count`、`fix_loop_count`、`max_fix_loops` 强转为数字，把 `linked_ralph` 强转为 boolean。

**状态字段 schema：**

| 字段 | 类型 | 描述 |
|-------|------|-------------|
| `active` | boolean | team 模式是否激活 |
| `current_phase` | string | 当前流水线阶段：`team-plan`、`team-prd`、`team-exec`、`team-verify`、`team-fix` |
| `team_name` | string | team 的 slug 名 |
| `agent_count` | number | worker agent 数量 |
| `agent_types` | string | 逗号分隔的 team-exec 阶段 agent 类型 |
| `task` | string | 原始任务描述 |
| `fix_loop_count` | number | 当前 fix 迭代次数 |
| `max_fix_loops` | number | 失败前的最大 fix 迭代次数（默认：3） |
| `linked_ralph` | boolean | team 是否与 ralph 持久化循环联动 |
| `stage_history` | string | 逗号分隔的阶段过渡列表，带时间戳 |

**每次阶段过渡时更新状态：**

```
state_write(mode="team", current_phase="team-exec", state={
  "stage_history": "team-plan:2026-02-07T12:00:00Z,team-prd:2026-02-07T12:01:00Z,team-exec:2026-02-07T12:02:00Z"
})
```

**读取状态做 resume 检测：**

```
state_read(mode="team")
```

如果 `active=true` 且 `current_phase` 非终态，从最近的未完成阶段恢复，而不是新建 team。

### Phase 4：创建任务

为每个子任务调用 `TaskCreate`。用 `TaskUpdate` 加 `addBlockedBy` 设置依赖。

```json
// TaskCreate for subtask 1
{
  "subject": "Fix type errors in src/auth/",
  "description": "Fix all TypeScript errors in src/auth/login.ts, src/auth/session.ts, and src/auth/types.ts. Run tsc --noEmit to verify.",
  "activeForm": "Fixing auth type errors"
}
```

**响应会存为一个任务文件（例如 `1.json`）：**
```json
{
  "id": "1",
  "subject": "Fix type errors in src/auth/",
  "description": "Fix all TypeScript errors in src/auth/login.ts...",
  "activeForm": "Fixing auth type errors",
  "owner": "",
  "status": "pending",
  "blocks": [],
  "blockedBy": []
}
```

对有依赖的任务，创建后用 `TaskUpdate`：

```json
// 任务 #3 依赖任务 #1（共享类型必须先修）
{
  "taskId": "3",
  "addBlockedBy": ["1"]
}
```

**从 lead 预分配 owner**，避免竞争（没有原子领取机制）：

```json
// 把任务 #1 分配给 worker-1
{
  "taskId": "1",
  "owner": "worker-1"
}
```

### Phase 5：派出队友

用 `Task` 的 `team_name` 与 `name` 参数派出 N 个队友。每个队友拿到 team worker 前言（见下文）加上自己具体的分配。

```json
{
  "subagent_type": "oh-my-kimi:executor",
  "team_name": "fix-ts-errors",
  "name": "worker-1",
  "prompt": "<worker-preamble + assigned tasks>"
}
```

**响应：**
```json
{
  "agent_id": "worker-1@fix-ts-errors",
  "name": "worker-1",
  "team_name": "fix-ts-errors"
}
```

**副作用：**
- 队友被加入 `config.json` 的 members 数组
- **internal task** 被自动创建（带 `metadata._internal: true`），跟踪 agent 生命周期
- internal task 会出现在 `TaskList` 输出里 —— 数真实任务时要过滤掉

**重要：** 并行派出所有队友（它们是后台 agent）。**不要**等一个完成再派下一个。

### Phase 6：监控

Lead orchestrator 通过两条通道监控进度：

1. **入站消息** —— 队友在完成任务或需要帮助时用 `SendMessage` 发给 `team-lead`。这些消息会自动作为新对话回合到达（不用轮询）。

2. **TaskList 轮询** —— 定期调用 `TaskList` 检查整体进度：
   ```
   #1 [completed] Fix type errors in src/auth/ (worker-1)
   #3 [in_progress] Fix type errors in src/api/ (worker-2)
   #5 [pending] Fix type errors in src/utils/ (worker-3)
   ```
   格式：`#ID [status] subject (owner)`

**Lead 可以采取的协调动作：**

- **解除阻塞：** 发 `message` 给队友带上指导或缺失上下文
- **重新分配：** 如果队友提前完成，用 `TaskUpdate` 把 pending 任务分给它，并通过 `SendMessage` 通知
- **处理失败：** 队友报告失败时，重新分配该任务或派一个替代者

#### 任务看门狗策略

监控卡住或失败的队友：

- **最大 in-progress 龄期**：任务 `in_progress` 超过 5 分钟无消息，发送状态检查
- **疑似 worker 死亡**：无消息 + 任务卡住 10+ 分钟 → 把任务转交给其他 worker
- **重新分配阈值**：worker 失败 2+ 次任务，停止给它分新任务

### Phase 6.5：阶段过渡（状态持久化）

每次阶段过渡时更新 oh-my-kimi 状态：

```
// 规划后进入 team-exec
state_write(mode="team", current_phase="team-exec", state={
  "stage_history": "team-plan:T1,team-prd:T2,team-exec:T3"
})

// 执行后进入 team-verify
state_write(mode="team", current_phase="team-verify")

// 验证失败后进入 team-fix
state_write(mode="team", current_phase="team-fix", state={
  "fix_loop_count": 1
})
```

这能支持：
- **Resume**：lead 崩溃时，`state_read(mode="team")` 暴露最近的阶段与 team name 用于恢复
- **Cancel**：cancel skill 读取 `current_phase` 以知道需要哪些清理
- **Ralph 集成**：Ralph 可以读取 team 状态，知道流水线是完成还是失败

### Phase 7：完成

所有真实任务（非 internal）都 completed 或 failed 时：

1. **验证结果** —— 通过 `TaskList` 检查所有子任务标为 `completed`
2. **关闭队友** —— 给每个活跃队友发 `shutdown_request`：
   ```json
   {
     "type": "shutdown_request",
     "recipient": "worker-1",
     "content": "All work complete, shutting down team"
   }
   ```
3. **等待回应** —— 每个队友回 `shutdown_response(approve: true)` 并终止
4. **删除 team** —— 调用 `TeamDelete` 清理：
   ```json
   { "team_name": "fix-ts-errors" }
   ```
   响应：
   ```json
   {
     "success": true,
     "message": "Cleaned up directories and worktrees for team \"fix-ts-errors\"",
     "team_name": "fix-ts-errors"
   }
   ```
5. **清理 oh-my-kimi 状态** —— 移除 `.omk/state/team-state.json`
6. **报告汇总** —— 把结果呈现给用户

## Agent 前言

派出队友时，在 prompt 里包含下面这段前言以建立工作协议。按队友的具体任务分配做适配。

```
You are a TEAM WORKER in team "{team_name}". Your name is "{worker_name}".
You report to the team lead ("team-lead").
You are not the leader and must not perform leader orchestration actions.

== WORK PROTOCOL ==

1. CLAIM: Call TaskList to see your assigned tasks (owner = "{worker_name}").
   Pick the first task with status "pending" that is assigned to you.
   Call TaskUpdate to set status "in_progress":
   {"taskId": "ID", "status": "in_progress", "owner": "{worker_name}"}

2. WORK: Execute the task using your tools (Read, Write, Edit, Bash).
   Do NOT spawn sub-agents. Do NOT delegate. Work directly.

3. COMPLETE: When done, mark the task completed:
   {"taskId": "ID", "status": "completed"}

4. REPORT: Notify the lead via SendMessage:
   {"type": "message", "recipient": "team-lead", "content": "Completed task #ID: <summary of what was done>", "summary": "Task #ID complete"}

5. NEXT: Check TaskList for more assigned tasks. If you have more pending tasks, go to step 1.
   If no more tasks are assigned to you, notify the lead:
   {"type": "message", "recipient": "team-lead", "content": "All assigned tasks complete. Standing by.", "summary": "All tasks done, standing by"}

6. SHUTDOWN: When you receive a shutdown_request, respond with:
   {"type": "shutdown_response", "request_id": "<from the request>", "approve": true}

== BLOCKED TASKS ==
If a task has blockedBy dependencies, skip it until those tasks are completed.
Check TaskList periodically to see if blockers have been resolved.

== ERRORS ==
If you cannot complete a task, report the failure to the lead:
{"type": "message", "recipient": "team-lead", "content": "FAILED task #ID: <reason>", "summary": "Task #ID failed"}
Do NOT mark the task as completed. Leave it in_progress so the lead can reassign.

== RULES ==
- NEVER spawn sub-agents or use the Task tool
- NEVER run tmux pane/session orchestration commands (for example `tmux split-window`, `tmux new-session`)
- NEVER run team spawning/orchestration skills or commands (for example `$team`, `$ultrawork`, `$autopilot`, `$ralph`, `omk team ...`, `omk team ...`)
- ALWAYS use absolute file paths
- ALWAYS report progress via SendMessage to "team-lead"
- Use SendMessage with type "message" only -- never "broadcast"
```

### Agent-Type 提示注入（worker 专属附录）

组装队友 prompt 时，按 worker 类型追加一段简短附录：

- `kimi_worker`：强调严格的 TaskList / TaskUpdate / SendMessage 循环，且不准跑编排命令。
- `codex_worker`：强调 CLI API 生命周期（`omk team api ... --json`），失败要带 stderr 显式 ACK。
- `gemini_worker`：强调有界的文件 ownership，每完成一个 sub-step 做一次里程碑 ACK。

该附录必须保留核心规则：**worker = 仅执行者，永远不是 leader / orchestrator**。

## 通信模式

### 队友到 Lead（任务完成报告）

```json
{
  "type": "message",
  "recipient": "team-lead",
  "content": "Completed task #1: Fixed 3 type errors in src/auth/login.ts and 2 in src/auth/session.ts. All files pass tsc --noEmit.",
  "summary": "Task #1 complete"
}
```

### Lead 到队友（重新分配或指导）

```json
{
  "type": "message",
  "recipient": "worker-2",
  "content": "Task #3 is now unblocked. Also pick up task #5 which was originally assigned to worker-1.",
  "summary": "New task assignment"
}
```

### 广播（节制使用 —— 会发送 N 条独立消息）

```json
{
  "type": "broadcast",
  "content": "STOP: shared types in src/types/index.ts have changed. Pull latest before continuing.",
  "summary": "Shared types changed"
}
```

### Shutdown 协议（阻塞）

**关键：步骤必须按精确顺序执行。`TeamDelete` 永远不要在 shutdown 被确认前调用。**

**步骤 1：验证完成**
```
Call TaskList — verify all real tasks (non-internal) are completed or failed.
```

**步骤 2：向每个队友请求 shutdown**

**Lead 发送：**
```json
{
  "type": "shutdown_request",
  "recipient": "worker-1",
  "content": "All work complete, shutting down team"
}
```

**步骤 3：等待回应（阻塞）**
- 对每个队友最多等 30 秒以获取 `shutdown_response`
- 跟踪谁确认、谁超时
- 30 秒内无回应：记 warning，标为 unresponsive

**队友接收并回应：**
```json
{
  "type": "shutdown_response",
  "request_id": "shutdown-1770428632375@worker-1",
  "approve": true
}
```

批准后：
- 队友进程终止
- 队友自动从 `config.json` members 数组移除
- 该队友的 internal task 完成

**步骤 4：TeamDelete —— 在所有队友确认或超时后再调**
```json
{ "team_name": "fix-ts-errors" }
```

**步骤 5：孤儿扫描**

检查在 TeamDelete 后仍存活的 agent 进程：
```bash
node "${CLAUDE_PLUGIN_ROOT}/scripts/cleanup-orphans.mjs" --team-name fix-ts-errors
```

它会扫描与 team 名匹配但 config 已不存在的进程，并终止它们（SIGTERM → 5 秒等待 → SIGKILL）。支持 `--dry-run` 做检查。

**Shutdown 序列是阻塞的：** 在所有队友满足以下任一条件之前，不要进入 TeamDelete：
- 确认 shutdown（`shutdown_response` 且 `approve: true`），或
- 超时（30 秒无回应）

**重要：** `request_id` 由队友接收到的 shutdown 请求消息提供。队友必须抽取它并原样回传。**不要**伪造 request ID。

## CLI Worker（Codex 与 Gemini）

team skill 支持**混合执行**：Kimi subagent 队友 + 外部 CLI worker（Kimi CLI 与 Gemini CLI）。两类都能改代码 —— 区别在于能力与成本。它们是独立 CLI 工具，不是 MCP server。

### 执行模式

任务在分解时打上执行模式标签：

| 执行模式 | Provider | 能力 |
|---------------|----------|-------------|
| `kimi_worker` | Kimi subagent | 完整 Kimi CLI 工具访问（Read / Write / Edit / Bash / Task）。适合需要 Claude 推理 + 迭代式工具使用的任务。 |
| `codex_worker` | Kimi CLI（tmux pane） | working_directory 内完整文件系统访问。通过 tmux pane 自主跑。适合代码评审、安全分析、重构、架构。需要 `npm install -g @openai/codex`。 |
| `gemini_worker` | Gemini CLI（tmux pane） | working_directory 内完整文件系统访问。通过 tmux pane 自主跑。适合 UI / 设计、文档、大上下文任务。需要 `npm install -g @google/gemini-cli`。 |

### CLI Worker 如何工作

Tmux CLI worker 在专用 tmux pane 中跑，具备文件系统访问。它们是**自主执行者**，不只是分析者：

1. Lead 把任务说明写入 prompt 文件
2. Lead 派出一个 tmux CLI worker，`working_directory` 设为项目根
3. worker 读文件、改文件、跑命令 —— 都限于其工作目录内
4. 结果 / 汇总写入输出文件
5. Lead 读取输出，标任务完成，把结果喂给依赖任务

**与 Kimi subagent 的关键区别：**
- CLI worker 通过 tmux 操作，不走 Kimi CLI 工具系统
- 不能用 TaskList / TaskUpdate / SendMessage（无 team 感知）
- 一次性自主作业，不是持久队友
- 由 Lead 管理其生命周期（spawn、monitor、收集结果）

### 何时路由到哪里

| 任务类型 | 最佳路由 | 原因 |
|-----------|-----------|-----|
| 迭代式多步工作 | Kimi subagent | 需要工具中介的迭代 + team 通信 |
| 代码评审 / 安全审计 | CLI worker 或专家 agent | 自主执行，擅长结构化分析 |
| 架构分析 / 规划 | architect Kimi subagent | 强分析推理 + 代码库访问 |
| 范围明确的重构 | CLI worker 或 executor agent | 自主执行，擅长结构化变换 |
| UI / 前端实现 | designer Kimi subagent | 设计专长、框架习惯 |
| 大规模文档 | writer Kimi subagent | 写作专长 + 大上下文保证一致性 |
| 构建 / 测试迭代循环 | Kimi subagent | 需要 Bash 工具 + 迭代式 fix 循环 |
| 需要团队协调的任务 | Kimi subagent | 需要 SendMessage 做状态更新 |

### 示例：带 CLI Worker 的混合 team

```
/team 3:executor "refactor auth module with security review"

Task decomposition:
#1 [codex_worker] Security review of current auth code -> output to .omk/research/auth-security.md
#2 [codex_worker] Refactor auth/login.ts and auth/session.ts (uses #1 findings)
#3 [kimi_worker:designer] Redesign auth UI components (login form, session indicator)
#4 [kimi_worker] Update auth tests + fix integration issues
#5 [gemini_worker] Final code review of all changes
```

Lead 先跑 #1（Codex 安全分析），再并行跑 #2 与 #3（Codex 重构后端、designer agent 重做前端），然后 #4（Kimi subagent 处理测试迭代），最后 #5（Gemini 终审）。

### 预先分析（可选）

对大而模糊的任务，team 创建前先跑分析：

1. 用任务描述 + 代码库上下文派 `Agent(subagent_type="oh-my-kimi:planner", ...)`
2. 用分析结果做更好的任务分解
3. 用更充分的上下文创建 team 与任务

任务范围不清、能从分解前的外部推理中受益时尤其有用。

## 监控增强：Outbox 自动摄取

Lead 可以利用 outbox reader 工具主动摄取 CLI worker 的 outbox 消息，使监控成为事件驱动，不再单纯依赖 `SendMessage` 投递。

### Outbox Reader 函数

**`readNewOutboxMessages(teamName, workerName)`** —— 用字节偏移游标读取单个 worker 的新 outbox 消息。每次调用推进游标，后续调用只返回自上次读取以来写入的消息。镜像了 `readNewInboxMessages()` 的 inbox 游标模式。

**`readAllTeamOutboxMessages(teamName)`** —— 读取 team 中所有 worker 的新 outbox 消息。返回 `{ workerName, messages }` 条目数组，跳过没有新消息的 worker。便于在监控循环中做批量轮询。

**`resetOutboxCursor(teamName, workerName)`** —— 把某 worker 的 outbox 游标重置回字节 0。lead 重启后想重读历史消息或调试时有用。

### 在监控阶段使用 `getTeamStatus()`

`getTeamStatus(teamName, workingDirectory, heartbeatMaxAgeMs?)` 函数提供统一快照，包含：

- **Worker 注册** —— 哪些 MCP worker 已注册（来自影子注册表 / config.json）
- **心跳新鲜度** —— 每个 worker 基于心跳龄期是否还活
- **任务进度** —— 每个 worker 与全 team 的任务计数（pending、in_progress、completed）
- **当前任务** —— 每个 worker 正在执行哪个任务
- **近期 outbox 消息** —— 自上次状态检查以来的新消息

监控循环中的示例用法：

```typescript
const status = getTeamStatus('fix-ts-errors', workingDirectory);

for (const worker of status.workers) {
  if (!worker.isAlive) {
    // Worker 死了 —— 重新分配它的 in-progress 任务
  }
  for (const msg of worker.recentMessages) {
    if (msg.type === 'task_complete') {
      // 标任务完成，解除依赖者的阻塞
    } else if (msg.type === 'task_failed') {
      // 处理失败，可能重试或重新分配
    } else if (msg.type === 'error') {
      // 记 error，看 worker 是否需要介入
    }
  }
}

if (status.taskSummary.pending === 0 && status.taskSummary.inProgress === 0) {
  // 所有工作完成 —— 进入 shutdown
}
```

### 基于 Outbox 消息的事件动作

| 消息类型 | 动作 |
|-------------|--------|
| `task_complete` | 标任务 completed，检查被阻塞任务是否解锁，通知依赖 worker |
| `task_failed` | 增加失败 sidecar 计数，决定重试 vs 重新分配 vs 跳过 |
| `idle` | worker 无分配任务 —— 分新工作或开始 shutdown |
| `error` | 记 error，检查心跳里的 `consecutiveErrors` 是否触发隔离阈值 |
| `shutdown_ack` | worker 已确认 shutdown —— 可从 team 移除 |
| `heartbeat` | 更新存活跟踪（与心跳文件冗余，但对延迟监控有用） |

这种方式补足已有的基于 `SendMessage` 的通信，为不能用 Kimi CLI team 消息工具的 MCP worker 提供拉式机制。

## 错误处理

### 队友任务失败

1. 队友通过 `SendMessage` 报告失败给 lead
2. Lead 决定：重试（把同任务分给同一或不同 worker）或跳过
3. 重新分配：用 `TaskUpdate` 设新 owner，然后 `SendMessage` 通知新 owner

### 队友卡住（无消息）

1. Lead 通过 `TaskList` 检测 —— 任务 `in_progress` 太久
2. Lead 用 `SendMessage` 询问队友状态
3. 无回应时认为队友已死
4. 通过 `TaskUpdate` 把任务重新分配给另一个 worker

### 依赖阻塞

1. 阻塞任务失败时，lead 必须决定：
   - 重试 blocker
   - 解除依赖（用修改后的 blockedBy 调 `TaskUpdate`）
   - 完全跳过被阻塞任务
2. 通过 `SendMessage` 把决定传达给受影响的队友

### 队友崩溃

1. 该队友的 internal task 显示非预期状态
2. 队友从 `config.json` members 中消失
3. Lead 把孤儿任务重新分配给剩余 worker
4. 需要时用 `Task(team_name, name)` 派一个替代队友

## Team + Ralph 组合

当用户调用 `/team ralph`、说「team ralph」，或同时用上两个关键词时，team 模式把自己包进 Ralph 持久化循环。它提供：

- **Team 编排** —— 多 agent 分阶段流水线，每阶段配专家
- **Ralph 持久化** —— 失败重试、完成前 architect 验证、迭代跟踪

### 激活

Team+Ralph 在以下情况下激活：
1. 用户调用 `/team ralph "task"` 或 `/oh-my-kimi:team ralph "task"`
2. 关键词检测器在 prompt 中同时发现 `team` 与 `ralph`
3. Hook 在 team 上下文旁检测到 `MAGIC KEYWORD: RALPH`

### 状态联动

两个模式各自写状态文件，互相交叉引用：

```
// Team 状态（通过 state_write）
state_write(mode="team", active=true, current_phase="team-plan", state={
  "team_name": "build-rest-api",
  "linked_ralph": true,
  "task": "build a complete REST API"
})

// Ralph 状态（通过 state_write）
state_write(mode="ralph", active=true, iteration=1, max_iterations=10, current_phase="execution", state={
  "linked_team": true,
  "team_name": "build-rest-api"
})
```

### 执行流程

1. Ralph 外层循环启动（iteration 1）
2. Team 流水线运行：`team-plan -> team-prd -> team-exec -> team-verify`
3. `team-verify` 通过：Ralph 跑 architect 验证（至少 STANDARD 等级）
4. architect 批准：两个模式完成，跑 `/oh-my-kimi:cancel`
5. `team-verify` 失败或 architect 拒绝：team 进入 `team-fix`，再回到 `team-exec -> team-verify`
6. fix 循环超过 `max_fix_loops`：Ralph 增加 iteration 并重试整条流水线
7. Ralph 超过 `max_iterations`：终态 `failed`

### 取消

取消任一模式都取消两者：
- **Cancel Ralph（联动）：** 先取消 Team（graceful shutdown），再清 Ralph 状态
- **Cancel Team（联动）：** 清 Team，把 Ralph iteration 标为 cancelled，停止循环

详见下文「取消」章节。

## 幂等恢复

如果 lead 在中途崩溃，team skill 应检测已有状态并恢复：

1. 检查 `${KIMI_CONFIG_DIR:-~/.claude}/teams/` 中匹配 task slug 的 team
2. 找到时读 `config.json` 发现活跃成员
3. 进入 monitor 模式，而不是创建新的重复 team
4. 调用 `TaskList` 确定当前进度
5. 从监控阶段继续

这能防止 team 重复，并允许从 lead 故障中优雅恢复。

## 对比：Team vs 旧版 Swarm

| 方面 | Team（原生） | Swarm（旧版 SQLite） |
|--------|--------------|----------------------|
| **存储** | `~/.claude/teams/` 与 `~/.claude/tasks/` 下的 JSON 文件 | `.omk/state/swarm.db` 中的 SQLite |
| **依赖** | 不需要 `better-sqlite3` | 需要 `better-sqlite3` npm 包 |
| **任务领取** | `TaskUpdate(owner + in_progress)` —— lead 预分配 | SQLite IMMEDIATE 事务 —— 原子 |
| **竞争条件** | 可能（两个 agent 抢同一任务），通过预分配缓解 | 无（SQLite 事务） |
| **通信** | `SendMessage`（DM、broadcast、shutdown） | 无（fire-and-forget agent） |
| **任务依赖** | 内置 `blocks` / `blockedBy` 数组 | 不支持 |
| **心跳** | Kimi CLI 自动 idle 通知 | 手动心跳表 + 轮询 |
| **关闭** | 优雅的请求 / 响应协议 | 基于信号终止 |
| **Agent 生命周期** | 通过 internal task + config 成员自动跟踪 | 通过心跳表手动跟踪 |
| **进度可见性** | `TaskList` 实时显示状态与 owner | tasks 表 SQL 查询 |
| **冲突预防** | owner 字段（lead 分配） | 基于租约的领取 + 超时 |
| **崩溃恢复** | Lead 通过缺失消息检测、重新分配 | 5 分钟租约超时后自动释放 |
| **状态清理** | `TeamDelete` 清理一切 | 手动 `rm` SQLite 数据库 |

**何时用 Team 而不用 Swarm：** 新工作始终优先 `/team`。它基于 Kimi CLI 内置基础设施，不需要外部依赖，支持 agent 间通信，并具备任务依赖管理。

## 取消

`/oh-my-kimi:cancel` skill 负责 team 清理：

1. 通过 `state_read(mode="team")` 读 team 状态，拿到 `team_name` 与 `linked_ralph`
2. 给所有活跃队友（来自 `config.json` members）发 `shutdown_request`
3. 等待每个 `shutdown_response`（每个成员超时 15 秒）
4. 调 `TeamDelete` 移除 team 与任务目录
5. 通过 `state_clear(mode="team")` 清状态
6. 如果 `linked_ralph` 为 true，也清 ralph：`state_clear(mode="ralph")`

### 联动模式取消（Team + Ralph）

team 与 ralph 联动时，取消按依赖顺序进行：

- **从 Ralph 上下文触发的取消：** 先取消 Team（所有队友 graceful shutdown），再清 Ralph 状态。这能确保 worker 在持久化循环退出前先停。
- **从 Team 上下文触发的取消：** 清 Team 状态，再把 Ralph 标为 cancelled。Ralph 的 stop hook 会检测到 team 缺失并停止迭代。
- **强制取消（`--force`）：** 通过 `state_clear` 无条件清掉 `team` 与 `ralph` 状态。

如果队友无响应，`TeamDelete` 可能失败。这时 cancel skill 应短暂等待并重试，或提醒用户手动清理 `~/.claude/teams/{team_name}/` 与 `~/.claude/tasks/{team_name}/`。

## Runtime V2（事件驱动）

设置 `OMC_RUNTIME_V2=1` 时，team 运行时使用事件驱动架构，替代旧的 done.json 轮询看门狗：

- **无 done.json**：任务完成通过 CLI API 生命周期转换（claim-task、transition-task-status）检测
- **基于快照的监控**：每个轮询周期对任务与 worker 拍点位快照，计算 delta 并发事件
- **事件日志**：所有 team 事件追加到 `.omk/state/team/{teamName}/events.jsonl`
- **Worker 状态文件**：worker 把状态写入 `.omk/state/team/{teamName}/workers/{name}/status.json`
- **保留**：哨兵门（阻止过早完成）、断路器（dead worker 检测）、失败 sidecar

v2 运行时由特性开关控制，可按会话开启。旧的 v1 运行时仍是默认。

## 动态伸缩

设置 `OMC_TEAM_SCALING_ENABLED=1` 时，team 支持会话中扩缩容：

- **scale_up**：给运行中的 team 加 worker（遵守 max_workers 上限）
- **scale_down**：移除 idle worker，并优雅 drain（worker 完成当前任务后再移除）
- 基于文件的 scaling 锁防止并发 scale 操作
- 单调递增的 worker index 计数器保证跨 scale 事件的 worker 名唯一

## 配置

可选配置位于 `.claude/omc.jsonc`（项目）或 `~/.config/claude-omc/config.jsonc`（用户）。项目值覆盖用户值；`OMC_TEAM_ROLE_OVERRIDES`（env JSON）覆盖两者。

```jsonc
{
  "team": {
    "ops": {
      "maxAgents": 20,
      "defaultAgentType": "claude",
      "monitorIntervalMs": 30000,
      "shutdownTimeoutMs": 15000
    }
  }
}
```

- **ops.maxAgents** —— 队友上限（默认 20）
- **ops.defaultAgentType** —— `/team` 调用未指定时的 CLI provider（`claude` | `codex` | `gemini`，默认 `claude`）
- **ops.monitorIntervalMs** —— 多久轮询一次 `TaskList`（默认 30s）
- **ops.shutdownTimeoutMs** —— shutdown 响应的等待时长（默认 15s）

> **注意：** team 成员**没有**硬编码的模型默认。每个队友是独立的 Kimi CLI 会话，继承用户配置的模型。由于队友可派出自己的 subagent，会话模型充当编排层，subagent 可使用任意模型层级。

## 按角色的 Provider 与模型路由

> **作用域：** 只适用于 `/team`。基于任务的委派使用 `delegationRouting`（见单独文档）。两套系统按设计共存。

声明每个规范化角色应由哪个 provider（`claude`、`codex`、`gemini`）与哪个模型层级承担。路由在 team 创建时**解析一次**并存进 `TeamConfig.resolved_routing` —— spawn、scale-up、restart 都读快照，因此一个角色的 worker CLI 与模型在 team 生命周期内保持稳定。

### 示例 —— 用户目标映射

```jsonc
// .claude/omc.jsonc
{
  "team": {
    "roleRouting": {
      "orchestrator":  { "model": "inherit" },
      "planner":       { "provider": "claude", "model": "HIGH" },
      "analyst":       { "provider": "claude", "model": "HIGH" },
      "executor":      { "provider": "claude", "model": "MEDIUM" },
      "critic":        { "provider": "codex" },
      "code-reviewer": { "provider": "gemini" },
      "test-engineer": { "provider": "gemini", "model": "MEDIUM" }
    }
  }
}
```

| 角色 | Provider | 模型 |
|---|---|---|
| `orchestrator` | claude（钉死） | 继承调用会话 |
| `planner` | claude | `HIGH`（opus） |
| `analyst` | claude | `HIGH`（opus） |
| `executor` | claude | `MEDIUM`（sonnet） |
| `critic` | codex | codex 默认 |
| `code-reviewer` | gemini | gemini 默认 |
| `test-engineer` | gemini | `MEDIUM`（sonnet） |

### 规范化角色

`orchestrator`、`planner`、`analyst`、`architect`、`executor`、`debugger`、`critic`、`code-reviewer`、`security-reviewer`、`test-engineer`、`designer`、`writer`、`code-simplifier`、`explore`、`document-specialist`。

用户友好的别名通过 `normalizeDelegationRole()` 归一化 —— 例如 `reviewer` → `code-reviewer`，`quality-reviewer` → `code-reviewer`，`harsh-critic` → `critic`，`build-fixer` → `debugger`。被接受的别名键在解析快照创建与之后的阶段路由中都被识别，不只是用于校验。未知角色在解析时校验失败。

### Spec 字段（`TeamRoleAssignmentSpec`）

- **provider** —— `"claude" | "codex" | "gemini"`。省略 → 默认 `claude`。
- **model** —— 层级名（`"HIGH" | "MEDIUM" | "LOW"`）或显式模型 ID。层级通过 `routing.tierModels` 解析。
- **agent** —— 可选 Kimi subagent 名（如 `"critic"`、`"executor"`）。仅当解析后的 provider 是 `claude` 时被采纳。

`orchestrator` 钉死为 `claude`；只有 `model` 由用户可配置。`orchestrator` 上的其他键会被校验器拒绝。

### Env 覆盖

```bash
OMC_TEAM_ROLE_OVERRIDES='{"critic":{"provider":"codex"},"code-reviewer":{"provider":"gemini"}}'
```

优先级：`OMC_TEAM_ROLE_OVERRIDES` > `.claude/omc.jsonc`（项目） > `~/.config/claude-omc/config.jsonc`（用户） > 内置默认。非法 JSON 记 warning 并忽略 —— env 覆盖是尽力而为，永不中止运行。

### Provider CLI 缺失时的回退

如果配置的 provider 在 spawn 时 `PATH` 上没有对应 CLI，`buildLaunchArgs()` 抛错，team lead 通过 `SendMessage` 发出可见 warning，运行时回退到 `buildResolvedRoutingSnapshot` 预先计算的确定性 Claude 分配（同层级 + 同 agent，`provider: "claude"`）。回退按设计是显式的 —— 静默回退是测试失败。用 `omk doctor --team-routing` 探测 provider 可用性。

### 黏性 —— 一次解析、处处复用

解析后的路由对每个 team 是不可变的。在 team 生命周期中编辑配置不会影响运行中的 team；新一次 `/team` 调用才会使用新映射。这保证 spawn、scale-up 与 worker-restart 看到完全相同的路由，包括跨 worktree detach（快照随 `TeamConfig` 一起走）。

### 零配置行为

空的 `team.roleRouting` 保留补丁前行为：每个 worker 是 Claude，模型层级跟随 `routing.tierModels`，`/team 3:executor ...` 仍然派出三个 Kimi executor。

## 状态清理

成功完成时：

1. `TeamDelete` 负责所有 Kimi CLI 状态：
   - 移除 `~/.claude/teams/{team_name}/`（config）
   - 移除 `~/.claude/tasks/{team_name}/`（所有任务文件 + 锁）
2. oh-my-kimi 状态清理通过 MCP 工具：
   ```
   state_clear(mode="team")
   ```
   联动到 Ralph 时：
   ```
   state_clear(mode="ralph")
   ```
3. 或者跑 `/oh-my-kimi:cancel`，它会自动做所有清理。

**重要：** `TeamDelete` 必须在**所有**队友已 shutdown **之后**调用。如果 config 中还有除 lead 之外的活跃成员，`TeamDelete` 会失败。

## Git Worktree 集成

MCP worker 可以在隔离的 git worktree 中工作，防止并发 worker 之间的文件冲突。

### 工作方式

1. **创建 worktree**：在派 worker 前调用 `createWorkerWorktree(teamName, workerName, repoRoot)` 在 `.omk/worktrees/{team}/{worker}` 创建隔离 worktree，分支为 `omc-team/{teamName}/{workerName}`。

2. **Worker 隔离**：把 worktree 路径作为 worker `BridgeConfig` 的 `workingDirectory` 传入。worker 只在自己的 worktree 内工作。

3. **合并协调**：worker 完成任务后用 `checkMergeConflicts()` 验证分支可干净合并，再用 `mergeWorkerBranch()` 带 `--no-ff` 合并，留下清晰历史。

4. **Team 清理**：team shutdown 时调用 `cleanupTeamWorktrees(teamName, repoRoot)` 移除所有 worktree 与对应分支。

### API 参考

| 函数 | 描述 |
|----------|-------------|
| `createWorkerWorktree(teamName, workerName, repoRoot, baseBranch?)` | 创建隔离 worktree |
| `removeWorkerWorktree(teamName, workerName, repoRoot)` | 移除 worktree 与分支 |
| `listTeamWorktrees(teamName, repoRoot)` | 列出所有 team worktree |
| `cleanupTeamWorktrees(teamName, repoRoot)` | 移除所有 team worktree |
| `checkMergeConflicts(workerBranch, baseBranch, repoRoot)` | 非破坏性冲突检查 |
| `mergeWorkerBranch(workerBranch, baseBranch, repoRoot)` | 合并 worker 分支（--no-ff） |
| `mergeAllWorkerBranches(teamName, repoRoot, baseBranch?)` | 合并所有完成的 worker |

### 重要说明

- `tmux-session.ts` 中的 `createSession()` **不**处理 worktree 创建 —— worktree 生命周期由 `git-worktree.ts` 单独管理
- 单个 worker shutdown **不**清理 worktree —— 只在 team shutdown 时清理，以便事后检查
- 分支名通过 `sanitizeName()` 清洗，防止注入
- 所有路径都做目录穿越校验

## 坑

1. **Internal task 会污染 TaskList** —— 派出队友时系统自动创建带 `metadata._internal: true` 的 internal task。它们会出现在 `TaskList` 输出里。数真实任务进度时要过滤掉。internal task 的 subject 就是队友名。

2. **没有原子领取** —— 与 SQLite swarm 不同，`TaskUpdate` 没有事务保证。两个队友可能竞争领取同一任务。**缓解：** lead 应在派出队友之前通过 `TaskUpdate(taskId, owner)` 预分配 owner。队友只做分配给自己的任务。

3. **Task ID 是字符串** —— ID 是自增字符串（"1"、"2"、"3"），不是整数。`taskId` 字段始终传字符串值。

4. **TeamDelete 需要空 team** —— 调 `TeamDelete` 前所有队友必须已 shutdown。lead（仅剩成员）不在此检查内。

5. **消息自动投递** —— 队友消息作为新对话回合到达 lead。入站消息**不**需要轮询或查 inbox。但如果 lead 正在 turn 中（处理中），消息会排队，turn 结束后投递。

6. **队友 prompt 存在 config 中** —— 完整 prompt 文本存在 `config.json` members 数组里。**不要**把密钥或敏感数据放进队友 prompt。

7. **成员在 shutdown 后自动移除** —— 队友批准 shutdown 并终止后，会自动从 `config.json` 移除。不要重读 config 期望找到已关闭的队友。

8. **shutdown_response 需要 request_id** —— 队友必须从入站 shutdown 请求 JSON 中抽取 `request_id` 原样回传。格式是 `shutdown-{timestamp}@{worker-name}`。伪造该 ID 会导致 shutdown 静默失败。

9. **Team 名必须是合法 slug** —— 用小写字母、数字与连字符。从任务描述派生（例如 "fix TypeScript errors" 派生为 "fix-ts-errors"）。

10. **Broadcast 很贵** —— 每次 broadcast 给每个队友各发一条独立消息。默认用 `message`（DM）。只在真正全 team 范围的关键告警时才广播。

11. **CLI worker 是一次性的，不是持久的** —— Tmux CLI worker 有完整文件系统访问，**可以**改代码。但它们是自主一次性作业 —— 不能用 TaskList / TaskUpdate / SendMessage。Lead 必须管理其生命周期：写 prompt_file、派 CLI worker、读 output_file、标任务完成。它们不像 Kimi subagent 那样参与 team 通信。
