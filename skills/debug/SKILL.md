---
name: debug
description: Evidence-driven debugging workflow for failures, regressions, flaky tests, and unclear errors.
argument-hint: "<error, failing command, or symptom>"
---

# Debug

## Workflow

1. Capture the exact symptom and the freshest failing command output.
2. Form 2-4 competing hypotheses.
3. Pick the cheapest probe that can disprove one hypothesis.
4. Inspect code, config, environment, and recent diffs around the failure.
5. Fix the root cause, not the observed symptom.
6. Rerun the failing command and then the smallest broader regression check.

Use the `debugger` or `tracer` subagent for independent root-cause analysis
when the failure spans multiple modules.
