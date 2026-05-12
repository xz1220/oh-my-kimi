# Hooks

Hooks are optional. The default installer appends a managed block to
`~/.kimi/config.toml`.

| Hook | Event | Purpose |
|---|---|---|
| `protect-env` | `PreToolUse` | Block likely secret file edits |
| `auto-format` | `PostToolUse` | Best-effort formatting after writes |
| `notify-on-stop` | `Stop` | Desktop notification |
| `ralph-guard` | `Stop` | Reminder when changed files remain |

Skip hooks:

```bash
bash scripts/install.sh --no-hooks
```

Remove hook block:

```bash
bash scripts/uninstall.sh
```

Hook snippets live in `hooks/*.toml`; scripts live in `hooks/*.sh`.
