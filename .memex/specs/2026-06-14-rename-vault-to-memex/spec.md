---
status: draft
feature: rename-vault-to-memex
created: 2026-06-14
shipped: null
branch: feat/rename-vault-to-memex
mode: autonomous
related:
  - "[[../2026-05-03-rename-context-to-vault/spec]]"
  - "[[../../learnings/rename-spec-grep-first]]"
  - "[[../../learnings/sed-rename-pattern-completeness]]"
  - "[[../../learnings/git-rm-leaves-gitignored-leftovers]]"
  - "[[../../learnings/vault-link-identity-is-basename-keyed]]"
---
# Rename `.vault/` to `.memex/` — Spec

**Status:** Draft
**Scope:** Rename the scaffolded knowledge-vault directory from `.vault/` to `.memex/` across this repo and across every artifact the `memex` skill installs into target repos. Hard cut — the renamed `memex` only knows `.memex/`. Directory and path references only; the conceptual term *vault* in prose and conceptual filenames are preserved.

## Context

`.vault/` is the directory the `memex` skill scaffolds in any repo to hold the knowledge vault: constitution, specs, learnings, conventions, rules, indices, templates. The previous rename (`context/` → `.vault/`, `[[../2026-05-03-rename-context-to-vault/spec]]`) aligned the directory name with the Obsidian-ecosystem term *vault*. This spec changes the directory name again — to `.memex/` — so the directory's name matches the **product** that owns it: a repo running memex stores its externalized memory in a `.memex/` directory, the same way a git repo stores its data in `.git/`.

This is a sibling-in-spirit to both prior vocabulary renames (`harness → memex`, `context → vault`): a deliberate naming change that makes the directory self-describing to a newcomer. The same precedent applies — `git mv` for history, frozen shipped specs, per-occurrence judgment in mixed-context notes, and `git grep` discipline before listing scope ([[../../learnings/rename-spec-grep-first]]).

One way this rename **differs** from its predecessor and shapes the whole approach: `context` and `vault` are distinctive tokens, so the predecessor could verify success by asserting *zero* surviving `context` mentions. The target token here — `memex` — is the product name and appears legitimately everywhere (`plugins/memex/`, `skills/memex/`, the marketplace, prose). Verification therefore anchors on the **dot-prefixed path token `.vault`**, never on the bare word `vault` or `memex`.

## Problem Statement

The directory at `.vault/` holds a repo's memex — its externalized, navigable project memory. But the name `.vault` names a generic Obsidian concept, not the tool that produces and governs the directory. A newcomer reading `AGENTS.md` sees `.vault/learnings/`, `.vault/specs/`, `.vault/constitution.md` and has to learn that "the vault" is what memex installs. Naming the directory `.memex/` removes the indirection: the directory announces which tool owns it, mirroring the `.git/` / `.github/` / `.obsidian/` convention of dot-directories named after their owning tool. The conceptual term *vault* survives in prose because it still accurately describes what the directory *is* (an Obsidian-style knowledge vault); only the directory's name changes.

## Non-Goals

- **Not** changing what's *inside* the directory. The structure (`learnings/`, `conventions/`, `rules.md`, `specs/`, `_index/`, `templates/`, `.obsidian/`) stays identical.
- **Not** changing how the memex audit/scaffold logic works internally. Pure rename of paths and string references. Same idempotency, same Phase 5 validation, same scaffolder shape.
- **Not** renaming the conceptual term *vault* in prose. "the knowledge vault", "Obsidian vault", "Project Knowledge Vault" stay. Only the directory name and `.vault/`-prefixed path references change.
- **Not** renaming conceptual filenames that contain the word *vault*: `skills/memex/references/vault-files.md`, `.vault/learnings/vault-link-identity-is-basename-keyed.md`, and spec folders such as `2026-05-03-rename-context-to-vault/` and `2026-05-03-strengthen-vault-cross-links/`. Their *contents* that reference the `.vault/` path flip; their names do not.
- **Not** rewriting historical spec records. Every shipped spec under `.vault/specs/` is frozen — its body references `.vault/` because that was the directory name at ship time. Touching them would rewrite history. (The structural move of the folders under the renamed parent is incidental, not a content edit.)
- **Not** updating downstream repos that already ran the old `memex` skill. **Hard cut** (confirmed): the new skill only knows `.memex/`. A downstream repo that previously scaffolded `.vault/` and then runs the renamed memex gets `.memex/` created *alongside* the legacy `.vault/`. Two parallel vaults until the user runs `git mv .vault/* .memex/ && rmdir .vault && /memex` to consolidate. Documented here; not auto-handled, no migration logic added to the skill.
- **Not** adding a back-compat fallback (memex looking for `.memex/` first then falling back to `.vault/`). Hard cut. Same posture as the `context → vault` rename.
- **Not** adding new tests for the rename itself. The existing `memex-link/tests/run.sh` already covers the bash detector; renaming its fixture directory keeps that test green and is sufficient verification.
- **Not** moving the content of `.vault/.obsidian/` — those files are machine-local and `.gitignore`-d; nothing to track-rename. (But the **old empty `.vault/` left behind by `git mv`** is handled — see Constraints.)

## Constraints

- **`git mv` for the directory rename** so history follows: `git mv .vault .memex`. Verify with `git log --follow .memex/constitution.md` reaching before this branch.
- **`git mv` leaves the gitignored `.obsidian/` behind** ([[../../learnings/git-rm-leaves-gitignored-leftovers]]). `git mv .vault .memex` moves only tracked files; the untracked, gitignored `.vault/.obsidian/` stays at the old path, leaving an orphan `.vault/` directory on disk. After the rename, explicitly remove the leftover (`rm -rf .vault`) — `.gitignore` now points at `.memex/.obsidian/`, so Obsidian recreates its config under the new path on next open. Verify `.vault/` no longer exists on disk.
- **Wikilinks of the form `[[../../learnings/...]]` are relative to the source file's parent directory and DO NOT change** ([[../../learnings/vault-link-identity-is-basename-keyed]]). A spec at `.memex/specs/.../spec.md` referencing `[[../../learnings/Y]]` resolves to `.memex/learnings/Y.md` — same as before, modulo the parent rename. No wikilink edits needed for relative links.
- **Verification anchors on the dot-path token, not the bare word.** Use `git grep -n '\.vault'` (dot + `vault`), never `grep -w vault` or `grep memex`. The bare word *vault* legitimately survives (conceptual term, conceptual filenames); the bare word *memex* is the product name and is everywhere. Only `.vault`-prefixed paths are in scope.
- **Plain-text references to `.vault/` are spread across the repo** (~721 occurrences across ~71 files at baseline). The state-describing files flip; the frozen shipped specs do not.
- **`find-candidates.sh` (3 copies) has hardcoded directory walks**: `if [ ! -d .vault ]`, the `FATAL: .vault/ not found...` message, `find .vault/learnings .vault/conventions .vault/rules .vault/specs`, and `grep -v '^.vault/specs/_template/'`. All flip to `.memex/`. The three copies are `.agents/skills/memex-link/scripts/`, `plugins/memex/skills/link/scripts/`, and `skills/memex/scaffold/skills/memex-link/scripts/`.
- **Test fixtures flip and must stay consistent with the script in the same commit.** `tests/fixtures/.vault/` (canonical + plugin copies) and `tests/fixtures/vault/` (scaffold copy) rename to `.memex/` / `memex`; `tests/expected-output.json` references the fixture path and flips too. Rename script paths and fixture paths together so `tests/run.sh` stays green at every commit.
- **Scaffold copies must mirror canonical byte-for-byte** post-rename: `diff -r .agents/skills/memex-link/ skills/memex/scaffold/skills/memex-link/` returns empty (and likewise the plugin copy under `plugins/memex/skills/link/`).
- **`.gitignore`** has `.vault/.obsidian/` — flip to `.memex/.obsidian/`.
- **No other agent dirs** (`.codex/`, `.cursor/`, `.opencode/`) are installed in this repo, so cross-agent symlink updates are not in play. The dogfood symlink `.claude/skills/memex` → `skills/memex/` is unaffected (it points at the skill source, not the vault).
- **CLAUDE.md is a symlink to AGENTS.md** — editing AGENTS.md propagates automatically.
- **Constitution and rules are canon, not history** — flip every `.vault/` mention in `.vault/constitution.md` and `.vault/rules.md` to `.memex/`. (Different posture from shipped specs because these describe *current* repo conventions.)
- **Learnings get per-occurrence judgment** ([[../../learnings/sed-rename-pattern-completeness]]): a `.vault/` that names the *current* vault structure flips; a `.vault/` that narrates the specific historical `context → vault` outcome may stay as historical record. Survivors annotated in the commit message.
- **MOC index files (`_index/specs.md`, `_index/learnings.md`) are current-state** and flip; they live at `.memex/_index/` post-rename.

## User Stories / Scenarios

1. **New contributor reading AGENTS.md** sees `.memex/learnings/`, `.memex/specs/`, `.memex/constitution.md` — the directory name announces the tool that owns it. No mental translation from "vault" to "what memex installs".
2. **Existing user re-running `/memex` on this repo** post-rename runs an audit that reports `.memex/` healthy and `.vault/` absent. No drift, no double-scaffolding.
3. **External user installing memex on a fresh repo** gets `.memex/` scaffolded (the new convention).
4. **Existing user with a downstream repo that ran the old memex (has `.vault/`)** runs the new `/memex`. The audit creates `.memex/` alongside the legacy `.vault/`. User decides: migrate manually (`git mv .vault/* .memex/ && rmdir .vault`), keep both, or revert. **Documented in Non-Goals; not auto-handled.**
5. **Reader opens a shipped spec** like `.memex/specs/2026-05-03-rename-context-to-vault/spec.md`. The body still says `.vault/` because that was the directory name at ship time — preserved as historical record. The spec's location (now under `.memex/`) is just structural.
6. **`/memex:link` smoke run** post-rename works — `find-candidates.sh` walks `.memex/learnings`, `.memex/conventions`, etc., the test fixtures live under `.memex/` inside `tests/fixtures/`, and the bundled `tests/run.sh` still PASSES across all three copies.

## Acceptance Criteria

- [ ] `find . -type d -name '.vault' -not -path './.git/*'` returns no results (the directory and all fixture copies are renamed). Verified by running it.
- [ ] `find . -type d -name '.memex' -not -path './.git/*'` returns exactly: `./.memex`, `./.agents/skills/memex-link/tests/fixtures/.memex`, `./plugins/memex/skills/link/tests/fixtures/.memex` (and the scaffold copy `./skills/memex/scaffold/skills/memex-link/tests/fixtures/memex`, no leading dot per the existing scaffold convention). Verified by listing.
- [ ] The scaffold copy's no-dot fixture is renamed: `test -d skills/memex/scaffold/skills/memex-link/tests/fixtures/memex && test ! -e skills/memex/scaffold/skills/memex-link/tests/fixtures/vault && echo OK`. (The `find -name '.memex'` check above silently skips this no-dot directory, so it gets its own check.)
- [ ] No `.vault/` directory remains on disk after the rename — the gitignored `.obsidian/` leftover is removed. Verified by `test ! -e .vault && echo OK`.
- [ ] `git grep -l '\.vault' | grep -v '^\.memex/specs/'` returns ONLY per-occurrence-reviewed learning survivors retained as historical narrative, each annotated in the commit message. (Concretely: `.memex/learnings/sed-rename-pattern-completeness.md`, whose `.vault/` mentions describe the *result* of the historical `context → .vault/` rename — flipping them to `.memex/` would state a falsehood, so they stay.) Every other `.vault` survivor is under `.memex/specs/`: frozen shipped specs (bodies reference the ship-time directory name) plus this rename spec's own intentional narrative (`.memex/specs/2026-06-14-rename-vault-to-memex/*`). Verified by running the command and confirming each survivor is either under `.memex/specs/` or an annotated historical-narrative learning.
- [ ] `AGENTS.md`, `README.md`, `.memex/constitution.md`, `.memex/rules.md` contain zero `.vault` references. Verified by `git grep -F '.vault' AGENTS.md README.md .memex/constitution.md .memex/rules.md` returning empty.
- [ ] All `.memex/_index/`, `.memex/templates/`, `.memex/conventions/` files contain zero `.vault` references. Verified by `git grep -F '.vault' .memex/_index/ .memex/templates/ .memex/conventions/` returning empty.
- [ ] `bash .agents/skills/memex-link/tests/run.sh` and `bash plugins/memex/skills/link/tests/run.sh` each exit 0 (PASS). The script's fixture rename and directory references flipped consistently. (The scaffold copy's `tests/run.sh` is **pre-existingly broken** at baseline — its fixture dir is `vault`/`memex` without a leading dot while the script looks for `.vault`/`.memex`, so it prints `FATAL: ... not found`. This rename preserves that exact behavior — it is **out of scope** to fix and must not regress further. Verified by confirming the scaffold copy's FATAL behavior is unchanged from baseline.)
- [ ] `find-candidates.sh` (all three copies) walks `.memex/...` paths and tests `-d .memex`, not `.vault`. Verified by `grep -F '.memex/' <each copy>` matching and `grep -F '.vault' <each copy>` returning nothing.
- [ ] `skills/memex/SKILL.md` references `.memex/` in its description of what the scaffolder produces. Verified by reading; `grep -F '.vault' skills/memex/SKILL.md` returns empty.
- [ ] `skills/memex/references/{audit-checklist,validation,vault-files,agents-md-template,constitution-template}.md` reference `.memex/` instead of `.vault/`. Verified by `git grep -F '.vault' skills/memex/references/` returning empty. (`vault-files.md` keeps its name; only its contents flip.)
- [ ] `plugins/memex/commands/*.md` and `.agents/skills/memex-*/SKILL.md` and `plugins/memex/skills/*/SKILL.md` reference `.memex/`. Verified by `git grep -F '.vault' plugins/memex/ .agents/skills/` returning empty.
- [ ] `.gitignore` contains `.memex/.obsidian/`, not `.vault/.obsidian/`. Verified by `grep -F '.memex/.obsidian/' .gitignore` matching and `grep -F '.vault' .gitignore` empty.
- [ ] `.github/PULL_REQUEST_TEMPLATE.md`, `SECURITY.md`, `CONTRIBUTING.md` contain zero `.vault` references. Verified by `git grep -F '.vault'` on those paths returning empty.
- [ ] The rename introduces **no new cross-copy divergence**. The three `memex-link` copies already differ at baseline (a pre-existing bare-filenames drift in the plugin copy's fixtures, and the scaffold copy's no-dot fixture name — both out of scope). Capture the baseline `diff -rq` file-name lists for `.agents` vs `plugins/link` (10 lines) and `.agents` vs `scaffold` (3 lines) **before** the rename; after the rename, the same `diff -rq` invocations produce file-name lists differing only where `.vault`/`vault` path tokens became `.memex`/`memex`. Verified by comparing the saved baseline lists to the post-rename lists. No copy that was identical to another at baseline becomes divergent.
- [ ] The validation checks in `skills/memex/references/validation.md` PASS when run against this repo, with the checks themselves now looking at `.memex/` paths.
- [ ] `git log --follow .memex/constitution.md` shows history reaching before this branch (the `git mv` preserved history).
- [ ] Branch is `feat/rename-vault-to-memex`, not `main`. Verified by `git branch --show-current`.
- [ ] Spec frontmatter has `status: shipped` and a non-null `shipped:` date once merged. (Self-referential — this spec moves under `.memex/specs/.../` and ticks itself.)

## Risks and Mitigations

| Risk | Mitigation |
|---|---|
| `git mv .vault .memex` fails or orphans history | Use the directory-level `git mv` (single command). Verify with `git log --follow .memex/constitution.md`. |
| `git mv` leaves an orphan `.vault/` holding the gitignored `.obsidian/` | Explicit `rm -rf .vault` after the move ([[../../learnings/git-rm-leaves-gitignored-leftovers]]); AC asserts `.vault/` absent on disk. |
| Verification greps the bare word and floods with false positives (`memex` is everywhere; `vault` is a kept conceptual term) | Anchor every grep on `\.vault` (dot-path). AC are written with `.vault`, never bare `vault`/`memex`. ([[../../learnings/rename-spec-grep-first]]) |
| A `.vault/` survives in a state-describing file | `git grep -l '\.vault'` before final commit; every survivor must be under `.memex/specs/`. Anything else is a miss to fix. |
| Frozen shipped spec accidentally edited | Restrict flips to non-spec paths; final `git grep -l '\.vault'` confirms only `.memex/specs/*` retain the token. |
| `find-candidates.sh` paths flipped but fixtures forgotten — tests break | Rename script paths AND fixture paths in the same task; AC enforces `tests/run.sh` PASS. ([[../../learnings/sed-rename-pattern-completeness]]) |
| Scaffold/plugin copies drift after rename | `diff -r` across the three copies in AC, accounting for the known `.memex` vs `memex` fixture-name difference. |
| `.obsidian/` JSON references `.vault` | Machine-local and gitignored, but check `grep -F '.vault' .memex/.obsidian/*.json` post-rename if present. |
| Downstream repos coexisting `.vault/` and `.memex/` | Documented in Non-Goals; manual user action. README "Use" note keeps it discoverable if one exists. |

## Open Questions

None. The three scope decisions (directory+paths only / conceptual term preserved, historical spec names preserved, spec flow) and the back-compat posture (hard cut) were resolved in conversation before the spec was written.
