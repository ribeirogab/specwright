---
feature: run-skill-contract
created: 2026-07-02
---
# Run Skill Contract — Tasks

**For this issue:** see the sibling `issue.md` (acceptance criteria) and `spec.md` (technical plan).

> Each task names the `AC:` (acceptance criteria from `issue.md` it satisfies — every `AC-N` must be referenced by at least one task) and `Delegable:` (whether it suits an isolated task worker, and the one-line context that worker would receive). Workers report findings back to the issue owner; only the owner writes `learnings.md`.

## Phase 1: Canonical edit (`.agents/skills/sw-run/SKILL.md`)

### Task 1: The-loop contract additions

**AC:** AC-1, AC-2, AC-3, AC-4, AC-8, AC-9
**Delegable:** no — the four hunks in one section interlock; a worker would need this whole plan anyway.
**Files:**
- Modify: `.agents/skills/sw-run/SKILL.md:20-32` (section `## The loop`)

- [ ] Step 1: Replace loop step 1 (readiness reads the dependency's own branch — AC-3):

Was:
```markdown
1. **Find ready issues** — every issue whose `issue.md` says `status: pending` and whose board dependencies all say `status: shipped`.
```
Becomes:
```markdown
1. **Find ready issues** — every issue whose `issue.md` says `status: pending` and whose board dependencies all say `status: shipped`. Readiness reads each dependency's `issue.md` **from the dependency's own branch** (its worktree or branch checkout): while the dependency's PR is unmerged, the `main` copy still says `pending` — the on-branch copy is the truth.
```

- [ ] Step 2: Replace loop step 2's intro sentence and the branching bullet (round-scoped approval — AC-1; stacking + re-target — AC-3):

Was:
```markdown
2. **Dispatch one issue owner per ready issue** — all of them, in parallel, no concurrency cap. For each:
   - Branch from `main` — or from the dependency's branch when the board says this issue depends on a not-yet-merged one (a stacked PR; the owner notes it in the PR body).
```
Becomes:
```markdown
2. **Dispatch one issue owner per ready issue** — all of them, in parallel, no concurrency cap. Interactive approval asks are scoped to **this round's writes** (its worktrees, branches, commits, pushes, PRs) — never the whole milestone; a later round is a new loop turn and requires a new ask. For each:
   - Branch from `main` — or, when a dependency's PR is not yet merged, stack on the dependency's branch: the owner branches from it, notes the stacked base in the PR body, and re-targets the PR onto `main` after the dependency merges.
```

- [ ] Step 3: In the owner's-prompt bullet, replace the `blocked` return with the paste-ready block (AC-4, owner side):

Was: `or \`blocked\` (+ the report: why / tried / needs).`
Becomes: `or \`blocked\` (+ a paste-ready Blockers block — **Why / Tried / Needs** — written by the owner for the board).`

- [ ] Step 4: After the bullet `Append \`dispatched\` to the board's Dispatch Log.`, add the agent-addressing bullet (AC-9):

```markdown
   - Keep the **agentId** from the spawn result — name aliases expire; address every resume or relay by that ID, never by name. Treat relays as one-way: read the owner's answers from repository artifacts, not from message replies.
```

- [ ] Step 5: Replace loop step 3 (board commit per append — AC-2; paste-unmodified Blockers — AC-4; state polling + watchdog — AC-8):

Was:
```markdown
3. **Track** — as each owner returns, append the event to the Dispatch Log. On `shipped`: note the learnings one-liners and PR URL. On `blocked`: copy the owner's report verbatim into the board's Blockers section. Owners flip their own `issue.md` status; the orchestrator never edits an `issue.md`.
```
Becomes:
```markdown
3. **Track** — as each owner returns, append the event to the Dispatch Log, and **commit the board after every Dispatch Log append** — not only at round close; an uncommitted line is lost to a crash. On `shipped`: note the learnings one-liners and PR URL. On `blocked`: paste the owner's paste-ready Blockers block (Why / Tried / Needs) into the board's Blockers section **unmodified** — the conductor never composes or restructures it. Owners flip their own `issue.md` status; the orchestrator never edits an `issue.md`.
   - Completion notifications reach only the top-level session — never wait on them. Poll each dispatched owner's **observable state** (repository files, branches, commit and output timestamps) on a cadence of a few minutes; treat silence as still-running only until a state check says otherwise.
   - **Watchdog:** 10 minutes without observable progress from an owner → flag it and verify its state directly; a confirmed stall is resumed by its agentId or re-dispatched.
```

- [ ] Step 6: Verify — `grep -c "new loop turn\|commit the board after every\|dependency's own branch\|paste-ready Blockers block\|agentId\|Watchdog" .agents/skills/sw-run/SKILL.md` returns non-zero and the section reads coherently top to bottom.
- [ ] Step 7: Commit (`fix: make round approvals, readiness source, log durability, blocker fidelity, polling and addressing explicit in run skill loop`).

### Task 2: Circuit-breaker and closeout contract additions

**AC:** AC-5, AC-6, AC-7
**Delegable:** no — same file, stacked on Task 1's edits.
**Files:**
- Modify: `.agents/skills/sw-run/SKILL.md:34-46` (sections `## Circuit breakers`, `## Closeout (all shipped)`)

- [ ] Step 1: Replace the halt bullet (executable recovery line — AC-5):

Was:
```markdown
  - **Only blocked issues left** → print a consolidated blockers report (every Blockers entry + what each needs from the human) and stop. When the human resolves a blocker, they set the issue back to `status: pending` (or edit its `issue.md`) and re-run this skill.
```
Becomes:
```markdown
  - **Only blocked issues left** → print a consolidated blockers report (every Blockers entry + what each needs from the human) and stop. Each entry's recovery line must be executable by a maintainer ignorant of the branch mechanics: name the exact `issue.md` path **inside the issue's own checkout** (its worktree or branch — the `main` copy is read by nobody in the loop), instruct editing it per the chosen option and setting `status:` back to `pending`, **committing the edit on the issue's branch**, and sweeping the rest of the ticket for restatements of the dropped constraint (a constraint rarely lives in a single hunk). Then re-run this skill.
```

- [ ] Step 2: Replace the scope guard (loop-scoped with closeout exception — AC-6):

Was:
```markdown
- **Scope guard:** the orchestrator never creates or removes issues, never reorders the board's dependencies, and never edits `goal.md`. Concluding the decomposition was wrong IS a blocker — report it and stop.
```
Becomes:
```markdown
- **Scope guard (conduction loop):** while the loop runs, the orchestrator never creates or removes issues, never reorders the board's dependencies, and never edits `goal.md` — the one exception is closeout's goal reconciliation, applied only with the maintainer's approval. Concluding the decomposition was wrong IS a blocker — report it and stop.
```

- [ ] Step 3: Replace the closeout list (goal reconciliation step — AC-6; summary timing — AC-7):

Was:
```markdown
1. Append a final summary to the board: issues shipped, PR URLs, blockers survived.
2. **Promote durable learnings** — read every issue's `learnings.md`; propose the facts that outlive the milestone (data formats, invariants, conventions) for promotion into the area `AGENTS.md` or `.specwright/conventions/`. **Apply only what the user approves.** Ephemeral learnings stay in the issue folders as history.
3. Report to the user: the milestone is done; merging the PRs is theirs.
```
Becomes:
```markdown
1. **Reconcile `goal.md`** — flag any goal statement superseded by decisions recorded during conduction (board notes, blocker resolutions); propose the reconciling edit; **apply only with the maintainer's approval**. Nothing superseded → say so and move on.
2. **Promote durable learnings** — read every issue's `learnings.md`; propose the facts that outlive the milestone (data formats, invariants, conventions) for promotion into the area `AGENTS.md` or `.specwright/conventions/`. **Apply only what the user approves.** Ephemeral learnings stay in the issue folders as history.
3. Append a final summary to the board: issues shipped, PR URLs, blockers survived. Written **after** the reconciliation and promotion approvals above; if a draft went in earlier, amend only within the appended summary section — the rest of the board stays frozen.
4. Report to the user: the milestone is done; merging the PRs is theirs.
```

- [ ] Step 4: Verify — read `## Circuit breakers` + `## Closeout` in full; the guard names the closeout exception and the closeout has 4 numbered steps.
- [ ] Step 5: Commit (`fix: executable blocked-recovery line, closeout goal reconciliation and summary timing in run skill`).

## Phase 2: Propagation

### Task 3: Propagate the body to the plugin and scaffold copies

**AC:** AC-10
**Delegable:** no — mechanical, seconds of work.
**Files:**
- Modify: `plugins/sw/skills/run/SKILL.md` (keep `name: run`)
- Modify: `skills/sw/scaffold/skills/sw-run/SKILL.md` (keep `name: sw-run`)

- [ ] Step 1: For each target, keep its lines 1–2 (`---` + its own `name:`) and replace line 3 onward with the canonical file's line 3 onward:

```bash
head -2 plugins/sw/skills/run/SKILL.md > /tmp/run-plugin.md && tail -n +3 .agents/skills/sw-run/SKILL.md >> /tmp/run-plugin.md && mv /tmp/run-plugin.md plugins/sw/skills/run/SKILL.md
head -2 skills/sw/scaffold/skills/sw-run/SKILL.md > /tmp/run-scaffold.md && tail -n +3 .agents/skills/sw-run/SKILL.md >> /tmp/run-scaffold.md && mv /tmp/run-scaffold.md skills/sw/scaffold/skills/sw-run/SKILL.md
```

- [ ] Step 2: Verify parity: `diff <(tail -n +3 plugins/sw/skills/run/SKILL.md) <(tail -n +3 .agents/skills/sw-run/SKILL.md)` and `diff <(tail -n +3 skills/sw/scaffold/skills/sw-run/SKILL.md) <(tail -n +3 .agents/skills/sw-run/SKILL.md)` — both empty; `head -2` of each shows only the `name:` divergence.
- [ ] Step 3: Commit (`fix: propagate run skill contract to plugin and scaffold copies`).

### Task 4: Board template Blockers wording

**AC:** AC-4, AC-10
**Delegable:** no — one line.
**Files:**
- Modify: `skills/sw/scaffold/templates/board.md:26`

- [ ] Step 1: Replace the Blockers intro line:

Was:
```markdown
One entry per blocked issue — the owner's report, copied verbatim. Delete the entry when the issue is unblocked (the Dispatch Log keeps the history).
```
Becomes:
```markdown
One entry per blocked issue — the owner's paste-ready Blockers block (Why / Tried / Needs), pasted unmodified. Delete the entry when the issue is unblocked (the Dispatch Log keeps the history).
```

- [ ] Step 2: Verify — `grep -n "verbatim" skills/sw/scaffold/templates/board.md` returns nothing; `grep -n "paste-ready Blockers block" skills/sw/scaffold/templates/board.md` hits line 26.
- [ ] Step 3: Commit (`fix: board template blockers section takes the owner's paste-ready block unmodified`).

## Phase 3: Verification

### Task 5: Runtime verification walk

**AC:** AC-1, AC-2, AC-3, AC-4, AC-5, AC-6, AC-7, AC-8, AC-9, AC-10
**Delegable:** no — the owner ticks the ACs.
**Files:**
- Modify: `.specwright/milestones/2026-07-02-specwright-fixes/issues/run-skill-contract/issue.md` (tick verified ACs)

- [ ] Step 1: Run `skills/sw/scripts/validate-spec.sh .specwright/milestones/2026-07-02-specwright-fixes/issues/run-skill-contract` — expect `PASS`, exit 0.
- [ ] Step 2: Walk AC-1 through AC-9 against the canonical file content (read the exact sentences; each AC's required elements present verbatim-in-meaning) and AC-10 by the two parity diffs + the board-template grep from Task 4 Step 2.
- [ ] Step 3: Tick each verified `AC-N` checkbox in `issue.md`.
- [ ] Step 4: Commit (`chore: verify run-skill-contract acceptance criteria`).
