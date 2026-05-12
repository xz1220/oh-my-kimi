# OMC / OMX Divergence

Research date: 2026-05-12.

Working conclusion:

- The `oh-my-*` projects share a workflow lineage: planning, specialist roles,
  persistent execution, team delegation, review, and verification.
- Host capability explains much of the implementation difference. Claude Code
  and Kimi CLI have native subagent and hook primitives; Codex-oriented ports
  compensate with process orchestration.
- For Kimi CLI v0, the safest route is not to port tmux/HUD/runtime machinery.
  It is to ship Kimi-native YAML agents, portable skills, hook templates, and
  install scripts.

This is why v0 is intentionally configuration-heavy and runtime-light.
