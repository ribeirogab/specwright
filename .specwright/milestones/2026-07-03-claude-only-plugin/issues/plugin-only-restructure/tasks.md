---
feature: plugin-only-restructure
created: 2026-07-03
---
# Plugin-only Restructure — Tasks

**For this issue:** see the sibling `issue.md` (acceptance criteria) and `spec.md` (technical plan).

> Each task names the `AC:` (acceptance criteria from `issue.md` it satisfies — every `AC-N` must be referenced by at least one task) and `Delegable:` (whether it suits an isolated task worker, and the one-line context that worker would receive). Workers report findings back to the issue owner; only the owner writes `learnings.md`.

## Phase 1: Move shared assets into plugins/sw/

### Task 1: Move the five artifact templates

**AC:** AC-1
**Delegable:** no (small, sequential with later deletion)
**Files:**
- Create (via `git mv`): `plugins/sw/templates/issue.md`, `plugins/sw/templates/spec.md`, `plugins/sw/templates/tasks.md`, `plugins/sw/templates/goal.md`, `plugins/sw/templates/board.md`
- Delete (source of the move): `skills/sw/scaffold/templates/{issue,spec,tasks,goal,board}.md`

- [ ] Step 1: `mkdir -p plugins/sw/templates`
- [ ] Step 2: `git mv skills/sw/scaffold/templates/issue.md plugins/sw/templates/issue.md` (repeat for spec.md, tasks.md, goal.md, board.md)
- [ ] Step 3: Verify: `ls plugins/sw/templates/` shows exactly 5 files; `git status` shows renames, not add+delete
- [ ] Step 4: Commit — `refactor(plugin): move artifact templates into plugins/sw/`

### Task 2: Move the validator, its fixtures, and the scaffolder's vendored scripts

**AC:** AC-1
**Delegable:** no
**Files:**
- Create (via `git mv`): `plugins/sw/scripts/validate-spec.sh`, `plugins/sw/scripts/fixtures/**`, `plugins/sw/scripts/__init__.py`, `plugins/sw/scripts/package_skill.py`, `plugins/sw/scripts/quick_validate.py`
- Delete (source): `skills/sw/scripts/**`

- [ ] Step 1: `mkdir -p plugins/sw/scripts`
- [ ] Step 2: `git mv skills/sw/scripts/validate-spec.sh plugins/sw/scripts/validate-spec.sh`
- [ ] Step 3: `git mv skills/sw/scripts/fixtures plugins/sw/scripts/fixtures`
- [ ] Step 4: `git mv skills/sw/scripts/__init__.py plugins/sw/scripts/__init__.py`
- [ ] Step 5: `git mv skills/sw/scripts/package_skill.py plugins/sw/scripts/package_skill.py`
- [ ] Step 6: `git mv skills/sw/scripts/quick_validate.py plugins/sw/scripts/quick_validate.py`
- [ ] Step 7: Verify executable bit survived: `ls -l plugins/sw/scripts/validate-spec.sh` shows `x` bits (was executable before the move)
- [ ] Step 8: Verify: `find plugins/sw/scripts/fixtures -type f | wc -l` equals the pre-move count (`find skills/sw/scripts/fixtures -type f | wc -l` beforehand — expect 18: 6 fixture dirs × 3 files each)
- [ ] Step 9: Commit — `refactor(plugin): move validator, fixtures, and scaffolder scripts into plugins/sw/`

### Task 3: Move the reference docs

**AC:** AC-1
**Delegable:** no
**Files:**
- Create (via `git mv`): `plugins/sw/references/{agents-md-template,audit-checklist,claude-plugin-settings,validation,vault-files}.md`
- Delete (source): `skills/sw/references/*.md`

- [ ] Step 1: `mkdir -p plugins/sw/references`
- [ ] Step 2: `git mv skills/sw/references/agents-md-template.md plugins/sw/references/agents-md-template.md` (repeat for audit-checklist.md, claude-plugin-settings.md, validation.md, vault-files.md)
- [ ] Step 3: Verify: `ls plugins/sw/references/` shows exactly 5 files
- [ ] Step 4: Commit — `refactor(plugin): move reference docs into plugins/sw/`

## Phase 2: Rewire plugin skill/command references to the new paths

### Task 4: Rewire the plan skill's template and validator mentions

**AC:** AC-5
**Delegable:** yes — isolated context: "Edit `plugins/sw/skills/plan/SKILL.md`. Three mentions of old paths need updating to the new single-location model: (1) 'Copy the bundled template (`scaffold/templates/spec.md`, under the installed `sw` skill or `skills/sw/` in the specwright dev repo)' → simplify to point at `plugins/sw/templates/spec.md` (one location now, no dual-phrasing needed); (2) 'Start `tasks.md` from the bundled template (`scaffold/templates/tasks.md`)' → `plugins/sw/templates/tasks.md`; (3) 'Mechanical — `.agents/skills/sw/scripts/validate-spec.sh <issue-folder>` (in the specwright dev repo: `skills/sw/scripts/validate-spec.sh`)' → `plugins/sw/scripts/validate-spec.sh <issue-folder>` (single path, drop the dev-repo parenthetical). Do not change any other wording or behavior in the file."
**Files:**
- Modify: `plugins/sw/skills/plan/SKILL.md` (the "Writing the technical spec" section, the "Bite-sized task granularity" section, and the "Self-review the spec" gates section)

- [ ] Step 1: Edit the spec-template line to reference `plugins/sw/templates/spec.md`
- [ ] Step 2: Edit the tasks-template line to reference `plugins/sw/templates/tasks.md`
- [ ] Step 3: Edit the mechanical-gate line to reference `plugins/sw/scripts/validate-spec.sh <issue-folder>`
- [ ] Step 4: Verify: `grep -n 'scaffold/templates\|\.agents/skills\|skills/sw/scripts' plugins/sw/skills/plan/SKILL.md` returns nothing
- [ ] Step 5: Commit — `refactor(plugin): rewire plan skill to plugins/sw/ paths`

### Task 5: Rewire the spec-document-reviewer prompt and the review-spec command

**AC:** AC-5
**Delegable:** yes — isolated context: "Two files each mention the validator's old path in a comment/prose aside: `plugins/sw/skills/plan/spec-document-reviewer-prompt.md` line 5 says 'the mechanical layer (`.agents/skills/sw/scripts/validate-spec.sh`)' — update to `plugins/sw/scripts/validate-spec.sh`. `plugins/sw/commands/review-spec.md` lines 21-24 show a bash invocation `.agents/skills/sw/scripts/validate-spec.sh <issue-folder>` with a comment '(in the specwright dev repo the script is at skills/sw/scripts/validate-spec.sh)' — update the invocation to `plugins/sw/scripts/validate-spec.sh <issue-folder>` and drop the now-obsolete dev-repo comment (single location now). Do not change any other wording."
**Files:**
- Modify: `plugins/sw/skills/plan/spec-document-reviewer-prompt.md`, `plugins/sw/commands/review-spec.md`

- [ ] Step 1: Edit `spec-document-reviewer-prompt.md`'s validator mention
- [ ] Step 2: Edit `review-spec.md`'s bash block: invocation path + drop the dev-repo comment line
- [ ] Step 3: Verify: `grep -n '\.agents/skills\|skills/sw/scripts' plugins/sw/skills/plan/spec-document-reviewer-prompt.md plugins/sw/commands/review-spec.md` returns nothing
- [ ] Step 4: Commit — `refactor(plugin): rewire review-spec references to plugins/sw/ paths`

### Task 6: Rewire the brainstorm skill's template and validator mentions

**AC:** AC-5
**Delegable:** yes — isolated context: "Edit `plugins/sw/skills/brainstorm/SKILL.md`. Three mentions: (1) single-issue artifact line — 'write `.specwright/issues/YYYY-MM-DD-<slug>/issue.md` from the bundled template (`scaffold/templates/issue.md`, under the installed `sw` skill or `skills/sw/` in the specwright dev repo)' → `plugins/sw/templates/issue.md`; (2) milestone artifacts line — 'write `.specwright/milestones/YYYY-MM-DD-<slug>/` from the bundled templates (`scaffold/templates/`)' → `plugins/sw/templates/`; (3) validator line — 'run the mechanical validator on **each** `issues/<slug>/` folder (`validate-spec.sh`, under `scripts/` of the installed `sw` skill or `skills/sw/scripts/` in the specwright dev repo)' → `plugins/sw/scripts/validate-spec.sh`. Do not change any other wording or the brainstorm flow itself."
**Files:**
- Modify: `plugins/sw/skills/brainstorm/SKILL.md` (Single issue and Milestone "batch and artifacts" sections)

- [ ] Step 1: Edit the single-issue template line
- [ ] Step 2: Edit the milestone templates line
- [ ] Step 3: Edit the validator line
- [ ] Step 4: Verify: `grep -n 'scaffold/templates\|\.agents/skills\|skills/sw/scripts' plugins/sw/skills/brainstorm/SKILL.md` returns nothing
- [ ] Step 5: Commit — `refactor(plugin): rewire brainstorm skill to plugins/sw/ paths`

### Task 7: Move sw-update.sh verbatim; rewire the update skill's 2 direct self-references only

**AC:** AC-2, AC-3
**Delegable:** no (requires judgment on which of the ~18 `.agents/skills`/`scaffold/skills` hits inside `sw-update.sh` are the documented exception vs. an actual dangling reference — keep in the owner's hands)
**Files:**
- Move (`git mv`): `skills/sw/scripts/sw-update.sh` → `plugins/sw/scripts/sw-update.sh` (verbatim, zero logic change)
- Modify: `plugins/sw/skills/update/SKILL.md` (2 direct self-reference path mentions only; the "What is managed" table's companion-skill-sync row is left as-is with an inline note — see spec.md's Constraints)

`sw-update.sh`'s `managed_pairs()` function and its self-test fixtures hard-code an **installed target repo's** local path (`.agents/skills/sw-<name>/SKILL.md`) and the **upstream clone's** path (`<clone>/skills/sw/scaffold/skills/sw-<name>/SKILL.md`) — both are other filesystems, not this repo's own deleted trees. Do NOT edit `managed_pairs()`, `_selftest_apply`, or any of the `$d/lo`/`$d/up` fixture paths inside the script — that is `remove-sw-update`'s redesign, not this task's.

- [ ] Step 1: `git mv skills/sw/scripts/sw-update.sh plugins/sw/scripts/sw-update.sh`
- [ ] Step 2: In `plugins/sw/skills/update/SKILL.md`, replace the 2 direct self-reference mentions — `.agents/skills/sw/scripts/sw-update.sh` (the run/record command examples) → `plugins/sw/scripts/sw-update.sh`, and `.agents/skills/sw/.update-manifest.json` (the manifest baseline mention) → `plugins/sw/.update-manifest.json`
- [ ] Step 3: Leave the "What is managed" table's companion-skill-sync row (`.agents/skills/sw-<name>/SKILL.md` / `<clone>/skills/sw/scaffold/skills/sw-<name>/SKILL.md`) untouched; add the inline note explaining it describes an installed target repo, not this one (see spec.md Constraints for the exact wording used)
- [ ] Step 4: Run `bash plugins/sw/scripts/sw-update.sh --self-test` — confirm `self-test: PASS` (behavior unchanged by the move)
- [ ] Step 5: Verify: `grep -n '\.agents/skills\|scaffold/skills' plugins/sw/skills/update/SKILL.md` shows only the companion-skill-sync row (expected, documented) — no other hit
- [ ] Step 6: Commit — `refactor(plugin): move sw-update.sh verbatim; rewire update skill's direct self-references`

## Phase 3: Delete the agent-agnostic layer

### Task 8: Delete .agents/ and skills/sw/

**AC:** AC-2
**Delegable:** no (destructive, must run after Phase 1/2 land)
**Files:**
- Delete: `.agents/` (entire tree)
- Delete: `skills/sw/` (entire tree — already emptied of templates/validator/fixtures/references by Phase 1, but its `SKILL.md`, `scaffold/skills/sw-*` companion copies, and `scripts/sw-update.sh` still need removing)

- [ ] Step 1: `git rm -r .agents`
- [ ] Step 2: `git rm -r skills/sw`
- [ ] Step 3: Verify: `find .agents skills/sw 2>&1` reports "No such file or directory" for both
- [ ] Step 4: Commit — `refactor(plugin): delete .agents/ and skills/sw/`

## Phase 4: Sweep for dangling references

### Task 9: Fix install.sh's 4 comment/output .agents/skills strings; document the 2 that must not change

**AC:** AC-3
**Delegable:** no (judgment call documented in spec.md's Constraints; keep in the owner's hands)
**Files:**
- Modify: `install.sh` (comments and one `say` output string only; `CANONICAL`/`LINK` variable *values*, the `ln -s` target, and all logic stay identical)

`grep -n '\.agents/skills' install.sh` currently returns 6 lines. 4 are comments/output text (reword these); 2 are executable code naming the end-user-machine target path (leave these — see spec.md's Constraints for why).

- [ ] Step 1: Reword the header comment (lines 7-8) and the `CANONICAL` comment (line 24) so the literal substring `.agents/skills` no longer appears verbatim (e.g. describe it as "the skills CLI's agent-agnostic canonical path, `.agents` + `/skills/<name>`" or similar phrasing broken across the sentence) — no change to any variable or command
- [ ] Step 2: Reword the `print_next_steps` say line (124) showing `${LINK} -> ../../.agents/skills/${SKILL}` the same way
- [ ] Step 3: Leave line 26 (`CANONICAL=".agents/skills/${SKILL}"`) and line 153 (`ln -s "../../.agents/skills/${SKILL}" "${LINK}"`) untouched — these are real behavior, not prose
- [ ] Step 4: Run `bash tests/install/run.sh` — confirm `ALL PASS` (behavior unchanged)
- [ ] Step 5: Verify: `grep -n '\.agents/skills' install.sh` returns exactly 2 lines (26 and 153) — this is the expected, documented residue, not a defect
- [ ] Step 6: Commit — `refactor(plugin): reword install.sh comments to avoid stale path string`

### Task 10: Fix AGENTS.md's dangling references

**AC:** AC-3, AC-5
**Delegable:** no (touches the repo's own entry-point doc; keep path-focused per the issue's Non-Goals)
**Files:**
- Modify: `AGENTS.md` (the "Non-Claude agents read canonical copies under `.agents/skills/sw-<name>/`" sentence in the Skills-and-commands intro; the "Editing the bundled skills" paragraph at the end)

- [ ] Step 1: Replace "Commands + companion skills ship through the `sw` plugin (marketplace `specwright`, in this repo's `.claude/settings.json`). Non-Claude agents read canonical copies under `.agents/skills/sw-<name>/`." with a version that drops the now-false second sentence (e.g. "Commands + companion skills ship through the `sw` plugin (marketplace `specwright`, in this repo's `.claude/settings.json`).")
- [ ] Step 2: Replace the "Editing the bundled skills" paragraph describing three copies with one describing the single-copy model: each companion skill's `SKILL.md` lives once, under `plugins/sw/skills/<name>/`; templates live at `plugins/sw/templates/`; the validator at `plugins/sw/scripts/validate-spec.sh`; reference docs at `plugins/sw/references/`
- [ ] Step 3: Verify: `grep -n '\.agents/skills\|scaffold/skills' AGENTS.md` returns nothing; `wc -l AGENTS.md` still ≤ 80 lines (the review skill's cap)
- [ ] Step 4: Commit — `docs(agents): update bundled-skills paragraph for the single plugins/sw/ copy`

### Task 11: Fix README.md, NOTICE.md, CONTRIBUTING.md, SECURITY.md, and the PR template's dangling references

**AC:** AC-3, AC-5
**Delegable:** yes — isolated context: "Five files reference paths this issue deletes. Per this issue's Non-Goals, do NOT rewrite surrounding install-flow/customization prose (that is `docs-and-install-flow`'s job) — only replace each literal dangling path with its `plugins/sw/` equivalent, or trim a clause naming a concept that no longer exists (e.g. the per-non-Claude-agent copy), keeping every other word as-is.

1. `README.md` — fix: the install-summary line naming `.agents/skills/sw/`; `[`skills/sw/SKILL.md`](skills/sw/SKILL.md)`; the 'three kept-in-sync copies' list (`.agents/skills/sw-<name>/`, `skills/sw/scaffold/skills/sw-<name>/`) — trim to describe the single `plugins/sw/skills/<name>/` copy; the orchestration/issue-flow customization lines naming `skills/sw/scaffold/templates/` and `skills/sw/references/agents-md-template.md` — point at `plugins/sw/templates/` and `plugins/sw/references/agents-md-template.md`; the repository-layout tree's `skills/sw/` row and the sentence below it naming `.agents/`; the license line naming `skills/sw/scripts/`.
2. `NOTICE.md` — the vendored-content table's two `skills/sw/scripts/` mentions → `plugins/sw/scripts/`.
3. `CONTRIBUTING.md` — line 11's `.agents/skills/sw-*/` → `plugins/sw/skills/*/`; line 11's and lines 30/33/36's `skills/sw/scripts/` → `plugins/sw/scripts/`.
4. `SECURITY.md` — line 24's `skills/sw/` and `.agents/skills/sw-*/` → `plugins/sw/`.
5. `.github/PULL_REQUEST_TEMPLATE.md` — the two `skills/sw/scripts/quick_validate.py`/`package_skill.py` commands → `plugins/sw/scripts/...`."
**Files:**
- Modify: `README.md`, `NOTICE.md`, `CONTRIBUTING.md`, `SECURITY.md`, `.github/PULL_REQUEST_TEMPLATE.md`

- [ ] Step 1: Re-run `grep -n '\.agents/skills\|scaffold/skills\|skills/sw/' README.md NOTICE.md CONTRIBUTING.md SECURITY.md .github/PULL_REQUEST_TEMPLATE.md` to get current line numbers
- [ ] Step 2: Fix each hit with the minimal path-focused substitution described above, file by file
- [ ] Step 3: Verify: `grep -n '\.agents/skills\|scaffold/skills' README.md NOTICE.md CONTRIBUTING.md SECURITY.md .github/PULL_REQUEST_TEMPLATE.md` returns nothing
- [ ] Step 4: Commit — `docs: update stale scaffolder paths to plugins/sw/`

### Task 12: Repo-wide sweep and historical-record triage

**AC:** AC-3
**Delegable:** no (final gate, needs judgment on shipped-vs-live)
**Files:**
- Read-only verification task; no new file edits expected beyond what Tasks 9-11 already made, unless the sweep finds something new

- [ ] Step 1: Run `grep -rn '\.agents/skills\|scaffold/skills' .` (repo root, excluding `.git/`)
- [ ] Step 2: For every remaining hit, classify: (a) `install.sh:26` and `install.sh:153`, and every hit inside `plugins/sw/scripts/sw-update.sh` → documented, intentional survivors (end-user-machine / installed-target-repo / upstream-clone paths, see spec.md's Constraints) — expected, not a defect; (b) inside an issue/milestone folder whose own `issue.md` says `status: shipped` → historical record, leave as-is; (c) anywhere else → live reference, must be fixed now
- [ ] Step 3: Fix any category-(c) hit found that wasn't already covered by Tasks 4-11
- [ ] Step 4: Record the final grep output (hit count + file list, annotated survivor/shipped/live) for the PR body's runtime-verification section
- [ ] Step 5: Commit any fixes from Step 3 — `refactor(plugin): fix remaining dangling path references`

## Phase 5: Quality gate and runtime verification

### Task 13: Run the install test suite and confirm no regression

**AC:** AC-1, AC-2, AC-3, AC-4, AC-5
**Delegable:** no
**Files:**
- Verification only: `tests/install/run.sh`

- [ ] Step 1: Run `bash tests/install/run.sh`
- [ ] Step 2: Confirm `ALL PASS` with the same test count as before this issue's changes (no silent drop) — compare against a pre-change run (`git stash` or check out `main`'s copy if needed to get the baseline count)
- [ ] Step 3: If any shell-lint tooling exists for the touched area (check `package.json`/`Makefile`/CI config for `shellcheck` or similar), run it against `install.sh` and `plugins/sw/scripts/validate-spec.sh`
- [ ] Step 4: Record results for the PR body

### Task 14: Runtime-verify AC-1 through AC-5 by observed behavior

**AC:** AC-1, AC-2, AC-3, AC-4, AC-5
**Delegable:** no
**Files:**
- Verification only

- [ ] Step 1: **AC-1** — `find plugins/sw/templates plugins/sw/scripts plugins/sw/references -type f | sort` and confirm: 5 templates, `validate-spec.sh` + `fixtures/` (18 fixture files across 6 dirs) + the 3 vendored scripts + `sw-update.sh`, 5 reference docs — each exactly once
- [ ] Step 2: **AC-2** — `[ ! -e .agents ] && [ ! -e skills/sw ] && echo "both absent"` confirms neither directory exists
- [ ] Step 3: **AC-3** — repo-wide `grep -rn '\.agents/skills\|scaffold/skills' .` (excluding `.git/`) returns only: the two documented `install.sh` survivors (lines 26, 153), the documented hits inside `plugins/sw/scripts/sw-update.sh` and the companion-skill-sync row of `plugins/sw/skills/update/SKILL.md`, plus any shipped-historical hits; zero matches in every other live file (per the scope resolution in spec.md). Tick the AC with the inline note specified in spec.md's Constraints rather than a bare "zero matches" claim
- [ ] Step 4: **AC-4** — `find . -name SKILL.md -path '*brainstorm*' -o -name SKILL.md -path '*plan*' -o -name SKILL.md -path '*pr*' -o -name SKILL.md -path '*review*' -o -name SKILL.md -path '*run*'` (excluding `.git/`) confirms each of the 5 companion skills' `SKILL.md` exists exactly once, under `plugins/sw/skills/`
- [ ] Step 5: **AC-5** — for every path mentioned in `plugins/sw/skills/plan/SKILL.md` and `plugins/sw/skills/brainstorm/SKILL.md` (the 3+3 rewired in Tasks 4/6, plus Task 5's), run `[ -f <path> ] && echo OK` for each and confirm all resolve
- [ ] Step 6: Tick `[x]` on each AC in `issue.md` that was actually observed above; mark `needs-human-verification` with a reason for any that couldn't be checked this way (expect none — all 5 are file-existence/grep checks doable in this environment)
- [ ] Step 7: Commit — `docs(issue): tick verified acceptance criteria`

## Phase 6: Delivery

### Task 15: Open the PR

**AC:** (delivery step, not tied to a single AC)
**Delegable:** no

- [ ] Step 1: Push `refactor/plugin-only-restructure`
- [ ] Step 2: Open PR against `main` via `gh`, Conventional-Commit title, body notes it stacks on `claude/nostalgic-engelbart-617af3`
- [ ] Step 3: Fill the PR body's quality-gate section (Tasks 13-14 results) and the three plan self-review gates (mechanical validator, spec-document-reviewer, review-spec) with their outcomes

### Task 16: Review to lgtm

**AC:** (delivery step)
**Delegable:** no

- [ ] Step 1: Run the sw-review pipeline (3 lanes: rubric+conventions, issue-conformance, documentation-consistency) — reviewer sub-agents on Opus 4.8 at xhigh effort per board conduction policy
- [ ] Step 2: Fix any blocker, re-request review, loop to `lgtm`

### Task 17: Learnings and ship

**AC:** (delivery step)
**Delegable:** no

- [ ] Step 1: Write `learnings.md` — final locations of templates/validator/references, the AC-3 shipped-historical scope resolution, the `install.sh`/AGENTS.md/README.md minimal-touch precedent
- [ ] Step 2: Set `issue.md` frontmatter `status: shipped`, `shipped: 2026-07-03`
- [ ] Step 3: Commit
