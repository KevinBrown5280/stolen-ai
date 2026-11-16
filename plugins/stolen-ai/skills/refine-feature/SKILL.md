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

**Read [the grilling protocol](../../docs/grilling-protocol.md) first.** It defines the shared turn rules (one question per message, with a recommendation), evidence-first questioning, the rewrite-in-place decision record, and glossary maintenance. This skill adds Feature-specific context below.

## Procedure

1. Load the shared vocabulary per the protocol's Glossary Maintenance section
2. Read the Feature description (may be sparse or vague)
3. Before asking anything, do a focused reconnaissance pass over the workspace for evidence that answers the next category already
  - Check the most likely local sources first: `docs/decisions.md`, `docs/roadmap.md`, workflow docs under `plugins/stolen-ai/docs/`, related agents/skills/scripts under `plugins/stolen-ai/`, and any nearby specs or templates that govern the same surface.
  - Prefer concrete repo evidence over asking the user to guess how the system works.
4. Ask ONE question at a time — explain why you need it, provide your recommended answer
5. Walk categories in order: Users → Value → Scope → Behavior → Dependencies → Constraints
6. Track decisions as they lock, rewriting the decision record in place
7. When all branches resolve, output the summary (see [output format](references/output-format.md))

Skip categories where the Feature description already provides a clear answer.

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
- [ ] I asked one question per message and kept the decision record rewritten in place (no Q&A log in the output)
- [ ] Any contradiction between user statements and repo evidence was surfaced and resolved or captured as unresolved
- [ ] Every acceptance scenario has a clear pass/fail condition
- [ ] Scope has both "in" and "out" explicitly stated
- [ ] No decision references another undecided item
- [ ] Output matches the format in [references/output-format.md](references/output-format.md)
