---
status: shipped
feature: dedicate-repo-to-memex
created: 2026-06-13
shipped: 2026-06-13
related:
  - "[[../../learnings/claude-code-reserved-marketplace-names|claude-code-reserved-marketplace-names]]"
  - "[[../../learnings/claude-code-extra-known-marketplaces-source-schema|claude-code-extra-known-marketplaces-source-schema]]"
  - "[[../../learnings/rename-spec-grep-first|rename-spec-grep-first]]"
  - "[[../../learnings/sed-rename-pattern-completeness|sed-rename-pattern-completeness]]"
  - "[[../../learnings/vendoring-a-single-skill-loses-upstream-license|vendoring-a-single-skill-loses-upstream-license]]"
  - "[[../2026-05-03-rename-harness-to-memex/spec|rename-harness-to-memex]]"
  - "[[../2026-05-15-memex-claude-plugin-namespace/spec|memex-claude-plugin-namespace]]"
  - "[[../2026-04-30-opensource-readiness/spec|opensource-readiness]]"
  - "[[../../learnings/memex-marketplace-name-not-reserved|memex-marketplace-name-not-reserved]]"
  - "[[../../learnings/git-rm-leaves-gitignored-leftovers|git-rm-leaves-gitignored-leftovers]]"
---
# Dedicate Repo to Memex — Spec

**Status:** Shipped (2026-06-13)
**Scope:** Convert the repo from a personal *multi-skill library* (flagship `memex` + `skill-improver` + vendored references) into a *memex-only* repository: delete every non-memex skill, rename the project identity `agent-skills → memex` (repo slug, marketplace, titles, install commands, and all embedded references), relocate the skill-validation scripts into `memex` itself, and rewrite the constitution / docs / vault so nothing frames the repo as a collection of skills.

## Context

The repo was created as "the author's personal collection of Claude Code skills" that happens to flag `memex` as its flagship (see `.vault/constitution.md:11-15`). In practice the repo's whole value has converged on `memex` — the externalized project-memory scaffolder — plus its four bundled companion skills (`memex-brainstorming`, `memex-recall`, `memex-writing-plans`, `memex-link`). The "library of skills" framing now produces friction: a second published skill (`skill-improver`), two vendored maintainer-local skills (`skill-creator`, `opensource-guide-coach`), and an open door for new-skill PRs all dilute the project's identity and the constitution's scope.

The maintainer has decided to dedicate the repo exclusively to memex. This is an **identity change**, not a feature: the dominant work is deletion, renaming, and prose rewriting across ~30 files. A prior full rename (`harness → memex`, [[../2026-05-03-rename-harness-to-memex/spec|rename-harness-to-memex]]) is the playbook precedent for the mechanics (grep-first, `git mv`, symlink re-creation, validation gate).

## Problem Statement

Every top-level artifact frames the repo as a plural library: the `# agent-skills` titles, README's `## Skills` section listing two skills, CONTRIBUTING's "pull requests for the published skills" + "curated personal collection", the constitution's "be a usable library of skills" and "any future scaffolding skill", the marketplace identifier `ribeirogab-agent-skills`, and the install slug `ribeirogab/agent-skills`. A reader cannot tell that the repo *is* memex. The goal is that, after this change, the repo's name, every doc, the marketplace, the install command, and the vault all say one thing: this repository is memex.

## Decisions (settled before this spec)

1. **Memex-ONLY (radical).** Delete all non-memex skills. Close the door to new skills.
2. **Rename hard, no migration.** `agent-skills → memex` for the repo slug; marketplace `ribeirogab-agent-skills → memex` (bare, pending the Phase-0 reservation gate; fallback `ribeirogab-memex`). Already-installed downstream clients break — accepted.
3. **`skill-improver`: delete** (not extracted to its own repo).
4. **Validation scripts: vendor into memex.** Move `quick_validate.py` + `package_skill.py` into `skills/memex/scripts/` (they exist to keep memex's bundled companion skills honest = memex infrastructure).
5. **GitHub repo rename: maintainer executes.** The implementer updates every in-repo reference and prepares the exact command; the maintainer runs `gh repo rename memex` at the chosen moment.
6. **Vault learnings: delete the 6 skill-authoring-craft notes, keep the rename/infra gotchas.**
7. **`skill_request.md`: repurpose** into a memex feature/companion request template (not deleted).
8. **Borderline generic learnings (`harness-engineering-foundations`, `mechanical-enforcement-over-prose`): keep.**

## The marketplace-name gate (Phase 0)

`agent-skills` is a confirmed Claude-Code-reserved marketplace name (see [[../../learnings/claude-code-reserved-marketplace-names|claude-code-reserved-marketplace-names]]); the reservation fires at `claude plugin marketplace add` time, not at file-write time. The maintainer chose bare `memex` as the new marketplace name. Short generic names are exactly the class at risk of reservation, so the rename **must not cascade** until the name is install-tested.

**Phase 0 procedure:** set `.claude-plugin/marketplace.json` `name` to `memex` on the feature branch, run `claude plugin marketplace add .` (directory source), and observe:
- **No reservation error →** `memex` is the marketplace name. Proceed.
- **`The name 'memex' is reserved …` →** fall back to `ribeirogab-memex`. Proceed with the fallback name everywhere.

Whichever name survives Phase 0 is referred to below as **`<MKT>`**. The enabled-plugins key becomes `memex@<MKT>` (i.e. `memex@memex` or `memex@ribeirogab-memex`).

## Scope — the six workstreams

### A. Identity rename `agent-skills → memex`
- **Titles** → "memex": `README.md:1`, `AGENTS.md:1`, `.vault/constitution.md:5`, `.vault/_index/home.md:5`.
- **Install slug** `ribeirogab/agent-skills → ribeirogab/memex`: `README.md` install command(s); `skills/memex/SKILL.md:170` (`MARKETPLACE_SOURCE` `repo` field).
- **Marketplace name** `ribeirogab-agent-skills → <MKT>`: `.claude-plugin/marketplace.json:2`; `.claude/settings.json` (`extraKnownMarketplaces["<MKT>"]`, `enabledPlugins["memex@<MKT>"]`); `skills/memex/SKILL.md` dogfood detection (`:165-167` jq check) + merge recipe (`:182-183`) + lines `:114,:139`; `skills/memex/references/claude-plugin-settings.md:3-13`; `skills/memex/references/audit-checklist.md:60,83-84`; `skills/memex/references/validation.md:143,151-153`; `AGENTS.md:64`.
- **Git remote / GitHub:** maintainer runs `gh repo rename memex` (auto-updates `origin`). Implementer documents and verifies post-rename.
- **Untouched:** the plugin name stays `memex` (`plugins/memex/.claude-plugin/plugin.json:2`) → `/memex:*` commands and user muscle memory are preserved.

### B. Removals (memex-only)
- `skills/skill-improver/` + symlink `.claude/skills/skill-improver` → delete (after B→C script move).
- `evals/skill-improver/` → the only content under `evals/` → delete `evals/` entirely.
- `.claude/skills/skill-creator/` (vendored, Apache-2.0, real dir) → delete.
- `.claude/skills/opensource-guide-coach/` (vendored, MIT, real dir) → delete.

### C. Validation infrastructure relocation
- `git mv` the three files in `skills/skill-improver/scripts/` — `quick_validate.py`, `package_skill.py`, and the empty `__init__.py` — into `skills/memex/scripts/`, **before** deleting `skills/skill-improver/`. (`__init__.py` is moved for parity so both invocation modes keep working; `package_skill.py` already imports `quick_validate` via `sys.path.insert`, so path-based invocation works regardless.) `__pycache__/` is gitignored and not moved.
- `CONTRIBUTING.md:30-42` quality-bar commands repointed from `skills/skill-improver/scripts/` to `skills/memex/scripts/`; remove the "invoke the skill-improver skill" paragraph (skill no longer exists).
- `NOTICE.md`: keep only the Apache-2.0 attribution section, updated to the new path `skills/memex/scripts/{quick_validate,package_skill}.py`; delete the "Maintainer-local content under `.claude/skills/`" section (those dirs are gone).

### D. Docs pivot (multi-skill → memex)
- **README.md:** rewrite lead from "Reusable agent skills…" to a memex-focused description; delete the `## Skills` section + the `skill-improver` subsection; collapse the layout tree to a single skill; keep exactly one `npx skills add ribeirogab/memex --skill memex` command.
- **AGENTS.md:** rewrite the opening from "personal library of agent skills" to "this repository is memex". Keep the architecture rules (no build system, markdown + bash, self-contained) but reword "each skill / skills/<name>/" to "memex and its bundled companion skills".
- **CONTRIBUTING.md:** narrow scope to "memex and its bundled companions"; remove "any skill under `skills/`", "curated personal collection", and the "New unrelated top-level skills" door; repoint validation commands (see C).
- **SECURITY.md:** reword "Skills under `skills/`" (`:24,:34`) to memex.
- **`.github/ISSUE_TEMPLATE/skill_request.md`:** repurpose into a memex feature / companion-skill request template (rename file to `feature_request.md`; rewrite body to drop the "new top-level skill" framing).
- **`.github/PULL_REQUEST_TEMPLATE.md`:** three edits — (a) repoint the two Test-plan checkboxes (`:7-8`) that invoke `skills/skill-improver/scripts/{quick_validate,package_skill}.py` to `skills/memex/scripts/` (matching the script move in C); (b) delete the "`README.md`'s `## Skills` section was updated" checkbox (`:15`) entirely (not reword — there is no longer a `## Skills` section); (c) remove `evals/` from the out-of-scope dir list (`:17`) since the directory is deleted in B.
- **Untouched:** `LICENSE` (MIT), `CODE_OF_CONDUCT.md`.

### E. Constitution + vault rewrite
- **`.vault/constitution.md`:** rewrite "Why agent-skills exists" → "Why memex exists" (single-purpose). Rewrite "Scope guardrails": in-scope = memex + its bundled companions + the Claude Code distribution surface; drop the "any future scaffolding skill" assumption (`:28`) and the vendored-refs sentence naming `skill-creator`/`opensource-guide-coach` (`:21`, now deleted). Keep: no-build-pipeline, markdown-is-source-of-truth, idempotency, git-hygiene, no-attribution, project-artifacts-in-English.
- **`.vault/_index/home.md`:** title + framing → "memex — Project Knowledge Vault".
- **Delete 6 skill-authoring-craft notes** and their MOC entries:
  - learnings: `skill-development-workflow`, `skill-progressive-disclosure`, `skill-degrees-of-freedom`, `generator-evaluator-separation`
  - conventions: `skill-directory-layout`, `skill-md-style`
  - Update `.vault/_index/learnings.md` and `.vault/_index/conventions.md` to remove the dangling links; fix any `related:` wikilinks in surviving notes that pointed at the deleted ones.
- **Keep** rename/infra gotchas (`claude-code-reserved-marketplace-names`, `rename-spec-grep-first`, `sed-rename-pattern-completeness`, `bash-strict-mode-grep-filter`), memex-specific notes (`memex`, `claude-code-extra-known-marketplaces-source-schema`, `agents-md-as-map-not-encyclopedia`, `vendoring-a-single-skill-loses-upstream-license`), and the borderline generics (`harness-engineering-foundations`, `mechanical-enforcement-over-prose`).
- **Specs:** all historical specs preserved unchanged (constitution: specs never deleted).

### F. Final validation
- Re-run memex's own Phase-5 validation (`skills/memex/references/validation.md`) against this repo; all checks pass post-rename.

## Non-Goals

- **Not** renaming the `memex` plugin or any `/memex:*` slash command.
- **Not** providing a back-compat alias or migration for downstream repos that installed the old `ribeirogab-agent-skills` marketplace — hard cut (Decision 2).
- **Not** extracting `skill-improver` to another repo — it is deleted (Decision 3).
- **Not** rewriting historical spec records under `.vault/specs/` — their `agent-skills` / multi-skill references are frozen history.
- **Not** changing how memex works internally — its scaffold logic only changes where it embeds the marketplace name/slug.
- **Not** deleting `LICENSE`, `CODE_OF_CONDUCT.md`, or the surviving vault notes.

## Constraints

- **Phase 0 gates the cascade.** No marketplace-name substitution lands until the reservation test resolves `<MKT>` (see gate section). Mitigates shipping a broken install (precedent: [[../2026-05-03-rename-harness-to-memex/spec|the prior rename]] shipped a reserved name and had to be patched post-merge).
- The repo dogfoods its own scaffolder: `.agents/skills/` is canonical, `.claude/skills/*` are symlinks. `.claude/skills/` currently holds four entries: `memex` (symlink, **keep**), `skill-improver` (symlink, delete), `skill-creator` (real dir, delete), `opensource-guide-coach` (real dir, delete). The `memex` symlink already exists and is only preserved — not created. After the deletions, `.claude/skills/` must contain exactly the `memex` symlink, and it must resolve.
- `CLAUDE.md` is a symlink to `AGENTS.md`; editing `AGENTS.md` propagates. The symlink must survive (`test -L CLAUDE.md`).
- Use `git mv` / `git rm` for every move/delete so history follows (precedent risk table).
- The scripts being vendored carry Apache-2.0 attribution; moving them must preserve the NOTICE entry and the inline module-docstring note in `package_skill.py` ([[../../learnings/vendoring-a-single-skill-loses-upstream-license|vendoring footgun]]).
- No `package.json` / no test runner — validation is memex's manual Phase-5 checklist plus the grep-based acceptance criteria below.
- All committed artifacts in English; branch is `feat/dedicate-repo-to-memex`, never committed to `main`.

## User Stories / Scenarios

1. A new visitor opens the GitHub repo `ribeirogab/memex`, reads the README, and sees a single tool — memex — described as externalized project memory. No "## Skills" list, no second skill.
2. A user installs with `npx skills add ribeirogab/memex --skill memex` and it resolves.
3. A user runs `/memex` in a target repo; the scaffolder writes `extraKnownMarketplaces["<MKT>"]` + `enabledPlugins["memex@<MKT>"]`, and `claude plugin marketplace add` succeeds (Phase-0-verified name).
4. A contributor reads CONTRIBUTING and sees the scope is memex + its companions only; the validation commands point at `skills/memex/scripts/` and run clean.
5. A maintainer greps the repo for `agent-skills` and finds matches only in frozen historical specs and the reserved-names learning that documents the old name.

## Acceptance Criteria

- [ ] **Phase 0 recorded:** `.claude-plugin/marketplace.json` `name` is either `memex` (reservation test passed) or `ribeirogab-memex` (fallback), and the closing PR description states which and quotes the `claude plugin marketplace add .` result.
- [ ] **No active `agent-skills` survivors:** `grep -rIn "agent-skills" --exclude-dir=.git .` returns matches **only** in (a) `.vault/specs/` historical spec folders, (b) the two frozen historical gotcha-narrative learnings that quote the old name verbatim — `.vault/learnings/claude-code-reserved-marketplace-names.md` and `.vault/learnings/claude-code-extra-known-marketplaces-source-schema.md`, (c) the MOC entries in `.vault/_index/` that describe those two learnings or the historical shipped specs, and (d) this spec's own folder. Zero matches in `README.md`, `AGENTS.md`, `SECURITY.md`, `CONTRIBUTING.md`, `NOTICE.md`, `.vault/constitution.md`, `.claude/`, `.claude-plugin/`, `plugins/`, `skills/`.
- [ ] **Marketplace name fully cascaded:** `grep -rIn "ribeirogab-agent-skills" --exclude-dir=.git .` returns matches only in historical specs and the reserved-names learning. `.claude/settings.json` contains `enabledPlugins["memex@<MKT>"]` and `extraKnownMarketplaces["<MKT>"]` with matching keys, and `skills/memex/SKILL.md` dogfood detection compares against `<MKT>`.
- [ ] **Install slug cascaded:** `grep -rIn "ribeirogab/agent-skills" --exclude-dir=.git .` returns matches only in historical specs. `README.md` and `skills/memex/SKILL.md` use `ribeirogab/memex`.
- [ ] **skill-improver gone:** `skills/skill-improver/`, `.claude/skills/skill-improver`, and `evals/` do not exist. `find . -path ./.git -prune -o -name '*skill-improver*' -print` returns only historical-spec content references (no live files/dirs).
- [ ] **Vendored refs gone:** `.claude/skills/skill-creator/` and `.claude/skills/opensource-guide-coach/` do not exist.
- [ ] **`.claude/skills/` is memex-only and resolves:** `ls .claude/skills/` prints exactly `memex`, and `for f in .claude/skills/*; do [ -e "$f" ] || echo BROKEN $f; done` prints nothing.
- [ ] **Scripts relocated + runnable:** `skills/memex/scripts/quick_validate.py` and `skills/memex/scripts/package_skill.py` exist; `python skills/memex/scripts/quick_validate.py skills/memex` prints `Skill is valid!`; `git log --follow --oneline skills/memex/scripts/quick_validate.py` shows pre-move history.
- [ ] **NOTICE.md correct:** contains the Apache-2.0 section pointing to `skills/memex/scripts/`, and contains no "Maintainer-local content under `.claude/skills/`" section. `grep -c "opensource-guide-coach" NOTICE.md` returns 0.
- [ ] **README is memex-only:** `grep -c "^## Skills" README.md` returns 0; the file contains no `skill-improver` mention; exactly one `npx skills add` command, using `ribeirogab/memex`.
- [ ] **CONTRIBUTING is memex-only:** no occurrence of "curated personal collection" or "any skill under"; validation command block references `skills/memex/scripts/` and not `skills/skill-improver/`.
- [ ] **Constitution rewritten:** `grep -c "library of skills" .vault/constitution.md` and `grep -c "any future scaffolding skill" .vault/constitution.md` both return 0; the "Why" section names memex as the repository's singular purpose; the no-build / markdown / idempotency / git-hygiene / no-attribution principles are still present.
- [ ] **6 craft notes deleted + indexes clean:** the four learnings and two conventions listed in scope E do not exist; `.vault/_index/learnings.md` and `.vault/_index/conventions.md` contain no links to them; `grep -rIn "skill-progressive-disclosure\|skill-degrees-of-freedom\|skill-development-workflow\|generator-evaluator-separation\|skill-directory-layout\|skill-md-style" .vault --include='*.md'` returns no matches outside historical specs.
- [ ] **`.github` updated:** no file named `skill_request.md` remains (repurposed/renamed); `.github/PULL_REQUEST_TEMPLATE.md` has no "## Skills section" checkbox; `grep -rIn "skill-improver\|skills/skill-improver" .github/` returns zero matches (Test-plan script paths repointed to `skills/memex/scripts/`); `grep -c "evals/" .github/PULL_REQUEST_TEMPLATE.md` returns 0.
- [ ] **CLAUDE.md symlink intact:** `test -L CLAUDE.md && [ "$(readlink CLAUDE.md)" = "AGENTS.md" ]` succeeds.
- [ ] **memex Phase-5 validation passes** against this repo (all checks in `skills/memex/references/validation.md`).
- [ ] **GitHub rename done:** `git remote get-url origin` resolves to `…ribeirogab/memex…` (after the maintainer runs `gh repo rename memex`).
- [ ] **Branch + status:** work is on `feat/dedicate-repo-to-memex` (not `main`); after merge the spec frontmatter is `status: shipped` with a non-null `shipped:` date.
- [ ] **Reflection:** a reflection learning note exists, or the closing PR description states "No new learnings from this spec" (per the after-completing-a-spec rule).

## Risks and Mitigations

| Risk | Mitigation |
|---|---|
| Bare `memex` marketplace name is reserved → broken install ships | Phase 0 gate: install-test before any cascade; auto-fallback to `ribeirogab-memex`. AC #1 records the outcome. |
| Cascade misses an embedded marketplace/slug reference (the name lives in 6+ memex internal files) | Grep-first per [[../../learnings/rename-spec-grep-first|rename-spec-grep-first]]; AC #2–#4 are repo-wide greps that fail on any survivor. Enumerate allowed survivors (historical specs + reserved-names learning) explicitly. |
| `git mv` history lost on the script move or skill deletions | Use `git mv`/`git rm` per file; AC #7 verifies `git log --follow` on a moved script. |
| Deleting `skill-improver` before moving its scripts loses the scripts | Sequence is fixed: C (move) precedes B (delete). Plan tasks must order the move first. |
| Vendored scripts lose Apache-2.0 attribution after the move | NOTICE Apache-2.0 section updated to the new path; `package_skill.py` docstring note preserved ([[../../learnings/vendoring-a-single-skill-loses-upstream-license|footgun]]). AC #8. |
| `.claude/skills/` left with a broken or extra entry after deletions | AC #6 asserts exactly `memex` and that it resolves. |
| `CLAUDE.md` symlink turned into a regular file while editing AGENTS.md | AC #14 checks `test -L`. |
| Renaming the GitHub repo breaks `npx skills` for downstream users | Accepted hard cut (Decision 2). GitHub redirect covers `git clone`; the README slug is updated to the new canonical path. |
| Deleting the rename-playbook learnings would remove the very notes this task relies on | Decision 6 keeps `rename-spec-grep-first`, `sed-rename-pattern-completeness`, `claude-code-reserved-marketplace-names`, `bash-strict-mode-grep-filter`. |
| A `/memex:*` command invoked mid-rename reads half-updated settings | Don't invoke any `/memex:*` slash command during the rename window; use raw shell + Edit. |

## Open Questions

None. All sub-decisions settled in the brainstorming dialogue prior to writing this spec (see Decisions section).
