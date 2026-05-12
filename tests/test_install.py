from __future__ import annotations

import os
import subprocess
from pathlib import Path

try:
    import tomllib
except ModuleNotFoundError:  # pragma: no cover
    import tomli as tomllib


ROOT = Path(__file__).resolve().parents[1]


# Mirrors what Kimi CLI ships in a fresh ~/.kimi/config.toml. The critical
# bit is `hooks = []` (inline empty array) — without the install-time strip,
# our `[[hooks]]` block would collide with TOML's "key already defined" rule.
KIMI_DEFAULT_CONFIG = """\
default_model = "kimi-code/kimi-for-coding"
default_thinking = true
default_yolo = false
default_plan_mode = false
default_editor = ""
theme = "dark"
show_thinking_stream = true
hooks = []
merge_all_available_skills = false

[loop_control]
max_steps_per_turn = 500
"""


def run(cmd: list[str], *, env: dict[str, str]) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        cmd,
        cwd=ROOT,
        env=env,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=True,
    )


def test_install_and_uninstall_are_idempotent(tmp_path: Path) -> None:
    home = tmp_path / "home"
    omk_home = tmp_path / "omk"
    kimi_dir = tmp_path / "kimi"
    bin_dir = tmp_path / "bin"
    home.mkdir()

    env = os.environ.copy()
    env.update(
        {
            "HOME": str(home),
            "OMK_HOME": str(omk_home),
            "KIMI_DIR": str(kimi_dir),
            "BIN_DIR": str(bin_dir),
        }
    )

    run(["bash", "scripts/install.sh", "--source", str(ROOT)], env=env)
    run(["bash", "scripts/install.sh", "--source", str(ROOT)], env=env)

    assert (omk_home / "agents" / "oh-my-kimi.yaml").exists()
    assert (bin_dir / "kimi-omk").exists()
    assert (kimi_dir / "skills" / "ralph").is_symlink()
    assert (kimi_dir / "skills" / "verify").is_symlink()

    config = kimi_dir / "config.toml"
    text = config.read_text(encoding="utf-8")
    assert text.count("# >>> oh-my-kimi >>>") == 1
    assert str(omk_home / "hooks" / "protect-env.sh") in text

    run(["bash", str(omk_home / "scripts" / "uninstall.sh")], env=env)
    assert not (kimi_dir / "skills" / "ralph").exists()
    assert not (bin_dir / "kimi-omk").exists()
    assert "# >>> oh-my-kimi >>>" not in config.read_text(encoding="utf-8")


def test_install_into_kimi_default_config_keeps_toml_parseable(tmp_path: Path) -> None:
    """Regression: Kimi's default config.toml contains `hooks = []` (inline empty
    array). Earlier versions of install.sh appended `[[hooks]]` array-of-tables
    blocks after that line, producing TOML that Kimi rejects with
    `Key "hooks" already exists`. This test fails if that regression returns.
    """
    home = tmp_path / "home"
    omk_home = tmp_path / "omk"
    kimi_dir = tmp_path / "kimi"
    bin_dir = tmp_path / "bin"
    home.mkdir()
    kimi_dir.mkdir()
    (kimi_dir / "config.toml").write_text(KIMI_DEFAULT_CONFIG, encoding="utf-8")

    env = os.environ.copy()
    env.update(
        {
            "HOME": str(home),
            "OMK_HOME": str(omk_home),
            "KIMI_DIR": str(kimi_dir),
            "BIN_DIR": str(bin_dir),
        }
    )

    run(["bash", "scripts/install.sh", "--source", str(ROOT)], env=env)

    config_text = (kimi_dir / "config.toml").read_text(encoding="utf-8")
    # The inline `hooks = []` line must have been stripped before our block
    # was appended; otherwise TOML parsing below would fail.
    assert "\nhooks = []\n" not in config_text, (
        "install.sh must strip the inline `hooks = []` line before appending "
        "[[hooks]] entries (otherwise Kimi CLI rejects the config)"
    )

    # Critical: the resulting config must parse as valid TOML.
    parsed = tomllib.loads(config_text)
    assert isinstance(parsed.get("hooks"), list), (
        "after install, `hooks` should be a list of dicts from [[hooks]] entries"
    )
    assert len(parsed["hooks"]) >= 3, "install should add multiple hook entries"
    events = {h["event"] for h in parsed["hooks"]}
    assert "PreToolUse" in events
    assert "Stop" in events
