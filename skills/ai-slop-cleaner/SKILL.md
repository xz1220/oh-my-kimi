---
name: ai-slop-cleaner
description: Remove AI-generated verbosity, brittle abstractions, stale comments, and cosmetic churn from recent changes.
argument-hint: "[--review] <files or diff>"
---

# AI Slop Cleaner

Use this after implementation or during review.

## Review Targets

- Unnecessary abstractions or wrappers.
- Generic comments that repeat the code.
- Overly broad error handling.
- Debug leftovers.
- Inconsistent naming or style.
- Docs that promise behavior the code does not implement.
- Changes outside the requested scope.

## Mode

- Default: edit the scoped files to clean issues, then rerun relevant checks.
- `--review`: report issues only.

Keep the cleanup bounded to files changed for the current task.
