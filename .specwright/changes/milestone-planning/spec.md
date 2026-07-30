---
feature: milestone-planning
created: 2026-07-02
scope: low
branch: chore/e2e-milestone-planning
worktree: .specwright/worktrees/milestone-planning
milestone: .specwright/milestones/2026-07-02-e2e-validation
---
# Milestone Planning (T2) — Spec

**Issue:** see the sibling `issue.md` (the *why*, the acceptance criteria, and the issue `status:`)
**Scope:** Audit the grow-taskr planning artifacts and the saved scope-detection transcript against the planning contract, recording verdicts and Expected/Observed/Proposed-fix entries in `findings.md`.

> **Note on `scope:` frontmatter** — `scope` is one of `low | medium | high | complex`. It is **recorded only**: reserved for a future quick-mode and does **not** yet gate which artifacts are written. Set it honestly; nothing branches on it today.
>
> **Note on `worktree:` frontmatter** — the path of this issue's git worktree under `.specwright/worktrees/`, or `null` when the work runs in place. **Recorded only**, like `scope:`.
>
> **Note on `milestone:` frontmatter** — the milestone folder this issue belongs to, or `null` for a standalone issue.

This is the **technical** spec — the *how*. The non-technical *why*, the acceptance criteria, and the status live in `issue.md`.

## Architecture

This is a read-only audit, not a code change. The subject under test is a fixture that already exists; the deliverable is a findings document plus the raw evidence that backs each verdict.

**Inputs (read-only):**

1. The grow-taskr milestone fixture — `/Users/gabriel/www/ribeirogab/specwright-sandbox/taskr/.specwright/milestones/2026-07-02-grow-taskr/` at sandbox commit `aaa117b`: `goal.md`, `board.md`, and five issue folders (`task-priority`, `list-filters`, `export-json-csv`, `web-page`, `list-newest-first`), each holding only `issue.md` (planning stage — `spec.md`/`tasks.md` are written just-in-time later by owners).
2. The saved scope-detection transcript — `../scope-detection/evidence/milestone-session.md` (78 lines) plus `milestone-artifacts.txt` in the same folder. Per the evidence file's own recording convention (`milestone-session.md` line 5) and the fidelity note in `../scope-detection/findings.md`, the transcript is mostly **relayed summaries** — user messages verbatim, session turns relayed — not verbatim session output — every transcript-based verdict must state whether it rests on verbatim text or on a relay, and a relay can support "consistent with the contract" but never "verbatim proof".

**The planning contract audited (one check per AC):**

- `goal.md` (AC-1): has Purpose, Motivation, milestone-level Success Criteria, Non-Goals; zero technical content (no file paths, function names, storage formats, CLI flags, or implementation choices).
- `board.md` (AC-2): Issues table carries order + dependencies; **no** `status` column and no per-issue status text anywhere; Dispatch Log and Blockers sections present and empty.
- Every issue ticket (AC-3): `issue.md` exists, frontmatter `status: pending`, folder slug is plain kebab (no `NN-` number prefix), AC are numbered `AC-N` and binary. Mechanical layer: run `skills/sw/scripts/validate-spec.sh <folder>` on each of the five folders.
- Transcript (AC-4): the post-design batch asked exactly one thing (worktrees); the printed handoff names the milestone path and `/sw:run` as the resume command; no conduction after the handoff (no dispatch, no code edits in the transcript tail).
- `findings.md` (AC-5): one verdict per check above; one Expected / Observed / Proposed-fix entry per divergence.

**Mechanical-check caveat (validator vs planning stage):** `validate-spec.sh` check 2 hard-fails when `spec.md` is missing, and check 5 only runs when `tasks.md` exists. Planning-stage tickets legitimately have neither, so on this fixture the expected validator outcome per folder is exit 1 with exactly one line — `FAIL (check 2): spec.md not found in <dir>` — and nothing else. The audit records the full validator output as evidence and treats the check-2 line as the planning-stage baseline, not a defect; any *additional* FAIL line (check 1 frontmatter/status, check 3 placeholders, check 4 vague verbs) is a real divergence. `findings.md` must state this interpretation explicitly so the verdict is reproducible.

**Verdict discipline:** each check gets `PASS` or `FAIL` plus the evidence pointer (file + line, grep output, or validator output). Failures additionally get an Expected / Observed / Proposed fix block. The audit **fixes nothing** — the sandbox is read-only for this issue (milestone non-goal), and proposed fixes name the upstream skill/template that should change, not the fixture.

## File Structure

- Create: `.specwright/milestones/2026-07-02-e2e-validation/issues/milestone-planning/findings.md` — the verdicts: one section per AC-1..AC-4 check, Expected/Observed/Proposed-fix per divergence, plus the validator-baseline interpretation note.
- Create: `.specwright/milestones/2026-07-02-e2e-validation/issues/milestone-planning/evidence/validate-spec-runs.txt` — raw output of `validate-spec.sh` for each of the five fixture issue folders.
- Create: `.specwright/milestones/2026-07-02-e2e-validation/issues/milestone-planning/evidence/fixture-checks.txt` — raw grep/awk outputs backing the goal.md/board.md/ticket checks (technical-content sweep, status-column sweep, frontmatter extraction, slug listing).
- Modify: `.specwright/milestones/2026-07-02-e2e-validation/issues/milestone-planning/issue.md` — status transitions and AC checkboxes.
- Read-only: everything under `/Users/gabriel/www/ribeirogab/specwright-sandbox/taskr/` and `../scope-detection/evidence/`.

## Phase Ordering

Single phase — the four audit checks are independent reads; findings.md is written last because it aggregates them.

## Constraints

- **Sandbox is read-only.** No writes, no commits, no `git` state changes in `/Users/gabriel/www/ribeirogab/specwright-sandbox/` — findings only (issue non-goal). Verify the sandbox is still at `aaa117b` before auditing; if it moved, note the drift in findings.md and audit the `aaa117b` tree via `git show`.
- **No new driven sessions.** The transcript evidence is what scope-detection saved; T2 drives a session only if evidence for a contract point is missing entirely. Known from T1's saved evidence (`../scope-detection/evidence/milestone-session.md`, turns 5–6): the batch did ask only the worktree question and the handoff was printed with the session stopping — but those turns are relayed summaries (per the file's line-5 recording convention), so AC-4 verdicts must be phrased as "relay-consistent" where no verbatim quote exists.
- **Inherited learnings that bind this audit:** fixture path and commit (`aaa117b`, committed but not pushed); board dependency shape (`task-priority` sole root; `list-newest-first` depends on `list-filters`) — the board audit cross-checks the recorded dependencies against this shape; the driver-name leak (`owner-scope-detection` visible to the session) is a known transcript contamination, not a planning-contract violation.
- All repo writes happen inside the worktree on branch `chore/e2e-milestone-planning`; the PR base is `chore/e2e-scope-detection` (stacked) and the PR body must say so.
- No AI attribution anywhere.

## User Stories / Scenarios

1. A maintainer reads `findings.md` and can see, for each planning-contract point, PASS/FAIL, the exact evidence (file+line or command output), and — for failures — what the contract expected, what the fixture shows, and which upstream artifact (skill prompt, template) should change.
2. A future test-plan issue (e.g. T5 dispatch) reads the board verdict and knows whether the board it will drive against is contract-clean.

## Acceptance Criteria

The acceptance criteria live in the sibling `issue.md` — the `AC-N` IDs defined there are the contract `tasks.md` references and `/sw:review` walks. Do not duplicate them here; if writing this spec exposed a missing or wrong criterion, fix `issue.md`.

## Risks and Mitigations

| Risk | Mitigation |
|---|---|
| Transcript is a relay, not verbatim — AC-4 could overclaim | Every AC-4 verdict labels its evidence tier: `verbatim` (quoted text in the evidence file) vs `relay` (summary); relay evidence supports consistency, not proof, and the verdict says so |
| Validator check-2 failure misread as a fixture defect | Spec fixes the expected baseline (exactly one `FAIL (check 2)` line per folder); findings.md states the interpretation; any extra FAIL line is the real signal |
| "Zero technical content" is judgment-prone at the margins | Operationalize: flag file paths, function/identifier names, storage formats, CLI flags/commands, library names; record the grep sweep in evidence so the judgment is reproducible |
| Sandbox drifted past `aaa117b` since T1 | Check `git log` first; if drifted, audit `git show aaa117b:<path>` output instead of the working tree and note the drift |

## Open Questions

None.
