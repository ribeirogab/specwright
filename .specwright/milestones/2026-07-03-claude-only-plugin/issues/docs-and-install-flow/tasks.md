---
feature: docs-and-install-flow
created: 2026-07-03
---
# Docs and Install Flow — Tasks

**For this issue:** see the sibling `issue.md` (acceptance criteria) and `spec.md` (technical plan).

> Each task names the `AC:` (acceptance criteria from `issue.md` it satisfies — every `AC-N` must be referenced by at least one task) and `Delegable:` (whether it suits an isolated task worker, and the one-line context that worker would receive). Workers report findings back to the issue owner; only the owner writes `learnings.md`.

## Phase 1: Delete the installer

### Task 1: Remove `install.sh`

**AC:** AC-1
**Delegable:** no (trivial, one command)

- [ ] Step 1: `git rm install.sh`
- [ ] Step 2: `ls install.sh` → confirm `No such file or directory`
- [ ] Step 3: Commit — `chore: remove the standalone install.sh`

## Phase 2: Converge the entry-point document to `CLAUDE.md`

### Task 2: Rename `AGENTS.md` to `CLAUDE.md` and drop the symlink

**AC:** AC-3
**Delegable:** no (touches the repo's own entry point, sequenced before README edits that reference it)

- [ ] Step 1: `git rm CLAUDE.md` (removes the existing symlink)
- [ ] Step 2: `git mv AGENTS.md CLAUDE.md`
- [ ] Step 3: `ls -la CLAUDE.md` → confirm it is a regular file, not a symlink (`file CLAUDE.md` should not say "symbolic link")
- [ ] Step 4: `grep -n "AGENTS.md" CLAUDE.md` → confirm no self-reference to the old filename survives inside the file's own prose
- [ ] Step 5: Commit — `docs: converge the entry-point document to CLAUDE.md`

### Task 3: Fix the command list inside `CLAUDE.md`

**AC:** AC-4
**Delegable:** no (small, sequenced right after Task 2)

- [ ] Step 1: In `CLAUDE.md`'s "Skills and slash commands" list, remove the `sw:update` bullet.
- [ ] Step 2: Add an `sw:init` bullet, placed first in the list (it runs before any workflow step).
- [ ] Step 3: `grep -n "sw:update" CLAUDE.md` → no match. `grep -n "sw:init" CLAUDE.md` → one match.
- [ ] Step 4: Commit — `docs: list /sw:init and drop /sw:update from CLAUDE.md`

## Phase 3: Rewrite `README.md`

### Task 4: Rewrite the Install section

**AC:** AC-2
**Delegable:** yes — worker receives: "Replace README.md's Install section (currently a curl-piped install.sh block) with the two-command plugin install (claude plugin marketplace add ribeirogab/specwright, claude plugin install sw@specwright) followed by running /sw:init in the target repo. No curl/shell install instruction may remain. Read plugins/sw/skills/init/SKILL.md for what /sw:init actually does, to describe it accurately."

- [ ] Step 1: Replace the curl-piped code block and its explanatory bullets with the two `claude plugin` commands.
- [ ] Step 2: Add one sentence: after the plugin is installed once, globally, running `/sw:init` in any repo scaffolds the `.specwright/` vault and the `CLAUDE.md` entry point.
- [ ] Step 3: `grep -in "curl" README.md` → no match. `grep -n "install.sh" README.md` → no match.
- [ ] Step 4: Commit — `docs: document the plugin-based install flow in README`

### Task 5: Fix the "What you get" table and prose

**AC:** AC-2, AC-4
**Delegable:** yes — worker receives: "In README.md's 'What you get' section: the command table lists /sw:update — remove that row and add a /sw:init row describing it as scaffolding the .specwright/ vault and CLAUDE.md entry point, idempotent. The prose above the table says 'an AGENTS.md describing the issue-driven workflow' — change to 'a CLAUDE.md'."

- [ ] Step 1: Add the `/sw:init` row to the command table; remove the `/sw:update` row.
- [ ] Step 2: Change "an `AGENTS.md`" to "a `CLAUDE.md`" in the bullet list above the table.
- [ ] Step 3: `grep -in "sw:update" README.md` → no match. `grep -n "AGENTS.md" README.md` → no match in this section.
- [ ] Step 4: Commit — `docs: refresh README's command table and vault-output description`

### Task 6: Fix the Customizing section's stale template reference

**AC:** AC-5
**Delegable:** no (requires cross-checking current skill behavior, sequenced)

- [ ] Step 1: In the "Customizing" section's "The issue-flow steps" bullet, change the referenced template filename from the old pre-rename name to the current `claude-md-template.md`.
- [ ] Step 2: Re-read `plugins/sw/skills/init/SKILL.md` Step 2 — `/sw:init` only appends a short plugin-requirement block to an existing `CLAUDE.md`, or generates the full template when none exists; it does not template a live "Issue flow" section into an existing file the way the old sentence implies. Rewrite the bullet to describe this accurately: editing the repo's own `CLAUDE.md` changes this repo's steps; editing the reference template changes what a brand-new `/sw:init` run generates for repos with no existing `CLAUDE.md`.
- [ ] Step 3: `grep -rn "agents-md-template" README.md` → no match.
- [ ] Step 4: Commit — `docs: fix the stale template filename in README's Customizing section`

### Task 7: Fix the Repository layout tree and closing sentence

**AC:** AC-1, AC-3, AC-5
**Delegable:** no (small, mechanical)

- [ ] Step 1: Remove the `install.sh` line from the repository-layout tree block.
- [ ] Step 2: Change the closing sentence naming "`AGENTS.md` (with its `CLAUDE.md` symlink)" to name only "`CLAUDE.md`" — drop the symlink parenthetical.
- [ ] Step 3: `grep -n "install.sh" README.md` → no match. `grep -in "symlink" README.md` → no match.
- [ ] Step 4: Commit — `docs: drop install.sh and the CLAUDE.md symlink from README's layout`

### Task 8: Drop the "agent-agnostic" claim from the top pitch line

**AC:** AC-3
**Delegable:** yes — worker receives: "README.md's opening paragraph ends with a sentence claiming the workflow is agent-agnostic. Remove that claim from the sentence — the milestone's non-goal is dropping non-Claude-agent support, so the pitch must not claim it. Keep the rest of the sentence (e.g. self-hosting) intact."

- [ ] Step 1: Edit the opening paragraph's last sentence.
- [ ] Step 2: `grep -in "agent-agnostic" README.md` → no match.
- [ ] Step 3: Commit — `docs: drop the agent-agnostic claim from README's pitch`

## Phase 4: Sweep the three extra-scope findings

### Task 9: Fix `.github/ISSUE_TEMPLATE/bug.md`

**AC:** AC-4 (companion-list sweep, carried scope)
**Delegable:** yes — worker receives: "In .github/ISSUE_TEMPLATE/bug.md's 'Component affected' section, the companion list still names the retired sw-update companion. Replace the parenthetical list with the current six companions: sw-init, sw-brainstorm, sw-plan, sw-pr, sw-review, sw-run."

- [ ] Step 1: Update the parenthetical companion list.
- [ ] Step 2: `grep -n "sw-update" .github/ISSUE_TEMPLATE/bug.md` → no match.
- [ ] Step 3: Commit — `docs: refresh the companion list in the bug report template`

### Task 10: Fix `.github/ISSUE_TEMPLATE/feature_request.md`

**AC:** AC-4 (companion-list sweep, carried scope)
**Delegable:** yes — worker receives: "In .github/ISSUE_TEMPLATE/feature_request.md's 'What should specwright do?' section, the companion list still names the retired sw-update companion. Replace the parenthetical list with the current six companions: sw-init, sw-brainstorm, sw-plan, sw-pr, sw-review, sw-run."

- [ ] Step 1: Update the parenthetical companion list.
- [ ] Step 2: `grep -n "sw-update" .github/ISSUE_TEMPLATE/feature_request.md` → no match.
- [ ] Step 3: Commit — `docs: refresh the companion list in the feature request template`

### Task 11: Fix `plugins/sw/references/vault-files.md`'s two stale paths

**AC:** AC-5 (carried scope — path drift flagged by `rewrite-sw-init`)
**Delegable:** yes — worker receives: "plugins/sw/references/vault-files.md's 'What does not live in the vault' bullets describe the templates and the validator script as shipping at old scaffold-era paths. Confirm the real current paths with ls plugins/sw/templates/ and ls plugins/sw/scripts/, then correct both bullets to the current plugins/sw/ locations."

- [ ] Step 1: `ls plugins/sw/templates/` and `ls plugins/sw/scripts/` to confirm current paths.
- [ ] Step 2: Correct both bullets in `vault-files.md`.
- [ ] Step 3: `grep -n "scaffold/templates\|scaffold/scripts" plugins/sw/references/vault-files.md` → no match.
- [ ] Step 4: Commit — `docs: fix stale scaffold paths in vault-files.md`

### Task 12: Fix `.claude-plugin/marketplace.json`'s companion list

**AC:** AC-4 (consistency with the entry-point/README fix, same live-doc surface)
**Delegable:** no (single-line JSON edit, low risk of parallel conflict)

- [ ] Step 1: Change the `description` string's companion list to drop `/sw:update` and add `/sw:init`.
- [ ] Step 2: `python3 -c "import json; json.load(open('.claude-plugin/marketplace.json'))"` → confirm still valid JSON.
- [ ] Step 3: `grep -n "sw:update" .claude-plugin/marketplace.json` → no match.
- [ ] Step 4: Commit — `chore: drop sw:update and list sw:init in the marketplace description`

### Task 12b: Fix the stale `AGENTS.md` references in three live plugin-behavior files

**AC:** AC-3 (carried scope — flagged by the spec-document-reviewer subagent pass on this issue's own plan)
**Delegable:** no (touches the review skill's own review logic; sequenced, low risk of conflict)

- [ ] Step 1: In `plugins/sw/commands/spec.md` line ~18, change `See \`AGENTS.md\` (\`## Workflow Spec Driven\`).` to name `CLAUDE.md` instead.
- [ ] Step 2: In `plugins/sw/skills/review/SKILL.md`, change every generic `AGENTS.md` mention (the project-specific-standards line, the blocker-calibration line about the 80-line cap, the live-doc-staleness blocker line, the Workflow step 2 line, and Subagent A's description) to `CLAUDE.md`.
- [ ] Step 3: In the same file's Subagent C description, drop the "and the three kept-in-sync copies of any touched companion skill" clause and the "or the 3 skill copies drifting beyond the allowed `name:` line" clause — every companion skill now lives in exactly one copy, so there is nothing to audit for copy drift.
- [ ] Step 4: In `plugins/sw/skills/run/SKILL.md` line ~76, change "promotion into the area `AGENTS.md`" to name `CLAUDE.md` instead.
- [ ] Step 5: `grep -rn "AGENTS.md" plugins/sw/` → no match. `grep -n "kept-in-sync copies\|3 skill copies" plugins/sw/skills/review/SKILL.md` → no match.
- [ ] Step 6: Commit — `docs: point the review/run/spec skills at CLAUDE.md and drop the retired three-copies audit`

## Phase 5: Quality gate — rewrite the install smoke test

### Task 13: Replace `tests/install/run.sh` with a plugin-install smoke test

**AC:** AC-1, AC-2, AC-5 (test integrity: the deleted install.sh's tests cannot survive testing a nonexistent file)
**Delegable:** no (needs judgment about what "meaningful" coverage looks like for the new model)

- [ ] Step 1: Record the current test count for the before/after report: `grep -c 'assert_eq "' tests/install/run.sh` on the pre-edit file.
- [ ] Step 2: Rewrite `tests/install/run.sh` to assert the plugin-only reality: (a) `install.sh` does not exist at repo root; (b) `.claude-plugin/marketplace.json` is valid JSON and its plugin entry's `source` is `./plugins/sw`; (c) `plugins/sw/.claude-plugin/plugin.json` is valid JSON, its `description` contains `init` and does not contain `update`; (d) `plugins/sw/skills/init/SKILL.md` exists and its frontmatter `name:` is `init`; (e) `plugins/sw/skills/update/` does not exist; (f) `plugins/sw/scripts/sw-update.sh` does not exist. Keep the same `pass`/`die`/`assert_eq` harness shape and the `ALL PASS` / `N FAILED` verdict line so any CI invocation keeps working unchanged.
- [ ] Step 3: Run `bash tests/install/run.sh` → expect `ALL PASS` and exit 0.
- [ ] Step 4: Count the new assertions the same way (`grep -c 'assert_eq "' tests/install/run.sh`) for the before/after report.
- [ ] Step 5: Commit — `test: rewrite the install smoke test for the plugin-only install flow`

### Task 14: Run repo-wide lint/format checks if any apply

**AC:** (quality gate, supports all criteria)
**Delegable:** no

- [ ] Step 1: Check for a lint/format config (`ls .markdownlint* .shellcheckrc 2>/dev/null; command -v shellcheck`).
- [ ] Step 2: If `shellcheck` is available, run it against `tests/install/run.sh` and fix any reported issue.
- [ ] Step 3: If no markdown linter is configured, note that in the PR body rather than silently skipping.
- [ ] Step 4: Commit any fixes — `fix: address shellcheck findings in the install smoke test` (only if needed).

## Phase 6: Runtime verification — walk every AC by observed behavior

### Task 15: Verify AC-1 through AC-5

**AC:** AC-1, AC-2, AC-3, AC-4, AC-5
**Delegable:** no (final verification, owner-only)

- [ ] Step 1 (AC-1): `[ -f install.sh ] && echo FOUND || echo ABSENT` → expect `ABSENT`.
- [ ] Step 2 (AC-2): `grep -n "claude plugin marketplace add ribeirogab/specwright\|claude plugin install sw@specwright\|/sw:init" README.md` → both commands and `/sw:init` present; `grep -in "curl.*| *sh" README.md` → no match.
- [ ] Step 3 (AC-3): `grep -in "per-agent symlink\|Codex\|Cursor\|OpenCode\|Aider\|three.copies" README.md CLAUDE.md` and separately check for the literal agents-directory path token → no match in either file.
- [ ] Step 4 (AC-4): `grep -in "sw:update" README.md CLAUDE.md` → no match in either file.
- [ ] Step 5 (AC-5, raw): `grep -rn "install.sh" .` → record the raw count and confirm every hit lives under `.specwright/` (historical issue records) or is this issue's own ticket discussing the deletion.
- [ ] Step 6 (AC-5, scoped): `grep -rn "install.sh" . --exclude-dir=.specwright --exclude-dir=.git` → expect zero matches.
- [ ] Step 7: Tick each verified `[x]` in `issue.md`; if any check cannot be observed, mark it `needs-human-verification` with the reason instead.
- [ ] Step 8: Commit — `docs: tick verified acceptance criteria in issue.md`

## Phase 7: Deliver

### Task 16: Open the PR

**AC:** (delivery step, supports all criteria)
**Delegable:** no

- [ ] Step 1: Push `docs/docs-and-install-flow`.
- [ ] Step 2: Open the PR against `main` via `gh`, Conventional-Commit title, noting it is the final milestone issue stacking on and merging the sibling restructure/init/update-removal issues.
- [ ] Step 3: Record the quality-gate and runtime-verification results in the PR body per the `pr` skill.

### Task 17: Review to `lgtm`

**AC:** (delivery step, supports all criteria)
**Delegable:** no

- [ ] Step 1: Run the `/sw:review` pipeline with reviewer sub-agents on `claude-opus-4-8` at xhigh effort, per the board's conduction policy.
- [ ] Step 2: Fix any blocker; loop until `lgtm`.

### Task 18: Curate learnings and ship

**AC:** (delivery step, supports all criteria)
**Delegable:** no

- [ ] Step 1: Write `learnings.md` — durable facts only (e.g. the AC-5 grep-scoping precedent, the entry-point-document convergence, the marketplace.json fix carried beyond the literal AC wording).
- [ ] Step 2: Set `issue.md` `status: shipped`, `shipped: 2026-07-03`.
- [ ] Step 3: Commit — `docs(docs-and-install-flow): curate learnings and ship`
