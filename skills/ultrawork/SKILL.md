---
name: ultrawork
description: 高吞吐量任务完成的并行执行引擎
---

<Purpose>
Ultrawork 是用于高吞吐量任务完成的并行执行引擎。它是一个**组件**，不是独立的持久化模式：它提供并行度、上下文纪律和智能委派指引，但不提供 Ralph 的持久化循环、architect 签字或长期完成保证。
</Purpose>

<Use_When>
- 多个独立任务可以同时跑
- 用户说「ulw」、「ultrawork」，或明确希望并行执行
- 任务能从并发执行 + 收尾前的轻量证据中受益
- 你需要一条直接工具执行通道，附带可选的后台证据通道，但不进入 Ralph
</Use_When>

<Do_Not_Use_When>
- 任务需要持久化、architect 验证、deslop / 重验证的完成保证 —— 改用 `ralph`（Ralph 包含 ultrawork）
- 任务需要完整的自主流水线 —— 改用 `autopilot`（autopilot 包含 Ralph，Ralph 又包含 ultrawork）
- 只有一个顺序任务，没有并行机会 —— 直接执行或委派给单个 `executor`
- 请求仍在 plan-consensus 阶段 —— 先把计划工件留在 `ralplan`，等明确授权再执行
- 用户需要会话级持久化以支持 resume —— 改用 `ralph`，它在 ultrawork 之上加了持久化
</Do_Not_Use_When>

<Why_This_Exists>
任务独立时，串行执行是浪费时间。Ultrawork 在保持执行分支高速的同时把协议收紧：先收集足够上下文，编辑前定义 pass/fail 验收标准，在本地执行与委派之间审慎选择，用证据而不是感觉收尾。
</Why_This_Exists>

<Execution_Policy>
- 实现前先收集足够上下文。先抓任务意图、目标产出、约束、可能涉及的代码点，以及任何可能改变执行路径的不确定性。
- 如果快速读完仓库后不确定性仍然重要，先做一次聚焦的证据采集，而不是立刻动手编辑。
- 启动执行通道前先定义 pass/fail 验收标准。包括能证明成功的命令、产物或人工检查。
- 任务小、强耦合或被即时本地上下文阻塞时，优先用直接工具完成。只有当工作足够独立、并行能带来收益时再委派。
- 必要时让一条直接工具通道与一条或多条后台证据通道并行。证据通道可以覆盖文档、测试、回归映射或受限的仓库分析。
- 独立的 agent 调用同时发出 —— 永远不要把独立工作串行化。
- 委派时**始终**显式传 `model` 参数。
- 首次委派前先读 `docs/shared/agent-tiers.md`，了解 agent 选型指引。
- 当官方文档、版本敏感的框架指引、最佳实践或外部依赖行为会显著影响任务正确性时，自动委派 `researcher`；把它当作证据通道，不当作主工作流的替代品。
- 对 ~30 秒以上的操作（安装、构建、测试）使用 `run_in_background: true`。
- 快速命令（git status、文件读取、简单检查）放前台跑。
- 应用共享的工作流指引模式：结果优先表述、对推测/被阻塞通道给出简洁可见的更新、把新指令当作当前工作流分支的本地覆盖、证据支撑的验证、显式的停止规则、对清晰且安全的执行分支选择继续而不是重启或重问。
- 用户说 `continue` 时，沿当前工作流分支继续，而不是重启发现流程或重问已定的问题。
</Execution_Policy>

<Steps>
1. **读 agent 参考**：加载 `docs/shared/agent-tiers.md`，做分层选型。
2. **上下文 + 确定性检查**：
   - 用一句话陈述任务意图。
   - 列出可能让「快速修」失效的约束与未知。
   - 信心不足时先探索，把任务收窄再编辑。
3. **执行前定义验收标准**：
   - 结束时必须为真的是什么？
   - 哪个命令或产物能证明？
   - 是否需要人工 QA 检查，若需要是什么？
4. **按依赖形态分类工作**：
   - 独立任务 -> 并行通道。
   - 共享文件或前置依赖密集的任务 -> 本地执行或分阶段通道。
5. **审慎地在自己做与委派之间选择**：
   - 下一步依赖即时仓库上下文、共享文件或紧密迭代时，本地执行。
   - 任务切片有边界、独立、能显著提升吞吐时，委派。
6. **跑执行通道**：
   - 直接工具通道：用于即时的实现或验证工作。
   - 后台证据通道：用于测试、文档、仓库分析或回归检查。
7. **顺序跑相互依赖的任务**：等前置完成再启动依赖任务。
8. **以轻量证据收尾**：
   - 相关时 build/typecheck 通过。
   - 受影响的测试通过。
   - 任务需要人类可见或行为级检查时，记录人工 QA 备注。
   - 没有引入新错误。
</Steps>

<Tool_Usage>
- 简单查找与有界证据采集用 LOW 层委派。
- 标准实现与回归工作用 STANDARD 层委派。
- 复杂分析、架构评审或高风险多文件改动用 THOROUGH 层委派。
- 当即时下一步被本地上下文阻塞时，优先用直接工具通道。
- 当能与实现并行学到有用东西时，优先用后台证据通道。
- 包安装、构建、测试套件用 `run_in_background: true`。
- 快速状态检查与文件操作放前台。
</Tool_Usage>

## 状态管理

UltraQA 生命周期状态使用 CLI 优先的状态接口（`omk state ... --json`）。如果显式 MCP 兼容工具已可用，等价的 `omx_state` 调用属于可选兼容，不作为默认。

- **启动时**：
  `omk state write --input '{"mode":"ultrawork","active":true,"reinforcement_count":1,"started_at":"<now>"}' --json`
- **每次强化/循环步骤**：
  `omk state write --input '{"mode":"ultrawork","reinforcement_count":<current>}' --json`
- **完成时**：
  `omk state write --input '{"mode":"ultrawork","active":false}' --json`
- **取消 / 清理时**：
  运行 `$cancel`（它应当调用 `omk state clear --input '{"mode":"ultrawork"}' --json`）

<Examples>
<Good>
先给出验收标准的双通道执行：
```
Acceptance criteria:
- `npm run build` passes
- `node --test dist/scripts/__tests__/codex-native-hook.test.js` passes
- Manual QA: verify `$ultrawork` activation message still points to the session state file

Direct-tool lane:
- update `skills/ultrawork/SKILL.md`

Background evidence lane:
- use /prompts:test-engineer for this scoped task
```
为什么好：上下文先落地，验收标准显式，直接工具通道与有界的证据通道并行。
</Good>

<Good>
自做与委派判断正确：
```
Shared-file edit in progress across `src/scripts/codex-native-hook.ts` and its test -> keep implementation local.
Independent regression mapping for keyword-detector coverage -> delegate to a test-engineer lane.
```
为什么好：共享文件工作留在本地；独立的证据工作扇出。
</Good>

<Bad>
任务还没落地就并行：
```
use /prompts:executor for this scoped task
use /prompts:test-engineer for this scoped task
```
为什么不好：没有上下文快照，没有 pass/fail 目标，工作形态还没定就开始委派。
</Bad>

<Bad>
没有证据或人工 QA 就声称成功：
```
Made the changes. Ultrawork should be updated now.
```
为什么不好：没有验证输出，没有验收证据；行为对用户可见时也没有人工 QA 备注。
</Bad>
</Examples>

<Escalation_And_Stop_Conditions>
- 直接调用 ultrawork（不经过 Ralph）时，只做轻量验证 —— 相关时 build/typecheck 通过，受影响的测试通过，需要时记录人工 QA 备注。
- 持久化、architect 验证、deslop 与完整的「已验证完成」承诺由 Ralph 负责。不要在仅用 ultrawork 时声称这些保证。
- 跨多次重试仍然失败时，报告问题，而不是无限重试。
- 当任务有不明依赖、冲突要求或验收目标出现明显分叉时，向用户升级。
</Escalation_And_Stop_Conditions>

<Final_Checklist>
- [ ] 编辑前完成了任务意图与约束的落地
- [ ] 执行前给出了 pass/fail 验收标准
- [ ] 并行通道只用于独立工作
- [ ] 相关时 build/typecheck 通过
- [ ] 受影响的测试通过
- [ ] 行为对用户可见时记录了人工 QA 备注
- [ ] 没有引入新错误
- [ ] 完成声明保持在 ultrawork 的轻量验证边界内
</Final_Checklist>

<Advanced>
## 与其他模式的关系

```
ralph（持久化 + 已验证完成的包装层）
 \-- 包含：ultrawork（本 skill）
     \-- 提供：高吞吐执行 + 轻量证据

autopilot（自主执行）
 \-- 包含：ralph
     \-- 包含：ultrawork（本 skill）

ecomode（token 效率）
 \-- 修改：ultrawork 的模型选型
```

Ultrawork 是并行度与执行纪律层。Ralph 加上持久化、architect 验证、deslop 和「重试到完成」的行为。Autopilot 再加上更宽的自主生命周期流水线。Ecomode 调整 ultrawork 的模型路由，倾向更便宜的模型。
</Advanced>
