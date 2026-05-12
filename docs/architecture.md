# Architecture

> Locked design decisions for oh-my-kimi v0. Read this before contributing.

## Mental model in one line

**oh-my-kimi is a Kimi CLI plugin** that ships a curated catalog of skills, subagents, hooks, and MCP server recommendations — derived from the `oh-my-*` lineage (oh-my-claudecode, oh-my-codex). It does not call the LLM directly; it configures Kimi CLI to behave like a curated multi-agent harness.

## What Kimi CLI gives us natively

Kimi CLI 1.37+ ships with the exact primitives oh-my-claudecode (OMC) needed Claude Code's `Task` tool for, and oh-my-codex (OMX) had to fake with tmux + state files:

| Primitive | Kimi CLI | Why it matters |
|---|---|---|
| In-process subagent (`Agent` tool) | ✅ native (`kimi_cli.tools.agent:Agent`) | We can ship YAML subagents that the main agent delegates to via `Task`-style call |
| Subagent lifecycle hooks | ✅ `SubagentStart` / `SubagentStop` | Hook scripts can react when delegation starts/ends |
| Skill discovery | ✅ `~/.kimi/skills/` (canonical) + `~/.claude/skills/` + `~/.codex/skills/` (cross-brand) | Same skill file works in Kimi, Claude Code, Codex |
| Hook event surface | ✅ 13 events incl. `PreToolUse`, `PostToolUse`, `UserPromptSubmit`, `Stop`, `PreCompact` | Hook templates work without compatibility shims |
| Plugin system | ✅ `kimi plugin install <git-url>` | Native install path, no curl-bash needed for skills layer |
| MCP | ✅ HTTP / stdio / OAuth | Same schema as Claude Code |
| Ralph mode | ✅ built-in `--max-ralph-iterations` flag | We do **not** need to reimplement OMX's `$ralph` — Kimi already has it |

The takeaway: **most of OMX's 50k-line TS+Rust codebase exists to compensate for Codex CLI's missing primitives.** Kimi CLI has those primitives, so oh-my-kimi can be ~95% configuration.

## Schema mapping (OMC/OMX → Kimi)

### Skills (`SKILL.md`)

OMC and OMX both use the canonical `<dir>/<name>/SKILL.md` layout with YAML frontmatter. **Kimi expects the exact same layout.** No conversion needed for the file format itself — only content edits:

- `s/\.omc\//.kimi\//g` (and `.omx/` → `.kimi/`)
- `s/Claude Code/Kimi CLI/g`, `s/Codex CLI/Kimi CLI/g`
- Tool name references (`subagent_type="oh-my-claudecode:executor"` → `oh-my-kimi:executor`)

### Subagents (OMC `agents/*.md` / OMX `prompts/*.md` → Kimi `agents/<name>.yaml + <name>.md`)

OMC stores subagents as Markdown with frontmatter:
```markdown
---
name: executor
description: Focused task executor for implementation work (Sonnet)
model: sonnet
level: 2
---
<Agent_Prompt>...</Agent_Prompt>
```

Kimi expects a YAML spec file pointing to a separate prompt file:
```yaml
# agents/executor.yaml
version: 1
agent:
  extend: ./_base.yaml   # inherits tools from base
  name: executor
  system_prompt_path: ./executor.md
  when_to_use: |
    Use when you need a focused implementation specialist...
  model: kimi-k2  # optional
  allowed_tools: [...]   # narrower than base
  exclude_tools: [...]
```

```markdown
# agents/executor.md   (the system prompt body)
<Agent_Prompt>...</Agent_Prompt>
```

So conversion is mechanical: split each OMC agent .md into (a) a Kimi YAML spec and (b) the system-prompt .md, then re-reference path.

### Hooks (`hooks.toml` snippets appended to `~/.kimi/config.toml`)

```toml
[[hooks]]
event = "PreToolUse"
command = "/usr/bin/env oh-my-kimi-hook-protect-env"
matcher = "WriteFile|StrReplaceFile"
timeout = 30
```

Schema confirmed from `/tmp/kimi-cli/src/kimi_cli/hooks/config.py:24-34`: fields are `event`, `command`, `matcher` (regex), `timeout` (1-600s default 30).

### MCP recommendations

Use `kimi mcp add <name> <command>` invocations from our install script. No custom config schema needed — Kimi has native MCP CLI.

## Repository layout

```
oh-my-kimi/
├── README.md                    # marketing + quickstart
├── LICENSE                      # Apache-2.0
├── NOTICE                       # attribution to OMC/OMX (MIT)
├── plugin.json                  # makes this a valid Kimi plugin
│
├── skills/                      # auto-discovered when plugin installed
│   ├── deep-interview/
│   │   └── SKILL.md
│   ├── autopilot/
│   ├── code-review/
│   ├── debug/
│   ├── plan/
│   ├── deep-dive/
│   ├── tdd/
│   ├── visual-verdict/
│   ├── verify/
│   ├── team/
│   ├── setup/
│   ├── mcp-setup/
│   └── help/
│
├── agents/                      # subagents bundle
│   ├── oh-my-kimi.yaml          # top-level agent that registers all subagents
│   ├── _base.yaml               # base spec other agents extend
│   ├── _base.md                 # base system prompt
│   ├── executor.yaml + .md
│   ├── critic.yaml + .md
│   ├── architect.yaml + .md
│   ├── planner.yaml + .md
│   ├── debugger.yaml + .md
│   ├── code-reviewer.yaml + .md
│   ├── security-reviewer.yaml + .md
│   ├── test-engineer.yaml + .md
│   ├── document-specialist.yaml + .md
│   ├── analyst.yaml + .md
│   └── git-master.yaml + .md
│
├── hooks/                       # templates (user copies into ~/.kimi/config.toml)
│   ├── README.md
│   ├── auto-format.toml
│   ├── protect-env.toml
│   ├── notify-on-stop.toml
│   └── ralph-guard.toml
│
├── mcp/                         # recommended MCP server install scripts
│   ├── add-context7.sh
│   ├── add-chrome-devtools.sh
│   ├── add-sequential-thinking.sh
│   └── add-recommended-all.sh
│
├── scripts/
│   ├── install.sh               # full install (plugin + hooks + mcp + alias)
│   ├── uninstall.sh             # clean removal with backup restore
│   └── lib.sh                   # shared bash helpers (logging, backup)
│
├── tests/
│   ├── test_yaml_valid.py       # all agent YAMLs parse via kimi_cli.agentspec
│   ├── test_skills_valid.py     # all SKILL.md frontmatter parses
│   ├── test_hooks_valid.py      # all hooks.toml chunks parse via kimi_cli.hooks.config
│   ├── test_install.sh          # smoke test install + verify symlinks
│   └── test_discovery.py        # kimi_cli.skill.discover_skills() finds our skills
│
├── docs/
│   ├── architecture.md          # this file
│   ├── install.md               # full install guide
│   ├── skills.md                # catalog with descriptions
│   ├── attribution.md           # detailed list of what came from where
│   ├── prd.md                   # PRD v2 (already exists)
│   └── research/                # archived調研 reports
│       ├── omc-omx-divergence.md
│       ├── omx-internals.md
│       ├── kimi-cli-extension-surface.md
│       └── adoption-data.md
│
├── .github/
│   └── workflows/
│       └── validate.yml         # CI: run tests/ on push
│
└── mkdocs.yml                   # GitHub Pages config
```

## Install paths

Kimi CLI can install a plugin root, but plugin skill discovery treats an
installed plugin directory as one skill root. That means the repository-level
`SKILL.md` is visible through native plugin discovery, while the full catalog in
`skills/*/SKILL.md` must be linked into `~/.kimi/skills` for normal
`/skill:<name>` usage.

### Path A: Native plugin install (catalog entry only)

```bash
kimi plugin install https://github.com/xz1220/oh-my-kimi
```

- Pros: native and reversible with `kimi plugin remove oh-my-kimi`
- Cons: exposes the root catalog skill only; it does not install all
  `skills/*`, configure hooks, add MCP servers, or create the `kimi-omk` wrapper

### Path B: Full install (recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/xz1220/oh-my-kimi/main/scripts/install.sh | bash
```

What it does:
1. Copies the repo to `~/.oh-my-kimi`
2. Symlinks every `skills/<name>` directory into `~/.kimi/skills/<name>`
3. Backs up `~/.kimi/config.toml` to `~/.kimi/config.toml.omk-backup-<ts>`
4. Appends hooks from `hooks/*.toml` with managed-block markers for clean removal
5. Optionally adds recommended MCP servers via `kimi mcp add`
6. Drops a `~/.local/bin/kimi-omk` wrapper that runs `kimi --agent-file ~/.oh-my-kimi/agents/oh-my-kimi.yaml "$@"`

Uninstall: `scripts/uninstall.sh` reverses these steps.

## Design constraints

1. **No LLM calls in install scripts.** Pure shell + Kimi CLI subcommands.
2. **Idempotent.** Running install twice is safe; second run is a no-op for already-installed pieces.
3. **Reversible.** Every action has a corresponding undo in `uninstall.sh`. Hook injection uses delimited blocks (`# >>> oh-my-kimi >>>` / `# <<< oh-my-kimi <<<`) so removal is `sed -i '/# >>> oh-my-kimi >>>/,/# <<< oh-my-kimi <<</d'`.
4. **No required env vars.** Install works on a fresh machine after `pip install kimi-cli` (or equivalent). API key configuration is the user's responsibility (Kimi CLI handles via `kimi login` or `KIMI_API_KEY`).
5. **Runtime-light skills.** v0 keeps the upstream role inspiration, but rewrites
   the skill catalog into Kimi-native, portable workflows instead of depending
   on OMC runtime commands.
6. **Plugin metadata in `plugin.json`** so `kimi plugin info oh-my-kimi` returns useful information.

## What v0 does **not** do

- HUD / tmux status panel (OMX has it; we skip because Kimi CLI already has its own TUI)
- Custom slash command files (`.claude/commands/*.md` equivalent doesn't exist in Kimi; we expose workflows via skills, e.g. `/skill:ralph`)
- Self-hosted plugin marketplace
- Multi-language docs beyond `zh` + `en`
- Auto-update mechanism
- Claude Code adapter

## What v0+ might do

- HUD via tmux (gated on user request)
- More skills harvested from OMX (autoresearch, deepsearch, frontend-ui-ux)
- Translated Chinese skill descriptions (when usage data justifies the cost)
- `oh-my-kimi-cn` MCP bundle (飞书/钉钉/企业微信 servers)
- Self-update: `kimi-omk update` calls `kimi plugin install --upgrade`

## Lineage

This project ports the `oh-my-*` lineage to Moonshot Kimi CLI:

```
code-yeongyu/oh-my-opencode-lite  (2026-01-06, OpenCode harness)
   │
   ├─→ Yeachan-Heo/oh-my-claudecode  (2026-01-09, Claude Code)         [SOURCE: skills + agents]
   ├─→ Yeachan-Heo/oh-my-codex       (2026-02-02, OpenAI Codex CLI)    [SOURCE: skills + agents]
   └─→ Yeachan-Heo/oh-my-gemini      (2026-03-05, Google Gemini CLI)
   │
   └─→ xz1220/oh-my-kimi             (2026-05-12, Moonshot Kimi CLI)  ← THIS PROJECT
```

All upstream projects are MIT-licensed. We are Apache-2.0 (to align with Kimi CLI upstream) which is compatible with MIT for derivative works under the "explicit attribution + same-or-permissive license" rule. See `NOTICE` for line-by-line attribution.
