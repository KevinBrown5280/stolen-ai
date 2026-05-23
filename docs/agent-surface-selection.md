# Agent Surface Selection

When to use each execution surface in StolenAi. This codifies Decision 19 from `docs/decisions.md` into actionable selection criteria.

## The Three Surfaces

| Surface | Format | Context | Interaction | Cost |
|---------|--------|---------|-------------|------|
| **Skill** | `SKILL.md` | Runs in the user's active session | Interactive (asks questions, waits for answers) | Tokens only when invoked |
| **Agent** | `.agent.md` | Fresh context (sub-agent sandbox) | Autonomous (runs to completion, returns result) | Full context window per invocation |
| **Script** | `.ps1` | No AI context | None (executes deterministically) | Zero tokens |

## Decision Matrix

| Situation | Surface | Why |
|-----------|---------|-----|
| Need human judgment mid-task | Skill | Only skills can ask follow-up questions |
| Decisions branch based on user answers | Skill | Interactive loop required |
| Output depends on domain knowledge the user holds | Skill | Must extract it conversationally |
| Transform structured input → structured output (no ambiguity) | Agent | Deterministic enough to run autonomously |
| Check/validate work against a spec | Agent | Objective criteria, no human input needed |
| Orchestrate a multi-step workflow | Agent | Coordinates skills + scripts + sub-agents |
| CRUD operations against external systems (ADO, git) | Script | No tokens burned; auditable; reversible via dry-run |
| Data fetch from APIs | Script | Deterministic, no reasoning needed |
| File I/O with known format | Script | Cheaper and more reliable than AI |

## Selection Rules

### Use a Skill when:
1. The task requires **back-and-forth** with a human
2. The input is **ambiguous or sparse** and needs clarification
3. The output quality depends on **eliciting** unstated knowledge
4. The task is **exploratory** (outcome not predictable from input alone)

Examples: `refine-feature` (elicit Feature details), `refine-story` (lock technical approach), `tdd` (drive implementation with human feedback)

### Use an Agent when:
1. The task can run to **completion without human input**
2. Input is **well-structured** (JSON, spec file, prior skill output)
3. Output follows a **defined schema** or template
4. The task benefits from a **clean context** (no prior conversation noise)
5. The task is a **sub-step** in a larger workflow

Examples: `slice` (structured input → Stories JSON), `micro-review` (diff + spec → findings), `plan-feature` (orchestrates the full pipeline)

### Use a Script when:
1. The task is **deterministic** (same input → same output)
2. No reasoning or judgment is needed
3. The task interacts with **external systems** (ADO, git, file system)
4. **Cost** matters — the operation would waste tokens if done by AI
5. The task needs to be **auditable** and **reproducible**

Examples: `fetch-feature.ps1` (ADO read), `post-stories.ps1` (ADO write), `persist-plan.ps1` (file + commit + post)

## Anti-Patterns

| Don't... | Do instead... |
|----------|---------------|
| Use an agent to ask the user questions | Use a skill — agents can't interact mid-run |
| Use a skill for deterministic transforms | Use an agent — skills waste human attention on non-decisions |
| Use AI (skill or agent) for CRUD | Use a script — zero tokens, fully auditable |
| Use a script where judgment varies by context | Use a skill or agent — scripts can't reason |
| Give an agent access to `execute` unless it orchestrates | Restrict tool list — sub-agents get minimal tools |

## Portability

| Surface | Portable across |
|---------|-----------------|
| Skills (`SKILL.md`) | VS Code, Visual Studio 2026, CLI, any agentskills.io-compatible tool |
| Agents (`.agent.md`) | VS Code, Visual Studio 2026, GitHub Copilot CLI |
| Scripts (`.ps1`) | Any PowerShell 7+ environment |

## How This Maps to the Workflows

```
Plan Feature:
  fetch-feature.ps1  →  refine-feature (SKILL)  →  slice (AGENT)  →  post-stories.ps1
       Script              Skill                 Agent               Script
       [fetch]          [elicit/clarify]      [transform]          [write to ADO]

Plan Story:
  fetch-story.ps1  →  refine-story (SKILL)  →  persist-plan.ps1  →  tdd (SKILL)  →  micro-review (AGENT)
       Script             Skill                  Script              Skill             Agent
       [fetch]        [elicit/decide]          [commit/post]     [implement]        [validate]
```

## Cost Implications

- **Skills** are the most expensive per-invocation (long interactive sessions burn context)
- **Agents** have fixed cost (one context window, runs once, returns)
- **Scripts** are free (no AI involvement)

The architecture minimizes cost by:
1. Using scripts for all I/O operations
2. Using compressed summaries between phases (grill output ≠ full transcript)
3. Giving agents minimal tool access (reduces exploration tokens)
4. Only invoking skills where human knowledge is genuinely needed
