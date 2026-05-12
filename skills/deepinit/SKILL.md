---
name: deepinit
description: Initialize a repository understanding pass before major agentic work.
argument-hint: "[repo path]"
---

# Deepinit

Use this at the start of substantial work in an unfamiliar repository.

## Steps

1. Read top-level README, AGENTS, package/config files, and project docs.
2. Identify language, framework, build system, test commands, and deployment
   assumptions.
3. Inspect directory layout and key ownership boundaries.
4. Check git status and recent changes.
5. Produce a short repo brief:
   - What this repo does
   - How to run / test it
   - Important conventions
   - Risky areas
   - First files to inspect for the current task
