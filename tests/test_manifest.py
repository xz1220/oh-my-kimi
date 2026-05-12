from __future__ import annotations

import json
import re
from pathlib import Path

import yaml


ROOT = Path(__file__).resolve().parents[1]


def frontmatter(path: Path) -> dict:
    text = path.read_text(encoding="utf-8")
    assert text.startswith("---\n"), path
    _, raw, _body = text.split("---", 2)
    data = yaml.safe_load(raw) or {}
    assert isinstance(data, dict), path
    return data


def test_plugin_json_is_valid() -> None:
    data = json.loads((ROOT / "plugin.json").read_text(encoding="utf-8"))
    assert data["name"] == "oh-my-kimi"
    assert re.match(r"^\d+\.\d+\.\d+$", data["version"])
    assert data["description"]
    assert data.get("tools") == []


def test_all_skills_have_valid_frontmatter() -> None:
    names = set()
    for path in sorted((ROOT / "skills").glob("*/SKILL.md")):
        data = frontmatter(path)
        name = data["name"]
        assert re.match(r"^[a-z0-9][a-z0-9-]{0,63}$", name), path
        assert data["description"].strip(), path
        assert name == path.parent.name, path
        assert name not in names
        names.add(name)

    assert {"ralph", "ralplan", "team", "verify", "code-review"} <= names


# Tokens that should never leak from upstream OMC/OMX into oh-my-kimi.
# Any commit that reintroduces one of these is almost certainly a sed-replace
# regression or an unrewritten reference to a Claude-Code/Codex-CLI primitive.
FORBIDDEN_TOKENS = [
    "oh-my-claudecode",
    "oh-my-codex",
    ".omc/",
    ".omx/",
    "CLAUDE_CONFIG_DIR",
    "claude-sisyphus",
    "TodoWrite",                  # Claude Code's tool name; Kimi uses SetTodoList
    "wrapWithPreamble",            # OMC TypeScript implementation detail
    "src/agents/preamble.ts",      # same
    "StrReplaceFileorial",         # sed regression on the word "Editorial"
    "(Opus)",                       # Anthropic-only model tag
    "(Sonnet)",
    "(Haiku)",
    "haiku tier",
    "sonnet tier",
    "subagent_type=\"oh-my-claudecode",
    # New tokens added when bulk-porting upstream SKILL.md content (2026-05-12)
    "Claude built-in team",        # Claude Code's TeamCreate/TaskCreate stack — Kimi has Agent tool
    "Claude teammate",             # same orchestration model — Kimi has subagents
    "Claude Task agent",            # Claude's Task tool — Kimi has Agent
    "claude_worker",                # Claude provider routing name
    "Claude Sonnet executor",       # model-tier-tagged executor
    "omx ask ",                     # OMX shell wrapper — Kimi calls advisor CLI directly
    "OMX:TEAM:WORKER",              # AGENTS.md overlay markers — renamed to OMK:TEAM:WORKER
    # Tool-name regressions found in agent audit (2026-05-12)
    "Kimi Task agent",              # sed regression: Claude Task -> Kimi Task; should be 'Kimi subagent'
    "Yeachan-Heo/oh-my-kimi",       # wrong org: was Yeachan-Heo/oh-my-codex pre-sed; we live at xz1220/
]


def _sweep_for_forbidden(target_glob: str, *, files_glob: bool = False) -> None:
    base = ROOT / target_glob if not files_glob else ROOT
    if files_glob:
        paths = sorted(base.glob(target_glob))
    else:
        paths = sorted(base.rglob("*"))
    for path in paths:
        if not path.is_file():
            continue
        if path.suffix not in {".md", ".yaml", ".yml", ".toml", ".sh", ".py"}:
            continue
        text = path.read_text(encoding="utf-8")
        for token in FORBIDDEN_TOKENS:
            assert token not in text, f"{token} in {path}"


def test_no_stale_host_runtime_references_in_skills() -> None:
    _sweep_for_forbidden("skills")


def test_no_stale_host_runtime_references_in_agents() -> None:
    _sweep_for_forbidden("agents")


def test_no_stale_host_runtime_references_in_hooks() -> None:
    _sweep_for_forbidden("hooks")
