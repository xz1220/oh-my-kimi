---
name: ralph
description: "Persistent autonomous execution loop: plan, implement, verify, review, fix, and repeat until done."
argument-hint: "[--max-iterations N] [--no-deslop] <task>"
---

# Ralph

Use this when the user explicitly wants the task completed end to end without
stopping at a proposal.

## Loop

1. Establish acceptance criteria. If none exist, create them from the task.
2. Build a short task list and keep exactly one item in progress.
3. Implement the next slice.
4. Run the relevant verification commands and read the output.
5. If verification fails, fix the root cause and rerun the failed check.
6. Run a review pass using the appropriate subagent (`critic`, `verifier`,
   `code-reviewer`, `security-reviewer`, or `qa-tester`) when the change is
   non-trivial.
7. Do a cleanup pass unless `--no-deslop` is present.
8. Stop only when acceptance criteria are met and fresh evidence exists.

## Rules

- Do not reduce scope silently.
- Do not delete tests to make the suite pass.
- Do not claim success from stale command output.
- Use parallel subagents only for independent investigation or review.
- Keep final output focused on changed files and verification evidence.
