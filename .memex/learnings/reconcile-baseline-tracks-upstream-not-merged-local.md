---
tags:
  - learning
  - gotcha
related:
  - "[[../specs/2026-06-16-memex-update-command/spec|memex-update-command]]"
  - "[[mechanical-enforcement-over-prose]]"
created: 2026-06-16
---
# Three-way reconcile: the recorded baseline must be the upstream hash, never the merged-local hash

In a stock-vs-edited reconcile (local `L`, baseline `B`, upstream `U`; `L==B`→stale-clean auto-copy, `L!=B & B!=U`→conflict), the hash you record **after resolving a file** must be `U` — the upstream content you reconciled *to* — and never the post-merge local hash. Record the merged-local hash and you reintroduce the exact bug the tool exists to prevent: next run sees `L==B` (user "untouched" since the recorded point), so an otherwise-unchanged upstream classifies the merged file as **stale-clean and auto-overwrites the user's merge**. The end-state invariant is `B == U` for every managed path after a complete run — for auto-applied files (`L` becomes `U`, so either works) *and* for agent-merged conflicts (`L` keeps local edits, so `B` must be set to `U` explicitly, leaving `L != B == U` → the file correctly reads `local-only` on the next unchanged-upstream run and is preserved).

## Context

Building `/memex:update` (the `memex-update.sh` engine). The committed `tasks.md` wired `--record <path>` to store `$(_local_hash "$path")`. That is correct only when `L==U` (a fresh install or a just-applied stale-clean file), and silently wrong for a merged conflict, where `L` carries the user's edits and `U` does not. Implemented `--record <path> <clone>` to recompute and store the **upstream** hash via the `managed_pairs` mapping; the `--self-test` apply-sandbox doesn't cover the post-merge record, so it was verified with a standalone sandbox asserting `recorded == sha(upstream) && recorded != sha(merged-local)`.

## How to Apply

When designing any baseline-tracked sync (manifest of "last-seen-upstream" hashes), state the invariant up front: **baseline := upstream-at-reconcile-time**, for all paths, after every run. Have the deterministic loop record `U` for the safe classes (current/stale-clean/local-only) inline, and have the agent record `U` (not the file it just wrote) after each semantic merge. Add a test that a merged file's recorded baseline equals the *upstream* hash and differs from the *local* hash — the matrix self-test won't catch a record-step that hashes the wrong operand.
