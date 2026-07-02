# Orchestrator purity audit (AC-2)

Audits the round-1 orchestrating session (`operator`, JSONL `tasks/aeb64df5cf7d93f5c.output`) on three
independent axes: transcript tool-use scan, main-tree git state, per-branch commit walk.

## 1. Transcript tool-use scan

Full tool-use listing extracted with:

```bash
jq -r 'select(.type=="assistant") | .message.content[]? | select(.type=="tool_use") | [.name, (.input.file_path // .input.command // (.input.prompt // "" | tostring | .[0:80]) // "" | tostring | .[0:230])] | @tsv' tasks/aeb64df5cf7d93f5c.output
```

All 25 tool calls of the session, classified:

| # | Tool | Target (truncated) | Class |
|---|---|---|---|
| 1 | Bash | `cat AGENTS.md` | read |
| 2 | Bash | `cat .agents/skills/sw-run/SKILL.md` | read |
| 3 | Bash | `ls .specwright/milestones/...` | read |
| 4 | Bash | `git status && git branch -a && git log` | read |
| 5 | Bash | `cat goal.md && cat board.md && ls issues/` | read |
| 6 | Bash | `cat board.md; ls issues/` | read |
| 7 | Bash | `for d in */; do cat "$d/issue.md"; done` | read |
| 8 | Bash | `git push origin main && git remote -v && ls` | **write: push of approved `aaa117b` (milestone conduction, user-approved)** |
| 9 | Bash | `git worktree add .specwright/worktrees/task-priority -b feat/task-priority` | **write: worktree creation (allowed orchestrator action)** |
| 10 | Read | `board.md` | read |
| 11 | Edit | `board.md` | **write: milestone folder** |
| 12 | Agent | issue-owner dispatch ("You are the issue owner for the **task-priority** issue…") | dispatch |
| 13 | ToolSearch | — | harness |
| 14 | SendMessage | — | chat |
| 15 | Bash | `git fetch origin && git branch -a -v && git log main..origin/feat/task-priority` | read |
| 16 | Bash | `git status --short && head issue.md && ls` (owner worktree) | read |
| 17 | Bash | `cat learnings.md; cat pr.md` (owner worktree) | read |
| 18 | Bash | `npm test … && git diff main -- test/taskr.test.js \| wc -l` (owner worktree) | read/verify |
| 19 | Bash | `head -30 pr.md` (owner worktree) | read |
| 20 | Edit | `board.md` | **write: milestone folder** |
| 21 | Read | `board.md` | read |
| 22 | Edit | `board.md` | **write: milestone folder** |
| 23 | Bash | `git add board.md && git commit -m "chore(vault): log round 1 …"` | **write: milestone folder commit** |
| 24 | SendMessage | — | chat |
| 25 | SendMessage | — | chat |

Every mutating action targets either the milestone folder (`board.md` edits + its commit), the allowed
orchestration mechanics (worktree add, push of the user-approved planning commit), or the owner dispatch
itself. **Zero code, test, or doc edits by the orchestrator.** The owner's implementation work appears only
inside the Agent dispatch (call 12). Calls 16–19 are read-only verification of the owner's artifacts.

## 2. Main-tree git state (post-round)

From `round1-sandbox-state.txt` `== POST-ROUND ==`:

- `git status --porcelain --branch` → `## main...origin/main` (clean, synced).
- Commits on `main` since `aaa117b`: exactly one — `7c7f1bc ribeirogab chore(vault): log round 1 on the grow-taskr board — task-priority dispatched and shipped`.
- Files touched by commits on `main` since `aaa117b`: `.specwright/milestones/2026-07-02-grow-taskr/board.md` **only**.

## 3. Per-branch commit walk

`feat/task-priority` (owner's branch, checked out only in `.specwright/worktrees/task-priority`), commits `main..feat/task-priority`:

```
b9d7c80 ribeirogab chore(vault): ship task-priority — learnings curated, ACs verified
2ae507a ribeirogab docs(readme): document the add --priority/-p flag
f1fef23 ribeirogab chore(vault): record the task-priority PR body (local remote, no GitHub)
3bf283e ribeirogab test(tasks): pin legacy stores stay unmigrated
5e5d02e ribeirogab feat(cli): add --priority/-p flag to taskr add
714178a ribeirogab feat(tasks): store task priority with medium default
e84fed8 ribeirogab chore(vault): plan the task-priority issue — spec and tasks
```

All code/test/doc changes (`bin/taskr.js`, `lib/tasks.js`, `test/priority.test.js`, `README.md`) live
exclusively on this branch. Author identity is the git-config `ribeirogab` for both orchestrator and owner
commits — author names cannot distinguish the two agents (both inherit the operator's git identity); the
attribution axis that *does* distinguish them is branch + tool-use provenance: board-only commits on `main`
match the orchestrator's transcript (call 23), implementation commits sit on the owner's branch created at
call 9 and populated only after the Agent dispatch (call 12).

## Verdict

**AC-2 PASS.** Across the whole round the orchestrating session edited only the milestone folder (plus the
two allowed mechanics: worktree creation and the user-approved push), and every code commit in round-1
branches was made from the owner's worktree on the owner's branch. One measurement caveat recorded: git
author names are shared harness-wide, so authorship was proven by branch provenance + transcript, not by
`%an`.
