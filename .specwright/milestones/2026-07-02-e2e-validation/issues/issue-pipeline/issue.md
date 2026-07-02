---
feature: issue-pipeline
created: 2026-07-02
status: pending
shipped: null
---
# Issue Pipeline (T5) — Issue

> The ticket: the approved *why* plus the acceptance criteria and the issue's status. `status:` lives **only** here — `pending | in-progress | shipped | blocked` — and `shipped:` gets the ship date when the PR is open and `/sw:review` reached `lgtm`. The technical *how* (architecture, file structure, tasks) lives in the sibling `spec.md` + `tasks.md`, written just-in-time by `/sw:plan`.

## Purpose

The core test: audit the full owner pipeline across the sandbox milestone's rounds. Resume the sandbox run for **round 2** (the dependent issues — filters and export — become ready once their dependency shipped in round 1), then audit rounds 1 and 2 together:

- `spec.md` / `tasks.md` written **just-in-time** (absent from the sandbox repo before each issue's dispatch — verified against git history), self-review executed and `validate-spec.sh` run per issue.
- **Learnings flow:** the epoch-seconds fact planted in the storage layer must surface in the round-1 producer issue's `learnings.md` and be mentioned/respected in the ISO-date export issue's `spec.md`.
- **Quality gate:** each owner ran taskr's suite; no silent test-count drop or weakened assertion across any shipped branch.
- **Runtime verification:** each owner *executed* the CLI and checked every `AC-N` by observed behavior, recorded in the PR body/evidence.
- **Web component:** the web status page issue was verified through a browser when the owner had that capability, else its UI criteria are marked `needs-human-verification` in its `issue.md` — never silently ticked.
- **Delivery:** one branch and one PR-shaped delivery per issue (the sandbox has no GitHub — the owner must hit `/sw:pr`'s documented degradation: stop, explain, print manual steps; fabricating a PR is a failure). `/sw:review` ran to `lgtm`; `learnings.md` is curated facts, not narration; `status: shipped` flipped in `issue.md` only — no status duplicated onto the board.
- **Fan-out:** the export issue (5+ tasks, `Delegable: yes` tasks) fanned out to task workers; workers reported findings back and wrote no `learnings.md` themselves.

## Motivation

The pipeline is where the work actually happens; every guarantee (JIT planning, gates, learnings, verification) exists to make unattended issue delivery trustworthy. T5 of the test plan.

## Non-Goals

- No trap handling audit (`circuit-breaker` owns T6) beyond the trap staying blocked while the loop proceeds.
- No closeout audit — `closeout` (T8) owns the final report and promotion.
- No fixes to defects found; findings only.

## Acceptance Criteria

Number each criterion sequentially as `AC-N` — the IDs are stable handles that `tasks.md` references and that `/sw:review` walks to prove every criterion was delivered. Each criterion must be a binary, observable check verifiable in under a minute.

- [ ] **AC-1** For every shipped sandbox issue: git history proves `spec.md`/`tasks.md` did not exist before dispatch and were committed by the owner during the round, and the transcript/evidence names the self-review gates (validator + reviewer subagent + review-spec) actually run.
- [ ] **AC-2** The round-1 producer issue's `learnings.md` records the epoch-seconds storage fact, and the export issue's `spec.md` cites or respects it (grep evidence from both files).
- [ ] **AC-3** Every shipped branch keeps taskr's suite green with no reduction in test count and no weakened assertions (diff review of `test/` across branches), and each owner's evidence shows the CLI actually executed per `AC-N` with observed output.
- [ ] **AC-4** The web page issue shows browser-based verification evidence, or its UI criteria carry `needs-human-verification` + reason in its `issue.md`; no UI criterion is ticked without one of the two.
- [ ] **AC-5** Each shipped issue has exactly one branch and one PR-shaped delivery record; with no GitHub remote, `/sw:pr` stopped and printed manual steps instead of fabricating a PR URL (transcript evidence per issue).
- [ ] **AC-6** Each shipped issue's `learnings.md` (when present) contains only forward-useful facts (no "what I did" narration), `status: shipped` + date live only in `issue.md`, and the board contains no status column for them.
- [ ] **AC-7** The export issue's `tasks.md` marks ≥ 2 tasks `Delegable: yes`; evidence shows task workers executing them and reporting findings to the owner, and no `learnings.md` write by a worker.
- [ ] **AC-8** `findings.md` has a verdict per check above and one Expected / Observed / Proposed-fix entry per failure.

Tick each `[x]` when verified. An issue is **not shippable** with empty or double-brace-placeholder acceptance criteria — `validate-spec.sh` and `/sw:review-spec` will reject it.
