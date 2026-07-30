---
feature: delivery-change-wave-terminology
created: 2026-07-29
---
# Delivery, Change, and Wave Terminology — Tasks

**For this change:** see the sibling `change.md` (acceptance criteria) and `spec.md` (technical plan).

> Each task names the `AC:` it satisfies (every `AC-N` is referenced by at least one task), **Files:** (the file-ownership set waves are derived from — two tasks sharing a file never run in the same wave), and `Delegable:` (whether it suits an isolated task worker, plus the one-line context that worker would receive). Workers report findings back to the change-owner; only the owner writes `learnings.md`.

## Phase 1: Plugin rename

### Task 1: Rename and rewrite the templates

**AC:** AC-1, AC-6
**Files:** `plugins/sw/templates/issue.md`, `plugins/sw/templates/goal.md`, `plugins/sw/templates/spec.md`, `plugins/sw/templates/tasks.md`, `plugins/sw/templates/board.md` (→ `change.md`, `delivery.md`, …)
**Delegable:** yes — rename per the vocabulary map in `spec.md`, add the `delivery:` key to `change.md` frontmatter, add the **Files:** line to the `tasks.md` template, rewrite prose to delivery/change/task/wave.

- [ ] Step 1: `git mv issue.md change.md` and `git mv goal.md delivery.md`; rewrite both with the new vocabulary and frontmatter.
- [ ] Step 2: Update `spec.md` (`milestone:` → `delivery:`), `tasks.md` (add **Files:** ownership line), `board.md` (changes, not issues).
- [ ] Step 3: Verify no surviving template placeholders and no old terms outside legacy-migration contexts; commit.

### Task 2: Rename the issue-owner agent and re-point dispatches

**AC:** AC-2, AC-7
**Files:** `plugins/sw/agents/issue-owner.md` (→ `change-owner.md`), `plugins/sw/skills/run/SKILL.md`, `plugins/sw/skills/plan/SKILL.md`
**Delegable:** yes — rename preserving `model: opus`, `effort: xhigh`, `skills: [plan]`; re-point the dispatch steps that named `issue-owner` to `change-owner`.

- [ ] Step 1: `git mv agents/issue-owner.md agents/change-owner.md`; update `name`, `description`, and body references.
- [ ] Step 2: In `run/SKILL.md` and `plan/SKILL.md`, name `change-owner` wherever `issue-owner` was the dispatch target.
- [ ] Step 3: Verify `plugins/sw/agents/` holds exactly four definitions with no `delivery-conductor.md`; commit.

### Task 3: Rewrite skill prose to the new vocabulary

**AC:** AC-3, AC-6, AC-7
**Files:** `plugins/sw/skills/brainstorm/SKILL.md`, `plugins/sw/skills/plan/SKILL.md`, `plugins/sw/skills/run/SKILL.md`, `plugins/sw/skills/review/SKILL.md`, `plugins/sw/skills/review-spec/SKILL.md`, `plugins/sw/skills/pr/SKILL.md`, `plugins/sw/skills/spec/SKILL.md`, `plugins/sw/skills/init/SKILL.md`
**Delegable:** no — the judgement pass (classifying every `issue`/`milestone` hit as artifact / tracker / migration) is owner work.

- [ ] Step 1: Rewrite paths and vocabulary in all eight skills; scope conclusion in `brainstorm` becomes standalone-change vs delivery; `run` derives waves from task dependencies + **Files:** ownership and never persists wave folders; `pr` finds the change by `branch:` and writes `pr.md`.
- [ ] Step 2: Classify every remaining `issue`/`milestone` occurrence — tracker references stay (qualified "GitHub issue" where ambiguous); zero legacy references survive in `plugins/sw/`.
- [ ] Step 3: Diff `run/SKILL.md` against `main` to confirm the PR #65 orchestration mechanics are behavior-preserved; commit.

### Task 4: Update command descriptions and references

**AC:** AC-3
**Files:** `plugins/sw/commands/*.md`, `plugins/sw/references/vault-files.md`, `plugins/sw/references/audit-checklist.md`, `plugins/sw/references/validation.md`, `plugins/sw/references/claude-md-template.md`
**Delegable:** yes — touch only description/prose that names the old terms; command names (`/sw:*`) stay.

- [ ] Step 1: Sweep `commands/*.md` descriptions for issue/milestone and rewrite.
- [ ] Step 2: Rewrite the four reference docs to the new vocabulary and flat layout.
- [ ] Step 3: Verify with the AC-3 grep classification; commit.

## Phase 2: Validator + migration

### Task 5: Port validate-spec.sh to the new format

**AC:** AC-4, AC-9, AC-10
**Files:** `plugins/sw/scripts/validate-spec.sh`, `tests/validate-spec/run.sh` (new), `tests/validate-spec/fixtures/` (new)
**Delegable:** yes — same five checks re-pointed: `change.md` (feature/created/status + enum), `spec.md` (feature/created/scope), placeholder sweep, vague-verb sweep, AC-reference coverage vs `tasks.md`; header comments rewritten. Plus a durable suite mirroring the `tests/install/` convention.

- [ ] Step 1: Re-point the five checks from `issue.md` to `change.md`; update usage and header comments.
- [ ] Step 2: Negative test — folder without `change.md` FAILs; folder with valid `change.md`/`spec.md`/`tasks.md` PASSes.
- [ ] Step 3: Make it durable: add `tests/validate-spec/run.sh` (same conventions as `tests/install/run.sh` — ephemeral fixtures, pass/die assertions) covering the PASS case, the missing-`change.md` failure, and the status/scope enums.
- [ ] Step 4: Run it on this change's own folder and capture the `PASS` line (AC-9); commit.

### Task 6: Migrate this repo's legacy vault

**AC:** AC-5
**Files:** `.specwright/issues/` (→ `.specwright/changes/`), `.specwright/milestones/` (→ `.specwright/deliveries/` + `.specwright/changes/`)
**Delegable:** no — the owner runs and verifies the move itself. Migration is a task of this change, never plugin logic: no skill, template, script, or reference gains migration code or legacy references.

- [ ] Step 1: `git mv` each `.specwright/issues/<slug>/` to `.specwright/changes/<slug>/`, renaming `issue.md` → `change.md`.
- [ ] Step 2: `git mv` each `.specwright/milestones/<slug>/` to `.specwright/deliveries/<slug>/`, renaming `goal.md` → `delivery.md`; move each milestone's `issues/<slug>/` child up to `.specwright/changes/<slug>/`, renaming its `issue.md` → `change.md`.
- [ ] Step 3: Verify the move is pure rename — `git diff --cached` shows only renames, and every moved file's content is byte-identical to its pre-move blob; commit.

## Phase 3: Repo docs

### Task 7: Update CLAUDE.md and README.md

**AC:** AC-8
**Files:** `CLAUDE.md`, `README.md`, `CONTRIBUTING.md` (check only)
**Delegable:** yes — workflow description, flat layout diagram, role names (`change-owner`); check `CONTRIBUTING.md` and touch it only if it names the old terms.

- [ ] Step 1: Rewrite the CLAUDE.md workflow/layout/role passages.
- [ ] Step 2: Rewrite the README.md workflow description.
- [ ] Step 3: Grep both files for old terms; commit.

## Phase 4: Gates + runtime verification

### Task 8: Quality gate

**AC:** AC-3
**Files:** none (verification only)
**Delegable:** no — gates run from the owning session.

- [ ] Step 1: Run the durable suites (`tests/install/run.sh`, `tests/validate-spec/run.sh`) and the per-skill `quick_validate.py` / `package_skill.py` checks the PR template requires.
- [ ] Step 2: Run the AC-3 grep classification over `plugins/sw/` and record the classified hits.
- [ ] Step 3: Fix anything the gates surface; commit.

### Task 9: Runtime verification and AC walk

**AC:** AC-4, AC-5, AC-9, AC-10 (plus the full AC-1…AC-10 walk)
**Files:** `.specwright/changes/2026-07-29-delivery-change-wave-terminology/change.md` (ticking ACs)
**Delegable:** no — the owner verifies by observed behavior and ticks each AC.

- [ ] Step 1: Verify each AC by observed behavior (file inspection, validator runs, fixture migration, grep classification); tick or mark `needs-human-verification` with the reason.
- [ ] Step 2: Run the three plan/delivery self-review gates (mechanical validator, spec-document-reviewer, review) and record outcomes.
- [ ] Step 3: Commit the ticked `change.md`; open/refresh the PR via `/sw:pr`.
