---
feature: role-subagents
created: 2026-07-03
---
# Per-Role Subagents with Model + Effort — Tasks

**For this issue:** see the sibling `issue.md` (acceptance criteria) and `spec.md` (technical plan).

> Each task names the `AC:` it satisfies and `Delegable:`. The owner runs Phase 1 inline (the four files share a frontmatter shape and must stay consistent), so fan-out is not used here.

## Phase 1: Bundle the four role definitions

### Task 1: issue-owner definition

**AC:** AC-1, AC-2, AC-3
**Delegable:** no — must stay consistent with the sibling definitions' frontmatter shape.

- [ ] Step 1: Create `plugins/sw/agents/issue-owner.md` with frontmatter `name: issue-owner`, `description:` (owns one milestone issue via the plan pipeline), `model: opus`, `effort: xhigh`, `skills:` listing `plan`.
- [ ] Step 2: Write the body (English): own ONE issue, run the `plan` pipeline end to end for the passed issue folder, return `shipped` (+ PR URL + one line per learning) or `blocked` (+ Why/Tried/Needs block).
- [ ] Step 3: Verify the file parses as YAML frontmatter + body (`head` shows a `---`-delimited block with all five keys).

### Task 2: task-worker definition

**AC:** AC-1, AC-2, AC-3
**Delegable:** no — sibling-consistency.

- [ ] Step 1: Create `plugins/sw/agents/task-worker.md` with frontmatter `name: task-worker`, `description:` (implements one delegable task, reports findings), `model: sonnet`, `effort: medium`, and **no** `skills:` key.
- [ ] Step 2: Write the body (English): implement the SINGLE task passed in; DRY/YAGNI/TDD, frequent commits; report raw findings back; never write `learnings.md`.
- [ ] Step 3: Verify frontmatter has `model: sonnet` + `effort: medium` and no `skills:` line.

### Task 3: spec-document-reviewer definition + prompt migration

**AC:** AC-1, AC-2, AC-3, AC-4
**Delegable:** no — a delete + verbatim migration that must match the source.

- [ ] Step 1: Create `plugins/sw/agents/spec-document-reviewer.md` with frontmatter `name: spec-document-reviewer`, `description:` (verifies spec.md + tasks.md against issue.md), `model: opus`, `effort: high`, no `skills:` key.
- [ ] Step 2: Copy the reviewer instructions from `plugins/sw/skills/plan/spec-document-reviewer-prompt.md` into the body verbatim (the What-to-Check table, Calibration, Output Format), adapting only the framing lines so it reads as a standing system prompt.
- [ ] Step 3: Delete `plugins/sw/skills/plan/spec-document-reviewer-prompt.md`.
- [ ] Step 4: Verify the prompt file is gone (`test ! -f`) and the agent body contains the What-to-Check categories.

### Task 4: reviewer definition

**AC:** AC-1, AC-2, AC-3
**Delegable:** no — sibling-consistency.

- [ ] Step 1: Create `plugins/sw/agents/reviewer.md` with frontmatter `name: reviewer`, `description:` (one find-only review lane), `model: opus`, `effort: xhigh`, `skills:` listing `review`.
- [ ] Step 2: Write the body (English): you are ONE find-only lane; the lane (A rubric+conventions / B issue-conformance / C documentation) is named in your dispatch prompt; stay in your lane; never edit code; apply the preloaded `review` standard.
- [ ] Step 3: Commit Phase 1: the four `agents/*.md` and the prompt-file deletion.

## Phase 2: Rewire the three dispatch sites

### Task 5: run skill dispatches issue-owner

**AC:** AC-5
**Delegable:** no.

- [ ] Step 1: In `plugins/sw/skills/run/SKILL.md`, edit the "Dispatch one issue owner per ready issue" step to spawn the `issue-owner` subagent by name; shrink the owner prompt to the issue/milestone/worktree paths + the `shipped`/`blocked` return contract (the pipeline instruction now lives in the agent + preloaded `plan`).
- [ ] Step 2: Verify the step names `issue-owner` and no longer inlines the full "run the plan skill pipeline" instruction.

### Task 6: plan skill dispatches spec-document-reviewer + task-worker

**AC:** AC-6
**Delegable:** no.

- [ ] Step 1: In `plugins/sw/skills/plan/SKILL.md` Gate 2, replace "dispatch it (see the sibling `spec-document-reviewer-prompt.md`)" with dispatching the `spec-document-reviewer` subagent by name.
- [ ] Step 2: In the "Implement" fan-out bullet, name the `task-worker` subagent as the dispatch target.
- [ ] Step 3: Verify `plan/SKILL.md` no longer contains the string `spec-document-reviewer-prompt.md`.

### Task 7: review skill dispatches reviewer

**AC:** AC-7
**Delegable:** no.

- [ ] Step 1: In `plugins/sw/skills/review/SKILL.md` "Three-subagent review", name the `reviewer` subagent as the dispatch target for each lane (A/B/C), keeping the lane definitions in place.
- [ ] Step 2: Verify the section names `reviewer` and still describes lanes A, B, and C.
- [ ] Step 3: Commit Phase 2: the three skill rewires.

## Phase 3: Docs + test coverage

### Task 8: document the agents/ home in CLAUDE.md

**AC:** AC-8
**Delegable:** no.

- [ ] Step 1: In `CLAUDE.md` "### Editing the bundled skills", add one sentence naming `plugins/sw/agents/` as the home of the bundled role subagents (issue-owner, task-worker, spec-document-reviewer, reviewer), each pinning `model` + `effort`.
- [ ] Step 2: Verify `CLAUDE.md` line count stays within its 80-line cap (`wc -l`).

### Task 9: smoke-test the four agents

**AC:** AC-1, AC-2, AC-3
**Delegable:** no.

- [ ] Step 1: In `tests/install/run.sh`, add assertions: each of the four `plugins/sw/agents/*.md` exists; each has `name`/`description`/`model`/`effort` in frontmatter; the four carry the agreed `model`/`effort` pairs; `issue-owner` and `reviewer` list their `skills:` preload while the other two do not.
- [ ] Step 2: Run `bash tests/install/run.sh`; confirm `ALL PASS`.
- [ ] Step 3: Commit Phase 3: docs + test.
