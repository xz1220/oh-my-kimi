#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_dir="$(cd -- "$script_dir/.." && pwd)"
# shellcheck source=lib.sh
. "$script_dir/lib.sh"

OMK_HOME="${OMK_HOME:-$HOME/.oh-my-kimi}"
KIMI_DIR="${KIMI_DIR:-$HOME/.kimi}"
BIN_DIR="${BIN_DIR:-$HOME/.local/bin}"
INSTALL_HOOKS=1
INSTALL_MCP=0
SOURCE_DIR="${OMK_SOURCE_DIR:-$repo_dir}"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --no-hooks) INSTALL_HOOKS=0 ;;
    --with-mcp) INSTALL_MCP=1 ;;
    --source)
      shift
      [ "$#" -gt 0 ] || omk_die "--source requires a path"
      SOURCE_DIR="$1"
      ;;
    *) omk_die "unknown option: $1" ;;
  esac
  shift
done

SOURCE_DIR="$(omk_abs_dir "$SOURCE_DIR")"
mkdir -p "$KIMI_DIR/skills" "$BIN_DIR"

if [ "$SOURCE_DIR" != "$OMK_HOME" ]; then
  rm -rf "$OMK_HOME.tmp"
  mkdir -p "$OMK_HOME.tmp"
  (cd "$SOURCE_DIR" && tar \
    --exclude='.git' \
    --exclude='site' \
    --exclude='.pytest_cache' \
    --exclude='__pycache__' \
    --exclude='*.pyc' \
    --exclude='.venv' \
    --exclude='.upstream-refs' \
    -cf - .) | (cd "$OMK_HOME.tmp" && tar -xf -)
  rm -rf "$OMK_HOME"
  mv "$OMK_HOME.tmp" "$OMK_HOME"
fi

omk_log "installed files to $OMK_HOME"

for skill in "$OMK_HOME"/skills/*/SKILL.md; do
  [ -f "$skill" ] || continue
  name="$(basename "$(dirname "$skill")")"
  target="$KIMI_DIR/skills/$name"
  if [ -e "$target" ] || [ -L "$target" ]; then
    if [ "$(readlink "$target" 2>/dev/null || true)" = "$OMK_HOME/skills/$name" ]; then
      :
    elif [ "${OMK_FORCE:-0}" = "1" ]; then
      omk_warn "replacing existing skill $target because OMK_FORCE=1"
      rm -rf "$target"
    else
      omk_warn "skipping existing non-oh-my-kimi skill: $target"
      continue
    fi
  fi
  ln -sfn "$OMK_HOME/skills/$name" "$target"
done

cat >"$BIN_DIR/kimi-omk" <<EOF
#!/usr/bin/env bash
exec kimi --agent-file "$OMK_HOME/agents/oh-my-kimi.yaml" "\$@"
EOF
chmod +x "$BIN_DIR/kimi-omk"
omk_log "installed wrapper $BIN_DIR/kimi-omk"

if [ "$INSTALL_HOOKS" = "1" ]; then
  config="$KIMI_DIR/config.toml"
  mkdir -p "$(dirname "$config")"
  touch "$config"
  omk_backup_file "$config"
  omk_remove_managed_block "$config"
  # Kimi CLI ships a default `hooks = []` inline-array line that conflicts
  # with the `[[hooks]]` array-of-tables entries we are about to append.
  # Drop it before appending; the inline empty array is semantically
  # equivalent to "no hooks", which the appended entries will then provide.
  omk_strip_inline_hooks_array "$config"
  {
    printf '\n# >>> oh-my-kimi >>>\n'
    for snippet in "$OMK_HOME"/hooks/*.toml; do
      [ -f "$snippet" ] || continue
      sed "s|{{OMK_HOME}}|$OMK_HOME|g" "$snippet"
      printf '\n'
    done
    printf '# <<< oh-my-kimi <<<\n'
  } >>"$config"
  omk_log "updated hooks in $config"
else
  omk_log "skipped hooks"
fi

if [ "$INSTALL_MCP" = "1" ]; then
  "$OMK_HOME/mcp/add-recommended-all.sh" || omk_warn "some MCP setup commands failed"
else
  omk_log "skipped MCP setup; run mcp/add-recommended-all.sh when needed"
fi

if ! command -v kimi >/dev/null 2>&1; then
  omk_warn "kimi was not found in PATH; install Kimi CLI before using kimi-omk"
fi

omk_log "done"
