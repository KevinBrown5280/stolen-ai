Read PLAN.md and README.md in C:\TeamCity\Git\StolenAi for full context.

This is an AI-assisted workflow system for ADO teams. The PO workflow has been tested step-by-step.

## ADO Details
- Org: wtw-bda-outsourcing-product
- Project: BenefitConnect

## Test the PO Workflow Pipeline

### 1. Test fetch-feature.ps1
```powershell
.\scripts\po-workflow\fetch-feature.ps1 -FeatureId 744719 -Org "wtw-bda-outsourcing-product" -Project "BenefitConnect"
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

---

## Agentic-Agile Comparison (May 2026)

Reviewed against:
- [Agentic-Agile: Why Agent Development Needs Agile (Not Just Prompts)](https://developer.microsoft.com/blog/agentic-agile-why-agent-development-needs-agile-not-just-prompts) — introductory blog post by Daniel Epstein (Microsoft PTS)
- [Agentic-Agile Manifesto](https://github.com/microsoft/agentic-agile-template/blob/main/MANIFESTO.md) — 5 values, 13 principles
- [microsoft/agentic-agile-template](https://github.com/microsoft/agentic-agile-template) — starter repo with agent context files, issue templates, docs

### Already Aligned / Ahead

- **Specs as control surface** (P1) — grill-first mandate locks specs before execution
- **Independent units** (P2) — slice agent produces stories with file ownership + AC
- **Human designs, agent executes, both review** (P4) — human checkpoint enforced architecturally (script/AI split)
- **Independent review** (P6) — micro-review after each TDD task
- **Waves not waterfalls** (P7) — DAG-based parallelism in dev workflow
- **Machine-verifiable contracts** — JSON schemas tighter than the template's markdown conventions
- **Cost discipline** — "AI = brain, scripts = hands" is concrete; template only discusses philosophically

### Gaps to Close

| Gap | What the template has | Action |
|-----|----------------------|--------|
| Agent context file | `CLAUDE.md`, `.github/copilot-instructions.md`, `STYLE.md` — persistent agent instructions | Add a `copilot-instructions.md` codifying design principles + conventions |
| Retrospectives | `docs/retrospective-template.md` — structured post-wave reflection | Add a retro mechanism (even lightweight) |
| Evaluation framework | 8 dimensions: escaped defects, rework rate, spec quality, autonomy progression | Pick 3-4 dimensions and start tracking |
| Governance as policy | Safety constraints documented as standalone architecture | Extract from PLAN.md decisions into a dedicated doc |
| Epic decomposition guide | `docs/epic-decomposition-example.md` | Document slice patterns for onboarding |
| Agent surface selection | When to use CLI vs IDE vs chat vs cloud | Document the skill=interactive / agent=autonomous decision |
| Shared vocabulary | Explicit glossary preventing drift (P11) | Define "grill," "slice," "persist," "brief," "micro-review" for newcomers |
| Issue template | Structured fields: scope, file ownership, negative constraints | Consider an ADO work item template mirroring their `agentic-story.md` |

### Philosophical Differences (intentional)

| Dimension | Agentic-Agile Template | StolenAi |
|-----------|----------------------|-----------|
| Tracker | GitHub Issues + Projects | Azure DevOps (enterprise) |
| Agent autonomy | Agents earn autonomy, eventually create issues | Conservative — agents never touch ADO directly |
| Parallelism | Wave-based swarming (multiple agents, separate branches) | DAG-based sequential + parallel where deps allow |
| CI/CD | First story built; governance from day one | Not addressed (PoC scope) |
| Doc maintenance | Agents required to update docs every change | Manual |
| MCP | `mcp.json` included | Explicitly excluded for PoC (Decision 18) |

### Assessment

**StolenAi is a more opinionated, production-targeted implementation** of the same philosophy the Agentic-Agile template describes. The template is a *framework* (placeholder docs, fill-in-the-blanks); StolenAi is a *system* (working scripts, schemas, tested flows).

**Concrete advantages over the template:**
1. Machine-verifiable contracts (JSON schemas) vs. their markdown conventions
2. Cost-conscious architecture (no tokens on CRUD) vs. no cost discussion in theirs
3. Actual working automation vs. template placeholders
4. ADO integration for real enterprise teams vs. GitHub-only
5. Enforced human checkpoints via architecture (script/AI boundary) vs. process suggestion
6. Feedback/revision loop for slice refinement — template has no equivalent

**Biggest gaps to close (priority order):**
1. Add a `copilot-instructions.md` — codify design principles so any agent grounding on the repo immediately knows the rules
2. Add a retrospective mechanism — even a simple template run after each end-to-end test
3. Formalize measurement — pick 3-4 of their 8 dimensions (escaped defects, first-pass acceptance rate, rework rate) and track them
4. Document governance as policy — safety patterns are great but live only in PLAN.md decisions; extract to standalone doc agents can reference

### AX Stack Relevance (May 2026)

From [The AX Stack: What's Fixed, Where You Can Win](https://developer.microsoft.com/blog/the-ax-stack-whats-fixed-where-you-can-win) (Waldek Mastykarz):

| AX Concept | StolenAi Status |
|---|---|
| Zero-sum context window | Addressed — progressive disclosure keeps skills minimal |
| Discovery | Addressed — clear naming (`po-grill`, `slice`, `dev-grill`) + explicit frontmatter triggers |
| Selection | Addressed — skill/agent separation means correct tool type is invoked per task |
| Quality (lift vs. drag) | **Gap** — no before/after measurement proving skills improve outcomes |
| Composition | Low risk now (small set), relevant when scaling to other teams |

**Takeaway:** When formalizing measurement (gap #3 above), use the AX "lift vs. drag" framing — run same scenario with/without extensions, compare outcomes.
