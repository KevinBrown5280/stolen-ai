# Story Template

Authoritative structure for User Stories produced by the `slice` agent and consumed by `post-stories.ps1`, `refine-story`, and `micro-review`. Mirrors structured fields from [agentic-agile-template](https://github.com/microsoft/agentic-agile-template) adapted for ADO.

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

> **Note:** File ownership deferred — see [roadmap.md](roadmap.md#file-ownership-story-level).

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
   - **refine-story**: surfaces boundaries the dev must respect
   - **scope creep prevention**: clear "stop" signals during implementation

## Design Notes

- Modeled after [microsoft/agentic-agile-template](https://github.com/microsoft/agentic-agile-template) `agentic-story.md`. Key differences: file ownership deferred (see [roadmap](roadmap.md#file-ownership-story-level)), dependencies omitted (stories are independently deliverable), scope/files captured at task level in `plan-output.schema.json` during refine-story.
- ADO lacks issue templates. Schema validation in `post-stories.ps1` is the enforcement mechanism.
