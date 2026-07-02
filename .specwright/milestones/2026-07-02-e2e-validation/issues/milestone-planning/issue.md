---
feature: milestone-planning
created: 2026-07-02
status: in-progress
shipped: null
---
# Milestone Planning (T2) — Issue

> The ticket: the approved *why* plus the acceptance criteria and the issue's status. `status:` lives **only** here — `pending | in-progress | shipped | blocked` — and `shipped:` gets the ship date when the PR is open and `/sw:review` reached `lgtm`. The technical *how* (architecture, file structure, tasks) lives in the sibling `spec.md` + `tasks.md`, written just-in-time by `/sw:plan`.

## Purpose

Audit the milestone artifacts the `scope-detection` brainstorm produced in the sandbox against the planning contract: `goal.md` carries purpose and milestone-level success criteria with zero technical content; `board.md` carries order and dependencies without duplicating issue status; every issue folder has an `issue.md` ticket with verifiable `AC-N` and `status: pending` frontmatter; the post-design batch asked **only** the worktree question; a mandatory handoff was printed and the planning session stopped without conducting.

The audit reads the sandbox artifacts and the saved `scope-detection` transcript — it drives no new sessions except where evidence is missing.

## Motivation

The planning artifacts are the orchestrator's only input — a `goal.md` polluted with technical decisions, a board that duplicates status, or a session that starts conducting after planning each corrupt the loop in a different way. T2 of the test plan.

## Non-Goals

- No re-running of the brainstorm; the fixture is what `scope-detection` left behind.
- No editing of the sandbox artifacts, even to fix defects found — findings only.

## Acceptance Criteria

Number each criterion sequentially as `AC-N` — the IDs are stable handles that `tasks.md` references and that `/sw:review` walks to prove every criterion was delivered. Each criterion must be a binary, observable check verifiable in under a minute.

- [ ] **AC-1** Verdict recorded for `goal.md`: has Purpose, Motivation, milestone-level Success Criteria, Non-Goals; contains no file paths, function names, storage formats, or other technical content.
- [ ] **AC-2** Verdict recorded for `board.md`: Issues table with order + dependencies; no `status` column or per-issue status text anywhere in the file; Dispatch Log and Blockers sections present and empty.
- [ ] **AC-3** Verdict recorded for every sandbox issue: `issue.md` exists with frontmatter `status: pending`, plain kebab slug (no number prefix), and numbered binary `AC-N` — checked mechanically where possible (`validate-spec.sh` accepts each issue folder's ticket or names the defect).
- [ ] **AC-4** Verdict recorded from the `scope-detection` transcript: the post-design batch asked exactly one thing (worktrees), the printed handoff names the milestone path and `/sw:run` as the resume command, and no conduction happened after it (no dispatch, no code edits in the transcript tail).
- [ ] **AC-5** `findings.md` has a verdict per check above and one Expected / Observed / Proposed-fix entry per failure.

Tick each `[x]` when verified. An issue is **not shippable** with empty or double-brace-placeholder acceptance criteria — `validate-spec.sh` and `/sw:review-spec` will reject it.
