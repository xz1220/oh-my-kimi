---
name: code-review
description: Review code for correctness, regressions, maintainability, tests, and integration risk.
argument-hint: "<diff, PR, or file list>"
---

# Code Review

Lead with findings, ordered by severity. Focus on bugs, behavioral regressions,
security exposure, missing tests, and unclear contracts.

For each finding include:

- File and line when available.
- Why it is a real risk.
- A concrete fix direction.

Keep summaries secondary. If there are no findings, say so and list residual
test gaps.
