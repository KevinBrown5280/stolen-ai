---
name: refine-story
description: >
  Refine a developer's implementation approach for a User Story until the approach
  is clear enough to produce a task breakdown with dependencies. Use when the
  user picks up a story, plans implementation, says "refine this story," or asks
  "how should I build this" — even if they just say "I grabbed story 12345,
  what's my plan?" without using the word "refine."
---

Grill the developer about their implementation approach for the User Story provided. Resolve all technical unknowns until you can produce a task breakdown with dependencies.

## Context

You will receive:
1. ADO Story fields (title, description, acceptance criteria) — the AC is the **contract**, don't question it
2. The attached `.md` brief from the PO workflow — guidance, not gospel

## Procedure

1. **Pre-check:** Look for `copilot-instructions.md` or `.github/copilot-instructions.md` in the workspace root. If absent, warn: "This repo has no copilot-instructions.md — the agent won't know codebase conventions (naming, patterns, formatting). Consider creating one before implementation begins."
2. Read the Story context
3. Ask ONE technical question at a time — provide your recommended answer
4. Explore categories as needed: Architecture → Data → Interface → Build/Deploy → Testing → Risk → Dependencies → Order
5. Focus on HOW, not WHAT (requirements are locked in the AC)
6. Track technical decisions as they lock
7. When resolved, produce JSON output (see [output format](references/output-format.md))

Skip categories where the brief already provides a clear answer. If a question can be answered by exploring the codebase, explore the codebase instead of asking.

## API/Library Verification

If the proposed approach introduces a library or external API not already used in the codebase, verify the API surface against live documentation before locking the decision. Check package manifests (package.json, .csproj, requirements.txt, etc.) — if the dependency isn't there, it's new. Use `mcp_context7_query-docs` or `fetch` to confirm that methods, signatures, and patterns actually exist in the current version.

## Tracer Bullet Detection

During the **Dependencies** category, ask: "Does this Story touch any integration or architectural layer that hasn't been proven in this codebase before?" (e.g., new external API, new protocol, new infrastructure component.)

During the **Build/Deploy** category, determine: "Does this repo have an existing CI/CD pipeline that builds and deploys this code?" If not, pipeline setup is folded into the tracer bullet — it's not a separate task.

If a tracer bullet is needed:
- The plan's first task should be a tracer bullet — a thin end-to-end path proving connectivity through the unproven boundary
- If no CI/CD exists, the tracer bullet also sets up the pipeline (build + deploy of the minimal code it proves)
- All other tasks depend on it (DAG root)
- Its done criteria is "proof of round-trip" not "complete behavior"
- Describe it naturally in the task — no special schema field needed

## Gotchas

- Devs may over-engineer. Push for the simplest approach that satisfies the AC.
- "I'll figure it out later" is not a locked decision — press for specifics.
- If the dev identifies risk that invalidates the Story's AC, surface it — don't silently work around it.
- Don't hide uncertainties. If something can't be fully resolved during the grill (needs DBA input, vendor confirmation, etc.), capture it in `openQuestions` in the output — don't silently drop it or pretend it's decided.
- Task dependencies matter for parallel execution. Always ask: "Can anything here run in parallel?"

## Validation

Before producing final output, self-check:
- [ ] Every task has enough detail for a TDD agent to execute without asking questions
- [ ] Dependencies form a DAG (no circular deps)
- [ ] Task sizes are 2-4 hours (split if larger, merge if trivially small)
- [ ] Output matches `../../schemas/plan-output.schema.json` (relative to this file)
