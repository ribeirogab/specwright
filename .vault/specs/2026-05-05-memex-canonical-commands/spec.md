---
status: draft
feature: memex-canonical-commands
created: 2026-05-05
shipped: null
related:
  - "[[../../conventions/skill-directory-layout]]"
---
# Memex Canonical Commands + Drop `memex-open-pr` — Spec

**Status:** Draft
**Scope:** Bring the `memex` skill's bundled slash commands under the same canonical-plus-symlink layout that already governs bundled skills, and stop shipping the `memex-open-pr` command.

## Context

The `memex` skill is the flagship scaffolder of this repo. It installs an externalized project memory (vault, AGENTS.md, templates, helper skills, slash commands) into any target repo. Today, **bundled skills** install canonically under `.agents/skills/<name>/` and are exposed via per-agent symlinks (`.claude/skills/<name>` → `../../.agents/skills/<name>`). Re-runs are idempotent and per-agent dirs that do not exist are not auto-created.

**Bundled slash commands**, however, install only as real files under `.claude/commands/<cmd>.md`. There is no canonical agent-agnostic location, and no symlink discipline. This is inconsistent with the skill pattern and makes the layout harder to reason about.

Separately, the maintainer has decided that the `memex-open-pr` command does not belong in this skill — opening a PR is a generic developer-workflow concern, not memex infrastructure.

## Problem Statement

1. **Inconsistent layout.** Skills follow the `.agents/skills/<name>/` (canonical) → `.claude/skills/<name>` (symlink) pattern. Commands break this pattern by living only as real files in `.claude/commands/`. The asymmetry forces every audit-checklist and validation rule to special-case commands.

2. **`memex-open-pr` shipped from the wrong place.** The command is bundled by `memex` even though its concern (opening a PR with a particular description format) has nothing to do with externalized agent memory. Keeping it in the skill bloats the bundle and conflates responsibilities.

## Non-Goals

- **Not migrating this repo's `.claude/commands/memex-*.md`** as part of the spec. The repo dogfoods memex, but the maintainer chose to defer the dogfood pass — running `/memex` here after the skill ships will migrate the four active commands automatically. Updating `AGENTS.md`'s `## Commands (most used)` section in this repo and removing this repo's stale `.claude/commands/memex-open-pr.md` are explicit out-of-spec manual cleanups (see Acceptance Criteria #8).
- **Not introducing canonical commands for other agents.** Slash commands are a Claude Code-specific concept; no other current agent (Codex, Cursor, OpenCode, Aider, Augment) has an equivalent. The per-agent symlink loop only targets `.claude/`.
- **Not adding content validation for `AGENTS.md`'s `## Commands (most used)` section.** Today the audit only enforces section-header presence and the 80-line cap. Catching stale command references in installed AGENTS.md files is a separate concern and is not in scope here.
- **Not removing the `memex-open-pr` slash-command file from any repo automatically.** The skill stops shipping it; existing repos keep their copy until manually removed (orphan policy B — see Architecture Decisions).
- **Not relocating `memex-open-pr` into another skill in this repo.** The command may live elsewhere later, but that is a separate decision outside this spec.

## Constraints

- **Idempotency is non-negotiable.** Re-running `/memex` against any repo (clean, partially installed, or fully installed) must converge without prompts beyond the destructive-op confirmations the skill already requires (spec-folder rename, spec-file rename). Migrating an existing real `.claude/commands/<cmd>.md` to a symlink is not treated as a destructive op for prompting purposes — the user has already declared "scaffold sempre vence" as policy.
- **No build pipeline.** Per `.vault/constitution.md` § "Tooling and workflow principles", the skill is markdown plus shell. The command-install logic stays in `SKILL.md` as inline bash and is loaded by the orchestrator; no scripts or new tooling.
- **Skills are self-contained.** Per `.vault/constitution.md` § "Architecture principles", the `memex` skill must remain usable by copying or symlinking its directory alone. The new canonical-commands logic ships inside `skills/memex/` and is not split across the repo.
- **Reference docs are loaded on demand.** Long instructions go in `references/*.md`. The orchestrator (`SKILL.md`) only carries the dispatch logic and the bash recipe.

## Architecture Decisions

The brainstorming pass settled four forks. They are recorded here as the decision log so the implementation plan does not relitigate them.

1. **Migration policy for existing `.claude/commands/<cmd>.md` real files: scaffold always wins.** When the audit sees a regular file at the symlink target, it removes the file and creates the symlink without comparing contents to the scaffold version. Rationale: the maintainer explicitly opted out of customization preservation ("não ligo se usuario tiver mexido"). This keeps the migration recipe small (no diff/merge logic) and matches how existing skills already overwrite drifted templated files when fixing.

2. **Orphan command handling: ignore (policy B).** The skill stops shipping `memex-open-pr.md` and the audit no longer expects it. Files already on disk in installed repos are not detected, not flagged, not removed. Rationale: a "deprecated commands" mechanism (option C) would add lasting complexity for a one-time cleanup; the maintainer accepted manual removal.

3. **Spec scope: skill only (escopo A).** Changes are confined to `skills/memex/`. This repo's `.claude/commands/memex-*.md` regular files, this repo's `AGENTS.md` `## Commands (most used)` section, and this repo's stale `memex-open-pr.md` file are all out-of-spec manual cleanups. Rationale: changing the dogfood layout in the same PR that changes the skill confuses the diff and risks the spec self-validating against still-stale state.

4. **Layout symmetry: same pattern as skills, single-agent loop.** Canonical at `.agents/commands/<cmd>.md`, per-agent symlinks at `.claude/commands/<cmd>.md` only. No multi-agent loop (Codex, Cursor, etc. do not have slash commands). Bundled command count drops from 5 to 4: `memex-learn`, `memex-spec`, `memex-review-spec`, `memex-sweep`.

## User Stories / Scenarios

1. **Fresh install on a new repo.** Maintainer runs `/memex` in a repo that has `.claude/` but no `.agents/commands/`. The skill creates `.agents/commands/<cmd>.md` for each of the four commands, then symlinks them under `.claude/commands/<cmd>.md`. Phase 5 validation passes 15/15.

2. **Audit on a repo that installed memex before this change.** Maintainer runs `/memex` in a repo that has real `.claude/commands/memex-{learn,spec,review-spec,sweep}.md` files plus the orphan `memex-open-pr.md`. The skill detects the four active commands as drift, removes the real files, copies scaffold contents to `.agents/commands/<cmd>.md`, and creates symlinks back into `.claude/commands/`. The orphan `memex-open-pr.md` is not touched (policy B). Phase 5 validation passes 15/15 because `memex-open-pr` is no longer in the expected list.

3. **Audit on a repo without `.claude/`.** Maintainer runs `/memex` in a repo that uses, say, only Codex. Canonical files are still installed under `.agents/commands/<cmd>.md`. No symlinks are created (no per-agent dir to populate). Phase 5 Check #11 reports `PASS` against the canonical files — the redefined Check #11 no longer gates on `.claude/` existence and no longer emits `N/A`. The total stays 15/15 PASS.

4. **Re-running audit after migration.** All four `.claude/commands/<cmd>.md` are now symlinks pointing to `../../.agents/commands/<cmd>.md`. Re-running `/memex` reports every command as `OK`, makes no changes, and Phase 5 passes 15/15.

5. **Symlink target drifted.** A user has a symlink at `.claude/commands/memex-spec.md` that points somewhere wrong (e.g., to a deleted path or to the wrong canonical). The audit's symlink check detects the bad symlink, removes it, and recreates it pointing at `../../.agents/commands/memex-spec.md`.

## Acceptance Criteria

Each criterion is binary and observable in under a minute by reading the resulting filesystem state and running the audit.

- [ ] **AC1.** `skills/memex/scaffold/commands/memex-open-pr.md` does not exist on disk (`test ! -e ...`).
- [ ] **AC2.** `skills/memex/SKILL.md` Phase 4 commands block defines `COMMAND_NAMES=(memex-learn memex-spec memex-review-spec memex-sweep)` and uses a two-step canonical-then-symlink loop. The canonical copy step is **idempotent skip-if-present** (`[ -e ".agents/commands/$cmd.md" ] && continue` before `cp`), matching the existing skills-canonical pattern. The canonical step runs whether or not `.claude/` exists; the symlink step runs only inside `if [ -d .claude ]; then`. There is no version of the canonical copy that overwrites an existing canonical file — re-runs are no-ops on canonicals that already exist.
- [ ] **AC3.** `skills/memex/SKILL.md` Phase 4 includes a real-file-to-symlink migration branch with the conditions in this exact order: `if [ -L "$target" ]; then continue; elif [ -f "$target" ]; then rm "$target"; fi; ln -s ...`. The `[ -L ]` test must come before the `[ -f ]` test because `[ -f ]` resolves through symlinks on macOS and would otherwise drop a working symlink on every run. AC9 (second run no-op) is the runtime validation of this ordering.
- [ ] **AC4.** `skills/memex/references/audit-checklist.md` "Files and directories to check" lists `.agents/commands/memex-{learn,spec,review-spec,sweep}.md` as canonical entries and no longer lists any `.claude/commands/memex-*.md` entry as required. The file contains a new subsection titled "Per-agent command symlinks" mirroring the existing "Per-agent skill symlinks" subsection (non-required, recreate-on-rerun semantics, with one explicit clarification: a regular file at the symlink target IS DRIFT and is auto-fixed by Phase 4 — not a no-prompt no-op like a missing symlink).
- [ ] **AC5.** `skills/memex/references/validation.md` Check #11 verifies canonical existence at `.agents/commands/<cmd>.md` for the four active commands using `[ -f ]`. The check no longer references `.claude/commands/`, no longer references `memex-open-pr`, and no longer emits `N/A` — it always runs and always returns PASS or FAIL based on canonical-file existence. Phase 5 keeps exactly 15 checks (one redefined, none added or removed). Symlink integrity at `.claude/commands/<cmd>.md` is **not** a Phase 5 concern; symlink drift is detected and fixed in Phase 1 (audit) / Phase 4 (scaffold) and Phase 5 only certifies that canonical files ended up in place.
- [ ] **AC6.** `skills/memex/references/agents-md-template.md`'s `## Skills and slash commands` section list does not contain any line referencing `/memex-open-pr` or `memex-open-pr`. The remaining seven bullet entries (`memex-brainstorming`, `memex-writing-plans`, `memex-recall`, `/memex-spec`, `/memex-review-spec`, `/memex-sweep`, `/memex-learn`) stay verbatim — the line is deleted with no replacement entry. `grep -F 'memex-open-pr' skills/memex/references/agents-md-template.md` returns no match.
- [ ] **AC7.** Running the new audit-and-scaffold flow on a clean test repo (one with `.claude/` but no `.agents/`) produces the canonical files plus four symlinks resolving correctly (`readlink .claude/commands/memex-spec.md` returns `../../.agents/commands/memex-spec.md`). Phase 5 reports 15/15 PASS.
- [ ] **AC8.** Running the new flow on a test repo seeded with real `.claude/commands/memex-{learn,spec,review-spec,sweep,open-pr}.md` files (simulating an existing install) results in: (a) canonical files at `.agents/commands/<cmd>.md` for the four active commands; (b) `.claude/commands/memex-{learn,spec,review-spec,sweep}.md` are symlinks; (c) `.claude/commands/memex-open-pr.md` is left untouched as a regular file (policy B). Phase 5 reports 15/15 PASS.
- [ ] **AC9.** Running the audit a second time on the result of AC7 or AC8 makes no filesystem changes (`git status` clean if these were a real repo) and reports 15/15 PASS.
- [ ] **AC10.** Running the audit on a `.claude/`-absent test repo (e.g., `.codex/` only) produces canonical files at `.agents/commands/<cmd>.md`, no symlinks anywhere (no `.claude/commands/` directory created), and Phase 5 reports 15/15 PASS — Check #11 PASSes against the canonical files even with `.claude/` absent.
- [ ] **AC11.** No file under `skills/memex/` references `memex-open-pr` after the change (`grep -rln 'memex-open-pr' skills/memex/ → no match`).

## Risks and Mitigations

| Risk | Mitigation |
|---|---|
| Migration `rm` deletes a `.claude/commands/<cmd>.md` that the user genuinely customized for a non-memex purpose. | Brain-dump policy was explicit ("scaffold sempre vence"). The skill's contract is that any file with a name matching a bundled command is owned by the skill. Document this in the audit-checklist subsection so the policy is discoverable. |
| Orphan `memex-open-pr.md` survives indefinitely in installed repos and becomes a stale reference in agents' command palettes. | Accepted by the maintainer (policy B). The skill's release notes / commit message must call out the removal so installed users know to remove the file manually. |
| `[ -f ]` test passes for symlinks too, causing the migration branch to `rm` a working symlink and recreate it on every run. | Order the conditions: check `[ -L ]` first and `continue` if true, then `[ -f ]` only catches real files. Cover this in the SKILL.md comment and verify in AC9 (second run is no-op). |
| `.agents/commands/<cmd>.md` exists with stale content from a prior canonical install (e.g., a previous edit). | Same idempotency rule as skills: canonical files are not overwritten on re-run. If the user wants to refresh a canonical command, they delete the file and re-run. Document this alongside AC9. |
| Audit-checklist and validation get out of sync (e.g., one references `memex-open-pr` and the other doesn't). | AC11 catches any leftover string anywhere under `skills/memex/`. |
| Existing audit runs against `AGENTS.md` start to disagree because `## Commands (most used)` references `/memex-open-pr` but the skill template no longer does. | Out of scope per Non-Goals. The audit doesn't validate `## Commands` content today, so no false-DRIFT is introduced. The maintainer's manual cleanup of the stale line is tracked separately. |

## Open Questions

None. All forks identified during brainstorming were resolved (migration policy, orphan handling, scope, layout symmetry).
