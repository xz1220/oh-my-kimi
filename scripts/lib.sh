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

# Strip a top-level `hooks = ...` inline array assignment from a Kimi config
# before we append `[[hooks]]` array-of-tables entries. TOML disallows mixing
# inline-array and array-of-tables forms for the same key, and Kimi CLI ships
# a default `hooks = []` line that triggers a "Key 'hooks' already exists"
# parser error otherwise. Safe because `hooks = []` means "no hooks" — the
# `[[hooks]]` entries we add below carry the real configuration.
omk_strip_inline_hooks_array() {
  local file="$1"
  [ -f "$file" ] || return 0
  python3 - "$file" <<'PY'
from pathlib import Path
import re
import sys

path = Path(sys.argv[1])
text = path.read_text(encoding="utf-8")

# Only strip when the line is at top level (no leading whitespace) and the
# RHS is an inline array (not a [[hooks]] table-array header). We match the
# common `hooks = []`, `hooks=[]`, and `hooks = [ ... ]` shapes.
pattern = re.compile(r"^[ \t]*hooks[ \t]*=[ \t]*\[[^\n\[]*\][ \t]*\n", re.MULTILINE)
new_text, n = pattern.subn("", text)
if n:
    path.write_text(new_text, encoding="utf-8")
    print(f"[oh-my-kimi] stripped {n} inline 'hooks = [...]' line(s) from {path}")
PY
}
