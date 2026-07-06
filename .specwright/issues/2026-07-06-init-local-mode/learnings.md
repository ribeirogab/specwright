# Init Local Mode — Learnings

Curated non-obvious facts a future issue may need. Not narration.

## `git worktree add` carries only tracked content

A git-ignored file (a blanket-ignored `.specwright/`, a `CLAUDE.local.md`) is **not** materialized inside a worktree created by `git worktree add` — the new worktree checks out the committed tree only. Verified empirically. This is the load-bearing reason `local` mode cannot support milestone conduction as-is: `/sw:run` dispatches each owner into `.specwright/worktrees/<slug>`, and under `local` mode neither the specwright contract nor the issue folder would be present there. The deferred follow-up (milestone support in `local` mode) must make `/sw:run` copy `CLAUDE.local.md` + the issue folder into each worktree it creates.

## `CLAUDE.local.md` is auto-loaded by Claude Code

Current Claude Code walks the directory tree and loads both `CLAUDE.md` and `CLAUDE.local.md` at session start (local appended after shared). It is the officially sanctioned home for uncommitted, per-project instructions and is not deprecated. So a git-ignored `CLAUDE.local.md` at the repo root is a working entry point for a single-checkout session — but see the worktree fact above for why that does not extend to `/sw:run`.

## Commit-mode detection signals

- **In `init`** (may run before `git init`): filename-based — `local` established ⟺ `CLAUDE.local.md` contains `claude plugin install sw@specwright`; else `shared` if `CLAUDE.md` does; else fresh. `local` wins the tie by check order.
- **In `run`** (git always present): `git check-ignore -q .specwright/milestones` — exit 0 means the vault is blanket-ignored (`local` mode). Probe the vault path, not `.specwright/worktrees/`, which is ignored in both modes.

## `validation.md` entry-point checks are now `$ENTRY`-relative

Checks 1–4 (placeholder sweep, headers, size cap, plugin requirement) resolve `ENTRY` (`CLAUDE.local.md` if it carries the plugin phrase, else `CLAUDE.md`) instead of the literal `CLAUDE.md`. Check 6 asserts `.specwright/worktrees/` in both modes plus `.specwright/` and `CLAUDE.local.md` in `local`. Any future check that targets the entry point must reuse the `ENTRY` resolver, not hardcode `CLAUDE.md`.

## The vendored `quick_validate.py` rejects `user-invocable` (pre-existing)

`plugins/sw/scripts/quick_validate.py` (vendored Apache-2.0) errors on the `user-invocable` frontmatter key that every companion skill uses, so it cannot emit `Skill is valid!` for any skill in this repo — the PR template's "run quick_validate" checklist item is un-tickable for skill PRs until the validator learns that key or the template is adjusted.
