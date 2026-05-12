---
name: pipeline
description: 可配置的 pipeline 编排器，用于串接阶段
---

# Pipeline Skill

`$pipeline` 是 oh-my-kimi 的可配置 pipeline 编排器。它通过统一的 `PipelineStage` 接口串接阶段，并支持状态持久化与 resume。

## 默认 Autopilot Pipeline

oh-my-kimi 权威 pipeline 串接：

```
RALPLAN (consensus planning) -> team-exec (Kimi CLI workers) -> ralph-verify (architect verification)
```

## 配置

每次运行可配置的 pipeline 参数：

| Parameter | Default | Description |
|-----------|---------|-------------|
| `maxRalphIterations` | 10 | Ralph 验证迭代上限 |
| `workerCount` | 2 | Kimi CLI team worker 数量 |
| `agentType` | `executor` | team worker 的 agent 类型 |

## Stage Interface

每个 stage 实现 `PipelineStage` 接口：

```typescript
interface PipelineStage {
  readonly name: string;
  run(ctx: StageContext): Promise<StageResult>;
  canSkip?(ctx: StageContext): boolean;
}
```

stage 接收一个含此前 stage 累积工件的 `StageContext`，并返回一个含 status、artifacts、duration 的 `StageResult`。

## 内置 stage

- **ralplan**：共识规划（planner + architect + critic）。仅当 `prd-*.md` 与 `test-spec-*.md` 规划工件都已存在时跳过，并将任何 `deep-interview-*.md` 规格路径带下去以便追溯。
- **team-exec**：通过 Kimi CLI worker 做团队执行。始终是 oh-my-kimi 的执行后端。
- **ralph-verify**：Ralph 验证循环，迭代次数可配置。

## 状态管理

Pipeline 状态通过 ModeState 持久化到 `.omk/state/pipeline-state.json`。HUD 会自动渲染 pipeline 阶段。支持从上一个未完成 stage 恢复。

- **启动时**：`omk state write --input '{"mode":"pipeline","active":true,"current_phase":"stage:ralplan"}' --json`
- **阶段切换时**：`omk state write --input '{"mode":"pipeline","current_phase":"stage:<name>"}' --json`
- **完成时**：`omk state write --input '{"mode":"pipeline","active":false,"current_phase":"complete"}' --json`

## API

```typescript
import {
  runPipeline,
  createAutopilotPipelineConfig,
  createRalplanStage,
  createTeamExecStage,
  createRalphVerifyStage,
} from './pipeline/index.js';

const config = createAutopilotPipelineConfig('build feature X', {
  stages: [
    createRalplanStage(),
    createTeamExecStage({ workerCount: 3, agentType: 'executor' }),
    createRalphVerifyStage({ maxIterations: 15 }),
  ],
});

const result = await runPipeline(config);
```

## 与其他模式的关系

- **autopilot**：autopilot 可以把 pipeline 作为执行引擎（v0.8+）
- **team**：pipeline 把执行委派给 team 模式（Kimi CLI workers）
- **ralph**：pipeline 把验证委派给 ralph（迭代数可配）
- **ralplan**：pipeline 的第一阶段跑 RALPLAN 共识规划
