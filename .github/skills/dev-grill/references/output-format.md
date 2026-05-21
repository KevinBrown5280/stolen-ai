# Dev Grill — Output Format

When grilling is complete, produce JSON matching `schemas/plan-output.schema.json`.

## Example

```json
{
  "storyId": "12345",
  "storyTitle": "As a participant, I can reset my password",
  "decisions": [
    {
      "decision": "Use existing email service for reset tokens",
      "rationale": "Already handles templating and delivery; no new infrastructure"
    },
    {
      "decision": "Token expires in 15 minutes",
      "rationale": "Balances security with UX; matches industry standard"
    }
  ],
  "tasks": [
    {
      "id": "add-reset-token-model",
      "title": "Add password reset token to data model",
      "description": "Create ResetToken entity with userId, token (UUID), expiresAt, usedAt fields. Add migration. Index on token column for lookup.",
      "testStrategy": "Unit test: token generation, expiration check. Integration: migration runs clean.",
      "dependsOn": []
    },
    {
      "id": "reset-request-endpoint",
      "title": "POST /auth/reset-request endpoint",
      "description": "Accepts email, looks up user, generates token, sends email via existing service. Returns 200 regardless (no user enumeration).",
      "testStrategy": "Unit: handler logic. Integration: email service called with correct template.",
      "dependsOn": ["add-reset-token-model"]
    },
    {
      "id": "reset-confirm-endpoint",
      "title": "POST /auth/reset-confirm endpoint",
      "description": "Accepts token + new password. Validates token not expired/used, updates password hash, marks token used.",
      "testStrategy": "Unit: token validation, password update. Integration: full flow from valid token to changed password.",
      "dependsOn": ["add-reset-token-model"]
    }
  ]
}
```

## Rules

- `storyId` must match the ADO work item ID provided at trigger time
- Task `id` values: kebab-case, descriptive, unique within the plan
- `dependsOn` references other task `id` values — must exist in the same plan
- Tasks with empty `dependsOn` can execute in parallel
- Every task must have a `testStrategy` — the TDD agent uses this to write tests first
