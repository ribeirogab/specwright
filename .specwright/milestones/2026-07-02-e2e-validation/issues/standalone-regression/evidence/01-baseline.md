# Evidence 01 — Sandbox baseline (pre-run)

Captured 2026-07-02, before any driven session was spawned. All commands run read-only in `/Users/gabriel/www/ribeirogab/specwright-sandbox/taskr` (main checkout).

## HEAD, cleanliness, remotes

```
$ git branch --show-current
main
$ git log --oneline -3
ab65ca0 chore(vault): apply the grow-taskr closeout decisions — promote approved learnings, reconcile goal.md ordering exception
d9c8114 chore(vault): close out the grow-taskr board — all 5 issues shipped, final summary appended
5a9b369 chore(vault): log round 4 on the grow-taskr board — list-newest-first resumed, dispatched and shipped; blocker cleared
$ git status --porcelain
(empty — clean tree)
$ git remote -v
origin	/Users/gabriel/www/ribeirogab/specwright-sandbox/taskr-origin.git (fetch)
origin	/Users/gabriel/www/ribeirogab/specwright-sandbox/taskr-origin.git (push)
```

Matches the T8 closeout learnings baseline exactly: `main` @ `ab65ca0` == `origin/main`, clean.

## Standalone vault empty; design.md sweep = 0 (AC-4 "before" leg)

```
$ ls -la .specwright/issues/
total 0
drwxr-xr-x@ 3 gabriel  staff   96 Jul  2 01:33 .
drwxr-xr-x@ 6 gabriel  staff  192 Jul  2 03:25 ..
-rw-r--r--@ 1 gabriel  staff    0 Jul  2 01:33 .gitkeep
$ find . -name design.md -not -path './node_modules/*' | wc -l
       0
```

## Leftover milestone machinery (inert, expected)

```
$ ls .specwright/worktrees/
export-json-csv  list-filters  list-newest-first  task-priority  web-page
```

Five grow-taskr worktrees and five unmerged feature branches remain (specwright never removes worktrees; merging is the human's). The conventions file `.specwright/conventions/store-and-constants.md` exists (T8 promotion).

## Suite and current --help behavior on main

```
$ npm test 2>&1 | grep -E '^ℹ (tests|pass|fail)'
ℹ tests 5
ℹ pass 5
ℹ fail 0
$ node bin/taskr.js --help; echo "exit: $?"
usage: taskr <add|list|done> ...        # printed on stderr (fail() → console.error)
exit: 1
```

`--help` currently falls into `bin/taskr.js`'s `default:` case: generic usage line on **stderr**, **exit 1**. The feature to be designed by the driven session ("a real `--help` flag with usage text") is genuinely absent.

## Dispatch-context correction (recorded, not a divergence)

The T9 dispatch prompt said "the suite is now 25 tests with newest-first default". That describes the unmerged `feat/list-newest-first` branch tip (`a15025c`), not `main`. On `main` (`ab65ca0`), where a standalone issue branches from, the suite is **5 tests** and `taskr list` is **oldest-first**. Consistent with every sibling learning (branches unmerged, tickets `pending` on main). Audits below use main's 5 as the inherited-test floor.
