---
name: autoresearch
description: 有状态的单任务改进循环，含严格 evaluator 契约、markdown 决策日志，以及 max-runtime 停止行为
argument-hint: "[--mission-dir <path>] [--max-runtime <duration>] [--cron <spec>] [--resume <run-id>]"
level: 4
---

<Purpose>
Autoresearch 是一个有状态 skill，用于有边界、由 evaluator 驱动的迭代改进。它一次只持有一个 mission，对非通过结果持续迭代，把每次评估与决策当作持久工件记录下来，并且仅在显式触达 max-runtime 上限或其他显式终止条件时停下。
</Purpose>

<Use_When>
- 你已经从 `/deep-interview --autoresearch` 拿到了 mission 与 evaluator
- 你需要持久化的单任务改进 + 严格评估
- 你需要在 `.omk/autoresearch/` 下持久的实验日志
- 你需要一条受支持的路径，通过 Kimi CLI 原生 cron 做周期性重跑
</Use_When>

<Do_Not_Use_When>
- 你需要在运行时生成 evaluator —— 先用 `/deep-interview --autoresearch`
- 你需要同时编排多个 mission —— v1 禁止
- 你想要弃用的 `omk autoresearch` CLI 流程 —— 它不再是权威实现
</Do_Not_Use_When>

<Contract>
- v1 仅支持单 mission
- mission 设置 / evaluator 生成留在 `deep-interview --autoresearch`
- evaluator 输出必须是结构化 JSON，包含必填布尔字段 `pass` 与可选数值字段 `score`
- 评估未通过的迭代**不会**停止 run
- 停止条件显式且有边界，max-runtime 是主要的强停钩子
</Contract>

<Required_Artifacts>
权威的持久化存储位于 `.omk/autoresearch/<mission-slug>/` 与 / 或 `.omk/logs/autoresearch/<run-id>/` 下。

至少要有的工件：
- mission spec
- evaluator 脚本或命令引用
- 每次迭代的评估 JSON
- markdown 决策日志

推荐的权威结构：
```text
.omk/autoresearch/<mission-slug>/
  mission.md
  evaluator.json
  runs/<run-id>/
    evaluations/
      iteration-0001.json
      iteration-0002.json
    decision-log.md
```
当已有运行时工件可用时，优先复用，不要无谓重复。
</Required_Artifacts>

<Workflow>
1. 确认存在单一 mission 且 evaluator 设置已就绪。
2. 确保 `autoresearch` 的 mode/state 处于激活，并记录：
   - mission slug/dir
   - evaluator 引用
   - 迭代次数
   - 起始 / 更新时间戳
   - 显式的 max-runtime 或截止时刻
3. 每次迭代：
   - 跑且仅跑一轮实验 / 改动循环
   - 跑 evaluator
   - 持久化机器可读的评估 JSON
   - 追加一条人类可读的 markdown 决策日志
   - 即使评估不通过也继续
4. 在以下情况停止：
   - 触达 max-runtime 上限
   - 用户显式取消
   - 运行时记录了另一种显式终止条件
</Workflow>

<Cron_Integration>
Kimi CLI 原生 cron 是对周期性 mission 增强的受支持集成点。v1 中优先文档化 / 配置 cron 入口，而不是构建复杂的调度 UI。

使用 cron 时：
- 每个调度作业只对应一个 mission
- 保持同一份 mission / evaluator 契约
- 追加新的 run 工件，而不是覆盖此前的实验
</Cron_Integration>

<Execution_Policy>
- 不要把执行权交回给 `omk autoresearch`
- 不要构造多 mission 编排
- 当 `src/autoresearch/*` 的运行时 / schema helper 已经契合更严格的契约时，优先复用
- 让日志对人有用，不只是对机器有用
</Execution_Policy>
