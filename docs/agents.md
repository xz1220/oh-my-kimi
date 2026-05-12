# Agents

Run the full bundle:

```bash
kimi-omk
```

or directly:

```bash
kimi --agent-file ~/.oh-my-kimi/agents/oh-my-kimi.yaml
```

## Included Subagents

| Agent | Use |
|---|---|
| `executor` | Bounded implementation work |
| `explore` | Read-only codebase discovery |
| `planner` | Implementation planning |
| `architect` | Architecture and design review |
| `critic` | Structured critique |
| `verifier` | Completion verification |
| `code-reviewer` | Code review |
| `security-reviewer` | Security review |
| `debugger` | Root-cause analysis |
| `tracer` | Causal tracing |
| `test-engineer` | Test design and hardening |
| `qa-tester` | Interactive QA |
| `designer` | UI/UX implementation review |
| `document-specialist` | External docs and references |
| `writer` | Documentation writing |
| `git-master` | Git and release hygiene |
| `analyst` | Requirements and product analysis |
| `scientist` | Data and research execution |
| `code-simplifier` | Cleanup and simplification |

Subagents inherit Kimi's default agent and then narrow their tool policies.
Subagents cannot launch more subagents.
