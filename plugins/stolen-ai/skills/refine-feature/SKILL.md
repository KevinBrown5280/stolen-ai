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
2. Read the Feature description (may be sparse or vague)
3. Ask ONE question at a time — explain why you need it, provide your recommended answer
4. Walk categories in order: Users → Value → Scope → Behavior → Dependencies → Constraints
5. Track decisions as they lock — never revisit a locked decision unless the user asks
6. When all branches resolve, output the summary (see [output format](references/output-format.md))

## Glossary Maintenance

During grilling, when a new domain term is resolved or an existing term's meaning is clarified:
- Challenge the user if they use a term that conflicts with the glossary ("The glossary defines X as Y, but you seem to mean Z — which is it?")
- When a new term is locked, update `docs/glossary.md` inline — add the term to the table immediately, don't batch
- When an existing term's definition is sharpened, update it in place
- Only add terms specific to this project's domain — not general programming concepts

Skip categories where the Feature description already provides a clear answer. If a question can be answered by exploring the codebase, explore the codebase instead of asking.

## Gotchas

- ADO Features are often just a title + one sentence. Don't assume context — ask.
- POs may not know technical constraints. Frame questions in business terms.
- "Out of scope" decisions are as valuable as "in scope" — always ask what's excluded.
- Don't batch questions. One at a time. Always.

## Validation

Before producing final output, self-check:
- [ ] Every acceptance scenario has a clear pass/fail condition
- [ ] Scope has both "in" and "out" explicitly stated
- [ ] No decision references another undecided item
- [ ] Output matches the format in [references/output-format.md](references/output-format.md)
