#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

"$script_dir/add-context7.sh" || true
"$script_dir/add-chrome-devtools.sh" || true
"$script_dir/add-sequential-thinking.sh" || true
