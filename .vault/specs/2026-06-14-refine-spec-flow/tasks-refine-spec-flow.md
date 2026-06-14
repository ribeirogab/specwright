---
feature: refine-spec-flow
plan: "[[plan-refine-spec-flow]]"
spec: "[[spec-refine-spec-flow]]"
created: 2026-06-14
---
# Refine Spec Flow — Tasks

**For this plan:** `[[plan-refine-spec-flow]]`

Branch `feat/refine-spec-flow`. No test runner — verification is grep/`wc` + `uv run --quiet --with pyyaml python skills/memex/scripts/quick_validate.py`. Conventional Commits, no AI attribution. Mode: **autonomous**.

---

## Phase 1: memex-brainstorming skill (§A/§C/§D)

### Task 1.1: Restructure the canonical copy
- [ ] In `.agents/skills/memex-brainstorming/SKILL.md`: (a) rewrite the post-design **"Ask execution mode"** step into the batch — confirm branch + mode; reviewed also asks PR? + compact?; (b) make the **spec-document-reviewer loop** and **`/memex:review-spec` pass** steps run in **both** modes (drop the "reviewed mode only" guards); (c) **delete** the "User reviews written spec" / User Review Gate step; (d) add a **compact-handoff** step (reviewed+compact, after spec/plan/tasks exist, prints a ```` ```txt ```` block, never auto-compacts); (e) add a reviewed **"start implementation?"** gate for the no-compact path; (f) update the `dot` flow diagram so both modes pass through the self-review before writing-plans, and the reviewed branch routes through PR/compact decisions; (g) update the "After the Design" prose to match.
- [ ] Verify: `! grep -qi 'User reviews written spec\|User Review Gate' .agents/skills/memex-brainstorming/SKILL.md`; `grep -qi 'compact' …`; `grep -qi 'both modes\|in both' …`.

### Task 1.2: Regenerate plugin + scaffold copies
- [ ] `cp` canonical → `skills/memex/scaffold/skills/memex-brainstorming/SKILL.md`; `sed 's/^name: memex-brainstorming$/name: brainstorming/'` canonical → `plugins/memex/skills/brainstorming/SKILL.md`.
- [ ] Verify body-identity: `diff <(tail -n +3 .agents/…) <(tail -n +3 plugins/…)` and `<(tail -n +3 scaffold/…)` both empty; validate all 3 via `uv`.
- [ ] **Commit:** `feat(brainstorming): single human gate (design), both-mode self-review, compact handoff`

---

## Phase 2: AGENTS.md `### Spec flow` (§B)

### Task 2.1: Replace the 7-step flow with the 8 steps
- [ ] In `AGENTS.md`, replace the `### Spec flow` numbered list with the 8 steps from spec §B (post-design batch; both-mode self-review + no human spec review; compact handoff; implement w/ reviewed "start?" gate; quality gate; reflect; deliver).
- [ ] Verify: `grep -cE '^[0-9]+\. ' AGENTS.md` returns 8 within the flow; `grep -c '^## ' AGENTS.md` = 4; `wc -l < AGENTS.md` ≤ 80; `! grep -qi 'User reviews' AGENTS.md`.
- [ ] **Commit:** `docs(agents): rewrite spec flow — design-only human review, compact handoff`

---

## Phase 3: template + command + README (§E)

### Task 3.1: agents-md-template.md
- [ ] Replace the Template block's `### Spec flow` with the same 8 steps; change the filling-rules sentence "the same 7 steps" → "the same 8 steps".
- [ ] Verify: `! grep -q '7 steps' skills/memex/references/agents-md-template.md`; the Template `### Spec flow` matches `AGENTS.md`.

### Task 3.2: spec.md command + README
- [ ] `plugins/memex/commands/spec.md`: rewrite the flow prose — post-design batch, both-mode agent self-review, compact handoff; remove any "user review gate" mention.
- [ ] `README.md`: update the "What you get" flow bullet (no human spec review; mode questions; compact handoff).
- [ ] Verify: `! grep -qi 'user review gate' plugins/memex/commands/spec.md`.
- [ ] **Commit:** `docs(memex): mirror refined flow into template, spec command, README`

---

## Phase 4: Quality gate (AC)

### Task 4.1: Validators + AC sweep
- [ ] `uv run --quiet --with pyyaml python skills/memex/scripts/quick_validate.py` on the 3 brainstorming copies → `Skill is valid!`.
- [ ] Run every binary AC check from the spec (8-step flow, 4 headers, ≤80 lines, no user-review-gate in 3 copies, self-review not mode-gated, compact-handoff present, 3-copy identity excl tmp/, template matches + no "7 steps", spec.md no user-review-gate, README updated).
- [ ] Fix any miss; re-run. **Commit (if fixes):** `fix(refine-spec-flow): close quality-gate gaps`

---

## Phase 5: Deliver (flow 6-8)

### Task 5.1: Reflection
- [ ] Capture any non-obvious learning in `.vault/learnings/` with a `related:` backlink; else "No new learnings".

### Task 5.2: Ship + PR + review cycle
- [ ] Mark spec `status: shipped` + `shipped: 2026-06-14`; tick task/AC checkboxes; commit.
- [ ] Open the PR (dogfood `memex-new-pr`): push, `gh pr create` against `main`, fill the template, link spec/plan/tasks, no attribution.
- [ ] Dispatch `memex-code-review` sub-agent over the branch; triage; iterate to `lgtm`.
