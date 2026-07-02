---
feature: resume
created: 2026-07-02
status: shipped
shipped: 2026-07-02
---
# Resume (T3) — Issue

> The ticket: the approved *why* plus the acceptance criteria and the issue's status. `status:` lives **only** here — `pending | in-progress | shipped | blocked` — and `shipped:` gets the ship date when the PR is open and `/sw:review` reached `lgtm`. The technical *how* (architecture, file structure, tasks) lives in the sibling `spec.md` + `tasks.md`, written just-in-time by `/sw:plan`.

## Purpose

Verify that a fresh session can pick up the sandbox milestone from its files alone. Drive two fresh "specwright session" sub-agents in the sandbox:

1. `/sw:run` — must locate the in-progress milestone, read `goal.md` + `board.md` + every issue's frontmatter, and announce the ready set (all issues whose dependencies are satisfied) **without** being told the milestone path.
2. Natural language — "continue the taskr milestone" must behave exactly like `/sw:run`.

Both sessions are stopped **before any owner is dispatched** (the user replies asking it to hold) — this issue proves state discovery, not conduction; the real run starts in `dispatch-parallelism`.

## Motivation

Resumability from artifacts alone is the core promise of the board design — "any fresh session can resume with this skill and nothing else". T3 of the test plan.

## Non-Goals

- No dispatching of issue owners; the sandbox board must be left untouched apart from what the run skill legitimately logs before holding.
- No auditing of planning artifact quality — done in `milestone-planning`.

## Acceptance Criteria

Number each criterion sequentially as `AC-N` — the IDs are stable handles that `tasks.md` references and that `/sw:review` walks to prove every criterion was delivered. Each criterion must be a binary, observable check verifiable in under a minute.

- [x] **AC-1** Evidence shows the `/sw:run` session finding the milestone without a path argument, reading the board, and naming exactly the dependency-free pending issues as ready — no issue with unmet dependencies included.
- [x] **AC-2** Evidence shows the natural-language session ("continue the taskr milestone") reaching the same ready set through the same skill behavior.
- [x] **AC-3** After both sessions, every sandbox `issue.md` still says `status: pending` and the board's Issues table is byte-identical to before (verified by diff against a pre-test copy).
- [x] **AC-4** `findings.md` has a verdict per check above and one Expected / Observed / Proposed-fix entry per failure.

Tick each `[x]` when verified. An issue is **not shippable** with empty or double-brace-placeholder acceptance criteria — `validate-spec.sh` and `/sw:review-spec` will reject it.
