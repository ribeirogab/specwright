# Evidence 04 — After-state audit (raw outputs)

All commands run read-only after the driven session finished. `$S` = `/Users/gabriel/www/ribeirogab/specwright-sandbox/taskr`, `$W` = `$S/.specwright/worktrees/help-flag`.

## 1. Vault path — standalone, not milestone (AC-2)

```
$ ls $W/.specwright/issues/2026-07-02-help-flag/
issue.md  learnings.md  spec.md  tasks.md
$ ls $S/.specwright/milestones/
2026-07-02-grow-taskr          # unchanged — no new milestone folder anywhere
$ ls $S/.specwright/issues/    # main checkout: still only .gitkeep (the issue lives on its branch)
```

## 2. JIT ordering from git history (AC-2)

```
$ git -C $W log --oneline --name-status --diff-filter=A main..HEAD -- '.specwright/issues/*'
2dcc275 chore(vault): ship the help-flag issue — ACs verified, review lgtm, learnings
A	.specwright/issues/2026-07-02-help-flag/learnings.md
A	.specwright/issues/2026-07-02-help-flag/spec.md
A	.specwright/issues/2026-07-02-help-flag/tasks.md
5b163f2 chore(vault): add the help-flag issue from the approved brainstorm
A	.specwright/issues/2026-07-02-help-flag/issue.md
```

`issue.md`'s adding commit (`5b163f2`) strictly predates the commit adding `spec.md`/`tasks.md` (`2dcc275`). Observation (not a failure): the session committed the plan artifacts only at ship time, not at plan time — the transcript places their Write calls at the plan stage, between the issue commit and implementation.

## 3. Suite green, no count drop (AC-3)

```
$ cd $W && npm test 2>&1 | grep -E '^ℹ (tests|pass|fail)'
ℹ tests 9
ℹ pass 9
ℹ fail 0
```

Base (`main`) had 5; the branch has 9 — 4 added, 5 inherited intact (audited against the branch's own base, per the T5 rule).

## 4. Runtime behavior (AC-3)

```
$ node $W/bin/taskr.js --help
usage: taskr <add|list|done> ...

commands:
  add <text...>   Add a task
  list            List tasks
  done <id>       Mark a task as done

Tasks are stored in the file named by TASKR_FILE (default: ./.taskr.json).
help exit: 0
$ node $W/bin/taskr.js -h >/dev/null; echo $?   # 0
$ node $W/bin/taskr.js bogus
usage: taskr <add|list|done> ...
try 'taskr --help'
bogus exit: 1
```

## 5. Delivery shape (AC-3)

```
$ git -C $S ls-remote origin | grep help
2dcc275f32294d8e07969c0d0c5eba31ced11812	refs/heads/feat/help-flag
$ grep -rn "github.com" $W/.specwright/issues/2026-07-02-help-flag/
no github.com URLs in issue folder
```

Branch pushed to the local bare origin at the ship commit; zero fabricated URLs. No `pr.md` — the organic degradation writes none (see findings Divergence 2).

## 6. design.md sweep, after leg (AC-4)

```
$ find $S -name design.md -not -path '*/node_modules/*'
(no output — count: 0)                       # covers the main checkout AND all worktrees (they live under $S)
$ jq -r '<assistant text turns>' agent-aa69801af5e6dff67.jsonl | grep -c 'design\.md'
0
```

No `design.md` file anywhere at any point (before leg: evidence 01); no assistant-authored transcript mention.

## 7. Shipped state (AC-3)

```
$ sed -n '1,5p' $W/.specwright/issues/2026-07-02-help-flag/issue.md
---
feature: help-flag
created: 2026-07-02
status: shipped
shipped: 2026-07-02
---
```

All 5 sandbox ACs ticked `[x]` (the final ticket elaborated the design preview's 4 ACs into 5 — AC-5 covers the README line; a normal brainstorm→ticket elaboration, not drift).
