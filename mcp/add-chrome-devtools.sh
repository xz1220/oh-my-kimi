#!/usr/bin/env bash
set -euo pipefail

kimi mcp add --transport stdio chrome-devtools -- npx -y chrome-devtools-mcp@latest
