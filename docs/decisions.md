# Locked Design Decisions

Numbered decisions that are **settled** — revisiting requires explicit justification.

| # | Decision | Choice | Rationale |
|---|----------|--------|-----------|
| 1 | Trigger | Human invokes CLI command | No automation/webhooks for PoC |
| 2 | Input | Existing ADO Feature ID (plan-feature) or Story ID (plan-story) | Features already exist in ADO |
| 3 | Grill mandatory | Always grill before slicing | ADO items are typically sparse |
| 4 | Artifact model | Stories ARE the specs (no monolithic spec file) | Each story is self-contained |
| 5 | PO output | Stories in ADO + attached .md brief per story | ADO scannable, .md has depth |
| 6 | Dev output | Discussion thread on Story + local spec files (`spec.json` + `spec.readme.md`) | ADO Tasks too noisy |
| 7 | Spec location | `specs/{feature}/{storyId}.md` — one file per Story | Cross-session continuity for AI |
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
