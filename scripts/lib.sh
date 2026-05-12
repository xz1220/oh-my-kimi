#!/usr/bin/env bash
set -euo pipefail

omk_log() {
  printf '[oh-my-kimi] %s\n' "$*"
}

omk_warn() {
  printf '[oh-my-kimi] warning: %s\n' "$*" >&2
}

omk_die() {
  printf '[oh-my-kimi] error: %s\n' "$*" >&2
  exit 1
}

omk_abs_dir() {
  cd -- "$1" && pwd
}

omk_backup_file() {
  local file="$1"
  if [ -f "$file" ]; then
    local backup="${file}.omk-backup-$(date +%Y%m%d%H%M%S)"
    cp "$file" "$backup"
    omk_log "backed up $file to $backup"
  fi
}

omk_remove_managed_block() {
  local file="$1"
  [ -f "$file" ] || return 0
  python3 - "$file" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
text = path.read_text(encoding="utf-8")
start = "# >>> oh-my-kimi >>>"
end = "# <<< oh-my-kimi <<<"
while start in text and end in text:
    before, rest = text.split(start, 1)
    _block, after = rest.split(end, 1)
    text = before.rstrip() + "\n" + after.lstrip("\n")
path.write_text(text.rstrip() + "\n", encoding="utf-8")
PY
}
