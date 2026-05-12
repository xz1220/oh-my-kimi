---
name: plan
description: Create a concrete implementation plan with files, risks, validation commands, and rollback notes.
argument-hint: "[--review] [--direct] <task>"
---

# Plan

Use this when the user wants a plan before implementation, or when the task is
large enough that editing immediately would create unnecessary risk.

## Modes

- `--direct`: skip interview and produce a plan from the available context.
- `--review`: review an existing plan for missing risks, unclear acceptance
  criteria, and weak validation.

## Planning Steps

1. Inspect the relevant repository structure and existing conventions.
2. Identify the smallest coherent implementation slice.
3. List likely files or modules to touch.
4. Call out data, migration, security, UX, or compatibility risks.
5. Define validation commands, including unit, integration, and smoke tests as
   appropriate.
6. State any assumptions that need later confirmation.

## Output

Return:

- Goal
- Scope
- Implementation steps
- Validation
- Risks / assumptions

Keep the plan executable. Avoid architecture theater.
