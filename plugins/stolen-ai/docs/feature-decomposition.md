# Feature Decomposition Guide

How StolenAi slices Features into Stories. Reference for onboarding and for the `slice-feature` agent's decision-making.

## The Slicing Model

```
Feature (ADO)
  ↓ grill (fills gaps, locks scope)
  ↓ slice (applies patterns below)
  └── Story 1: Foundation / Config surface
  └── Story 2: Core mechanism
  └── Story 3: Integration / Trigger
  └── Story 4: End-to-end UX completion
  └── (Story 5: Ops/admin tooling — only if needed)
```

## Patterns

### Pattern 1: Config → Core → Integration → UX

**Use when:** Feature introduces a new capability that requires configuration, a processing engine, and a user-facing entry point.

| Slice | Purpose | Example (Feature 522809: Hartford EOI SSO) |
|-------|---------|---------------------------------------------|
| Config surface | Settings schema + validation | cm_settings for employment key, ACS URL, benefit triggers |
| Core mechanism | The engine that does the work | SAML 2.0 assertion generator (Hartford IdP class) |
| Integration trigger | Hooks core into existing workflow | To-do item generated after enrollment of eligible benefit |
| UX completion | End-to-end user experience works | Click to-do → SAML redirect → authenticated landing |

**Why this order:** Each slice is independently deployable and testable. Config can ship and be populated before core exists. Core can be unit-tested without integration. Integration can be tested with a stub. UX wires it all together.

### Pattern 2: Behavior → Data → Operations

**Use when:** Feature modifies existing behavior and needs data to support it, plus operational affordances.

| Slice | Purpose | Example (Feature 744719: Document History Exclusion) |
|-------|---------|------------------------------------------------------|
| Behavior change | Read config, apply new logic, fallback to old | Service reads cm_setting, filters docs, falls back to hard-coded |
| Data seeding | Populate config for existing clients | SQL migration seeds exclusion list for PPR clients |
| Ops tooling | Enable ongoing management without devs | Runbook + SQL template for support teams to update settings |

**Why this order:** Behavior ships first (with fallback, zero impact without data). Data activates it for existing clients. Ops enables self-service going forward.

### Pattern 3: Read → Write → React

**Use when:** Feature adds a new entity or data flow.

| Slice | Purpose |
|-------|---------|
| Read path | Display/query the new data (even if empty state) |
| Write path | Create/update the data |
| Reactive behavior | Side effects triggered by the data (notifications, workflows, etc.) |

### Pattern 4: Happy Path → Edge Cases → Error Handling

**Use when:** Feature has complex validation or failure modes that would bloat a single story.

| Slice | Purpose |
|-------|---------|
| Happy path | Core flow works for the standard case |
| Edge cases | Boundary conditions, unusual inputs, multi-state scenarios |
| Error/recovery | What happens when things go wrong; retry, rollback, user feedback |

**Use sparingly.** Prefer including basic error handling in the happy-path story. Only split if error handling is its own significant effort (e.g., retry with backoff, compensation transactions).

## Anti-Patterns (Don'ts)

| Anti-Pattern | Why It's Wrong | Instead |
|--------------|---------------|---------|
| Horizontal layers ("create DB schema", "build API", "build UI") | No story delivers user value alone | Vertical slices that touch all layers |
| "Setup" or "scaffolding" stories | Tech debt without value | Fold setup into the first story that needs it |
| One giant story | Unreviewed, undeliverable | Apply a pattern above |
| Mirror the architecture | Couples stories to implementation | Slice by user outcome |
| Stories that can't be demo'd | Not independently valuable | Each story has a "done looks like..." |

## Sizing Guardrails

- **Target:** 1–3 days per story for a single dev
- **Maximum:** 8 stories per Feature (if more are needed, the Feature itself should be split)
- **Minimum:** 2 stories (a single-story Feature is just a Story — reclassify it)

## How to Pick a Pattern

1. Does the Feature introduce **new config + new behavior + new UX**? → Pattern 1
2. Does it **modify existing behavior** with supporting data/ops? → Pattern 2
3. Does it add a **new data entity** with CRUD + side effects? → Pattern 3
4. Is the complexity in **error/edge handling** specifically? → Pattern 4
5. None fit perfectly? → Combine. Use Pattern 1's ordering logic with Pattern 2's slice boundaries.

## Relationship to Grill

The grill phase determines *what goes into* each slice by locking:
- Scope boundaries (what's in, what's out)
- Technical decisions (how it works)
- Edge cases to handle vs. defer

The slice phase then applies these patterns to determine *how many stories* and *what each one delivers*.
