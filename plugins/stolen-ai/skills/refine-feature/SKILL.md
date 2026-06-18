---
name: refine-feature
description: >
  Sharpen a vague ADO Feature into slice-ready clarity through relentless
  one-at-a-time questioning. Use when the user provides a Feature ID and wants
  to refine it, prepare for story slicing, resolve ambiguity, or says "refine
  this feature" — even if they just say "I need to break this down" or "help me
  think through this Feature" without using the word "refine."
---

Grill the user about the ADO Feature they provide until every branch of ambiguity is resolved. Produce a structured summary that the Slice agent can consume directly.

## Procedure

1. Read `docs/glossary.md` from the workspace root to load the shared vocabulary
   - If the file does not exist, skip — the workspace may not have established a shared vocabulary yet.
2. Read the Feature description (may be sparse or vague)
3. Before asking anything, do a focused reconnaissance pass over the workspace for evidence that answers the next category already
  - Check the most likely local sources first: `docs/decisions.md`, `docs/roadmap.md`, workflow docs under `plugins/stolen-ai/docs/`, related agents/skills/scripts under `plugins/stolen-ai/`, and any nearby specs or templates that govern the same surface.
  - Prefer concrete repo evidence over asking the user to guess how the system works.
4. Ask ONE question at a time — explain why you need it, provide your recommended answer
5. Walk categories in order: Users → Value → Scope → Behavior → Dependencies → Constraints
6. Track decisions as they lock — never revisit a locked decision unless the user asks
7. When all branches resolve, output the summary (see [output format](references/output-format.md))

## Evidence-First Grilling

Before each question:
- Ask yourself whether the answer is already in the codebase, docs, scripts, templates, or prior spec artifacts. If yes, read that evidence instead of asking.
- When you do ask, anchor the question in what you found: "I found `<file/path>` suggesting `<behavior>`. Is that still the intended direction?"
- If docs, code, or templates disagree, surface the contradiction explicitly and resolve it before moving on.
- If you still lack enough evidence after a focused scan, ask the narrowest question that unlocks the next decision.

When the Feature implies behavior, dependencies, or scope boundaries:
- Stress-test them with concrete scenarios, especially edge cases and exclusions.
- Distinguish between current behavior, desired future behavior, and assumptions hiding in the wording.
- Treat "we probably do X" as unresolved until supported by repo evidence or user confirmation.

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

Skip categories where the Feature description already provides a clear answer. If a question can be answered by exploring the codebase, explore the codebase instead of asking.

If the user states how something works and the repo evidence disagrees, call that out directly: "The repo currently does X in `<path>`, but you just described Y. Which should the workflow treat as authoritative?"

## Gotchas

- ADO Features are often just a title + one sentence. Don't assume context — ask.
- Broad "what do you want?" questions are low value. Narrow them using what the repo already tells you.
- POs may not know technical constraints. Frame questions in business terms.
- Features often inherit constraints from existing workflow scripts, agent contracts, or templates. Check those before inventing new behavior.
- "Out of scope" decisions are as valuable as "in scope" — always ask what's excluded.
- Don't batch questions. One at a time. Always.

## Validation

Before producing final output, self-check:
- [ ] I searched the workspace before asking questions whose answers may already exist locally
- [ ] Any contradiction between user statements and repo evidence was surfaced and resolved or captured as unresolved
- [ ] Every acceptance scenario has a clear pass/fail condition
- [ ] Scope has both "in" and "out" explicitly stated
- [ ] No decision references another undecided item
- [ ] Output matches the format in [references/output-format.md](references/output-format.md)
