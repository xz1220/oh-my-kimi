---
name: cancel
description: Cleanly stop an oh-my-kimi workflow and summarize partial progress, changed files, and next steps.
argument-hint: "[reason]"
---

# Cancel

Use this when the user wants to stop an active workflow or when an autonomous
loop must exit cleanly.

## Steps

1. Stop launching new subagents or background work.
2. Check for active background tasks and report them.
3. Summarize completed work, changed files, verification already run, and
   incomplete acceptance criteria.
4. Leave the workspace in a non-destructive state.
5. Do not revert user changes unless explicitly requested.
