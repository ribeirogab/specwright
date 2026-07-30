---
feature: opencode-host-support
created: 2026-07-29
scope: high
branch: feat/opencode-host-support
worktree: null
delivery: null
---
# OpenCode Host Support — Spec

**Change:** see the sibling `change.md` (the *why*, the acceptance criteria, and the change `status:`)
**Scope:** Add OpenCode as a third thin host adapter — 4 agent templates, 9 command templates, a generalized tri-host deterministic updater with migration from 2026.7.29, tri-host docs, and dogfooding on this repository.

> **Note on `scope:` frontmatter** — `scope` is one of `low | medium | high | complex`. It is **recorded only**: reserved for a future quick-mode and does **not** yet gate which artifacts are written. Set it honestly; nothing branches on it today.
>
> **Note on `worktree:` frontmatter** — the path of this change's git worktree under `.specwright/worktrees/`, or `null` when the work runs in place. **Recorded only**, like `scope:`.
>
> **Note on `delivery:` frontmatter** — the delivery folder this change belongs to, or `null` for a standalone change. Membership is data, not directory nesting: every change lives flat under `.specwright/changes/`.

This is the **technical** spec — the *how*. The non-technical *why*, the acceptance criteria, and the status live in `change.md`.

## Architecture

specwright's invariant is "the nine skills are the single implementation; hosts are thin adapters." OpenCode (a) reads `AGENTS.md` natively, (b) loads `SKILL.md` files in the exact format this repo ships via `skills.paths` in `opencode.json`, (c) derives commands from `.opencode/command/<name>.md` filenames (`/<name>`), and (d) defines subagents in `.opencode/agent/<name>.md` with `mode`/`permission` frontmatter. Points (c) and (d) have no path-indirection — the files must live inside the consumer project, exactly like the Codex `.codex/agents/sw-*.toml` profiles. The architecture therefore extends the existing Codex mechanism rather than inventing a new one:

1. **Two new template sets ship in the plugin package**: `templates/opencode-agents/` (4 role manifests) and `templates/opencode-commands/` (9 thin redirects, `sw-*.md` — hyphens, since OpenCode command names come from filenames and colons are filesystem-hostile). They are the single source of truth, byte-matched into consumer projects by the updater.
2. **`sw_update.py` generalizes from one hardcoded profile set to three managed template sets** — `(destination dir, template dir, names)`: the existing Codex set plus the two OpenCode sets. Every per-set site (`_observe_paths`, `_classify`, `_is_up_to_date`, `_managed_update_desired`, `_operations`, `_validate_profile_source`, `_apply_operation`) iterates `MANAGED_TEMPLATE_SETS` instead of `PROFILE_DIRECTORY`/`PROFILE_NAMES`. A single `_template_source(relative_path)` helper resolves a managed destination to its installed template. Everything else — plan identity, `--expect-plan`, preflight, atomic writes, symlink probe, drift refusal — is untouched.
3. **Migration from 2026.7.29 is a first-class path, not an accident**: the managed block template changes (third command surface) and 13 new managed files appear, so both manifests bump to `2026.7.30` and `KNOWN_PROFILE_DIGESTS_BY_VERSION` gains the four real 2026.7.29 TOML digests. A 2026.7.29 project then classifies `legacy-migratable` and receives: block replacement, the 13 creates, and (local mode) two new ignore rules. A project where any `.opencode` managed destination exists with non-template content classifies `drifted` — the updater never overwrites an unrecognized file.
4. **Distribution is documentation, not code**: the consumer clones the repo (same checkout Claude/Codex use) and points `skills.paths` at `plugins/sw/skills` in their `opencode.json`. No npm package, no TS plugin, no build pipeline (rejected alternative B). OpenCode agent templates deliberately omit `model:` (multi-provider host; inherits the session model) and map the Codex `read-only` sandbox to `permission: { edit: deny }` on the two reviewer roles.

Rejected alternatives: (B) npm TS plugin injecting config via the `config` hook — adds a build/publish pipeline and TS/markdown drift to a markdown+shell+python repo; (C) skills-only — loses explicit `/sw-*` surfaces and the permission-restricted roles the owner/worker/reviewer protocol depends on.

## File Structure

**Created — templates (T1, T2):**

- `plugins/sw/templates/opencode-agents/sw-change-owner.md` — owner role; body ported from `plugins/sw/agents/change-owner.md`, first line becomes a `plan`-skill load instruction.
- `plugins/sw/templates/opencode-agents/sw-task-worker.md` — worker role; body ported from `plugins/sw/agents/task-worker.md`.
- `plugins/sw/templates/opencode-agents/sw-reviewer.md` — review lane; `permission: edit: deny`; body ported from `plugins/sw/agents/reviewer.md`, preload mention becomes a `review`-skill load instruction.
- `plugins/sw/templates/opencode-agents/sw-spec-document-reviewer.md` — spec gate reviewer; `permission: edit: deny`; body ported from `plugins/sw/agents/spec-document-reviewer.md`.
- `plugins/sw/templates/opencode-commands/sw-{init,brainstorm,spec,plan,run,review,review-spec,pr,update}.md` — nine pure redirects naming their skill's `skills/<name>/SKILL.md` path and passing `$ARGUMENTS`.

**Modified — engine + package (T3):**

- `plugins/sw/scripts/sw_update.py` — tri-host managed sets, `_template_source`, extended ignore rules, 2026.7.29 known digests, OpenCode drift guard in `_managed_update_desired`.
- `plugins/sw/.codex-plugin/plugin.json`, `plugins/sw/.claude-plugin/plugin.json` — version `2026.7.30`.
- `plugins/sw/references/agents-md-template.md` — managed block gains the OpenCode command-surface sentence.
- `tests/install/run.sh` — `assert_opencode_files`, init expectations, up-to-date fixture setup, OpenCode drift case, extended local ignore-rule expectation, retriangulated operation counts.
- `tests/install/fixtures/update/up-to-date/AGENTS.md`, `tests/update/fixtures/up-to-date/AGENTS.md` — re-rendered to the 2026.7.30 managed block (otherwise they would classify `legacy-migratable`).
- `tests/update/test_plan.py` — updated expectations plus OpenCode install/drift/up-to-date cases.

**Modified — docs (T4):**

- `plugins/sw/skills/{init,update,brainstorm,plan,run}/SKILL.md` — tri-host surfaces, triggers, required-files lists, run's local-mode copy set, handoff blocks; sweep of `{spec,review,review-spec,pr}/SKILL.md` for dual-host-only phrasing; `brainstorm/visual-companion.md` gains an OpenCode-unverified note.
- `plugins/sw/commands/{init,update}.md` — descriptions neutralized to match the OpenCode templates.
- `plugins/sw/references/{validation.md,vault-files.md,audit-checklist.md}` — 13-file inventory and mode rules.
- `README.md` — OpenCode install subsection, parity-table column, updater-owns list, trees, role table, skill-name caveat.
- `CONTRIBUTING.md` — generated-files rule extended to `.opencode/`, scope wording.
- `.specwright/conventions/skill-validation-requirements.md` — amended to tri-host surfaces so review lane A does not enforce stale "both valid surfaces" wording against the new skill text.

**Created — dogfood (T5):**

- `.opencode/agent/sw-*.md`, `.opencode/command/sw-*.md` (updater-generated), `AGENTS.md` managed-block migration — all tracked (shared mode).

## Phase Ordering

1. **Templates** (T1 ∥ T2, file-disjoint) — the byte-targets everything else matches.
2. **Engine + tests** (T3, depends on T1+T2) — updater, manifests, block template, suites; CONTRIBUTING rule: templates and migration tests land together.
3. **Docs** (T4, depends on T3) — documents final, tested behavior.
4. **Dogfood + gates** (T5, inline owner) — migrate this repo, full validation matrix, runtime verification of every AC.

## Constraints

- Python stdlib only in the updater; no new dependencies anywhere.
- OpenCode template frontmatter uses only documented keys (`description`, `mode`, `permission`); unknown keys are silently routed into `options` by OpenCode — none may appear.
- Templates must be host-neutral in body: no `${CLAUDE_PLUGIN_ROOT}`, no `$sw:` surfaces; commands reference skills by name and plugin-relative `skills/<name>/SKILL.md` path.
- Do not weaken plan identity, digest checking, preflight, atomic writes, or the drift refusal (CONTRIBUTING rule 7).
- Test integrity: the install/update suites' assertions are extended, never weakened; existing cases keep passing.
- This session predates the OpenCode roles it creates: isolated tasks are dispatched to generic subagents carrying the full `sw-task-worker` payload contract (dispatch inputs, authority boundary, return contract). The substitution is recorded in the PR body.
- Conventional Commits; no AI attribution anywhere.

## User Stories / Scenarios

1. **Consumer, fresh project** — clones specwright, adds `{"skills": {"paths": ["<checkout>/plugins/sw/skills"]}}` to `opencode.json`, runs `/sw-init` in their repo, confirms the plan, and gets the vault plus 13 tracked `.opencode/` files; `/sw-plan` and the `sw-task-worker` subagent are immediately available.
2. **Existing dual-host user updates the plugin** — their 2026.7.29 project runs `/sw-update`; the plan classifies `legacy-migratable`, shows the block replacement plus 13 creates, and applies byte-exactly after confirmation. A hand-edited `.opencode/agent/sw-reviewer.md` instead yields `drifted` and zero writes.
3. **Maintainer dogfoods** — this repository migrates itself to 2026.7.30, tracks its own `.opencode/` files, and an OpenCode session in this checkout discovers the nine `/sw-*` commands and four `sw-*` agents.

## Acceptance Criteria

The acceptance criteria live in the sibling `change.md` — the `AC-N` IDs defined there are the contract `tasks.md` references and ```sw:review``` walks. Do not duplicate them here; if writing this spec exposed a missing or wrong criterion, fix `change.md`.

## Risks and Mitigations

| Risk | Mitigation |
|---|---|
| Adding 13 observed paths changes every `plan_id`; a 2026.7.29 project without a migration path would classify `drifted` forever | Bump both manifests to `2026.7.30` in the same change and record the real 2026.7.29 TOML digests in `KNOWN_PROFILE_DIGESTS_BY_VERSION`; T3's tests prove `legacy-migratable` → `up-to-date` byte-exactly |
| OpenCode does not namespace skills loaded via `skills.paths`; generic names (`plan`, `run`, `review`) can collide with a user's other skills | Documented caveat in README (Non-Goal: no frontmatter rename in this change); command templates name the plugin-relative skill path so the loader's target is unambiguous |
| Same-day version bump (`2026.7.29` → `2026.7.30`) stamps tomorrow's date | Calendar versions are release stamps, not wall-clock assertions; both manifests bump together and the release smoke test enforces they match |
| AC-9's "real OpenCode session discovers" may not be verifiable headlessly | Attempt `opencode run` discovery output; if the CLI cannot expose it, mark the criterion `needs-human-verification` with the reason — never silently tick |
| Stray hand-made `.opencode/agent/sw-*.md` in a consumer project blocks init with `drifted` | By design (no overwrite of unrecognized files); the diagnostic names the managed paths, and removal restores the `new` classification |

## Open Questions

None.
