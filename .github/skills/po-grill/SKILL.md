---
name: po-grill
description: >
  Sharpen a vague ADO Feature into slice-ready clarity through relentless
  one-at-a-time questioning. Use when the user provides a Feature ID and wants
  to refine it, prepare for story slicing, resolve ambiguity, or says "grill
  this feature" — even if they just say "I need to break this down" or "help me
  think through this Feature" without using the word "grill."
---

Grill the user about the ADO Feature they provide until every branch of ambiguity is resolved. Produce a structured summary that the Slice agent can consume directly.

## Procedure

1. Read the Feature description (may be sparse or vague)
2. Ask ONE question at a time — explain why you need it, provide your recommended answer
3. Walk categories in order: Users → Value → Scope → Behavior → Dependencies → Constraints
4. Track decisions as they lock — never revisit a locked decision unless the user asks
5. When all branches resolve, output the summary (see [output format](references/output-format.md))

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
