---
feature: {{kebab-slug-of-change}}
created: {{YYYY-MM-DD}}
status: pending
shipped: null
delivery: {{.specwright/deliveries/YYYY-MM-DD-<slug> | null}}
---
# {{Change Name}} — Change

> The ticket: the approved *why* plus the acceptance criteria and the change's status. `status:` lives **only** here — `pending | in-progress | shipped | blocked` — and `shipped:` gets the ship date when the PR is open and `/sw:review` reached `lgtm`. The technical *how* (architecture, file structure, tasks) lives in the sibling `spec.md` + `tasks.md`, written just-in-time by `/sw:plan`. Delivery membership is data: `delivery:` holds the parent delivery folder, or `null` for a standalone change.

## Purpose

{{what this change delivers, in plain language — the outcome a reader should understand without any code context}}

## Motivation

{{why this exists now — what triggered it, what pain it removes, what it unlocks}}

## Non-Goals

{{what this change explicitly does NOT do — the boundaries that keep scope honest}}

## Acceptance Criteria

Number each criterion sequentially as `AC-N` — the IDs are stable handles that `tasks.md` references (each task names the criteria it satisfies) and that `/sw:review` walks to prove every criterion was delivered. Each criterion must be a binary, observable check that someone other than the implementer can verify in under a minute. **No vague verbs** ("works well", "is fast", "is robust", "handles errors gracefully") — replace them with specific, measurable conditions. If a criterion cannot be verified without reading the implementation, it is not an acceptance criterion; rewrite it. State a hard constraint once — in the criterion (or Non-Goal) that owns it — and reference it elsewhere; every restatement is an amendment hazard.

Runtime verification checks each criterion by observed behavior before the PR opens; a criterion the agent cannot verify at runtime (e.g. UI without browser capability) is marked `needs-human-verification` with the reason — never silently ticked.

- [ ] **AC-1** {{ e.g. `POST /users` with a duplicate email returns 409 and body `{"code":"DUPLICATE_EMAIL"}` }}
- [ ] **AC-2** {{ e.g. the migration script runs idempotently — running it twice on the same DB yields no diff }}
- [ ] **AC-N** {{ ... }}

Tick each `[x]` when verified. A change is **not shippable** with empty or double-brace-placeholder acceptance criteria — `validate-spec.sh` and `/sw:review-spec` will reject it.
