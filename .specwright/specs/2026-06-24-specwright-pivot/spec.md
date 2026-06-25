---
status: shipped
feature: specwright-pivot
scope: complex
created: 2026-06-24
shipped: 2026-06-25
branch: feat/specwright
mode: autonomous
worktree: null
---
# specwright Pivot — Spec

**Status:** Draft
**Design:** design.md
**Scope:** Rename the skill to specwright/sw and strip it to a spec-driven-only workflow, removing the entire memory half and relocating all machinery into the skill.

This is the **technical** spec — the *how*. The non-technical *why* lives in `design.md`.

## Architecture

The skill ships in three mirrored locations that must stay in sync:

- **Canonical** — `.agents/skills/sw-<name>/` (what non-Claude agents read).
- **Plugin** — `plugins/sw/skills/<name>/` and `plugins/sw/commands/<cmd>.md` (the Claude Code plugin).
- **Scaffold** — `skills/sw/scaffold/skills/sw-<name>/` (what a fresh install copies into a target repo).

Plus the scaffolder skill itself at `skills/sw/` (invoked `/sw`), the marketplace manifest at `.claude-plugin/marketplace.json`, the per-project `install.sh`, and the root docs.

The pivot is four coordinated movements:

1. **Rename** — `memex`→`sw` for every technical identifier (plugin name, command namespace, skill directories, scaffolder), `memex`→`specwright` for the brand (vault directory `.specwright/`, marketplace name, README, prose). Claude derives the command namespace from the plugin name, so the plugin must be named `sw` to yield `/sw:spec`.
2. **Remove** — the memory half: the learnings flow and the `recall`/`link`/`sweep`/`learn` skills and commands; `rules.md`; `constitution.md`; `_index/` MOCs; `spec-driven-development.md`; the `specs.md` tracker; all Obsidian (`.obsidian/*.json`, `[[ ]]` wikilinks, `related:` frontmatter, the `.gitignore` line, the Obsidian/MOC validation checks); note templates; and the reflection step.
3. **Relocate** — machinery stops being scaffolded into target repos and travels inside the skill: the `validate-spec.sh` and update scripts; the spec templates; and the universal coding standard (Unix philosophy + meaningful-comments + basic security) baked into the `code-review` rubric. Project-specific standards stay in `conventions/`.
4. **Re-wire** — every surviving skill that cited `rules.md`/`constitution.md` re-points (universal standard → the baked-in `code-review` rubric; project standard → `conventions/`); `AGENTS.md` becomes self-contained (no guide reference, step 9 records status in spec frontmatter only).

Finally the repo re-hosts itself: `.memex/` is deleted and a fresh `.specwright/{conventions,specs}` is born with this spec as record #1.

A target repo, post-install, receives exactly `AGENTS.md` + `.specwright/{conventions,specs}`.

## File Structure

**Renamed (git mv, history preserved):**
- `skills/memex/` → `skills/sw/`
- `plugins/memex/` → `plugins/sw/`
- `.agents/skills/memex-<kept>/` → `.agents/skills/sw-<kept>/` for kept = brainstorming, writing-plans, new-pr, code-review, update (review-spec is a command, not a companion skill)
- `skills/sw/scaffold/skills/memex-<kept>/` → `skills/sw/scaffold/skills/sw-<kept>/`

**Deleted:**
- Companion skills `recall`, `link` in all three locations
- Commands `plugins/sw/commands/learn.md`, `plugins/sw/commands/sweep.md`
- `skills/sw/references/constitution-template.md`
- `skills/sw/scaffold/vault-docs/spec-driven-development.md`
- Scaffold note templates and `_index`/MOC scaffold assets
- This repo's `.memex/` (after carrying the pivot spec out)

**Created:**
- `skills/sw/scripts/validate-spec.sh` and `skills/sw/scripts/sw-update.sh` (relocated from scaffold vault-scripts)
- `skills/sw/scaffold/spec-templates/{spec.md,design.md,tasks.md}` (spec templates, no longer scaffolded into the vault)
- `.specwright/conventions/` (re-authored, no old-name references) and `.specwright/specs/2026-06-24-specwright-pivot/`

**Modified:**
- `plugins/sw/.claude-plugin/plugin.json` (`name: sw`), `.claude-plugin/marketplace.json` (marketplace `specwright`, plugin `sw`, source `./plugins/sw`), `.claude/settings.json` (`sw@specwright`)
- `install.sh` (repo, skill name, paths, command list)
- `skills/sw/SKILL.md`, `skills/sw/references/{vault-files.md,audit-checklist.md,validation.md,agents-md-template.md}`
- Every kept SKILL.md / command (drop rules/constitution/learnings/wikilink references) across the three copies
- `code-review` SKILL.md (bake in the universal rubric) across the three copies
- Root `AGENTS.md`, `CLAUDE.md` symlink target unchanged, `README.md`, `.gitignore`, `NOTICE.md`, `CONTRIBUTING.md`

## Phase Ordering

1. **Phase 1 — Rename the trees** (`git mv` skill/plugin/companion directories; update manifests, settings, install.sh).
2. **Phase 2 — Remove the memory half** (delete recall/link/sweep/learn, rules.md, constitution, _index, SDD guide, specs.md tracker, note templates; strip references in kept skills and AGENTS.md).
3. **Phase 3 — Remove Obsidian** (delete `.obsidian` scaffolding, wikilink convention, `related:` frontmatter, `.gitignore` line, Obsidian/MOC validation checks).
4. **Phase 4 — Relocate machinery** (scripts into the skill + re-wire callers; spec templates into the skill; bake universal standard into code-review).
5. **Phase 5 — Make AGENTS.md self-contained** (template + this repo's copy: self-contained flow, step 9 frontmatter-status, no removed references).
6. **Phase 6 — Re-brand root docs** (README, install.sh, NOTICE, CONTRIBUTING to specwright/sw).
7. **Phase 7 — Dogfood re-host** (delete `.memex/`, born-fresh `.specwright/`, carry the pivot spec in as record #1, re-author conventions).
8. **Phase 8 — Quality gate** (sync check, scaffolder validation, validate-spec.sh, grep guards).

Phases 1–6 edit product source; 7 re-hosts this repo; 8 verifies. Phase 2 and 3 overlap on shared files (vault-files.md, validation.md, AGENTS.md) and run in the listed order to avoid churn.

## Constraints

- **No migration, no alias, no old-name reference** anywhere in the product surface.
- **Markdown + shell only** — no build pipeline, no new language toolchain.
- **Three copies stay in sync** — a change to a kept companion skill lands identically in canonical, plugin, and scaffold copies.
- **No GitHub repo rename** inside this change; the code only assumes the new name.

## User Stories / Scenarios

1. A developer runs `install.sh` in a fresh repo, then `/sw`; the scaffolder writes `AGENTS.md` + `.specwright/{conventions,specs}` and enables the `sw` plugin — no learnings, no Obsidian, no `.specwright/scripts`.
2. A developer types `/sw:spec`; the spec flow runs to a PR and `code-review` to `lgtm`, with the universal coding standard enforced from the `code-review` rubric and project specifics from `conventions/`.
3. A maintainer greps the product surface for the old name and finds nothing.

## Acceptance Criteria

- [ ] **AC-1** `grep -ril 'memex' skills/sw plugins/sw .agents/skills AGENTS.md README.md install.sh .claude-plugin .gitignore .claude/settings.json` returns zero files.
- [ ] **AC-2** None of these paths exist: `plugins/sw/commands/learn.md`, `plugins/sw/commands/sweep.md`, `plugins/sw/skills/recall`, `plugins/sw/skills/link`, `.agents/skills/sw-recall`, `.agents/skills/sw-link`, `skills/sw/scaffold/skills/sw-recall`, `skills/sw/scaffold/skills/sw-link`.
- [ ] **AC-3** `grep -rIl -e 'constitution' -e 'spec-driven-development' -e '_index' -e 'rules\.md' skills/sw plugins/sw .agents/skills AGENTS.md` returns zero files.
- [ ] **AC-4** `grep -rIl '\.obsidian' skills/sw plugins/sw .agents/skills AGENTS.md` returns zero files; `grep -rIl --include='*.md' '\[\[' skills/sw plugins/sw .agents/skills AGENTS.md` returns zero files (the wikilink check is markdown-scoped — bash `[[ ]]` test syntax in `.sh` companion scripts is not a wikilink); and `grep -rIl '^related:' skills/sw/scaffold` returns zero files.
- [ ] **AC-5** `plugins/sw/.claude-plugin/plugin.json` has `"name": "sw"`; `.claude-plugin/marketplace.json` has marketplace `"name": "specwright"` and a plugin entry with `"name": "sw"` and `"source": "./plugins/sw"`; `.claude/settings.json` enables `"sw@specwright"`.
- [ ] **AC-6** The scaffolder (`skills/sw/SKILL.md` + `skills/sw/references/audit-checklist.md` + `skills/sw/references/validation.md`) names only `.specwright/conventions/` and `.specwright/specs/` as scaffolded vault directories — `grep -ril -e '\.specwright/learnings' -e '\.specwright/_index' -e '\.specwright/templates' -e '\.specwright/scripts' skills/sw` returns zero files.
- [ ] **AC-7** `skills/sw/scripts/validate-spec.sh` and `skills/sw/scripts/sw-update.sh` exist and are executable; `skills/sw/scaffold/vault-scripts/` no longer exists; the writing-plans and update SKILLs reference the `skills/sw/scripts/` path and no file instructs copying a script into `.specwright/scripts`.
- [ ] **AC-8** Each of the three `code-review` SKILL.md copies contains the strings `Modularity`, `Meaningful Comments`, and `secret` (the embedded universal rubric), and `grep -L -e 'constitution' -e 'rules\.md'` confirms none of them reference the removed law files.
- [ ] **AC-9** `AGENTS.md` contains the `### Spec flow` heading and the step-9 text `status: shipped`, and `grep -e 'spec-driven-development' -e 'constitution' -e 'rules\.md' -e 'specs\.md' -e 'Vault — read' AGENTS.md` returns zero matches.
- [ ] **AC-10** For every kept companion skill, `diff` between its canonical copy, its `plugins/sw/skills/<name>/SKILL.md`, and its `skills/sw/scaffold/skills/sw-<name>/SKILL.md` reports no differences **other than the frontmatter `name:` line** (canonical/scaffold use `sw-<name>`; the plugin copy uses the bare `<name>` so the `/sw:` namespace resolves).
- [ ] **AC-11** `.memex` does not exist; `.specwright/` contains exactly the entries `conventions` and `specs`; `.specwright/specs/2026-06-24-specwright-pivot/` contains `design.md`, `spec.md`, and `tasks.md`.
- [ ] **AC-12** `skills/sw/scripts/validate-spec.sh .specwright/specs/2026-06-24-specwright-pivot` exits 0, and the scaffolder validation routine (`skills/sw/scripts/quick_validate.py` or `references/validation.md` checks) reports no failures on this repo.
- [ ] **AC-13** `.gitignore` contains no `.memex` or `.obsidian` line, and `.claude/settings.json` contains no occurrence of the old plugin identifier.

## Risks and Mitigations

| Risk | Mitigation |
|---|---|
| A stray old-name reference survives in one of the three copies | AC-1 greps the whole product surface; the quality gate fails on any hit |
| The three copies drift during the rename | AC-10 diffs every trio; fix until zero diff |
| Re-wiring breaks a script-invocation path | AC-7 + AC-12 run the relocated scripts from their new path |
| Deleting `.memex/` loses spec history | git history retains everything; the pivot spec is carried into `.specwright/specs/` |

## Open Questions

None.
