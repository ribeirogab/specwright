---
feature: dispatch-parallelism
created: 2026-07-02
status: pending
shipped: null
---
# Dispatch and Parallelism (T4) — Issue

> The ticket: the approved *why* plus the acceptance criteria and the issue's status. `status:` lives **only** here — `pending | in-progress | shipped | blocked` — and `shipped:` gets the ship date when the PR is open and `/sw:review` reached `lgtm`. The technical *how* (architecture, file structure, tasks) lives in the sibling `spec.md` + `tasks.md`, written just-in-time by `/sw:plan`.

## Purpose

Conduct **round 1** of the sandbox milestone for real and audit the orchestrator's behavior. Drive a fresh `/sw:run` session in the sandbox and let it dispatch the ready set (the dependency-free issues — expected: the priorities-style issue, the list-ordering trap, and the web page):

- Owners must be dispatched **in parallel**, each in its own worktree under `.specwright/worktrees/<slug>` on its own branch.
- **Orchestrator purity:** across the whole round, the orchestrating session edits only the milestone folder — zero code, test, or doc edits outside it (audited from the transcript and from `git status` / commit authors per branch).
- The round runs to completion (owners return shipped or blocked; the trap issue blocking is expected and handled by `circuit-breaker`); the session is stopped after it logs the round's outcomes on the board, before it dispatches round 2.

**Degradation sub-test:** on a disposable clone of the pre-round sandbox, run one round with the session instructed that sub-agent support is unavailable — conduction must fall back to serial, in-place (no worktrees), same pipeline and gates. The clone is discarded afterwards; only the evidence is kept.

## Motivation

Parallel dispatch with worktree isolation and a conductor that never touches code are the two structural guarantees of the run loop; violating either corrupts every issue built on top. T4 of the test plan.

## Non-Goals

- No deep audit of what each owner produced inside its pipeline (JIT specs, gates, learnings) — that is `issue-pipeline` (T5); this issue audits the *orchestration*.
- No handling of the trap's blocked report beyond confirming the loop moves on — `circuit-breaker` (T6) owns that.

## Acceptance Criteria

Number each criterion sequentially as `AC-N` — the IDs are stable handles that `tasks.md` references and that `/sw:review` walks to prove every criterion was delivered. Each criterion must be a binary, observable check verifiable in under a minute.

- [ ] **AC-1** Evidence shows ≥ 2 issue owners dispatched concurrently in round 1 (overlapping lifetimes in the transcript/log), one worktree each under `.specwright/worktrees/<slug>` (verified via `git worktree list` captured during the round).
- [ ] **AC-2** Orchestrator purity holds: the transcript shows no orchestrator edit outside the milestone folder, and every code commit in round-1 branches was made from an owner's worktree.
- [ ] **AC-3** The board's Dispatch Log gained one `dispatched` line per round-1 issue and one outcome line per owner return, appended without rewriting earlier lines (diff against the pre-round board).
- [ ] **AC-4** Degradation evidence shows the no-sub-agent round conducted serially in place: owners executed one at a time in the session itself, no new entries under `.specwright/worktrees/`, same per-issue pipeline steps named in the transcript.
- [ ] **AC-5** `findings.md` has a verdict per check above and one Expected / Observed / Proposed-fix entry per failure.

Tick each `[x]` when verified. An issue is **not shippable** with empty or double-brace-placeholder acceptance criteria — `validate-spec.sh` and `/sw:review-spec` will reject it.
