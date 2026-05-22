# Measurement Framework

Formalized evaluation for StolenAi workflows. Tracks whether the system improves outcomes over time and identifies which skills/agents need tuning.

## Dimensions

| # | Dimension | Definition | Measured At | Target |
|---|-----------|-----------|-------------|--------|
| 1 | First-pass acceptance | Stories or plan accepted by human without edits | Review step (PO: stories-review, Dev: plan review) | ≥ 80% of stories need zero edits |
| 2 | Rework cycles | Number of revision rounds before human approves | Slice feedback loop / dev-grill iterations | ≤ 1 revision round average |
| 3 | Grill efficiency | Questions asked before reaching slice-ready / plan-ready | End of grill phase | Trending down per Feature area |
| 4 | Escaped defects | Issues found after posting (re-slice needed, plan divergence, missed AC) | Post-implementation retro | 0 per workflow run (aspirational) |

## How to Record

Both orchestrator agents (`po-workflow.agent.md`, `dev-workflow.agent.md`) **automatically append** an entry to `output/metrics.jsonl` as their penultimate step — no human action required. The agent has observed every number (grill questions, revision rounds, acceptance counts) by the time it reaches the metrics step.

`escapedDefects` starts at 0 and is manually incremented if an issue surfaces post-completion.

### PO Workflow Entry

```json
{
  "timestamp": "2026-05-22T14:30:00Z",
  "workflow": "po",
  "featureId": 744719,
  "featureTitle": "Document History Exclusion",
  "grillQuestions": 8,
  "sliceRevisions": 0,
  "storiesProposed": 3,
  "storiesAcceptedFirstPass": 3,
  "storiesEdited": 0,
  "storiesRejected": 0,
  "escapedDefects": 0,
  "notes": ""
}
```

### Dev Workflow Entry

```json
{
  "timestamp": "2026-05-22T15:00:00Z",
  "workflow": "dev",
  "storyId": 744812,
  "storyTitle": "Configurable exclusion list from cm_setting",
  "grillQuestions": 6,
  "planRevisions": 0,
  "tasksPlanned": 4,
  "tasksCompletedFirstPass": 4,
  "microReviewDrifts": 0,
  "escapedDefects": 0,
  "notes": ""
}
```

## When to Record

| Event | Action |
|-------|--------|
| PO workflow completes (post or dry-run) | Append PO entry |
| Dev workflow completes (all tasks done) | Append Dev entry |
| Escaped defect discovered | Update the relevant entry's `escapedDefects` count |

## Analysis

Periodically (weekly or after 5+ runs), review `output/metrics.jsonl` for:

1. **Acceptance trend** — `storiesAcceptedFirstPass / storiesProposed` over time. Rising = skill/schema improving.
2. **Rework trend** — `sliceRevisions` or `planRevisions` average. Falling = grill quality improving.
3. **Grill efficiency** — `grillQuestions` per Feature area. Lower = better input quality or better skill targeting.
4. **Defect rate** — `escapedDefects` total. Any non-zero triggers a retrospective.

## Lift vs. Drag (AX Stack)

When evaluating a skill/agent change, compare:
- **Baseline run** — same Feature/Story without the change (or historical average)
- **Treatment run** — with the change

A change is **lift** if it reduces rework, increases first-pass acceptance, or reduces grill questions without degrading other dimensions. A change is **drag** if it increases any dimension negatively without offsetting gains.

## Relation to Retrospectives

The [retrospective template](retrospective-template.md) includes a Metrics section. After formalizing, that section is **required** (not optional) and must reference the JSONL entry for the run.
