---
status: shipped
feature: rename-context-to-vault
created: 2026-05-03
shipped: 2026-05-03
related:
  - "[[../../learnings/memex]]"
  - "[[../../learnings/rename-spec-grep-first]]"
  - "[[../../learnings/agents-md-as-map-not-encyclopedia]]"
---
# Rename `context/` to `.vault/` — Spec

**Status:** Shipped (2026-05-03)
**Scope:** Rename the canonical knowledge-base directory from `context/` to `.vault/` across this repo and across every artifact the `memex` skill installs into target repos. Hard cut — the renamed `memex` only knows `.vault/`; downstream repos that previously installed `context/` keep what they have until manually migrated.

## Context

`context/` is the directory the `memex` skill scaffolds in any repo to hold the knowledge vault: constitution, specs, learnings, conventions, rules, indices, templates. The name was inherited from earlier drafts of the harness/memex skill — pre-Obsidian-alignment thinking — and was never deliberately chosen.

In the broader knowledge-management ecosystem (Obsidian, Logseq, Foam) the established term for "the directory containing your notes" is **vault**. The `memex` skill already produces an Obsidian-compatible layout (`.obsidian/` config, wikilinks, MOCs, frontmatter), so calling that directory `context/` rather than `.vault/` is a naming inconsistency the project has been carrying. This spec resolves it.

This is a sibling-in-spirit to the `harness → memex` rename (`[[../2026-05-03-rename-harness-to-memex/spec-rename-harness-to-memex]]`): a deliberate vocabulary cleanup that removes a load-bearing inconsistency in user-facing terminology. Same precedent applies for shipped specs (frozen historical record), per-occurrence judgment in mixed-context notes, and `git grep` discipline before listing scope ([[../../learnings/rename-spec-grep-first]]).

## Problem Statement

The directory at `context/` IS an Obsidian vault — same layout, same wikilink discipline, same `.obsidian/` config. But its name implies something more abstract ("contextual information") that doesn't match what it actually is. New users reading `AGENTS.md` see references to `context/learnings/`, `context/specs/`, `context/_index/` and need an explanation that "context here means vault". External tooling that scans for Obsidian vaults by convention does not find this one. The rename eliminates the indirection: the directory's name and its role agree.

## Non-Goals

- **Not** changing what's *inside* the directory. The structure (`learnings/`, `conventions/`, `rules/`, `specs/`, `_index/`, `templates/`, `.obsidian/`) stays identical.
- **Not** changing how the memex audit/scaffold logic works internally. Pure rename of paths and string references. Same idempotency, same Phase 5 validation, same scaffolder shape.
- **Not** rewriting historical spec records. The three shipped specs (`2026-04-30-opensource-readiness/`, `2026-05-03-rename-harness-to-memex/`, `2026-05-03-strengthen-vault-cross-links/`) are frozen — their contents reference `context/` because that was the directory name at ship time. Touching them would rewrite history.
- **Not** updating downstream repos that already ran the old `memex` skill. They keep `context/` until the user manually migrates. **Cross-version coexistence note:** if a downstream repo previously ran the old memex (which scaffolded `context/`) and then runs the renamed memex, the new scaffolder will create `.vault/` *alongside* the existing `context/`. Two parallel vaults until the user runs `git mv context/* .vault/ && rmdir context && /memex` to consolidate. Documented but not auto-handled.
- **Not** adding a back-compat fallback (memex looking for `.vault/` first then falling back to `context/`). Hard cut. Same posture as the `harness → memex` rename.
- **Not** adding new tests for the rename itself. The existing `memex-link/tests/run.sh` already covers the bash detector's correctness; renaming its fixture directory keeps that test green and is sufficient verification. Adding "the script handles .vault/" tests is YAGNI — the directory name appears as a literal in one place (`if [ ! -d context ]` → `if [ ! -d vault ]` and `find .vault/learnings .vault/conventions .vault/rules .vault/specs ...`).
- **Not** moving content of `context/.obsidian/` — those files are machine-local and `.gitignore`-d already; nothing to track-rename.

## Constraints

- **`git mv` for the directory rename** so history follows. `mv` + `git add` separately would orphan history per file; verify with `git log --follow` on a sample file after the rename.
- **Wikilinks of the form `[[../../learnings/...]]` are relative to the source file's parent directory and DO NOT change.** A spec at `.vault/specs/.../spec-X.md` referencing `[[../../learnings/Y]]` resolves to `.vault/learnings/Y.md` — same as before, modulo the parent rename. No wikilink edits needed for relative links.
- **Plain-text references to `context/` ARE all over the repo (430 occurrences across 48 files).** These are what the rename actually touches. Two big shipped specs hold ~113 of those occurrences and are frozen per Non-Goals.
- **`find-candidates.sh` has hardcoded directory walks**: `if [ ! -d context ]` and `find context/learnings context/conventions context/rules context/specs`. These flip to `.vault/`. The script's test fixtures at `.agents/skills/memex-link/tests/fixtures/context/` rename to `tests/fixtures/.vault/` to keep `tests/run.sh` green.
- **Scaffold copies must mirror canonical byte-for-byte** post-rename. Pattern established in prior specs.
- **`.gitignore`** has `context/.obsidian/` — flip to `.vault/.obsidian/`.
- **No other agent dirs** (`.codex/`, `.cursor/`, `.opencode/`) are installed in this repo, so cross-agent symlink updates are not in play.
- **CLAUDE.md is a symlink to AGENTS.md** — editing AGENTS.md propagates automatically.
- **Constitution is canon, not history** — flip every `context/` mention in `constitution.md` to `.vault/`. (Different posture from shipped specs because the constitution describes *current* repo conventions, not the past.)

## User Stories / Scenarios

1. **New contributor reading AGENTS.md** sees `.vault/learnings/`, `.vault/specs/`, `.vault/_index/` — the directory name and the role agree. No mental translation needed.
2. **Existing user re-running `/memex` on this repo** post-rename runs an audit that reports `.vault/` healthy, `context/` does not exist (it was renamed). No drift, no double-scaffolding.
3. **External user installing `npx skills add ribeirogab/agent-skills --skill memex` on a fresh repo** gets `.vault/` scaffolded (the new convention).
4. **Existing user with a downstream repo that ran the old memex (has `context/`)** runs the new `/memex`. The audit creates `.vault/` alongside the legacy `context/`. User decides: migrate manually (`git mv context/* .vault/ && rmdir context`), keep both, or revert the new `.vault/` install. **Documented in Non-Goals; not auto-handled.**
5. **Reader opens a shipped spec** like `.vault/specs/2026-05-03-rename-harness-to-memex/spec-rename-harness-to-memex.md`. The body still says `context/` because that was the directory name at ship time — preserved as historical record per Non-Goal #3. The spec's location (now under `.vault/`) is just structural.
6. **`/memex-link` smoke run** post-rename works — its `find-candidates.sh` walks `.vault/learnings`, `.vault/conventions`, etc., the test fixtures live under `.vault/` inside `tests/fixtures/`, and the script's bundled tests still PASS.

## Acceptance Criteria

- [x] `find . -type d -name 'context' -not -path './.git/*' -not -path './node_modules/*'` returns no results. Verified by running it.
- [x] `find . -type d -name 'vault' -not -path './.git/*' -not -path './node_modules/*'` returns exactly these three paths (in any order): `./vault`, `./.agents/skills/memex-link/tests/fixtures/vault`, `./skills/memex/scaffold/skills/memex-link/tests/fixtures/vault`. Verified by listing.
- [x] `git grep -l 'context/'` returns ONLY: (a) the three shipped spec folders' files (`.vault/specs/2026-04-30-opensource-readiness/*.md`, `.vault/specs/2026-05-03-rename-harness-to-memex/*.md`, `.vault/specs/2026-05-03-strengthen-vault-cross-links/*.md`), (b) the in-flight spec for THIS rename at `.vault/specs/2026-05-03-rename-context-to-vault/*.md` (intentional narrative — the spec is *about* the rename and references `context/` as a literal), and (c) any per-occurrence-reviewed survivors in mixed-context learnings. Each survivor in (c) is annotated in the commit message with a one-line justification.
- [x] `AGENTS.md`, `README.md`, `.vault/constitution.md` contain zero `context/` references. Verified by `grep -F 'context/' AGENTS.md README.md .vault/constitution.md` returning empty.
- [x] All `.vault/_index/`, `.vault/templates/`, `.vault/conventions/`, `.vault/rules/` files contain zero `context/` references. Verified by `grep -rF 'context/' .vault/_index/ .vault/templates/ .vault/conventions/ .vault/rules/` returning empty.
- [x] `bash .agents/skills/memex-link/tests/run.sh` exits 0 (PASS) — the script's fixture renaming and the script's directory references both flipped consistently.
- [x] `find-candidates.sh` (canonical and scaffold copies) walks `.vault/...` paths, not `context/...`. Verified by `grep -F '.vault/' .agents/skills/memex-link/scripts/find-candidates.sh` and the same for the scaffold copy returning matches; `grep -F 'context/' ...` returning nothing in both.
- [x] `skills/memex/SKILL.md` references `.vault/` in its install snippet (any documentation of what the scaffolder produces). Verified by reading.
- [x] `skills/memex/references/{audit-checklist,validation,vault-files,agents-md-template,constitution-template}.md` reference `.vault/` instead of `context/`. Verified by `grep -F 'context/' skills/memex/references/` returning empty.
- [x] `.claude/commands/memex-*.md` and `skills/memex/scaffold/commands/memex-*.md` reference `.vault/`. Verified by `grep -F 'context/' .claude/commands/memex-*.md skills/memex/scaffold/commands/memex-*.md` returning only references inside historical/literature contexts (none expected for this rename — the slash commands describe current behavior).
- [x] `.gitignore` has `.vault/.obsidian/`, not `context/.obsidian/`. Verified by `grep -E '^.vault/\.obsidian/?$' .gitignore`.
- [x] All `.agents/skills/memex-*/SKILL.md` (canonical) and scaffold copies reference `.vault/` not `context/`. Verified by `grep -rF 'context/' .agents/skills/memex-*/` and the scaffold equivalent returning empty.
- [x] Scaffold byte-equivalence post-rename: `diff -r .agents/skills/memex-link/ skills/memex/scaffold/skills/memex-link/` returns empty.
- [x] The 15 checks in `skills/memex/references/validation.md` PASS when run against this repo (`15/15 PASS`). Note: validation checks themselves now look at `.vault/` paths.
- [x] Branch is `feat/rename-context-to-vault`, not `main`. Verified by `git branch --show-current`.
- [x] Spec frontmatter has `status: shipped` and a non-null `shipped:` date once merged. (Self-referential — this spec moves to `.vault/specs/.../` and ticks itself.)

## Risks and Mitigations

| Risk | Mitigation |
|---|---|
| `git mv context vault` fails or leaves history orphaned | Use the directory-level `git mv` (single command). Verify with `git log --follow .vault/constitution.md` and confirm the history reaches before this branch. |
| Wikilinks `[[../../learnings/...]]` interpreted by Obsidian as broken because the parent directory renamed | They are relative to the source file's parent, not to the repo root. The relative path stays valid as long as internal structure under `.vault/` matches what was under `context/`. Sanity check: open Obsidian after rename, scan for unresolved wikilinks. (Manual.) |
| Plain-text mentions of `context/` survive in mixed-context learnings | Same per-occurrence rule as the harness/memex rename: `git grep -n 'context/' .vault/learnings/` and edit per match. Annotate survivors in commit message. |
| Shipped specs contain `context/` mentions in body — accidentally edited | Non-Goal #3 freezes them. Run a final `git grep -l 'context/' .vault/specs/2026-*` after rename and confirm only those three shipped spec folders remain (the new spec for THIS rename will also be in .vault/specs/.../ but its references to `context/` are intentional historical narrative). |
| `find-candidates.sh` paths flipped but fixtures forgotten — tests break | AC #6 enforces `tests/run.sh` PASS post-rename. Plan order: rename script paths AND fixture paths in the same task to keep tests green at every commit. |
| Scaffold copies drift after rename (canonical edited but scaffold not) | AC #13 uses `diff -r` to enforce byte-equivalence. Pattern from prior renames. |
| Downstream repos coexisting `context/` and `.vault/` | Documented in Non-Goals #4. No tooling support — manual user action. Add a one-line note to the README's "Use" section so the rename is discoverable. |
| Constitution mentions `context/` and is "canon" but the rename is happening *in this PR* — chicken-and-egg | The constitution gets edited in the same commit that renames the directory. Constitution's job is to describe *current* state; flipping it post-rename matches reality. |
| `git grep` baseline misses files because intuition was incomplete (per `[[../../learnings/rename-spec-grep-first]]`) | Run `git grep -l 'context/'` BEFORE writing scope and again BEFORE final commit to enforce zero unintended survivors. The acceptance criteria use grep directly. |
| `.obsidian/` JSON files reference `context/` somewhere | Those JSONs are gitignored and machine-local, but the values themselves shouldn't reference `context/`. Quick check: `grep -F 'context' .vault/.obsidian/*.json` post-rename. |

## Open Questions

None. Two key decisions raised in conversation were resolved (cross-version coexistence: hard cut; test fixtures: flip to `.vault/`; no new tests). Three minor decisions defaulted as recommended (specs shipped frozen, constitution flipped, wikilinks unchanged).
