---
name: security-review
description: Security-focused review for secrets, injection, authz/authn, unsafe IO, dependency, and data exposure risks.
argument-hint: "<diff, files, or feature>"
---

# Security Review

Check for:

- Secrets or credential handling mistakes.
- Injection through shell, SQL, template, path, or browser sinks.
- Missing authorization checks.
- Confused authentication boundaries.
- Unsafe file writes, archive extraction, or path traversal.
- Excessive logging of personal or sensitive data.
- Dependency or supply-chain risk introduced by the change.

Report only plausible risks grounded in code or config evidence.
