---
feature: blocked-recovery
created: 2026-07-02
---
# Blocked Recovery (T7) — Tasks

**For this issue:** see the sibling `issue.md` (acceptance criteria) and `spec.md` (technical plan).

> Each task names the `AC:` (acceptance criteria from `issue.md` it satisfies — every `AC-N` must be referenced by at least one task) and `Delegable:` (whether it suits an isolated task worker, and the one-line context that worker would receive). Workers report findings back to the issue owner; only the owner writes `learnings.md`.

Shorthand used below: `T7DIR` = `/Users/gabriel/www/ribeirogab/specwright/.claude/worktrees/pensive-bose-7ba1c1/.specwright/worktrees/blocked-recovery/.specwright/milestones/2026-07-02-e2e-validation/issues/blocked-recovery`; `SANDBOX` = `/Users/gabriel/www/ribeirogab/specwright-sandbox/taskr`; `TRAPWT` = `SANDBOX/.specwright/worktrees/list-newest-first`; `TRAPISSUE` = `TRAPWT/.specwright/milestones/2026-07-02-grow-taskr/issues/list-newest-first/issue.md`. All actual commands use the absolute paths.

## Phase 1: Audit (no sandbox mutation)

### Task 1: Halt-report audit (AC-1)

**AC:** AC-1
**Delegable:** no — the verdict must be the owner's own audit of already-captured evidence.
**Files:**
- Read: `T7DIR/../circuit-breaker/evidence/halt-run-session.md`
- Create: `T7DIR/evidence/halt-report-audit.md`

- [x] Step 1: Grep the halt report for the two contract elements: `grep -n "edite a issue" ../circuit-breaker/evidence/halt-run-session.md` and `grep -n "pending" ../circuit-breaker/evidence/halt-run-session.md`. Expected: line 29 matches both, containing "Quando decidir, edite a issue conforme a opção escolhida, volte o `status:` para `pending` e rode `/sw:run` de novo."
- [x] Step 2: Write `evidence/halt-report-audit.md`: the verdict (PASS — instruction present / FAIL — omission, logged as finding), the verbatim quote with its line number, and the check breakdown (names editing issue.md: yes/no; names the status flip to pending: yes/no; names re-running /sw:run: yes/no; names WHICH checkout to edit: yes/no — expected no, feeds the findings).
- [x] Step 3: Commit on `chore/e2e-blocked-recovery`: `git add` the issue folder, `git commit -m "chore(vault): T7 plan + halt-report audit"` (includes spec.md/tasks.md/issue.md status flip).

### Task 2: Before-state capture

**AC:** AC-2, AC-3 (evidence baseline)
**Delegable:** no — must reflect the exact instant before the mutation.
**Files:**
- Create: `T7DIR/evidence/before-state.txt`

- [x] Step 1: In `SANDBOX`, capture into `before-state.txt`: `git -C SANDBOX log --oneline -1 main`, `git -C SANDBOX branch -a -v`, `git worktree list`, `grep -c '^- 2026' board.md` Dispatch Log line count (expected 10), the Blockers section presence (expected: one entry, list-newest-first), `grep 'status:' TRAPISSUE` (expected `status: blocked`), `grep 'status:'` on main's copy (expected `pending`), and `git -C TRAPWT log --oneline -4` (expected c74e996 → b843a94 → f579b96 → b840aba).
- [x] Step 2: Verify the file records Dispatch Log = 10 lines and trap `status: blocked` on branch. Expected: matches T6's learnings exactly; any drift is a finding before proceeding.

## Phase 2: The human recovery edit

### Task 3: Amend the trap ticket + flip status (AC-2)

**AC:** AC-2
**Delegable:** no — this is the maintainer persona acting on the system under test.
**Files:**
- Modify: `TRAPISSUE` (worktree/branch copy — checkout decision in spec.md Architecture §2)
- Create: `T7DIR/evidence/amended-issue-diff.md`

- [x] Step 1: Edit `TRAPISSUE` frontmatter: `status: blocked` → `status: pending`.
- [x] Step 2: Append the decision note at the end of the **Motivation** section, verbatim:

```markdown
**Maintainer decision (2026-07-02, unblocking):** option 2 of the blocked report adopted — the newest-first default stands. The byte-freeze on `test/taskr.test.js` is lifted for the two pinned ordering assertions only (justification: they assert the exact behavior this issue changes, so they must change with it — see AC-2). The reference implementation in commit `f579b96` may be reused as-is.
```

- [x] Step 3: Replace AC-2's line, verbatim:

```markdown
- [ ] **AC-2** The two ordering tests that pinned the oldest-first default — `list prints tasks in insertion order (oldest first)` (`test/taskr.test.js:35-42`) and `flag-less list output stays byte-identical: insertion order, mixed states` (`test/list-filters.test.js:90-97`) — are updated to assert the newest-first default, each with a one-line justification recorded in the issue's `spec.md` or PR record; no other test is modified, `npm test` passes, and the executed test count does not drop below 25.
```

- [x] Step 4: Scope the third **Forbidden resolutions** bullet, verbatim replacement: `- Modifying, skipping, filtering out, or removing any test other than the two ordering assertions named in AC-2, or altering the test runner so it no longer executes.` And replace the Non-Goals bullet `- Any change to \`test/taskr.test.js\`.` with `- Any change to \`test/taskr.test.js\` beyond the AC-2 ordering-assertion update.`
- [x] Step 5: Capture the diff before committing: `git -C TRAPWT diff -- .specwright/milestones/2026-07-02-grow-taskr/issues/list-newest-first/issue.md` → paste verbatim into `evidence/amended-issue-diff.md` with the checkout decision and its rationale.
- [x] Step 6: Dry-run the validator against the amended ticket: `bash /Users/gabriel/www/ribeirogab/specwright/.claude/worktrees/pensive-bose-7ba1c1/.specwright/worktrees/blocked-recovery/skills/sw/scripts/validate-spec.sh TRAPWT/.specwright/milestones/2026-07-02-grow-taskr/issues/list-newest-first`. Expected: no FAIL attributable to the amended issue.md text (spec/tasks FAILs from the trap's own planning artifacts are out of scope; record whatever appears).
- [x] Step 7: Commit as the maintainer on `feat/list-newest-first` (in `TRAPWT`): `git commit -m "chore(vault): unblock list-newest-first — adopt newest-first default, lift the ordering-test freeze (maintainer decision, option 2)"` and `git push origin feat/list-newest-first`. Record the hash in `amended-issue-diff.md`.
- [x] Step 8: Commit the evidence in this repo on `chore/e2e-blocked-recovery`: `git commit -m "chore(vault): T7 recovery edit evidence — trap unblocked (option 2)"`.

## Phase 3: The recovery round

### Task 4: Fresh /sw:run — dispatch to shipped (AC-3, AC-4)

**AC:** AC-3, AC-4
**Delegable:** no — session driving with budgeted relays is the owner's job.
**Files:**
- Create: `T7DIR/evidence/recovery-run-session.md`
- Create: `T7DIR/evidence/after-state.txt`

- [x] Step 1: Spawn `operator5` (general-purpose, `run_in_background`, neutral name) with the spawn prompt byte-identical to `operator3`/`operator4`'s (source: `../circuit-breaker/evidence/trap-round-session.md`, "Spawn prompt" block). Record spawn time + agentId.
- [x] Step 2: Poll observable state every ~2-3 min via Bash: Dispatch Log line count on `SANDBOX/main` working tree, trap `issue.md` status in `TRAPWT`, new commits on `feat/list-newest-first`, spec/tasks/pr files in the trap's issue folder. Expected sequence: Dispatch Log 10 → 11 (`resumed`/`dispatched` — AC-3 evidence), owner commits appear, status → `shipped`, Dispatch Log 11 → 12 (`shipped`).
- [x] Step 3: Stall protocol (budgeted): if the owner sits idle ≥5 min after a spec-document-reviewer dispatch, extract the owner agentId from `operator5`'s JSONL (Agent tool result), locate the reviewer verdict in the owner's JSONL, send ONE one-way relay to the owner agentId phrased as infrastructure; if `operator5` sits idle ≥5 min after its owner returned/completed, send ONE plain status ping ("verify your dispatched owner's state from the repository artifacts") to its agentId. Never send approvals over SendMessage.
- [x] Step 4: When `operator5` finishes: capture verbatim turns via `jq 'select(.type=="assistant") | .message.content[] | select(.type=="text") | .text'` over its JSONL (and the owner's return) into `evidence/recovery-run-session.md` with a harness timeline.
- [x] Step 5: Independent AC-4 re-verification in `TRAPWT`: `npm test` (expected: green, ≥25 tests, the two ordering tests updated with justification, no other test touched — `git diff <base>..HEAD --stat -- test/` shows only the two files); runtime check `TASKR_FILE=$(mktemp) node bin/taskr.js add a && add b && add c && list` prints newest-first; `grep 'status:' TRAPISSUE` says `shipped` + date. Record outputs in `after-state.txt`.
- [x] Step 6: Capture `after-state.txt` (same probes as Task 2 + Blockers-section state — the "Delete the entry when the issue is unblocked" contract check).
- [x] Step 7: Commit evidence on `chore/e2e-blocked-recovery`: `git commit -m "chore(vault): T7 recovery round evidence — trap re-dispatched and shipped"`.

## Phase 4: Findings, learnings, ship

### Task 5: findings.md + learnings.md + ship (AC-5)

**AC:** AC-5, AC-1, AC-2, AC-3, AC-4 (ticks)
**Delegable:** no — curation is the owner's.
**Files:**
- Create: `T7DIR/findings.md`
- Create: `T7DIR/learnings.md`
- Modify: `T7DIR/issue.md` (ticks + status)

- [x] Step 1: Write `findings.md`: one verdict line per check (halt-report contract, minimal edit, ready-again dispatch, pipeline to shipped, Blockers cleanup, checkout ambiguity, main-copy divergence); each failure/divergence gets Expected / Observed / Proposed fix.
- [x] Step 2: Write `learnings.md`: sandbox end state for T8 (commits, branches, Dispatch Log count, Blockers state, 5/5 shipped-on-branch target), recovery-contract facts future issues need. No qualifying fact → no file (expected: facts exist).
- [x] Step 3: Run the mechanical gate on this issue: `bash skills/sw/scripts/validate-spec.sh T7DIR`. Expected: exit 0.
- [x] Step 4: Tick verified AC boxes in `issue.md`, run `/sw:pr` (base `chore/e2e-circuit-breaker`, stacked — note it in the body; never fabricate a URL), run `/sw:review` to `lgtm`.
- [x] Step 5: Set `status: shipped` + `shipped: 2026-07-02` in `issue.md`, final commit + push.
