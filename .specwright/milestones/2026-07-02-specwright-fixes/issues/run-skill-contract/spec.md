---
feature: run-skill-contract
created: 2026-07-02
scope: medium
branch: fix/run-skill-contract
worktree: .specwright/worktrees/run-skill-contract
milestone: .specwright/milestones/2026-07-02-specwright-fixes
---
# Run Skill Contract — Spec

**Issue:** see the sibling `issue.md` (the *why*, the acceptance criteria, and the issue `status:`)
**Scope:** Make eight conduction behaviors the e2e validation proved emergent or missing explicit in the run skill's text, across all three shipped copies plus the board template's Blockers wording.

> **Note on `scope:` frontmatter** — `scope` is one of `low | medium | high | complex`. It is **recorded only**: reserved for a future quick-mode and does **not** yet gate which artifacts are written. Set it honestly; nothing branches on it today.
>
> **Note on `worktree:` frontmatter** — the path of this issue's git worktree under `.specwright/worktrees/`, or `null` when the work runs in place. **Recorded only**, like `scope:`.
>
> **Note on `milestone:` frontmatter** — the milestone folder this issue belongs to, or `null` for a standalone issue.

This is the **technical** spec — the *how*. The non-technical *why*, the acceptance criteria, and the status live in `issue.md`.

## Architecture

Pure documentation change: amend the run skill's contract text so behavior the e2e validation observed only as good judgment becomes specified. No scripts, no scaffolder, no build step. The repo ships the run skill in three byte-parallel copies that differ only in the frontmatter `name:` (`run` in the plugin, `sw-run` in `.agents` and the scaffold source); the strategy is **edit one canonical copy** (`.agents/skills/sw-run/SKILL.md`), then propagate the identical body to the other two, preserving each file's first two frontmatter-distinct lines. A final `diff` of the bodies (from line 3) proves parity — the check AC-10 encodes.

Placement of each contract addition, mapped to the existing section structure:

- **The loop → step 1 (Find ready issues):** readiness reads the dependency's own-branch `issue.md` (AC-3, first half).
- **The loop → step 2 (Dispatch):** round-scoped approval asks (AC-1); stacked-branch mechanics + re-target step (AC-3, second half); keep the spawn-time agentId, resume/relay by ID, relays one-way, answers from artifacts (AC-9); the owner prompt's `blocked` return names the paste-ready Blockers block (AC-4, owner side).
- **The loop → step 3 (Track):** commit the board after every Dispatch Log append (AC-2); paste the owner's Blockers block unmodified, dropping the composed-"verbatim" wording (AC-4, conductor side); poll observable state on a cadence, silence is still-running only until a state check says otherwise, 10-minute watchdog (AC-8).
- **Circuit breakers → orchestrator-level halt:** the recovery line names the exact `issue.md` path inside the issue's own checkout, instructs committing the edit on the issue's branch, and reminds the maintainer to sweep the ticket for restatements of the dropped constraint (AC-5).
- **Circuit breakers → scope guard:** scoped to the conduction loop, with closeout's approved goal reconciliation as the stated exception (AC-6, guard side).
- **Closeout:** new goal-reconciliation step (flag → propose → apply only with approval) ordered before learnings promotion (AC-6); the final summary is appended after those approvals, and any earlier draft is amendable only within the appended summary section (AC-7).
- **Board template (`skills/sw/scaffold/templates/board.md`):** the Blockers section intro says the owner's paste-ready block is pasted unmodified, replacing "copied verbatim" (AC-4/AC-10).

The watchdog threshold is stated as **10 minutes** — AC-8 requires "a stated number of minutes", and 10 matches the observed stall-detection cadence from the e2e conduction rounds.

Explicitly out of scope (owned by siblings): a "Progress reporting" section (run-skill-progress-panel stacks on this branch), any change to plan/pr/brainstorm/review skills, the scaffolder script, README.

## File Structure

- Modify: `.agents/skills/sw-run/SKILL.md` — canonical edit: all eight contract additions.
- Modify: `plugins/sw/skills/run/SKILL.md` — body propagated from canonical; keeps `name: run`.
- Modify: `skills/sw/scaffold/skills/sw-run/SKILL.md` — body propagated from canonical; keeps `name: sw-run`.
- Modify: `skills/sw/scaffold/templates/board.md` — one line: Blockers intro wording (AC-4 contract).
- Modify: `.specwright/milestones/2026-07-02-specwright-fixes/issues/run-skill-contract/issue.md` — status flips and AC tick-offs (pipeline bookkeeping, part of this PR).

## Phase Ordering

1. **Phase 1 — canonical edit:** all contract text lands in `.agents/skills/sw-run/SKILL.md`.
2. **Phase 2 — propagation:** copy the body (line 3 onward) to the plugin and scaffold copies; edit the board template.
3. **Phase 3 — verification:** diff-parity check, per-AC grep/read walk, `validate-spec.sh`.

Phase 2 depends on 1; Phase 3 on 2.

## Constraints

- The three copies must stay byte-identical from line 3 (repo convention, restated by AC-10); the only divergence allowed is the `name:` frontmatter line.
- Skill frontmatter obeys `.specwright/conventions/skill-validation-requirements.md` — no `<`/`>` in `name`/`description`, description ≤ 1024 chars. The frontmatter is untouched by this issue, so this is a non-regression constraint.
- No "Progress reporting" section may be introduced — the sibling issue `run-skill-progress-panel` adds it on top of this branch; colliding text would conflict its stacked diff.
- The approved `AC-N` in `issue.md` are never reworded (milestone contract).
- The skill stays a compact contract: additions are sentences inside existing steps, not new top-level sections, except where the existing section already owns the concern.

## User Stories / Scenarios

1. An interactive conductor starting round 2 of a milestone asks the user for approval covering only round 2's writes — the skill text now says a prior round's consent does not carry.
2. A conductor appends `dispatched` to the Dispatch Log and immediately commits the board; a crash a minute later loses nothing.
3. A conductor evaluating readiness for an issue depending on unmerged `feat/x` reads `feat/x`'s own `issue.md`, sees `shipped`, dispatches the dependent stacked on `feat/x`, and the owner notes the re-target-after-merge step in the PR.
4. An owner returns `blocked` with a paste-ready Why/Tried/Needs block; the conductor pastes it into the board's Blockers section byte-identical.
5. A maintainer ignorant of branch mechanics reads the halt report and can execute recovery: the exact `issue.md` path in the issue's checkout, edit, commit on the issue's branch, sweep the ticket for restatements.
6. At closeout the conductor flags a `goal.md` sentence superseded by a recorded decision, proposes the edit, and applies it only after the maintainer approves; the summary is appended after that approval.
7. A conductor whose owners have been silent for 10 minutes checks worktree files, branches, and output timestamps instead of waiting for a completion notification, and resumes a stalled owner by its spawn-time agentId.

## Acceptance Criteria

The acceptance criteria live in the sibling `issue.md` — the `AC-N` IDs defined there are the contract `tasks.md` references and `/sw:review` walks. Do not duplicate them here; if writing this spec exposed a missing or wrong criterion, fix `issue.md`.

## Risks and Mitigations

| Risk | Mitigation |
|---|---|
| Copies drift during propagation (missed hunk) | Single canonical edit, then whole-body copy from line 3; `diff <(tail -n +3 a) <(tail -n +3 b)` must be empty for both pairs (AC-10 check). |
| New text collides with the stacked progress-panel issue | Add no "Progress reporting" section and no panel/one-liner content; keep additions inside existing sections. |
| Contract additions bloat the skill into prose the model skims | Each addition is 1–3 sentences in the step that owns the behavior; no new top-level sections. |
| Board template edit drifts from the skill's Blockers wording | Both edits name the same artifact ("paste-ready Blockers block (Why / Tried / Needs), pasted unmodified") and verification greps both files for it. |

## Open Questions

None.
