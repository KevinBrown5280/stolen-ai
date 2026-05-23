---
name: tdd
description: >
  Red-green-refactor TDD loop integrated with the plan-story task plan.
  Accepts a task's description and testStrategy from the plan output and
  drives implementation through vertical slices. Use when executing a task
  that has automated tests in its testStrategy.
attribution: >
  Based on TDD principles from Matt Pocock's AI Hero (aihero.dev).
  Adapted for plan-story integration.
---

# Test-Driven Development (Plan Story)

## Entry Point

You receive a **task** from the plan-story plan (`../../schemas/plan-output.schema.json`, relative to this file):

```json
{
  "id": "task-id",
  "title": "...",
  "description": "What to build and how",
  "testStrategy": "What behaviors to test and how",
  "dependsOn": []
}
```

- `description` = implementation spec (WHAT to build). This is locked — don't expand scope.
- `testStrategy` = behaviors to verify (WHAT to test). These are your test cases.

**The planning phase is already complete.** Interface decisions, approach, and scope were locked during refine-story. Begin at the Tracer Bullet step.

## Philosophy

**Tests verify behavior through public interfaces, not implementation details.**

- Good tests exercise real code paths through public APIs
- Good tests survive refactors — they don't care about internal structure
- If you rename an internal function and tests fail, those tests were testing implementation

## Anti-Pattern: Horizontal Slices

**DO NOT write all tests first, then all implementation.**

```
WRONG (horizontal):
  RED:   test1, test2, test3, test4, test5
  GREEN: impl1, impl2, impl3, impl4, impl5

RIGHT (vertical):
  RED→GREEN: test1→impl1
  RED→GREEN: test2→impl2
  RED→GREEN: test3→impl3
```

Each test responds to what you learned from the previous cycle.

## Workflow

### 1. Derive Behaviors from testStrategy

Parse the task's `testStrategy` into discrete behaviors to test. Each becomes one RED→GREEN cycle. Order them from simplest/most foundational to most complex.

### 2. Tracer Bullet (First Behavior)

```
RED:   Write ONE test for the first behavior → test fails
GREEN: Write minimal code to pass → test passes
```

This proves the path works end-to-end.

### 3. Incremental Loop (Remaining Behaviors)

For each remaining behavior from the testStrategy:

```
RED:   Write next test → fails
GREEN: Minimal code to pass → passes
```

Rules:
- One test at a time
- Only enough code to pass current test
- Don't anticipate future tests
- Keep tests focused on observable behavior

### 4. Refactor

After all tests pass:
- [ ] Extract duplication
- [ ] Deepen modules (see [references/deep-modules.md](references/deep-modules.md))
- [ ] Run tests after each refactor step

**Never refactor while RED.** Get to GREEN first.

### 5. Report Completion

When all behaviors from `testStrategy` pass, report:
- Files changed
- Tests added (count + names)
- Any risks or observations for micro-review

## Mocking Rules

Mock at **system boundaries** only:
- External APIs, databases, time/randomness, file system

Do NOT mock:
- Your own classes/modules
- Internal collaborators
- Anything you control

Use dependency injection at boundaries to enable mockability (see [references/mocking.md](references/mocking.md)).

## Scope Boundaries

- Only modify files/interfaces mentioned in the task `description`
- If you discover the task description is insufficient, STOP and report back — don't expand scope
- If a test reveals a design flaw in the plan, surface it — don't silently work around it
