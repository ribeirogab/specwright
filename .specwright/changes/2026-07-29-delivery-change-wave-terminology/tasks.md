---
feature: delivery-change-wave-terminology
created: 2026-07-29
tasks_schema: 2
---
# Delivery, Change, and Wave Terminology — Tasks

**For this change:** see the sibling `change.md` (acceptance criteria) and `spec.md` (technical plan).

> Every task has a stable `Tn` identifier and names the `AC:` criteria it satisfies. `Delegable:` begins with `yes` or `no` and may add a concise context after ` — `. `Delegable: yes` tasks use `Integration: isolated` and own explicit repository-relative files. `Delegable: no` tasks use `Integration: inline` and list exactly `- None` when they have no owned files. `Depends on:` plus the `Files:` ownership set are the graph `sw:run` derives **waves** from — a wave is a dependency-ready, file-disjoint set of isolated tasks that may run in parallel; waves are computed at dispatch time and never persisted. Workers report findings back to the change-owner; only the owner writes `learnings.md`.

## Phase 1: Plugin rename

### T1: Rename and rewrite the templates

**AC:** AC-1, AC-6
**Delegable:** no — owner ran the rename inline to keep the vocabulary judgement in one session
**Depends on:** none
**Files:**
- Delete: `plugins/sw/templates/issue.md`
- Delete: `plugins/sw/templates/goal.md`
- Create: `plugins/sw/templates/change.md`
- Create: `plugins/sw/templates/delivery.md`
- Modify: `plugins/sw/templates/spec.md`
- Modify: `plugins/sw/templates/tasks.md`
- Modify: `plugins/sw/templates/board.md`
**Integration:** inline
**Validation:** `ls plugins/sw/templates/ | sort` shows exactly board.md, change.md, codex-agents, delivery.md, spec.md, tasks.md

- [x] Step 1: `git mv issue.md change.md` and `git mv goal.md delivery.md`; rewrite both with the new vocabulary and frontmatter (`delivery:` key on `change.md`).
- [x] Step 2: Update `spec.md` (`milestone:` → `delivery:`), `tasks.md` (schema-2 with `tasks_schema: 2`, wave note in the header), `board.md` (changes, not issues).
- [x] Step 3: Verify no surviving template placeholders and no old terms; commit.

### T2: Rename the issue-owner agent and Codex profiles

**AC:** AC-2
**Delegable:** no — frontmatter values had to be preserved exactly while rewriting prose
**Depends on:** none
**Files:**
- Delete: `plugins/sw/agents/issue-owner.md`
- Create: `plugins/sw/agents/change-owner.md`
- Modify: `plugins/sw/agents/spec-document-reviewer.md`
- Delete: `plugins/sw/templates/codex-agents/sw-issue-owner.toml`
- Create: `plugins/sw/templates/codex-agents/sw-change-owner.toml`
- Modify: `plugins/sw/templates/codex-agents/sw-task-worker.toml`
- Modify: `plugins/sw/templates/codex-agents/sw-reviewer.toml`
- Modify: `plugins/sw/templates/codex-agents/sw-spec-document-reviewer.toml`
**Integration:** inline
**Validation:** `ls plugins/sw/agents/ plugins/sw/templates/codex-agents/` shows change-owner artifacts and no issue-owner artifact

- [x] Step 1: `git mv agents/issue-owner.md agents/change-owner.md`; update `name`, `description`, and body preserving `model: opus`, `effort: xhigh`, `skills: [plan]`.
- [x] Step 2: `git mv sw-issue-owner.toml sw-change-owner.toml`; rewrite the four Codex profiles to the new vocabulary.
- [x] Step 3: Verify `plugins/sw/agents/` holds exactly four definitions with no `delivery-conductor.md`; commit.

### T3: Rewrite skill prose to the new vocabulary

**AC:** AC-3, AC-6, AC-7
**Delegable:** no — the judgement pass (classifying every `issue`/`milestone` hit as artifact / tracker) is owner work
**Depends on:** none
**Files:**
- Modify: `plugins/sw/skills/brainstorm/SKILL.md`
- Modify: `plugins/sw/skills/plan/SKILL.md`
- Modify: `plugins/sw/skills/run/SKILL.md`
- Modify: `plugins/sw/skills/review/SKILL.md`
- Modify: `plugins/sw/skills/review-spec/SKILL.md`
- Modify: `plugins/sw/skills/pr/SKILL.md`
- Modify: `plugins/sw/skills/spec/SKILL.md`
- Modify: `plugins/sw/skills/init/SKILL.md`
- Modify: `plugins/sw/skills/update/SKILL.md`
**Integration:** inline
**Validation:** `grep -rni 'milestone\|issue-owner\|issue\.md\|goal\.md' plugins/sw/skills/` exits 1 (zero hits)

- [x] Step 1: Rewrite paths and vocabulary in all nine skills; scope conclusion in `brainstorm` is standalone-change vs delivery; `run` conducts deliveries, dispatches `sw-change-owner`, and documents waves derived from the schema-2 graph (never persisted); `pr` finds the change by `branch:` and writes `pr.md`.
- [x] Step 2: Classify every remaining `issue`/`milestone` occurrence — tracker references stay (qualified "GitHub issue" where ambiguous); zero legacy references survive.
- [x] Step 3: Diff `run/SKILL.md` against `main` to confirm the PR #65 orchestration mechanics are behavior-preserved; commit.

### T4: Update command descriptions, references, and manifests

**AC:** AC-3
**Delegable:** no — bundled with T3's classification pass for a single zero-remnant sweep
**Depends on:** none
**Files:**
- Modify: `plugins/sw/commands/brainstorm.md`
- Modify: `plugins/sw/commands/plan.md`
- Modify: `plugins/sw/commands/pr.md`
- Modify: `plugins/sw/commands/review.md`
- Modify: `plugins/sw/commands/review-spec.md`
- Modify: `plugins/sw/commands/run.md`
- Modify: `plugins/sw/commands/spec.md`
- Modify: `plugins/sw/references/vault-files.md`
- Modify: `plugins/sw/references/audit-checklist.md`
- Modify: `plugins/sw/references/validation.md`
- Modify: `plugins/sw/references/agents-md-template.md`
- Modify: `plugins/sw/.claude-plugin/plugin.json`
- Modify: `plugins/sw/.codex-plugin/plugin.json`
- Modify: `.claude-plugin/marketplace.json`
**Integration:** inline
**Validation:** `grep -rni 'milestone\|issue-owner\|issue\.md\|goal\.md' plugins/sw/commands/ plugins/sw/references/ plugins/sw/.claude-plugin/ plugins/sw/.codex-plugin/ .claude-plugin/` exits 1

- [x] Step 1: Sweep `commands/*.md` descriptions for issue/milestone and rewrite (command names unchanged).
- [x] Step 2: Rewrite the reference docs to the new vocabulary and flat layout; rewrite the managed block in `agents-md-template.md`.
- [x] Step 3: Bump both manifests to `2026.7.29` and rewrite "issue-driven" descriptions; verify with the AC-3 grep; commit.

## Phase 2: Validator, updater, and durable tests

### T5: Port validate-spec.sh, topology script, sw_update.py, fixtures, and test suites

**AC:** AC-4, AC-9, AC-10
**Delegable:** no — sw_update.py's legacy-recognition removal changed the updater contract and needed owner judgement
**Depends on:** none
**Files:**
- Modify: `plugins/sw/scripts/validate-spec.sh`
- Modify: `plugins/sw/scripts/validate_task_topology.py`
- Modify: `plugins/sw/scripts/sw_update.py`
- Modify: `plugins/sw/scripts/fixtures/good/change.md`
- Modify: `plugins/sw/scripts/fixtures/good/spec.md`
- Modify: `plugins/sw/scripts/fixtures/good/tasks.md`
- Create: `tests/validate-spec/run.sh`
- Modify: `tests/install/run.sh`
- Modify: `tests/update/test_plan.py`
- Modify: `tests/task-topology/test_parser.py`
- Modify: `tests/worktrees/test_local_copy.py`
- Modify: `tests/update/fixtures/up-to-date/AGENTS.md`
- Modify: `tests/install/fixtures/update/up-to-date/AGENTS.md`
**Integration:** inline
**Validation:** `bash tests/validate-spec/run.sh && bash tests/install/run.sh && python3 tests/update/test_plan.py` all pass

- [x] Step 1: Re-point the six checks from `issue.md` to `change.md`; update topology diagnostics ("schema-1", "change status"); `--issue` flag → `--change`.
- [x] Step 2: sw_update.py — rename `PROFILE_NAMES`, drop `LEGACY_GENERIC_TEMPLATE`/`LEGACY_DOGFOOD_DIGEST` recognition and the 2026.7.27 predecessor digests (zero legacy names ship); unrecognized shapes classify `drifted`.
- [x] Step 3: Rename every fixture `issue.md` → `change.md` (`milestone:` → `delivery:`); rewrite the legacy-migration test cases as unrecognized-shape drift refusals; regenerate the up-to-date fixtures with the 2026.7.29 block.
- [x] Step 4: Add durable `tests/validate-spec/run.sh` (checks 1–5 + missing-`change.md` + scope enum); commit.

### T6: Migrate this repo's legacy vault

**AC:** AC-5
**Delegable:** no — the owner runs and verifies the move itself; migration is a task of this change, never plugin logic
**Depends on:** none
**Files:**
- Modify: `.specwright/issues/`
- Modify: `.specwright/milestones/`
**Integration:** inline
**Validation:** `test ! -d .specwright/issues && test ! -d .specwright/milestones && git diff --cached --stat` shows renames only

- [x] Step 1: `git mv` each `.specwright/issues/<slug>/` to `.specwright/changes/<slug>/`, renaming `issue.md` → `change.md`.
- [x] Step 2: `git mv` each `.specwright/milestones/<slug>/` to `.specwright/deliveries/<slug>/`, renaming `goal.md` → `delivery.md`; move each milestone's `issues/<slug>/` child up to `.specwright/changes/<slug>/`, renaming its `issue.md` → `change.md`.
- [x] Step 3: Verify the move is pure rename — `git diff --cached` showed 185 files, 0 insertions, 0 deletions; commit.

## Phase 3: Repo docs

### T7: Update CLAUDE.md, README.md, and CONTRIBUTING.md

**AC:** AC-8
**Delegable:** no — the managed block had to be re-rendered from the canonical template, not hand-edited
**Depends on:** none
**Files:**
- Modify: `CLAUDE.md`
- Modify: `README.md`
- Modify: `CONTRIBUTING.md`
**Integration:** inline
**Validation:** `grep -niE 'milestone|issue-owner|issue\.md|goal\.md' CLAUDE.md README.md CONTRIBUTING.md` exits 1

- [x] Step 1: Re-render the CLAUDE.md `sw:managed` block from `agents-md-template.md` (version 2026.7.29) and rewrite the surrounding workflow/role passages.
- [x] Step 2: Rewrite the README.md workflow description, command table, state layout, and role table; check CONTRIBUTING.md and update its updater-contract and tracker references.
- [x] Step 3: Grep all three files for old terms; commit.

## Phase 4: Gates + runtime verification

### T8: Quality gate

**AC:** AC-3
**Delegable:** no — gates run from the owning session
**Depends on:** T1, T2, T3, T4, T5, T6, T7
**Files:**
- None
**Integration:** inline
**Validation:** `bash tests/install/run.sh && bash tests/validate-spec/run.sh && bash tests/release/run.sh` all pass

- [x] Step 1: Run the durable suites (`tests/install/run.sh`, `tests/validate-spec/run.sh`, `tests/release/run.sh`) and the per-skill `quick_validate.py` / `package_skill.py` checks the PR template requires — all nine skills valid and packaged; `tests/skills/test_validation.py` PASS.
- [x] Step 2: Run the AC-3 grep classification over `plugins/sw/` — zero hits for `milestone`, `issue-owner`, `issue.md`, `goal.md`; remaining `issue` occurrences are protocol tokens ("Issues Found") or generic English.
- [x] Step 3: Fix the residuals the sweep surfaced (reviewer lane name, task-worker role prose); commit.

### T9: Runtime verification and AC walk

**AC:** AC-1, AC-2, AC-3, AC-4, AC-5, AC-6, AC-7, AC-8, AC-9, AC-10
**Delegable:** no — the owner verifies by observed behavior and ticks each AC
**Depends on:** T8
**Files:**
- Modify: `.specwright/changes/2026-07-29-delivery-change-wave-terminology/change.md`
- Modify: `.specwright/changes/2026-07-29-delivery-change-wave-terminology/tasks.md`
**Integration:** inline
**Validation:** `bash plugins/sw/scripts/validate-spec.sh .specwright/changes/2026-07-29-delivery-change-wave-terminology` prints PASS

- [x] Step 1: Verify each AC by observed behavior (file inspection, validator runs, migration diff, grep classification); tick or mark `needs-human-verification` with the reason.
- [x] Step 2: Run the plan self-review gates (mechanical validator — PASS; spec-document-reviewer and review-spec recorded in the PR body) and the three-lane `sw:review` (findings merged and fixed: dogfooded `.codex/agents/` profiles replaced, SECURITY/NOTICE/GitHub-template docs swept, AC-10 amended).
- [x] Step 3: Commit the ticked artifacts; refresh the PR via `sw:pr`.
