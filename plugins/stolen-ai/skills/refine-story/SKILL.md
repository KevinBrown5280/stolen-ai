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
   - If the file does not exist, skip — the workspace may not have established a shared vocabulary yet.
3. Read the Story context
4. Ask ONE technical question at a time — provide your recommended answer
5. Explore categories as needed: Architecture → Data → Interface → Reuse → Design → Build/Deploy → Testing → Risk → Dependencies → Order
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

## Reuse Category

Before locking the approach, explore the codebase for existing shared components, styles, hooks, utilities, or patterns that cover (or partially cover) this work. Do the exploration yourself — don't outsource it to the dev as a question they'll answer with a guess.

Then ask, one at a time as relevant:

1. **Existing match?** "I found `<component/util/style>` at `<path>` that does `<X>`. Use it as-is?"
2. **Near match — extend or fork?** "`<thing>` is close but missing `<Y>`. Extend it (and own the regression risk for current consumers) or fork a variant?"
3. **New but reusable?** "Nothing exists for this. Will this be reused elsewhere? If yes, build it in `<shared location>` from day one rather than inline."
4. **Consistency drift?** "This Story introduces a `<button/modal/form/color/spacing>` pattern. Does it match what's already used in `<adjacent surface>`? If not, align or document the deliberate divergence."

Lock the answers as decisions. If a shared component must be extracted or extended, that becomes its own task (often a dependency of the consuming tasks) — not a side-effect of another task. If a new shared location is being established, name it in the decisions so `slice-feature` and `code-story` honor it.

## Design Category

For any Story that touches UI, resolve the visual contract before locking the approach.

1. **Design artifact?** "Is there a Figma link (or other design spec) for this work?" If found in the Story, brief, or parent Feature, lock it as a binding decision. If absent for a UI story, ask the dev: will they design it, or should planning block until a design exists?
2. **Visual contract type?** "Is this pixel-perfect to the design, or functional-match (layout and behavior correct, exact styling flexible)?" Lock the expectation.
3. **Interaction states?** "What states must be rendered? Default, empty, loading, error, success, disabled, hover/focus?" Only ask for states not obvious from the design or AC.
4. **WCAG level?** Default is AA unless the team has declared otherwise. Confirm. For non-standard controls (custom dropdowns, date pickers, modals, drag-and-drop), name the ARIA pattern or library that handles accessibility.
5. **Responsive?** "Does this need to work at mobile/tablet/desktop breakpoints?" Lock which breakpoints matter or explicitly declare desktop-only.

If the dev's approach introduces custom UI controls, prefer an existing accessible library (Radix, Headless UI, etc.) over building from scratch — this is both a reuse and an accessibility decision.

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
- [ ] Reuse opportunities surfaced — shared components/styles/utilities either leveraged, extended (as their own task), or consciously rejected with rationale captured in `decisions`
- [ ] Output matches `$PLUGIN_ROOT/schemas/spec-output.schema.json`
