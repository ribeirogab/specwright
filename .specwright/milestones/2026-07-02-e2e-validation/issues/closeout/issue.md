---
feature: closeout
created: 2026-07-02
status: pending
shipped: null
---
# Closeout (T8) — Issue

> The ticket: the approved *why* plus the acceptance criteria and the issue's status. `status:` lives **only** here — `pending | in-progress | shipped | blocked` — and `shipped:` gets the ship date when the PR is open and `/sw:review` reached `lgtm`. The technical *how* (architecture, file structure, tasks) lives in the sibling `spec.md` + `tasks.md`, written just-in-time by `/sw:plan`.

## Purpose

With every sandbox issue shipped, drive the final `/sw:run` and audit the closeout contract: a final summary appended to the board (issues shipped, delivery records, blockers survived); durable learnings read from every issue's `learnings.md` and **proposed** for promotion into the sandbox's `AGENTS.md` / `.specwright/conventions/` — applied only after the user approves (the scripted user approves a subset, so both accepted and rejected proposals are observed); the board left frozen as history (no state edits after the summary); and the session ending by handing PR merges back to the human.

Additionally, consolidate this milestone's own dossier: gather every T-issue's `findings.md` into a single summary the follow-up fixes delivery can be planned from.

## Motivation

Closeout is where a milestone's paid-for knowledge either becomes durable (promoted conventions) or evaporates; and where this validation milestone converts its observations into the fixes backlog. T8 of the test plan.

## Non-Goals

- No merging of sandbox deliveries; that stays with the (scripted) human.
- No writing of the fixes issues/milestone — the dossier seeds a later brainstorm; this issue only consolidates.

## Acceptance Criteria

Number each criterion sequentially as `AC-N` — the IDs are stable handles that `tasks.md` references and that `/sw:review` walks to prove every criterion was delivered. Each criterion must be a binary, observable check verifiable in under a minute.

- [ ] **AC-1** The sandbox board ends with a final summary section listing every shipped issue with its delivery record and the blocker history; no Issues-table or Dispatch-Log rewriting (diff against pre-closeout copy shows appends only).
- [ ] **AC-2** The session proposed promoting at least the epoch-seconds learning, waited for approval, applied exactly the approved subset to `AGENTS.md`/`.specwright/conventions/`, and left rejected proposals unapplied (transcript + file diff evidence).
- [ ] **AC-3** After closeout the sandbox milestone folder receives no further writes from the session (transcript tail shows the report and stop; merging explicitly left to the human).
- [ ] **AC-4** This issue's folder contains `dossier.md`: every finding from all T-issues' `findings.md`, deduplicated, each with Expected / Observed / Proposed fix and the owning issue — ready to seed the follow-up fixes delivery.
- [ ] **AC-5** `findings.md` has a verdict per check above and one Expected / Observed / Proposed-fix entry per failure.

Tick each `[x]` when verified. An issue is **not shippable** with empty or double-brace-placeholder acceptance criteria — `validate-spec.sh` and `/sw:review-spec` will reject it.
