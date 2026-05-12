---
name: visual-verdict
description: 截图与参考图对比的结构化视觉 QA 判定
level: 2
---

<Purpose>
使用本 skill 把生成的 UI 截图与一张或多张参考图对比，返回严格的 JSON 判定，用来驱动下一轮编辑。
</Purpose>

<Use_When>
- 任务包含视觉保真度要求（布局、间距、排版、组件样式）
- 你有一张生成截图和至少一张参考图
- 在继续编辑前需要确定性的 pass/fail 指引
</Use_When>

<Inputs>
- `reference_images[]`（一张或多张参考图路径）
- `generated_screenshot`（当前输出图）
- 可选：`category_hint`（例如 `hackernews`、`sns-feed`、`dashboard`）
</Inputs>

<Output_Contract>
**只**返回 JSON，结构必须精确如下：

```json
{
  "score": 0,
  "verdict": "revise",
  "category_match": false,
  "differences": ["..."],
  "suggestions": ["..."],
  "reasoning": "short explanation"
}
```

规则：
- `score`：0-100 的整数
- `verdict`：简短状态（`pass`、`revise` 或 `fail`）
- `category_match`：当生成截图匹配预期的 UI 类型/风格时为 `true`
- `differences[]`：具体的视觉不匹配点（布局、间距、排版、配色、层级）
- `suggestions[]`：与差异挂钩的可执行下一步编辑
- `reasoning`：1-2 句话的总结

<Threshold_And_Loop>
- 通过阈值目标为 **90+**。
- 如果 `score < 90`，继续编辑，并在下一轮视觉评审前重新运行 `/oh-my-kimi:visual-verdict`。
- 在下一张截图越过阈值之前，**不要**把视觉任务当作已完成。
</Threshold_And_Loop>

<Debug_Visualization>
当不匹配难以诊断时：
1. `$visual-verdict` 仍是权威判定。
2. 用像素级 diff 工具（pixel diff / pixelmatch overlay）作为**次级调试辅助**，定位热点。
3. 把像素 diff 的热点转写成具体的 `differences[]` 与 `suggestions[]` 更新。
</Debug_Visualization>

<Example>
```json
{
  "score": 87,
  "verdict": "revise",
  "category_match": true,
  "differences": [
    "Top nav spacing is tighter than reference",
    "Primary button uses smaller font weight"
  ],
  "suggestions": [
    "Increase nav item horizontal padding by 4px",
    "Set primary button font-weight to 600"
  ],
  "reasoning": "Core layout matches, but style details still diverge."
}
```
</Example>

Task: {{ARGUMENTS}}
