# Blocked Recovery (T7) — Findings

Verdict per check, then one Expected / Observed / Proposed-fix entry per divergence. Findings only — nothing was fixed in specwright by this issue.

## Verdicts

| # | Check | Verdict | Evidence |
|---|---|---|---|
| 1 | Halt report communicates the recovery contract (edit issue.md + flip to `pending` + re-run) | **PASS** | `evidence/halt-report-audit.md` — verbatim: "Quando decidir, edite a issue conforme a opção escolhida, volte o `status:` para `pending` e rode `/sw:run` de novo." (halt-run-session.md line 29). The omission-finding does not materialize. |
| 2 | Human edit minimal and recorded | **PASS** | `evidence/amended-issue-diff.md` — one file, 5 hunks (status flip + the contradiction's four restatements rescoped), commit `1be3afa` pushed; everything else untouched. |
| 3 | Fresh `/sw:run` treats the trap as ready and dispatches without special-casing | **PASS** | Dispatch Log gained `resumed` + `dispatched` (round 4) — the conductor read the amended on-branch ticket, cited the maintainer commit `1be3afa` unprompted, and **reused** the existing worktree/branch. Spawn prompt byte-identical to round 3's and the halt run's (no hint of the unblock). |
| 4 | Trap completes the pipeline to `shipped` | **PASS** | `evidence/after-state.txt` + `recovery-run-session.md`: replan `8eb07ff` → impl `f377675` (f579b96 sort reused verbatim) → `882d28e` → ship `a15025c`; 25/25 green (no count drop), exactly the two sanctioned test hunks (assertion form preserved), newest-first runtime-verified independently by this owner; `status: shipped, shipped: 2026-07-02`; review lgtm; pr.md on-branch. |
| 5 | Blockers entry deleted when unblocked (documented contract: "Delete the entry when the issue is unblocked") | **PASS** | Board on main @ `5a9b369`: Blockers section is `_None._`; the `resumed` log line says "Blockers entry cleared" explicitly. The expected-divergence candidate did **not** materialize — the contract self-executed. |
| 6 | One-round hard stop with all-shipped state | **PASS** | Conductor stopped after logging `shipped`; explicitly deferred closeout (final summary, learnings promotion, goal.md reconciliation) to a future run — T8's entry state is clean. |

## Divergences and gaps

### Divergence 1 — the halt report never names WHICH checkout to edit (and it matters)

- **Expected:** a recovery instruction executable by a maintainer with no knowledge of the milestone's stacked-branch mechanics. The ticket exists in two states: `status: blocked` on `feat/list-newest-first` (worktree copy) and `status: pending` with the old contradictory ACs on `main`.
- **Observed:** the halt report says only "edite a issue conforme a opção escolhida, volte o `status:` para `pending`" — no path, no branch, no mention that two copies exist. A maintainer editing `main`'s copy would flip nothing (it already says `pending`) and amend a ticket the re-dispatched owner never reads: the conductor reads readiness from the on-branch ticket and the owner resumes in the trap's worktree (both confirmed this round). It also never says whether the edit should be committed/pushed — an uncommitted working-tree edit would have satisfied this round's readiness check but leaves the maintainer decision unrecorded in history and clobberable.
- **Proposed fix:** the run skill's escalation/consolidated-report contract should require the blocked report's recovery line to name the exact file path in the issue's own checkout (worktree or branch) and to say "commit the edit on the issue's branch". One sentence in `plugins/sw/skills/run/SKILL.md` (and the `.agents` mirror) closes it. Charge to milestone closeout (T8) with the other skill-wording reconciliations.

### Divergence 2 — "the contradictory criterion" is four passages, not one

- **Expected (T7's own AC-2 wording):** remove/replace the contradictory criterion, everything else untouched.
- **Observed:** the contradiction was restated in four places in the trap's ticket — the AC-2 line, Purpose ("existing tests stay exactly as they are"), forbidden-resolutions bullet 3 (absolute test-modification ban), Non-Goals bullet 3 ("Any change to `test/taskr.test.js`."). Rescoping only the AC line would have left a Purpose/forbidden-list contradiction for a strict owner to re-block on; the minimal *coherent* edit took 5 hunks (all justified hunk-by-hunk in `evidence/amended-issue-diff.md`), and the round-4 owner indeed shipped against it without re-blocking.
- **Proposed fix:** none to specwright (ticket-authoring reality, not a skill defect). For future blocked reports, the "edit the issue per the chosen option" instruction could remind the maintainer to sweep the whole ticket for restatements of the dropped constraint. Note for T8's promotion pass: worth one line in a conventions/brainstorm note ("state a constraint once; every restatement is a future amendment hazard").

### Divergence 3 — the trap ticket on `main` is now semantically stale, not just status-stale

- **Expected:** one authoritative ticket per issue.
- **Observed:** the known T4/T5 pattern (status lives on-branch, `main` copies say `pending`) now extends to **content**: `main`'s copy still carries the original contradictory AC-2 and the absolute test freeze, while the shipped contract lives on `feat/list-newest-first`. Anyone auditing from `main` alone reads a ticket that was never satisfiable.
- **Proposed fix:** nothing new to build — merging the stacked PRs reconciles it (the human's queued action). T8 should audit post-merge ticket consistency if merges happen; otherwise record it as the expected cost of the unmerged-stack window.

### Divergence 4 — the driver-name leak reproduced through the T7 harness itself

- **Expected (own spec constraint):** relays phrased as infrastructure and sent so that no issue-slug-bearing name reaches the session under test (T6 used a separately spawned neutral relay, `maintainer3`).
- **Observed:** this owner sent the budgeted status ping via SendMessage directly from its own session; the conductor received it as `<agent-message from="owner-blocked-rec">` — the dispatch-name attribution channel (T1/T4/T5) confirmed again, fourth reproduction. Mitigating facts: the ping text was neutral and identical to T6's; by ping time the recovery-relevant behaviors (resume, Blockers cleanup, dispatch, owner shipped) had already happened, so the leak could not have steered them; "blocked-rec" names T7's issue, not the trap.
- **Proposed fix:** the conduction-mechanics learning should be sharpened from "name the agents you spawn neutrally" to "never SendMessage a session under test from a slug-named session — spawn a neutral relay for every ping". Candidate for `AGENTS.md`/conventions promotion at closeout.

### Confirmations (no divergence, worth the record)

- **Owner-stall on background-child completion: 6/6.** The conductor sat idle after its owner returned; one plain status ping un-stalled it, and it independently re-verified from artifacts (re-ran `npm test` itself) before logging — same shape as rounds 1-3 and T5/T6.
- **The `resumed` event exists in the wild:** the board template's event vocabulary (`dispatched / shipped / blocked / resumed`) got its first `resumed` line, written unprompted with the maintainer's commit hash and decision summary — the recovery contract's full loop (blocked → report → human edit → resumed → shipped) is now exercised end to end.
- **goal.md staleness (owner-flagged, routed, not fixed):** the sandbox `goal.md` still says `test/taskr.test.js` stays byte-for-byte untouched — superseded for the two ordering assertions by the recorded option-2 decision. The round-4 owner flagged it to closeout in its pr.md review note and the board line; goal edits are a human scope change, so T7 left it alone. T8 inherits it explicitly.
