# Roadmap

Deferred capabilities with defined triggers. Nothing here is active — each item specifies when to revisit.

## File Ownership (Story-Level)

**Trigger:** Parallel story execution or multi-agent swarming adopted.

File ownership is not formalized in any schema today. It would add value when:

1. **Parallel story execution** — multiple devs working stories from the same slice simultaneously, needing to avoid merge conflicts on shared files.
2. **Wave-based swarming** — multiple agents work separate stories on separate branches concurrently.

It does NOT add value at the task level because tasks within a single story are executed sequentially (DAG order). The task `description` already implies which files are touched, and micro-review detects drift.

**Implementation:** Add `fileOwnership` array to `stories-output.schema.json` (populated during refine-story, not plan-feature slice) with structure: `[{ "path": "...", "action": "create|modify|delete" }]`.

## Dev Spec as ADO Attachment

**Trigger:** Team grows beyond single-developer workflow; non-dev stakeholders need spec access without cloning the repo.

Currently the dev spec (`specs/{feature}/*.md`) lives in git only, with a discussion comment on the ADO Story providing inline visibility. The brief is already attached to ADO (required — `output/` is ephemeral and `fetch-story.ps1` pulls it for refine-story).

Attaching the dev spec alongside the discussion comment would be ~5 lines in `persist-plan.ps1` — the file already exists on disk at post time and the auth token is already acquired. Marginal runtime cost is one REST upload + one relation add.

**Implementation:** After writing the spec file and posting the discussion comment, upload `specs/{feature}/{storyId}.md` as an attachment on the Story using the same pattern as `post-stories.ps1` brief attachment (REST POST to `_apis/wit/attachments`, then `az boards work-item relation add --relation-type "Attached File"`).

## Feature Slice Summary vs. Dev-Driven Story Creation

**Trigger:** Evidence that Feature-created Stories lack technical depth, or that refine-story frequently restructures the slice boundaries.

Currently the plan-feature workflow creates full User Stories in ADO (title, description, AC, brief). The plan-story workflow then picks up each Story and plans tasks within it. An alternative model:

1. **Plan-feature workflow** produces a *slice summary* (posted as a comment or attachment on the Feature) — describing the functional decomposition, priorities, and constraints — but does NOT create individual Stories in ADO.
2. **Plan-story workflow** consumes the slice summary + performs their own technical refinement, then creates Stories that blend Feature intent with technical structure (dependency order, shared-code boundaries, integration points).

**Arguments for this change:**
- Stories would reflect both business and technical slicing in one pass
- Avoids the refine-story discovering that Feature slice boundaries don't align with code boundaries (e.g. two stories touch the same component and should be one, or one story hides two independent code changes)
- Single point of Story creation = single schema, single post script

**Arguments against (current design):**
- Feature-created Stories give early backlog visibility before any dev picks them up
- Separation of concerns: Feature planning owns "what," Story planning owns "how"
- Current flow already works — refine-story refines *within* the Story rather than restructuring across Stories

**Implementation (if adopted):**
- `post-stories.ps1` replaced by a `post-slice-summary.ps1` that posts a structured comment/attachment to the Feature
- New `create-stories.ps1` in `scripts/plan-story/` that takes the combined refinement output (Feature summary + technical plan) and creates Stories
- `schemas/slice-summary.schema.json` for the Feature→Story handoff artifact
- `stories-output.schema.json` would gain technical fields (task DAG sketch, file ownership)

## Graduated Agent Autonomy

**Trigger:** Sustained metrics data in `metrics/metrics.jsonl` justifying removal of human gates.

| Tier | Behaviour | Unlock Criteria |
|------|-----------|-----------------|
| 0 (current) | Agent produces JSON → human reviews → script posts | Default — no trust data needed |
| 1 | On re-slice with minor feedback, agent posts delta without re-presenting all stories | Human already approved intent; only mechanical changes |
| 2 | Slice → validate schema → post with no human gate | `firstPassAcceptanceRate >= 0.9` over last 10 runs |
| 3 | Agent self-initiates on ADO state change, posts draft stories tagged `[needs-review]` | Sustained Tier 2 + async review workflow established |

**Rules:**
- Tier revokes automatically if a run triggers rework (drops back one level)
- All auto-posted items must be tagged `[auto]` for audit trail
- Metrics pipeline must be running and trustworthy before any tier > 0
- Governance Rule §2 (AI never calls `az devops` directly) remains at all tiers — scripts still execute CRUD

## Plugin Distribution

**Trigger:** PoC validated end-to-end, team ready to share across repos/workspaces.

When ready to share as an installable plugin (like `adversarial-review@fun-with-copilot`):

### What a plugin needs

```
plugin.json              # Manifest (name, description, agents[], skills[])
agents/                  # .agent.md files (or paths in plugin.json)
skills/                  # SKILL.md directories
```

Installed via `/plugin install <name>@<marketplace-source>`. Files land in `~/.copilot/installed-plugins/<source>/<plugin>/`.

### Steps to convert StolenAi

1. **Add `plugin.json`** at repo root:
   ```json
   {
     "name": "stolen-ai",
     "description": "AI-assisted Feature and Story planning workflows for Azure DevOps teams.",
     "author": { "name": "Kevin" },
     "repository": "https://github.com/Benefits-Outsourcing/StolenAi",
     "license": "MIT",
     "keywords": ["ado", "plan-feature", "plan-story", "tdd", "agile"],
     "agents": [
       "./.github/agents/plan-feature.agent.md",
       "./.github/agents/plan-story.agent.md",
       "./.github/agents/slice.agent.md",
       "./.github/agents/micro-review.agent.md"
     ],
     "skills": ["./.github/skills/"]
   }
   ```

2. **Fix script path resolution** — when installed as a plugin, the working directory is the user's workspace, not the plugin folder. Options:
   - Introduce a variable/convention that resolves to the plugin install directory
   - Have agents locate scripts via `$env:COPILOT_PLUGIN_DIR` or similar (check what's available at the time)
   - Duplicate scripts into the user's workspace on first run (messy, avoid)

3. **Choose hosting model**:
   - **Standalone marketplace source**: `Benefits-Outsourcing/StolenAi` as its own repo
   - **Multi-plugin repo** (like `fun-with-copilot`): move into `plugins/stolen-ai/` inside a shared repo

4. **Schemas and output** — `schemas/` ships with the plugin. `output/` is always workspace-local (gitignored).

### What does NOT need to change for local dev

- `.github/agents/` and `.github/skills/` still load as workspace agents/skills when working inside the repo
- Adding `plugin.json` has zero effect on local behavior — it's only consumed by `/plugin install`
- Both mechanisms coexist: local workspace convention + plugin manifest
