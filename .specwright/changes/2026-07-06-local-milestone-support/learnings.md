# Local Milestone Support — Learnings

Curated non-obvious facts a future issue may need. Not narration.

## Local-mode conduction = canonical vault + copy-in/sync-back

In `local` mode the vault and `CLAUDE.local.md` are git-ignored, so git cannot carry them across worktrees. `/sw:run` therefore treats the checkout it runs in as the **canonical vault** (the only place the artifacts live — where `/sw:init local` ran) and bridges worktrees by **file copy**: copy `CLAUDE.local.md` + the issue folder into each worktree on dispatch, copy the owner's folder back into the canonical vault on return. Because the `.gitignore` lines are committed in `local` mode, every copied artifact lands git-ignored in the worktree — the owner never commits it. Any future change to `/sw:run` or `/sw:pr` that assumes committed artifacts must add a `local`-mode branch keyed off `git check-ignore -q .specwright/milestones`.

## The two-probe detection

- `git check-ignore -q .specwright/milestones` reports `local` from **any** worktree — the `.gitignore` is committed and present in every checkout, so it detects the mode even where the vault directory is absent.
- `[ -d .specwright/milestones ]` is the separate test for whether *this* checkout actually holds the vault. `local` + absent → stop (an externally-created worktree, e.g. `.claude/worktrees/`, is not the conductor's home).

## `cp -R` idempotency: copy contents, not the dir

`cp -R src dest` nests as `dest/src` when `dest` already exists. To stay idempotent across a re-dispatch into a reused worktree, copy **contents**: `mkdir -p "$DEST" && cp -R "$SRC/." "$DEST/"`. Both the copy-in and the sync-back use this shape.

## In local mode the board persists by file write, not commit

`/sw:run`'s "commit the board after every Dispatch Log append" is a `shared`-mode crash guard. In `local` mode the board is git-ignored, so the commit is a no-op; the board survives by the file write itself in the canonical vault (there is no branch to lose an uncommitted line to).

## Deferred: home-dir import for externally-created worktrees

Loading the `CLAUDE.local.md` contract inside an arbitrary externally-created worktree (a `.claude/worktrees/` one, or a manual `git worktree add`) is **not** solved here — copy-in only covers the worktrees `/sw:run` itself creates. The clean fix for the general case is a home-dir import (`@~/.claude/specwright-<repo>.md`) that survives every worktree because it lives outside the repo; it was deferred as a Non-Goal in both this issue and [[init-local-mode]].
