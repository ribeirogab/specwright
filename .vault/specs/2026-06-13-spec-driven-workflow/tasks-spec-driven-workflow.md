---
feature: spec-driven-workflow
plan: "[[plan-spec-driven-workflow]]"
spec: "[[spec-spec-driven-workflow]]"
created: 2026-06-13
---
# Spec-Driven Workflow — Tasks

**For this plan:** `[[plan-spec-driven-workflow]]`

Work on branch `feat/spec-driven-workflow` (created; spec/plan/tasks committed there). No test runner — verification is grep/`wc`/shell + the memex validators. Every phase ends with a Conventional-Commits commit, **no AI-attribution footer**. Mode: **autonomous** — implement straight through, then quality gate, then PR, then the `memex-code-review` cycle to `lgtm`.

---

## Phase 1: Rules consolidation (§D)

### Task 1.1: Create `.vault/rules.md`
- [x] Write `.vault/rules.md` with frontmatter (`status: canonical`, `created: 2026-06-13`) and four H2 sections: `## Philosophy (Unix, ESR)` (17 numbered rules — Modularity…Extensibility, English), `## Git & delivery` (5 rules: Conventional Commits; Explicit Consent in recorded-consent form; Branch Naming; No Attribution; PR via Command `/memex:new-pr`), `## Code` (2 rules: Meaningful Comments; Currency), `## Security` (one-line pointer to `.vault/constitution.md`).
- [x] Verify: `grep -c '^## ' .vault/rules.md` returns `4`; `grep -c '^[0-9]' .vault/rules.md` ≥ `24`.

### Task 1.2: Relocate skill-validation note
- [x] `git mv .vault/rules/skill-validation-requirements.md .vault/conventions/skill-validation-requirements.md`
- [x] Fix the note's internal wikilinks/paths if any point at `../rules/` or assume the rules-dir home.
- [x] Verify: `test -f .vault/conventions/skill-validation-requirements.md && ! test -e .vault/rules/skill-validation-requirements.md`.

### Task 1.3: Remove rules MOC + empty dir
- [x] `git rm .vault/_index/rules.md`
- [x] `rmdir .vault/rules` (must be empty after 1.2).
- [x] Verify: `! test -e .vault/_index/rules.md && ! test -d .vault/rules`.

### Task 1.4: Update home + conventions indexes
- [x] `.vault/_index/home.md`: replace `[[rules|Rules MOC]]` line with a link to `[[../rules|Rules]]` (`.vault/rules.md`); fix the "New rule needed → add to `../rules/`" line to reference `rules.md`.
- [x] `.vault/_index/conventions.md`: add `- [[../conventions/skill-validation-requirements|Skill validation requirements]]` under an appropriate heading.
- [x] Verify: `! grep -rn 'rules/' .vault/_index/ .vault/*.md` returns nothing pointing at the dead dir (links to `rules.md` are fine).
- [x] **Commit:** `chore(vault): consolidate rules into single .vault/rules.md`

---

## Phase 2: Constitution (§H)

### Task 2.1: Align constitution
- [x] `.vault/constitution.md`: replace `/memex-open-pr` with `/memex:new-pr`; reword the git-hygiene bullet so a spec's recorded `mode:` is the authorization for feature-branch commit/push/PR while `main`/`master` is never pushed; add a pointer that operational rules live in `.vault/rules.md`.
- [x] Verify: `grep -q '/memex:new-pr' .vault/constitution.md && ! grep -q '/memex-open-pr' .vault/constitution.md`.
- [x] **Commit:** `docs(constitution): rename PR command, align recorded-consent, point to rules.md`

---

## Phase 3: AGENTS.md restructure (§A/§B/§C)

### Task 3.1: Rewrite AGENTS.md
- [x] Replace `AGENTS.md` with the 5-section structure: minimal intro (2 lines + `**Never give up on the right solution.**`) → `## Workflow Spec Driven` (pre-work reads home+constitution+rules; triage gate; `### Spec flow` 7 steps) → `## Non-negotiable rules` (pointer) → `## Vault — read from it, write to it` → `## Skills and slash commands` (lists the 2 new skills).
- [x] Verify: `wc -l < AGENTS.md` ≤ `80`; `grep -c '^## ' AGENTS.md` returns `4`; `grep -q '## Workflow Spec Driven' AGENTS.md`; `! grep -qE '^## (Commands|Knowledge locations|Work ethic|Before starting)' AGENTS.md`; `### Spec flow` followed by 7 numbered items.
- [x] **Commit:** `docs(agents): restructure AGENTS.md around the spec-driven workflow`

---

## Phase 4: Spec template (§G)

### Task 4.1: Extend spec template
- [x] `.vault/specs/_template/spec.md`: add `branch:` and `mode:` (`autonomous | reviewed`) keys to the frontmatter block.
- [x] Mirror the same change in the scaffold's vault spec template under `skills/memex/scaffold/` (locate via `grep -rl 'kebab-slug-of-feature' skills/memex/scaffold/`).
- [x] Verify: both files `grep -q '^branch:'` and `grep -q '^mode:'`.
- [x] **Commit:** `feat(spec-template): record branch and execution mode`

---

## Phase 5: memex-new-pr skill (§F)

### Task 5.1: Author canonical copy
- [x] Write `.agents/skills/memex-new-pr/SKILL.md` (`name: memex-new-pr`, `description:` one line) with the body per spec §F: never-from-main; resolve branch+base; push if needed; resolve `.github/PULL_REQUEST_TEMPLATE.md` with embedded fallback; `gh pr create --assignee @me`; English Conventional title + English body (top sentence + bullets + `## Summary`/spec links/`## Test plan`); no AI attribution; mode behavior; `gh`/remote degradation.

### Task 5.2: Mirror to plugin + scaffold
- [x] Copy to `plugins/memex/skills/new-pr/SKILL.md` with `name: new-pr` (only the name field differs).
- [x] Copy to `skills/memex/scaffold/skills/memex-new-pr/SKILL.md` with `name: memex-new-pr`.
- [x] Verify: three files exist with the correct `name:` each.
- [x] **Commit:** `feat(skills): add memex-new-pr companion skill`

---

## Phase 6: memex-code-review skill (§E)

### Task 6.1: Author canonical copy
- [x] Write `.agents/skills/memex-code-review/SKILL.md` (`name: memex-code-review`) per spec §E: read project-law first (rules.md→constitution→area AGENTS→conventions); scope branch-vs-main + uncommitted; plain-text output (no emoji/header/praise) + pre-reply gate; four severities (blocker/suggestion/nitpick/question); `lgtm` verdict templates; memex-adapted blocker calibration; re-review loop; never-approve-under-pressure; sub-agent orchestration + fresh-context degradation; English output.

### Task 6.2: Mirror to plugin + scaffold
- [x] Copy to `plugins/memex/skills/code-review/SKILL.md` (`name: code-review`).
- [x] Copy to `skills/memex/scaffold/skills/memex-code-review/SKILL.md` (`name: memex-code-review`).
- [x] Verify: three files exist with the correct `name:` each.
- [x] **Commit:** `feat(skills): add memex-code-review companion skill`

---

## Phase 7: memex-brainstorming edit (§J)

### Task 7.1: Edit all three copies
- [x] In each of `.agents/skills/memex-brainstorming/SKILL.md`, `plugins/memex/skills/brainstorming/SKILL.md`, `skills/memex/scaffold/skills/memex-brainstorming/SKILL.md`: insert a checklist step (after "Present design", before "Write design doc") that asks the execution **mode** and records `branch:`+`mode:`; mark the spec-review-loop and user-review-gate steps conditional on `mode: reviewed`; update the flow diagram with an "Ask execution mode" node (`reviewed` → review loop; `autonomous` → writing-plans); update the "After the Design" prose for the autonomous path.
- [x] Verify: each copy `grep -qi 'autonomous'` and references the conditional skip.
- [x] **Commit:** `feat(brainstorming): add autonomous/reviewed execution switch`

---

## Phase 8: Reference + scaffold mirror (§I)

### Task 8.1: agents-md-template.md
- [x] Update the section list (~lines 26-33) and the Template block (~lines 37+) to the new 5-section structure; keep the ≤80-line cap language.

### Task 8.2: audit-checklist.md
- [x] Replace the required-AGENTS.md-headers list (lines 155-162) with the new 4 headers; change `.vault/rules/ (directory exists)` (line 43) to `.vault/rules.md (file exists)`; remove the `.vault/_index/rules.md` required-file line (line 33); keep the ≤80-line cap check.

### Task 8.3: vault-files.md + validation.md + spec.md command
- [x] `vault-files.md`: replace the `.vault/rules/` dir description with the single `.vault/rules.md` file; drop the rules MOC.
- [x] `validation.md`: update any reference to the rules dir or the old flow.
- [x] `plugins/memex/commands/spec.md`: mention the autonomy switch + the reviewed/autonomous branch in its flow prose.
- [x] Verify: `! grep -rn '\.vault/rules/' skills/memex/references/` (only `.vault/rules.md` remains); `grep -q '## Workflow Spec Driven' skills/memex/references/agents-md-template.md`.
- [x] **Commit:** `docs(memex): mirror the new flow into references + scaffold`

---

## Phase 9: Quality gate (AC block)

### Task 9.1: Validators
- [x] `python3 skills/memex/scripts/quick_validate.py .agents/skills/memex-new-pr` → `Skill is valid!`
- [x] `python3 skills/memex/scripts/quick_validate.py .agents/skills/memex-code-review` → `Skill is valid!`
- [x] `python3 skills/memex/scripts/quick_validate.py .agents/skills/memex-brainstorming` → still valid.
- [x] `python3 skills/memex/scripts/package_skill.py .agents/skills/memex-new-pr /tmp` and the code-review skill → `Successfully packaged`.

### Task 9.2: Acceptance grep/wc sweep
- [x] Run every binary check from the spec's Acceptance Criteria block (rules.md 4 sections; no `.vault/rules/`; relocated note; AGENTS headers + `wc -l` ≤ 80; spec template keys; the 6 skill files with correct names; no `commands/new-pr.md`/`code-review.md`; constitution string swap; `_index/rules.md` gone; audit-checklist headers).
- [x] Fix any failing check, then re-run.
- [x] **Commit (if fixes):** `fix(spec-driven-workflow): close quality-gate gaps`

---

## Phase 10: PR + review cycle (flow steps 6-7)

### Task 10.1: Reflection (§ After completing a spec)
- [x] Capture any non-obvious learning in `.vault/learnings/` (e.g. the skill-distribution-3-copies topology, the plugin-skill-vs-command distinction) with a `related:` backlink to this spec; index it in `.vault/_index/learnings.md`. If nothing non-obvious: state "No new learnings".

### Task 10.2: Open the PR
- [x] Mark the spec `status: shipped` + set `shipped: 2026-06-13` once all boxes are checked.
- [x] Commit the tasks/spec status updates.
- [x] Open the PR following the `memex-new-pr` design (dogfood it): push the branch, `gh pr create` against `main`, English Conventional title, body filling `.github/PULL_REQUEST_TEMPLATE.md`, link spec/plan/tasks, no AI attribution. (Autonomous mode → open without waiting.)

### Task 10.3: Code-review cycle
- [x] Dispatch a sub-agent running the new `memex-code-review` skill over the branch.
- [x] Triage findings: fix the sensible ones; contest the rest until consensus. Push fixes, re-request review.
- [x] Repeat until the reviewer returns `lgtm`.
