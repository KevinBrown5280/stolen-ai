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

**Read [the grilling protocol](../../docs/grilling-protocol.md) first.** It defines the shared turn rules (one question per message, with a recommendation), evidence-first questioning, the rewrite-in-place decision record, and glossary maintenance. This skill adds Story-specific technical categories below.

## Context

You will receive:
1. ADO Story fields (title, description, acceptance criteria) — the AC is the **contract**, don't question it
2. The attached `.md` brief from the PO workflow — guidance, not gospel

## Procedure

1. **Pre-check:** Look for `copilot-instructions.md` or `.github/copilot-instructions.md` in the workspace root. If absent, warn: "This repo has no copilot-instructions.md — the agent won't know codebase conventions (naming, patterns, formatting). Consider creating one before implementation begins."
2. Load the shared vocabulary per the protocol's Glossary Maintenance section
3. Read the Story context
4. Before asking anything, do a focused reconnaissance pass over the owning surface
  - Read the files most likely to decide the behavior: the attached brief, nearby agents/skills/scripts, relevant docs under `docs/` and `plugins/stolen-ai/docs/`, existing specs, tests, and any build/deploy files that constrain the implementation.
  - If the Story touches an existing feature area, inspect the current implementation and tests before asking the developer to describe it from memory.
5. Ask ONE technical question at a time — provide your recommended answer
6. Explore categories as needed: Architecture → Data → Interface → Reuse → Design → Build/Deploy → Testing → Risk → Dependencies → Order
7. Focus on HOW, not WHAT (requirements are locked in the AC)
8. Track technical decisions as they lock, rewriting the decision record in place
9. When resolved, produce JSON output (see [output format](references/output-format.md))

Skip categories where the brief already provides a clear answer. Cross-check developer claims about current behavior against the codebase; if they disagree, force the contradiction into the open.

## Reuse Category

Before locking the approach, explore the codebase for existing shared components, styles, hooks, utilities, or patterns that cover (or partially cover) this work. Do the exploration yourself — don't outsource it to the dev as a question they'll answer with a guess.

Also inspect adjacent tests and prior specs for the same surface. Reuse is not just code reuse — it includes established expectations, naming, failure handling, and deployment patterns.

Then ask, one at a time as relevant:

1. **Existing match?** "I found `<component/util/style>` at `<path>` that does `<X>`. Use it as-is?"
2. **Near match — extend or fork?** "`<thing>` is close but missing `<Y>`. Extend it (and own the regression risk for current consumers) or fork a variant?"
3. **New but reusable?** "Nothing exists for this. Will this be reused elsewhere? If yes, build it in `<shared location>` from day one rather than inline."
4. **Consistency drift?** "This Story introduces a `<button/modal/form/color/spacing>` pattern. Does it match what's already used in `<adjacent surface>`? If not, align or document the deliberate divergence."

Lock the answers as decisions. If a shared component must be extracted or extended, that becomes its own task (often a dependency of the consuming tasks) — not a side-effect of another task. If a new shared location is being established, name it in the decisions so `slice-feature` and `code-story` honor it.

## Design Category

For any Story that touches UI, resolve the visual contract before locking the approach.

Before asking design questions, inspect the existing UI surface for nearby components, states, and interaction patterns so the discussion starts from evidence rather than taste.

1. **Design artifact?** "Is there a Figma link (or other design spec) for this work?" If found in the Story, brief, or parent Feature, lock it as a binding decision. If absent for a UI story, ask the dev: will they design it, or should planning block until a design exists?
2. **Visual contract type?** "Is this pixel-perfect to the design, or functional-match (layout and behavior correct, exact styling flexible)?" Lock the expectation.
3. **Interaction states?** "What states must be rendered? Default, empty, loading, error, success, disabled, hover/focus?" Only ask for states not obvious from the design or AC.
4. **WCAG level?** Default is AA unless the team has declared otherwise. Confirm. For non-standard controls (custom dropdowns, date pickers, modals, drag-and-drop), name the ARIA pattern or library that handles accessibility.
5. **Responsive?** "Does this need to work at mobile/tablet/desktop breakpoints?" Lock which breakpoints matter or explicitly declare desktop-only.

If the dev's approach introduces custom UI controls, prefer an existing accessible library (Radix, Headless UI, etc.) over building from scratch — this is both a reuse and an accessibility decision.

## API/Library Verification

If the proposed approach introduces a library or external API not already used in the codebase, verify the API surface against live documentation before locking the decision. Check package manifests (package.json, .csproj, requirements.txt, etc.) — if the dependency isn't there, it's new. Use `mcp_context7_query-docs` or `fetch` to confirm that methods, signatures, and patterns actually exist in the current version.

If the repo already uses that dependency elsewhere, inspect the existing call sites first and prefer the established local pattern unless there is a concrete reason to diverge.

## Testing Category

Agree the test seams during the grill, before code-story writes tests:
- Name the public interface each task will exercise and the observable AC behavior it proves. Include relevant failure cases and affected existing consumers, not tests of private methods or internal call counts.
- Inspect the repo's test/build/lint commands and nearby tests. Put the actual targeted command and test file paths in `testStrategy` and `files`; do not invent a runner or mandate a full suite by default.
- For a bug fix, specify a regression that fails on the original symptom. Expected results come from the AC or independent fixtures, not a copy of the implementation.
- If automation is impractical, start `testStrategy` with "Manual" and give a reproducible procedure with an explicit pass/fail condition. Identify any check that requires human access.
- Include new test/fixture files in task ownership. Identify shared mutable resources such as migrations, generated files, or build outputs; require sequential execution unless independence is proven.

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
- Do not accept "I think" or "probably" for current-state questions when the repo can answer them.
- "I'll figure it out later" is not a locked decision — press for specifics.
- Planning quality drops fast when contradictions stay implicit. Surface them immediately.
- If the dev identifies risk that invalidates the Story's AC, surface it — don't silently work around it.
- Don't hide uncertainties. If something can't be fully resolved during the grill (needs DBA input, vendor confirmation, etc.), capture it in `openQuestions` in the output — don't silently drop it or pretend it's decided.
- Task dependencies matter for parallel execution. Always ask: "Can anything here run in parallel?"

## Validation

Before producing final output, self-check:
- [ ] I inspected the owning code/docs/tests/pipeline surface before asking questions the repo could answer
- [ ] I asked one question per message and kept the decision record rewritten in place (no Q&A log in the output)
- [ ] Any contradiction between the brief, code, tests, docs, or developer statements was surfaced and resolved or captured in `openQuestions`
- [ ] Every task has enough detail for a TDD agent to execute without asking questions
- [ ] Each testStrategy names an agreed public interface, observable result, and runnable command or manual procedure; test/fixture ownership and shared mutable resources are accounted for
- [ ] Dependencies form a DAG (no circular deps)
- [ ] Task sizes are 2-4 hours (split if larger, merge if trivially small)
- [ ] Reuse opportunities surfaced — shared components/styles/utilities either leveraged, extended (as their own task), or consciously rejected with rationale captured in `decisions`
- [ ] Output matches `$PLUGIN_ROOT/schemas/spec-output.schema.json`
