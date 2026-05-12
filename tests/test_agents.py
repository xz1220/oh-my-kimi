from __future__ import annotations

from pathlib import Path

import yaml


ROOT = Path(__file__).resolve().parents[1]
AGENTS = ROOT / "agents"


def load_yaml(path: Path) -> dict:
    data = yaml.safe_load(path.read_text(encoding="utf-8"))
    assert isinstance(data, dict), path
    return data


def test_agent_bundle_registers_all_subagents() -> None:
    bundle = load_yaml(AGENTS / "oh-my-kimi.yaml")
    agent = bundle["agent"]
    subagents = agent["subagents"]

    yaml_agents = {
        path.stem
        for path in AGENTS.glob("*.yaml")
        if path.name != "oh-my-kimi.yaml"
    }
    assert set(subagents) == yaml_agents

    for name, spec in subagents.items():
        path = AGENTS / spec["path"]
        assert path.exists(), name
        assert spec["description"].strip(), name


def test_agent_specs_have_existing_prompts_and_valid_tool_policy() -> None:
    for path in AGENTS.glob("*.yaml"):
        data = load_yaml(path)
        assert data["version"] == 1
        agent = data["agent"]
        assert agent["name"].strip()
        prompt_path = AGENTS / agent["system_prompt_path"]
        assert prompt_path.exists(), path
        assert prompt_path.read_text(encoding="utf-8").strip(), path

        if path.name == "oh-my-kimi.yaml":
            continue

        allowed = agent.get("allowed_tools")
        excluded = agent.get("exclude_tools")
        assert isinstance(allowed, list) and allowed, path
        assert isinstance(excluded, list), path
        assert "kimi_cli.tools.agent:Agent" in excluded, path


def test_agent_specs_load_with_kimi_cli_when_available() -> None:
    # Use importorskip so the skip is visible in pytest output rather than
    # silently green; CI installs kimi-cli so this should run there.
    import pytest

    agentspec = pytest.importorskip("kimi_cli.agentspec")
    load_agent_spec = agentspec.load_agent_spec

    spec = load_agent_spec(AGENTS / "oh-my-kimi.yaml")
    assert spec.name == "oh-my-kimi"
    assert len(spec.subagents) >= 10

    for subagent in spec.subagents.values():
        loaded = load_agent_spec(subagent.path)
        assert loaded.system_prompt_path.exists()
        # The top-level oh-my-kimi.yaml registers all subagents but doesn't
        # narrow tools itself, so allowed_tools may be None (inherits default).
        # Every actual subagent should narrow via allowed_tools, though.
        assert loaded.allowed_tools, f"{subagent.path} has no allowed_tools"
