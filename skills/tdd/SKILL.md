---
name: tdd
description: Test-driven implementation loop for small behavior changes and bug fixes.
argument-hint: "<behavior>"
---

# TDD

1. Identify the smallest externally visible behavior.
2. Write or update a failing test that proves the behavior.
3. Run the focused test and confirm it fails for the expected reason.
4. Implement the smallest production change.
5. Rerun the focused test.
6. Run the relevant broader suite.
7. Refactor only after tests pass.

Do not write tests that simply mirror implementation details.
