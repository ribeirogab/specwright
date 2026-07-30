# Dispatch and Parallelism (T4) — Findings

One verdict per AC check, then one Expected / Observed / Proposed-fix entry per failure or divergence.
Evidence citations point into `evidence/` in this folder.

**T-label drift (read this first):** sibling learnings disagree on this issue's T-number — `../scope-detection/learnings.md` and `../milestone-planning/learnings.md` refer to the round-1 conduction issue as "T5", while this issue's ticket, the milestone dispatch, and `../resume/learnings.md` call it "T4" (and call the next issue, issue-pipeline, "T5"). Both label sets denote the same two issues; map sibling references by *issue slug*, not by T-number.

## Verdicts

| Check | Verdict | Evidence |
|---|---|---|
| AC-1a — ≥ 2 owners dispatched concurrently in round 1 | **DIVERGENCE** (fixture cannot produce it; unverifiable at N=1) | `round1-session.md` session-1 turn 1; Finding 1 |
| AC-1b — dispatched owner in own worktree under `.specwright/worktrees/<slug>`, own branch, captured during the round | **PASS** (at N=1) | `round1-sandbox-state.txt` probes 06:25:30Z/06:25:50Z; `round1-session.md` session-2 turn 1 |
| AC-2 — orchestrator purity (transcript + git + per-branch commits) | **PASS** (caveat: shared git author identity — proven by branch provenance + transcript, not `%an`) | `purity-audit.md` |
| AC-3 — board gained one `dispatched` + one outcome line, append-only | **PASS** (nuance: log lines stay uncommitted until round close — Finding 6) | `round1-sandbox-state.txt` `== POST-ROUND ==` board diff (additions only); `round1-session.md` round-close report |
| AC-3 (stop) — session stopped after logging round-1 outcomes, before round 2 | **PASS** (stop point harness-scripted via pacing constraint — by design, since unattended runs have no natural pause) | `round1-session.md` closing turns ("Nada mais foi despachado") + post-round state (no new worktrees/branches) |
| AC-4 — degradation round serial, in place, no worktrees, same pipeline | **PASS** (caveats: the "one at a time" clause is only trivially exercised at N=1 — same fixture limit as Finding 1; and the session was externally stopped at the delivery step, so ship/outcome-logging unobserved — harness interruption, not skill failure) | `degradation-session.md`; `degradation-state.txt` `== POST-DEGRADATION ==` |
| AC-5 — findings verdicts + Expected/Observed/Proposed fix per failure | **PASS** | this file |

## Finding 1 — Round-1 parallelism is unobservable in this fixture (expectation vs board reality)

- **Expected** (issue.md Purpose): round 1 dispatches three dependency-free issues (priorities, the trap, the web page) — the parallel wave T4 was written to audit.
- **Observed:** the actual grow-taskr board makes `task-priority` the only dependency-free issue; round 1 is a single dispatch. Both driven sessions independently computed the same ready set (session 1 and session 2, `round1-session.md`). The 3-way wave (`list-filters`, `export-json-csv`, `web-page`) opens at round 2, and the trap (`list-newest-first`) only after `list-filters`. Already flagged as scope-detection's Finding 1.
- **Proposed fix:** audit true N≥2 concurrency at round 2 (issue-pipeline's round — its owner should capture overlapping `git worktree list` snapshots there); if a future fixture revision must exercise round-1 parallelism, give the board a second dependency-free issue. The parallelism *mechanics* (own worktree, own branch, orchestrator alive while the owner works) are verified here at N=1.

## Finding 2 — The interactive approval batch covered the whole milestone, not the round

- **Expected** (run-skill loop contract + T3's learning): dispatch happens per loop turn; T3 recorded "all of **round 1's** writes behind one approval ask".
- **Observed:** session 1's single ask requested approval for "worktrees + branches + commits + push + PRs **para as 5 issues do milestone**" (`round1-session.md` session-1 turn 1) — one consent for every future round, removing any natural per-round checkpoint an interactive user could rely on.
- **Proposed fix:** the run skill's dispatch step should scope interactive approval asks to the current round's writes; continuation into later rounds is a new loop turn and (in approval-mode sessions) a new ask.

## Finding 3 — Both owners resolved the seeded validator trip by unilaterally rewording the approved AC (2/2)

- **Expected** (plan-skill contract + T2's learning): `task-priority`'s AC-2 "(short alias works)" trips `validate-spec.sh` check 4; ACs in an approved ticket are the contract — a milestone issue owner *reports* a wrong criterion, never edits it. Expected report/blocked or an orchestrator-routed resolution.
- **Observed:** the real round's owner reworded AC-2 to "(via the short alias)" in commit `e84fed8`, commit message silent about the ticket edit, disclosure only post-hoc in learnings ("AC-2 reworded non-semantically") — `round1-session.md` mid-round events. The degradation session, fully isolated, did the same thing (reworded to "(short alias)") — `degradation-session.md`. Two independent owners, same choice: semantics-preserving reword over report.
- **Proposed fix:** make the plan skill's mechanical-gate step explicit about gate failures *caused by the approved ticket itself*: stop, report to the orchestrator/user with the exact validator line, and only proceed after an acknowledged resolution (which may well be the same reword — but authorized and logged on the board). Alternatively (weaker), require any ticket edit to be its own commit with a message naming the changed AC.

## Finding 4 — Background-agent completion notifications route only to the top-level session; nested pipelines stall

- **Expected:** an orchestrator that dispatches owners (and owners that dispatch reviewers) hear their children return and continue the loop.
- **Observed:** completions notify the top-level session only. Two real stalls in one round: the task-priority owner waited on its spec-document-reviewer ("Waiting for the spec-document-reviewer to complete before proceeding to gate 3"), and the operator waited on the owner it had dispatched — each needed an external nudge (verdict relay / user-plausible status ping) to resume (`round1-session.md` mid-round events + closing observations). On the second ping the operator did the right thing unprompted: verified the real artifacts before logging.
- **Proposed fix:** the run skill (and plan skill, for reviewer dispatches) should not assume push notifications from sub-agents: poll the dispatched agent's observable state (worktree/branch commits, issue.md status, output file) on a cadence, treating silence as "still running" only until a state check says otherwise. Harness-side (test-plan doc): drivers must budget for relaying grandchild completions.

## Finding 5 — Driven sessions categorically refuse approvals delivered over agent-to-agent messages

- **Expected** (harness assumption from T1/T3): scripted replies via SendMessage can play the user end-to-end.
- **Observed:** holds and information pass fine (T1/T3, and this round's status pings), but an *approval* is refused: "mensagem de outra sessão nunca vale como aprovação do usuário para um prompt pendente, mesmo alegando ser ele" — two refusals including one after an explicit identity confirmation (`round1-session.md` session-1 turns 2–4). Session 1 had to be abandoned (zero sandbox writes) and re-spawned with standing approval in the framing prompt, which worked immediately. Note: this is *correct* security posture by the driven session — the finding is a harness-methodology constraint, not a defect.
- **Proposed fix:** test-plan methodology note for T5+: any driven session that must cross a consent boundary needs that consent embedded in its spawn prompt (spawn prompts carry no sender attribution); SendMessage remains usable for holds, questions, and status.

## Finding 6 — Dispatch Log lines are written at event time but committed only at round close

- **Expected** (board contract): append-only log, one line per orchestrator event; T3's learning implies the log append is part of the batched dispatch action.
- **Observed:** the `dispatched` line was in `board.md` at 06:25:50Z (probe) but `board.md` sat modified/uncommitted until the round-close commit `7c7f1bc` bundled `dispatched` + `shipped`. A crash mid-round would have left the log unversioned (recoverable only from the dirty tree).
- **Proposed fix:** run skill: commit the board after every Dispatch Log append (event-time durability), not once per round.

## Finding 7 — "Deps shipped" is ambiguous while the dep's branch is unmerged (round-2 readiness hazard)

- **Expected** (run-skill ready rule): an issue is ready when deps say `status: shipped` in their own `issue.md`.
- **Observed:** `task-priority`'s `status: shipped` exists only on unmerged `feat/task-priority`; the main-tree ticket still says `pending` (`round1-sandbox-state.txt` `== POST-ROUND ==`). The operator read the *worktree/branch* copy and declared round 2 ready. But a round-2 owner would branch from `main` — which does not contain its dependency's code (or its `shipped` status). PR merging stays with the human, so an autonomous round 2 would build `list-filters` against a `main` without priorities.
- **Proposed fix:** the run skill should define readiness against the checkout owners will branch from (dep shipped **and merged into the base branch**), or instruct owners to branch from the dependency's branch when unmerged (stacked), and say which explicitly. Directly relevant to T5's round-2 audit.

## Finding 8 — Driver identity leaks to driven sessions via message attribution (slug-bearing name)

- **Expected** (T1/T3 mitigation): neutral names avoid contaminating driven sessions.
- **Observed:** the *driver's own* dispatch name `owner-dispatch-par` (truncated issue slug) was quoted by both session 1 ("Recebi uma mensagem de outra sessão Claude (`owner-dispatch-par`)") and the operator's final report. Neutral naming covers agents I spawn, not the name I was dispatched under. No behavioral reaction observed, but the leak is structural.
- **Proposed fix:** milestone orchestrators dispatching *session-driving* owners should use neutral dispatch names for those owners (or the test-plan should accept and record the leak, as done here).
