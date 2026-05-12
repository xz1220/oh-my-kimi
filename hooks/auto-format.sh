#!/usr/bin/env bash
set -euo pipefail

payload="$(cat)"
file_path="$(
  python3 - "$payload" <<'PY'
import json
import sys
payload = json.loads(sys.argv[1] or "{}")
tool_input = payload.get("tool_input") or {}
print(tool_input.get("file_path") or tool_input.get("path") or "")
PY
)"

[ -n "$file_path" ] || exit 0
[ -f "$file_path" ] || exit 0

case "$file_path" in
  *.py)
    if command -v ruff >/dev/null 2>&1; then
      ruff format "$file_path" >/dev/null 2>&1 || true
    elif command -v black >/dev/null 2>&1; then
      black "$file_path" >/dev/null 2>&1 || true
    fi
    ;;
  *.js|*.jsx|*.ts|*.tsx|*.json|*.css|*.scss|*.md|*.yml|*.yaml)
    if command -v prettier >/dev/null 2>&1; then
      prettier --write "$file_path" >/dev/null 2>&1 || true
    fi
    ;;
  *.sh|*.bash)
    if command -v shfmt >/dev/null 2>&1; then
      shfmt -w "$file_path" >/dev/null 2>&1 || true
    fi
    ;;
esac

exit 0
