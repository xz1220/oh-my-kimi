#!/usr/bin/env bash
set -euo pipefail

payload="$(cat)"
stop_active="$(
  python3 - "$payload" <<'PY'
import json
import sys
payload = json.loads(sys.argv[1] or "{}")
print("1" if payload.get("stop_hook_active") else "0")
PY
)"

[ "$stop_active" = "0" ] || exit 0

if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  changed="$(git status --short 2>/dev/null | wc -l | tr -d ' ')"
  if [ "${changed:-0}" -gt 0 ]; then
    printf '%s\n' "oh-my-kimi reminder: changed files exist; make sure fresh verification evidence is included before finalizing."
  fi
fi

exit 0
