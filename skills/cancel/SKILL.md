---
name: cancel
description: 取消任何活跃的 oh-my-kimi 模式（autopilot、ralph、ultrawork、ecomode、ultraqa、swarm、ultrapilot、pipeline、team）
---

# Cancel Skill

智能检测并取消活跃的 oh-my-kimi 模式。

**cancel skill 是收尾并退出任意 oh-my-kimi 模式的标准方式。**
当 stop hook 检测到工作完成时，会指示 LLM 调用本 skill 做状态清理。如果 cancel 失败或被中断，可加 `--force` 重试，或作为最后手段等待 2 小时的过期超时。

## 做什么

自动检测当前活跃的模式并取消：
- **Autopilot**：停止工作流，保留进度以便恢复
- **Ralph**：停止持久化循环，若有关联则清理 linked ultrawork
- **Ultrawork**：停止并行执行（独立或 linked）
- **Ecomode**：停止 token-efficient 并行执行（独立或与 ralph 关联）
- **UltraQA**：停止 QA 循环工作流
- **Swarm**：停止协同 agent swarm，释放已认领的任务
- **Ultrapilot**：停止并行 autopilot worker
- **Pipeline**：停止顺序 agent 流水线
- **Team**：给所有 worker 发关停 inbox，等待退出，杀掉 tmux 会话，并清空 team 状态

## 用法

```
/cancel
```

或者说："cancelomc"、"stopomc"。

## 自动检测

`/cancel` 遵循会话感知的状态契约：
- 默认情况下，命令通过 `state_list_active` 与 `state_get_status` 检视当前会话，按 `.omk/state/sessions/{sessionId}/…` 路径发现活跃模式。
- 当提供了 session id 或已知时，该会话作用域路径为权威。`.omk/state/*.json` 下的旧文件只在 session id 缺失或为空时作为兼容回退。
- Swarm 是共享的 SQLite / marker 模式（`.omk/state/swarm.db` / `.omk/state/swarm-active.marker`），不受 session 作用域约束。
- 默认清理流程用 session id 调用 `state_clear`，仅移除匹配的 session 文件；模式仍绑定到它们的发起会话。

## Ralph 取消的规范性后置条件（MUST）

针对 Ralph 的取消（独立或 linked），按后置条件判定是否完成：

1. 目标 Ralph state 被「终态化」，而非静默删除：
   - `active=false`
   - `current_phase='cancelled'`
   - `completed_at` 已设置（ISO 时间戳）
2. 若 Ralph 在同一作用域内 linked 到 Ultrawork 或 Ecomode，则该 linked 模式也被终态化 / 非活跃。
4. 取消必须保持作用域安全：不得改动无关 session。

参见：`docs/contracts/ralph-cancel-contract.md`。

活跃模式仍按依赖顺序取消：
1. Autopilot（含 linked ralph/ultraqa/ecomode 清理）
2. Ralph（清理其 linked ultrawork 或 ecomode）
3. Ultrawork（独立）
4. Ecomode（独立）
5. UltraQA（独立）
6. Swarm（独立）
7. Ultrapilot（独立）
8. Pipeline（独立）
9. Team（基于 tmux）
10. Plan Consensus（独立）

## Ralph 后置条件的规范性约束（MUST）

当取消针对某个作用域内的 Ralph state 时，完成必须同时满足以下全部条件：

1. 在该作用域内 Ralph state 处于终态：`active=false`、`current_phase='cancelled'`（或 linked 的终态阶段）、并设置 `completed_at`。
2. 同作用域内 linked 的 Ultrawork/Ecomode 也处于终态 / 非活跃。
4. 无关 session 不受影响。

## 强制清理全部

需要擦除所有 session 加遗留工件（例如整工作区重置）时用 `--force` 或 `--all`。

```
/cancel --force
```

```
/cancel --all
```

幕后步骤：
1. `state_list_active` 枚举 `.omk/state/sessions/{sessionId}/…` 找出每个已知 session。
2. 每个 session 跑一次 `state_clear` 删掉该 session 的文件。
3. 一次无 `session_id` 的全局 `state_clear` 删除 `.omk/state/*.json` 下的旧文件、`.omk/state/swarm*.db` 与兼容工件（见列表）。
4. Team 工件（`.omk/state/team/*/`、匹配 `omx-team-*` 的 tmux 会话）作为兼容回退的一部分尽力清理。

每个 `state_clear` 命令都尊重 `session_id` 参数，因此即便是 force 模式也仍先走 session 感知路径，再去删旧文件。

兼容遗留清单（只在 `--force`/`--all` 下移除）：
- `.omk/state/autopilot-state.json`
- `.omk/state/ralph-state.json`
- `.omk/state/ralph-plan-state.json`
- `.omk/state/ralph-verification.json`
- `.omk/state/ultrawork-state.json`
- `.omk/state/ecomode-state.json`
- `.omk/state/ultraqa-state.json`
- `.omk/state/swarm.db`
- `.omk/state/swarm.db-wal`
- `.omk/state/swarm.db-shm`
- `.omk/state/swarm-active.marker`
- `.omk/state/swarm-tasks.db`
- `.omk/state/ultrapilot-state.json`
- `.omk/state/ultrapilot-ownership.json`
- `.omk/state/pipeline-state.json`
- `.omk/state/plan-consensus.json`
- `.omk/state/ralplan-state.json`
- `.omk/state/boulder.json`
- `.omk/state/hud-state.json`
- `.omk/state/subagent-tracking.json`
- `.omk/state/subagent-tracker.lock`
- `.omk/state/rate-limit-daemon.pid`
- `.omk/state/rate-limit-daemon.log`
- `.omk/state/checkpoints/` (directory)
- `.omk/state/sessions/`（清完 session 后空目录清理）

## 实现步骤

调用该 skill 时：

### 1. 解析参数

```bash
# Check for --force or --all flags
FORCE_MODE=false
if [[ "$*" == *"--force"* ]] || [[ "$*" == *"--all"* ]]; then
  FORCE_MODE=true
fi
```

### 2. 检测活跃模式

skill 现在依赖会话感知的状态契约，而不是硬编码文件路径：
1. 调用 `state_list_active` 枚举 `.omk/state/sessions/{sessionId}/…`，发现每个活跃 session。
2. 对每个 session id 调用 `state_get_status` 了解正在跑的模式（`autopilot`、`ralph`、`ultrawork` 等）以及是否存在依赖模式。
3. 如果 `/cancel` 传入了 `session_id`，完全跳过遗留回退，只在该 session 路径下操作；否则只有当状态工具报告无活跃 session 时才查阅 `.omk/state/*.json` 下的旧文件。Swarm 仍是 session 作用域外的共享 SQLite / marker 模式。
4. 本文中的任何取消逻辑都镜像状态工具发现的依赖顺序（autopilot → ralph → …）。

### 3A. Force Mode（若 --force 或 --all）

用 force 模式通过 `state_clear` 清掉所有 session 加遗留工件。只有当状态工具报告无活跃 session 时才用直接删文件做遗留清理。

### 3B. 智能取消（默认）

#### 若 Team 活跃（基于 tmux）

通过检查 `.omk/state/team/` 下的配置文件检测 team：

```bash
# Check for active teams
ls .omk/state/team/*/config.json 2>/dev/null
```

**两遍取消协议：**

**Pass 1：优雅关停**
```
For each team found in .omk/state/team/:
  1. Read config.json to get team_name and workers list
  2. For each worker:
     a. Write shutdown inbox to .omk/state/team/{name}/workers/{worker}/inbox.md
     b. Send short trigger via tmux send-keys
     c. Wait up to 15 seconds for worker tmux pane to exit
     d. If still alive: mark as unresponsive
```

**Pass 2：强制 kill**
```
After graceful pass:
  1. For each remaining alive worker:
     a. Send C-c via tmux send-keys
     b. Wait 2 seconds
     c. Kill the tmux window if still alive
  2. Destroy the tmux session: tmux kill-session -t omx-team-{name}
```

**清理：**
```
  1. Strip AGENTS.md team worker overlay (<!-- OMK:TEAM:WORKER:START/END -->)
  2. Remove team state directory: rm -rf .omk/state/team/{name}/
  3. Clear team mode state: state_clear(mode="team")
  4. Emit structured cancel report
```

**结构化取消报告：**
```
Team "{team_name}" cancelled:
  - Workers signaled: N
  - Graceful exits: M
  - Force killed: K
  - tmux session destroyed: yes/no
  - State cleaned up: yes/no
```

**实现备注：** cancel skill 是由 LLM 执行的，不是 bash 脚本。当你检测到活跃 team 时：
1. 检查 `.omk/state/team/*/config.json` 找活跃 team
2. 对 config.workers 中的每个 worker，写关停 inbox 并发触发
3. 短暂等待 worker 退出（15s 超时）
4. 通过 tmux 强制 kill 剩余 worker
5. 销毁 tmux 会话：`tmux kill-session -t omx-team-{name}`
6. 剥离 AGENTS.md overlay
7. 删除状态：`rm -rf .omk/state/team/{name}/`
8. `state_clear(mode="team")`
9. 向用户报告结构化总结

#### 若 Autopilot 活跃

调用 `src/hooks/autopilot/cancel.ts:27-78` 的 `cancelAutopilot()`：

```bash
# Autopilot handles its own cleanup + ralph + ultraqa
# Just mark autopilot as inactive (preserves state for resume)
if [[ -f .omk/state/autopilot-state.json ]]; then
  # Clean up ralph if active
  if [[ -f .omk/state/ralph-state.json ]]; then
    RALPH_STATE=$(cat .omk/state/ralph-state.json)
    LINKED_UW=$(echo "$RALPH_STATE" | jq -r '.linked_ultrawork // false')

    # Clean linked ultrawork first
    if [[ "$LINKED_UW" == "true" ]] && [[ -f .omk/state/ultrawork-state.json ]]; then
      rm -f .omk/state/ultrawork-state.json
      echo "Cleaned up: ultrawork (linked to ralph)"
    fi

    # Clean ralph
    rm -f .omk/state/ralph-state.json
    rm -f .omk/state/ralph-verification.json
    echo "Cleaned up: ralph"
  fi

  # Clean up ultraqa if active
  if [[ -f .omk/state/ultraqa-state.json ]]; then
    rm -f .omk/state/ultraqa-state.json
    echo "Cleaned up: ultraqa"
  fi

  # Mark autopilot inactive but preserve state
  CURRENT_STATE=$(cat .omk/state/autopilot-state.json)
  CURRENT_PHASE=$(echo "$CURRENT_STATE" | jq -r '.phase // "unknown"')
  echo "$CURRENT_STATE" | jq '.active = false' > .omk/state/autopilot-state.json

  echo "Autopilot cancelled at phase: $CURRENT_PHASE. Progress preserved for resume."
  echo "Run /autopilot to resume."
fi
```

#### 若 Ralph 活跃（且 Autopilot 未活跃）

调用 `src/hooks/ralph-loop/index.ts:147-182` 的 `clearRalphState()` + `clearLinkedUltraworkState()`：

```bash
if [[ -f .omk/state/ralph-state.json ]]; then
  # Check if ultrawork is linked
  RALPH_STATE=$(cat .omk/state/ralph-state.json)
  LINKED_UW=$(echo "$RALPH_STATE" | jq -r '.linked_ultrawork // false')

  # Clean linked ultrawork first
  if [[ "$LINKED_UW" == "true" ]] && [[ -f .omk/state/ultrawork-state.json ]]; then
    UW_STATE=$(cat .omk/state/ultrawork-state.json)
    UW_LINKED=$(echo "$UW_STATE" | jq -r '.linked_to_ralph // false')

    # Only clear if it was linked to ralph
    if [[ "$UW_LINKED" == "true" ]]; then
      rm -f .omk/state/ultrawork-state.json
      echo "Cleaned up: ultrawork (linked to ralph)"
    fi
  fi

  # Clean ralph state
  rm -f .omk/state/ralph-state.json
  rm -f .omk/state/ralph-plan-state.json
  rm -f .omk/state/ralph-verification.json

  echo "Ralph cancelled. Persistent mode deactivated."
fi
```

#### 若 Ultrawork 活跃（独立，未 linked）

调用 `src/hooks/ultrawork/index.ts:150-173` 的 `deactivateUltrawork()`：

```bash
if [[ -f .omk/state/ultrawork-state.json ]]; then
  # Check if linked to ralph
  UW_STATE=$(cat .omk/state/ultrawork-state.json)
  LINKED=$(echo "$UW_STATE" | jq -r '.linked_to_ralph // false')

  if [[ "$LINKED" == "true" ]]; then
    echo "Ultrawork is linked to Ralph. Use /cancel to cancel both."
    exit 1
  fi

  # Remove local state
  rm -f .omk/state/ultrawork-state.json

  echo "Ultrawork cancelled. Parallel execution mode deactivated."
fi
```

#### 若 UltraQA 活跃（独立）

调用 `src/hooks/ultraqa/index.ts:107-120` 的 `clearUltraQAState()`：

```bash
if [[ -f .omk/state/ultraqa-state.json ]]; then
  rm -f .omk/state/ultraqa-state.json
  echo "UltraQA cancelled. QA cycling workflow stopped."
fi
```

#### 没有活跃模式

```bash
echo "No active oh-my-kimi modes detected."
echo ""
echo "Checked for:"
echo "  - Autopilot (.omk/state/autopilot-state.json)"
echo "  - Ralph (.omk/state/ralph-state.json)"
echo "  - Ultrawork (.omk/state/ultrawork-state.json)"
echo "  - UltraQA (.omk/state/ultraqa-state.json)"
echo ""
echo "Use --force to clear all state files anyway."
```

## 实现备注

cancel skill 的执行流程：
1. 解析 `--force` / `--all` 标志，跟踪清理范围是覆盖所有 session 还是仅限当前 session id。
2. 用 `state_list_active` 枚举已知 session id，用 `state_get_status` 了解每个 session 上活跃的模式（`autopilot`、`ralph`、`ultrawork` 等）。
3. 默认模式下，按 session_id 调用 `state_clear` 仅删除该 session 文件，再根据状态工具的信号按 mode-specific 顺序（autopilot → ralph → …）做清理。
4. force 模式下，遍历每个活跃 session、逐个 `state_clear`，然后跑一次无 `session_id` 的全局 `state_clear` 删除旧文件（`.omk/state/*.json`、兼容工件），并汇报结果。Swarm 仍是 session 作用域外的共享 SQLite / marker 模式。
5. Team 工件（`.omk/state/team/*/`、匹配 `omx-team-*` 的 tmux 会话）作为遗留 / 全局阶段的 best-effort 清理项。

状态工具始终尊重 `session_id` 参数，因此即便是 force 模式也仍先清理 session 作用域路径，再去删那些仅用于兼容的遗留状态。

下面 mode-specific 小节描述全局状态操作完成后每个处理器还要做哪些额外清理。
## 消息参考

| Mode | Success Message |
|------|-----------------|
| Autopilot | "Autopilot cancelled at phase: {phase}. Progress preserved for resume." |
| Ralph | "Ralph cancelled. Persistent mode deactivated." |
| Ultrawork | "Ultrawork cancelled. Parallel execution mode deactivated." |
| Ecomode | "Ecomode cancelled. Token-efficient execution mode deactivated." |
| UltraQA | "UltraQA cancelled. QA cycling workflow stopped." |
| Swarm | "Swarm cancelled. Coordinated agents stopped." |
| Ultrapilot | "Ultrapilot cancelled. Parallel autopilot workers stopped." |
| Pipeline | "Pipeline cancelled. Sequential agent chain stopped." |
| Team | "Team cancelled. Teammates shut down and cleaned up." |
| Plan Consensus | "Plan Consensus cancelled. Planning session ended." |
| Force | "All oh-my-kimi modes cleared. You are free to start fresh." |
| None | "No active oh-my-kimi modes detected." |

## 保留的内容

| Mode | State Preserved | Resume Command |
|------|-----------------|----------------|
| Autopilot | Yes (phase, files, spec, plan, verdicts) | `/autopilot` |
| Ralph | No | N/A |
| Ultrawork | No | N/A |
| UltraQA | No | N/A |
| Swarm | No | N/A |
| Ultrapilot | No | N/A |
| Pipeline | No | N/A |
| Plan Consensus | Yes (plan file path preserved) | N/A |

## 备注

- **依赖感知**：Autopilot 取消会清理 Ralph 与 UltraQA
- **链路感知**：Ralph 取消会清理 linked Ultrawork 或 Ecomode
- **安全**：仅清理 linked Ultrawork，保留独立 Ultrawork
- **仅本地**：清理 `.omk/state/` 目录下的状态文件
- **易于恢复**：Autopilot state 被保留，便于无缝恢复
- **Team 感知**：检测基于 tmux 的 team，并做带强制 kill 兜底的优雅关停

## Tmux Team 清理

取消 team 模式时，cancel skill 应：

1. **杀掉所有 team tmux 会话**：`tmux list-sessions -F '#{session_name}' 2>/dev/null | grep '^omx-team-'`，逐个 kill
2. **删除 team 状态目录**：`rm -rf .omk/state/team/*/`
3. **剥离 AGENTS.md overlay**：删除 `<!-- OMK:TEAM:WORKER:START -->` 与 `<!-- OMK:TEAM:WORKER:END -->` 之间的内容

### Force Clear 附加

使用 `--force` 时同时清理：
```bash
rm -rf .omk/state/team/                  # All team state
# Kill all omx-team-* tmux sessions
tmux list-sessions -F '#{session_name}' 2>/dev/null | grep '^omx-team-' | while read s; do tmux kill-session -t "$s" 2>/dev/null; done
```
