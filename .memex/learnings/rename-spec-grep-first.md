---
tags:
  - learning
  - gotcha
related:
  - "[[../specs/2026-05-03-rename-harness-to-memex/spec]]"
created: 2026-05-03
---
# Rename specs must start with `git grep <oldname>` — never list scope from memory

When writing a spec for a rename or refactor that touches a single identifier across the repo, **the very first step is `git grep -l <oldname>` and `find . -name "*<oldname>*"` from the repo root**. Use that output to enumerate the spec's "in scope" list. Listing scope from memory misses files; listing it from `grep` does not.

## Context

While writing the rename-harness-to-memex spec, the "in scope" section was assembled from intuition: `skills/harness/`, `.agents/skills/harness-*`, `.claude/commands/harness-*`, `AGENTS.md`, `README.md`, `.vault/constitution.md`, the three mixed-context learnings, `_index/`, `templates/`, `conventions/`, `rules/`. That looked complete. During Phase 6 a repo-wide `git grep "harness"` surfaced **three additional files not in scope**: `.github/ISSUE_TEMPLATE/bug.md`, `CONTRIBUTING.md`, `SECURITY.md` — all of which needed updates. They got fixed mid-flight, but they should have been on the list from the start.

A second related gotcha: AC #1 in the same spec was *wrong on its face* — it listed paths that "should remain matching `find -name '*harness*'`" but it included shipped-spec files like `spec-opensource-readiness.md` whose basenames do **not** contain "harness". The original AC was assembled by recalling "the shipped spec contained harness references" and conflating *content* (`grep`) with *basename* (`find -name`). The error was caught when running the baseline `find` during Phase 1 — at which point the AC had to be re-written.

## How to Apply

For any rename/refactor spec — single identifier across multiple files:

1. **Before writing the Scope and Acceptance Criteria sections**, run two commands from repo root and save the output:
   ```bash
   git grep -l "<oldname>"        # files with the string anywhere
   find . -name "*<oldname>*"     # files/dirs whose basename contains it
   ```
2. **The "in scope" list is the union of those outputs**, minus any explicit Non-Goals (frozen historical records, literature/external-name collisions). Do not list scope from memory.
3. **Sanity-check every Acceptance Criterion that uses `find` or `grep` by running it against current state** while writing the spec. If the expected output doesn't match what the command actually produces today, the AC is wrong — fix it before locking the spec.
4. **Distinguish `find -name` from `grep` explicitly.** `find -name "*X*"` matches **basenames only**; a file at `path/with-X-in-it/spec.md` is matched but `path/with-X-in-it/different.md` is *not*. If your AC means "no file mentions X anywhere", use `grep -rl`, not `find`. Mixing them is a common bug.

The cost is one minute of `grep` + `find` up front, against the cost of finding three forgotten files in Phase 6 of a multi-phase rename.
