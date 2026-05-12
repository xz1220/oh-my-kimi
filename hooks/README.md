# Hooks

These are Kimi CLI `config.toml` snippets and small shell hooks used by the
full oh-my-kimi installer.

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
