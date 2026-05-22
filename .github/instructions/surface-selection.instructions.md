---
applyTo: "**/*.agent.md,**/*SKILL.md"
---

# Surface Selection — When Building Skills & Agents

Only loaded when editing `.agent.md` or `SKILL.md` files.

## Use a Skill (`SKILL.md`) when:
- Task requires back-and-forth with a human
- Input is ambiguous/sparse and needs clarification
- Output quality depends on eliciting unstated knowledge
- Task is exploratory (outcome not predictable from input alone)

## Use an Agent (`.agent.md`) when:
- Task can run to completion without human input
- Input is well-structured (JSON, spec, prior skill output)
- Output follows a defined schema or template
- Benefits from clean context (no conversation noise)
- Is a sub-step in a larger workflow

## Use a Script (`.ps1`) when:
- Deterministic (same input → same output)
- Interacts with external systems (ADO, git)
- No reasoning or judgment needed
- Cost matters — would waste tokens if done by AI

## Anti-Patterns
- Agent asking user questions → should be a skill
- Skill doing deterministic transform → should be an agent
- AI doing CRUD → should be a script
- Script needing contextual judgment → should be a skill/agent

## Tool Access Rules
- Orchestrator agents: `read`, `execute`, `agent`
- Sub-agents (slice, micro-review): `read` only (+ `search` for review)
- Skills: inherit session tools (no restriction needed)

## Full reference: `docs/agent-surface-selection.md`
