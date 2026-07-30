# Halt-Report Audit (AC-1) — Was the recovery contract communicated?

**Artifact audited:** `../circuit-breaker/evidence/halt-run-session.md` — the verbatim jq capture of `operator4`'s halt run (T6's final run over the fully-dispatched grow-taskr board: 4 shipped + 1 blocked, zero ready issues). T6 verified the capture is faithful to the session JSONL (`agent-a6b7e29689defe3f3.jsonl`); the halt run is idempotent, so a re-run for a fresh capture was available but unnecessary — the existing artifact is verbatim and complete.

**Audit method:** independent re-read of the full artifact by the T7 owner, plus targeted greps for the contract elements. This audit does not rely on T6's own conclusion; the quotes below were re-extracted from the artifact directly.

## Verdict: PASS — the flip instruction is present, verbatim

The consolidated blockers report ends with the recovery instruction (artifact line 29):

> Quando decidir, edite a issue conforme a opção escolhida, volte o `status:` para `pending` e rode `/sw:run` de novo. Os 4 PRs enviados (empilhados sobre `feat/task-priority`) aguardam seu merge.

The omission-finding contemplated by AC-1 ("a report that omits the flip instruction is itself a finding") does **not** materialize.

## Check breakdown

| Contract element | Present? | Evidence (artifact line) |
|---|---|---|
| Names editing the trap's `issue.md` as the recovery move | yes | line 29: "edite a issue conforme a opção escolhida" |
| Names flipping `status:` back to `pending` | yes | line 29: "volte o `status:` para `pending`" |
| Names re-running `/sw:run` | yes | line 29: "rode `/sw:run` de novo" |
| Gives the maintainer a concrete decision menu | yes | lines 25-27: two explicit options — (1) keep the frozen-test contract → drop AC-1; (2) adopt newest-first → amend both pinned contracts (`test/taskr.test.js:35-42`, `test/list-filters.test.js:90-97`), reference implementation `f579b96` ready for reuse |
| Points at the full evidence trail | yes | line 23: `blocked-evidence.md` on branch `feat/list-newest-first` (commit `c74e996`) |
| Names WHICH checkout of `issue.md` to edit | **no** | "edite a issue" names no path/branch; the ticket exists in two states — `status: blocked` on `feat/list-newest-first` (worktree copy) and `status: pending` with the old contradictory ACs on `main` |
| Says whether the edit should be committed/pushed | **no** | no mention |

## Consequence of the two gaps

Both gaps are recoverable by a maintainer who understands the milestone's stacked-branch state (the flip is only meaningful on the copy that says `blocked`), but neither is stated. A maintainer who edits `main`'s copy would (a) not flip anything — it already says `pending` — and (b) amend a ticket the re-dispatched owner never reads, since the owner resumes in the trap's worktree on its branch. Logged as a finding (checkout ambiguity) in `findings.md`; the deliberate checkout decision T7 takes is recorded in `evidence/amended-issue-diff.md`.
