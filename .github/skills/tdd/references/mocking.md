# When to Mock

Mock at **system boundaries** only:

- External APIs (payment, email, etc.)
- Databases (sometimes — prefer test DB)
- Time/randomness
- File system (sometimes)

Don't mock:

- Your own classes/modules
- Internal collaborators
- Anything you control

## Designing for Mockability

**1. Use dependency injection** — pass external dependencies in rather than creating them internally.

**2. Prefer SDK-style interfaces over generic fetchers** — create specific functions for each external operation instead of one generic function with conditional logic. Each function is independently mockable with a single return shape.
