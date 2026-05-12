---
name: mcp-setup
description: Install or explain the recommended MCP servers for an oh-my-kimi Kimi CLI setup.
argument-hint: "[context7|chrome-devtools|sequential-thinking|all]"
---

# MCP Setup

Use the scripts in `mcp/` from the oh-my-kimi checkout:

```bash
bash mcp/add-context7.sh
bash mcp/add-chrome-devtools.sh
bash mcp/add-sequential-thinking.sh
bash mcp/add-recommended-all.sh
```

## Guidance

- `context7`: current library documentation lookup.
- `chrome-devtools`: browser inspection and frontend debugging.
- `sequential-thinking`: structured reasoning support for complex tasks.

Run only the integrations the user actually wants. MCP setup may require network
access and package downloads.
