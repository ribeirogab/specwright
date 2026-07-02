---
feature: scope-detection
created: 2026-07-02
status: in-progress
shipped: null
---
# Scope Detection (T1) — Issue

> The ticket: the approved *why* plus the acceptance criteria and the issue's status. `status:` lives **only** here — `pending | in-progress | shipped | blocked` — and `shipped:` gets the ship date when the PR is open and `/sw:review` reached `lgtm`. The technical *how* (architecture, file structure, tasks) lives in the sibling `spec.md` + `tasks.md`, written just-in-time by `/sw:plan`.

## Purpose

Verify that `/sw:brainstorm` concludes the right scope. Drive two brainstorm sessions in the sandbox (the owner spawns a sub-agent as the "specwright session" and plays the user with scripted replies — never leaking expected outcomes):

1. **Milestone case** — ask for a multi-part feature: taskr with priorities, filters by priority/status, export (JSON and CSV with ISO-8601 dates), a minimal web status page, and a "newest task first" list view that must not touch the existing tests. Steer requirements, not mechanics; the agent must **suggest** a milestone with an issue preview (slugs, one-liners, dependencies) and let the user decide — never force it. Approve the design and let it write the milestone artifacts; this session's output is the fixture for `milestone-planning` and every run-loop issue after it.
2. **False-positive case** — in a disposable copy of the sandbox, ask for a tiny change ("add a `--version` flag"). The session must follow the single-issue path with the milestone never mentioned.

The five capabilities above are the scenario seeds later issues depend on: parallel round-1 issues, a learnings producer/consumer pair (epoch dates → ISO export), a browser-verifiable page, and one issue whose acceptance criteria are impossible against the planted oldest-first test.

## Motivation

Scope detection is the entry gate of the unified workflow: if the brainstorm forces milestones on small work or misses them on large work, everything downstream inherits the error. T1 of the test plan.

## Non-Goals

- No auditing of the artifact *contents* — that is `milestone-planning` (T2).
- No conducting of the created milestone — that starts at `resume` (T3).
- No fixes to any defect found; failures become findings.

## Acceptance Criteria

Number each criterion sequentially as `AC-N` — the IDs are stable handles that `tasks.md` references and that `/sw:review` walks to prove every criterion was delivered. Each criterion must be a binary, observable check verifiable in under a minute.

- [ ] **AC-1** Evidence (saved session transcript under this issue's `evidence/`) shows the milestone-case session *suggesting* a milestone with an issue preview (slugs + one-liners + dependencies) and explicitly leaving the decision to the user — no artifact written before the user's choice.
- [ ] **AC-2** The milestone-case session ends with milestone artifacts committed in the sandbox under `.specwright/milestones/*/` containing issues that cover the five seeded capabilities, including at least two issues with no dependencies (parallel round 1) and a list-ordering issue whose criteria conflict with the planted oldest-first test.
- [ ] **AC-3** Evidence shows the false-positive session following the single-issue path with zero milestone mentions in the transcript (checked by search over the saved transcript).
- [ ] **AC-4** `findings.md` in this issue folder has a verdict (pass/fail + evidence pointer) for each of AC-1..AC-3's underlying checks, and one Expected / Observed / Proposed-fix entry per failed check (empty findings list allowed only if all checks passed).

Tick each `[x]` when verified. An issue is **not shippable** with empty or double-brace-placeholder acceptance criteria — `validate-spec.sh` and `/sw:review-spec` will reject it.
