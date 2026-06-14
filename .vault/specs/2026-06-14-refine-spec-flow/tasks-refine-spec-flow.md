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
- [x] In `.agents/skills/memex-brainstorming/SKILL.md`: (a) rewrite the post-design **"Ask execution mode"** step into the **3-question batch** — confirm branch + mode + compact (no PR question); (b) make the **spec-document-reviewer loop** and **`/memex:review-spec` pass** steps run in **both** modes (drop the "reviewed mode only" guards); (c) **delete** the "User reviews written spec" / User Review Gate step; (d) add a **compact-handoff** step (**either mode**, after spec/plan/tasks exist, prints a ```` ```txt ```` block, never auto-compacts); (e) **no "start implementation?" gate**; the **mode decides delivery** — `reviewed` asks "open the PR and run code-review?" after reflect, `autonomous` opens it on its own; (f) update the `dot` flow diagram (post-design node = "branch + mode + compact"); (g) update the "After the Design" prose to match.
- [x] Verify: `! grep -qi 'User reviews written spec\|User Review Gate' .agents/skills/memex-brainstorming/SKILL.md`; `grep -qi 'compact' …`; `grep -qi 'both modes\|in both' …`.

### Task 1.2: Regenerate plugin + scaffold copies
- [x] `cp` canonical → `skills/memex/scaffold/skills/memex-brainstorming/SKILL.md`; `sed 's/^name: memex-brainstorming$/name: brainstorming/'` canonical → `plugins/memex/skills/brainstorming/SKILL.md`.
- [x] Verify body-identity: `diff <(tail -n +3 .agents/…) <(tail -n +3 plugins/…)` and `<(tail -n +3 scaffold/…)` both empty; validate all 3 via `uv`.
- [x] **Commit:** `feat(brainstorming): single human gate (design), both-mode self-review, compact handoff`

---

## Phase 2: AGENTS.md `### Spec flow` (§B)

### Task 2.1: Replace the 7-step flow with the 8 steps
- [x] In `AGENTS.md`, replace the `### Spec flow` numbered list with the 8 steps from spec §B (post-design batch; both-mode self-review + no human spec review; compact handoff; implement w/ reviewed "start?" gate; quality gate; reflect; deliver).
- [x] Verify: `grep -cE '^[0-9]+\. ' AGENTS.md` returns 8 within the flow; `grep -c '^## ' AGENTS.md` = 4; `wc -l < AGENTS.md` ≤ 80; `! grep -qi 'User reviews' AGENTS.md`.
- [x] **Commit:** `docs(agents): rewrite spec flow — design-only human review, compact handoff`

---

## Phase 3: template + command + README (§E)

### Task 3.1: agents-md-template.md
- [x] Replace the Template block's `### Spec flow` with the same 8 steps; change the filling-rules sentence "the same 7 steps" → "the same 8 steps".
- [x] Verify: `! grep -q '7 steps' skills/memex/references/agents-md-template.md`; the Template `### Spec flow` matches `AGENTS.md`.

### Task 3.2: spec.md command + README
- [x] `plugins/memex/commands/spec.md`: rewrite the flow prose — post-design batch, both-mode agent self-review, compact handoff; remove any "user review gate" mention.
- [x] `README.md`: update the "What you get" flow bullet (no human spec review; mode questions; compact handoff).
- [x] Verify: `! grep -qi 'user review gate' plugins/memex/commands/spec.md`.
- [x] **Commit:** `docs(memex): mirror refined flow into template, spec command, README`

---

## Phase 4: Quality gate (AC)

### Task 4.1: Validators + AC sweep
- [x] `uv run --quiet --with pyyaml python skills/memex/scripts/quick_validate.py` on the 3 brainstorming copies → `Skill is valid!`.
- [x] Run every binary AC check from the spec (8-step flow, 4 headers, ≤80 lines, no user-review-gate in 3 copies, self-review not mode-gated, compact-handoff present, 3-copy identity excl tmp/, template matches + no "7 steps", spec.md no user-review-gate, README updated).
- [x] Fix any miss; re-run. **Commit (if fixes):** `fix(refine-spec-flow): close quality-gate gaps`

---

## Phase 5: Deliver (flow 6-8)

### Task 5.1: Reflection
- [x] Capture any non-obvious learning in `.vault/learnings/` with a `related:` backlink; else "No new learnings".

### Task 5.2: Ship + PR + review cycle
- [x] Mark spec `status: shipped` + `shipped: 2026-06-14`; tick task/AC checkboxes; commit.
- [x] Open the PR (dogfood `memex-new-pr`): push, `gh pr create` against `main`, fill the template, link spec/plan/tasks, no attribution.
- [x] Dispatch `memex-code-review` sub-agent over the branch; triage; iterate to `lgtm`.
