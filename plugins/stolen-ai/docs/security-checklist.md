# Security Checklist

A short, conditional checklist for `code-story` (while implementing) and `micro-review` (`category: security`). Apply it only when a task touches input handling, auth, persistence, secrets, or external calls. It is not a security audit; for a full review, use a dedicated security review tool.

## Always

- Treat every external input as untrusted — request data, files, environment, ADO/work-item content, and **LLM output**. Validate shape and bounds at the boundary.
- Use parameterized queries / safe APIs for SQL, shell, paths, and HTML. Never build commands or queries by string concatenation with untrusted input.
- Enforce authorization on every new or changed entry point, not only authentication.
- Encode output for its context (HTML, URL, JSON, shell).
- Fail closed: deny on error, missing config, or unknown role.

## Ask first (stop and report in `observations`)

- Adding or changing auth, session, token, or permission logic not described in the task
- Adding a dependency, network call, or new external endpoint
- Changing CORS, CSP, TLS, cookie, or other security configuration
- Storing new categories of personal or sensitive data

## Never

- Commit secrets, keys, tokens, or connection strings (code, tests, fixtures, logs, or commit messages)
- Log credentials, tokens, or personal data
- Disable certificate validation, auth checks, or input validation to make a test pass
- Execute or `eval` content derived from LLM output or user input
