#!/usr/bin/env bash
set -euo pipefail

python3 -m pytest

bash -n scripts/*.sh
bash -n hooks/*.sh
bash -n mcp/*.sh

if command -v kimi >/dev/null 2>&1; then
  kimi --version
fi
