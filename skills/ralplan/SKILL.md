---
name: ralplan
description: "Plan in Ralph style: turn a task into verifiable stories before starting autonomous execution."
argument-hint: "<task>"
---

# Ralplan

Use this before `/skill:ralph` when a task needs autonomous execution but should
first be broken into verifiable increments.

## Workflow

1. Clarify the goal, constraints, and non-goals.
2. Break the work into user stories or engineering slices.
3. For each story, write concrete acceptance criteria that can be checked with
   commands, screenshots, or file inspection.
4. Order stories so foundational work comes first and verification gates are
   visible.
5. Produce a validation matrix mapping each story to the checks that prove it.

## Output

Use this shape:

```markdown
## Objective
...

## Stories
1. ...
   Acceptance:
   - ...

## Validation Matrix
| Story | Evidence |
|---|---|

## Execution Notes
...
```
