---
feature: command-surface-and-artifacts
created: 2026-08-07
scope: complex
branch: refactor/command-surface-and-artifacts
worktree: null
delivery: null
---
# Command Surface and Artifacts — Tasks

**Proposal:** `proposal.md` holds the *why* and the `AC-N`. **Design:** `design.md` holds the architecture.

Task order in the document is execution order. The checkboxes are the resume
state: `sw:implement` continues at the first unticked box.

## Phase 1: Remove sw:pr

### T1: Delete the pr skill and its command

**AC:** AC-1
**Files:**
- Delete: `plugins/sw/skills/pr/SKILL.md`
- Delete: `plugins/sw/commands/pr.md`
- Modify: `plugins/sw/skills/ship/SKILL.md`
- Modify: `plugins/sw/references/vault-files.md`
**Validation:** `test ! -e plugins/sw/skills/pr && test ! -e plugins/sw/commands/pr.md`

- [ ] Remove both paths with `git rm -r`
- [ ] In `ship/SKILL.md`, drop step 4, renumber `review` to 4, and change the opening promise from a pull request to a reviewed branch
- [ ] In `vault-files.md`, drop the `pr.md` line from the change-folder listing
- [ ] Commit

### T2: Move the branch-safety gate into implement

**AC:** AC-2
**Files:**
- Modify: `plugins/sw/skills/implement/SKILL.md`
**Validation:** `grep -q 'branch --show-current' plugins/sw/skills/implement/SKILL.md`

- [ ] Add a gate section that runs `git branch --show-current` before the first commit and stops when the branch is `main` or `master`
- [ ] Replace the two `sw:pr` references: the verification record goes in the change ticket, and the next command is `/sw:review`
- [ ] Commit

## Phase 2: Remove the conventions directory

### T3: Move the repository conventions out of the vault

**AC:** AC-3
**Files:**
- Create: `docs/conventions/skill-validation-requirements.md`
- Create: `docs/conventions/verbatim-evidence.md`
- Delete: `.specwright/conventions/README.md`
- Modify: `AGENTS.md`
**Validation:** `test -f docs/conventions/verbatim-evidence.md && test ! -e .specwright/conventions`

- [ ] `git mv` both convention files into `docs/conventions/`, delete the signpost, remove the empty directory
- [ ] Add one `## Conventions` section to `AGENTS.md` linking both files
- [ ] Commit

### T4: Stop scaffolding and reading the vault conventions directory

**AC:** AC-4, AC-3
**Files:**
- Modify: `plugins/sw/scripts/sw_init.py`
- Modify: `plugins/sw/skills/review/SKILL.md`
- Modify: `plugins/sw/skills/init/SKILL.md`
- Modify: `plugins/sw/skills/delivery/SKILL.md`
- Modify: `plugins/sw/agents/reviewer.md`
- Modify: `plugins/sw/templates/codex-agents/sw-reviewer.toml`
- Modify: `plugins/sw/references/vault-files.md`
- Modify: `plugins/sw/references/validation.md`
- Modify: `tests/install/run.sh`
**Validation:** `! grep -rqn '\.specwright/conventions' plugins tests README.md AGENTS.md`

- [ ] Drop `CONVENTIONS_SIGNPOST` and its scaffolding branch from `sw_init.py`, and update `SECTION` to stop naming `conventions/`
- [ ] Point every reviewer-facing reference at the canonical AGENTS `## Conventions` section and its links
- [ ] Drop the conventions assertions from `assert_vault` in `tests/install/run.sh`
- [ ] Run `python3 plugins/sw/scripts/sw_init.py --project "$(mktemp -d)" --mode shared --format json` and confirm no `conventions` path appears
- [ ] Commit

## Phase 3: Add sw:archive

### T5: Write the archive skill and its command redirect

**AC:** AC-9, AC-6
**Files:**
- Create: `plugins/sw/skills/archive/SKILL.md`
- Create: `plugins/sw/commands/archive.md`
**Validation:** `grep -q 'merge-base --is-ancestor' plugins/sw/skills/archive/SKILL.md && ! grep -qE '\bgh ' plugins/sw/skills/archive/SKILL.md`

- [ ] Write `SKILL.md` with `name: archive`, `user-invocable: false`, a description that states when it is invoked, and the two steps: confirm the merge with `git merge-base --is-ancestor` on a folder already at `status: shipped`, then `git mv` it under `changes/archive/YYYY-MM-DD-<slug>/`
- [ ] Write the thin command redirect matching the other seven
- [ ] Commit

## Phase 4: Rename and split the artifacts

### T6: Rename the templates and split the plan

**AC:** AC-5
**Files:**
- Delete: `plugins/sw/templates/change.md`
- Delete: `plugins/sw/templates/plan.md`
- Create: `plugins/sw/templates/proposal.md`
- Create: `plugins/sw/templates/design.md`
- Create: `plugins/sw/templates/tasks.md`
**Validation:** `ls plugins/sw/templates | tr '\n' ' ' | grep -qx 'codex-agents delivery.md design.md proposal.md tasks.md '`

- [ ] `git mv templates/change.md templates/proposal.md` and retitle it
- [ ] Split `templates/plan.md`: architecture sections into `design.md` (frontmatter `feature` only), the task checklist into `tasks.md` (frontmatter `feature`, `created`, `scope`, `branch`, `worktree`, `delivery`)
- [ ] State in `tasks.md` that `scope: low` means no `design.md`, and any other value requires one
- [ ] Commit

### T7: Rename the change skill and command to propose

**AC:** AC-6
**Files:**
- Delete: `plugins/sw/skills/change/SKILL.md`
- Delete: `plugins/sw/commands/change.md`
- Create: `plugins/sw/skills/propose/SKILL.md`
- Create: `plugins/sw/commands/propose.md`
**Validation:** `test -f plugins/sw/skills/propose/SKILL.md && test ! -e plugins/sw/skills/change`

- [ ] `git mv` both paths, set `name: propose`, and update every trigger phrase and template reference in the body
- [ ] Commit

### T8: Teach the validator the new names and enforce scope

**AC:** AC-7, AC-8
**Files:**
- Modify: `plugins/sw/scripts/validate-change.sh`
**Validation:** `bash plugins/sw/scripts/validate-change.sh plugins/sw/scripts/fixtures/ready`

- [ ] Rename the `change`/`plan` path variables to `proposal.md` and `tasks.md` throughout, keeping checks 1–6 and their messages otherwise intact
- [ ] Add check 7: a `scope:` other than `low` requires a sibling `design.md`, reported as `FAIL (check 7)` naming `design.md`
- [ ] Update the header comment block to describe seven checks
- [ ] Commit

### T9: Migrate the validator fixtures

**AC:** AC-7
**Files:**
- Modify: `plugins/sw/scripts/fixtures/ready/change.md`
- Modify: `plugins/sw/scripts/fixtures/bad-placeholder/change.md`
- Modify: `plugins/sw/scripts/fixtures/bad-task-metadata/change.md`
- Modify: `plugins/sw/scripts/fixtures/bad-unref-ac/change.md`
- Modify: `plugins/sw/scripts/fixtures/bad-vague-verb/change.md`
- Modify: `plugins/sw/scripts/fixtures/missing-status/change.md`
- Modify: `tests/validate-change/run.sh`
**Validation:** `bash tests/validate-change/run.sh`

- [ ] `git mv` every fixture's `change.md` to `proposal.md` and `plan.md` to `tasks.md`
- [ ] Set every fixture's `scope:` to `low` so no fixture needs a `design.md`
- [ ] Update the file names, the `sed` targets, and the expected messages in `tests/validate-change/run.sh`
- [ ] Add a case asserting check 7 fires for `scope: medium` with no `design.md`
- [ ] Commit

### T10: Sweep the remaining skills, roles, and references

**AC:** AC-6
**Files:**
- Modify: `plugins/sw/skills/plan/SKILL.md`
- Modify: `plugins/sw/skills/implement/SKILL.md`
- Modify: `plugins/sw/skills/ship/SKILL.md`
- Modify: `plugins/sw/skills/review/SKILL.md`
- Modify: `plugins/sw/skills/init/SKILL.md`
- Modify: `plugins/sw/skills/delivery/SKILL.md`
- Modify: `plugins/sw/agents/change-owner.md`
- Modify: `plugins/sw/templates/codex-agents/sw-change-owner.toml`
- Modify: `plugins/sw/references/vault-files.md`
- Modify: `plugins/sw/references/validation.md`
**Validation:** `! grep -rqnE 'change\.md|plan\.md|/sw:change' plugins`

- [ ] Replace every `change.md` with `proposal.md` and every `plan.md` with `design.md` or `tasks.md` as the sentence requires
- [ ] In `plan/SKILL.md`, write both files and make the `scope:` decision explicit, skipping `design.md` at `low`
- [ ] Replace every `/sw:change` and `$sw:change` with the propose form
- [ ] Commit

## Phase 5: Documentation and the gate

### T11: Sweep the root documents and manifests

**AC:** AC-1, AC-3
**Files:**
- Modify: `README.md`
- Modify: `AGENTS.md`
- Modify: `plugins/sw/.claude-plugin/plugin.json`
- Modify: `plugins/sw/.codex-plugin/plugin.json`
**Validation:** `! grep -rqniE 'sw:pr|\.specwright/conventions' README.md AGENTS.md plugins`

- [ ] Update the ladder diagram, the command table, the artifact tree, the layout tree, and the customize section in `README.md`
- [ ] Update the ladder step count, the artifact sentence, and the vault description in `AGENTS.md`
- [ ] Update both manifest descriptions to list the current commands
- [ ] Commit

### T12: Run the full gate and verify every criterion

**AC:** AC-10
**Files:**
- Modify: `.specwright/changes/2026-08-07-command-surface-and-artifacts/proposal.md`
**Validation:** `bash tests/validate-change/run.sh && bash tests/install/run.sh`

- [ ] Run `bash tests/validate-change/run.sh` and require `ALL PASS`
- [ ] Run `bash tests/install/run.sh` and require `ALL PASS`
- [ ] Run `bash tests/release/run.sh` and require the eight-skill inventory line
- [ ] Run `claude plugin validate --strict plugins/sw`
- [ ] Run `bash plugins/sw/scripts/validate-change.sh` on this change folder
- [ ] Tick every verified `AC-N` in `proposal.md` and set `status: shipped`
- [ ] Commit
