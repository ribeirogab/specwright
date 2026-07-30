---
feature: issue-pipeline
created: 2026-07-02
scope: complex
branch: chore/e2e-issue-pipeline
worktree: .specwright/worktrees/issue-pipeline
milestone: .specwright/milestones/2026-07-02-e2e-validation
---
# Issue Pipeline (T5) — Spec

**Issue:** see the sibling `issue.md` (the *why*, the acceptance criteria, and the issue `status:`)
**Scope:** Resume the sandbox milestone for round 2 (the 3-way parallel wave), then audit rounds 1 and 2 together against the eight pipeline guarantees, producing evidence, findings, and learnings — fixing nothing.

> **Note on `scope:` frontmatter** — `scope` is one of `low | medium | high | complex`. It is **recorded only**: reserved for a future quick-mode and does **not** yet gate which artifacts are written. Set it honestly; nothing branches on it today.
>
> **Note on `worktree:` frontmatter** — the path of this issue's git worktree under `.specwright/worktrees/`, or `null` when the work runs in place. **Recorded only**, like `scope:`.
>
> **Note on `milestone:` frontmatter** — the milestone folder this issue belongs to, or `null` for a standalone issue.

This is the **technical** spec — the *how*. The non-technical *why*, the acceptance criteria, and the status live in `issue.md`.

## Architecture

Two halves: **drive** then **audit**. All repo writes happen in this issue's worktree (`.specwright/worktrees/issue-pipeline`, branch `chore/e2e-issue-pipeline`, stacked on `chore/e2e-dispatch-parallelism`). The sandbox at `/Users/gabriel/www/ribeirogab/specwright-sandbox/taskr` is the system under test: round 2 changes it for real, and its post-round state is itself a deliverable (T6/T7 inherit it) — nothing there gets reverted or tidied.

**Drive (round 2).** A fresh conducting session is spawned as a general-purpose sub-agent (T4's parked `operator` session is not resumed — a fresh `/sw:run` re-entry also re-tests resume-from-files). Conduction mechanics inherited from T3/T4 learnings, all mandatory:

- **Standing approval + stop condition live in the spawn prompt** — driven sessions categorically refuse approvals over SendMessage (T4 Finding 5). The prompt grants standing approval for worktrees/branches/commits/pushes/PR-degradation records inside the grow-taskr milestone, and orders a hard stop after round 2's outcomes are logged on the board — **before any further dispatch**. The trap round (`list-newest-first`) belongs to circuit-breaker (T6/T7); this issue's scope ends at round 2.
- **Neutral names** — the conducting session and any relay agent get slug-free names (`operator2`, `maintainer`); the driver's own dispatch name leaks via SendMessage attribution (T4), so mid-run nudges are sent by a neutral-named relay agent, never directly by this owner session.
- **Poll, never wait** — nested completions notify only the top-level session (T4 Finding 4). A background prober snapshots `git worktree list`, `git branch -a`, and the board file with UTC timestamps on a fixed cadence for the entire round; overlapping worktree/branch snapshots are the N≥2 parallelism evidence T4 could not produce (its Finding 1 moved that observation here). The owner additionally polls the driven session's JSONL output file and relays grandchild verdicts via the relay agent when progress stalls.
- **Verbatim capture** — key turns are extracted from the driven session's JSONL with `jq` (`select(.type=="assistant") | .message.content[] | select(.type=="text") | .text`), never paraphrased (T2/resume learning).

**The Finding 7 hazard is observed, not defused.** `task-priority` is `shipped` only on unmerged `feat/task-priority`; the main-tree ticket says `pending`. The run skill's contract says owners branch "from the dependency's branch when the board says this issue depends on a not-yet-merged one (a stacked PR; the owner notes it in the PR body)". The spawn prompt must NOT leak the hazard or coach a resolution. Three observable outcomes, all legitimate evidence: (a) the session reads only `main`, sees no shipped dependency, and declares nothing ready — readiness-rule divergence recorded; (b) it stacks round-2 branches on `feat/task-priority` per the contract — contract-followed path recorded; (c) it asks the maintainer to merge `feat/task-priority` first — the relay may grant that as a legitimate maintainer action, recorded verbatim. Whichever occurs is a finding input.

**Audit (rounds 1+2 together).** Pure read-side forensics over the sandbox after round 2, checked against the eight guarantees in `issue.md`:

- **JIT planning (AC-1):** `git log --follow --format='%H %cI %s' -- <issue>/spec.md <issue>/tasks.md` per shipped issue proves the files' first commit falls inside the round, after dispatch (dispatch times come from the board log and probe timestamps); transcripts/evidence must name `validate-spec.sh`, the spec-document-reviewer, and `/sw:review-spec` actually running.
- **Learnings flow (AC-2):** grep the epoch-seconds fact in `task-priority/learnings.md` (producer) and its citation/respect in `export-json-csv/spec.md` (consumer). The fixture's ground truth: `createdAt` is `Math.floor(Date.now()/1000)` in `lib/tasks.js`.
- **Quality gate (AC-3):** per shipped branch, count executed tests (`npm test` spec-reporter `ℹ tests N` line) against the branch's baseline (main = 5; round-2 branches inherit task-priority's count if stacked), diff `test/` for weakened/deleted assertions, and confirm each owner's `pr.md`/evidence shows the CLI executed per AC with observed output.
- **Web verification (AC-4):** the web-page issue must show browser evidence or `needs-human-verification` + reason in its `issue.md` — never a silently ticked UI criterion. Independently, this owner runs its own browser check of `taskr serve` from the shipped branch (Chrome MCP available) to ground-truth the page.
- **Delivery shape (AC-5):** exactly one branch + one `pr.md` per shipped issue; no `github.com` pull URL anywhere in the sandbox artifacts (the sandbox origin is a local bare repo — a GitHub URL would be fabricated); transcript shows `/sw:pr` degrading per its documented no-remote path (T4 set the precedent: `pr.md` is the PR artifact in all sandbox rounds).
- **Hygiene (AC-6):** `learnings.md` files contain forward-useful facts, no "what I did" narration; `status:`+`shipped:` only in `issue.md`; the board has no status column.
- **Fan-out (AC-7):** `export-json-csv/tasks.md` marks ≥ 2 tasks `Delegable: yes`; the owner's transcript shows task workers dispatched and reporting findings back; no worker writes `learnings.md` (transcript tool-use scan via `jq` over Write/Edit targets — git authorship is useless here, all agents share the operator identity, T4 purity learning).

Deliverables land in this issue's folder: `evidence/` (state captures, verbatim session excerpts, per-guarantee audit files), `findings.md` (verdict per check + Expected/Observed/Proposed-fix per divergence), `learnings.md` (precise sandbox end state + facts for T6/T7/T8). Findings only — no fixes to specwright, no edits to sandbox artifacts.

## File Structure

All created under `.specwright/milestones/2026-07-02-e2e-validation/issues/issue-pipeline/` in this worktree:

- `spec.md` — this file.
- `tasks.md` — task breakdown.
- `evidence/round2-pre-state.txt` — sandbox git/board/status snapshot before the drive (already-verified inherited state).
- `evidence/round2-probes.txt` — timestamped worktree/branch/board snapshots for the whole round (parallelism evidence).
- `evidence/round2-session.md` — verbatim key turns of the conducting session (spawn prompt included) + relay exchanges.
- `evidence/round2-post-state.txt` — sandbox git/board/status snapshot after round 2 (T6's inherited baseline).
- `evidence/pipeline-audit.md` — per-guarantee audit: JIT (AC-1), learnings flow (AC-2), quality gate (AC-3), web (AC-4), delivery (AC-5), hygiene (AC-6), fan-out (AC-7), with commands and outputs.
- `findings.md` — verdict table + Expected/Observed/Proposed-fix entries (AC-8).
- `learnings.md` — curated facts for T6/T7/T8, including the exact sandbox end state.
- `issue.md` — modified only for `status:` transitions and AC tick-off.

Sandbox files are read, executed, and probed — never edited by this owner. Scratch scripts live in the session scratchpad, not the repo.

## Phase Ordering

1. **Phase 1 — Drive round 2** (Tasks 1–4): pre-state capture → background prober → spawn + supervise the conducting session to its stop → post-state capture + verbatim extraction. Blocking: the audit needs round 2 shipped (or its blocked/divergent outcome recorded).
2. **Phase 2 — Audit rounds 1+2** (Tasks 5–8): the seven guarantee audits over the post-round sandbox, then `findings.md`. Depends on Phase 1's end state; audit sub-checks are independent of each other.
3. **Phase 3 — Deliver** (Tasks 9–11): learnings, gates, AC tick-off, commit, `/sw:pr` (stacked), `/sw:review` to `lgtm`, ship.

## Constraints

- **Sandbox is mutated on purpose and left as round 2 leaves it** — its end state is T6's input; no cleanup, no reverts, no merges except a maintainer-role merge the driven session explicitly requests (recorded verbatim).
- **No hazard leakage:** the spawn prompt describes the resume task neutrally; it must not mention Finding 7, stacking, or the unmerged branch.
- **Stop before the trap:** the conducting session must not dispatch `list-newest-first`; the stop condition is in the spawn prompt, and the prober verifies no trap worktree/branch ever appears.
- **Commits only on `chore/e2e-issue-pipeline`, inside this worktree.** PR base is `chore/e2e-dispatch-parallelism` (stacked; noted in the PR body). Never fabricate a PR URL.
- **Circuit breaker:** one gate/criterion failing three times identically → stop, report, `status: blocked`.
- **Round-2 owners' language may be pt-BR** (driver's global instructions propagate — resume learning); graders must not read that as divergence.
- **Budget:** round 2 runs three full owner pipelines; the prober cadence (≤ 60 s) and JSONL polling replace any wait-on-notification. Nudges only after observable stall (no new commits/board/JSONL bytes across ≥ 3 probe intervals).

## User Stories / Scenarios

1. **Resume + parallel wave:** a fresh conducting session finds the grow-taskr milestone from files, computes the ready set for round 2, dispatches `list-filters`, `export-json-csv`, `web-page` in parallel (one worktree + branch each), tracks them to shipped/blocked, logs the board, and stops before dispatching `list-newest-first`.
2. **Readiness under an unmerged dependency:** the session confronts `task-priority` shipped-on-branch/pending-on-main and takes one of the three legitimate paths (nothing-ready divergence, stacked branches, maintainer merge request); the harness records the path verbatim without steering.
3. **Owner pipeline per issue:** each round-2 owner writes spec/tasks JIT, passes self-review gates, implements TDD-style, keeps the suite green, runtime-verifies each AC by observed behavior (browser or `needs-human-verification` for the web page), delivers branch + `pr.md`, reviews to `lgtm`, curates learnings, flips its own `issue.md`.
4. **Fan-out:** the export owner delegates ≥ 2 `Delegable: yes` tasks to task workers who report findings back and write no learnings.
5. **Audit:** T5 proves or falsifies each guarantee from git history, artifacts, transcripts, and its own browser check, and files findings.

## Acceptance Criteria

The acceptance criteria live in the sibling `issue.md` — the `AC-N` IDs defined there are the contract `tasks.md` references and `/sw:review` walks. Do not duplicate them here; if writing this spec exposed a missing or wrong criterion, fix `issue.md`.

## Risks and Mitigations

| Risk | Mitigation |
|---|---|
| Conducting session sees no ready issues (reads `main` only) and ends round 2 without dispatching | That outcome IS evidence (Finding 7 confirmed at conductor level). Record it, then — as maintainer, via relay — ask the session to proceed however it judges correct; if it requests the merge, grant it verbatim-recorded. Three identical dead-ends → blocked report. |
| Session stalls waiting on owner completions (T4 Finding 4) | Prober + JSONL polling detect stalls; neutral `maintainer` relay sends a plain status ping (T4: a state-poll prompt suffices, no coaching). |
| Session asks for approval mid-run despite standing approval | Approval cannot travel over SendMessage; if the ask is a *decision* (e.g. merge), the relay answers as maintainer; if it is a *consent* re-ask, re-spawn a fresh session with the consent folded into the spawn prompt (T4 session-1 precedent). |
| Session dispatches the trap despite the stop condition | Prober catches a `list-newest-first` worktree/branch immediately; relay orders the stop; the overrun is a finding against the pacing contract. |
| Round-2 owners hit the AC-reword pattern (T4 Finding 3) on their own tickets | Expected behavior class, not a harness problem: audit records any ticket edits per branch (`git log -p -- <issue>/issue.md`). |
| Browser check of `taskr serve` unavailable in this session | Fall back to `curl` semantics + record that the owner-of-web-page's own evidence is the binding AC-4 check; my browser pass is corroboration only. |
| Test-count baseline ambiguity across stacked branches | Count per branch against its own merge-base with the dependency branch, not against main's 5. |

## Open Questions

None.
