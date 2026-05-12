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


def test_no_stale_host_runtime_references_in_skills() -> None:
    forbidden = [
        "oh-my-claudecode",
        ".omc",
        "CLAUDE_CONFIG_DIR",
        "claude-sisyphus",
        "TodoWrite",
    ]
    for path in sorted((ROOT / "skills").glob("*/SKILL.md")):
        text = path.read_text(encoding="utf-8")
        for token in forbidden:
            assert token not in text, f"{token} in {path}"
