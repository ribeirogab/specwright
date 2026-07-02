---
feature: circuit-breaker
created: 2026-07-02
status: pending
shipped: null
---
# Circuit Breaker (T6) — Issue

> The ticket: the approved *why* plus the acceptance criteria and the issue's status. `status:` lives **only** here — `pending | in-progress | shipped | blocked` — and `shipped:` gets the ship date when the PR is open and `/sw:review` reached `lgtm`. The technical *how* (architecture, file structure, tasks) lives in the sibling `spec.md` + `tasks.md`, written just-in-time by `/sw:plan`.

## Purpose

Audit how the trap was handled. The sandbox's list-ordering issue is impossible by construction: its criteria demand newest-first output while forbidding changes to the planted oldest-first test — the quality gate can never pass. From the round evidence and the sandbox state, verify the owner-level breaker (stop after at most 3 identical failures — count the attempts in the transcript; more than 3 is thrashing, fewer with a reasoned contradiction report is acceptable), the blocked contract (`status: blocked` in the trap's `issue.md`, a why / tried / needs report copied verbatim into the board's Blockers), and the orchestrator-level breaker (the loop skipped to other ready issues instead of retrying the trap).

Then resume the sandbox run once more: with every other issue shipped and only the trap left, the orchestrator must **halt** with a consolidated blockers report instead of spinning.

## Motivation

The breaker is what makes unattended conduction safe — without it a single impossible criterion burns the whole run. T6 of the test plan.

## Non-Goals

- No fixing of the trap issue and no status flip — that is `blocked-recovery` (T7), which owns the human side of the contract.
- No re-litigation of round auditing already done by T4/T5; this issue reads their evidence plus the sandbox state.

## Acceptance Criteria

Number each criterion sequentially as `AC-N` — the IDs are stable handles that `tasks.md` references and that `/sw:review` walks to prove every criterion was delivered. Each criterion must be a binary, observable check verifiable in under a minute.

- [ ] **AC-1** Transcript evidence counts the trap owner's failed gate attempts: ≤ 3, no identical retry after the third, and the stop is explicit (no further implementation attempts afterwards).
- [ ] **AC-2** The trap's `issue.md` says `status: blocked`, and the board's Blockers section carries its report with all three parts — why (the contradicting AC/test pair), tried (distinct attempts), needs (the human decision required).
- [ ] **AC-3** Dispatch Log evidence shows the loop continuing past the blocked trap in the same round (other owners dispatched/completed after the `blocked` event, no re-dispatch of the trap).
- [ ] **AC-4** With only the trap unshipped, a resumed `/sw:run` halts with a consolidated blockers report (every blocker + what each needs from the human) and does not dispatch anything — transcript evidence.
- [ ] **AC-5** `findings.md` has a verdict per check above and one Expected / Observed / Proposed-fix entry per failure.

Tick each `[x]` when verified. An issue is **not shippable** with empty or double-brace-placeholder acceptance criteria — `validate-spec.sh` and `/sw:review-spec` will reject it.
