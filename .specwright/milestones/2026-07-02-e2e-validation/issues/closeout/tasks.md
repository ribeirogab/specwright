---
feature: closeout
created: 2026-07-02
---
# Closeout (T8) — Tasks

**For this issue:** see the sibling `issue.md` (acceptance criteria) and `spec.md` (technical plan).

> Each task names the `AC:` (acceptance criteria from `issue.md` it satisfies — every `AC-N` must be referenced by at least one task) and `Delegable:` (whether it suits an isolated task worker, and the one-line context that worker would receive). Workers report findings back to the issue owner; only the owner writes `learnings.md`.

## Phase 1: Pre-closeout snapshot

### Task 1: Capture the sandbox pre-state

**AC:** AC-1, AC-3
**Delegable:** no — the snapshot is the audit baseline; the owner must vouch for it.
**Files:**
- Create: `.specwright/milestones/2026-07-02-e2e-validation/issues/closeout/evidence/pre-state.txt`

- [x] Step 1: In the sandbox (read-only), capture: `git log --oneline -5`, `git status --short`, `git branch -v`, `git worktree list`, Dispatch Log line count, the Blockers section, `shasum -a 256 AGENTS.md`, `ls -la .specwright/conventions/` + per-file sha256, and a full byte copy of `board.md`.

Run: `cd /Users/gabriel/www/ribeirogab/specwright-sandbox/taskr && git log --oneline -1`
Expected: `5a9b369 chore(vault): log round 4 on the grow-taskr board — list-newest-first resumed, dispatched and shipped; blocker cleared`

- [x] Step 2: Write it all to `evidence/pre-state.txt`; keep a scratch copy of `board.md` at the scratchpad as the diff baseline.
- [x] Step 3: Commit (`chore(vault): T8 pre-closeout sandbox snapshot`).

## Phase 2: Drive the closeout session

### Task 2: Spawn the conductor and run the scripted closeout

**AC:** AC-1, AC-2, AC-3
**Delegable:** no — live conduction with scripted decisions cannot be handed to an isolated worker.
**Files:**
- Create: `.specwright/milestones/2026-07-02-e2e-validation/issues/closeout/evidence/closeout-session.md`
- Create: `.specwright/milestones/2026-07-02-e2e-validation/issues/closeout/evidence/promotion-decisions.md`

- [x] Step 1: Compose the spawn prompt: the T6 conductor prompt (verbatim base in `../circuit-breaker/evidence/trap-round-session.md`) with the three deltas from spec.md §Part A (natural-end pacing; summary-append added to standing approval; decision-messages-are-maintainer-answers line). It must not name promotions, epoch-seconds, goal.md, or any expected output.
- [x] Step 2: Spawn `operator6` (general-purpose, `run_in_background`, cwd-independent absolute paths); record agentId + JSONL path; arm a 20–30 s poll over board bytes, sandbox `git log`, AGENTS.md/conventions mtimes, and the session JSONL.
- [x] Step 3: When the session asks the promotion question, reply via a fresh neutral relay (`maintainer8`) to the agentId with the scripted subset: approve (i) epoch-seconds + ×1000 conversion, (ii) `taskPriority()`/`PRIORITIES` access rule; reject everything else by name. Capture the proposal and the reply verbatim.
- [x] Step 4: When (if) the session raises goal.md reconciliation, approve the minimal wording edit via a fresh relay (`maintainer9`); capture the exchange verbatim. If it never raises it, note the absence. *(Deviation: the session raised both questions in one turn, so both decisions went in the single `maintainer8` relay — no second relay needed.)*
- [x] Step 5: If the session stalls > 5 min without observable progress, send the proven T6 status-ping text via a fresh neutral relay (one budgeted ping). *(Never fired: the run produced observable progress continuously and finished in ~6 min.)*
- [x] Step 6: When the session delivers its final report and stops, extract every assistant turn verbatim (`jq 'select(.type=="assistant") | .message.content[] | select(.type=="text") | .text'`), assemble `evidence/closeout-session.md` (spawn prompt, UTC timeline, turns, replies) and `evidence/promotion-decisions.md` (proposals, decisions, applied diffs via sandbox `git show`, rejected-items absence proof).
- [x] Step 7: Commit (`chore(vault): T8 closeout session driven — transcript and promotion evidence`).

### Task 3: Audit the post-state

**AC:** AC-1, AC-2, AC-3
**Delegable:** no — verdicts are the owner's.
**Files:**
- Create: `.specwright/milestones/2026-07-02-e2e-validation/issues/closeout/evidence/post-state.txt`

- [x] Step 1: Re-capture the Task 1 snapshot post-closeout; `diff` pre/post `board.md`.

Run: `diff <scratch>/board-pre.md /Users/gabriel/www/ribeirogab/specwright-sandbox/taskr/.specwright/milestones/2026-07-02-grow-taskr/board.md`
Expected: only `>` (added) lines — a final-summary section; zero `<` (removed) or `|` (changed) lines in the Issues table, the 13 Dispatch Log lines, and Blockers.

- [x] Step 2: Verify applied diffs == approved subset (AGENTS.md/conventions), rejected items absent, no code/test edits (`git diff 5a9b369..HEAD -- bin lib test package.json README.md` empty except vault), no writes after the final report (last commit time vs report time; `git status` clean or explained).
- [x] Step 3: Verify the final report hands the five PR merges to the human and the session stopped (JSONL tail).
- [x] Step 4: Write `evidence/post-state.txt`; commit (`chore(vault): T8 post-closeout audit evidence`).

## Phase 3: Consolidation

### Task 4: Write dossier.md

**AC:** AC-4
**Delegable:** no — deduplication needs full milestone context this owner already holds.
**Files:**
- Create: `.specwright/milestones/2026-07-02-e2e-validation/issues/closeout/dossier.md`

- [x] Step 1: Collect the ten findings.md (8 local; command-surface + docs-coherence via `git show <branch>:<path>`, already extracted to scratch) + the board Conduction notes (parent checkout) + Part A's fresh findings.
- [x] Step 2: Write the dossier per spec.md §Part B: theme groups, one consolidated entry per recurring pattern with full evidence trail, source issue + Expected/Observed/Proposed fix + severity per entry, the two user-requested skill improvements as first-class items, standalone-regression noted as not-yet-run, closing with the fixes-delivery decomposition recommendation.
- [x] Step 3: Self-check: every F-entry of all ten findings files appears exactly once (map them by source id in a coverage table inside the dossier); commit (`chore(vault): T8 consolidated dossier`).

### Task 5: Write findings.md

**AC:** AC-5
**Delegable:** no.
**Files:**
- Create: `.specwright/milestones/2026-07-02-e2e-validation/issues/closeout/findings.md`

- [x] Step 1: One verdict per check C1–C5 (spec.md §Part A) citing evidence files; one Expected/Observed/Proposed-fix entry per failure or divergence.
- [x] Step 2: Commit (`chore(vault): T8 findings`).

## Phase 4: Delivery

### Task 6: Quality gate + runtime verification

**AC:** AC-1, AC-2, AC-3, AC-4, AC-5
**Delegable:** no.

- [x] Step 1: Quality gate — markdown/vault-only change set in this repo: run `skills/sw/scripts/validate-spec.sh` on this issue folder (expect exit 0); confirm the diff against the stacked base touches only the milestone folder (`git diff chore/e2e-blocked-recovery --stat`); sandbox suite untouched by the driven session (verified in Task 3 Step 2).
- [x] Step 2: Runtime verification — walk AC-1..AC-5 against the observed behavior recorded in evidence/ (the driven session IS the runtime); record the walk for the PR body.
- [x] Step 3: Commit anything pending.

### Task 7: Learnings, PR, review, ship

**AC:** AC-1, AC-2, AC-3, AC-4, AC-5
**Delegable:** no.
**Files:**
- Create: `.specwright/milestones/2026-07-02-e2e-validation/issues/closeout/learnings.md`
- Modify: `.specwright/milestones/2026-07-02-e2e-validation/issues/closeout/issue.md`

- [x] Step 1: Curate `learnings.md` — sandbox final state (post-closeout, for standalone-regression which must find it idle), promotion/goal outcomes, durable harness facts, dossier path + fixes recommendation one-liner.
- [x] Step 2: `/sw:pr` — base `chore/e2e-blocked-recovery`, stacking noted in the body, runtime-verification results included.
- [x] Step 3: `/sw:review` to `lgtm`.
- [x] Step 4: Flip `issue.md` to `status: shipped` + `shipped: 2026-07-02`, tick verified ACs; commit (`chore(vault): ship the closeout (T8) issue`).
