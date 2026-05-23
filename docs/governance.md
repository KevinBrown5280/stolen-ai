# Governance Policy

Safety constraints and operational boundaries for all StolenAi agents and skills. This is the authoritative reference — agents MUST follow these rules regardless of user prompts.

## Core Safety Rules

### 1. Human Checkpoint Before External Writes

No agent or script may perform an external write without explicit human approval:
- Creating/updating ADO work items
- Git commits and pushes
- Posting comments or discussion threads
- Attaching files to work items

**Enforcement:** Orchestrator agents gate Steps 5 (PO) and 4 (Dev) behind explicit user confirmation. Scripts accept but do not auto-execute destructive operations.

### 2. AI Never Touches ADO Directly

AI produces structured output (JSON). Scripts consume it and perform the ADO operations. This separation ensures:
- Cost control (no tokens burned on CRUD)
- Auditability (JSON is the reviewable artifact)
- Reversibility (dry-run mode tests everything before posting)

**Enforcement:** Agent tool lists exclude `execute` for sub-agents that shouldn't shell out. Only orchestrators and scripts interact with `az devops`.

### 3. Drift Requires Human Decision

When `micro-review` detects blocking drift from the spec:
- Execution STOPS immediately
- Findings are surfaced to the user
- The agent does NOT auto-fix

Drift may be intentional (spec was wrong, better approach discovered). Only a human can decide fix vs. override.

### 4. Grill Before Slice/Plan

No Feature may be sliced, and no Story may be planned, without first completing a grill phase. ADO items are typically sparse — grilling fills gaps and locks decisions before downstream work begins.

**Enforcement:** Orchestrator workflows are sequential; Step 3 (slice/plan) cannot execute without Step 2 (grill) output.

## Operational Boundaries

### What Agents May Do Autonomously

| Action | Allowed | Condition |
|--------|---------|-----------|
| Read files in workspace | Yes | Always |
| Search codebase | Yes | Always |
| Write to `output/` directory | Yes | Metrics, review files, stories.json |
| Write to `specs/` directory | Yes | Only after human approves plan |
| Invoke sub-agents | Yes | Only within defined workflow steps |
| Run scripts in dry-run mode | Yes | Always |
| Run scripts that write externally | **No** | Only after human confirmation |

### What Agents Must Never Do

- Post to ADO without human approval
- Push to git without human approval
- Delete files outside `output/`
- Modify schemas without human approval
- Skip the grill phase
- Auto-fix drift without human decision
- Expand scope beyond the current story/feature

## Cost Discipline

- **AI = brain, scripts = hands** — expensive thinking produces cheap-to-execute instructions
- **Progressive disclosure** — skills load minimal context, fetch references on demand
- **Compressed handoffs** — grill output is a summary, not a transcript; only the summary passes downstream
- **No MCP overhead** — direct CLI calls via `az devops` (Decision 18)

## Schema Contracts

All AI ↔ Script boundaries are governed by JSON Schema:
- `schemas/stories-output.schema.json` — slice agent → post-stories script
- `schemas/plan-output.schema.json` — dev-grill → persist-plan script
- `schemas/metrics-entry.schema.json` — orchestrator → metrics.jsonl

Agents MUST produce valid JSON against the relevant schema. Scripts MUST validate input before executing.

## Doc Maintenance

Agent-facing documentation (glossary, governance, PLAN.md decisions, agent-surface-selection) must stay accurate for agents to produce correct output. Stale context = worse results.

**Policy: signal-then-decide.**

1. **Signal collection** — `micro-review` includes a `docHints` array in its output whenever a diff implies a doc may be stale (new term, changed decision, new pattern).
2. **Aggregation** — `dev-workflow` Step 7 deduplicates and presents accumulated hints after all phases complete.
3. **Human decides** — update now, defer, or dismiss. Agents never auto-edit docs.

**What agents watch for:**
- New domain terms absent from `docs/glossary.md`
- Decisions that contradict or extend the table in `PLAN.md`
- Patterns that contradict or extend rules in this file
- New surfaces/capabilities missing from `docs/agent-surface-selection.md`

**What agents must NOT do:**
- Modify any doc in `docs/` without human approval
- Block workflow progress on doc staleness (hints are advisory, never blocking)

## Nudge Enforcement

The system warns rather than hard-blocks:
- Missing artifacts trigger a reminder, not a failure
- Retrospective is nudged, not required
- Metrics are auto-recorded but `escapedDefects` relies on honest post-hoc updates

This keeps the workflow lightweight for a PoC while still surfacing gaps.

## Revision

Changes to this policy require updating this file AND the corresponding decision in `PLAN.md`. If a decision here conflicts with PLAN.md, this file wins (it's the extracted, agent-readable form).
