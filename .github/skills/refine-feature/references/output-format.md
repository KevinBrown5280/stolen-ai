# PO Grill — Output Format

When grilling is complete, produce this exact structure. This output is the input to the Slice agent.

```markdown
## Feature
[Feature title from ADO]

## Locked Decisions
1. **[Decision]** — [Rationale] 
2. **[Decision]** — [Rationale]
...

## Personas
- [Persona 1]: [What they need from this feature]
- [Persona 2]: [What they need]

## Scope
- **In**: [Bulleted list of what's included]
- **Out**: [Bulleted list of what's explicitly excluded]

## Behavior
- **Happy path**: [Primary flow in 1-3 sentences]
- **Edge cases**: [Bulleted list]
- **Error states**: [Bulleted list]

## Constraints
- [Any performance, security, compliance, or technical constraints]

## Dependencies
- [What already exists that this builds on]
- [What must be built first, if anything]

## Ready for slicing: YES
```

## Rules

- Every field must be filled. Use "None identified" if genuinely empty after grilling.
- Decisions must be numbered — the Slice agent references them by number.
- Keep each decision to one sentence + one sentence rationale.
- Scope "Out" is mandatory — forces explicit exclusion.
