Read PLAN.md and README.md in C:\TeamCity\Git\StolenAi for full context.

This is an AI-assisted workflow system for ADO teams. The PO workflow has been tested step-by-step.

## ADO Details
- Org: wtw-bda-outsourcing-product
- Project: BenefitConnect

## Test the PO Workflow Pipeline

### 1. Test fetch-feature.ps1
```powershell
.\scripts\po-workflow\fetch-feature.ps1 -FeatureId 522809 -Org "wtw-bda-outsourcing-product" -Project "BenefitConnect"
```
- Confirm: returns valid JSON with id, title, description, acceptanceCriteria, state, areaPath, iterationPath
- Fix any issues before proceeding

### 2. Dry-run po-grill skill
Feed the fetched Feature JSON to the po-grill skill interactively. Answer grill questions until it produces a slice-ready summary.
- Confirm: skill asks clarifying questions, converges to a structured summary suitable for slicing

### 3. Test slice agent
Feed the grill output to the slice agent. It should produce a JSON array matching `schemas/stories-output.schema.json`.
- Confirm: valid JSON, no duplicate keys, all required fields (title, description, acceptanceCriteria, briefMarkdown)
- Save output to `output/522809/stories.json`

### 4. Test post-stories.ps1 in DryRun mode
```powershell
.\scripts\po-workflow\post-stories.ps1 -InputFile output/522809/stories.json -ParentId 522809 -Org "wtw-bda-outsourcing-product" -Project "BenefitConnect" -DryRun
```
- Confirm: schema validation passes, stories-review.md generated in same directory as input
- Review stories-review.md for quality

### 5. Test feedback loop
Provide per-story feedback and re-invoke slice agent with previous stories + feedback (revision mode).
- Confirm: slice agent preserves unchanged stories, applies feedback precisely

## After PO Workflow Passes

### 6. ADO Attachment API
post-stories.ps1 uses `az boards work-item relation add --relation-type AttachedFile` to attach .md briefs.
This likely doesn't work (AttachedFile may need a REST upload first).
- Test: try posting a story to a scratch Feature and attaching a brief
- If it fails: switch to `az devops invoke` REST call or two-step (upload attachment, then link)

### 7. End-to-end PO Workflow (real post)
Pick a NEW Feature (not Closed) and run the full flow through to actual ADO posting:
- fetch → grill → slice → review → post
- Verify: Stories created, linked to parent Feature, .md briefs attached

### 8. Test Dev Workflow Side
- Test fetch-story.ps1 against one of the stories created above
- Dry-run dev-grill with the fetched story
- Test persist-plan.ps1 (spec file creation, commit, ADO discussion post)

### 9. Wire TDD Skill
- Integrate existing `tdd` skill into dev-workflow.agent.md
- Ensure task breakdown from dev-grill feeds into TDD loop correctly
