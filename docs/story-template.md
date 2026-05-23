# Story Template

Authoritative structure for User Stories produced by the `slice` agent and consumed by `post-stories.ps1`, `dev-grill`, and `micro-review`. Mirrors structured fields from [agentic-agile-template](https://github.com/microsoft/agentic-agile-template) adapted for ADO.

## ADO Fields (posted directly)

| ADO Field | Source | Notes |
|-----------|--------|-------|
| Title | `title` | "As a [persona], I can [action] so that [value]" |
| Description | `description` | High-level what/why (1-3 sentences) |
| Acceptance Criteria | `acceptanceCriteria` | Given/When/Then format, testable |
| Area Path | Inherited from parent Feature | |
| Iteration Path | Inherited from parent Feature | |
| Attached File | `briefMarkdown` rendered as `{id}-brief.md` | |

## Schema Fields

All fields defined in `schemas/stories-output.schema.json`:

### Required

- **title** — User Story title in persona format
- **description** — What and why
- **acceptanceCriteria** — Testable Given/When/Then conditions
- **briefMarkdown** — Rich implementation brief (attached as .md)

### Optional (but strongly recommended)

- **negativeConstraints** — Array of strings declaring what this story does NOT do

> **Note:** File ownership is intentionally NOT part of either schema today. See "Future: File Ownership" below.

## Brief Markdown Sections

```markdown
# Implementation Brief

## Context
Why this story exists. Relationship to parent Feature. Decisions locked during grill.

## Suggested Approach
Non-prescriptive implementation guidance. Steps the dev might follow.

## Negative Constraints
What this story explicitly does NOT do (mirrors negativeConstraints field).
- Does NOT modify ...
- Does NOT implement ...

## Risks / Unknowns
Anything the dev should investigate before committing to an approach.

## Relevant ADRs
References to architectural decisions that apply.
```

## Negative Constraints Guidelines

1. Include at least 1-2 per story
2. Focus on adjacent scope someone might mistakenly include
3. Use concrete language: "Does NOT modify admin document views"
4. Useful for:
   - **micro-review**: verifies no constraint was violated in the diff
   - **dev-grill**: surfaces boundaries the dev must respect
   - **scope creep prevention**: clear "stop" signals during implementation

## Relationship to Agentic-Agile Template

| Agentic-Agile Field | StolenAi Equivalent |
|---------------------|---------------------|
| Summary | `description` |
| Originating Prompt | Captured via grill summary (not per-story) |
| Context / Motivation | Brief → Context section |
| Files to Create or Modify | Not formalized — task `description` implies files |
| Interfaces to Implement | Brief → Suggested Approach |
| Invariants to Preserve | `negativeConstraints` + Brief → Negative Constraints |
| Acceptance Criteria | `acceptanceCriteria` (Given/When/Then) |
| Negative Constraints | `negativeConstraints` field |
| Dependencies | Not used — stories are independently deliverable |
| File Ownership | Not formalized — see "Future: File Ownership" below |

## Future: File Ownership

File ownership is **not currently formalized** in any schema. It would add value when:

1. **Parallel story execution** — multiple devs working stories from the same slice simultaneously, needing to avoid merge conflicts on shared files. Add `fileOwnership` at the **story level** (populated by dev-grill, not PO slice).
2. **Wave-based swarming** — if StolenAi adopts the agentic-agile "wave" model where multiple agents work separate stories on separate branches concurrently.

It does NOT add value at the **task level** because tasks within a single story are executed by one dev sequentially (DAG order). The task `description` already implies which files are touched, and micro-review detects drift from that.

**When to revisit:** If you introduce parallel story execution or multi-agent swarming, add a `fileOwnership` array to `stories-output.schema.json` (populated during dev-grill, not PO slice) with structure: `[{ "path": "...", "action": "create|modify|delete" }]`.
