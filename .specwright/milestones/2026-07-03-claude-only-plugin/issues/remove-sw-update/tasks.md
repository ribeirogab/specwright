---
feature: remove-sw-update
created: 2026-07-03
---
# Remove sw:update — Tasks

**For this issue:** see the sibling `issue.md` (acceptance criteria) and `spec.md` (technical plan).

## Phase 1: Delete the capability

### Task 1: Delete the update skill directory

**AC:** AC-1
**Delegable:** no (trivial, single `rm -rf`)

- [ ] Step 1: `rm -rf plugins/sw/skills/update/`
- [ ] Step 2: Verify: `[ ! -d plugins/sw/skills/update ]` and `ls plugins/sw/skills/` shows only `brainstorm plan pr review run`.
- [ ] Step 3: Commit.

### Task 2: Delete the sw-update.sh script

**AC:** AC-2
**Delegable:** no (trivial, single `rm`)

- [ ] Step 1: `rm plugins/sw/scripts/sw-update.sh`
- [ ] Step 2: Verify: `find . -name 'sw-update.sh'` returns no results anywhere in the repo.
- [ ] Step 3: Commit.

### Task 3: Drop `update` from the plugin manifest enumeration

**AC:** AC-4
**Delegable:** no (single-line edit)

- [ ] Step 1: Edit `plugins/sw/.claude-plugin/plugin.json` — remove `update` from the `description` field's companion-skill list (`brainstorm, plan, run, review, pr, update` → `brainstorm, plan, run, review, pr`).
- [ ] Step 2: Verify: `grep -n update plugins/sw/.claude-plugin/plugin.json` returns no match; `cat plugins/sw/.claude-plugin/plugin.json` still parses as valid JSON (`jq . plugins/sw/.claude-plugin/plugin.json`).
- [ ] Step 3: Commit.

### Task 4: Verify the AC-3 carve-out and run the quality gate

**AC:** AC-3
**Delegable:** no (verification + gate, needs full repo context)

- [ ] Step 1: `grep -rn -E "sw:update|sw-update|/sw:update" plugins/sw/` — confirm every remaining match falls inside exactly `plugins/sw/references/agents-md-template.md`, `plugins/sw/references/validation.md`, `plugins/sw/references/audit-checklist.md` and no other file.
- [ ] Step 2: `grep -rln update tests/install/` — confirm no test references the update skill/script (expected: no matches); if a match appears, update the test meaningfully rather than deleting the assertion.
- [ ] Step 3: Run `bash tests/install/run.sh` and any other relevant lint/tests touched by this change; confirm pass.
- [ ] Step 4: Commit (if any test file changed).

## Phase 2: Self-review and delivery

### Task 5: Self-review, validate, PR, review-to-lgtm

**AC:** AC-1, AC-2, AC-3, AC-4
**Delegable:** no (owner-only pipeline steps)

- [ ] Step 1: Run `bash plugins/sw/scripts/validate-spec.sh .specwright/milestones/2026-07-03-claude-only-plugin/issues/remove-sw-update/` until exit 0.
- [ ] Step 2: Self-review with the spec-document-reviewer prompt + `/sw:review-spec` checklist.
- [ ] Step 3: Runtime-verify AC-1..4 by observed behavior (ls, grep, manifest inspection); tick `issue.md` checkboxes.
- [ ] Step 4: Push branch, open PR against `main` via `gh` (Conventional Commit title), noting the stack on PR #57 and the AC-3 sibling carve-out in the body.
- [ ] Step 5: Run `/sw:review` (reviewer sub-agents on Opus 4.8 at xhigh effort per board policy) until `lgtm`; fix any blockers.
- [ ] Step 6: Curate `learnings.md`; flip `issue.md` `status: shipped` + `shipped: 2026-07-03`; commit.
