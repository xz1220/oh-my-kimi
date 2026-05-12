#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
. "$script_dir/lib.sh"

OMK_HOME="${OMK_HOME:-$HOME/.oh-my-kimi}"
KIMI_DIR="${KIMI_DIR:-$HOME/.kimi}"
BIN_DIR="${BIN_DIR:-$HOME/.local/bin}"
REMOVE_FILES=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --remove-files) REMOVE_FILES=1 ;;
    *) omk_die "unknown option: $1" ;;
  esac
  shift
done

if [ -d "$KIMI_DIR/skills" ]; then
  for item in "$KIMI_DIR"/skills/*; do
    [ -e "$item" ] || [ -L "$item" ] || continue
    link="$(readlink "$item" 2>/dev/null || true)"
    case "$link" in
      "$OMK_HOME"/skills/*)
        rm -f "$item"
        omk_log "removed skill link $item"
        ;;
    esac
  done
fi

config="$KIMI_DIR/config.toml"
if [ -f "$config" ]; then
  omk_backup_file "$config"
  omk_remove_managed_block "$config"
  omk_log "removed managed hooks from $config"
fi

if [ -f "$BIN_DIR/kimi-omk" ] && grep -q "$OMK_HOME/agents/oh-my-kimi.yaml" "$BIN_DIR/kimi-omk"; then
  rm -f "$BIN_DIR/kimi-omk"
  omk_log "removed $BIN_DIR/kimi-omk"
fi

if [ "$REMOVE_FILES" = "1" ] && [ -d "$OMK_HOME" ]; then
  rm -rf "$OMK_HOME"
  omk_log "removed $OMK_HOME"
fi

omk_log "done"
