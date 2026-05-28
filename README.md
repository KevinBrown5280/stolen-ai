# StolenAi

AI-assisted software engineering workflows for Azure DevOps teams.

## Overview

Two workflows that separate **AI thinking** (expensive) from **script execution** (free):

- **Plan Feature**: Feature → Refine → Slice → Stories in ADO
- **Plan Story**: Story → Refine → Plan → Persist → TDD → Review

Human approves before any external write. AI never touches ADO directly — it produces JSON, scripts do the posting.

## Quick Start

```powershell
# Plan Feature: Break a Feature into Stories
# 1. Invoke plan-feature agent (or run steps manually)
# 2. Provide ADO Feature ID when prompted
# 3. Answer refinement questions
# 4. Review proposed stories in output/{feature-id}/stories-review.md
# 5. Approve → stories posted to ADO

# Manual step-by-step:
.\plugins\stolen-ai\scripts\plan-feature\fetch-feature.ps1 -WorkItemId 12345 -Org "myorg" -Project "myproject"
# → refine (interactive) → slice-feature agent produces stories.json
.\plugins\stolen-ai\scripts\plan-feature\post-stories.ps1 -InputFile output/12345/stories.json -ParentId 12345 -Org "myorg" -Project "myproject" -DryRun
# → review stories-review.md, then run without -DryRun to post

# Plan Story: Pick up a Story and implement
# 1. Invoke plan-story agent (or run steps manually)
# 2. Provide ADO Story ID when prompted
# 3. Answer technical refinement questions
# 4. Review task plan
# 5. Approve → spec persisted, TDD begins
```

## Structure

```
plugins/stolen-ai/
  agents/                          # Autonomous + orchestration (.agent.md)
    plan-feature.agent.md          #   Orchestrator: full Feature planning flow
    plan-story.agent.md            #   Orchestrator: full Story planning flow
    slice-feature.agent.md         #   Sub-agent: Feature → Stories JSON
    code-story.agent.md            #   Sub-agent: TDD implementation
    micro-review.agent.md          #   Sub-agent: drift detection
    designer.agent.md              #   Handles UI/UX design tasks - styling, visual alignment, component appearance
  skills/                          # Interactive (agentskills.io format)
    refine-feature/SKILL.md        #   Refine a Feature for slicing
    refine-feature/references/     #   Output format template
    refine-story/SKILL.md          #   Refine a Story for implementation
    refine-story/references/       #   Output format + example JSON
    getting-started/SKILL.md       #   Onboarding walkthrough
  scripts/
    plan-feature/
      fetch-feature.ps1            # Read Feature from ADO
      post-stories.ps1             # Validate, dry-run review, or create Stories + attach briefs
    plan-story/
      fetch-story.ps1              # Read Story + attached brief
      persist-spec.ps1             # Write spec, commit, post discussion
    post-comment.ps1               # Post markdown comment to ADO work item
  schemas/
    stories-output.schema.json     # Contract: slice → post script
    spec-output.schema.json        # Contract: refine-story → persist script
    metrics-entry.schema.json      # Contract: workflow metrics entries
  docs/
    governance.md                  # What agents may/may not do
    feature-decomposition.md       # Decomposition patterns
    retrospective-template.md      # Post-workflow retro template
    story-template.md              # Story template
  plugin.json                      # Plugin manifest
output/                            # Transient (gitignored)
  {feature-id}/
    stories.json                   # Slice agent output
    stories-review.md              # Human-readable review (from -DryRun)
    feedback.md                    # PO feedback for revision rounds
specs/                             # Persisted specs (per Story)
```

## Process Artifacts

| Template | When to use | Location |
|----------|-------------|----------|
| [Retrospective](docs/retrospective-template.md) | After each completed PO or Dev workflow run | Copy to `output/{id}/retro.md` and fill in |

Both workflow agents remind you at end-of-run.

## Design Principles

- **AI = brain, scripts = hands** — no tokens burned on CRUD
- **Human checkpoints** — always before external writes (ADO, git)
- **Skills for dialogue, agents for autonomous work** — context isolation where it matters
- **agentskills.io + .agent.md** — portable across VS Code, Visual Studio 2026, and CLI
- **Nudge enforcement** — warn on missing artifacts, don't hard-block
- **Progressive disclosure** — skills reference detailed docs on demand

## Decisions

See [docs/decisions.md](docs/decisions.md) for all locked design decisions.

## Prior Art & Influences

See [docs/inspirations.md](docs/inspirations.md) for full sources, what we adopted from each, and alignment analysis.
