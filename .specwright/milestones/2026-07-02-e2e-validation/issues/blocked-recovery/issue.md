---
feature: blocked-recovery
created: 2026-07-02
status: pending
shipped: null
---
# Blocked Recovery (T7) — Issue

> The ticket: the approved *why* plus the acceptance criteria and the issue's status. `status:` lives **only** here — `pending | in-progress | shipped | blocked` — and `shipped:` gets the ship date when the PR is open and `/sw:review` reached `lgtm`. The technical *how* (architecture, file structure, tasks) lives in the sibling `spec.md` + `tasks.md`, written just-in-time by `/sw:plan`.

## Purpose

Exercise the human side of the blocked contract. First, verify the contract was *communicated*: the halt report from `circuit-breaker`'s final run must tell the human that recovery means editing the trap's `issue.md` and flipping its status back to `pending` — a report that omits the flip instruction is itself a finding.

Then act as the human: resolve the contradiction in the trap's `issue.md` (drop the no-test-edits criterion, keep newest-first, allow updating the ordering test with justification), flip `status: blocked` → `pending`, and drive a fresh `/sw:run`. The orchestrator must see the issue as ready again, dispatch it, and the owner must complete the full pipeline to `shipped`.

## Motivation

Blocked issues are the designed pause point of unattended conduction; if recovery does not work exactly as the halt report promises, milestones die at their first blocker. T7 of the test plan.

## Non-Goals

- No changes to the trap beyond the minimal issue.md edit + status flip the contract prescribes.
- No closeout auditing — with the trap shipped, `closeout` (T8) takes over.

## Acceptance Criteria

Number each criterion sequentially as `AC-N` — the IDs are stable handles that `tasks.md` references and that `/sw:review` walks to prove every criterion was delivered. Each criterion must be a binary, observable check verifiable in under a minute.

- [ ] **AC-1** Verdict recorded on the halt report's recovery instructions: it names editing the trap's `issue.md` and setting `status: pending` as the way back (evidence quote); an omission is logged as a finding.
- [ ] **AC-2** The human edit is minimal and recorded: the contradictory criterion removed/replaced in the trap's `issue.md`, `status: pending`, everything else untouched (diff evidence).
- [ ] **AC-3** A fresh `/sw:run` treats the trap as ready and dispatches it without special-casing (Dispatch Log shows a `resumed`/`dispatched` event after the flip).
- [ ] **AC-4** The trap issue completes the pipeline: suite green with the justified test update, runtime verification of newest-first output, `status: shipped` + date in its `issue.md`, learnings curated if any.
- [ ] **AC-5** `findings.md` has a verdict per check above and one Expected / Observed / Proposed-fix entry per failure.

Tick each `[x]` when verified. An issue is **not shippable** with empty or double-brace-placeholder acceptance criteria — `validate-spec.sh` and `/sw:review-spec` will reject it.
