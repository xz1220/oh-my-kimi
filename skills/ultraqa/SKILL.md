---
name: ultraqa
description: QA 循环工作流 —— 测试、验证、修复、重复，直到达成目标
---

# UltraQA Skill

## 运行契约

- 用结果优先的表述，进度与完成报告做到简洁、证据密集。
- 把更新的用户指令视为当前工作流分支的本地覆盖，同时保留更早期、不冲突的约束。
- 用户说 `continue` 时，推进当前已验证的下一步，而不是重启发现流程。

[ULTRAQA ACTIVATED - AUTONOMOUS QA CYCLING]

## 概览

## 目标解析

从参数解析目标。支持的格式：

| 调用 | 目标类型 | 检查内容 |
|------------|-----------|---------------|
| `/ultraqa --tests` | tests | 所有测试套件通过 |
| `/ultraqa --build` | build | 构建以 exit 0 退出 |
| `/ultraqa --lint` | lint | 没有 lint 错误 |
| `/ultraqa --typecheck` | typecheck | 没有 TypeScript 错误 |
| `/ultraqa --custom "pattern"` | custom | 输出里包含自定义成功模式 |

如果没有提供结构化目标，把参数解释为自定义目标。

## 循环工作流

### Cycle N（最多 5）

1. **RUN QA**：基于目标类型执行验证
   - `--tests`：跑项目的测试命令
   - `--build`：跑项目的构建命令
   - `--lint`：跑项目的 lint 命令
   - `--typecheck`：跑项目的类型检查命令
   - `--custom`：跑合适的命令，并检查模式
   - `--interactive`：用 qa-tester 做交互式 CLI/服务测试：
     ```
     Use `/prompts:qa-tester` with:
     Goal: [描述要验证什么]
     Service: [如何启动]
     Test cases: [要验证的具体场景]
     ```

2. **CHECK RESULT**：目标通过了吗？
   - **YES** → 以成功消息退出
   - **NO** → 继续步骤 3

3. **ARCHITECT DIAGNOSIS**：派 architect 分析失败
   ```
   Use `/prompts:architect` with:
   Goal: [目标类型]
   Output: [test/build 输出]
   Provide root cause and specific fix recommendations.
   ```

4. **FIX ISSUES**：应用 architect 的建议
   ```
   Use `/prompts:executor` with:
   Issue: [architect diagnosis]
   Files: [受影响的文件]
   Apply the fix precisely as recommended.
   ```

5. **REPEAT**：回到步骤 1

## 退出条件

| 条件 | 行动 |
|-----------|--------|
| **Goal Met** | 成功退出：「ULTRAQA COMPLETE: Goal met after N cycles」 |
| **Cycle 5 Reached** | 带诊断退出：「ULTRAQA STOPPED: Max cycles. Diagnosis: ...」 |
| **Same Failure 3x** | 提前退出：「ULTRAQA STOPPED: Same failure detected 3 times. Root cause: ...」 |
| **Environment Error** | 退出：「ULTRAQA ERROR: [tmux/port/dependency issue]」 |

## 可观测性

每个循环输出进度：
```
[ULTRAQA Cycle 1/5] Running tests...
[ULTRAQA Cycle 1/5] FAILED - 3 tests failing
[ULTRAQA Cycle 1/5] Architect diagnosing...
[ULTRAQA Cycle 1/5] Fixing: auth.test.ts - missing mock
[ULTRAQA Cycle 2/5] Running tests...
[ULTRAQA Cycle 2/5] PASSED - All 47 tests pass
[ULTRAQA COMPLETE] Goal met after 2 cycles
```

## 状态跟踪

UltraQA 生命周期状态使用 CLI 优先的状态接口（`omk state ... --json`）。如果显式 MCP 兼容工具已可用，等价的 `omx_state` 调用属于可选兼容，不作为默认。

- **启动时**：
  `omk state write --input '{"mode":"ultraqa","active":true,"current_phase":"qa","iteration":1,"started_at":"<now>"}' --json`
- **每个循环**：
  `omk state write --input '{"mode":"ultraqa","current_phase":"qa","iteration":<cycle>}' --json`
- **diagnose/fix 状态切换时**：
  `omk state write --input '{"mode":"ultraqa","current_phase":"diagnose"}' --json`
  `omk state write --input '{"mode":"ultraqa","current_phase":"fix"}' --json`
- **完成时**：
  `omk state write --input '{"mode":"ultraqa","active":false,"current_phase":"complete","completed_at":"<now>"}' --json`
- **resume 检测**：
  `omk state read --input '{"mode":"ultraqa"}' --json`

## 场景示例

**Good：** 工作流已经有明确的下一步，用户说 `continue`。继续当前工作分支，而不是重启或重新询问同一个问题。

**Good：** 用户只改输出形态或下游交付步骤（例如 `make a PR`）。保留更早期、不冲突的工作流约束，并在本地应用更新。

**Bad：** 用户说 `continue`，工作流却重启发现流程，或在缺失的验证 / 证据被收集之前就停下。

## 取消

用户可以用 `/cancel` 取消，会清掉状态文件。

## 重要规则

1. **能并行就并行** —— 边诊断边准备可能的修复
2. **跟踪失败** —— 记录每次失败以识别规律
3. **遇到规律提前退出** —— 同一失败 3 次 = 停下并暴露问题
4. **清晰输出** —— 用户应始终能看到当前 cycle 与状态
5. **清理** —— 完成或取消时清掉状态文件

## 完成时的状态清理

达成目标 / 达到最大循环数 / 提前退出时，运行 `$cancel` 或调用：

`omk state clear --input '{"mode":"ultraqa"}' --json`

用 CLI 状态清理，而不是直接删文件。

---

现在开始 ULTRAQA 循环。解析目标，从 cycle 1 启动。
