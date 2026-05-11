# oh-my-kimi

把 [`oh-my-*`](https://github.com/Yeachan-Heo/oh-my-claudecode) 谱系 port 到 Moonshot Kimi CLI。复刻 oh-my-claudecode（OMC）/ oh-my-codex（OMX）的角色 catalog、skill catalog、工作流（`$deep-interview → $ralplan → $ralph → $team`）到国产 host。

Kimi CLI 的扩展面与 Claude Code 同构（13 个 hook 事件 + YAML subagent + SKILL.md），且原生读 `~/.claude/skills/`——同一份 skill 包**对 Kimi CLI 和 Claude Code 双 host 生效**。

**核心动作不是「设计」，是「down-port」**：spec 已被 3 个 host（opencode / claude / codex）验证过，我们的工程价值在 Kimi CLI 的适配层 + 中文优先 + 国内场景预集成。

详细需求看 [docs/prd.md](docs/prd.md)。
