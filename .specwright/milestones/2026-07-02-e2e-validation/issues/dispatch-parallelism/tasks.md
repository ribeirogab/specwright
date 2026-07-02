---
feature: dispatch-parallelism
created: 2026-07-02
---
# Dispatch and Parallelism (T4) — Tasks

**For this issue:** see the sibling `issue.md` (acceptance criteria) and `spec.md` (technical plan).

> Each task names the `AC:` (acceptance criteria from `issue.md` it satisfies — every `AC-N` must be referenced by at least one task) and `Delegable:` (whether it suits an isolated task worker, and the one-line context that worker would receive). Workers report findings back to the issue owner; only the owner writes `learnings.md`.

Shorthand used below: `SANDBOX=/Users/gabriel/www/ribeirogab/specwright-sandbox/taskr`, `ISSUE=<this worktree>/.specwright/milestones/2026-07-02-e2e-validation/issues/dispatch-parallelism`, `SCRATCH=<session scratchpad>`.

## Phase 1: Baseline and degradation clone

### Task 1: Pre-round capture + disposable clone

**AC:** AC-3, AC-4 (baselines both audits diff against)
**Delegable:** no — the baseline must be taken by the session that later interprets the diffs.

- [x] Step 1: Capture pre-round sandbox state into `ISSUE/evidence/round1-sandbox-state.txt` (section `== PRE-ROUND ==`, timestamped):

```bash
cd $SANDBOX && git status --porcelain --branch && git log --oneline -3 && git worktree list && git branch -a && shasum -a 256 .specwright/milestones/2026-07-02-grow-taskr/board.md .specwright/milestones/2026-07-02-grow-taskr/issues/*/issue.md && grep -H '^status:' .specwright/milestones/2026-07-02-grow-taskr/issues/*/issue.md
ls $SANDBOX/.specwright/worktrees 2>/dev/null || echo 'no .specwright/worktrees'
```

Expected: clean tree on `main` at `aaa117b` (ahead 1 of origin — baseline), no worktrees beyond the main tree, all five issues `status: pending`, empty Dispatch Log.

- [x] Step 2: Byte-copy `board.md` and the five `issue.md` to `SCRATCH/pre/`.
- [x] Step 3: Create the degradation clone **before the real round**: `git clone $SANDBOX $SCRATCH/taskr-degradation`.
- [x] Step 4: Verify the clone carries the fixture and the skills: `git -C $SCRATCH/taskr-degradation log --oneline -2` shows `aaa117b`; `ls $SCRATCH/taskr-degradation/.agents/skills/` lists `sw-run`; the milestone folder exists with all five tickets. Expected: all present (vault dirs survive clones via `.gitkeep` — sandbox-setup learning).
- [x] Step 5: Isolate the clone from the live sandbox: `git -C $SCRATCH/taskr-degradation remote remove origin`, then verify `git -C $SCRATCH/taskr-degradation remote -v` prints nothing. Rationale: the clone's default `origin` is the live sandbox and the sandbox's sw-pr skill pushes to origin — a degradation-round push would silently contaminate the real sandbox after the audit. Record the removal in `ISSUE/evidence/degradation-state.txt`, noting that `ahead 1` no longer displays because `main` lost its upstream (expected, not pollution).
- [x] Step 6: Commit the evidence baseline on `chore/e2e-dispatch-parallelism` (spec, tasks, pre-round state).

## Phase 2: The real round

### Task 2: Drive `/sw:run` through round 1

**AC:** AC-1, AC-2, AC-3
**Delegable:** no — the owner is the scripted user; a worker cannot hold the SendMessage channel.

- [x] Step 1: Spawn the session-under-test — Agent tool, `subagent_type: general-purpose`, `name: maintainer` (neutral — T1/T3 leak learning), `run_in_background: true`, with this framing prompt (verbatim):

```
You are an AI coding assistant session working in the repository /Users/gabriel/www/ribeirogab/specwright-sandbox/taskr. Treat that directory as your working repository for everything.

Session rules:
- This is an interactive chat with your user. When you need the user (a question, a completed deliverable, or an approval), end your turn and wait for their reply.
- Read the repository's AGENTS.md first and follow it.
- Slash commands map to skills: a command like /sw:run corresponds to the skill file .agents/skills/sw-run/SKILL.md in the repository — read that file and follow it exactly. The same applies to any other /sw:<name> command or $sw-<name> skill reference you encounter: .agents/skills/sw-<name>/SKILL.md.
- Any action beyond reading files and running read-only commands requires user approval first: describe what you intend to do and end your turn. Once the user approves an action or a batch of actions, you do not need to re-ask for the same batch.

The user's first message follows.

/sw:run
```

- [x] Step 2: Record the spawn (agentId, timestamp) and the framing prompt verbatim in `ISSUE/evidence/round1-session.md`.
- [x] Step 3: When the session yields with its discovery + batched round-1 approval ask (T3 learning: one ask covering worktree + dispatch + log), capture the ask verbatim, then approve via SendMessage with user-plausible wording, e.g. `Approved — go ahead with all of that.` Non-leak rule: never name slugs, ready sets, or outcomes before the session does.
- [x] Step 4: While the round runs, probe from outside every ~60–90s, appending timestamped snapshots to `evidence/round1-sandbox-state.txt` (section `== MID-ROUND ==`):

```bash
cd $SANDBOX && date -u +%FT%TZ && git worktree list && git branch -a && sed -n '/## Dispatch Log/,/## Blockers/p' .specwright/milestones/2026-07-02-grow-taskr/board.md && ls .specwright/worktrees 2>/dev/null
```

Expected while owner lives: `.specwright/worktrees/task-priority` in `git worktree list` on its own branch — that snapshot is AC-1's worktree evidence.

- [x] Step 5: At each subsequent yield, reply per policy: intermediate approval asks → approve (`Approved.`); owner outcome reported + logged and session asks to continue → `Stop here for today — don't start anything new.` and end; session reports blocked/nothing-ready and stops on its own → acknowledge (`Understood, stop here.`). Capture every turn (both directions) verbatim — in particular, the session's **round-outcome announcement** (the turn reporting the owner's shipped/blocked result and the board logging) must appear as a verbatim quote in `round1-session.md`; it is AC-3's transcript-side anchor.
- [x] Step 6: After the session ends, extract the full assistant-turn transcript from the sub-agent JSONL with the T3 recipe and fold it into `evidence/round1-session.md`:

```bash
jq -r 'select(.type=="assistant") | .message.content[]? | select(.type=="text") | .text' <agent-jsonl-path>
```

- [x] Step 7: Commit the evidence.

## Phase 3: Audits

### Task 3: Purity audit, board diff, post-round capture

**AC:** AC-1, AC-2, AC-3
**Delegable:** no — interpretation depends on the round just driven.

- [x] Step 1: Post-round capture (section `== POST-ROUND ==` of `round1-sandbox-state.txt`): same command block as Task 1 Step 1, plus `git -C $SANDBOX log --oneline --all -15` and, for each new branch, `git log --format='%h %an %s' main..<branch>` and `git diff --stat main...<branch>`.
- [x] Step 2: Board append-only check: `diff SCRATCH/pre/board.md $SANDBOX/.specwright/milestones/2026-07-02-grow-taskr/board.md` — every hunk must be an addition (one `dispatched` line + one outcome line in the Dispatch Log; a Blockers entry if the owner blocked); zero deletions/rewrites of pre-round lines. Record the raw diff in the evidence.
- [x] Step 3: Transcript tool-use scan for orchestrator purity, into `ISSUE/evidence/purity-audit.md`:

```bash
jq -r 'select(.type=="assistant") | .message.content[]? | select(.type=="tool_use") | [.name, (.input.file_path // .input.command // .input.prompt // "" | tostring | .[0:200])] | @tsv' <agent-jsonl-path>
```

Verdict rule: every Write/Edit/mutating-Bash by the **orchestrator** targets `$SANDBOX/.specwright/milestones/2026-07-02-grow-taskr/` (or worktree-creation git commands); owner work appears only inside Agent-dispatch entries. Any orchestrator edit to code/tests/docs → AC-2 failure, recorded.
- [x] Step 4: Git-side purity: `git -C $SANDBOX status --porcelain` (main tree must show only the milestone-folder changes, no code edits); commits on `main` since `aaa117b` must be zero or milestone-folder-only; every code commit lives on the owner's branch.
- [x] Step 5: Commit the audit evidence.

## Phase 4: Degradation sub-test

### Task 4: No-sub-agent round in the disposable clone

**AC:** AC-4
**Delegable:** no — same scripted-user channel requirement.

- [x] Step 1: Capture the clone's pre state into `ISSUE/evidence/degradation-state.txt` (git status/log/worktree list, `ls .specwright/worktrees`, board Dispatch Log section).
- [x] Step 2: Spawn the second session — `subagent_type: general-purpose`, `name: maintainer-b`, `run_in_background: true`, framing prompt identical to Task 2 Step 1 **except** the working repository is `$SCRATCH/taskr-degradation` and one rule is appended before the first message:

```
- Environment note: sub-agent support is unavailable in this session — you cannot spawn agents, dispatch sub-agents, or delegate work to parallel workers. Plan accordingly.
```

- [x] Step 3: Drive with the same reply policy (approve the batch; stop after round-1 outcomes are logged). Capture all turns verbatim into `ISSUE/evidence/degradation-session.md`.
- [x] Step 4: Post-round capture into `degradation-state.txt`: `git -C $SCRATCH/taskr-degradation worktree list` (must show only the main tree), `ls .specwright/worktrees` (must be absent/empty of new entries), board diff, branch list, `git status --porcelain`. Verdict inputs for AC-4: serial in-session execution, no worktrees, pipeline steps (spec/tasks/gates) named in the transcript.
- [x] Step 5: Extract the JSONL transcript (same `jq` recipe), fold into the evidence, then discard the clone: `rm -rf $SCRATCH/taskr-degradation` (scratchpad copy only — never the sandbox).
- [x] Step 6: Commit the evidence.

## Phase 5: Findings

### Task 5: Write `findings.md`

**AC:** AC-5 (and closes AC-1..AC-4 verdicts)
**Delegable:** no — verdicts are the owner's.

- [x] Step 1: Write `ISSUE/findings.md`: one verdict (PASS / FAIL / DIVERGENCE / UNVERIFIABLE) per check in AC-1..AC-4, each citing its evidence file+section; one Expected / Observed / Proposed-fix entry per failure or divergence — including the known AC-1 expectation-vs-fixture divergence (single-dispatch round 1; concurrency observation re-scoped to round 2) and whatever the task-priority owner did with the validator defect. Also spell out the **T-label drift**: scope-detection's and milestone-planning's learnings refer to this issue as "T5" while this issue's ticket and resume's learnings call it "T4" — name both labels so the next issue's owner maps the sibling references correctly.
- [x] Step 2: Cross-check every finding cites evidence that actually contains the quoted material.
- [x] Step 3: Commit.

## Phase 6: Delivery

### Task 6: Quality gate + runtime verification mapping

**AC:** AC-1..AC-5 (verification bookkeeping)
**Delegable:** no.

- [x] Step 1: Quality gate — this issue writes vault markdown only in the specwright repo; the touched area's only executable gate is the spec validator: run `<worktree>/skills/sw/scripts/validate-spec.sh ISSUE` → expected exit 0. Also run the sandbox's `npm test` in `$SANDBOX` post-round and record the result — round 1's owner must not have broken the suite on `main` (owner changes live on its branch; `main` must still pass 5/5).
- [x] Step 2: Runtime verification = the test executions themselves; map each AC to its evidence in the PR body. Tick verified ACs in `issue.md`; leave AC-1 unticked if the concurrency clause stayed unverifiable at N=1, with the finding referenced (never silently tick).
- [x] Step 3: Commit.

### Task 7: Learnings, PR, review, ship

**AC:** AC-1..AC-5 (delivery)
**Delegable:** no.

- [x] Step 1: Write `ISSUE/learnings.md` — facts T5+ inherit: exact sandbox end state (branches, worktree paths, board lines, issue statuses, whether the owner pushed), which issue shipped/blocked and how the validator defect resolved, where the trap stands, harness facts (batched approval behavior at round scale, nested-dispatch availability).
- [x] Step 2: `/sw:pr` — base `chore/e2e-resume`, stacking noted in the body, runtime-verification table included.
- [x] Step 3: `/sw:review` to `lgtm`; apply fixes on this branch until clean.
- [x] Step 4: Set `issue.md` `status: shipped` + `shipped: 2026-07-02`, tick verified ACs, commit, push.
- [x] Step 5: Report to the orchestrator: PR URL + one line per learning.
