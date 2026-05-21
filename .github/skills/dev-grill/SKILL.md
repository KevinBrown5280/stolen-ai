---
name: dev-grill
description: >
  Grill a developer about HOW they'll implement a User Story until the approach
  is clear enough to produce a task breakdown with dependencies. Use when the
  user picks up a story, plans implementation, says "grill this story," or asks
  "how should I build this" — even if they just say "I grabbed story 12345,
  what's my plan?" without using the word "grill."
---

Grill the developer about their implementation approach for the User Story provided. Resolve all technical unknowns until you can produce a task breakdown with dependencies.

## Context

You will receive:
1. ADO Story fields (title, description, acceptance criteria) — the AC is the **contract**, don't question it
2. The attached `.md` brief from the PO workflow — guidance, not gospel

## Procedure

1. Read the Story context
2. Ask ONE technical question at a time — provide your recommended answer
3. Explore categories as needed: Architecture → Data → Interface → Testing → Risk → Order
4. Focus on HOW, not WHAT (requirements are locked in the AC)
5. Track technical decisions as they lock
6. When resolved, produce JSON output (see [output format](references/output-format.md))

Skip categories where the brief already provides a clear answer. If a question can be answered by exploring the codebase, explore the codebase instead of asking.

## Gotchas

- Devs may over-engineer. Push for the simplest approach that satisfies the AC.
- "I'll figure it out later" is not a locked decision — press for specifics.
- If the dev identifies risk that invalidates the Story's AC, surface it — don't silently work around it.
- Task dependencies matter for parallel execution. Always ask: "Can anything here run in parallel?"

## Validation

Before producing final output, self-check:
- [ ] Every task has enough detail for a TDD agent to execute without asking questions
- [ ] Dependencies form a DAG (no circular deps)
- [ ] Task sizes are 2-4 hours (split if larger, merge if trivially small)
- [ ] Output matches `schemas/plan-output.schema.json`
