from __future__ import annotations

import os
import subprocess
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


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
