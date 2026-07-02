---
feature: resume
created: 2026-07-02
---
# Resume (T3) — Tasks

**For this issue:** see the sibling `issue.md` (acceptance criteria) and `spec.md` (technical plan).

> Each task names the `AC:` (acceptance criteria from `issue.md` it satisfies — every `AC-N` must be referenced by at least one task) and `Delegable:` (whether it suits an isolated task worker, and the one-line context that worker would receive). Workers report findings back to the issue owner; only the owner writes `learnings.md`.

## Phase 1: Baseline

### Task 1: Capture the sandbox pre-test state

**AC:** AC-3
**Delegable:** no — trivial capture, and the baseline must be taken by the same actor that diffs it.
**Files:**
- Create: `evidence/sandbox-state.txt` (in this issue folder)
- Create (scratchpad, disposable): `<scratchpad>/pre/board.md`, `<scratchpad>/pre/<slug>.issue.md` (x5), `<scratchpad>/pre/state.txt`

- [x] **Step 1: Create the evidence folder and the pre-test copies**

Run (SANDBOX=`/Users/gabriel/www/ribeirogab/specwright-sandbox/taskr`, MS=`$SANDBOX/.specwright/milestones/2026-07-02-grow-taskr`):

```bash
mkdir -p <issue-folder>/evidence <scratchpad>/pre
cp "$MS/board.md" <scratchpad>/pre/board.md
for d in "$MS"/issues/*/; do cp "$d/issue.md" "<scratchpad>/pre/$(basename "$d").issue.md"; done
```

- [x] **Step 2: Capture the pre-test git and file state**

Run and save to `<scratchpad>/pre/state.txt`, then start `evidence/sandbox-state.txt` with a `## Before` section containing the same output:

```bash
git -C "$SANDBOX" status --porcelain --branch
git -C "$SANDBOX" log --oneline -3
git -C "$SANDBOX" worktree list
shasum -a 256 "$MS/board.md" "$MS"/issues/*/issue.md
grep -H '^status:' "$MS"/issues/*/issue.md
```

Expected: clean tree on `main` (ahead 1 of origin — baseline per learnings), HEAD `aaa117b`, single worktree, all five issues `status: pending`.

- [x] **Step 3: Commit the baseline evidence**

Run in this worktree: `git add <issue-folder> && git commit -m "chore(vault): plan the resume test (T3) and capture the sandbox baseline"` (includes spec.md/tasks.md and the in-progress status flip).

## Phase 2: /sw:run session

### Task 2: Drive the `/sw:run` session to the ready-set announcement and hold

**AC:** AC-1
**Delegable:** no — the owner is the scripted user; delegating the user role would leak the harness into the session.
**Files:**
- Create: `evidence/run-session.md`

- [x] **Step 1: Start the transcript file**

Start `evidence/run-session.md` with a header noting date, sandbox path, the recording convention (every `**User:**` / `**Session:**` exchange appended verbatim, in order), and the known harness caveat (driver agent name is visible to the session).

- [x] **Step 2: Spawn the session-under-test**

Agent tool, `subagent_type: general-purpose`, `name: taskr-session-run`, prompt exactly:

```
You are an AI coding assistant session working for a user in the repository
/Users/gabriel/www/ribeirogab/specwright-sandbox/taskr. Work only inside that
repository, always via absolute paths. The repository has agent instructions in
AGENTS.md — read and follow them.

This is an interactive chat with the user. Whenever you need an answer, a
decision, or an approval from the user, end your turn with your message to the
user — their reply arrives as the next message. Never simulate or assume the
user's replies. Address the user directly; there is no one else in the chat.

You are running in approval mode: reading files and running read-only commands
is allowed freely, but any other action — writing or editing any file, running
any command that changes state, creating branches or worktrees, or delegating
work to sub-agents — requires the user's approval first. Before any such
action, tell the user exactly what you intend to do and end your turn.

The user's first message is:

/sw:run

The /sw:run command corresponds to the skill at
.agents/skills/sw-run/SKILL.md in the repository — read that file and follow
it exactly.
```

- [x] **Step 3: Record and reply until the hold point**

Append each session reply and each user reply verbatim to `evidence/run-session.md`. Continue via SendMessage (keep the spawn-result agentId — names can expire). Reply policy (never name "ready", "dependency", any issue slug, or the milestone path before the session does; never mention the test):

| Session asks | Scripted user answer |
|---|---|
| Approval to dispatch / create a worktree / write the dispatch log (after announcing the ready set) | "Hold off — don't dispatch or change anything yet. I just wanted to see where the milestone stands; let's stop here for now." |
| Which milestone (should not happen — only one exists) | "The taskr one — grow-taskr." (record as a finding) |
| Approval for a read-only step it over-cautiously gated | "Go ahead." |
| Anything else | Shortest user-plausible answer that neither steers nor leaks; record verbatim. |

- [x] **Step 4: Session end check**

After the hold reply, the session should acknowledge and stop. Save its final reply verbatim. If the session stalls or errors, restart from Step 2 (max 3 attempts → `status: blocked`).

- [x] **Step 5: Commit the transcript**

Run: `git add <issue-folder>/evidence/run-session.md && git commit -m "chore(vault): capture the resume /sw:run session transcript"`

## Phase 3: Natural-language session

### Task 3: Drive the "continue the taskr milestone" session to the same hold

**AC:** AC-2
**Delegable:** no — same reason as Task 2.
**Files:**
- Create: `evidence/nl-session.md`

- [x] **Step 1: Start the transcript file**

Same header convention as `evidence/run-session.md`, noting this session receives **no** skill pointer — trigger-based discovery is under test.

- [x] **Step 2: Spawn the session-under-test**

Agent tool, `subagent_type: general-purpose`, `name: taskr-session-nl`, prompt exactly:

```
You are an AI coding assistant session working for a user in the repository
/Users/gabriel/www/ribeirogab/specwright-sandbox/taskr. Work only inside that
repository, always via absolute paths. The repository has agent instructions in
AGENTS.md — read and follow them. The repository's agent skills live under
.agents/skills/ — consult them when the instructions or the user's request
call for one.

This is an interactive chat with the user. Whenever you need an answer, a
decision, or an approval from the user, end your turn with your message to the
user — their reply arrives as the next message. Never simulate or assume the
user's replies. Address the user directly; there is no one else in the chat.

You are running in approval mode: reading files and running read-only commands
is allowed freely, but any other action — writing or editing any file, running
any command that changes state, creating branches or worktrees, or delegating
work to sub-agents — requires the user's approval first. Before any such
action, tell the user exactly what you intend to do and end your turn.

The user's first message is:

continue the taskr milestone
```

- [x] **Step 3: Record and reply until the hold point**

Identical reply policy to Task 2 Step 3, appended verbatim to `evidence/nl-session.md`.

- [x] **Step 4: Session end check**

Same as Task 2 Step 4 (max 3 attempts → `status: blocked`).

- [x] **Step 5: Commit the transcript**

Run: `git add <issue-folder>/evidence/nl-session.md && git commit -m "chore(vault): capture the resume natural-language session transcript"`

## Phase 4: Verification and findings

### Task 4: Post-test sandbox capture and AC-3 diffs

**AC:** AC-3
**Delegable:** no — verdicts are the owner's.
**Files:**
- Modify: `evidence/sandbox-state.txt`

- [x] **Step 1: Capture the post-test state**

Append a `## After` section to `evidence/sandbox-state.txt` with the same five commands as Task 1 Step 2.

Expected: byte-identical output to `## Before` (same porcelain, same HEAD `aaa117b`, same hashes, all five `status: pending`).

- [x] **Step 2: Byte-level diffs against the pre-test copies**

Run and append to `evidence/sandbox-state.txt` under `## Diffs`:

```bash
diff <scratchpad>/pre/board.md "$MS/board.md" && echo "board.md: identical"
for d in "$MS"/issues/*/; do s=$(basename "$d"); diff "<scratchpad>/pre/$s.issue.md" "$d/issue.md" && echo "$s/issue.md: identical"; done
```

Expected: every diff empty. The board's Issues table byte-identity (AC-3's named check) is subsumed by whole-file identity; if the whole file differs, extract and diff the `## Issues` section specifically and record both results.

- [x] **Step 3: Sandbox code-integrity check**

Run: `cd /Users/gabriel/www/ribeirogab/specwright-sandbox/taskr && npm test`
Expected: 5 tests pass (sessions must not have touched code).

- [x] **Step 4: Commit the state evidence**

Run: `git add <issue-folder>/evidence/sandbox-state.txt && git commit -m "chore(vault): capture the resume sandbox before/after state evidence"`

### Task 5: Write findings.md

**AC:** AC-1, AC-2, AC-3, AC-4
**Delegable:** no — verdicts are the owner's.
**Files:**
- Create: `findings.md`

- [x] **Step 1: Walk the transcripts for the AC-1/AC-2 checks**

For each session record pass/fail with a quote or evidence pointer: (a) milestone located without a path argument (user message contained none); (b) board/goal/frontmatter actually read (announcement reflects their content); (c) ready set announced as exactly `task-priority`; (d) no issue with unmet dependencies included; (e) session stopped on hold with no dispatch; (f) NL session reached the same behavior via trigger discovery, no skill pointer given.

- [x] **Step 2: Record the AC-3 verdicts**

From Task 4's diffs: all-pending check, board byte-identity, clean tree, unchanged HEAD, unchanged worktree list, `npm test` green.

- [x] **Step 3: Write findings.md**

Structure: one `### Check` block per check above with Verdict + Evidence pointer; one `### Divergence` block per failure with **Expected / Observed / Proposed fix**. Findings only — fix nothing.

- [x] **Step 4: Commit**

Run: `git add <issue-folder>/findings.md && git commit -m "chore(vault): record the resume (T3) findings"`

## Phase 5: Delivery

### Task 6: Quality gate and runtime verification

**AC:** AC-1, AC-2, AC-3, AC-4
**Delegable:** no.

- [x] **Step 1: Mechanical gate**

Run: `<worktree>/skills/sw/scripts/validate-spec.sh <issue-folder>`
Expected: exit 0.

- [x] **Step 2: Runtime verification mapping**

This is a test-execution issue: the driven sessions ARE the runtime. Map each `AC-N` to its observed evidence (transcript lines, diff outputs) and tick the `issue.md` checkboxes only for ACs whose evidence shows a pass.

- [x] **Step 3: Commit any final artifact touch-ups**

### Task 7: PR, review, learnings, ship

**AC:** AC-4
**Delegable:** no.

- [x] **Step 1: Open the PR** — `/sw:pr`, base `chore/e2e-milestone-planning` (stacked on the milestone-planning branch; note it in the PR body). Never fabricate a PR URL.
- [x] **Step 2: Review to lgtm** — `/sw:review`; fix blockers, re-run until `lgtm`.
- [x] **Step 3: Curate learnings.md** — only non-obvious facts downstream issues (dispatch-parallelism T4, circuit-breaker T7, blocked-recovery T8) need: how sessions behave at the dispatch boundary, discovery quirks, harness caveats.
- [x] **Step 4: Ship** — set `issue.md` `status: shipped` + date, tick verified ACs, commit on this branch.
