---
name: sw-plan
description: "Use when an approved issue (issue.md) needs its technical plan — produces the fused spec.md + tasks.md just-in-time, self-reviews them, then drives the issue pipeline: implement, quality gate, runtime verification, PR, review to lgtm, learnings. The issue owner's skill."
---

# Plan — the issue pipeline, from ticket to shipped

Turn an approved issue (`issue.md`) into the **fused technical `spec.md`** (architecture, file structure, phase ordering) plus the **`tasks.md`** breakdown, then drive the pipeline to delivery. Whoever runs this skill is the **issue owner**: one owner per issue, owning the branch, the artifacts, the gates, and the issue's `learnings.md`.

Assume the implementing engineer has zero context for our codebase and questionable taste: document which files to touch for each task, the code, the docs they might need, and how to test it. DRY. YAGNI. TDD. Frequent commits.

**Announce at start:** "I'm using the plan skill to write the technical spec and tasks."

**Context:** runs after the issue exists — written by the brainstorm (standalone) or by the milestone decomposition (dispatched by `/sw:run`). Work in the issue's branch — or its worktree under `.specwright/worktrees/<slug>`, if one was created.

## Locate the issue folder

- Standalone: `.specwright/issues/YYYY-MM-DD-<slug>/`
- Milestone: `.specwright/milestones/YYYY-MM-DD-<milestone-slug>/issues/<slug>/`

`spec.md` and `tasks.md` are written **just-in-time** into that folder, next to `issue.md`. Set `status: in-progress` in `issue.md` when you start.

## Inherit the learnings (milestone issues)

Before writing the spec for an issue that belongs to a milestone, read every **sibling** issue's `learnings.md` whose own `issue.md` says `status: shipped` (`../*/learnings.md`). These are curated, non-obvious facts earlier issues paid to discover — data formats, surprising API behavior, cross-cutting decisions, required workarounds. Fold every applicable one into the spec's Architecture/Constraints. A spec that trips over a recorded learning is a review blocker.

## Scope check

If the issue covers multiple independent subsystems, it should have been decomposed during the brainstorm (or on the milestone board). If it wasn't, stop and suggest splitting — for a milestone issue, that is a **blocked** report, not a unilateral board edit.

## Writing the technical spec (`spec.md`)

Copy the bundled template (`scaffold/templates/spec.md`, under the installed `sw` skill or `skills/sw/` in the specwright dev repo) into the issue folder and fill it:

- **Frontmatter** — `feature`, `created`, `scope:` (your honest sizing: one of `low | medium | high | complex`; recorded only), the issue's `branch:`, `worktree:` (path or `null`), and `milestone:` (the milestone folder or `null`).
- **Architecture / File Structure / Phase Ordering** — the technical *how*. Map which files will be created or modified and what each is responsible for. Units with clear boundaries and one responsibility; smaller focused files over large ones; files that change together live together; follow the existing patterns of the codebase.
- **Acceptance criteria stay in `issue.md`** — the `AC-N` there are the approved contract. Do not duplicate them into the spec. If planning exposes a wrong or missing criterion: for a standalone issue, fix `issue.md` with the user; for a milestone issue, report it — changing approved ACs is a scope change, never a unilateral edit.

## Bite-sized task granularity (`tasks.md`)

**Each step is one action (2-5 minutes):** "Write the failing test" — step. "Run it to make sure it fails" — step. "Implement the minimal code to make the test pass" — step. "Run the tests" — step. "Commit" — step.

**Every `tasks.md` MUST start with this header:**

```markdown
# [Issue Name] — Tasks

> **For agentic workers:** implement task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. Each task names the `AC:` it satisfies and a `Delegable:` note.

**For this issue:** see the sibling `issue.md` (acceptance criteria) and `spec.md`.

---
```

**Task structure:**

````markdown
### Task N: [Component Name]

**AC:** [AC-N it satisfies, e.g. AC-1, AC-3]
**Delegable:** [yes/no + one-line isolated context an isolated worker would receive]
**Files:**
- Create: `exact/path/to/file.py`
- Modify: `exact/path/to/existing.py:123-145`
- Test: `tests/exact/path/to/test.py`

- [ ] **Step 1: Write the failing test**

```python
def test_specific_behavior():
    result = function(input)
    assert result == expected
```

- [ ] **Step 2: Run test to verify it fails**

Run: `pytest tests/path/test.py::test_name -v`
Expected: FAIL with "function not defined"

- [ ] **Step 3: Write minimal implementation**
- [ ] **Step 4: Run test to verify it passes**
- [ ] **Step 5: Commit**
````

Every `AC-N` defined in `issue.md` must be named by at least one task's `AC:` field — the traceability contract the validator and `/sw:review` enforce.

**No placeholders.** Never write: "TBD", "TODO", "implement later", "add appropriate error handling", "write tests for the above" (without actual test code), "similar to Task N" (repeat the code), steps that describe without showing, or references to types/functions no task defines. Exact file paths, complete code in code steps, exact commands with expected output.

## Self-review the spec — no human gate

After `spec.md` + `tasks.md` are written, review them before implementation. The user is **not** asked to review — the issue's approval already gated the work.

**Author pass (inline, you):**

1. **Coverage** — every requirement in `issue.md` maps to a task; list and close gaps.
2. **AC coverage** — every `AC-N` in `issue.md` is referenced by at least one task's `AC:` field; no task cites a nonexistent `AC-N`.
3. **Placeholder scan** — no double-brace survivors, no "TBD"/"TODO".
4. **Type consistency** — names and signatures match across tasks.

**Gates (run in order):**

1. **Mechanical** — `.agents/skills/sw/scripts/validate-spec.sh <issue-folder>` (in the specwright dev repo: `skills/sw/scripts/validate-spec.sh`); non-zero exit names the structural defect. Fix and re-run until it exits 0.
2. **Spec-document-reviewer subagent** — dispatch it (see the sibling `spec-document-reviewer-prompt.md`) over `issue.md` + `spec.md` + `tasks.md`. Fix, re-dispatch until Approved (max 3 iterations, then surface to the human).
3. **`/sw:review-spec`** — the external evaluator (conventions + issue compliance, vague ACs, scope creep). Fix any `FAIL`.

## Implement

Decide the execution approach yourself — do not ask:

- **Fan-out** (large issue, 5+ tasks, many independent files): dispatch a fresh **task worker** per `Delegable: yes` task. Workers implement and **report findings back** (raw discoveries, surprises, constraints); they never write `learnings.md` — curation is the owner's. Review each worker's diff before starting the next wave.
- **Inline** (small issue, < 5 tasks, focused changes): execute the tasks in this session, checkpointing after each.

## Quality gate

Detect the touched modules' code-quality processes (test, lint, typecheck, build — Makefile, `package.json` scripts, the area's CI) and run them all; nothing you did may break them. Logic added or changed in a tested area without a test → write the missing tests first. **Test integrity:** the touched area's test count must not silently drop, and assertions must not be weakened, skipped, or deleted to pass the gate without an in-spec justification.

## Runtime verification

After the quality gate and **before the PR**, execute what you built and check every `AC-N` by **observed behavior** — run the CLI, start the server and hit the endpoint, run the script against a fixture. For UI criteria: verify through a browser when the agent has that capability. When a criterion cannot be runtime-verified (no browser, no reachable environment), mark it `needs-human-verification` in `issue.md` with one line of reason — **never silently tick it, never fake a verification**. Record what was verified and how; it goes in the PR body.

**Circuit breaker:** the same gate or criterion failing **three times identically** means stop — do not thrash. Standalone issue: report to the user (why / what you tried / what you need). Milestone issue: write that report, set `status: blocked` in `issue.md`, and return it to the orchestrator.

## Deliver

Open the PR with `/sw:pr` and run `/sw:review` to `lgtm` — the issue's approval is the standing consent; no further asks. Then:

1. **Curate learnings** — write the issue folder's `learnings.md`: only non-obvious facts **future issues need** (data formats, surprising behaviors, cross-cutting constraints, required workarounds). Not narration of what you did, not internals only this issue touches. No qualifying fact → no file.
2. **Ship** — set `issue.md` `status: shipped` + `shipped:` date, tick the verified `AC-N` checkboxes. On the issue's own branch, part of its PR.
3. Milestone issue: report back one line per learning + the PR URL — the orchestrator logs them on the board.
