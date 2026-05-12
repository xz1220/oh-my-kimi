from __future__ import annotations

from pathlib import Path

try:
    import tomllib
except ModuleNotFoundError:  # pragma: no cover
    import tomli as tomllib


ROOT = Path(__file__).resolve().parents[1]
HOOKS = ROOT / "hooks"

EVENTS = {
    "PreToolUse",
    "PostToolUse",
    "PostToolUseFailure",
    "UserPromptSubmit",
    "Stop",
    "StopFailure",
    "SessionStart",
    "SessionEnd",
    "SubagentStart",
    "SubagentStop",
    "PreCompact",
    "PostCompact",
    "Notification",
}


def test_hook_toml_snippets_are_valid() -> None:
    for path in HOOKS.glob("*.toml"):
        text = path.read_text(encoding="utf-8").replace("{{OMK_HOME}}", "/tmp/oh-my-kimi")
        data = tomllib.loads(text)
        hooks = data.get("hooks")
        assert isinstance(hooks, list) and hooks, path
        for hook in hooks:
            assert hook["event"] in EVENTS
            assert isinstance(hook["command"], str) and hook["command"].strip()
            assert 1 <= int(hook.get("timeout", 30)) <= 600


def test_hook_scripts_have_matching_snippets() -> None:
    snippets = {p.stem for p in HOOKS.glob("*.toml")}
    scripts = {p.stem for p in HOOKS.glob("*.sh")}
    assert snippets == scripts
