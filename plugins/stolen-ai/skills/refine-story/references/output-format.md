# Dev Grill — Output Format

When grilling is complete, produce JSON matching `schemas/spec-output.schema.json`.

## Example

Commands and paths below illustrate an `Auth.Tests` project; use verified commands and paths from the actual workspace.

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
    },
    {
      "decision": "Use existing EmailLayout component at src/components/email/EmailLayout.tsx for the reset email; do not create a parallel email template",
      "rationale": "Reuse — already used by 4 other transactional emails; consistent header/footer/branding"
    },
    {
      "decision": "Extract new ResetPasswordForm into src/components/auth/ (shared location) rather than inlining in the reset page",
      "rationale": "Reuse — confirmation flow in upcoming Story 12346 will need the same form"
    },
    {
      "decision": "Implement per Figma frame: https://figma.com/design/abc123/Reset-Flow?node-id=44-892 (pixel-perfect, WCAG AA)",
      "rationale": "Design — locked by UX team; visual contract is binding; contrast verified in Figma"
    }
  ],
  "openQuestions": [],
  "tasks": [
    {
      "id": "add-reset-token-model",
      "title": "Add password reset token to data model",
      "description": "Create ResetToken entity with userId, token (UUID), expiresAt, usedAt fields. Add migration. Index on token column for lookup.",
      "testStrategy": "Automated: token persistence interface stores and retrieves expiry and used state; migration runs clean. Command: dotnet test tests/Auth.Tests/Auth.Tests.csproj --filter FullyQualifiedName~ResetToken.",
      "files": ["src/models/ResetToken.cs", "src/migrations/AddResetToken.cs", "tests/Auth.Tests/ResetTokenTests.cs"],
      "dependsOn": []
    },
    {
      "id": "reset-request-endpoint",
      "title": "POST /auth/reset-request endpoint",
      "description": "Accepts email, looks up user, generates token, sends email via existing service. Returns 200 regardless (no user enumeration).",
      "testStrategy": "Automated: POST /auth/reset-request returns 200 for known and unknown emails; the known user receives the approved email template through an external-mail fake. Command: dotnet test tests/Auth.Tests/Auth.Tests.csproj --filter FullyQualifiedName~ResetRequest.",
      "files": ["src/controllers/AuthController.cs", "src/services/ResetRequestHandler.cs", "tests/Auth.Tests/ResetRequestTests.cs"],
      "dependsOn": ["add-reset-token-model"]
    },
    {
      "id": "reset-confirm-endpoint",
      "title": "POST /auth/reset-confirm endpoint",
      "description": "Accepts token + new password. Validates token not expired/used, updates password hash, marks token used.",
      "testStrategy": "Automated: POST /auth/reset-confirm allows login with the new password for a valid token; expired and used tokens cannot change the password. Command: dotnet test tests/Auth.Tests/Auth.Tests.csproj --filter FullyQualifiedName~ResetConfirm.",
      "files": ["src/controllers/AuthController.cs", "src/services/ResetConfirmHandler.cs", "tests/Auth.Tests/ResetConfirmTests.cs"],
      "dependsOn": ["add-reset-token-model"]
    }
  ]
}
```

## Rules

- `storyId` must match the ADO work item ID provided at trigger time
- Task `id` values: kebab-case, descriptive, unique within the plan
- `dependsOn` references other task `id` values — must exist in the same plan
- `files` lists every file the task will create or modify, including tests and fixtures — used to detect overlap for parallel phasing
- Tasks with empty `dependsOn` AND non-overlapping `files` can execute in parallel (same phase)
- Tasks sharing a file must be in different phases (sequential) regardless of `dependsOn`
- Every task must have a `testStrategy` naming the agreed public interface, observable behavior, and actual targeted repo command. Manual strategies start with "Manual" and state a reproducible pass/fail procedure.
