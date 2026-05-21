# StolenAi — Plan & Handoff

## What This Is

AI-assisted software engineering workflows for Azure DevOps teams. Two workflows that separate AI thinking (expensive) from script execution (free). Proof of concept for team adoption.

## Architecture Summary

```
Skills (interactive, in main session)     Agents (autonomous, fresh context)
┌──────────────────────────────┐         ┌───────────────────────────────┐
│  po-grill   → grill the PO  │         │  po-workflow.agent.md         │
│  dev-grill  → grill the dev │         │  dev-workflow.agent.md        │
└──────────────────────────────┘         │  slice.agent.md              │
                                         │  micro-review.agent.md       │
Scripts (no AI, no tokens)               └───────────────────────────────┘
┌──────────────────────────────┐
│  fetch-feature.ps1           │         Schemas (contracts)
│  post-stories.ps1            │         ┌───────────────────────────────┐
│  fetch-story.ps1             │         │  stories-output.schema.json   │
│  persist-plan.ps1            │         │  plan-output.schema.json      │
└──────────────────────────────┘         └───────────────────────────────┘
```

## Locked Design Decisions

| # | Decision | Choice | Rationale |
|---|----------|--------|-----------|
| 1 | Trigger | Human invokes CLI command | No automation/webhooks for PoC |
| 2 | Input | Existing ADO Feature ID (PO) or Story ID (Dev) | Features already exist in ADO |
| 3 | Grill mandatory | Always grill before slicing | ADO items are typically sparse |
| 4 | Artifact model | Stories ARE the specs (no monolithic spec file) | Each story is self-contained |
| 5 | PO output | Stories in ADO + attached .md brief per story | ADO scannable, .md has depth |
| 6 | Dev output | Discussion thread on Story + single local spec file | ADO Tasks too noisy |
| 7 | Spec location | `specs/{feature}/{story-slug}.md` — one file per Story | Cross-session continuity for AI |
| 8 | AI ↔ Script contract | JSON (schemas in `schemas/`) | Testable, versionable |
| 9 | Human checkpoint | Always before external writes (ADO, git) | Safety |
| 10 | Task granularity | 2-4 hour logical groupings, AI decides | Balance visibility vs noise |
| 11 | Task dependencies | AI suggests dep graph, dev confirms | Enables parallelism |
| 12 | TDD execution | Parallel where deps allow | Deps form a DAG |
| 13 | Review timing | Micro-review after each task | Catch drift early |
| 14 | Drift response | Pause for human decision (no auto-fix) | Drift may be intentional |
| 15 | Cost model | AI = brain, scripts = hands | No tokens burned on CRUD |
| 16 | Persist step | Writes spec + commits + posts ADO discussion (one script) | Three actions, atomic |
| 17 | Brief attached at slice time | With option to regenerate | Pre-baked, consistent |
| 18 | No MCP for PoC | Use `az devops` CLI directly from scripts | Simpler, already available |
| 19 | Format split | Skills (`SKILL.md`) for interactive. Agents (`.agent.md`) for autonomous + orchestration | Skills = portable (agentskills.io). Agents = sub-agent delegation |
| 20 | Reuse existing | grill-me, tdd, code-review patterns already exist | Only build the gaps |
| 21 | Grill output = compressed summary | Only summary passes to next phase | Prevents context bloat |
| 22 | .agent.md portability | VS Code, Visual Studio 2026, CLI all support it | Confirmed via fun-with-copilot repo |
| 23 | agentskills.io compliance | Skills follow the open spec (frontmatter, progressive disclosure, references/) | Portable across all AI tools |

## Two Workflows

### PO Workflow (`po-workflow.agent.md` orchestrates)
```
1. Trigger    → Human: CLI command + ADO Feature ID
2. Fetch      → Script: fetch-feature.ps1 reads Feature from ADO
3. Grill      → Skill: po-grill (interactive with PO, fills gaps, locks decisions)
4. Slice      → Agent: slice.agent.md (produces Stories JSON + .md briefs)
5. Review     → Human: approves/edits proposed stories
6. Post       → Script: post-stories.ps1 creates Stories in ADO + attaches .md
7. Confirm    → Script: reports links to created items
```

### Dev Workflow (`dev-workflow.agent.md` orchestrates)
```
1. Trigger    → Human: CLI command + ADO Story ID
2. Fetch      → Script: fetch-story.ps1 reads Story AC + attached .md brief
3. Dev Grill  → Skill: dev-grill (interactive, locks technical decisions)
4. Plan       → Output: task breakdown + dependency graph as JSON
5. Review     → Human: approves/edits plan + deps
6. Persist    → Script: persist-plan.ps1 (spec file + commit + ADO discussion)
7. TDD Loop   → Sub-agents per task (sequential respecting deps, parallel where independent)
8. Micro-review → Agent: micro-review.agent.md (checks diff after each task)
9. Pause      → Human: decides fix or override if drift detected
```

## File Structure

```
.github/
  skills/
    po-grill/
      SKILL.md                    # Interactive PO grilling (agentskills.io format)
      references/output-format.md # Progressive disclosure: output template
    dev-grill/
      SKILL.md                    # Interactive Dev grilling
      references/output-format.md # Progressive disclosure: output template + example JSON
  agents/
    po-workflow.agent.md          # Orchestrator agent (model: sonnet, tools: read/execute/agent)
    dev-workflow.agent.md         # Orchestrator agent (model: sonnet, tools: read/execute/edit/agent)
    slice.agent.md               # Sub-agent (model: sonnet, tools: read)
    micro-review.agent.md        # Sub-agent (model: sonnet, tools: read/search)
schemas/
  stories-output.schema.json     # Contract: slice agent → post-stories script
  plan-output.schema.json        # Contract: dev-grill output → persist-plan script
scripts/
  po-workflow/
    fetch-feature.ps1            # Reads Feature from ADO via az boards
    post-stories.ps1             # Creates Stories + attaches .md briefs
  dev-workflow/
    fetch-story.ps1              # Reads Story + attached .md brief
    persist-plan.ps1             # Writes spec file, commits, posts ADO discussion
```

## Build Order (usage order)

| # | Item | Location | Type | Status |
|---|------|----------|------|--------|
| 1 | Fetch Feature | `scripts/po-workflow/fetch-feature.ps1` | Script | ✅ Tested (Feature 522809) |
| 2 | PO Grill | `.github/skills/po-grill/SKILL.md` | Skill | ✅ Tested (dry-run) |
| 3 | Slice | `.github/agents/slice.agent.md` | Agent | ✅ Tested (produces valid JSON, revision mode added) |
| 4 | Review UX | `post-stories.ps1 -DryRun` → `stories-review.md` | Script | ✅ Built |
| 5 | Post Stories | `scripts/po-workflow/post-stories.ps1` | Script | ✅ Schema validation + DryRun added |
| 6 | PO Workflow Orchestrator | `.github/agents/po-workflow.agent.md` | Agent | ✅ Updated (output dir, feedback loop) |
| 7 | **End-to-end PO workflow test** | — | Integration | ⬜ TODO (post to ADO with real Feature) |
| 8 | Fetch Story | `scripts/dev-workflow/fetch-story.ps1` | Script | ✅ Scaffolded |
| 9 | Dev Grill | `.github/skills/dev-grill/SKILL.md` | Skill | ✅ Scaffolded |
| 10 | Plan (task breakdown) | (output of dev-grill, no separate agent needed) | — | ✅ Built into dev-grill |
| 11 | Persist Plan | `scripts/dev-workflow/persist-plan.ps1` | Script | ✅ Scaffolded |
| 12 | Dev Workflow Orchestrator | `.github/agents/dev-workflow.agent.md` | Agent | ✅ Scaffolded |
| 13 | TDD integration | Reuse existing `tdd` skill | Skill | ⬜ TODO (wire in) |
| 14 | Micro-review | `.github/agents/micro-review.agent.md` | Agent | ✅ Scaffolded |
| 15 | **End-to-end Dev workflow test** | — | Integration | ⬜ TODO |

## What's Done

- Full project scaffold with correct file structure
- Skills follow agentskills.io spec (frontmatter, progressive disclosure via references/)
- Agents have proper .agent.md format (model, tools, description)
- JSON schemas define the contract between AI and scripts
- Scripts for all ADO interactions (fetch, post, persist)
- Both orchestrator agents describe the full workflow with human checkpoints
- **fetch-feature.ps1 tested** — validated against Feature 522809 in BenefitConnect
- **po-grill dry-run** — 8-question grill from vague HTML to slice-ready summary
- **slice agent tested** — produces valid 4-story output; duplicate key issue identified and mitigated
- **post-stories.ps1 hardened** — schema validation (duplicate keys, required fields), -DryRun switch writes stories-review.md
- **Output directory convention** — `output/{feature-id}/` for stories.json + stories-review.md (gitignored)
- **Feedback loop** — PO can edit/reject slices with per-story feedback; slice agent revises without re-rolling approved stories
- **Orchestrator updated** — po-workflow.agent.md now references output dir, dry-run review, and feedback loop

## Next Steps (for next session)

1. **ADO attachment API** — verify `az boards` supports file attachments or switch to REST (post-stories.ps1 attachment step untested)
2. **End-to-end PO workflow** — pick a real NEW Feature, run full flow, post to ADO
3. **Test dev-workflow side** — fetch-story.ps1 + dev-grill + persist-plan.ps1
4. **Wire TDD skill** — integrate existing `tdd` skill into dev-workflow orchestrator
5. **Refine slice agent** — still occasionally produces duplicate JSON keys on first attempt (self-corrects but noisy for automation)

## Key Influences / Prior Art

- **Burke Holland orchestrator** — sub-agent delegation, parallel phases, never implements itself
- **Matt Pocock skills** — grill-me, tdd, write-a-skill patterns, agentskills.io spec
- **GitHub Spec Kit** — spec→plan→tasks pipeline
- **agentskills.io** — open standard for portable skills (VS Code, VS 2026, CLI, Cursor, Claude Code, etc.)

## Design Principles

- **AI = brain, scripts = hands** — cost control at the boundary
- **Nudge enforcement** — warn on missing artifacts, don't hard-block
- **Human checkpoints** — always before external writes
- **Progressive disclosure** — skills load minimal context, reference detailed docs on demand
- **Tracer bullets** — thin end-to-end slices proving architecture before fleshing out
