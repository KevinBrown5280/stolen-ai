# StolenAi

AI-assisted software engineering workflows for Azure DevOps teams.

## Overview

Two workflows that separate **AI thinking** (expensive) from **script execution** (free):

- **PO Workflow**: Feature → Grill → Slice → Stories in ADO
- **Dev Workflow**: Story → Grill → Plan → Persist → TDD → Review

Human approves before any external write. AI never touches ADO directly — it produces JSON, scripts do the posting.

## Quick Start

```powershell
# PO: Break a Feature into Stories
# 1. Invoke po-workflow agent (or run steps manually)
# 2. Provide ADO Feature ID when prompted
# 3. Answer grill questions
# 4. Review proposed stories in output/{feature-id}/stories-review.md
# 5. Approve → stories posted to ADO

# Manual step-by-step:
.\scripts\po-workflow\fetch-feature.ps1 -FeatureId 12345 -Org "myorg" -Project "myproject"
# → grill (interactive) → slice agent produces stories.json
.\scripts\po-workflow\post-stories.ps1 -InputFile output/12345/stories.json -ParentId 12345 -Org "myorg" -Project "myproject" -DryRun
# → review stories-review.md, then run without -DryRun to post

# Dev: Pick up a Story and implement
# 1. Invoke dev-workflow agent (or run steps manually)
# 2. Provide ADO Story ID when prompted
# 3. Answer technical grill questions
# 4. Review task plan
# 5. Approve → spec persisted, TDD begins
```

## Structure

```
.github/
  skills/                         # Interactive (agentskills.io format)
    po-grill/SKILL.md            #   Grill PO about a Feature
    po-grill/references/         #   Output format template
    dev-grill/SKILL.md           #   Grill Dev about a Story
    dev-grill/references/        #   Output format + example JSON
  agents/                         # Autonomous + orchestration (.agent.md)
    po-workflow.agent.md          #   Orchestrator: full PO flow
    dev-workflow.agent.md         #   Orchestrator: full Dev flow
    slice.agent.md               #   Sub-agent: Feature → Stories JSON
    micro-review.agent.md        #   Sub-agent: drift detection
scripts/
  po-workflow/
    fetch-feature.ps1            # Read Feature from ADO
    post-stories.ps1             # Validate, dry-run review, or create Stories + attach briefs
  dev-workflow/
    fetch-story.ps1              # Read Story + attached brief
    persist-plan.ps1             # Write spec, commit, post discussion
schemas/
  stories-output.schema.json     # Contract: slice → post script
  plan-output.schema.json        # Contract: dev-grill → persist script
output/                           # Transient (gitignored)
  {feature-id}/
    stories.json                 # Slice agent output
    stories-review.md            # Human-readable review (from -DryRun)
    feedback.md                  # PO feedback for revision rounds
```

## Design Principles

- **AI = brain, scripts = hands** — no tokens burned on CRUD
- **Human checkpoints** — always before external writes (ADO, git)
- **Skills for dialogue, agents for autonomous work** — context isolation where it matters
- **agentskills.io + .agent.md** — portable across VS Code, Visual Studio 2026, and CLI
- **Nudge enforcement** — warn on missing artifacts, don't hard-block
- **Progressive disclosure** — skills reference detailed docs on demand

## Status

See [PLAN.md](PLAN.md) for full decisions, build order, and next steps.

## Prior Art & Influences

- [Burke Holland's orchestrator pattern](https://gist.github.com/burkeholland/0e68481f96e94bbb98134fa6efd00436) — sub-agent delegation, parallel phases, never implements itself
- [Matt Pocock's skills](https://github.com/mattpocock/skills) — grill-me, tdd, write-a-skill patterns
- [AI Hero (aihero.dev)](https://www.aihero.dev/) — [5 agent skills I use every day](https://www.aihero.dev/5-agent-skills-i-use-every-day), [video walkthrough](https://www.youtube.com/watch?v=-QFHIoCo-Ko)
- [GitHub Spec Kit](https://github.com/github/spec-kit) — spec → plan → tasks pipeline
- [Awesome Copilot](https://awesome-copilot.github.com/) — curated patterns and extensions
- [Agentic-Agile: Why Agent Development Needs Agile (Not Just Prompts)](https://developer.microsoft.com/blog/agentic-agile-why-agent-development-needs-agile-not-just-prompts) — Daniel Epstein (Microsoft PTS)
- [Agentic-Agile Manifesto](https://github.com/microsoft/agentic-agile-template/blob/main/MANIFESTO.md) — 5 values, 13 principles
- [microsoft/agentic-agile-template](https://github.com/microsoft/agentic-agile-template) — starter repo with agent context files, issue templates, docs
- [The AX Stack: What's Fixed, Where You Can Win](https://developer.microsoft.com/blog/the-ax-stack-whats-fixed-where-you-can-win) — Agent Experience (AX) measurement: discovery, selection, quality, lift vs. drag
- [agentskills.io](https://agentskills.io/) — open standard for portable skills (VS Code, VS 2026, CLI, Cursor, Claude Code)
