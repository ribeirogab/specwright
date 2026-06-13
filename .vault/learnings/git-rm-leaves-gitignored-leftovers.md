---
tags:
  - learning
  - gotcha
related:
  - "[[../specs/2026-06-13-dedicate-repo-to-memex/spec-dedicate-repo-to-memex]]"
created: 2026-06-13
---
# `git rm -r <dir>` leaves the directory on disk when it holds gitignored files

`git rm -r <dir>` removes and stages only the **tracked** files. Any gitignored or untracked content inside the directory is left untouched, so the directory itself remains on disk after the commit. Filesystem-level acceptance checks (`test ! -e <dir>`, `ls`) then report the dir as still present even though git shows it as fully deleted.

## Context

Deleting the non-memex skills in `dedicate-repo-to-memex`, `git rm -r skills/skill-improver evals .claude/skills/skill-creator` committed cleanly, yet `find`/`test -e` still found all three dirs. The survivors were purely gitignored build/eval artifacts: `scripts/__pycache__/*.pyc`, `evals/*/workspace/**` (matched by `evals/*/workspace/` in `.gitignore`), and `.claude/skills/skill-creator/*.skill`. `git ls-files <dir>` returned nothing (no tracked files remained), confirming the leftovers were all ignored.

## How to Apply

- After `git rm -r <dir>` on a directory that may contain build artifacts, run `git ls-files <dir>` (expect empty) and then `rm -rf <dir>` to clear the gitignored remainder. The `rm -rf` is safe precisely because git already shows zero tracked files there.
- When an acceptance criterion is a filesystem assertion (`test ! -e`), remember it sees ignored files too — a passing `git status` does not imply the path is gone.
