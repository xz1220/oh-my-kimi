---
name: ultrawork
description: Execute a large task through parallel bounded workstreams with explicit integration and verification.
argument-hint: "<large task>"
---

# Ultrawork

Use this when a task is too large for a single linear pass but can be split into
independent workstreams.

## Workflow

1. Define the final acceptance criteria.
2. Split into independent workstreams with disjoint file ownership where
   possible.
3. Delegate read-only research and bounded implementation to appropriate
   subagents.
4. Integrate results in the main context.
5. Run full relevant validation.
6. Use `/skill:ai-slop-cleaner` and `/skill:verify` before final response.

Do not parallelize work that will collide in the same files.
