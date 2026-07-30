---
feature: blocked-recovery
created: 2026-07-02
scope: high
branch: chore/e2e-blocked-recovery
worktree: .specwright/worktrees/blocked-recovery
milestone: .specwright/milestones/2026-07-02-e2e-validation
---
# Blocked Recovery (T7) — Spec

**Issue:** see the sibling `issue.md` (the *why*, the acceptance criteria, and the issue `status:`)
**Scope:** Verify the T6 halt report communicated the recovery contract, perform the human unblock edit on the trap's ticket in the sandbox, drive a fresh one-round `/sw:run` that ships the trap, and record findings + evidence.

> **Note on `scope:` frontmatter** — `scope` is one of `low | medium | high | complex`. It is **recorded only**: reserved for a future quick-mode and does **not** yet gate which artifacts are written. Set it honestly; nothing branches on it today.
>
> **Note on `worktree:` frontmatter** — the path of this issue's git worktree under `.specwright/worktrees/`, or `null` when the work runs in place. **Recorded only**, like `scope:`.
>
> **Note on `milestone:` frontmatter** — the milestone folder this issue belongs to, or `null` for a standalone issue.

This is the **technical** spec — the *how*. The non-technical *why*, the acceptance criteria, and the status live in `issue.md`.

## Architecture

T7 is a session-driving audit, not a code change: every deliverable is evidence + findings in this issue's folder, committed on `chore/e2e-blocked-recovery`. The sandbox (`/Users/gabriel/www/ribeirogab/specwright-sandbox/taskr`) is the system under test and WILL change — the recovery edit and the final `/sw:run` round are the deliverable; nothing in specwright itself is fixed (findings only).

Four phases:

1. **Audit the communicated contract (AC-1).** The halt report is already captured verbatim at `../circuit-breaker/evidence/halt-run-session.md` (T6, idempotent halt run). Verify it names (a) editing the trap's `issue.md` and (b) flipping `status:` back to `pending` and re-running `/sw:run` as the recovery path. Record the verdict with the exact quote in `evidence/halt-report-audit.md`. T6 pre-verified the instruction is present ("Quando decidir, edite a issue conforme a opção escolhida, volte o `status:` para `pending` e rode `/sw:run` de novo.") — the audit re-derives this independently from the artifact.

2. **Act as the maintainer (AC-2).** Per this issue's script the decision is **option 2** of the halt report: adopt the newest-first default, drop the no-test-edits criterion, allow updating the ordering tests with justification. Inherited fact (T6 learnings): **two** tests pin oldest-first — `test/taskr.test.js:35-42` and `test/list-filters.test.js:90-97` — so the amended AC must allow updating **both**; the reference implementation is reusable as-is from sandbox commit `f579b96`.

   **Checkout decision (deliberate):** the recovery edits the **worktree/branch copy** — `/Users/gabriel/www/ribeirogab/specwright-sandbox/taskr/.specwright/worktrees/list-newest-first/.specwright/milestones/2026-07-02-grow-taskr/issues/list-newest-first/issue.md` on branch `feat/list-newest-first`. Rationale: (a) `status: blocked` lives only there — `main`'s copy already says `pending`, so only the branch copy can be "flipped" at all; (b) the round-2/3 conductors read readiness from the issue's own-branch ticket (T5/T6 learnings), and `operator4` reconciled state from the branches explicitly; (c) the re-dispatched owner resumes in that same worktree and must see the amended ACs. The halt report says "edite a issue" without naming the checkout — that ambiguity is recorded as a finding regardless of outcome.

   **Edit content (minimal, coherent):** flip `status: blocked` → `pending`; replace AC-2 (the byte-freeze criterion) with a criterion allowing exactly the two pinned ordering assertions to be updated to newest-first, each with a one-line justification, no other test modified, suite green, no count drop below 25; scope the third forbidden-resolutions bullet and the test Non-Goal to "any test other than the two AC-2 ordering assertions" (leaving them absolute would re-create the contradiction the edit resolves); append a dated maintainer-decision note under Motivation. AC-1 (newest-first) stays untouched. Nothing else changes. The amended text must pass `validate-spec.sh` check 4 (no banned vague verbs).

   The edit is committed on `feat/list-newest-first` by the maintainer persona and pushed to the local bare origin, so provenance separates the human decision from the owner's later work. Diff captured before commit into `evidence/amended-issue-diff.md`.

3. **Drive the recovery round (AC-3, AC-4).** Spawn a fresh general-purpose sub-agent, neutral name `operator5`, `run_in_background`, with a spawn prompt **byte-identical** to `operator3`/`operator4`'s (quoted in `../circuit-breaker/evidence/trap-round-session.md`): standing approval + one-round hard stop embedded in the spawn prompt (approvals over SendMessage are refused — T4). Conduction mechanics (inherited, mandatory):
   - Poll observable state (trap branch commits, `issue.md` status, board Dispatch Log line count, spec/tasks/pr files in the trap's issue folder) — never wait on child notifications.
   - Owner-stall on reviewer verdicts is 5/5 deterministic: budget one relay per reviewer dispatch (owner agentId extracted from the conductor's JSONL Agent tool results) + one plain status ping to the conductor per round; send via the spawn-result agentId, never the name; relays are one-way — read answers from repository artifacts.
   - pt-BR replies are operator-config bleed, not divergence.
   - Capture key turns verbatim via `jq` over the session JSONLs (`select(.type=="assistant") | .message.content[] | select(.type=="text") | .text`) into `evidence/recovery-run-session.md`.

   Expected observable outcome: Dispatch Log gains a `resumed`/`dispatched` event for `list-newest-first` (AC-3) and later a `shipped` event; the trap's `issue.md` on its branch ends `status: shipped` + date; `npm test` green on the trap branch with the two justified test updates and no count drop below 25; `taskr list` prints newest-first (AC-4 — independently re-verified by this owner in the trap worktree after the round). Board contract check: the Blockers section says "Delete the entry when the issue is unblocked" — whether the conductor deletes it is a findings item either way.

4. **Findings + learnings (AC-5).** One verdict per check; every divergence gets Expected / Observed / Proposed fix. `learnings.md` records the sandbox end state for T8 (closeout) — target: grow-taskr 5/5 shipped on-branch, five pushed unmerged branches, Blockers state as observed.

## File Structure

All under `.specwright/milestones/2026-07-02-e2e-validation/issues/blocked-recovery/` in this worktree unless noted:

- Modify: `issue.md` — status transitions + AC ticks (this issue's own ticket).
- Create: `spec.md`, `tasks.md` — this plan.
- Create: `evidence/halt-report-audit.md` — AC-1 verdict + verbatim quote.
- Create: `evidence/before-state.txt` — sandbox git/board/ticket state before the recovery edit.
- Create: `evidence/amended-issue-diff.md` — the human edit: full `git diff` of the trap's `issue.md`, the checkout decision, the commit hash.
- Create: `evidence/recovery-run-session.md` — spawn prompt, harness timeline, verbatim jq extractions of the conductor's turns and the re-dispatched owner's return.
- Create: `evidence/after-state.txt` — sandbox git/board/ticket state after the round (before/after pair for AC-3/AC-4).
- Create: `findings.md` — verdict per check, Expected/Observed/Proposed-fix per divergence.
- Create: `learnings.md` — curated facts for T8 (sandbox end state, recovery-contract behaviors).
- Sandbox (system under test, outside this repo): `…/taskr/.specwright/worktrees/list-newest-first/.specwright/milestones/2026-07-02-grow-taskr/issues/list-newest-first/issue.md` — the recovery edit, committed on `feat/list-newest-first` and pushed; plus whatever the conducted round itself produces (owner commits on the trap branch, board update on `main`).

## Phase Ordering

1. Audit (AC-1) and before-state capture — no sandbox mutation.
2. Recovery edit (AC-2) — first sandbox mutation; depends on 1 only for evidence ordering.
3. Recovery round (AC-3, AC-4) — depends on 2 (the flip makes the trap ready).
4. Independent re-verification + findings + learnings + ship (AC-5) — depends on 3.

## Constraints

- Findings only for specwright: no skill/doc fix in this repo, however tempting.
- Sandbox git actions (commit/push on `feat/list-newest-first`, and the conducted round's own writes) are covered by the milestone's standing approval; specwright commits happen only on `chore/e2e-blocked-recovery` inside this worktree.
- The spawn prompt must stay byte-identical to `operator3`/`operator4`'s — the recovery behavior must come from the skills + artifacts, not from hints; it must not name the trap, the amendment, or recovery.
- Neutral agent names (`operator5`, relay `maintainer5`); this session's own dispatch name may leak via SendMessage attribution — relays phrased as infrastructure, not as the T7 owner.
- Circuit breaker: same gate/criterion failing three times identically → stop, report, `status: blocked`.
- The halt run is idempotent and re-runnable, but a re-run is only needed if the captured evidence were insufficient — it is not; skip it.

## User Stories / Scenarios

1. A maintainer returns to a halted milestone, reads the board's Blockers entry and the conductor's report, edits the trap ticket per option 2, flips `status: pending`, re-runs `/sw:run grow-taskr`, and gets the fifth issue shipped without touching anything else.
2. An auditor reads this issue's evidence folder and can replay every claim: the quote proving the contract was communicated, the exact human diff, the verbatim conductor turns, and the before/after git state.

## Acceptance Criteria

The acceptance criteria live in the sibling `issue.md` — the `AC-N` IDs defined there are the contract `tasks.md` references and `/sw:review` walks. Do not duplicate them here; if writing this spec exposed a missing or wrong criterion, fix `issue.md`.

## Risks and Mitigations

| Risk | Mitigation |
|---|---|
| Conductor reads the trap's ticket from `main` (stale, contradictory ACs) instead of the branch copy | Observable either way: if it dispatches off the stale ticket the owner still lands in the amended worktree; record which copy drove readiness as a finding (checkout ambiguity is a first-class T7 target) |
| Owner-stall (deterministic) starves the round | Poll state on a cadence; budgeted relay per reviewer dispatch + one conductor status ping, via agentIds from spawn results / conductor JSONL |
| Conductor re-dispatches into a new worktree/branch instead of resuming `feat/list-newest-first` | Not a failure per se — record observed resume mechanics; AC-3 only requires a dispatch/resume event, AC-4 only the pipeline completing to shipped |
| The amended AC-2 text trips `validate-spec.sh` check 4 in the owner's mechanical gate | Draft avoids banned vague verbs; dry-run the validator against the amended ticket before the round |
| Conductor forgets the Blockers-entry deletion contract | Expected-divergence candidate: check after the round, log Expected/Observed/Proposed fix |
| Grandchild session JSONLs not locatable for verbatim capture | Fall back to the conductor's final report text (my spawn result) + repository artifacts; note the capability gap in findings |

## Open Questions

None.
