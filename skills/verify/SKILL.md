---
name: verify
description: Build an evidence-based completion check before saying a task is done.
argument-hint: "<task or changed files>"
---

# Verify

Use this before finalizing non-trivial work.

## Checklist

1. Reconstruct the acceptance criteria from the user request.
2. Inspect changed files and related call paths.
3. Run the smallest relevant checks first, then broader checks when the change
   touches shared behavior.
4. Confirm generated artifacts, docs, and examples still match the code.
5. Record exact commands and outcomes.

If evidence is missing, say what remains unverified and why.
