# Hooks

These are Kimi CLI `config.toml` snippets and small shell hooks used by the
full oh-my-kimi installer.

| Hook | Event | What it does |
|---|---|---|
| `auto-format.{toml,sh}` | `PostToolUse` | Best-effort run `prettier` / `gofmt` / `black` / `cargo fmt` on the file that was just written or edited. Fail-open. |
| `protect-env.{toml,sh}` | `PreToolUse` | Blocks (exit 2) `WriteFile` / `StrReplaceFile` on a path whose basename matches a `.env`-like secret file. Allows `.example` / `.template` / `.dist` / `.sample` variants. |
| `notify-on-stop.{toml,sh}` | `Stop` | Desktop notification when a long turn ends. Uses `notify-send` / `terminal-notifier` if available, otherwise no-ops. |
| `stop-guard.{toml,sh}` | `Stop` | Reminds the agent to include fresh verification evidence when `git status --short` is non-empty. Pairs well with Kimi's `--max-ralph-iterations`, but does not integrate with it. |

The installer appends a managed block to `~/.kimi/config.toml`:

```bash
bash scripts/install.sh
```

Manual install:

1. Copy the wanted `*.toml` snippets into `~/.kimi/config.toml`.
2. Replace `{{OMK_HOME}}` with the checkout path, usually `~/.oh-my-kimi`.
3. Make the matching `*.sh` files executable.

All hooks are fail-open unless they intentionally return exit code `2` or a
Kimi hook JSON denial object.
