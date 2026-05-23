Read README.md in C:\TeamCity\Git\StolenAi for full context. Decisions are in docs/decisions.md.

This is an AI-assisted workflow system for ADO teams. **Re-test pass after recent changes** — prior `output/` artifacts (522809, 744719, 744812) are from earlier runs; clear or compare as needed.

## ADO Details
- Org: wtw-bda-outsourcing-product
- Project: BenefitConnect
- Test Feature ID: **744719** (used as the working example throughout)

## Test the PO Workflow Pipeline

### 1. Re-test fetch-feature.ps1
```powershell
.\scripts\po-workflow\fetch-feature.ps1 -FeatureId 744719 -Org "wtw-bda-outsourcing-product" -Project "BenefitConnect"
```
- Confirm: returns valid JSON with `id`, `title`, `description`, `acceptanceCriteria`, `state`, `areaPath`, `iterationPath`
- Compare against `output/744719/` baseline if helpful; fix any regressions before proceeding

### 2. Re-run po-grill skill
Feed the fetched Feature JSON to the po-grill skill interactively. Answer grill questions until it produces a slice-ready summary.
- Confirm: skill asks clarifying questions, converges to a structured summary suitable for slicing
- Save grill output to `output/744719/grill-summary.md` (overwrite prior)

### 3. Re-run slice agent
Feed the grill summary to the slice agent. It should produce a JSON array matching `schemas/stories-output.schema.json`.
- Confirm: valid JSON, no duplicate keys, all required fields (`title`, `description`, `acceptanceCriteria`, `briefMarkdown`)
- Save output to `output/744719/stories.json` (overwrite prior)

### 4. Re-run post-stories.ps1 in DryRun mode
```powershell
.\scripts\po-workflow\post-stories.ps1 -InputFile output/744719/stories.json -ParentId 744719 -Org "wtw-bda-outsourcing-product" -Project "BenefitConnect" -DryRun
```
- Confirm: schema validation passes, `output/744719/stories-review.md` regenerated
- Review stories-review.md for quality

### 5. Exercise the feedback loop end-to-end
This has been built but never exercised on real data.
- Create `output/744719/feedback.md` with per-story feedback (mark some stories "keep", others "revise: …", optionally "reject")
- Re-invoke the slice agent in revision mode with `stories.json` + `feedback.md`
- Confirm: approved stories are byte-identical, only the targeted stories change, no re-rolling of unchanged work
- Re-run step 4 to regenerate `stories-review.md`

## After PO Workflow Passes

### 6. ADO Attachment API
post-stories.ps1 uses `az boards work-item relation add --relation-type AttachedFile` to attach .md briefs. **Still untested.**
This likely doesn't work as-is (AttachedFile may require a REST upload first).
- Test: post one story to a scratch Feature and try the attach step
- If it fails: switch to `az devops invoke` REST call, or two-step (upload attachment via REST, then link)

### 7. End-to-end PO Workflow (real post to ADO)
Pick a NEW Feature (not Closed) and run the full flow through to actual ADO posting:
- fetch → grill → slice → review → post (no `-DryRun`)
- Verify: Stories created, linked to parent Feature, .md briefs attached
- Capture metrics entry in `metrics/metrics.jsonl` per `schemas/metrics-entry.schema.json`

### 8. Re-validate Dev Workflow Side
Prior run produced `output/744812/plan.json` and `specs/document-history-exclusion/744812.md`, but scripts/skills have changed since.
- Re-run `fetch-story.ps1` against Story 744812 (or a Story created in step 7); confirm output shape and that the brief attachment is read correctly
- Dry-run dev-grill with the fetched story; confirm it converges to a task DAG matching `schemas/plan-output.schema.json`
- Re-run `persist-plan.ps1` and verify all three actions (spec file write, git commit, ADO discussion post) still succeed atomically

### 9. Wire TDD Skill into dev-workflow
- Add an explicit reference/invocation of the existing `tdd` skill in `.github/agents/dev-workflow.agent.md` (currently absent)
- Confirm task breakdown from dev-grill (the `plan.json` task list) feeds into the TDD loop one task at a time, respecting the dependency DAG
- Confirm micro-review.agent.md is invoked after each task and findings pause the loop on drift

