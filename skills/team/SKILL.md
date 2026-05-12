---
name: team
description: Coordinate Kimi CLI subagents for parallel exploration, implementation, review, and verification.
argument-hint: "[N:agent] <task>"
---

# Team

Use this when the task benefits from independent specialist work. Prefer direct
work for small tasks.

## Native Kimi Pattern

Use Kimi's `Agent` tool with the subagent types registered by
`agents/oh-my-kimi.yaml`:

- `explore`: read-only codebase investigation.
- `planner` / `architect`: design and implementation planning.
- `executor`: bounded implementation work.
- `debugger` / `tracer`: failure analysis.
- `test-engineer` / `qa-tester`: test design and smoke testing.
- `critic` / `verifier` / `code-reviewer`: final review.
- `security-reviewer`: security-sensitive changes.

## Coordination Rules

1. Split only independent work. Do not send two writers into the same files.
2. Give each agent a concrete scope and expected output.
3. Ask read-only agents for file references and reasoning, not edits.
4. Integrate results yourself and run final verification locally.
5. Report only the conclusions that affect the main task.
