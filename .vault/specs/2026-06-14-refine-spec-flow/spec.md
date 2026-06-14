---
status: shipped
feature: refine-spec-flow
created: 2026-06-14
shipped: 2026-06-14
branch: feat/refine-spec-flow
mode: autonomous
related:
  - "[[2026-06-13-spec-driven-workflow/spec|spec-driven-workflow]]"
  - "[[constitution]]"
---
# Refine Spec Flow — Spec

**Status:** Shipped
**Scope:** Second iteration of the spec-driven flow: remove the human spec-review gate (design approval is the only human review point), make the agent self-review run in both modes, restructure the post-design questions into a single three-question batch (branch + mode + compact, no PR question), make `mode` decide only the delivery (autonomous opens the PR on its own; reviewed asks first), and add an optional `/compact` handoff (either mode) that emits a resume prompt once spec/plan/tasks are written. Applied to both the dogfood and the scaffold.

## Context

The spec-driven flow shipped in `[[2026-06-13-spec-driven-workflow/spec|spec-driven-workflow]]` (PR #16) coupled the review gates to the execution mode: `reviewed` ran the spec-document-reviewer loop + a user-review gate + `/memex:review-spec`; `autonomous` skipped all three. Two things were off:

1. **Human spec review is unwanted.** The maintainer wants exactly one human checkpoint before any artifact — **design approval** — and nothing else asking the human to read/approve the written spec. The agent should review its own spec.
2. **The mode no longer maps cleanly to "review vs not".** Both modes should self-review the spec (agent-only). What actually differs is the human's involvement at **delivery** — a `reviewed` run asks before opening the PR + running code-review, an `autonomous` run does it on its own — plus the option to hand off implementation to a fresh, compacted context.

Separately, `/compact` (and `/clear`) are harness controls the agent cannot self-invoke. But the flow has a natural seam — once `spec.md` + `plan.md` + `tasks.md` exist, the planning context is no longer needed and implementation can run from the files. The flow should offer a **handoff prompt** at that seam so the user can compact or start a fresh chat without losing state.

## Problem Statement

Restructure the flow's human-interaction model so that (a) the only human review is design approval, (b) the agent self-reviews the spec in both modes, (c) the post-design questions are a single three-item batch (branch + mode + compact — no PR question), (d) a `compact` run (either mode) emits a `txt` handoff prompt — after the artifacts are written, never before — so implementation can resume in a compacted/fresh context, and (e) the `mode` decides only the delivery (autonomous opens the PR + code-review on its own; reviewed asks first). Encode it across `AGENTS.md`, the three `memex-brainstorming` copies, the scaffold template, the `/memex:spec` command, and the README.

## Non-Goals

- **No change to the PR / code-review skills** (`memex-new-pr`, `memex-code-review`) — their behavior is unchanged; only *when* they run shifts with the mode (autonomous runs them on its own; reviewed asks first).
- **No new frontmatter beyond `branch`/`mode`.** The compact preference and the reviewed delivery go-ahead are run-time choices carried in the conversation and the handoff prompt, not persisted to `spec.md`.
- **No auto-`/compact`.** The agent only prints a handoff prompt; the user runs `/compact` (or opens a new chat) themselves.
- **No change to the 4 `AGENTS.md` H2 headers** or the ≤80-line cap.
- **No constitution rewrite** — its `## Spec-Driven workflow` pointer to `AGENTS.md` already covers the detail; update only if it contradicts the new model.

## Constraints

- **Dogfood + scaffold parity.** Lands in this repo's live files AND `skills/memex/` (the template + the three scaffold skill copies).
- **`AGENTS.md` ≤ 80 lines**, 4 H2 headers unchanged (the `### Spec flow` body grows from 7 to 8 steps; must still fit).
- **3-copy skill sync.** The three `memex-brainstorming` copies stay body-identical except `name:`.
- **Agent-agnostic.** The handoff prompt and self-review work on any agent; `/compact` is named as a Claude-Code control with "or start a new chat" as the portable equivalent.

## Design

### A. Human-interaction model

The **only** human review is **design approval** (the brainstorming HARD-GATE). Immediately after approval, one batch asks **exactly three things, in both modes**:

- confirm the **branch name**;
- choose the **mode** (`autonomous` | `reviewed`);
- whether to **compact** before implementing.

There is **no PR question** — a PR is always the delivery; the `mode` only decides whether the agent opens it on its own (`autonomous`) or asks first (`reviewed`). Record `branch:` + `mode:` in the spec. The human spec-review gate **and** the "start implementation" gate are **removed**. The agent reviews its own spec in **both** modes (Design §C).

### B. `### Spec flow` (8 steps, replaces the current 7)

1. `memex-brainstorming` → design. After the design is approved, the post-design batch confirms the **branch name**, the **mode**, and whether to **compact**. The spec records `branch:` + `mode:`.
2. Create the branch. **One branch + one PR per spec** — spec, plan, tasks, implementation, learnings all live in it.
3. The agent writes `spec-<slug>.md` and **reviews its own spec** — the spec-document-reviewer subagent (completeness/clarity) **and** `/memex:review-spec` (constitution compliance); both run in **both** modes. **No human spec review.** Then `memex-writing-plans` → `plan-<slug>.md` + `tasks-<slug>.md`.
4. **Compact handoff (either mode):** if compact was chosen, once spec/plan/tasks are written print a `txt` handoff prompt (summary + the three file paths + mode) and stop. The agent does **not** compact before the artifacts exist. You `/compact` (or open a new chat), paste the prompt, and implementation continues there.
5. **Implement.**
6. **Quality gate.** Detect + run the touched modules' code-quality processes (test, lint, typecheck, build); nothing breaks; missing tests written first.
7. Reflect; write learnings to `.vault/learnings/` if genuinely useful — part of delivery.
8. **Deliver.** `autonomous` → open the PR (`/memex:new-pr`) and run the `memex:code-review` cycle to `lgtm`, hands-off. `reviewed` → after reflect, ask "open the PR and run code-review?", then the same on the go-ahead.

### C. Agent spec self-review (both modes)

The `memex-brainstorming` skill's review steps stop being conditional on `mode`. In **both** modes, after writing the spec:

1. **spec-document-reviewer subagent loop** — completeness/clarity (max 3 iterations, then surface to human).
2. **`/memex:review-spec` external pass** — constitution + vault compliance; fix `FAIL`s.

The **"User reviews written spec"** step is **deleted**. The design-approval gate is untouched.

### D. Compact handoff prompt

Emitted whenever the user chose compact (in **either** mode), and only **after** `spec.md` + `plan.md` + `tasks.md` are written. Printed in the chat as a fenced ```` ```txt ```` block the user can copy. Contents:

- a one-paragraph **summary** of what to implement;
- the **mode** — so a resumed `autonomous` run finishes on its own through the PR, and a resumed `reviewed` run asks before delivery;
- absolute-or-repo-relative **paths** to `spec-<slug>.md`, `plan-<slug>.md`, `tasks-<slug>.md`;
- an instruction to read those three, implement per the tasks, run the quality gate, reflect, and deliver per the mode (autonomous opens the PR + code-review; reviewed asks first).

The flow text makes explicit that compacting happens **at this seam, not at question time** — the preference is recorded up front, the handoff is produced only when the artifacts exist.

### E. Files changed

- `AGENTS.md` — replace the `### Spec flow` (7→8 steps per §B); keep 4 headers + ≤80 lines.
- `.agents/skills/memex-brainstorming/SKILL.md` + `plugins/memex/skills/brainstorming/SKILL.md` + `skills/memex/scaffold/skills/memex-brainstorming/SKILL.md` — restructure the checklist (post-design batch of exactly three questions: branch + mode + compact, no PR question; delete the User-Review-Gate step; make the two self-review steps both-modes; add the compact-handoff step that applies in either mode; no "start implementation" gate; the mode decides delivery — reviewed asks before the PR), the dot flow diagram, and the "After the Design" prose.
- `skills/memex/references/agents-md-template.md` — mirror the new `### Spec flow` in the Template block **and** fix the Filling-rules sentence that says the flow is "the same 7 steps for every project" → 8 steps.
- **Not changed:** the gitignored E2E sandbox copy `tmp/sample-app/.agents/skills/memex-brainstorming/SKILL.md` is ephemeral (a throwaway scaffold from the previous E2E test, not tracked) — intentionally left as-is; the 3-copy sync and the AC greps explicitly exclude `tmp/`. It is regenerated by re-running the scaffold, not hand-edited.
- `plugins/memex/commands/spec.md` — update its flow prose (post-design batch, both-mode self-review, compact handoff, no human spec review).
- `README.md` — update the "What you get" flow bullet to match (mode questions, compact handoff, no human spec review).
- Constitution — only if its `## Spec-Driven workflow` text contradicts the new model (it currently points at `AGENTS.md`, so likely no change).

## User Stories / Scenarios

1. **Autonomous, no compact.** Design approved; user picks `autonomous`, confirms branch, compact: no. Agent writes spec, self-reviews (both passes), plan + tasks, implements, quality gate, reflects, opens the PR, drives code-review to `lgtm` — no further prompts.
2. **Autonomous + compact.** Same, but compact: yes. After plan + tasks the agent prints a `txt` handoff and stops; user `/compact`s (or new chat), pastes it; the resumed agent runs hands-off to the open PR + code-review `lgtm`.
3. **Reviewed + compact.** User picks `reviewed`, compact: yes. After plan + tasks the agent prints the handoff and stops; the resumed agent implements, quality gate, reflects, then **asks** "open the PR and run code-review?" before delivering.
4. **Reviewed, no compact.** User picks `reviewed`, compact: no. Agent writes spec, self-reviews, plan + tasks, implements, quality gate, reflects, then **asks** "open the PR and run code-review?" → on yes, opens the PR + code-review to `lgtm`.

## Acceptance Criteria

- [x] `AGENTS.md` `### Spec flow` is a numbered list of exactly 8 steps matching Design §B; the file keeps its 4 H2 headers and `wc -l AGENTS.md` ≤ 80.
- [x] `AGENTS.md` step 1 names the post-design batch as exactly three questions (branch + mode + compact, no PR question); step 3 states the agent self-reviews in **both** modes and that there is **no human spec review**; step 8 makes delivery mode-gated (autonomous opens the PR on its own; reviewed asks first).
- [x] None of the three `memex-brainstorming` SKILL copies contains a "User reviews written spec" / user-review-gate step; a grep for `User Review Gate` / `User reviews written spec` across all three returns nothing.
- [x] In all three `memex-brainstorming` copies, the spec-document-reviewer loop and the `/memex:review-spec` pass are **not** marked "reviewed mode only" (they run in both modes); the dot diagram routes both `autonomous` and `reviewed` through the self-review before writing-plans.
- [x] All three `memex-brainstorming` copies contain a compact-handoff step that (a) applies in **either** mode, (b) states the handoff is produced after spec/plan/tasks exist (never before), and (c) prints a ```` ```txt ```` block; there is **no** "start implementation?" gate, and delivery is mode-gated (reviewed asks "open the PR and run code-review?").
- [x] The three `memex-brainstorming` copies are body-identical except the `name:` field (`diff <(tail -n +3 A) <(tail -n +3 B)` empty for both pairs).
- [x] `skills/memex/references/agents-md-template.md` `### Spec flow` matches `AGENTS.md` (same 8 steps), and its Filling-rules prose no longer says "7 steps" (a grep for `7 steps` in that file returns nothing).
- [x] `plugins/memex/commands/spec.md` flow prose describes the both-mode self-review, the post-design batch, and the compact handoff, and no longer implies a human spec-review gate.
- [x] `README.md` "What you get" flow description matches the new model (no human spec review; compact handoff mentioned).
- [x] `python3`-via-`uv` `quick_validate.py` passes for all three `memex-brainstorming` copies.
- [x] No spec frontmatter field beyond `branch`/`mode` is added to `.vault/specs/_template/spec.md` for this change.

## Risks and Mitigations

| Risk | Mitigation |
|---|---|
| 8th step pushes `AGENTS.md` over 80 lines | Steps are one line each; current file is 46 lines — ample headroom. AC asserts `wc -l ≤ 80`. |
| Compact handoff wording implies the agent compacts itself | Flow text and the skill prose state explicitly the agent only prints a prompt; the user runs `/compact` or opens a new chat. |
| Removing the user-review gate weakens spec quality | The agent self-review (two passes, both modes) replaces it; design approval still gates the whole thing. |
| 3-copy drift on the brainstorming edit | Edit the canonical `.agents` copy, regenerate the other two by `cp`/`sed`, assert body-identical (AC). |

## Open Questions

_None — design approved during brainstorming (three-question batch with no PR question, compact in either mode, both-mode self-review, mode-gated delivery where reviewed asks before the PR, no "start implementation" gate)._
