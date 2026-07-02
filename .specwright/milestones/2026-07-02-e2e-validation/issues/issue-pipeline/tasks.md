---
feature: issue-pipeline
created: 2026-07-02
---
# Issue Pipeline (T5) — Tasks

**For this issue:** see the sibling `issue.md` (acceptance criteria) and `spec.md` (technical plan).

> Each task names the `AC:` (acceptance criteria from `issue.md` it satisfies — every `AC-N` must be referenced by at least one task) and `Delegable:` (whether it suits an isolated task worker, and the one-line context that worker would receive). Workers report findings back to the issue owner; only the owner writes `learnings.md`.

## Phase 1: Drive round 2

### Task 1: Pre-round state capture

**AC:** AC-1, AC-3 (baseline inputs)
**Delegable:** no — the owner must personally verify the inherited state before mutating it.

- [x] Step 1: Capture the sandbox pre-round snapshot into `evidence/round2-pre-state.txt`:

```bash
cd /Users/gabriel/www/ribeirogab/specwright-sandbox/taskr
{ echo "== PRE-ROUND2 $(date -u +%Y-%m-%dT%H:%M:%SZ) =="
  git log --oneline -3 --all; git branch -a; git worktree list; git status --short
  grep -H "^status:" .specwright/milestones/2026-07-02-grow-taskr/issues/*/issue.md
  sed -n '/## Dispatch Log/,/## Blockers/p' .specwright/milestones/2026-07-02-grow-taskr/board.md
  echo "== main test baseline =="; TASKR_FILE=$(mktemp) npm test 2>&1 | tail -5; } > /Users/gabriel/www/ribeirogab/specwright/.claude/worktrees/pensive-bose-7ba1c1/.specwright/worktrees/issue-pipeline/.specwright/milestones/2026-07-02-e2e-validation/issues/issue-pipeline/evidence/round2-pre-state.txt
```

- [x] Step 2: Verify it matches T4's recorded end state (main `7c7f1bc`, `feat/task-priority` `b9d7c80` unmerged, task-priority worktree present, 5 tickets `pending` on main, `ℹ pass 5`). Any mismatch → stop and reconcile against `../dispatch-parallelism/evidence/` before driving.
- [x] Step 3: Commit (`chore(vault): capture the pre-round-2 sandbox state`).

### Task 2: Background state prober

**AC:** AC-1 (dispatch timing), AC-5 (one branch per issue), plus the round-2 parallelism observation (spec: overlapping worktree snapshots)
**Delegable:** no — must run in the owner session to survive the whole round.

- [x] Step 1: Start a background loop appending to `evidence/round2-probes.txt` every 45 s: UTC timestamp, `git worktree list`, `git branch -a | cat`, `ls .specwright/worktrees/`, board `## Dispatch Log` section, and per-issue `status:` lines.
- [x] Step 2: Verify the first probe line appears within one interval.
- [x] Step 3: Leave it running until Task 4 ends the round; then stop it.

### Task 3: Spawn and supervise the conducting session

**AC:** AC-1, AC-5, AC-7 (produces the round-2 transcripts/artifacts all audits consume)
**Delegable:** no — stateful session driving.

- [x] Step 1: Spawn a general-purpose sub-agent named `operator2` (neutral, no issue slug) whose spawn prompt contains, verbatim requirements: work in `/Users/gabriel/www/ribeirogab/specwright-sandbox/taskr`; resume the grow-taskr milestone with `/sw:run`; unattended mode with standing approval for worktrees, branches, commits, pushes to the local origin, and PR records for grow-taskr issues; **after the round now dispatched is fully logged on the board, STOP and report — do not dispatch any further round**; end its final message with the board's Dispatch Log quoted verbatim. No mention of merged/unmerged state, stacking, or any specific issue.
- [x] Step 2: Record the exact spawn prompt at the top of `evidence/round2-session.md`.
- [x] Step 3: Poll (never wait): every few minutes check `evidence/round2-probes.txt` growth, sandbox commits, and the sub-agent JSONL under the harness project dir (newest `*.jsonl` by mtime). Stall = no new bytes/commits across 3+ probe intervals → spawn a neutral relay agent `maintainer` to send a plain status ping (no coaching).
- [x] Step 4: If `operator2` surfaces a maintainer decision (e.g. asks to merge `feat/task-priority`): answer via `maintainer` as the repo owner — merging is permitted; record the exchange verbatim in `evidence/round2-session.md`. If it declares nothing ready and ends: record verbatim, then have `maintainer` ask it to proceed as it judges correct (still no hazard coaching).
- [x] Step 5: If the prober shows a `list-newest-first` worktree or branch: immediately have `maintainer` order the stop; record as a pacing finding.
- [x] Step 6: Round ends when `operator2` reports (or is stopped): confirm by state, not notification — board log lines present, three round-2 issues at a terminal status (`shipped`/`blocked`) in the checkout the session used.

### Task 4: Post-round capture and verbatim extraction

**AC:** AC-1, AC-8 (evidence base), sandbox end state for learnings
**Delegable:** no.

- [x] Step 1: Stop the prober. Capture `evidence/round2-post-state.txt` (same probe recipe as Task 1 plus `git log --oneline -15 --all` and, per round-2 branch, `git log --format='%H %cI %s' <branch> --not <its-base>`).
- [x] Step 2: Extract key turns from `operator2`'s JSONL (and owner JSONLs if locatable) with `jq 'select(.type=="assistant") | .message.content[] | select(.type=="text") | .text'`; paste the load-bearing turns (ready-set computation, branching decision, dispatch announcements, stop report, final Dispatch Log) into `evidence/round2-session.md`, verbatim.
- [x] Step 3: Commit (`chore(vault): record the round-2 drive evidence`).

## Phase 2: Audit rounds 1 and 2

### Task 5: JIT + learnings-flow audit (AC-1, AC-2)

**AC:** AC-1, AC-2
**Delegable:** yes — "given the sandbox repo path and the list of shipped branches, produce per-issue `git log --follow` proof for spec.md/tasks.md creation time and grep evidence for the epoch-seconds fact in task-priority's learnings.md and export-json-csv's spec.md; report findings back, write nothing."

- [x] Step 1: Per shipped issue (task-priority + round-2 set), on its branch: `git log --follow --format='%H %cI %s' -- .specwright/milestones/2026-07-02-grow-taskr/issues/<slug>/spec.md` (and `tasks.md`); confirm first commit is inside the issue's round, after its dispatch (board log + probe timestamps), and absent from the pre-dispatch base commit (`git show <base>:<path>` fails).
- [x] Step 2: Per issue, grep the owner transcript/`pr.md`/evidence for the three self-review gates (`validate-spec.sh` exit, spec-document-reviewer verdict, review-spec pass) actually executed.
- [x] Step 3: AC-2: `git grep -n "epoch" <task-priority-branch> -- '*learnings.md'` and the equivalent over `export-json-csv`'s `spec.md` on its branch; quote both hits (or their absence) with exact lines.
- [x] Step 4 (owner-only integration — not part of the delegable scope): Write the `AC-1`/`AC-2` sections of `evidence/pipeline-audit.md` with commands + outputs. Commit.

### Task 6: Quality-gate + delivery + hygiene audit (AC-3, AC-5, AC-6)

**AC:** AC-3, AC-5, AC-6
**Delegable:** yes — "given the sandbox repo path and shipped branches: per branch run `npm test` (temp `TASKR_FILE`), record `# tests` totals vs the branch's merge-base baseline, diff `test/` for deleted/weakened assertions; verify one branch + one pr.md per issue and no github.com pull URLs; check learnings.md for narration and status fields outside issue.md; report findings back, write nothing."

- [x] Step 1: Per shipped branch: `git diff <merge-base> <branch> -- test/` reviewed for assertion deletions/weakenings; `npm test` (fresh temp `TASKR_FILE`) recording `# tests` / `# pass` / `# fail`; compare counts against the branch's own base.
- [x] Step 2: Per issue: confirm exactly one branch (probe file + `git branch -a`) and one `pr.md`; `git grep -nE "github.com/.*/pull" <branch> -- <issue-folder>` must return nothing; confirm `pr.md`/evidence records CLI executions with observed output per AC-N. Record explicitly which degradation shape each issue exhibited — organic `/sw:pr` stop + printed manual steps vs orchestrator-pre-instructed branch+`pr.md` (T4 precedent) — so the AC-5 tick is honest against the literal criterion.
- [x] Step 3: Hygiene: per issue `learnings.md`, flag narration ("I did/ran/then..."-style entries); `grep -rn "^status:" ` over the milestone folder must hit only `issue.md` files; board diff shows no status column added.
- [x] Step 4 (owner-only integration — not part of the delegable scope): Write the `AC-3`/`AC-5`/`AC-6` sections of `evidence/pipeline-audit.md`. Commit.

### Task 7: Web verification + fan-out audit (AC-4, AC-7)

**AC:** AC-4, AC-7
**Delegable:** no — the browser corroboration must run in this session (Chrome MCP capability lives here).

- [x] Step 1: Read `web-page/issue.md` on its branch: every UI criterion must be ticked-with-browser-evidence or carry `needs-human-verification` + reason; cross-check the owner's evidence/`pr.md` for the browser claim. Neither → AC-4 failure entry.
- [x] Step 2: Corroborate: from the web-page branch's worktree, run `taskr serve` against a temp `TASKR_FILE` with seeded tasks (including the `<script>alert(1)</script>` task), load `http://localhost:<port>/` in the browser, capture text/screenshot evidence of the table + escaping, then stop the server. Record in `evidence/pipeline-audit.md` (AC-4 section); on browser failure, fall back to `curl` and record the capability note per spec.
- [x] Step 3: AC-7: `grep -c "Delegable: yes" export-json-csv/tasks.md` (must be ≥ 2 among its tasks); locate the export owner's transcript JSONL and extract worker dispatch + findings-report turns; scan worker tool-use (`jq` over Write/Edit `file_path`s) proving no worker wrote any `learnings.md`.
- [x] Step 4: Write the `AC-4`/`AC-7` sections. Commit (`chore(vault): record the rounds-1-2 pipeline audit`).

### Task 8: findings.md (AC-8)

**AC:** AC-8
**Delegable:** no — verdicts are the owner's.

- [x] Step 1: Write `findings.md`: verdict table (one row per AC-1..AC-7 check, PASS/FAIL/DIVERGENCE + evidence pointer) and one `Expected / Observed / Proposed fix` entry per failure or divergence, including the observed Finding-7 resolution path. If round 2 ends blocked rather than shipped for any issue, express the affected AC-4/AC-7 verdicts as UNOBSERVABLE-with-reason (the blocked outcome is itself the evidence), never as silent PASS.
- [x] Step 2: Re-read `issue.md` Purpose bullets and confirm every audit bullet has a verdict; close gaps.
- [x] Step 3: Commit (`chore(vault): record the issue-pipeline (T5) findings`).

## Phase 3: Deliver

### Task 9: Learnings, gates, AC tick-off

**AC:** AC-1..AC-8 (closure)
**Delegable:** no.

- [x] Step 1: Write `learnings.md`: precise sandbox end state (commits, branches, worktrees, statuses per checkout, trap untouched-or-not) + forward-useful facts for T6/T7/T8. Facts only, no narration.
- [x] Step 2: Quality gate: `bash skills/sw/scripts/validate-spec.sh <issue-folder>` (repo checkout of the validator) → exit 0; this repo has no other test/lint/build for vault files — state that in the PR body.
- [x] Step 3: Runtime verification: walk AC-1..AC-8 against the produced evidence files; tick each verified `[x]` in `issue.md`.
- [x] Step 4: Commit (`chore(vault): curate T5 learnings and tick verified ACs`).

### Task 10: PR

**AC:** AC-8 (delivery)
**Delegable:** no.

- [x] Step 1: `/sw:pr` — push `chore/e2e-issue-pipeline`, open the PR with base `chore/e2e-dispatch-parallelism`, note the stacking in the body, include the runtime-verification record. Never fabricate a URL; if the remote/PR step fails, record the documented degradation instead.

### Task 11: Review to lgtm and ship

**AC:** AC-1..AC-8 (contract walk)
**Delegable:** no.

- [x] Step 1: `/sw:review` over the branch diff; fix findings in this issue's own artifacts only; iterate to `lgtm` (three identical failures of one criterion → circuit breaker).
- [x] Step 2: Set `issue.md` `status: shipped` + `shipped: 2026-07-02` (or actual date). Commit + push.
- [x] Step 3: Report back: one line per learning + the PR URL.
