---
tags:
  - learning
  - gotcha
related:
  - "[[../specs/2026-05-03-rename-context-to-vault/spec]]"
  - "[[rename-spec-grep-first]]"
  - "[[bash-strict-mode-grep-filter]]"
created: 2026-05-03
---
# Renaming a directory via `sed 's|old/|new/|g'` misses two classes of leftover references

When renaming a directory across many files, the natural pattern is `sed -i 's|old/|new/|g'` — substitute every occurrence of `old/` with `new/`. This works for path-style references (`old/learnings/foo.md`, `cd old/`, `find old/...`). But it leaves two classes of leftovers that need a separate pass:

1. **Bare directory references without a trailing slash.** Shell tests like `[ -d old ]`, `cd old`, `mkdir old`, `rm -rf old`. The pattern `old/` only matches `old/`-prefixed strings; `old` alone is invisible. In the `context/` → `.vault/` rename, `find-candidates.sh` had `if [ ! -d context ]` (line 12) which the sed pattern missed entirely. The script then ran post-rename and reported `FATAL: .vault/ not found` because it was checking for a `context` directory that no longer existed.

2. **Contextual phrases that read awkwardly post-substitute.** When the original text used the directory name as a path *inside a noun phrase* like "the `context/` vault" (meaning "the context/ directory, which is a vault"), the substitution produces `"the .vault/ vault"` — semantically redundant. Five SKILL.md/command descriptions had this artifact post-rename: `"Analyze the .vault/ vault for missing related: cross-links"`, `"Manual garbage-collection pass over the .vault/ vault"`, etc.

## Context

Hit during the `context/` → `.vault/` rename. The sed pass ran cleanly across 39 active files. `tests/run.sh` failed silently afterward — exit 1, FATAL message saying the wrong-named directory wasn't found. Took a `head -20` of the script to spot the missed `[ ! -d context ]` line. After fixing that, a wider grep `git grep -nE '\bcontext\b'` surfaced no other bare references in active files (only legitimate English usage of the word "context"). The phrase-level artifacts were caught later by a `git grep '.vault/ vault'` sweep.

Both classes are mechanically detectable but not by the obvious-looking `git grep 'old/'` baseline check, because the baseline by design doesn't see the bare references or the awkward repetitions.

## How to Apply

For any directory rename via sed (`old/` → `new/`):

1. **Run the sed pass on a list filtered by `git grep -l 'old/'`** as usual. This handles all path-style references.

2. **Then run a follow-up audit for bare references** that don't have the trailing slash. The grep that surfaces them:
   ```bash
   git grep -nE '\bold\b' \
     | grep -v -E '<paths to exclude>' \
     | head -20
   ```
   Inspect each. Most will be legitimate English usage of the word `old` (which is why a global substitution is unsafe). The ones that need flipping are usually shell tests or commands: `[ -d old ]`, `cd old`, `mkdir old`, `find old ...` (with the directory name as a literal arg, no slash). Fix those individually with `Edit`, not bulk sed.

3. **Then run a sweep for awkward post-substitute phrases**:
   ```bash
   git grep -n 'new/ new'   # double-mention from "old/ X" where X was the role description
   git grep -n 'new/new'    # accidental concatenation
   git grep -n 'new/X/new'  # nested awkwardness
   ```
   These are typo-grade artifacts. Fix individually.

4. **Re-run any test suites** (`tests/run.sh`, validation checklists) to surface anything missed. Tests that exercise the renamed directory are the highest-leverage check, because they exercise the path resolution end-to-end.

The general principle: a sed-based rename is **necessary but not sufficient**. Always pair it with two grep audits (bare references + awkward phrases) and a test rerun. A passing test suite is the strongest evidence the rename is complete; a clean `git grep 'old/'` is not.

This complements [[rename-spec-grep-first]] (which says "use grep to *enumerate scope* before writing the spec") with a different point: even after grep enumerates and sed substitutes, the rename isn't done — bare references and phrase artifacts survive both.
