# Inspirations & Alignment

External influences on StolenAi's design, and how the system relates to each.

## Sources

- [Burke Holland's orchestrator pattern](https://gist.github.com/burkeholland/0e68481f96e94bbb98134fa6efd00436) — sub-agent delegation, parallel phases, never implements itself
- [Matt Pocock's skills](https://github.com/mattpocock/skills) — grill-me, tdd, write-a-skill patterns
- [AI Hero (aihero.dev)](https://www.aihero.dev/) — [5 agent skills I use every day](https://www.aihero.dev/5-agent-skills-i-use-every-day), [video walkthrough](https://www.youtube.com/watch?v=-QFHIoCo-Ko)
- [GitHub Spec Kit](https://github.com/github/spec-kit) — spec → plan → tasks pipeline
- [Awesome Copilot](https://awesome-copilot.github.com/) — curated patterns and extensions
- [Agentic-Agile: Why Agent Development Needs Agile (Not Just Prompts)](https://developer.microsoft.com/blog/agentic-agile-why-agent-development-needs-agile-not-just-prompts) — Daniel Epstein (Microsoft PTS)
- [Agentic-Agile Manifesto](https://github.com/microsoft/agentic-agile-template/blob/main/MANIFESTO.md) — 5 values, 13 principles
- [microsoft/agentic-agile-template](https://github.com/microsoft/agentic-agile-template) — starter repo with agent context files, issue templates, docs
- [The AX Stack: What's Fixed, Where You Can Win](https://developer.microsoft.com/blog/the-ax-stack-whats-fixed-where-you-can-win) — Waldek Mastykarz (Agent Experience measurement: discovery, selection, quality, composition, lift vs. drag)
- [agentskills.io](https://agentskills.io/) — open standard for portable skills (VS Code, VS 2026, CLI, Cursor, Claude Code)

## What We Took From Each

| Source | What StolenAi adopted | Where it lives |
|--------|----------------------|----------------|
| Burke Holland | Orchestrator never implements; sub-agent delegation; parallel phases | `plan-story.agent.md`, `plan-feature.agent.md` |
| Matt Pocock | Grill-first pattern; TDD skill structure; write-a-skill conventions | `refine-feature`, `refine-story`, `tdd` skills |
| AI Hero | Skill as progressive-disclosure unit; daily-use skill design | All SKILL.md files |
| GitHub Spec Kit | Spec → plan → tasks pipeline; spec as persistent artifact | `persist-plan.ps1`, `specs/` directory |
| Awesome Copilot | Community patterns for agent/skill discovery | README structure, skill triggers |
| Agentic-Agile | Values, principles, evaluation framework, story structure | See [Agentic-Agile Alignment](#agentic-agile-alignment) below |
| AX Stack | Discovery/selection/quality/composition measurement lens | `docs/metrics.md` lift-vs-drag protocol |
| agentskills.io | Portable skill format (frontmatter, triggers, references/) | All skills comply with the open spec |

## Agentic-Agile Alignment

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
- **CI/CD from day one** — slice agent notes CI/CD in first story's brief when no pipeline exists; refine-story folds pipeline setup into the tracer bullet
- **Doc maintenance** — signal-then-decide: micro-review collects `docHints` per phase, plan-story aggregates post-completion, human acts. Avoids both staleness (manual-only) and cost waste (auto-update every change)
- **Structured story fields** — schema enforcement + `plan-output.schema.json` `files[]` at task level. Stronger than GH issue templates (enforced gate vs. suggestion). File ownership deferred to [roadmap](docs/roadmap.md).
- **Lift vs. drag measurement** — comparison protocol in `docs/metrics.md` with `treatment` field in schema. Baseline data collecting (1/3 PO runs).

## Philosophical Differences (intentional)

| Dimension | Agentic-Agile Template | StolenAi |
|-----------|----------------------|-----------|
| Tracker | GitHub Issues + Projects | Azure DevOps (enterprise) |
| Agent autonomy | Agents earn autonomy, eventually create issues | Conservative — agents never touch ADO directly (see `docs/governance.md` § Graduated Agent Autonomy for future tiers) |
| MCP | Off-the-shelf `mcp.json` (github, filesystem, memory) | No MCP wired in scripts/agents. Skills may use Microsoft Learn + Context7 MCPs in-session for docs/library lookups. Custom MCP excluded for PoC (Decision 18) |
| Spec location | Spec lives in the issue | PO brief → ADO attachment (handoff mechanism); dev spec → git only + ADO discussion comment for visibility. Future considerations in `docs/roadmap.md` |

## Manifesto Values Mapping (5 values)

| Value | StolenAi Status |
|---|---|
| V1 Specs/contracts over open-ended prompts | ✅ Grill-first + JSON schemas (`schemas/`) |
| V2 Human-agent partnership over one-directional delegation | ✅ Human checkpoints at script/AI boundary |
| V3 Parallel independence over sequential handoffs | ✅ DAG phases within a story (sub-agent parallelism) + cross-developer coordination via ADO assignment, file ownership in stories, and git branches |
| V4 Built-in governance over bolted-on compliance | ✅ `docs/governance.md` standalone policy |
| V5 Continuous measurement over post-hoc assessment | Partial — `docs/metrics.md` defines protocol; no baseline data yet |

## Assessment

**StolenAi is a more opinionated, production-targeted implementation** of the same philosophy the Agentic-Agile template describes. The template is a *framework* (placeholder docs, fill-in-the-blanks); StolenAi is a *system* (working scripts, schemas, tested flows).

**Concrete advantages over the template:**
1. Machine-verifiable contracts (JSON schemas) vs. their markdown conventions
2. Cost-conscious architecture (no tokens on CRUD) vs. no cost discussion in theirs
3. Actual working automation vs. template placeholders
4. ADO integration for real enterprise teams vs. GitHub-only
5. Enforced human checkpoints via architecture (script/AI boundary) vs. process suggestion
6. Feedback/revision loop for slice refinement — template has no equivalent

## AX Stack Relevance

From [The AX Stack: What's Fixed, Where You Can Win](https://developer.microsoft.com/blog/the-ax-stack-whats-fixed-where-you-can-win) (Waldek Mastykarz):

| AX Concept | StolenAi Status |
|---|---|
| Zero-sum context window | Addressed — progressive disclosure keeps skills minimal |
| Discovery | Baseline coverage via agentskills.io frontmatter triggers; not measured |
| Selection | Skill/agent separation is structural; not measured whether the correct surface is invoked per task |
| Quality (lift vs. drag) | Protocol designed in `docs/metrics.md` (`treatment` field in schema); awaiting ≥3 runs for baseline. **Not yet addressed in practice.** |
| Composition | Skills/agents run alongside Copilot built-ins + any user-installed plugins. Risk applies today, not just at scale — unmeasured. |

## Principle Dispositions

All manifesto principles have been dispositioned:

- **P3 (parallel partnerships across multiple humans+agents)** — ✅ Addressed. Intra-story: sub-agents run in parallel within DAG waves. Cross-developer: multiple devs each run the workflow independently on their assigned stories; conflicts prevented by slice agent's file ownership + ADO story assignment + git branches. No special coordination layer needed — existing tooling handles it.
- **P10 (autonomy earned through evidence)** — ✅ Intentional divergence. StolenAi's architecture enforces human-as-gatekeeper by design (script/AI boundary). Automated evidence-gated promotion toward autonomous ADO writes is not a goal — the conservative governance stance is a feature, not a gap to close. Metrics data will naturally inform *manual* decisions about loosening guardrails if/when trust warrants it.
- **P13 (budget for the full cycle)** — ✅ Addressed architecturally. The full cycle (review, rework, integration) is *executed and measured*, not pre-estimated. Micro-review = review, drift-pause = rework, persist-plan = integration. `durationMinutes` in metrics captures actual wall-clock for the whole cycle. An AI-generated pre-estimate adds no signal (it would be `taskCount × constant` with no velocity data) — actuals are more valuable than fabricated estimates.
- **CI/CD as Story 1** — ✅ Addressed differently. Template mandates a hard check at slice time (greenfield assumption). StolenAi uses two-layer enforcement: slice agent suggests when no pipeline detected (soft, lacks repo context) → refine-story enforces via tracer bullet (hard, has full codebase visibility). Enforcement at the phase with actual context is more reliable than a blind mandate at slice time.
- **Originating Prompt capture** — ✅ N/A. Template captures freeform prompts because that's their only trigger context. StolenAi's trigger is a structured ADO ID; the grill summary already captures all human-supplied clarification beyond what ADO contains — stronger provenance than a raw prompt.
- **Per-model instruction splits (CLAUDE.md / STYLE.md)** — ✅ Addressed. CLAUDE.md irrelevant (Microsoft shop). STYLE.md is a coding conventions template but nothing auto-loads it — only `copilot-instructions.md` is natively consumed by VS Code Copilot. Target repos own their own conventions via their `copilot-instructions.md`; StolenAi doesn't need to prescribe style. Refine-story now warns if target repo lacks a `copilot-instructions.md` (added as pre-check step 1 in refine-story SKILL.md).
- **8-dimension evaluation framework** — ✅ Resolved. Template's 8 dimensions covered by StolenAi's 4 dimensions + `durationMinutes` + architectural invariants. Rationale documented in `docs/metrics.md` § Dimension Coverage Rationale. Decomposition effectiveness added as slice-time validation rule in `slice.agent.md`.
