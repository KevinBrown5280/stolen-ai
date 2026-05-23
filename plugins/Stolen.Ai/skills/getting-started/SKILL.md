---
name: getting-started
description: >
  How to use the Stolen AI workflows. Use when a user asks "how do I use this",
  "getting started", "what can this do", "how do I plan a feature", or
  "how do I plan a story."
---

# Getting Started with Stolen AI

## Prerequisites

Create a `.stolenai.json` file in your project root with your ADO details:

```json
{
  "org": "your-ado-org",
  "project": "YourProject"
}
```

## Workflows

### Plan Feature — Break down a Feature into Stories

Say: `@plan-feature process Feature <ID>`

This runs the full pipeline:
1. **Fetch** — retrieves the Feature from ADO
2. **Refine** — grills you on ambiguity until the Feature is slice-ready
3. **Slice** — produces independently deliverable User Stories
4. **Review** — presents stories for your approval (approve/edit/reject)
5. **Post** — creates Stories in ADO as children of the Feature

### Plan Story — Plan implementation and execute with TDD

Say: `@plan-story pick up Story <ID>`

This runs the full pipeline:
1. **Fetch** — retrieves the Story and attached brief from ADO
2. **Refine** — grills you on technical approach until a task breakdown emerges
3. **Review** — presents task plan for approval
4. **Persist** — writes spec and posts discussion to ADO
5. **TDD** — executes tasks with red-green-refactor, drift-checked after each

### Manual Steps

If you prefer step-by-step control:

| I want to... | Do this |
|--------------|---------|
| Just refine a Feature | Say "refine this feature" in chat |
| Just refine a Story | Say "refine this story" in chat |
| Run TDD for a single task | Say "run TDD for task 1" in chat |

## Output Locations

All runtime artifacts are written to your working directory:

| Artifact | Location |
|----------|----------|
| Stories JSON | `./output/<feature-id>/stories.json` |
| Stories review | `./output/<feature-id>/stories-review.md` |
| Task specs | `./specs/<feature>/<story>.md` |
| Metrics | `./metrics/metrics.jsonl` |
| Retrospectives | `./output/<id>/retro.md` |

## Key Rules

- **Human approval required** before any ADO writes
- **Grill phase cannot be skipped** — ambiguity must be resolved first
- **Drift detection** pauses execution if code diverges from spec
- AI produces JSON; scripts handle ADO CRUD
