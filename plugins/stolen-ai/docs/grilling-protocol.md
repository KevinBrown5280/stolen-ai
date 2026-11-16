# Grilling Protocol

Shared rules for the `refine-feature` and `refine-story` skills. Each skill adds its own categories, context, and output format.

## Turn Rules

- **Exactly one question per message.** Never batch, even when questions seem related.
- Give your recommended answer with each question and say why the answer matters.
- Ask the narrowest question that unlocks the next decision.
- Never revisit a locked decision unless the user asks.

## Evidence-First

Before each question:
- Decide whether repo evidence (code, tests, docs, scripts, templates, prior specs, pipeline files) can answer it. If yes, read the evidence instead of asking.
- Anchor questions in what you found: "I found `<path>` doing `<behavior>`. Keep, extend, or replace?"
- When sources disagree (user, code, tests, docs, brief), surface the contradiction explicitly and resolve it before moving on — or record it as an open question.

Throughout:
- Separate current behavior, intended behavior, and assumptions. "We probably do X" stays unresolved until proven by evidence or confirmed by the user.
- Pressure-test with concrete scenarios: edge cases, exclusions, failure modes, state transitions, ownership, and integration boundaries.
- Do not ask the user to rediscover facts the repo already contains.

## Decision Record (rewrite, don't append)

- Keep one running decisions summary, organized by category. When a decision locks or sharpens, rewrite the relevant section in place.
- Never accumulate a Q&A log or a changelog of how a decision was reached. Downstream phases receive decisions, not the transcript.
- Unresolved items live in one open-questions list; remove them when resolved.

## Glossary Maintenance

Read `docs/glossary.md` from the workspace root before grilling. If it does not exist, skip glossary steps.

During grilling, when a new domain term is resolved or an existing term's meaning is clarified:
- Challenge conflicting usage: "The glossary defines X as Y, but you seem to mean Z — which is it?"
- If a term is absent from the glossary but clearly established elsewhere in the repo, read that usage before asking for a definition.
- When a new term is locked, update `docs/glossary.md` inline immediately — don't batch. Sharpen existing definitions in place.
- Only add terms specific to this project's domain — not general programming concepts.

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
