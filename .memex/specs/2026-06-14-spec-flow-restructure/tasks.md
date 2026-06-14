---
feature: spec-flow-restructure
plan: "[[2026-06-14-spec-flow-restructure/plan|plan]]"
spec: "[[2026-06-14-spec-flow-restructure/spec|spec]]"
created: 2026-06-14
---
# Spec-Flow Restructure — Tasks

**For this plan:** `[[2026-06-14-spec-flow-restructure/plan|plan]]`

Conventions: each task lists `AC:` (the spec acceptance criteria it satisfies, dogfooding insight #1) and `Delegable:` (whether it suits an isolated subagent, dogfooding the TLC sub-agent model). "Test" steps = run the shell validator / `diff -rq` / fresh-scaffold Phase-5, since the memex repo has no test runner.

Before starting: capture a baseline `diff -rq` of the three copies of each skill to be edited (brainstorming, writing-plans, code-review) so Phase 5 can prove only-intended drift.

## Phase 1: Artifact model + flow + skill reflow

### Task 1: New `design.md` template + remove `plan.md` (dogfood home)

**AC:** design.md exists w/ sections; plan.md removed. **Delegable:** no (defines the shape the rest depends on).
**Files:** Create `.memex/specs/_template/design.md`; Delete `.memex/specs/_template/plan.md`.

- [x] Step 1: Write `_template/design.md` — frontmatter (`feature: {{kebab-slug-of-feature}}`, `spec: "[[spec]]"`, `created: {{YYYY-MM-DD}}`) + `# {{Feature Name}} — Design` and sections: `## Purpose`, `## Motivation`, `## Definitions`, `## Non-Goals`, each with a `{{...}}` placeholder. Add a header note: "Non-technical write-up of the approved design (purpose/motivation/definitions). Created after design approval; not a second human-review gate."
- [x] Step 2: `git rm .memex/specs/_template/plan.md`.
- [x] Step 3: Commit `docs(templates): add design.md, remove plan.md from spec template`.

### Task 2: Fuse `spec.md` template into the technical doc + `scope` + `AC-N` (dogfood home)

**AC:** spec.md technical w/ scope+AC-N, no Context/Problem; scope reserved-note. **Delegable:** no.
**Files:** Modify `.memex/specs/_template/spec.md`.

- [x] Step 1: Frontmatter — add `scope: {{low | medium | high | complex}}`; keep `status/feature/created/shipped/branch/mode/related`.
- [x] Step 2: Remove `## Context` and `## Problem Statement` (they move to design.md). Add a `**Design:** [[design]]` pointer line near the top and an inline note on the `scope` field: "recorded only — reserved for a future quick-mode; does not yet gate which artifacts are written."
- [x] Step 3: Absorb plan's technical sections: add `## Architecture`, `## File Structure`, `## Phase Ordering` (from the old plan template) alongside the kept `## Constraints`, `## User Stories / Scenarios`, `## Acceptance Criteria`, `## Risks and Mitigations`, `## Open Questions`.
- [x] Step 4: Rewrite the Acceptance Criteria guidance to require `AC-N` IDs: "Number each criterion `AC-1`, `AC-2`, … Each must be binary/observable … tasks.md references these IDs."  Update the example bullets to `- [ ] **AC-1** …`.
- [x] Step 5: Commit `docs(templates): fuse spec+plan into technical spec.md with scope + AC-N`.

### Task 3: `tasks.md` template — AC refs + delegation (dogfood home)

**AC:** tasks.md shows `AC:` + `Delegable:` per task. **Delegable:** no.
**Files:** Modify `.memex/specs/_template/tasks.md`.

- [x] Step 1: In the task skeleton add two fields under the task heading: `**AC:** {{AC-N it satisfies}}` and `**Delegable:** {{yes/no + one-line isolated context the subagent would receive}}`.
- [x] Step 2: Update frontmatter `plan: "[[plan]]"` → keep `spec: "[[spec]]"` and drop the `plan` ref only if plan.md no longer exists in the *new* model — NOTE: in the new model there is no plan.md, so frontmatter references `design`/`spec`, not `plan`. Set `design: "[[design]]"`, `spec: "[[spec]]"`.
- [x] Step 3: Commit `docs(templates): tasks.md carries AC refs + delegation notes`.

### Task 4: Mirror all template changes in the install home

**AC:** vault-files.md embeds the 4 template changes. **Delegable:** yes — isolated: "edit only `skills/memex/references/vault-files.md` to match the just-changed `.memex/specs/_template/*` files byte-for-content."
**Files:** Modify `skills/memex/references/vault-files.md`.

- [x] Step 1: Replace the embedded `_template/spec.md` block with the new technical version (Task 2).
- [x] Step 2: Remove the embedded `_template/plan.md` block; add an embedded `_template/design.md` block (Task 1).
- [x] Step 3: Replace the embedded `_template/tasks.md` block (Task 3).
- [x] Step 4: Update the "Spec templates (3 files)" heading/prose and the Group A substitution list: `design.md` replaces `plan.md`.
- [x] Step 5: Commit `docs(references): mirror new spec artifact templates in vault-files.md`.

### Task 5: Reflow the flow docs (both AGENTS.md homes)

**AC:** AGENTS.md ≤80 lines describes reflow; agents-md-template mirrors; check #4 header lockstep. **Delegable:** no (judgment on the canonical contract).
**Files:** Modify `AGENTS.md` (root), `skills/memex/references/agents-md-template.md`.

- [x] Step 1: In `AGENTS.md` `### Spec flow`, update the steps: brainstorming → `design.md`; writing-plans → fused `spec.md` + `tasks.md`; code-review = two subagents. Keep it terse.
- [x] Step 2: `wc -l AGENTS.md` — confirm ≤ 80 (target 45–70). If over, move detail into the skills/references.
- [x] Step 3: Mirror the same reflow in `agents-md-template.md`; add the `scope` reserved-note mention.
- [x] Step 4: If any section *header* changed, update `references/validation.md` check #4's `$h` list to match.
- [x] Step 5: Commit `docs(agents): reflow spec flow for design.md + fused spec + two-subagent review`.

### Task 6: Reflow `memex-brainstorming` (×3 copies)

**AC:** brainstorming writes design.md; reviewer retargets. **Delegable:** yes — isolated: "apply the same edit to all three copies of memex-brainstorming/SKILL.md + spec-document-reviewer-prompt.md; list the three paths."
**Files:** `.agents/skills/memex-brainstorming/SKILL.md` + `spec-document-reviewer-prompt.md`; same under `plugins/memex/skills/brainstorming/`; same under `skills/memex/scaffold/skills/memex-brainstorming/`.

- [x] Step 1: Change step 7 ("Write design doc → spec.md") to write `design.md` (Purpose/Motivation/Definitions/Non-Goals) as the approved-design write-up; the technical spec is produced later by writing-plans.
- [x] Step 2: Retarget `spec-document-reviewer-prompt.md` to review the fused technical `spec.md` (acceptance criteria + AC-N + architecture), not the old what/why spec.
- [x] Step 3: Apply identically to all 3 copies; `diff -rq` the three brainstorming dirs → only intended differences.
- [x] Step 4: Commit `feat(brainstorming): write design.md; retarget spec reviewer (3 copies)`.

### Task 7: Reflow `memex-writing-plans` + fold plan reviewer (×3 copies)

**AC:** writing-plans produces fused spec.md+tasks.md; plan reviewer folded. **Delegable:** yes — isolated as in Task 6.
**Files:** `memex-writing-plans/SKILL.md` + `plan-document-reviewer-prompt.md` (×3).

- [x] Step 1: Diff `plan-document-reviewer-prompt.md` vs `spec-document-reviewer-prompt.md`; note checks unique to the plan reviewer.
- [x] Step 2: Change `memex-writing-plans/SKILL.md` to produce the fused technical `spec.md` (Architecture/File Structure/Phase Ordering/AC-N) + `tasks.md` (AC: + Delegable:); carry the unique plan-reviewer checks into the spec reviewer reference.
- [x] Step 3: Remove the standalone `plan-document-reviewer-prompt.md` (folded). Update any reference to it.
- [x] Step 4: Apply to all 3 copies; `diff -rq` → only intended differences.
- [x] Step 5: Commit `feat(writing-plans): produce fused technical spec + tasks; fold plan reviewer (3 copies)`.

### Task 8: Update the `review-spec` command for the new artifacts

**AC:** review-spec required-sections updated; evaluates design.md. **Delegable:** no (depends on final template shape).
**Files:** `plugins/memex/commands/review-spec.md`.

- [x] Step 1: Update the "required sections" check (#3) list to the new `spec.md` sections (drop Context/Problem Statement; add Architecture/File Structure/Phase Ordering).
- [x] Step 2: Add a check that `design.md` exists with Purpose/Motivation/Definitions/Non-Goals.
- [x] Step 3: Commit `docs(review-spec): match new spec.md sections + evaluate design.md` (validator wiring lands in Task 12).

## Phase 2: Code-review two-subagent (insight #3)

### Task 9: Two-subagent code-review (×3 copies)

**AC:** memex-code-review defines law generalist + AC-conformance subagent; main agent merges verdicts. **Delegable:** yes — isolated: "edit all 3 copies of memex-code-review/SKILL.md to add a second subagent."
**Files:** `memex-code-review/SKILL.md` (×3).

- [x] Step 1: Add a "Two-subagent review" section: subagent A = existing law generalist (rules/constitution/conventions); subagent B = spec-conformance — reads the spec's `AC-N` + the diff and reports **Completeness / Correctness / Coherence** per AC.
- [x] Step 2: Specify the main agent merges both into one of the existing A/B/C/D verdict templates; an AC-N with no satisfying change in the diff is a blocker (insight #1 coverage).
- [x] Step 3: Apply to all 3 copies; `diff -rq` → only intended differences.
- [x] Step 4: Commit `feat(code-review): add spec-conformance subagent alongside law generalist (3 copies)`.

## Phase 3: Mechanical validator (insight #4)

### Task 10: Write `validate-spec.sh` + fixtures

**AC:** validator exits 0 on good folder, non-zero naming the check on each of 4 bad cases; safe under `set -euo pipefail`. **Delegable:** yes — isolated: "write a self-contained bash script + 5 fixture folders; spec of checks below."
**Files:** Create `skills/memex/scaffold/vault-scripts/validate-spec.sh`; Create `skills/memex/scaffold/vault-scripts/fixtures/{good,bad-frontmatter,bad-placeholder,bad-vague-verb,bad-unref-ac}/{spec,design,tasks}.md`.

- [x] Step 1: Write `validate-spec.sh <spec-folder>` with `set -euo pipefail`. Checks: (1) `spec.md` frontmatter has `status/feature/created/scope` and `scope` ∈ {low,medium,high,complex}; (2) no `{{` in any of `spec.md`/`design.md`/`tasks.md`; (3) acceptance criteria contain no banned vague verbs (`works`, `robust`, `fast`/`is fast` without a number, `simple`, `gracefully`); (4) every `AC-N` defined in `spec.md` appears at least once in `tasks.md`. Each failing check prints `FAIL (check N): <reason>` and accumulates a non-zero exit; wrap every zero-match grep with `|| true` / brace blocks (no subshell verdict — see the validator-verdict learning).
- [x] Step 2: Create the `good/` fixture (passes all) and four `bad-*/` fixtures, each tripping exactly one check.
- [x] Step 3: Test — run the script against each fixture:
  - `bash skills/memex/scaffold/vault-scripts/validate-spec.sh .../fixtures/good` → exit 0.
  - each `bad-*` → non-zero, prints the matching `FAIL (check N)`.
  Record commands + output in a task note / PR.
- [x] Step 4: `chmod +x` the script. Commit `feat(scripts): add validate-spec.sh shell validator + fixtures`.

### Task 11: Scaffold the validator into installs (SKILL.md copy step)

**AC:** SKILL.md writes `.memex/scripts/validate-spec.sh` + chmod; `for type` loop → `spec design tasks`. **Delegable:** no.
**Files:** `skills/memex/SKILL.md`.

- [x] Step 1: Add a scaffold step that copies `scaffold/vault-scripts/validate-spec.sh` → `.memex/scripts/validate-spec.sh` (mkdir `.memex/scripts`) and `chmod +x` it; do NOT copy the `fixtures/` sibling.
- [x] Step 2: Change the spec-folder loop `for type in spec plan tasks` → `for type in spec design tasks`.
- [x] Step 3: Commit `feat(skill): scaffold validate-spec.sh to installs; handle design.md in spec loop`.

### Task 12: Wire the validator into `review-spec` as a feedforward gate

**AC:** review-spec invokes `.memex/scripts/validate-spec.sh`, non-zero = blocking FAIL. **Delegable:** no.
**Files:** `plugins/memex/commands/review-spec.md`.

- [x] Step 1: Add a "Step 0 — mechanical pre-check" that runs `.memex/scripts/validate-spec.sh <spec-folder>`; a non-zero exit is a blocking FAIL reported before the prose review.
- [x] Step 2: Commit `docs(review-spec): run validate-spec.sh as a feedforward gate`.

## Phase 4: Test-integrity (insight #2)

### Task 13: Test-integrity rule in the scaffolded quality gate + code-review

**AC:** quality-gate text + code-review (×3) state the test-integrity rule; scoped to installed repos. **Delegable:** yes — isolated: "add the same rule paragraph to agents-md-template.md, root AGENTS.md quality-gate line, and the 3 code-review copies."
**Files:** `skills/memex/references/agents-md-template.md`, root `AGENTS.md`, `memex-code-review/SKILL.md` (×3).

- [x] Step 1: In the scaffolded quality-gate text add: "In a tested area, the test count must not silently drop and assertions must not be weakened/skipped/deleted to pass the gate without an in-spec justification."
- [x] Step 2: In `memex-code-review` (×3) add a blocker-calibration line: a silent test deletion / weakened assertion in a tested area is a **blocker**. Scope the note to installed repos (the memex repo has no test runner).
- [x] Step 3: `wc -l AGENTS.md` still ≤ 80. `diff -rq` the 3 code-review copies.
- [x] Step 4: Commit `feat(quality-gate): add test-integrity rule to scaffold + code-review (3 copies)`.

## Phase 5: Sync & audit

### Task 14: Update Phase-5 validation + audit for the new template set

**AC:** validation.md #5/#15 + audit expected-files use spec/design/tasks; validator listed as expected; no plan.md assertion; fresh scaffold PASSes. **Delegable:** yes — isolated.
**Files:** `skills/memex/references/validation.md`, `skills/memex/references/audit-checklist.md`.

- [x] Step 1: `validation.md` — check #5 loop and check #15 bare-name list → `spec/design/tasks`; add a check that `.memex/scripts/validate-spec.sh` exists and is executable; remove any `_template/plan.md` assumption.
- [x] Step 2: `audit-checklist.md` — expected-file list `_template/{spec,plan,tasks}.md` → `{spec,design,tasks}.md`; bare-name prose; add `.memex/scripts/validate-spec.sh` as expected.
- [x] Step 3: Commit `docs(validation): reflect design.md + validator in Phase-5 and audit`.

### Task 15: Full verification + drift check

**AC:** diff -rq only-intended; fresh-scaffold Phase-5 PASS; mermaid parse-check. **Delegable:** no (final gate, needs full context).
**Files:** none (verification).

- [x] Step 1: `diff -rq` each skill across its 3 copies → only the documented name/path differences.
- [x] Step 2: Scaffold into a throwaway temp dir (per SKILL.md) and run Phase-5 validation → reports PASS for the new model (design.md present, plan.md absent, validator present).
- [x] Step 3: `npx -y @mermaid-js/mermaid-cli` over any mermaid added to committed artifacts → all pass (per [[validate-vault-mermaid-with-mmdc]]).
- [x] Step 4: Run `.memex/scripts/validate-spec.sh` against this very spec folder (dogfood) — note it uses the OLD model, so document expected behavior rather than forcing pass.
- [x] Step 5: Commit any fixes from the checks.

## Phase 6: Reflect + deliver

### Task 16: Reflect + PR + review

**AC:** PR via /memex:new-pr; code-review to lgtm. **Delegable:** no.

- [x] Step 1: Reflect — write learnings to `.memex/learnings/` if any non-obvious thing surfaced (e.g. folding two reviewer prompts, the scaffold copy-step pattern); else "No new learnings".
- [x] Step 2: `/memex:new-pr`.
- [x] Step 3: `memex:code-review` cycle to `lgtm` (autonomous), hands-off.
- [x] Step 4: On `lgtm` (PR opened + reviewed), flip spec `status: shipped` + `shipped:` date.
