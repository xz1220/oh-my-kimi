#!/usr/bin/env bash
set -euo pipefail

kimi mcp add --transport stdio sequential-thinking -- npx -y @modelcontextprotocol/server-sequential-thinking
