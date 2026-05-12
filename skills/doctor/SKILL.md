---
name: doctor
description: Diagnose and fix an oh-my-kimi installation on Kimi CLI (skills, hooks, wrapper, MCP).
argument-hint: "[--fix] [--verbose]"
---

# Doctor

Run a structured health check against the local `oh-my-kimi` install and
surface concrete fix commands for every problem found. Use this when:

- A `/skill:<name>` invocation says "skill not found" but you believe it
  was installed.
- `kimi-omk` errors at launch.
- A hook does not fire (no `.env` block, no auto-format, etc.).
- `kimi info` reports `Invalid TOML in configuration file …`.
- You want to verify a fresh machine before running real work.

## Do not use when

- Diagnosing Kimi CLI itself (model errors, login, API key) — that lives
  with upstream Kimi CLI, not this skill.
- Diagnosing the host OS network / DNS / TLS — outside scope.
- Diagnosing skill **content** quality — use the relevant workflow skill
  (e.g. `/skill:critic`) instead.

## What this skill checks

The seven things `install.sh` actually does — in the same order — so a
failure points directly at which install step is broken or got rolled
back manually:

| # | Check | What it verifies |
|---|---|---|
| 1 | Kimi CLI on `PATH` | `kimi` binary exists; version ≥ 1.37 |
| 2 | `~/.oh-my-kimi/` layout | Repo snapshot was copied (agents/, skills/, hooks/, scripts/) |
| 3 | Skill symlinks in `~/.kimi/skills/` | Each shipped skill is symlinked to `~/.oh-my-kimi/skills/<name>` |
| 4 | `~/.local/bin/kimi-omk` wrapper | Exists, executable, points at `oh-my-kimi.yaml` |
| 5 | Managed hook block in `~/.kimi/config.toml` | Single `# >>> oh-my-kimi >>>` … `# <<< oh-my-kimi <<<` block; TOML parses cleanly |
| 6 | Hook scripts executable | Every `~/.oh-my-kimi/hooks/*.sh` is `+x` |
| 7 | (Optional) MCP servers | `kimi mcp list` shows the recommended servers if `--with-mcp` ran |

A passing run prints `✅` for each line; any failure prints `❌` plus the
one-line fix command.

## Procedure

Walk through the checks below in order. Stop and ask the user before
running any `--fix` action that mutates state outside `~/.oh-my-kimi/`
(specifically: editing `~/.kimi/config.toml`, removing user-owned
symlinks, re-running `install.sh`).

### Check 1 — Kimi CLI on PATH

```bash
command -v kimi >/dev/null 2>&1 \
  && kimi --version
```

Expected output: `kimi 1.37.0` or higher. Anything lower means missing
primitives (Agent tool, SubagentStart hook, MCP) that several shipped
skills depend on.

Fix: install or upgrade Kimi CLI per
`https://github.com/MoonshotAI/kimi-cli`. Do **not** alias or shim
`kimi` to a different binary — `kimi-omk` resolves the real `kimi` from
`PATH` at runtime.

### Check 2 — install dir layout

```bash
test -d ~/.oh-my-kimi \
  && test -f ~/.oh-my-kimi/agents/oh-my-kimi.yaml \
  && test -d ~/.oh-my-kimi/skills \
  && test -d ~/.oh-my-kimi/hooks \
  && test -x ~/.oh-my-kimi/scripts/install.sh \
  && echo "layout OK"
```

If any line fails: the user moved or partly deleted the install. Run
`bash ~/.oh-my-kimi/scripts/install.sh` from any checkout, **or**
re-clone:

```bash
git clone https://github.com/xz1220/oh-my-kimi.git ~/.oh-my-kimi
bash ~/.oh-my-kimi/scripts/install.sh
```

### Check 3 — skill symlinks

```bash
expected=$(ls -d ~/.oh-my-kimi/skills/*/ | wc -l)
actual=$(find ~/.kimi/skills -maxdepth 1 -type l \
  -lname '*.oh-my-kimi/skills/*' 2>/dev/null | wc -l)
echo "expected=$expected installed=$actual"
```

Expect `installed == expected`. Mismatch usually means:

- `install.sh` saw a pre-existing non-`oh-my-kimi` skill at the same
  name and skipped it (look for `[oh-my-kimi] warning: skipping
  existing non-oh-my-kimi skill: …` in the install log). Manually
  decide whether to keep yours or let `oh-my-kimi` take that slot.
- The user moved `~/.kimi/skills/` or deleted symlinks by hand.

Fix (idempotent — safe to rerun):

```bash
bash ~/.oh-my-kimi/scripts/install.sh
```

To force-replace conflicting skills:

```bash
OMK_FORCE=1 bash ~/.oh-my-kimi/scripts/install.sh
```

To inspect a single broken slot:

```bash
ls -l ~/.kimi/skills/<name>            # is it a symlink? where to?
readlink ~/.kimi/skills/<name>          # target path
```

### Check 4 — `kimi-omk` wrapper

```bash
test -x ~/.local/bin/kimi-omk \
  && grep -q "$HOME/.oh-my-kimi/agents/oh-my-kimi.yaml" \
       ~/.local/bin/kimi-omk \
  && echo "wrapper OK"
```

The wrapper is a 2-line bash script. If missing or it points elsewhere,
the user (or another tool) wrote over it.

Fix: rerun `install.sh`. The wrapper is overwritten safely.

Also confirm `~/.local/bin` is on `PATH`:

```bash
case ":$PATH:" in *":$HOME/.local/bin:"*) echo "PATH OK" ;;
  *) echo "add $HOME/.local/bin to PATH" ;;
esac
```

### Check 5 — managed hook block + TOML validity

This is the check that catches the install bug fixed in `a62af4b`:
Kimi ships a default `hooks = []` inline-array line, and appending
`[[hooks]]` array-of-tables blocks after it produces `Invalid TOML:
Key "hooks" already exists`.

```bash
config=~/.kimi/config.toml
block_count=$(grep -c '^# >>> oh-my-kimi >>>$' "$config" 2>/dev/null || echo 0)
echo "managed blocks: $block_count (expect 1)"
python3 - <<PY
import sys
try:
    import tomllib
except ModuleNotFoundError:
    import tomli as tomllib
text = open("$config","rb").read()
try:
    parsed = tomllib.loads(text.decode())
except Exception as e:
    print("TOML PARSE ERROR:", e); sys.exit(1)
hooks = parsed.get("hooks")
print("hooks keytype:", type(hooks).__name__)
print("hooks count:", len(hooks) if isinstance(hooks, list) else "n/a")
PY
```

Expected:

- `managed blocks: 1`
- `hooks keytype: list`
- `hooks count: ≥3` (auto-format, protect-env, notify-on-stop ± stop-guard)

Failure modes:

- `managed blocks: 0` — hooks were stripped or never installed. Run
  `bash ~/.oh-my-kimi/scripts/install.sh`.
- `managed blocks: 2+` — duplicate injection (rare; happens if someone
  edited the markers). Run `bash ~/.oh-my-kimi/scripts/uninstall.sh`
  then reinstall.
- `TOML PARSE ERROR: Key 'hooks' already exists` — the inline
  `hooks = []` line from Kimi's default config wasn't stripped. The
  install.sh from commit `a62af4b` or later fixes this automatically;
  upgrade the install:

  ```bash
  cd ~/.oh-my-kimi && git pull
  bash scripts/install.sh
  ```

  For a one-off manual fix without reinstall:

  ```bash
  sed -i.before-fix '/^hooks = \[\]$/d' ~/.kimi/config.toml
  ```

### Check 6 — hook scripts executable

```bash
for sh in ~/.oh-my-kimi/hooks/*.sh; do
  test -x "$sh" || echo "NOT EXECUTABLE: $sh"
done
```

If any line prints: the install tar lost the exec bit (rare). Fix:

```bash
chmod +x ~/.oh-my-kimi/hooks/*.sh
```

### Check 7 — (optional) MCP servers

Only run if the user installed with `--with-mcp` or expects MCP support.

```bash
kimi mcp list 2>/dev/null | grep -E 'context7|chrome-devtools|sequential-thinking'
```

Expected: three lines (one per server) if installed via
`mcp/add-recommended-all.sh`. Missing servers can be added one at a
time:

```bash
bash ~/.oh-my-kimi/mcp/add-context7.sh
bash ~/.oh-my-kimi/mcp/add-chrome-devtools.sh
bash ~/.oh-my-kimi/mcp/add-sequential-thinking.sh
```

## Cross-host visibility (informational)

Kimi CLI's default config (`merge_all_available_skills = true`) reads
skills from all of these roots:

```
~/.kimi/skills/        ← canonical (oh-my-kimi installs here)
~/.claude/skills/      ← also read by Kimi
~/.codex/skills/       ← also read by Kimi
~/.config/agents/skills/
~/.agents/skills/
```

This means oh-my-kimi installed at `~/.kimi/skills/` is automatically
visible inside Claude Code and Codex CLI sessions as well, with **no
extra setup** (provided their respective hosts also use the canonical
skill layout). If a skill shows up duplicated in `kimi /skill`, check
whether you have an old copy in `~/.claude/skills/<name>` or
`~/.codex/skills/<name>` that wasn't installed by oh-my-kimi.

## Reporting

End the run with a concise markdown report:

```
## oh-my-kimi doctor — <date>

| # | Check                          | Result |
|---|--------------------------------|--------|
| 1 | Kimi CLI on PATH               | ✅ kimi 1.37.0 |
| 2 | Install dir layout             | ✅ |
| 3 | Skill symlinks (36/36)         | ✅ |
| 4 | kimi-omk wrapper               | ✅ |
| 5 | Managed hook block + TOML      | ✅ 1 block, 4 hooks |
| 6 | Hook scripts +x                | ✅ |
| 7 | MCP servers                    | ⚠ context7 missing |

Fixes applied: <list>  ← only if --fix was passed
Suggested next steps: <list>
```

## Tool usage

- Use `Shell` for every check above; pipe output into the report.
- Prefer non-mutating diagnostics first; only run fixes after surfacing
  what you intend to mutate.
- Never rewrite `~/.kimi/config.toml` directly — always re-run
  `install.sh`, which preserves the user's own non-managed lines and
  takes a timestamped backup.

## Final checklist

- [ ] Every check has a ✅ or an explicit ❌ + fix command.
- [ ] Report explicitly lists any file that was mutated.
- [ ] If `--fix` was not passed, no files were written.
- [ ] Backup paths (`*.omk-backup-*`) are mentioned if the user wants to
      roll back any change.
