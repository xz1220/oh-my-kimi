# Install

## Requirements

- Kimi CLI 1.37 or newer.
- Bash, Python 3, and a Unix-like shell for the installer.
- Optional: `npx` for MCP helpers that use Node packages.

## Full Install

```bash
git clone https://github.com/xz1220/oh-my-kimi.git ~/.oh-my-kimi
bash ~/.oh-my-kimi/scripts/install.sh
```

The installer:

1. Copies the repo to `~/.oh-my-kimi`.
2. Symlinks `skills/*` into `~/.kimi/skills`.
3. Installs `~/.local/bin/kimi-omk`.
4. Appends a managed hook block to `~/.kimi/config.toml`.

Start with:

```bash
kimi-omk
```

## Options

```bash
bash scripts/install.sh --no-hooks
bash scripts/install.sh --with-mcp
OMK_FORCE=1 bash scripts/install.sh
```

`OMK_FORCE=1` replaces existing skill paths with the same name. Without it, the
installer skips non-oh-my-kimi skill directories.

## Uninstall

```bash
bash ~/.oh-my-kimi/scripts/uninstall.sh
```

Remove installed files too:

```bash
bash ~/.oh-my-kimi/scripts/uninstall.sh --remove-files
```

## Verify

```bash
kimi-omk --version
ls ~/.kimi/skills/ralph/SKILL.md
grep -n "oh-my-kimi" ~/.kimi/config.toml
```
