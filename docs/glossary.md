# Glossary

Shared vocabulary for StolenAi. Use these terms precisely to prevent drift across skills, agents, scripts, and documentation.

| Term | Definition |
|------|-----------|
| **Grill** | Interactive questioning phase (via a skill) that fills gaps in a sparse ADO item and locks decisions before downstream work begins. Always mandatory before slice or plan. Invoked via the `refine-feature` or `refine-story` skills. |
| **Slice** | Decomposing a grilled Feature into independently deliverable User Stories with acceptance criteria, file ownership, and attached briefs. Performed by the `slice-feature` agent. |
| **Brief** | The `.md` document attached to each Story providing depth beyond ADO fields (context, constraints, edge cases). Generated at slice time; can be regenerated. |
| **Persist** | Atomic step that writes `spec.json` + `spec.readme.md`, commits to git, and posts an ADO discussion thread — all in one script invocation. |
| **Micro-review** | Autonomous post-task check that compares the diff against the approved spec. Produces structured findings. Runs after each TDD task completes. |
| **Drift** | When implementation diverges from the approved spec. May be intentional (spec was wrong) or accidental (missed constraint). Always pauses for human decision. |
| **Checkpoint** | Human approval gate before any external write (ADO post, git push, attachment). Architecturally enforced — scripts require explicit confirmation. |
| **Surface** | Execution context for a capability: **Skill** (interactive, in-session), **Agent** (autonomous, fresh context), or **Script** (deterministic, zero tokens). See `docs/agent-surface-selection.md`. |
| **Contract** | JSON Schema in `schemas/` defining the interface between AI output and script input. Both sides validate against it. |
| **DAG** | Directed acyclic graph of task dependencies produced during dev planning. Determines which tasks can run in parallel and which must be sequential. |
| **Orchestrator** | A top-level agent (e.g., `plan-feature`, `plan-story`) that coordinates the full pipeline — invoking skills, sub-agents, and scripts in sequence. |
| **po** | Metrics workflow identifier for the plan-feature pipeline (Product Owner flow). |
| **dev** | Metrics workflow identifier for the plan-story pipeline (Developer flow). |
| **Tracer Bullet** | A root task in a dev plan that proves end-to-end connectivity through an unproven architectural boundary before other tasks build on it. Always the DAG root — everything else depends on it. Expressed as a naturally-described task (no schema flag); refine-story surfaces it when a Story touches integrations or layers that haven't been proven yet. Plan-story concern only — not part of Feature slicing. |
| **DryRun** | Script execution mode that validates inputs and generates review artifacts without performing external writes. Always safe to run. |
| **Implementation Spec** | The task breakdown JSON (`spec.json`) produced by refine-story. Authoritative source of truth for code-story and micro-review. The Story's AC is the requirement; the spec is the program. |

## Relationships

- A **Feature** is decomposed into one or more **Stories** via a **Slice**
- A **Story** produces a **Brief** (attached .md) at slice time
- A **Story** is refined via a **Grill**, producing a **DAG** of tasks
- Each task in the **DAG** is implemented by a **code-story** agent
- Each completed task is checked by a **Micro-review**
- **Drift** is detected by **Micro-review** and resolved at a **Checkpoint**
- A **Contract** governs the boundary between an **Orchestrator** and a **Script**
- A **Tracer Bullet** is always the root of a **DAG**
- **Persist** consumes a **Contract**-validated JSON and performs the external write

## Flagged Ambiguities

- "Plan" was used to mean both the grill output (task breakdown JSON) and the act of running the workflow — resolved: the artifact is a "plan" (lowercase); the workflow is "plan-story" or "plan-feature" (hyphenated, refers to the orchestrator agent).
