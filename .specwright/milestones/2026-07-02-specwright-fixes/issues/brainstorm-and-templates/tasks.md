---
feature: brainstorm-and-templates
created: 2026-07-02
---
# Brainstorm and Templates — Tasks

**For this issue:** see the sibling `issue.md` (acceptance criteria) and `spec.md` (technical plan).

> Each task names the `AC:` (acceptance criteria from `issue.md` it satisfies — every `AC-N` must be referenced by at least one task) and `Delegable:` (whether it suits an isolated task worker, and the one-line context that worker would receive). Workers report findings back to the issue owner; only the owner writes `learnings.md`.

## Phase 1: Canonical brainstorm-skill edits

### Task 1: Reword checklist item 6 — scope conclusion without the milestone reflex

**AC:** AC-3
**Delegable:** no — all skill edits land in one file and must stay stylistically coherent; the owner does them inline.
**Files:**
- Modify: `.agents/skills/sw-brainstorm/SKILL.md` (checklist item 6)

- [ ] Step 1: Replace checklist item 6 so it reads that work fitting one issue concludes **single issue** plainly, without presenting the milestone alternative, and that the milestone option (with a decomposition preview: issue slugs, one-liners, dependencies) is suggested only when the scope signals (see "Judging the scope") point to one; keep "The user decides" and "conclusion of the design, not a command choice".
- [ ] Step 2: Verify: `grep -n "without presenting the milestone" .agents/skills/sw-brainstorm/SKILL.md` returns the item-6 line, and the item no longer instructs to "state whether this is a single issue or a milestone" unconditionally.
- [ ] Step 3: Commit `fix(brainstorm): conclude single issue without naming the milestone for small work`.

### Task 2: Goal-writing rule — behavior terms plus worked example

**AC:** AC-1
**Delegable:** no — same file as Task 1.
**Files:**
- Modify: `.agents/skills/sw-brainstorm/SKILL.md` (`goal.md` bullet in "Milestone — batch and artifacts")

- [ ] Step 1: Extend the `goal.md` bullet with: goals phrased in **behavior terms** — no file paths, function names, or storage formats; one worked example translating a technical hard constraint into goal-level language (e.g. "`test/taskr.test.js` must pass unmodified" → "the existing test suite passes without edits"); and the sentence that path-level constraints live in the issue tickets.
- [ ] Step 2: Verify: `grep -n "behavior terms" .agents/skills/sw-brainstorm/SKILL.md` hits the goal.md bullet; the worked example shows both the technical phrasing and its goal-level translation; "issue tickets" named as the home of path-level constraints.
- [ ] Step 3: Commit `fix(brainstorm): goal.md rule — behavior terms, worked example, paths live in tickets`.

### Task 3: Validate tickets before committing

**AC:** AC-2
**Delegable:** no — same file as Task 1.
**Files:**
- Modify: `.agents/skills/sw-brainstorm/SKILL.md` ("Milestone — batch and artifacts" + "Single issue — batch and artifacts")

- [ ] Step 1: In the milestone artifacts step, before "Commit the milestone folder", add the instruction: run `validate-spec.sh` on each `issues/<slug>/` folder before committing (dev repo: `skills/sw/scripts/validate-spec.sh`; installed: under the installed `sw` skill at `scripts/validate-spec.sh`); the planning-stage baseline is **exactly one failure — check 2, `spec.md not found`** (the spec is written just-in-time by the plan skill); any other failure is the planner's to fix before the commit.
- [ ] Step 2: In the single-issue artifact paragraph, add one sentence applying the same pre-commit validator run to the standalone ticket, referencing the milestone step's baseline instead of restating it.
- [ ] Step 3: Verify: `grep -n "validate-spec.sh" .agents/skills/sw-brainstorm/SKILL.md` hits both sections; the baseline sentence names check 2 and `spec.md not found` exactly once in the file.
- [ ] Step 4: Commit `fix(brainstorm): run validate-spec.sh on every ticket before committing`.

### Task 4: State-once rule for hard constraints in tickets

**AC:** AC-4
**Delegable:** no — same file as Task 1.
**Files:**
- Modify: `.agents/skills/sw-brainstorm/SKILL.md` ("Writing acceptance criteria" section)

- [ ] Step 1: Add a bullet to "Writing acceptance criteria (the loop's exit condition)": state a hard constraint **once** — in the criterion (or Non-Goal) that owns it — and reference it from anywhere else that needs it; every restatement is an amendment hazard when scope changes.
- [ ] Step 2: Verify: `grep -n "amendment hazard" .agents/skills/sw-brainstorm/SKILL.md` hits the new bullet.
- [ ] Step 3: Commit `fix(brainstorm): state a hard constraint once — restatements are amendment hazards`.

## Phase 2: Propagate the skill copies

### Task 5: Sync the three shipped brainstorm copies

**AC:** AC-6
**Delegable:** no — mechanical propagation of Phase 1's result.
**Files:**
- Modify: `plugins/sw/skills/brainstorm/SKILL.md`
- Modify: `skills/sw/scaffold/skills/sw-brainstorm/SKILL.md`

- [ ] Step 1: `cp .agents/skills/sw-brainstorm/SKILL.md skills/sw/scaffold/skills/sw-brainstorm/SKILL.md` and `cp` to `plugins/sw/skills/brainstorm/SKILL.md`, then restore the plugin copy's frontmatter to `name: brainstorm`.
- [ ] Step 2: Verify: `diff .agents/skills/sw-brainstorm/SKILL.md skills/sw/scaffold/skills/sw-brainstorm/SKILL.md` exits 0; `diff .agents/skills/sw-brainstorm/SKILL.md plugins/sw/skills/brainstorm/SKILL.md` shows exactly the one `name:` hunk.
- [ ] Step 3: Commit `fix(brainstorm): propagate skill contract to plugin and scaffold copies`.

## Phase 3: Reference and templates

### Task 6: vault-files.md carve-out for evidence-consuming issues

**AC:** AC-5
**Delegable:** yes — "add the evidence-consuming-issue carve-out to skills/sw/references/vault-files.md per dossier 3.5: plain-text sibling paths allowed, link syntax still banned" (owner runs it inline anyway).
**Files:**
- Modify: `skills/sw/references/vault-files.md`

- [ ] Step 1: In the "Issues are self-contained" paragraph (standalone-issues section), add the carve-out: **evidence-consuming issues** — work whose job is to audit, validate, or consolidate sibling issues — may cite sibling-issue paths as **plain text**; link syntax remains banned.
- [ ] Step 2: In the Bare-filename-rule section, add a one-line reference to the carve-out (no restatement).
- [ ] Step 3: Verify: `grep -n "evidence-consuming" skills/sw/references/vault-files.md` hits both sections; the phrase "link syntax remains banned" (or equivalent ban) survives.
- [ ] Step 4: Commit `fix(vault): evidence-consuming issues may cite sibling paths as plain text`.

### Task 7: Template hints — goal.md behavior terms, issue.md state-once

**AC:** AC-1, AC-4
**Delegable:** yes — "add one guidance line each to skills/sw/scaffold/templates/goal.md (Success Criteria in behavior terms, no paths/functions/formats) and issue.md (state a hard constraint once)" (owner runs it inline anyway).
**Files:**
- Modify: `skills/sw/scaffold/templates/goal.md`
- Modify: `skills/sw/scaffold/templates/issue.md`

- [ ] Step 1: In `goal.md`'s Success Criteria placeholder, extend the hint: behavior terms only — no file paths, function names, or storage formats; path-level constraints belong in the issue tickets.
- [ ] Step 2: In `issue.md`'s Acceptance Criteria preamble, add one sentence: state a hard constraint once — in the criterion that owns it — and reference it elsewhere; every restatement is an amendment hazard.
- [ ] Step 3: Verify: `grep -n "behavior terms" skills/sw/scaffold/templates/goal.md` and `grep -n "amendment hazard" skills/sw/scaffold/templates/issue.md` each hit; no new double-brace openers outside existing placeholders.
- [ ] Step 4: Commit `fix(templates): behavior-terms goal hint and state-once ticket rule`.

## Phase 4: Gates and delivery

### Task 8: Quality gate and runtime verification

**AC:** AC-1, AC-2, AC-3, AC-4, AC-5, AC-6
**Delegable:** no — the owner runs the gates.
**Files:**
- Test: `tests/install/run.sh` (repo suite, run as-is)

- [ ] Step 1: Run the repo's test suite — `bash tests/install/run.sh` — expecting all PASS lines and exit 0; nothing may break.
- [ ] Step 2: Runtime-verify each AC against the shipped files: AC-1/AC-2/AC-3/AC-4 by reading the exact contract text in all three brainstorm copies; AC-5 by reading `vault-files.md`; AC-6 by the two `diff` commands (only the `name:` hunk differs). For AC-2, additionally run `skills/sw/scripts/validate-spec.sh` against a scratch ticket folder written per the template to observe the check-2-only baseline the new rule describes.
- [ ] Step 3: Tick the verified `AC-N` boxes in `issue.md`; commit `chore(issue): verification results for brainstorm-and-templates`.
