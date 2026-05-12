---
name: ralph
description: 自引用循环直至任务完成，并由 architect 验证
---

[RALPH + ULTRAWORK - ITERATION {{ITERATION}}/{{MAX}}]

Your previous attempt did not output the completion promise. Continue working on the task.

<Purpose>
Ralph 是一个持久化循环，会持续推进任务直到完全完成并经 architect 验证。它在 ultrawork 的并行执行外裹上会话持久化、失败自动重试，以及完成前的强制验证。
</Purpose>

<Use_When>
- 任务需要带验证的保证完成（而非「尽力而为」）
- 用户说 "ralph"、"don't stop"、"must complete"、"finish this" 或 "keep going until done"
- 工作可能跨多次迭代，需要跨重试的持久化
- 任务适合并行执行，并在末尾让 architect 签字
</Use_When>

<Do_Not_Use_When>
- 用户想要「从想法到代码」的完全自主 pipeline —— 改用 `autopilot`
- 用户想先探索或规划再承诺 —— 改用 `plan` skill
- 用户想要一击即中的快修 —— 直接委派给 executor agent
- 用户想手动控制何时算完成 —— 直接用 `ultrawork`
</Do_Not_Use_When>

<Why_This_Exists>
复杂任务常常静默失败：部分实现被宣布为「done」、测试被跳过、边界情况被遗忘。Ralph 通过持续循环直到工作真正完成、要求新鲜的验证证据后才允许完成、并通过分层的 architect 评审来确认质量，避免这些问题。
</Why_This_Exists>

<Execution_Policy>
- 同时发起独立的 agent 调用 —— 永远不要顺序等待独立工作
- 长操作（installs、builds、test suites）使用 `run_in_background: true`
- 委派给 agent 时始终显式传 `model` 参数
- 第一次委派前先读 `docs/shared/agent-tiers.md`，挑选正确的 agent tier
- 交付完整实现：不缩范围、不部分完成、不删测试以让它通过
- 应用共享工作流指引模式：outcome-first 框架、多步执行的简洁可见更新、对当前工作流分支的本地覆盖、与风险成比例的校验、显式停止规则，以及对安全可逆步骤的自动续推。仅在重大、破坏性、需凭证、对接外部生产或依赖偏好的分支上才求问。
- 当 goal 工具可用时与 Codex goal mode 集成：用 `get_goal` 检视当前线程 goal，把它保留为顶层停止条件，且仅在 Ralph 的完成审计证明目标真的达成后调用 `update_goal({status: "complete"})`。
</Execution_Policy>

<Steps>
0. **预先上下文采集（在规划 / 执行循环开始前必做）**：
   - 在 `.omk/context/{task-slug}-{timestamp}.md`（UTC `YYYYMMDDTHHMMSSZ`）组装或加载一份上下文快照。
   - 快照至少包含：
     - 任务陈述
     - 期望结果
     - 已知事实 / 证据
     - 约束
     - 未知 / 待定问题
     - 可能涉及的代码库触点
   - 若已有相关快照可用，复用之，并把路径记到 Ralph state。
   - 如果请求歧义大，先收集 brownfield 事实。session 指引启用 `USE_OMX_EXPLORE_CMD` 时，简单只读仓库查询用 `omk explore` 配窄而具体的 prompt；否则走更丰富的常规 explore 路径。然后跑 `$deep-interview --quick <task>` 补齐关键缺口。
   - 在快照落地之前不要启动 Ralph 执行工作（委派、实现或验证循环）。若被迫快速推进，显式标注风险取舍。
1. **回顾进度**：检查 TODO 列表与任何先前迭代状态
2. **从上次停下的位置继续**：拾起未完成任务
3. **并行委派**：把任务路由到合适 tier 的专精 agent
   - 简单查询：LOW tier —— "这个函数返回什么？"
   - 标准工作：STANDARD tier —— "给这个模块加错误处理"
   - 复杂分析：THOROUGH tier —— "调试这个 race condition"
   - 当 Ralph 是作为 ralplan 的后续进入时，从被批准的 **available-agent-types roster** 出发，并显式给出委派计划：实现 lane、证据 / 回归 lane、最终签字 lane，且只用已知的 agent 类型
4. **长操作放后台**：构建、安装、测试套件用 `run_in_background: true`
5. **视觉任务闸门（含截图 / 参考图时）**：
   - 在**每次下一编辑前**都跑 Visual Ralph 判定步骤。
   - 要求结构化 JSON 输出：`score`、`verdict`、`category_match`、`differences[]`、`suggestions[]`、`reasoning`。
   - 把判定持久化到 `.omk/state/{scope}/ralph-progress.json`，含数值 + 定性反馈。
   - 默认通过阈值：`score >= 90`。
   - **基于 URL 的视觉克隆任务**：任务描述含目标 URL（例如 "clone https://example.com"）时，把工作路由到 `$visual-ralph`。`$web-clone` 硬弃用；Visual Ralph 接管已迁移的实时 URL 视觉实现用例，并用其内置视觉判定步骤做可测量的视觉打分。
6. **用新鲜证据校验完成**：
   - 若 Codex goal mode 可用，在最终校验前调 `get_goal` 复述当前目标，并把它纳入证据 checklist。
   a. 找到能证明任务完成的命令
   b. 跑校验（test、build、lint）
   c. 读输出 —— 确认它真的过了
   d. 检查：零个 pending/in_progress TODO 项
7. **Architect 验证**（分层）：
   - <5 文件、<100 行且测试齐全：至少 STANDARD tier（architect 角色）
   - 标准变更：STANDARD tier（architect 角色）
   - >20 文件或涉及安全 / 架构变更：THOROUGH tier（architect 角色）
   - Ralph 底线：始终至少 STANDARD，即便是小改动
7.5 **强制 Deslop Pass**：
   - 步骤 7 通过后，对 **Ralph 会话中变更的所有文件**跑 `oh-my-kimi:ai-slop-cleaner`。
   - 清理范围限定为**变更文件**；不要扩大到 Ralph 自有编辑之外。
   - 用**标准模式**跑清理器（不要 `--review`）。
   - 若 prompt 含 `--no-deslop`，整段跳过步骤 7.5，沿用最近一次成功验证证据。
7.6 **回归再校验**：
   - deslop 后重新跑所有 tests/build/lint，并读输出确认仍通过。
   - 若 post-deslop 回归失败，回滚清理改动或定向修复后重试。然后重跑步骤 7.5 与 7.6，直到回归绿。
   - 在 post-deslop 回归绿之前不要进入完成（除非 `--no-deslop` 显式跳过）。
8. **批准时**：若 Codex goal mode 激活，在 `/cancel` 前调 `update_goal({status: "complete"})`；当工具返回时报告最终耗时与 token-budget 使用。然后跑 `/cancel` 干净退出并清理状态文件。
9. **被驳回时**：修复指出的问题，然后在同 tier 重新验证
</Steps>

<Tool_Usage>
- 当改动安全敏感、涉及架构或多系统集成时，使用 `ask_codex` 配 `agent_role: "architect"` 做验证交叉核对
- 简单的功能新增、已充分测试的改动或时效紧迫的验证可以跳过 Codex 咨询
- MCP 兼容工具不可用时，仅靠 CLI/agent 验证继续 —— 永远不要在外部工具上阻塞
- 用 `omk state write/read --input '<json>' --json` 在迭代之间持久化 ralph 模式状态
- 存在 Codex goal 工具时使用：`get_goal` 发现或复检当前目标，`create_goal` 仅在用户 / 系统显式要求新建 goal 且当前无激活 goal 时使用，`update_goal` 仅在被审计目标完全达成后使用。
- 把上下文快照路径写入 Ralph 模式状态，让后续阶段与 agent 共享同一份接地上下文
- 优先 CLI 状态命令。若显式 MCP 兼容 `omx_state` 调用报告其 stdio transport 不可用 / 关闭，**不要**重试同一 MCP 调用。改为通过受支持的 CLI 同步面用同一 payload 重试一次，并保留 `workingDirectory` 与 `session_id`：`omk state write --input '<json>' --json`、`omk state read --input '<json>' --json` 或 `omk state clear --input '<json>' --json`。若 CLI 路径也失败，转用 `.omk/context` / `.omk/plans` 等文件支持的工件，并报告状态持久化的阻塞。
</Tool_Usage>

## Goal Mode 集成

Codex goal mode 是长跑 Ralph 工作的线程级完成契约。Ralph state 跟踪工作流机制；goal mode 跟踪用户目标是否真的达成。当 goal 工具可用时：

1. 当 prompt/hook 说存在 active 线程目标时，在 intake 或第一次执行循环之前调 `get_goal`。
2. 若不存在目标，仅当用户或系统显式要求 goal 跟踪时才调 `create_goal`；否则只用 Ralph state。
3. 把 `goal.objective` 当作有约束力的验收范围。新用户更新可以精炼当前分支，但不要静默缩窄目标。
4. 完成前对真实证据做 prompt-to-artifact 检查与完成审计：
   - 把目标复述为交付物 / 成功标准
   - 把每条 prompt 要求、命名工作流（`$ralplan`、`$ralph`）、文件、命令、测试、闸门与交付物映射到证据
   - 检视每一条 checklist 背后实际的文件、命令输出、状态与测试
   - 找出缺失、校验薄弱或未覆盖的要求，仍有就继续
5. 仅当审计显示无未完成必须工作时才调 `update_goal({status: "complete"})`。不要把通过的测试、Ralph state 或 architect 通过当作通用证明，除非它们覆盖整个目标。
6. 若 goal 工具不可用，继续用 Ralph state 推进，并在最终报告里提一下缺少 goal-mode 证据。

## 状态管理

用 CLI-first 的状态接口管 Ralph 生命周期状态（`omk state write/read/clear --input '<json>' --json`）。显式 MCP 兼容工具（`state_write`、`state_read`、`state_clear`）仅在已启用时才可用。

- **启动时**：
  `omk state write --input '{"mode":"ralph","active":true,"iteration":1,"max_iterations":10,"current_phase":"executing","started_at":"<now>","state":{"context_snapshot_path":"<snapshot-path>"}}' --json`
- **每次迭代**：
  `omk state write --input '{"mode":"ralph","iteration":<current>,"current_phase":"executing"}' --json`
- **验证 / 修复切换**：
  `omk state write --input '{"mode":"ralph","current_phase":"verifying"}' --json` 或 `omk state write --input '{"mode":"ralph","current_phase":"fixing"}' --json`
- **完成时**：
  `omk state write --input '{"mode":"ralph","active":false,"current_phase":"complete","completed_at":"<now>"}' --json`
- **取消 / 清理**：
  跑 `$cancel`（它应当调 `omk state clear --input '{"mode":"ralph"}' --json`）


## 场景示例

**Good：** 工作流已有清晰的下一步，用户说 `continue`。沿当前分支继续，不重启也不重复问同样问题。

**Good：** 用户只改变输出形态或下游交付步骤（例如 `make a PR`）。保留此前不冲突的工作流约束，并在局部应用更新。

**Bad：** 用户说 `continue`，工作流却重启发现流程，或在缺失校验 / 证据收齐之前就停下。

<Examples>
<Good>
正确的并行委派：
```
delegate(role="executor", tier="LOW", task="Add type export for UserConfig")
delegate(role="executor", tier="STANDARD", task="Implement the caching layer for API responses")
delegate(role="executor", tier="THOROUGH", task="Refactor auth module to support OAuth2 flow")
```
为什么好：三件独立任务在合适 tier 同时发起。
</Good>

<Good>
完成前的正确验证：
```
1. Run: npm test           → Output: "42 passed, 0 failed"
2. Run: npm run build      → Output: "Build succeeded"
3. Run: lsp_diagnostics    → Output: 0 errors
4. Delegate to architect at STANDARD tier  → Verdict: "APPROVED"
5. Run /cancel
```
为什么好：每步都有新鲜证据、architect 验证，最后干净退出。
</Good>

<Bad>
未经验证就声称完成：
"All the changes look good, the implementation should work correctly. Task complete."
为什么差：用了 "should" 与 "look good" —— 没新鲜的 test/build 输出、没 architect 验证。
</Bad>

<Bad>
独立任务串行执行：
```
delegate(executor, LOW, "Add type export") → wait →
delegate(executor, STANDARD, "Implement caching") → wait →
delegate(executor, THOROUGH, "Refactor auth")
```
为什么差：这些独立任务应并行而非串行。
</Bad>
</Examples>

<Escalation_And_Stop_Conditions>
- 当根本性阻塞需要用户输入（缺凭证、需求不清、外部服务挂了）时停下并报告
- 用户说 "stop"、"cancel" 或 "abort" 时停下 —— 跑 `/cancel`
- 当 hook 系统发 "The boulder never stops" 时继续工作 —— 它意味着迭代继续
- 若 architect 拒绝验证，修问题并重新验证（不停）
- 同一问题在 3+ 轮迭代后复发，把它当作潜在的根本性问题报告
</Escalation_And_Stop_Conditions>

<Final_Checklist>
- [ ] 原任务的所有要求都满足（不缩范围）
- [ ] 零 pending 或 in_progress TODO 项
- [ ] 新鲜测试运行输出显示全部通过
- [ ] 新鲜 build 输出显示成功
- [ ] 受影响文件的 lsp_diagnostics 显示 0 错误
- [ ] Architect 验证通过（至少 STANDARD tier）
- [ ] Codex goal-mode 完成审计通过，且当存在 active goal 时调过 `update_goal({status: "complete"})`
- [ ] 变更文件已完成 ai-slop-cleaner pass（或指定了 --no-deslop）
- [ ] post-deslop 回归测试通过
- [ ] 跑了 `/cancel` 做状态清理
</Final_Checklist>

<Advanced>
## PRD Mode（可选）

用户提供 `--prd` 标志时，在启动 ralph 循环前先初始化一份 Product Requirements Document。

### 检测 PRD Mode
检查 `{{PROMPT}}` 是否含 `--prd` 或 `--PRD`。

prompt 侧的 `$ralph` 工作流激活比 `omk ralph --prd ...` 更轻量。
它播种 Ralph 工作流状态与指引，但不隐式启动 CLI 入口或应用 PRD 启动闸门。把 `omk ralph --prd ...` 当作显式 PRD-gated 路径。

### 检测 `--no-deslop`
检查 `{{PROMPT}}` 是否含 `--no-deslop`。
若有，整段跳过步骤 7 之后的 deslop pass，沿用最近一次成功 pre-deslop 校验证据。

### 视觉参考标志（可选）
Ralph 执行支持视觉参考标志用于截图任务：
- 可重复图片输入：`-i <image-path>`（可多次）
- 图片目录输入：`--images-dir <directory>`

例：
`ralph -i refs/hn.png -i refs/hn-item.png --images-dir ./screenshots "match HackerNews layout"`

### PRD 工作流
1. 在创建 PRD 工件之前用 quick 模式跑 deep-interview：
   - 执行：`$deep-interview --quick <task>`
   - 完成一遍紧凑的需求 pass（context、goals、scope、constraints、validation）
   - 把访谈输出持久化到 `.omk/interviews/{slug}-{timestamp}.md`
2. 创建权威的 PRD / progress 工件：
   - PRD：`.omk/plans/prd-{slug}.md`
   - Progress ledger：`.omk/state/{scope}/ralph-progress.json`（可用时用 session scope，否则用 root scope）
3. 解析任务（`--prd` 标志之后的全部）
4. 拆成 user stories：

```json
{
  "project": "[Project Name]",
  "branchName": "ralph/[feature-name]",
  "description": "[Feature description]",
  "userStories": [
    {
      "id": "US-001",
      "title": "[Short title]",
      "description": "As a [user], I want to [action] so that [benefit].",
      "acceptanceCriteria": ["Criterion 1", "Typecheck passes"],
      "priority": 1,
      "passes": false
    }
  ]
}
```

5. 在 `.omk/state/{scope}/ralph-progress.json` 初始化权威 progress ledger
6. 准则：合适大小的 story（每个一次 session）、可校验标准、独立 story、按优先级排序（基础工作在前）
7. 进入正常 ralph 循环，把 user stories 当作任务列表

### 例
用户输入：`--prd build a todo app with React and TypeScript`
工作流：检测标志、抽取任务、创建 `.omk/plans/prd-{slug}.md`、创建 `.omk/state/{scope}/ralph-progress.json`、开始 ralph 循环。

### 旧版兼容
- 在兼容窗口期，Ralph `--prd` 启动仍校验 `.omk/prd.json` 的机器可读 story 状态。
- `.omk/plans/prd-{slug}.md` 仍是权威存储 / 文档工件，但还不是启动校验源。
- 若 `.omk/prd.json` 存在且权威 PRD 缺失，单向迁移到 `.omk/plans/prd-{slug}.md`。
- 若 `.omk/progress.txt` 存在且权威 progress ledger 缺失，单向导入到 `.omk/state/{scope}/ralph-progress.json`。
- 旧文件在一个发布周期内保持不变。

## 后台执行规则

**放后台**（`run_in_background: true`）：
- 包安装（npm install、pip install、cargo build）
- 构建过程（make、项目 build 命令）
- 测试套件
- Docker 操作（docker build、docker pull）

**阻塞前台**：
- 快速状态查看（git status、ls、pwd）
- 文件读写编辑
- 简单命令
</Advanced>

Original task:
{{PROMPT}}
