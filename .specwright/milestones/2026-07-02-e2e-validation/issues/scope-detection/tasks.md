---
feature: scope-detection
created: 2026-07-02
---
# Scope Detection (T1) — Tasks

**For this issue:** see the sibling `issue.md` (acceptance criteria) and `spec.md` (technical plan).

> Each task names the `AC:` (acceptance criteria from `issue.md` it satisfies — every `AC-N` must be referenced by at least one task) and `Delegable:` (whether it suits an isolated task worker, and the one-line context that worker would receive). Workers report findings back to the issue owner; only the owner writes `learnings.md`.

## Phase 1: Milestone case

### Task 1: Drive the milestone-case brainstorm session

**AC:** AC-1, AC-2
**Delegable:** no — the owner is the scripted user; delegating the user role would leak the harness into the session.
**Files:**
- Create: `evidence/milestone-session.md` (in this issue folder)

- [x] **Step 1: Create the evidence folder and transcript file**

Run: `mkdir -p <issue-folder>/evidence`
Start `evidence/milestone-session.md` with a header noting date, sandbox path, and the recording convention (every `**User:**` / `**Session:**` exchange appended verbatim, in order).

- [x] **Step 2: Spawn the session-under-test with the neutral framing prompt + opening user message**

Agent tool, `subagent_type: general-purpose`, `name: taskr-session-m`, prompt exactly:

```
You are an AI coding assistant session working for a user in the repository
/Users/gabriel/www/ribeirogab/specwright-sandbox/taskr. Work only inside that
repository, always via absolute paths. The repository has agent instructions in
AGENTS.md — read and follow them.

This is an interactive chat with the user. Whenever you need an answer, a
decision, or an approval from the user, end your turn with your message to the
user — their reply arrives as the next message. Never simulate or assume the
user's replies. Address the user directly; there is no one else in the chat.

The user's first message is:

/sw:brainstorm I want to grow taskr beyond add/list/done. Here's what I need:
(1) tasks should have a priority — high, medium, or low; (2) I want to filter
the list by priority and by status; (3) I need to export my tasks to JSON and
to CSV, and dates in the exports must be ISO-8601; (4) a minimal web page that
shows my tasks and their status; (5) the list should show the newest task
first. One hard constraint: the existing tests must not be touched — they stay
exactly as they are and keep passing.

The /sw:brainstorm command corresponds to the skill at
.agents/skills/sw-brainstorm/SKILL.md in the repository — read that file and
follow it exactly.
```

- [x] **Step 3: Record the exchange and reply per the policy until the session stops**

Append each session reply and each user reply verbatim to `evidence/milestone-session.md`. Continue the session with SendMessage (`to: taskr-session-m`). Reply policy (requirements only, never mechanics; never say "milestone"/"single issue"/"scope" before the session does):

| Session asks about | Scripted user answer |
|---|---|
| Visual companion offer | "No thanks, text is fine." |
| Default priority for existing/new tasks | "Default to medium." |
| Filter UX | "Flags on `taskr list`, like `--priority high` and `--status done`, combinable." |
| Export UX | "An `export` command with a format option, printing to stdout is fine." |
| Web page scope | "Read-only, just show the tasks and whether they're done. No frameworks, keep it dependency-free like the rest of taskr." |
| Pushback on "newest first vs untouched tests" conflict | "I hear you, but the requirement stands as stated: newest first, and the existing tests stay exactly as they are." |
| Design approval | "Approved, looks good." (only after a design is actually presented) |
| Scope conclusion (only after the session suggests it) | Accept the session's suggestion: "Agreed — go with that." |
| One-batch worktree question | "Yes, use the default." |
| Anything else requirement-shaped | Shortest reasonable user answer consistent with the five capabilities; never mechanics. |

Contingency (record in findings if used): session concludes one issue → one nudge: "That feels like too much for one PR — can it be broken up?"

- [x] **Step 4: Session end check**

The session is over when it prints a handoff (or otherwise stops asking). Save the final reply to the transcript. If the session errors/stalls, restart from Step 2 (max 3 attempts → blocked).

- [x] **Step 5: Commit the transcript**

Run in this worktree: `git add <issue-folder>/evidence/milestone-session.md && git commit -m "chore(vault): capture scope-detection milestone-case transcript"`

### Task 2: Verify the milestone-case results and capture artifact evidence

**AC:** AC-1, AC-2
**Delegable:** no — verdicts are the owner's.
**Files:**
- Create: `evidence/milestone-artifacts.txt`

- [x] **Step 1: AC-1 checks over the transcript**

Manually walk `evidence/milestone-session.md` and record (for findings.md): (a) the session *suggested* a milestone before any artifact was written; (b) the suggestion included an issue preview with slugs, one-liners, and dependencies; (c) the decision was explicitly left to the user; (d) no artifact write happened before the user's choice (cross-check: the sandbox commit for the milestone folder must postdate the user's acceptance turn — single commit after acceptance is the expected shape).

- [x] **Step 2: AC-2 checks in the sandbox**

Run and capture into `evidence/milestone-artifacts.txt`:
`git -C /Users/gabriel/www/ribeirogab/specwright-sandbox/taskr log --oneline -5`
`git -C /Users/gabriel/www/ribeirogab/specwright-sandbox/taskr show --stat HEAD`
`find /Users/gabriel/www/ribeirogab/specwright-sandbox/taskr/.specwright/milestones -type f`
Then verify by reading the artifacts: (a) milestone folder committed; (b) issues cover the five seeded capabilities (priorities, filters, export ISO-8601, web page, newest-first list); (c) at least two issues have no dependencies on the board; (d) a list-ordering issue exists whose criteria conflict with the planted oldest-first test.

- [x] **Step 3: Sandbox integrity check**

Run: `cd /Users/gabriel/www/ribeirogab/specwright-sandbox/taskr && npm test`
Expected: 5 tests pass (brainstorm must not have touched code/tests).

- [x] **Step 4: Commit the artifact evidence**

Run: `git add <issue-folder>/evidence/milestone-artifacts.txt && git commit -m "chore(vault): capture scope-detection milestone artifact evidence"`

## Phase 2: False-positive case

### Task 3: Prepare the disposable sandbox copy

**AC:** AC-3
**Delegable:** no — trivial setup inline.
**Files:**
- Create (scratchpad, disposable): `<scratchpad>/taskr-fp/`, `<scratchpad>/taskr-fp-origin.git`, `<scratchpad>/taskr-fp-baseline.txt`

- [x] **Step 1: Copy the sandbox and repoint origin**

Run:
`cp -R /Users/gabriel/www/ribeirogab/specwright-sandbox/taskr <scratchpad>/taskr-fp`
`git clone --bare /Users/gabriel/www/ribeirogab/specwright-sandbox/taskr-origin.git <scratchpad>/taskr-fp-origin.git`
`git -C <scratchpad>/taskr-fp remote set-url origin <scratchpad>/taskr-fp-origin.git`

- [x] **Step 2: Verify the copy is intact**

Run: `git -C <scratchpad>/taskr-fp remote -v && cd <scratchpad>/taskr-fp && npm test`
Expected: origin points at the scratch bare; 5 tests pass.

- [x] **Step 3: Snapshot the post-copy baseline**

The copy is taken after Phase 1, so it already contains the milestone fixture — "milestones dir empty" can never be the check. Snapshot what the copy starts with:
Run: `find <scratchpad>/taskr-fp/.specwright -type f | sort > <scratchpad>/taskr-fp-baseline.txt`

### Task 4: Drive the false-positive brainstorm session

**AC:** AC-3
**Delegable:** no — owner plays the user.
**Files:**
- Create: `evidence/false-positive-session.md`
- Create: `evidence/false-positive-checks.txt`

- [x] **Step 1: Spawn the session with the neutral framing + tiny request**

Agent tool, `subagent_type: general-purpose`, `name: taskr-session-fp`, prompt: same neutral framing as Task 1 Step 2 but with repository path `<scratchpad>/taskr-fp` and the user's first message:

```
/sw:brainstorm Can we add a --version flag to taskr? It should print the
version from package.json and exit.
```

- [x] **Step 2: Record and reply per policy until the session stops**

Same recording convention into `evidence/false-positive-session.md`. Reply policy:

| Session asks about | Scripted user answer |
|---|---|
| Visual companion offer | "No thanks." |
| Flag UX details | "`taskr --version` and that's it — print the version, exit 0." |
| Design approval | "Approved." |
| Three-part batch (branch / worktree / handoff) | "Branch name is fine, no worktree, and yes — hand off, I'll pick it up later." |
| Anything else | Shortest reasonable user answer; never the words the session hasn't used. |

- [x] **Step 3: AC-3 mechanical check**

Run and capture into `evidence/false-positive-checks.txt`:
`grep -in "milestone" <issue-folder>/evidence/false-positive-session.md`
Expected: zero matches inside `**Session:**` turns — scope the verdict to session turns (any match must be attributed; a match in a `**User:**` turn would be a harness leak and its own finding; expected overall: grep exits 1). Also capture the new-file diff against the Task 3 baseline:
`find <scratchpad>/taskr-fp/.specwright -type f | sort | comm -13 <scratchpad>/taskr-fp-baseline.txt -`
Expected: the only new line(s) are paths ending in `.specwright/issues/<date>-<slug>/issue.md`; no new path contains `.specwright/milestones/` (both sides of the comm come from the same `find` shape, so paths compare like-for-like). Plus `git -C <scratchpad>/taskr-fp log --oneline -3` showing the single-issue commit.

- [x] **Step 4: Commit the fp evidence**

Run: `git add <issue-folder>/evidence/false-positive-session.md <issue-folder>/evidence/false-positive-checks.txt && git commit -m "chore(vault): capture scope-detection false-positive evidence"`

The copy stays in the scratchpad (session-temporary — that is the discard).

## Phase 3: Findings and delivery

### Task 5: Write findings.md

**AC:** AC-4
**Delegable:** no — the verdicts are the owner's synthesis.
**Files:**
- Create: `findings.md` (in this issue folder)

- [x] **Step 1: Write one verdict per check**

Structure: a `## Checks` table — one row per underlying check of AC-1 (suggested-not-forced, preview with slugs/one-liners/deps, user decides, no early artifact write), AC-2 (committed artifacts, five capabilities covered, ≥2 dependency-free issues, conflicting list-ordering issue), AC-3 (single-issue path, zero milestone mentions) — each with pass/fail + evidence pointer (file + section/line). Then `## Findings`: one `### Finding N` per failed check with **Expected / Observed / Proposed fix**. If all pass, state "No findings — all checks passed."

- [x] **Step 2: Commit**

Run: `git add <issue-folder>/findings.md && git commit -m "chore(vault): record scope-detection findings"`

### Task 6: Quality gate + runtime verification

**AC:** AC-1, AC-2, AC-3, AC-4
**Delegable:** no.
**Files:**
- Modify: `issue.md` (tick verified ACs)

- [x] **Step 1: Mechanical gate**

Run: `<worktree>/skills/sw/scripts/validate-spec.sh <issue-folder>`
Expected: exit 0.

- [x] **Step 2: Runtime verification pass**

Re-walk AC-1..AC-4 against the observed evidence (the sessions *are* the runtime): each AC's verdict must trace to a file in `evidence/` or `findings.md`. Tick the `[x]` boxes in `issue.md` for ACs verified by observed behavior. Note: an AC whose underlying checks failed is still "verified" for this issue if the failure is recorded in findings.md — this issue ships findings, not fixes; AC-4 is the gate that makes failures shippable. But AC-1..AC-3 tickboxes reflect the actual observed outcomes; leave unticked any that failed and say so in the PR body.

- [x] **Step 3: Sandbox quality gate re-check**

Run: `cd /Users/gabriel/www/ribeirogab/specwright-sandbox/taskr && npm test`
Expected: 5 tests pass.

- [x] **Step 4: Commit**

Run: `git add <issue-folder>/issue.md && git commit -m "chore(vault): record scope-detection runtime verification"`

### Task 7: Deliver — PR, review, learnings, ship

**AC:** AC-4
**Delegable:** no.
**Files:**
- Create: `learnings.md`
- Modify: `issue.md` (`status: shipped`, `shipped:` date)

- [x] **Step 1: Curate learnings.md**

Facts future issues need, at minimum: the sandbox milestone fixture's exact path and slugs, which of its issues are dependency-free (round-1 candidates), which issue carries the impossible oldest-first conflict, and any surprising session behavior downstream drivers must plan around.

- [x] **Step 2: Open the PR**

`/sw:pr` — base `chore/e2e-sandbox-setup` (stacked; note the stacking in the PR body), head `chore/e2e-scope-detection`. Include the runtime-verification record. Never fabricate the URL.

- [x] **Step 3: Review to lgtm**

`/sw:review` on the branch diff; fix blockers; iterate to `lgtm`.

- [x] **Step 4: Ship**

Set `issue.md` `status: shipped` + `shipped: <date>`; commit `learnings.md` + `issue.md`; push. Report back: one line per learning + PR URL.
