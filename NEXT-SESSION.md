Read PLAN.md and README.md in C:\TeamCity\Git\StolenAi for full context.

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

---

## Agentic-Agile & AX Stack Review (May 2026)

Single-section review of StolenAi against the full referenced material:
- [Agentic-Agile: Why Agent Development Needs Agile (Not Just Prompts)](https://developer.microsoft.com/blog/agentic-agile-why-agent-development-needs-agile-not-just-prompts) — introductory blog post by Daniel Epstein (Microsoft PTS)
- [Agentic-Agile Manifesto](https://github.com/microsoft/agentic-agile-template/blob/main/MANIFESTO.md) — 5 values, 13 principles
- [microsoft/agentic-agile-template](https://github.com/microsoft/agentic-agile-template) — starter repo with agent context files, issue templates, docs
- [The AX Stack: What's Fixed, Where You Can Win](https://developer.microsoft.com/blog/the-ax-stack-whats-fixed-where-you-can-win) — Waldek Mastykarz (Agent Experience measurement: discovery, selection, quality, composition, lift vs. drag)

### Already Aligned / Ahead

- **Specs as control surface** (P1) — grill-first mandate locks specs before execution
- **Independent units** (P2) — slice agent produces stories with file ownership + AC
- **Human designs, agent executes, both review** (P4) — human checkpoint enforced architecturally (script/AI split)
- **Independent review** (P6) — micro-review after each TDD task
- **Waves not waterfalls** (P7) — DAG-based phase parallelism; independent tasks spawn concurrent sub-agents within a phase (same pattern as wave swarming, at task granularity)
- **Machine-verifiable contracts** — JSON schemas tighter than the template's markdown conventions
- **Cost discipline** — "AI = brain, scripts = hands" is concrete; template only discusses philosophically
- **Agent context file** — `.github/copilot-instructions.md` codifies design principles + conventions
- **Retrospectives** — `docs/retrospective-template.md` with structured post-wave reflection + metrics recording
- **Evaluation framework** — `docs/metrics.md` tracks 4 dimensions (first-pass acceptance, rework cycles, grill efficiency, escaped defects) with JSONL schema
- **Governance as policy** — `docs/governance.md` standalone doc with safety rules, operational boundaries, and enforcement mechanisms
- **Epic decomposition guide** — `docs/feature-decomposition.md` documents slice patterns (Config→Core→Integration→UX, Behavior→Data→Operations)
- **Agent surface selection** — `docs/agent-surface-selection.md` with decision matrix, selection rules, and anti-patterns
- **Shared vocabulary** — `docs/glossary.md` defines 12 terms (grill, slice, brief, persist, micro-review, drift, checkpoint, surface, contract, DAG, orchestrator, tracer bullet)
- **CI/CD from day one** — slice agent notes CI/CD in first story's brief when no pipeline exists; dev-grill folds pipeline setup into the tracer bullet
- **Doc maintenance** — signal-then-decide: micro-review collects `docHints` per phase, dev-workflow aggregates post-completion, human acts. Avoids both staleness (manual-only) and cost waste (auto-update every change)
- **Structured story fields** — schema enforcement + `plan-output.schema.json` `files[]` at task level. Stronger than GH issue templates (enforced gate vs. suggestion). File ownership deferred to [roadmap](docs/roadmap.md).
- **Lift vs. drag measurement** — comparison protocol in `docs/metrics.md` with `treatment` field in schema. Baseline data collecting (1/3 PO runs).

### Philosophical Differences (intentional)

| Dimension | Agentic-Agile Template | StolenAi |
|-----------|----------------------|-----------|
| Tracker | GitHub Issues + Projects | Azure DevOps (enterprise) |
| Agent autonomy | Agents earn autonomy, eventually create issues | Conservative — agents never touch ADO directly (see `docs/governance.md` § Graduated Agent Autonomy for future tiers) |
| MCP | Off-the-shelf `mcp.json` (github, filesystem, memory) | No MCP wired in scripts/agents. Skills may use Microsoft Learn + Context7 MCPs in-session for docs/library lookups. Custom MCP excluded for PoC (Decision 18) |
| Spec location | Spec lives in the issue | PO brief → ADO attachment (handoff mechanism); dev spec → git only + ADO discussion comment for visibility. Future considerations in `docs/roadmap.md` |

### Manifesto Values Mapping (5 values)

| Value | StolenAi Status |
|---|---|
| V1 Specs/contracts over open-ended prompts | ✅ Grill-first + JSON schemas (`schemas/`) |
| V2 Human-agent partnership over one-directional delegation | ✅ Human checkpoints at script/AI boundary |
| V3 Parallel independence over sequential handoffs | Partial — DAG phases *within* a story; cross-story parallelism by independent devs not yet addressed (see P3 below) |
| V4 Built-in governance over bolted-on compliance | ✅ `docs/governance.md` standalone policy |
| V5 Continuous measurement over post-hoc assessment | Partial — `docs/metrics.md` defines protocol; no baseline data yet |

### Assessment

**StolenAi is a more opinionated, production-targeted implementation** of the same philosophy the Agentic-Agile template describes. The template is a *framework* (placeholder docs, fill-in-the-blanks); StolenAi is a *system* (working scripts, schemas, tested flows).

**Concrete advantages over the template:**
1. Machine-verifiable contracts (JSON schemas) vs. their markdown conventions
2. Cost-conscious architecture (no tokens on CRUD) vs. no cost discussion in theirs
3. Actual working automation vs. template placeholders
4. ADO integration for real enterprise teams vs. GitHub-only
5. Enforced human checkpoints via architecture (script/AI boundary) vs. process suggestion
6. Feedback/revision loop for slice refinement — template has no equivalent

### AX Stack Relevance (May 2026)

From [The AX Stack: What's Fixed, Where You Can Win](https://developer.microsoft.com/blog/the-ax-stack-whats-fixed-where-you-can-win) (Waldek Mastykarz):

| AX Concept | StolenAi Status |
|---|---|
| Zero-sum context window | Addressed — progressive disclosure keeps skills minimal |
| Discovery | Baseline coverage via agentskills.io frontmatter triggers; not measured |
| Selection | Skill/agent separation is structural; not measured whether the correct surface is invoked per task |
| Quality (lift vs. drag) | Protocol designed in `docs/metrics.md` (`treatment` field in schema); awaiting ≥3 runs for baseline. **Not yet addressed in practice.** |
| Composition | Skills/agents run alongside Copilot built-ins + any user-installed plugins. Risk applies today, not just at scale — unmeasured. |

### Not Yet Addressed

Gaps from the manifesto and template worth tracking:

- **P3 (parallel partnerships across multiple humans+agents)** — StolenAi is single-developer-with-agents. The template assumes a *team* of humans each running their own agentic swarms in the same codebase. Cross-developer coordination (file ownership across concurrent stories) is out of scope today.
- **P10 (autonomy earned through evidence)** — `docs/governance.md` describes graduated autonomy tiers, but there is no measurement-gated promotion path. Promotions are currently manual/policy-driven, not evidence-driven.
- **P13 (budget for the full cycle)** — `plan-output.schema.json` tracks implementation tasks; it does not separately budget review, rework, or integration time. Micro-review + retros imply this but don't quantify it.
- **CI/CD as Story 1** — Template makes this a mandate ("validation infrastructure is the first story implemented, not the last"). StolenAi's slice agent *suggests* CI/CD when no pipeline exists — softer enforcement. Consider promoting to a slice-time hard check.
- **Originating Prompt capture** — Template's issue template has an explicit field for the originating human prompt to feed retros. StolenAi doesn't capture this. Easy add to `fetch-story.ps1` brief or the grill summary.
- **Per-model instruction splits (CLAUDE.md / STYLE.md)** — Template ships separate files for Claude vs Copilot vs style conventions. StolenAi has one `copilot-instructions.md`. Fine for the PoC's single-model assumption; revisit when expanding model coverage.
- **8-dimension evaluation framework** — Template's `docs/evaluation-framework.md` uses 8 dimensions; `docs/metrics.md` uses 4 (first-pass acceptance, rework cycles, grill efficiency, escaped defects). Either document why 4 is sufficient for PoC, or close the gap.
