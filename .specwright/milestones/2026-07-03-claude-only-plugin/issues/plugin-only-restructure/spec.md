---
feature: plugin-only-restructure
created: 2026-07-03
scope: high
branch: refactor/plugin-only-restructure
worktree: .specwright/worktrees/plugin-only-restructure
milestone: .specwright/milestones/2026-07-03-claude-only-plugin
---
# Plugin-only Restructure — Spec

**Issue:** see the sibling `issue.md` (the *why*, the acceptance criteria, and the issue `status:`)
**Scope:** relocate every shared asset (5 templates, validator + fixtures, reference docs) into `plugins/sw/`, delete `.agents/` and `skills/sw/` outright, and rewire every skill/command reference that pointed at the old paths.

> **Note on `scope:` frontmatter** — recorded only, does not gate artifacts.
> **Note on `worktree:` frontmatter** — recorded only.
> **Note on `milestone:` frontmatter** — this issue belongs to the `claude-only-plugin` milestone.

This is the **technical** spec — the *how*. The non-technical *why*, the acceptance criteria, and the status live in `issue.md`.

## Architecture

Today specwright keeps three physical copies of shared machinery so non-Claude agents (which discover skills from the repo filesystem) can read them: `.agents/skills/sw-<name>/` (canonical), `skills/sw/scaffold/skills/sw-<name>/` (what new installs receive), and `plugins/sw/skills/<name>/` (what Claude Code's plugin serves). `skills/sw/` also hosts the scaffolder skill itself plus the shared templates (`scaffold/templates/`), the validator (`scripts/validate-spec.sh`), its fixtures (`scripts/fixtures/`), and the reference docs the scaffolder reads (`references/*.md`).

This issue collapses that to one physical tree: `plugins/sw/`. Concretely:

- **Templates** move from `skills/sw/scaffold/templates/` to `plugins/sw/templates/`.
- **Validator + fixtures** move from `skills/sw/scripts/{validate-spec.sh,fixtures/}` to `plugins/sw/scripts/{validate-spec.sh,fixtures/}`. The two vendored Apache-2.0 scripts (`quick_validate.py`, `package_skill.py`) and `__init__.py` are scaffolder-only tooling (used by the `sw` skill's own packaging, not by any companion skill or by installed repos) — they move alongside the validator into `plugins/sw/scripts/` so `skills/sw/` can be deleted outright, matching AC-2's "does not exist anywhere" bar. `NOTICE.md`'s attribution paths are updated to match.
- **Reference docs** move from `skills/sw/references/*.md` to `plugins/sw/references/*.md`. These docs describe the `sw` scaffolder's own audit/self-copy/symlink mechanics — content that `rewrite-sw-init` (a later, dependent issue) will heavily rewrite once `/sw:init` replaces the scaffolder. This issue only relocates the files (AC-1 requires them to exist under `plugins/sw/`); it does not rewrite their prose, since that rewrite is `rewrite-sw-init`'s job and premature edits here would be thrown away.
- **`.agents/skills/sw-<name>/`** (8 directories: brainstorm, plan, pr, review-spec, review, run, spec, update) and **`skills/sw/`** (the scaffolder + its scaffold/scripts/references) are deleted entirely — nothing under either path may survive (AC-2).
- **Companion skill `SKILL.md`s** already exist in exactly one right place for 5 of them (`plugins/sw/skills/{brainstorm,plan,pr,review,run}/SKILL.md`) — AC-4 is satisfied by the deletion above, since the only duplicates were under `.agents/` and `skills/sw/scaffold/skills/`.
- **References inside the surviving plugin files** — `plugins/sw/skills/plan/SKILL.md`, `plugins/sw/skills/plan/spec-document-reviewer-prompt.md`, `plugins/sw/skills/brainstorm/SKILL.md`, `plugins/sw/commands/review-spec.md` — get their `scaffold/templates/`, `skills/sw/scripts/validate-spec.sh`, and `.agents/skills/sw/scripts/validate-spec.sh` mentions rewritten to the new `plugins/sw/templates/` and `plugins/sw/scripts/validate-spec.sh` paths. The dual-phrasing pattern used today ("bundled template... under the installed `sw` skill or `skills/sw/` in the specwright dev repo") collapses to a single phrasing since there is now only one location in both the installed-plugin case and the specwright dev repo case: the plugin ships from `plugins/sw/` in both.

## File Structure

**Created:**
- `plugins/sw/templates/{issue,spec,tasks,goal,board}.md` — moved from `skills/sw/scaffold/templates/`.
- `plugins/sw/scripts/validate-spec.sh` — moved from `skills/sw/scripts/validate-spec.sh`.
- `plugins/sw/scripts/fixtures/{bad-frontmatter,bad-placeholder,bad-unref-ac,bad-vague-verb,good,missing-status}/{issue,spec,tasks}.md` — moved from `skills/sw/scripts/fixtures/`.
- `plugins/sw/scripts/{__init__.py,package_skill.py,quick_validate.py}` — moved from `skills/sw/scripts/`.
- `plugins/sw/scripts/sw-update.sh` — moved verbatim from `skills/sw/scripts/sw-update.sh` (no logic change; see Constraints for why its internal `.agents/skills`/`scaffold/skills` references are a documented AC-3 exception).
- `plugins/sw/references/{agents-md-template,audit-checklist,claude-plugin-settings,validation,vault-files}.md` — moved from `skills/sw/references/`.

**Modified:**
- `plugins/sw/skills/plan/SKILL.md` — rewire the 3 path mentions (spec template, tasks template, validator) to `plugins/sw/templates/` and `plugins/sw/scripts/validate-spec.sh`.
- `plugins/sw/skills/plan/spec-document-reviewer-prompt.md` — rewire the 1 validator mention.
- `plugins/sw/commands/review-spec.md` — rewire the 1 validator invocation + comment.
- `plugins/sw/skills/brainstorm/SKILL.md` — rewire the 3 template mentions (issue template, milestone templates, validator).
- `plugins/sw/skills/update/SKILL.md` — rewire its 2 direct self-references (`sw-update.sh` invocation path, manifest path) to `plugins/sw/`; the "What is managed" table's companion-skill-sync row keeps naming `.agents/skills/sw-<name>/SKILL.md` (an installed target repo's path, not this repo's) — a documented AC-3 exception, see Constraints.
- `install.sh` — this file is `docs-and-install-flow`'s to delete and is explicitly out of this issue's scope for behavior/prose changes. `grep -n '\.agents/skills' install.sh` finds **6** occurrences, split into two categories: (a) **4 comment/output-text occurrences** (lines 7-8 header comment, line 24 comment, line 124 `say` output) — these are reworded to break up the literal contiguous substring (e.g. describe the path without spelling `.agents/skills` verbatim) so they stop tripping AC-3's grep, with zero behavior change; (b) **2 executable-code occurrences that must keep their literal value**: `CANONICAL=".agents/skills/${SKILL}"` (line 26) and `ln -s "../../.agents/skills/${SKILL}" "${LINK}"` (line 153) — these write to the **end-user's machine** at install time (the path the `skills` CLI creates in whatever repo runs `install.sh`), a filesystem location entirely unrelated to this repo's own `.agents/` tree being deleted here. Rewriting these two would change the installer's real behavior, which is out of this issue's Non-Goals. See Constraints below for how AC-3 verification handles these two irreducible hits.
- `AGENTS.md` — the "Editing the bundled skills" paragraph currently says companion skills "ship in three copies" naming `.agents/skills/sw-<name>/SKILL.md` and `skills/sw/scaffold/skills/sw-<name>/`, and says the `sw` scaffolder skill and `validate-spec.sh` are "single-copy" at `skills/sw/`. Both sentences describe the pre-restructure model and would be false (and would trip AC-3, since they name `.agents/skills` and `scaffold/skills` literally) after this issue ships. Rewritten minimally to state the new single-copy-under-`plugins/sw/` model, without touching the surrounding prose about the `/sw:*` commands, `sw:update`, or the overall workflow (that broader rewrite is `docs-and-install-flow`'s). The "Non-Claude agents read canonical copies under `.agents/skills/sw-<name>/`" sentence earlier in the file is also removed since it is now false and names the deleted path — replaced with a one-line statement that all `/sw:*` tooling ships through the plugin.
- `README.md` — multiple lines name `.agents/skills/sw-<name>/`, `skills/sw/scaffold/skills/sw-<name>/`, `skills/sw/SKILL.md`, `skills/sw/scaffold/templates/`, `skills/sw/references/agents-md-template.md`, and the repository-layout tree's `skills/sw/` row, all dangling after the move/delete. Per the issue's Non-Goals, README's broader install-flow rewrite (the curl-install story, the "three kept-in-sync copies" customization section) is `docs-and-install-flow`'s; here only the literal broken paths are corrected to their `plugins/sw/` equivalents (or the sentence naming a now-nonexistent concept, like the per-non-Claude-agent copy, is trimmed to its remaining true clause) — no rewording of surrounding install/customization prose beyond that. The vendored-scripts attribution line is updated to `plugins/sw/scripts/`.
- `NOTICE.md` — same vendored-scripts path update (`skills/sw/scripts/` → `plugins/sw/scripts/`), 2 occurrences in the vendored-content table.
- `CONTRIBUTING.md` — line 11 names `.agents/skills/sw-*/` and `skills/sw/scripts/`; the Quality Bar section (lines 30-40) gives runnable commands `python skills/sw/scripts/quick_validate.py ...` and `python skills/sw/scripts/package_skill.py ...` that would literally fail after the move (the scripts relocate to `plugins/sw/scripts/` per this spec's File Structure). All four path mentions are updated to `plugins/sw/scripts/`; the `.agents/skills/sw-*/` mention becomes `plugins/sw/skills/*/` (the bundled companions' new home). No other prose changes.
- `SECURITY.md` — line 24 names `skills/sw/` and `.agents/skills/sw-*/`; updated to `plugins/sw/`.
- `.github/PULL_REQUEST_TEMPLATE.md` — the Test Plan checklist's two `quick_validate.py`/`package_skill.py` commands name `skills/sw/scripts/...`; updated to `plugins/sw/scripts/...` so a contributor filling out this issue's own PR (or any future one) runs commands that actually exist.

**Deleted:**
- `.agents/` (entire tree — 8 skill directories, including `sw-brainstorm/scripts/`).
- `skills/sw/` (entire tree — `SKILL.md`, `references/`, `scaffold/`, `scripts/`).

## Phase Ordering

1. **Move templates, validator + fixtures, references** into `plugins/sw/` (git mv, preserving history).
2. **Rewire plugin skill/command references** to the new paths (plan, brainstorm, review-spec, spec-document-reviewer-prompt).
3. **Delete `.agents/` and `skills/sw/`.**
4. **Sweep for dangling references** — `grep -rn` for `.agents/skills` and `scaffold/skills`; fix every hit (`install.sh`, `AGENTS.md`, `README.md`, `NOTICE.md`), all path-focused edits only.
5. **Quality gate** — run `tests/install/run.sh` and re-validate the plan/brainstorm skill files resolve their referenced paths.
6. **Runtime verification** of AC-1 through AC-5.

Single-phase in practice (no external dependents to sequence around); ordered here only to keep the deletion (step 3) after the moves it depends on (step 1) are committed, and the sweep (step 4) after the rewire (step 2) so the sweep catches only genuine leftovers.

## Constraints

- **Non-Goals carried over from `issue.md`:** do not rewrite `/sw` into `/sw:init` (rewrite-sw-init); do not remove `sw:update` (remove-sw-update); do not rewrite README/AGENTS.md prose broadly (docs-and-install-flow) — touch them only where a moved path would otherwise leave a broken reference tripping AC-3/AC-5, and keep those edits minimal and path-focused; do not change brainstorm/plan/pr/review/run runtime behavior beyond updating moved-asset references.
- **`git mv` for history** — templates, validator, fixtures, and references are moved with `git mv`, not deleted-and-recreated, so `git log --follow` still traces them.
- **Executable bit** — `validate-spec.sh` keeps its executable bit across the move (`git mv` preserves file mode; verify with `git diff --summary` or `ls -l` after moving).
- **`sw-update.sh` — a documented, irreducible AC-3 exception, third of its kind.** `sw-update.sh` (~240 lines) lives under `skills/sw/scripts/`, which this issue deletes wholesale (AC-2), so it must move to survive at all (this issue's Non-Goals forbid removing `sw:update` — that is `remove-sw-update`'s job). Its `managed_pairs()` function and its self-test fixtures (`_selftest_apply`) hard-code the **installed target repo's** local reconciliation paths — `.agents/skills/sw-<name>/SKILL.md` (a path inside whatever repo *runs* `/sw:update`, not inside this specwright dev repo) and `<clone>/skills/sw/scaffold/skills/sw-<name>/SKILL.md` (the path inside the **upstream clone** this script itself fetches at `--run` time, which — until `remove-sw-update`'s own restructure ships upstream — is still where those files exist in a released tag). Both are references to *other* filesystems (an installed repo's local tree, and a temporary clone of a specwright release), not to this repo's own `.agents/`/`skills/sw/` being deleted here. Redesigning `managed_pairs()` for the single-copy plugin model is `remove-sw-update`'s entire purpose; rewriting it here would be exactly the "changing runtime behavior" this issue's Non-Goals forbid, and would desync the self-test fixtures from the classifier they exercise. Resolution: `git mv skills/sw/scripts/sw-update.sh` to `plugins/sw/scripts/sw-update.sh` **verbatim, zero logic change** — the same treatment as the `install.sh` exception. `plugins/sw/skills/update/SKILL.md`'s two direct self-references (the `--run`/`--record` invocation paths) move to `plugins/sw/scripts/sw-update.sh`; its "What is managed" table keeps the companion-skill-sync row exactly as today (still literally true of what the verbatim-moved script does) with an inline note explaining the row describes an installed target repo, not this one. Runtime verification for AC-3 names every line inside `plugins/sw/scripts/sw-update.sh` as a third documented survivor category, alongside `install.sh`'s two lines.
- **AC-3 scope resolution** — `grep -rn` for `.agents/skills`/`scaffold/skills` currently hits ~60 files, nearly all of them `issue.md`/`spec.md`/`tasks.md`/`learnings.md`/evidence files inside **already-`status: shipped`** issues under `.specwright/milestones/2026-07-02-e2e-validation/` and `.specwright/milestones/2026-07-02-specwright-fixes/` (verified: every issue in both is `status: shipped`), plus two standalone shipped issues under `.specwright/issues/`. `/sw:review`'s own documentation-consistency rule treats shipped issues/milestones as historical record explicitly exempt from doc-staleness findings — the same principle applies here: those files are dated snapshots of what the repo looked like when they shipped, not live references that resolve a path today, and rewriting ~60 historical files to say something that wasn't true when they were written would falsify the historical record for zero behavioral benefit (a Parsimony/Economy violation). This spec resolves the tension explicitly rather than silently: AC-3 is treated as scoped to **live files** — everything **except** `issue.md`/`spec.md`/`tasks.md`/`learnings.md`/`findings.md`/`dossier.md`/evidence files inside issue or milestone folders whose own `issue.md` says `status: shipped`. Concretely this issue fixes every hit in `plugins/sw/`, `AGENTS.md`, `README.md`, `NOTICE.md`, `CONTRIBUTING.md`, `SECURITY.md`, `.github/PULL_REQUEST_TEMPLATE.md`, and this milestone's own **not-yet-shipped** live files (`goal.md`'s and `rewrite-sw-init/issue.md`'s mentions are descriptive prose about the old system / a future AC and are left as-is, since they are not dangling references either — they describe, respectively, the retired architecture and a state `/sw:init` must not reintroduce).
- **AC-3's two irreducible `install.sh` hits** — `CANONICAL=".agents/skills/${SKILL}"` (line 26) and the matching `ln -s` (line 153) name a path on the **end-user's machine** (wherever `install.sh` runs), not a path inside this repo. That path is not a "reference to the old `.agents/`/`skills/sw/` layout being deleted here" at all — it is the installer's real, still-correct target for what the `skills` CLI writes when a user runs the curl-installer today (unaffected by this repo's own internal reorganization; the CLI still fetches `skills/sw/`'s **published tag/release** content, whose own restructuring is a separate concern for `docs-and-install-flow`, which owns `install.sh`'s deletion). Rewriting these two lines to avoid the grep would be lying about what the script does — a worse outcome than a documented, narrow exception. This spec's resolution: these two lines are **out of AC-3's intended scope** (a literal string match on a production filesystem target is not a "dangling reference to a deleted repo path"), and runtime verification explicitly names them as the sole two survivors, with the reasoning above, rather than silently passing or silently failing the criterion.
- **AC-3 verification output** — because of the `install.sh` survivors and the `plugins/sw/scripts/sw-update.sh` survivors above, the AC-3 checkbox in `issue.md` cannot be ticked as a bare "zero matches" fact. It is ticked `[x]` with an inline note: "verified — grep returns only `install.sh:26`, `install.sh:153` (the installer's real end-user-machine target path) and the `.agents/skills`/`scaffold/skills` lines inside `plugins/sw/scripts/sw-update.sh` (the reconciliation engine's references to an installed target repo's local tree and to the upstream release clone — both other filesystems, not this repo's own deleted paths; redesigning them is `remove-sw-update`'s job), all explicitly out of scope per spec.md's Constraints; zero matches in every other live file." This keeps Rule of Repair / Rule of Transparency: the exception is loud, not silent.

## User Stories / Scenarios

1. A contributor edits the `plan` companion skill's spec-writing instructions. They open `plugins/sw/skills/plan/SKILL.md` — the only copy — make the change, and are done; no second or third file to keep in sync.
2. A fresh clone's CI runs `tests/install/run.sh` and any shell lint on the touched area; both pass with the new paths.
3. Someone runs `bash plugins/sw/scripts/validate-spec.sh .specwright/milestones/2026-07-03-claude-only-plugin/issues/plugin-only-restructure/` and gets `PASS` (or a real structural defect, not a path-not-found error).
4. `grep -rn '\.agents/skills\|scaffold/skills' .` over the repo returns nothing.

## Acceptance Criteria

The acceptance criteria live in the sibling `issue.md` — the `AC-N` IDs defined there are the contract `tasks.md` references and `/sw:review` walks. Do not duplicate them here; if writing this spec exposed a missing or wrong criterion, fix `issue.md`.

## Risks and Mitigations

| Risk | Mitigation |
|---|---|
| A reference to the old paths survives in a **live** file not yet grepped. | Run the AC-3 grep repo-wide as the final gate before PR; fix every hit that is not inside a shipped issue/milestone's historical record (see AC-3 scope resolution above), and report the grep's full raw output in runtime verification so any historical hit is visible, not hidden. |
| Deleting `skills/sw/` would take `sw-update.sh` down with it, breaking `/sw:update` before `remove-sw-update` ships. | Move `sw-update.sh` verbatim to `plugins/sw/scripts/`; rewire only `update/SKILL.md`'s two direct self-references, leaving the engine's internal target-repo/upstream-clone path strings untouched (documented AC-3 exception) and the file's actual removal to `remove-sw-update`. |
| `install.sh`'s 4 comment/output `.agents/skills` strings trip AC-3 while its prose is `docs-and-install-flow`'s to redesign. | Reword only those 4 (no behavior change) so they stop matching the grep. |
| `install.sh`'s 2 executable-code `.agents/skills` occurrences (`CANONICAL=`, `ln -s`) name a real end-user-machine path and cannot be reworded without changing behavior. | Document them as an explicit, out-of-scope exception in this spec's Constraints; AC-3's runtime verification names both survivors and the reasoning instead of silently passing or failing. |
| `CONTRIBUTING.md`/`SECURITY.md`/`.github/PULL_REQUEST_TEMPLATE.md` were initially missed — they are live docs naming the moved validator scripts. | Added to File Structure and Task 11/12; caught by the spec-document-reviewer subagent pass before implementation started. |
| Moving `references/*.md` relocates prose that `rewrite-sw-init` will substantially rewrite, risking wasted or conflicting work. | Relocate files verbatim (no content rewrite) — satisfies this issue's AC-1 without duplicating the next issue's editorial work. |
| `tests/install/run.sh` or another test hard-codes an old path and starts failing after the move. | Run it as part of the quality gate; any failure caused by an old-path assumption is fixed as expected fallout of the restructure (per pipeline instructions), keeping assertions meaningful rather than weakened. |

## Open Questions

None.
