---
feature: docs-and-validator
created: 2026-07-02
---
# Docs and Validator — Tasks

**For this issue:** see the sibling `issue.md` (acceptance criteria) and `spec.md` (technical plan).

> Each task names the `AC:` (acceptance criteria from `issue.md` it satisfies — every `AC-N` must be referenced by at least one task) and `Delegable:` (whether it suits an isolated task worker, and the one-line context that worker would receive). Workers report findings back to the issue owner; only the owner writes `learnings.md`.

## Phase 1: Validator exit semantics

### Task 1: Fixtures that pin the exit-code contract

**AC:** AC-1
**Delegable:** no — needs the issue owner's decision on the empty-value semantics.
**Files:**
- Create: `skills/sw/scripts/fixtures/missing-status/{issue.md,spec.md,tasks.md}` — a folder whose only defect is a missing `status:` key (exercises the check-1 single-fire).
- Reuse: existing `fixtures/good`, `fixtures/bad-unref-ac`.

- [ ] Step 1: Write `fixtures/missing-status/` — a valid issue folder with `feature:`/`created:` present but `status:` absent from `issue.md` frontmatter, a valid `spec.md` and `tasks.md`, one `AC-1` referenced by a task. This is the failing case that today double-fires check 1.
- [ ] Step 2: Run the current validator over it: `skills/sw/scripts/validate-spec.sh skills/sw/scripts/fixtures/missing-status; echo "exit: $?"`. Record the observed exit (today: 2, two FAIL lines) as the pre-fix baseline.
- [ ] Step 3: Run it over `fixtures/good` — expect exit 0, `PASS:` line.
- [ ] Step 4: Commit the fixture.

### Task 2: Dedup the failure counter per check + skip enum when key missing

**AC:** AC-1
**Delegable:** no.
**Files:**
- Modify: `skills/sw/scripts/validate-spec.sh` — the `fail()` helper and check-1 body.

- [ ] Step 1: Replace the line-counting `fail()` with a per-check-deduped counter: track which check numbers have already failed (e.g. a space-delimited `failed_checks` string); still `echo` every `FAIL (check N): …` diagnostic line, but increment `fails` only the first time a given check number fails. `fails` then equals the number of distinct failed checks.
- [ ] Step 2: In check 1, when the `status:` key is absent, emit the missing-key FAIL for check 1 and **skip** the enum test (the empty-value FAIL would report the same root defect). When the key is present but the value is empty or not in the enum, emit the enum FAIL. Document in an adjacent comment that empty/missing `status:` is a real defect by deliberate choice (unlike recorded-only `scope:`).
- [ ] Step 3: Run `bash -n skills/sw/scripts/validate-spec.sh` to confirm it parses.
- [ ] Step 4: Run the validator over `fixtures/missing-status` — expect exit **1** and exactly one `FAIL (check 1)` line.
- [ ] Step 5: Run over `fixtures/good` — expect exit 0. Run over `fixtures/bad-unref-ac` (unref AC + any other seeded defect) — expect the exit to equal the count of distinct failed checks.
- [ ] Step 6: Commit.

### Task 3: Rewrite the validator header to match the exit semantics

**AC:** AC-1
**Delegable:** no.
**Files:**
- Modify: `skills/sw/scripts/validate-spec.sh` — the top-of-file comment block (Usage / exit description / Checks).

- [ ] Step 1: Reword the header so it states: exits 0 when every check passes, otherwise exits with the number of **distinct failed checks** (1–5), printing one `FAIL (check N): …` line per failed condition.
- [ ] Step 2: Add the collision note: operational errors (bad usage, missing directory) go to stderr and exit 2 — distinguished from a two-check failure by their `usage:` / `FAIL:` (no `(check N)`) message; any non-zero exit means "not clean".
- [ ] Step 3: In the Checks list, record the deliberate check-1 decision: missing/empty `status:` fails check 1 once; `scope:` (check 2) is allowed to be empty because it is recorded-only.
- [ ] Step 4: Re-run the validator over `fixtures/good`, `fixtures/missing-status`, and this issue's own folder (`.specwright/milestones/2026-07-02-specwright-fixes/issues/docs-and-validator`) — the own-folder run must exit 0.
- [ ] Step 5: Commit.

## Phase 2: Docs reconciliation

### Task 4: Sync the AGENTS.md template Issue flow + the shared AC-5 clause

**AC:** AC-2, AC-5
**Delegable:** no — AC-2 and AC-5 touch the same two lines here (AGENTS.md line 20 / template line 51); doing them together in one owner pass avoids a two-step drift.
**Files:**
- Modify: `skills/sw/references/agents-md-template.md:49-85` (the fenced template body).
- Modify: `AGENTS.md:20` (the inline folder sentence only — AC-5 clause).
- Reference: `AGENTS.md:18-54`.

- [ ] Step 1: Apply the seven AC-2 sync hunks listed in `spec.md` (intro `with AC-N`; step 1 `converse first, decide at the end` + `design approval is the only`; step 3 `curates` + worktree-guard clause; mermaid nodes D and F; coding-standard `standalone issues in`).
- [ ] Step 2: Leave the template's Skills-and-slash-commands intro as `(marketplace specwright)` — do **not** add `in this repo's .claude/settings.json` (the dogfood-only clause).
- [ ] Step 3: Add the AC-5 clause `+ any issue-specific artifacts` (terse form) to the inline folder sentence in **both** `AGENTS.md` line 20 and the template line 51, so the two stay byte-identical modulo the placeholder fill and the settings-path clause.
- [ ] Step 4: Confirm `AGENTS.md` is still ≤ 80 lines (`wc -l AGENTS.md`).
- [ ] Step 5: Diff the template's Issue-flow body against `AGENTS.md`'s to confirm they match modulo the double-brace project-name fill and the settings-path clause: extract both `### Issue flow … ## Skills` ranges and eyeball the diff.
- [ ] Step 6: Commit.

### Task 5: README license sentence names the two Apache-2.0 scripts

**AC:** AC-3
**Delegable:** yes — "In `README.md` `## License`, reword the second sentence to name `quick_validate.py` and `package_skill.py` (under `skills/sw/scripts/`) as the Apache-2.0 portion and keep the `NOTICE.md` link; do not call them the validator."
**Files:**
- Modify: `README.md:115`.

- [ ] Step 1: Replace "The vendored validator scripts under `skills/sw/scripts/` are Apache-2.0; see `NOTICE.md` for attribution." with a sentence naming both helper scripts explicitly as Apache-2.0, pointing to `NOTICE.md`.
- [ ] Step 2: Confirm `NOTICE.md` exists and lists both scripts (it does) so the pointer is accurate.
- [ ] Step 3: Commit.

### Task 6: README repository-layout includes install.sh and tests/

**AC:** AC-4
**Delegable:** yes — "In `README.md` `## Repository layout`, add `install.sh` and `tests/` rows to the tree, and extend the dogfood paragraph below the tree to also name `AGENTS.md`/`CLAUDE.md` as dogfood artifacts."
**Files:**
- Modify: `README.md:96-111`.

- [ ] Step 1: Add an `install.sh` row (one-line: the curl-piped installer) and a `tests/` row (one-line: install smoke tests) to the layout tree, in a sensible position.
- [ ] Step 2: Extend the dogfood paragraph (currently naming `.agents/`, `.claude/`, `.specwright/`) to also name `AGENTS.md` and its `CLAUDE.md` symlink as dogfood artifacts, so the layout section is complete without listing them as install output.
- [ ] Step 3: Confirm every path named in the tree exists at the repo root (`ls` each).
- [ ] Step 4: Commit.

### Task 7: Issue-folder enumerations in vault-files.md and README

**AC:** AC-5
**Delegable:** yes — "In `skills/sw/references/vault-files.md` (both folder-tree code blocks) and `README.md` line ~73 (the inline `one folder — issue.md …` bullet), add a short note that an issue folder may also carry issue-specific artifacts such as `findings.md` or `evidence/`. Edit only the fenced code-block file lists in vault-files.md, not the surrounding prose (the self-containment/carve-out prose is a sibling PR's surface)."
**Files:**
- Modify: `skills/sw/references/vault-files.md` — the `.specwright/issues/` tree (~line 50) and the milestone `issues/<slug>/` tree (~line 72).
- Modify: `README.md:73`.

> The AGENTS.md and template enumerations are handled in Task 4 (coordinated with AC-2). This task covers the remaining two live-doc enumerations.

- [ ] Step 1: In each `vault-files.md` folder-tree code block, add a trailing comment line noting issue-specific artifacts may also be present (e.g. `findings.md`, `evidence/` for validation issues), consistent with the existing `# optional:` comment style. Do not touch the self-containment or bare-filename prose paragraphs.
- [ ] Step 2: In `README.md` line 73, append the same idea to the inline bullet (e.g. "plus any issue-specific artifacts").
- [ ] Step 3: Run `skills/sw/scripts/validate-spec.sh` over this issue folder again — the edits are in other files, but confirm nothing regressed; expect exit 0.
- [ ] Step 4: Commit.

## Phase 3: Quality gate + verification

### Task 8: Full quality gate and runtime verification

**AC:** AC-1, AC-2, AC-3, AC-4, AC-5
**Delegable:** no.
**Files:**
- Read: all modified files.

- [ ] Step 1: `bash -n skills/sw/scripts/validate-spec.sh` and `shellcheck` it if available.
- [ ] Step 2: Run the validator over every fixture folder (`good`, `bad-frontmatter`, `bad-placeholder`, `bad-unref-ac`, `bad-vague-verb`, `missing-status`) and record each exit code; confirm each non-zero exit equals its count of distinct failed checks and `good` exits 0.
- [ ] Step 3: Run `/usr/bin/python3 skills/sw/scripts/quick_validate.py` on any skill that packaging requires, per the repo PR template (validate-spec.sh is not a skill, but confirm no skill regressed).
- [ ] Step 4: Runtime-verify each AC by observed content: AC-1 by the fixture exit codes + header text; AC-2 by the template/AGENTS diff; AC-3/AC-4 by reading the README sections; AC-5 by grepping the two docs for the new note.
- [ ] Step 5: Tick the verified `AC-N` in `issue.md`.
- [ ] Step 6: Commit any residual changes.
