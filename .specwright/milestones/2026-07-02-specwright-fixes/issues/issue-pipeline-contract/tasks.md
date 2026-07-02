---
feature: issue-pipeline-contract
created: 2026-07-02
---
# Issue Pipeline Contract — Tasks

**For this issue:** see the sibling `issue.md` (acceptance criteria) and `spec.md` (technical plan).

> Each task names the `AC:` (acceptance criteria from `issue.md` it satisfies — every `AC-N` must be referenced by at least one task) and `Delegable:` (whether it suits an isolated task worker, and the one-line context that worker would receive). Workers report findings back to the issue owner; only the owner writes `learnings.md`.

## Phase 1: Plan-skill amendments (working copy `.agents/skills/sw-plan/SKILL.md`)

### Task 1: Ticket-is-contract clause in the mechanical gate

**AC:** AC-1
**Delegable:** no — all Phase 1/2 tasks edit two shared files whose voice and anchors must stay coherent; one owner edits inline.

- [ ] Step 1: In the `Gates (run in order)` list, extend item 1 (**Mechanical**) after "Fix and re-run until it exits 0." with: a failure caused by the approved ticket itself (`issue.md`) is different — stop and report it with the exact validator `FAIL` line (to the user for a standalone issue, to the orchestrator for a milestone issue) and proceed only after an acknowledged resolution; the owner never rewords an approved criterion; any sanctioned ticket edit is its own commit naming the changed criterion.
- [ ] Step 2: Re-read the amended item; confirm it contains all four AC-1 conditions (stop-and-report, exact validator line, acknowledged resolution, never-reword + own-commit-naming-criterion).
- [ ] Step 3: Commit — `fix(plan): mechanical gate treats the approved ticket as a contract`.

### Task 2: Commit-the-plan step and gate outcomes in the PR body

**AC:** AC-2
**Delegable:** no — same file as Task 1.

- [ ] Step 1: At the end of the `Self-review the spec — no human gate` section (after the gates list), add a closing paragraph: **Commit the plan** — when the three gates pass, commit `spec.md` + `tasks.md` (including any gate fixes) before the first implementation commit; and the PR body's quality-gate section must name these three gates and their outcomes.
- [ ] Step 2: Confirm the paragraph names both halves of AC-2 (explicit commit-the-plan step at the end of the spec-writing stage; PR body quality-gate section names the three plan self-review gates and outcomes).
- [ ] Step 3: Commit — `fix(plan): commit the plan and record gate outcomes in the PR body`.

### Task 3: Define "UI criterion" and the degradation capability-gap record

**AC:** AC-3
**Delegable:** no — same file as Task 1.

- [ ] Step 1: In the `Runtime verification` section, expand "For UI criteria" with a definition — a UI criterion is one about rendered appearance or interaction, not HTTP responses or text output — and add that an unattended session degrading browser verification to curl must record the capability gap alongside the verification.
- [ ] Step 2: Confirm both AC-3 conditions are present (definition with the rendered-appearance/interaction vs HTTP/text contrast; capability-gap recording on curl degradation).
- [ ] Step 3: Commit — `fix(plan): define UI criterion and record browser-to-curl capability gaps`.

### Task 4: Key fan-out on delegable-task count

**AC:** AC-4
**Delegable:** no — same file as Task 1.

- [ ] Step 1: In the `Implement` section, replace the fan-out trigger "(large issue, 5+ tasks, many independent files)" with "(two or more `Delegable: yes` tasks)" and the inline trigger "(small issue, < 5 tasks, focused changes)" with "(fewer than two delegable tasks)".
- [ ] Step 2: `grep -n "5+" .agents/skills/sw-plan/SKILL.md` — expect no match; confirm no total-task-count threshold survives in the section.
- [ ] Step 3: Commit — `fix(plan): fan-out keys on delegable-task count`.

### Task 5: Per-stream redirection guidance for runtime verification

**AC:** AC-7
**Delegable:** no — same file as Task 1.

- [ ] Step 1: In the `Runtime verification` section, add one sentence: stream-sensitive checks must use per-stream file redirection (e.g. `>out 2>err`) because piping merged streams cannot attribute output to stdout vs stderr.
- [ ] Step 2: Confirm the sentence names both the mechanism (per-stream file redirection with the `>out 2>err` example) and the reason (merged-stream piping cannot attribute output).
- [ ] Step 3: Commit — `fix(plan): per-stream redirection for stream-sensitive runtime checks`.

## Phase 2: Pr-skill amendments (working copy `.agents/skills/sw-pr/SKILL.md`)

### Task 6: Degradation as an ordered pre-flight, never probing with `gh pr create`

**AC:** AC-5
**Delegable:** no — Task 7 rewrites the same section; splitting them across workers guarantees a merge conflict.

- [ ] Step 1: Move the `## Degradation` section to before `## Create the PR`, retitle it `## Degradation — ordered pre-flight`, and rewrite it as an ordered list run before `gh pr create`: (1) inspect `git remote -v` first — empty or non-GitHub means stop before anything else, explain, never fabricate a PR; (2) check `gh` presence and `gh auth status` — failure means stop and print the exact `git push` + manual PR-creation steps; (3) only after both pass, run `gh pr create` with the real, fully-filled title and body. State explicitly: `gh pr create` is never invoked as a probe and never with a placeholder title or body.
- [ ] Step 2: Verify section order with `grep -n "^## " .agents/skills/sw-pr/SKILL.md` — the pre-flight heading appears before `## Create the PR`; verify the never-probe sentence and both stop branches are present.
- [ ] Step 3: Commit — `fix(pr): degradation checks are an ordered pre-flight, never a live probe`.

### Task 7: Durable `pr.md` record on either stop branch

**AC:** AC-6, AC-2
**Delegable:** no — same section as Task 6.

- [ ] Step 1: In the new pre-flight section, add the durable-record rule: on either stop branch, write the fully-filled PR body — template or embedded fallback, including the quality-gate results and the per-criterion runtime-verification record — to `<issue-folder>/pr.md`, and say in the stop explanation that the record was written there.
- [ ] Step 2: In `## Title and body`, extend the quality-section sentence so an issue-driven PR body also names the three plan self-review gates and their outcomes (the pr-skill half of the AC-2 recording contract).
- [ ] Step 3: Confirm AC-6's conditions (both stop branches, fully-filled body, quality-gate results + per-criterion runtime-verification record, `<issue-folder>/pr.md` path, says so in the explanation).
- [ ] Step 4: Commit — `fix(pr): degraded delivery writes the PR record to the issue folder`.

## Phase 3: Propagation and parity

### Task 8: Sync all shipped copies and verify parity

**AC:** AC-8
**Delegable:** no — depends on every prior task being final.

- [ ] Step 1: Byte-copy `.agents/skills/sw-plan/SKILL.md` → `skills/sw/scaffold/skills/sw-plan/SKILL.md` and `.agents/skills/sw-pr/SKILL.md` → `skills/sw/scaffold/skills/sw-pr/SKILL.md`.
- [ ] Step 2: Copy the same working files → `plugins/sw/skills/plan/SKILL.md` and `plugins/sw/skills/pr/SKILL.md`, then restore `name: plan` / `name: pr` on the frontmatter `name:` line.
- [ ] Step 3: Verify: `diff` scaffold vs `.agents` copies (expect byte-identical) and `diff` plugin vs `.agents` copies (expect exactly one differing line: `name:`); run `python skills/sw/scripts/quick_validate.py` on all four plugin/scaffold skill dirs.
- [ ] Step 4: Commit — `fix(skills): propagate plan and pr contract text to all shipped copies`.
