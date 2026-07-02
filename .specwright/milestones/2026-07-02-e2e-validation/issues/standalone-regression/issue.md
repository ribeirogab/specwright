---
feature: standalone-regression
created: 2026-07-02
status: pending
shipped: null
---
# Standalone Issue Regression (T9) — Issue

> The ticket: the approved *why* plus the acceptance criteria and the issue's status. `status:` lives **only** here — `pending | in-progress | shipped | blocked` — and `shipped:` gets the ship date when the PR is open and `/sw:review` reached `lgtm`. The technical *how* (architecture, file structure, tasks) lives in the sibling `spec.md` + `tasks.md`, written just-in-time by `/sw:plan`.

## Purpose

Prove the milestone work did not regress the standalone path. In the sandbox (now idle after closeout), drive a `/sw:brainstorm` session for a small change — "add a `--help` flag with usage text" — and verify the single-issue flow end to end: design conversation and approval, scope concluded as a single issue, the post-design batch asking exactly branch + worktree + handoff, `issue.md` written under `.specwright/issues/YYYY-MM-DD-<slug>/`, then the full pipeline (JIT spec + tasks, self-review, implementation, quality gate, runtime verification, PR-degradation delivery, review to `lgtm`, `status: shipped`).

The old format must stay dead: no `design.md` created anywhere in the sandbox at any point of the flow.

## Motivation

The unified layout replaced the old spec/design format; the standalone path is the most-used entry point and must work unchanged after the milestone machinery landed. T9 of the test plan.

## Non-Goals

- No milestone involvement — this scenario must never suggest or touch `.specwright/milestones/`.
- No re-testing of pipeline internals already covered by T5 beyond what the single pass naturally exercises.

## Acceptance Criteria

Number each criterion sequentially as `AC-N` — the IDs are stable handles that `tasks.md` references and that `/sw:review` walks to prove every criterion was delivered. Each criterion must be a binary, observable check verifiable in under a minute.

- [ ] **AC-1** Evidence shows the post-design batch asking exactly three things — branch name, worktree, handoff — in one message, and nothing else.
- [ ] **AC-2** The sandbox gains `.specwright/issues/YYYY-MM-DD-<slug>/` with `issue.md` (`status:` frontmatter + numbered `AC-N`), and `spec.md`/`tasks.md` appear only after planning starts (git history evidence).
- [ ] **AC-3** The pipeline completes: suite green, `--help` verified by executing the CLI, delivery via `/sw:pr`'s documented no-GitHub degradation, `/sw:review` reaching `lgtm`, `status: shipped` + date in `issue.md`.
- [ ] **AC-4** `find <sandbox> -name design.md` returns nothing, and the transcript contains no design.md mention (old format dead).
- [ ] **AC-5** `findings.md` has a verdict per check above and one Expected / Observed / Proposed-fix entry per failure.

Tick each `[x]` when verified. An issue is **not shippable** with empty or double-brace-placeholder acceptance criteria — `validate-spec.sh` and `/sw:review-spec` will reject it.
