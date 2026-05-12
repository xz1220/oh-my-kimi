---
name: visual-ralph
description: "Visual Ralph 编排：用 $ralph 加上内置的 visual verdict 与像素 diff 证据，从生成参考、静态参考或在线 URL 目标出发实现前端 UI，直到实现匹配，并沉淀出可复用的设计系统。"
---

# Visual Ralph Skill

当用户希望 Codex 通过 Visual Ralph 循环来构建或重做前端 UI 时使用本 skill：已批准的生成参考、静态参考，或来自在线 URL 的基线作为目标，Ralph 负责实现，Visual Verdict 用可测量的判定驱动迭代，而不是仅靠主观描述。

## 目的

从生成参考、静态参考或在线 URL 出发，构建可测量的前端交付循环：

`用户描述 / 在线 URL -> 已批准的视觉参考 -> $ralph 实现 -> Visual Ralph verdict + 像素 diff -> 可复用的设计系统`。

对于在线 URL 克隆请求，Visual Ralph 接管已迁移的 `$web-clone` 用例。**不要**把新的 URL 驱动的网站克隆工作路由到 `$web-clone`；把 URL、视口、保真度要求与交互说明都保留在 Visual Ralph 循环里。

这是一个**编排** skill。它组合已有的 skills，自身不应当引入运行时命令、依赖或应用级假设。

## 何时使用

- 用户描述了想要的 web/app UI，要的是**实现**，不只是设计建议。
- 用户提供了在线 URL，希望通过可测量的 Visual Verdict 迭代得到视觉实现或克隆。
- 生成一张栅格化的 mockup / 参考图能让目标更清楚。
- 任务需要带 pass/fail 阈值的像素级视觉迭代。
- 最终结果应当留下可复用的设计 token / 组件，而不仅仅是一次性的截图匹配。

## 何时不要用

- 用户只想要设计批评或一般前端建议；用 `$frontend-ui-ux` 或 designer 通道。
- 任务是没有 UI 参考目标的纯后端 / API 实现。
- 用户已经给了最终静态参考图，只需要对比/修复；直接交给 `$ralph` 并附 Visual Ralph verdict 指引。
- 请求的产物是确定性的 SVG / 矢量 / 代码原生资源，而不是栅格参考。

## 工作流

### 1. 落地目标仓库

在做任何技术栈相关选择之前，先检查本地证据：
- 包管理器与脚本，
- 前端框架与路由结构，
- 样式系统与设计 token 约定，
- 截图 / 测试工具链，
- 应当复用的已有组件。

不要在没有仓库证据支持的情况下硬编码 React、Vue、Tailwind、Playwright 或任何其他技术栈。

### 2. 建立视觉参考

对于在线 URL 请求，在 Visual Ralph 工件里捕获或记录 URL 派生的参考，并把视口、内容状态、交互约束保留下来。**不要**调用 `$web-clone`；该独立 skill 已硬弃用。

在线 URL 参考工件必须包含：
- 来源 URL 与权限/范围说明，
- 视口、路由/状态、任何种子/登录假设，
- 捕获的基线截图路径，或记录在案的截取命令/工具，
- 可见控件的交互对齐说明，
- 已知的排除项，例如后端 / API / 鉴权、个性化数据、多页爬取、第三方组件对齐。

对于生成式的 UI 概念，用 `$imagegen` 从用户的 UI 描述产出参考。

Prompt 要求：
- 分类为 `ui-mockup`，除非另一种 imagegen 分类明显更合适，
- 包含视口 / 长宽比与目标承载面，
- 指定布局、层次、排版方向、配色情绪与任何精确文本，
- 禁止 logo / 水印 / 未请求的品牌标记，
- 要求 imagegen 避免不可能存在的 UI 细节或不可读的文本。

在 oh-my-kimi CLI / runtime 下运行、且生成参考是某个活跃的 Ralph 风格循环的一部分时，在调用内置图像工具之前先排入一个 continuation checkpoint：

```bash
kimi-omk imagegen continuation <session-id> --artifact <slug-or-filename> --generated-dir "$CODEX_HOME/generated_images/<session>" --work-dir ".omk/artifacts/visual-ralph/<slug>"
```

这个 helper 会记录 `.omk/state/sessions/<session>/imagegen-pending.json`，并复用已有的 Stop-hook 后续队列。它的存在是因为内置图像生成可能必须立刻结束 assistant 的本轮回合；下一次 Stop checkpoint 应当恢复工件回收，把生成的图像拷贝进工作区，并跑必要的视觉 QA / verdict 门，而不是依赖手动 `$ralph` 再次提示。

对于绑定到项目的实现，把已批准的参考拷贝到工作区，例如 `.omk/artifacts/visual-ralph/<slug>/reference.png`。永远**不要**让实现参考只留在 `$CODEX_HOME/generated_images/...` 里。

### 3. 要求显式的用户批准

在参考生成或 URL 派生参考捕获完成后停下，并请用户批准一张参考图 / 状态，或请求定向的重新生成 / 捕获调整。

批准之前：
- 不要开始前端实现，
- 不要调用 `$ralph`，
- 不要把一张草稿图当作最终。

批准之后，被确认的图像或 URL 派生基线成为视觉真理来源。任何重大设计转向、替换参考或改变设计方向都需要用户显式请求。

### 4. 移交给 `$ralph` 实现

调用 `$ralph` 时附上：
- 已批准的参考图路径或 URL 派生的基线工件，
- 在线 URL 任务的源 URL、视口、内容状态与交互对齐说明，
- 用户描述，
- 检测到的仓库 / 前端上下文，
- 截图命令 / 视口的精确要求，
- 下面的完成清单。

批准后 Ralph 可以自主迭代。它应当编辑代码、跑应用、截图，并持续改进直到匹配已批准的参考，或出现真正的阻塞。

### 5. 每次下一笔编辑之前都用 Visual Ralph verdict

每一次视觉迭代：
1. 按记录的视口 / 状态截取当前生成的截图。
2. 跑 Visual Ralph verdict 步骤，对已批准的参考与生成截图做对比。需要时用 `vision` agent 做图像理解。
3. 把 JSON 判定作为权威。
4. 如果 `score < 90`，把 `differences[]` 与 `suggestions[]` 转成下一次编辑计划。
5. 下一笔编辑前再跑一次。

必需的 verdict 形状：`score`、`verdict`、`category_match`、`differences[]`、`suggestions[]`、`reasoning`。

### 6. 像素 diff 仅作为次级调试证据

当不匹配的诊断很难时，生成像素 diff 或 pixelmatch overlay 来定位热点。像素 diff **不**替代 Visual Ralph verdict；它只帮你把视觉热点翻译成具体编辑。

把最终 diff 证据与参考 / 截图工件一并记录，让结果可被审计。

### 7. 沉淀出可复用的设计系统

如果视觉匹配没有被编码成仓库原生的可复用工件，实现就不算完成。视项目情况，这可能意味着 CSS 变量、theme token、Tailwind 配置、组件 variant、Storybook story、设计文档，或已有的等价物。

至少捕获相关的：
- 配色，
- 间距系统，
- 排版尺度 / 字重，
- 圆角，
- 阴影 / elevation，
- 重要的组件 variant 与状态。

优先复用已有的 token / 组件模式。如果仓库已经有可扩展的设计系统层，不要再引入一个新的。

## 完成清单

下面全部为真之前不要宣告完成：
- 已批准的参考图或 URL 派生的参考工件保存在工作区。
- 截图复现命令、视口、路由、种子 / 状态与输出路径都已记录。
- Visual Ralph verdict 对已批准参考的最终分数 `>= 90`。
- 像素 diff 或 overlay 证据作为次级调试证据已记录。
- 设计系统 token / 组件是仓库原生、可复用的。
- 构建 / lint / 测试或仓库的等价验证通过。
- 参考批准后没有未经授权的重大设计转向。
- 残留的视觉差异（若有）显式记录，并附理由。

## 移交模板

```text
$ralph "Implement the approved frontend reference.
Reference: <workspace-reference-image-or-url-derived-artifact>
Source URL (if URL-derived): <url and permission/scope note>
Viewport/content state: <viewport, route/state, seed/login assumptions>
Interaction parity notes: <visible controls and known exclusions>
Route/surface: <route or component>
Screenshot command: <command and viewport>
Use the Visual Ralph verdict step before every next edit; pass threshold score >= 90.
Use pixel diff only as secondary debug evidence.
Extract reusable design tokens/components for colors, spacing, typography, radii, shadows, and key variants.
Run build/lint/test before completion.
Do not make major design pivots unless explicitly requested."
```

Task: {{ARGUMENTS}}
