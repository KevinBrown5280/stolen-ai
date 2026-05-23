# StolenAi — Copilot Instructions

## Architecture

AI-assisted ADO workflows. Two pipelines: Plan Feature (Feature → Stories) and Plan Story (Story → Code).

**Core rule: AI = brain, scripts = hands.** AI produces structured JSON. Scripts do CRUD. Never burn tokens on deterministic I/O.

## Design Principles

1. **Grill before slice/plan** — ADO items are sparse; always clarify first
2. **Human checkpoint before external writes** — ADO posts, git pushes require confirmation
3. **Schema contracts** — all AI↔Script boundaries use JSON Schema (`schemas/`)
4. **Compressed handoffs** — summaries between phases, never full transcripts
5. **Drift = pause** — micro-review findings stop execution; human decides

## File Conventions

- `scripts/` — PowerShell, no AI, zero tokens
- `.github/skills/` — interactive (SKILL.md, agentskills.io format)
- `.github/agents/` — autonomous sub-agents (.agent.md)
- `schemas/` — JSON Schema contracts
- `specs/{feature}/` — one spec per Story
- `output/{id}/` — ephemeral working files (gitignored)

## When Modifying This Repo

- Don't let agents write to ADO directly (Decision 2, governance.md)
- New AI capabilities: check `docs/agent-surface-selection.md` for which surface to use
- Scripts validate schema before executing — keep schemas and scripts in sync
