# Attribution

`oh-my-kimi` is a downstream port of the `oh-my-*` agent harness lineage.

## Upstream Sources

| Source | License | Used for |
|---|---|---|
| [`Yeachan-Heo/oh-my-claudecode`](https://github.com/Yeachan-Heo/oh-my-claudecode) | MIT | Agent role catalog and workflow inspiration |
| [`Yeachan-Heo/oh-my-codex`](https://github.com/Yeachan-Heo/oh-my-codex) | MIT lineage, verify upstream file before vendoring code | Ralph/team workflow comparison |
| [`MoonshotAI/kimi-cli`](https://github.com/MoonshotAI/kimi-cli) | Apache-2.0 | Host runtime schema and docs |

## What Changed

- Claude Code agent markdown was split into Kimi YAML agent specs plus prompt
  markdown.
- Skills were rewritten into Kimi-native workflows without depending on the OMC
  runtime.
- Hook snippets target Kimi `config.toml`.
- Installer symlinks skills into `~/.kimi/skills` and provides `kimi-omk`.

See the repository `NOTICE` for the license notice.
