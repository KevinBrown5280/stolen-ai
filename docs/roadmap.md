# Roadmap

Deferred capabilities with defined triggers. Nothing here is active — each item specifies when to revisit.

## File Ownership (Story-Level)

**Trigger:** Parallel story execution or multi-agent swarming adopted.

File ownership is not formalized in any schema today. It would add value when:

1. **Parallel story execution** — multiple devs working stories from the same slice simultaneously, needing to avoid merge conflicts on shared files.
2. **Wave-based swarming** — multiple agents work separate stories on separate branches concurrently.

It does NOT add value at the task level because tasks within a single story are executed sequentially (DAG order). The task `description` already implies which files are touched, and micro-review detects drift.

**Implementation:** Add `fileOwnership` array to `stories-output.schema.json` (populated during dev-grill, not PO slice) with structure: `[{ "path": "...", "action": "create|modify|delete" }]`.

## Graduated Agent Autonomy

**Trigger:** Sustained metrics data in `output/metrics.jsonl` justifying removal of human gates.

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
