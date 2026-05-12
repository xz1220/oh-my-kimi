#!/usr/bin/env bash
set -euo pipefail

omk_log() {
  printf '[oh-my-kimi] %s\n' "$*"
}

omk_warn() {
  printf '[oh-my-kimi] 警告: %s\n' "$*" >&2
}

omk_die() {
  printf '[oh-my-kimi] 错误: %s\n' "$*" >&2
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
    omk_log "已将 $file 备份到 $backup"
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

# 在追加 `[[hooks]]` array-of-tables 条目之前，先从 Kimi 配置里剥掉顶层的
# `hooks = ...` 内联数组赋值。TOML 不允许同一个 key 同时用 inline-array 和
# array-of-tables 两种写法，而 Kimi CLI 默认会带一行 `hooks = []`，否则解析
# 时会报 "Key 'hooks' already exists"。这样做是安全的：`hooks = []` 含义是
# 「没有 hook」——下面我们追加的 `[[hooks]]` 条目才承载真正的配置。
omk_strip_inline_hooks_array() {
  local file="$1"
  [ -f "$file" ] || return 0
  python3 - "$file" <<'PY'
from pathlib import Path
import re
import sys

path = Path(sys.argv[1])
text = path.read_text(encoding="utf-8")

# 仅当该行位于顶层（无前导空白）且右侧是 inline array（不是 [[hooks]]
# table-array header）时才剥除。匹配常见的 `hooks = []`、`hooks=[]`、
# `hooks = [ ... ]` 几种写法。
pattern = re.compile(r"^[ \t]*hooks[ \t]*=[ \t]*\[[^\n\[]*\][ \t]*\n", re.MULTILINE)
new_text, n = pattern.subn("", text)
if n:
    path.write_text(new_text, encoding="utf-8")
    print(f"[oh-my-kimi] 已从 {path} 剥除 {n} 行 inline 'hooks = [...]'")
PY
}
