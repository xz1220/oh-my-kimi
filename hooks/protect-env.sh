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

SECRET_RE = re.compile(
    r"(^|/)(\.env(\.[A-Za-z0-9_-]+)?|id_rsa|id_ed25519|credentials|credentials\.json|"
    r"service-account[A-Za-z0-9._-]*\.json|\.aws/credentials|\.config/gcloud)(\b|$)"
)

# Explicit allowlist — these suffixes mean the file is a *template*, not a
# real secret, and editing them is safe. Suppresses the false positives the
# loose .env regex would otherwise flag.
SAFE_SUFFIX_RE = re.compile(
    r"\.(example|template|tmpl|sample|dist)(\b|$)",
    re.IGNORECASE,
)


def is_secret(path: str) -> bool:
    if SAFE_SUFFIX_RE.search(path):
        return False
    return bool(SECRET_RE.search(path))


for value in paths:
    if is_secret(value):
        print(
            "oh-my-kimi blocked a possible secret edit. Use an example file or "
            "confirm the exact non-secret target. To bypass, edit "
            "~/.oh-my-kimi/hooks/protect-env.sh.",
            file=sys.stderr,
        )
        sys.exit(2)

sys.exit(0)
PY
