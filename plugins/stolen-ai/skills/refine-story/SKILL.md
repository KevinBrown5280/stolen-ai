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
2. Read `docs/glossary.md` from the workspace root to load the shared vocabulary
3. Read the Story context
4. Ask ONE technical question at a time — provide your recommended answer
5. Explore categories as needed: Architecture → Data → Interface → Build/Deploy → Testing → Risk → Dependencies → Order
6. Focus on HOW, not WHAT (requirements are locked in the AC)
7. Track technical decisions as they lock
8. When resolved, produce JSON output (see [output format](references/output-format.md))

## Glossary Maintenance

During grilling, when a new domain term is resolved or an existing term's meaning is clarified:
- Challenge the user if they use a term that conflicts with the glossary ("The glossary defines X as Y, but you seem to mean Z — which is it?")
- When a new term is locked, update `docs/glossary.md` inline — add the term to the table immediately, don't batch
- When an existing term's definition is sharpened, update it in place
- Only add terms specific to this project's domain — not general programming concepts

**Entry format** (append to the existing table):
```
| **Term** | One-sentence definition. Context on when/where it applies. |
```
Rules:
- Bold the term name
- Definition is one sentence max — define what it IS, not what it does
- If a synonym should be avoided, append: `(avoid: X, Y)`
- Keep alphabetical order within the table
- If the new term relates to existing terms, add a line to `## Relationships` showing direction and cardinality
- If the term was ambiguous and got resolved, add an entry to `## Flagged Ambiguities` documenting the confusion and resolution

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
- [ ] Output matches `$PLUGIN_ROOT/schemas/plan-output.schema.json`
