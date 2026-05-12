#!/usr/bin/env bash
set -euo pipefail

payload="$(cat)"

python3 - "$payload" <<'PY'
import json
import re
import sys

payload = json.loads(sys.argv[1] or "{}")
tool = payload.get("tool_name", "")
tool_input = payload.get("tool_input") or {}

paths = []
for key in ("file_path", "path", "target_file"):
    value = tool_input.get(key)
    if isinstance(value, str):
        paths.append(value)

command = tool_input.get("command")
if tool == "Shell" and isinstance(command, str):
    paths.append(command)

pattern = re.compile(
    r"(^|/)(\.env(\..*)?|id_rsa|id_ed25519|credentials|credentials\.json|"
    r"service-account.*\.json|\.aws/credentials|\.config/gcloud)(\b|$)"
)

for value in paths:
    if pattern.search(value):
        print(
            "oh-my-kimi blocked a possible secret edit. Use an example file or "
            "confirm the exact non-secret target.",
            file=sys.stderr,
        )
        sys.exit(2)

sys.exit(0)
PY
