---
name: writing-plans
description: Use when you have an approved design (design.md) for a multi-step task — produces the fused technical spec.md + tasks.md, before touching code.
---

# Writing Plans

## Overview

Turn the approved design (`design.md`) into the **fused technical `spec.md`** (architecture, file structure, phase ordering, numbered acceptance criteria) plus the **`tasks.md`** breakdown (bite-sized tasks, each naming the `AC-N` it satisfies and whether it is delegable). Assume the implementing engineer has zero context for our codebase and questionable taste: document which files to touch for each task, the code, the docs they might need, and how to test it. DRY. YAGNI. TDD. Frequent commits.

Assume they are a skilled developer, but know almost nothing about our toolset or problem domain. Assume they don't know good test design very well.

**Announce at start:** "I'm using the writing-plans skill to write the technical spec and tasks."

**Context:** This runs after brainstorming wrote `design.md` and the branch/mode/worktree were recorded. Work in the spec's branch — or its worktree under `.specwright/worktrees/<slug>`, if one was created.

**Save to:** `.specwright/specs/YYYY-MM-DD-<slug>/spec.md` (the technical spec) and `tasks.md`, alongside the `design.md` brainstorming wrote.
- (User preferences for location override this default)

## Scope Check

If the design covers multiple independent subsystems, it should have been broken into sub-project specs during brainstorming. If it wasn't, suggest splitting — one spec per subsystem. Each spec should produce working, testable software on its own.

## Writing the technical spec (`spec.md`)

Copy `skills/sw/scaffold/spec-templates/spec.md` into the spec folder and fill it from the approved `design.md`:

- **Frontmatter** — set `status: draft`, `feature`, `created`, the recorded `branch:`/`mode:`/`worktree:`, and `scope:` — your honest sizing of the work, one of `low | medium | high | complex`. `scope` and `worktree` are **recorded only**; nothing branches on them yet (`scope` is reserved for a future quick-mode; `worktree` records the worktree path or `null`).
- **Architecture / File Structure / Phase Ordering** — the technical *how*. Before defining tasks, map out which files will be created or modified and what each is responsible for. This is where decomposition decisions get locked in.
  - Design units with clear boundaries and well-defined interfaces. Each file has one clear responsibility.
  - You reason best about code you can hold in context at once, and your edits are more reliable when files are focused. Prefer smaller, focused files over large ones that do too much.
  - Files that change together live together. Split by responsibility, not by technical layer.
  - In existing codebases, follow established patterns. Don't unilaterally restructure — but a split of an unwieldy file you're modifying is reasonable.
- **Acceptance Criteria** — number each `AC-1`, `AC-2`, …. Each must be binary, observable, verifiable in under a minute, and free of vague verbs ("works", "fast"/"robust" without a number, "gracefully"). These IDs are the contract `tasks.md` and `sw-code-review` trace against, so they must be specific enough to check.
- The non-technical *why* (purpose, motivation, definitions, non-goals) stays in `design.md` — don't duplicate it here.

## Bite-Sized Task Granularity (`tasks.md`)

**Each step is one action (2-5 minutes):**
- "Write the failing test" - step
- "Run it to make sure it fails" - step
- "Implement the minimal code to make the test pass" - step
- "Run the tests and make sure they pass" - step
- "Commit" - step

## Tasks Document Header

**Every `tasks.md` MUST start with this header:**

```markdown
# [Feature Name] — Tasks

> **For agentic workers:** implement task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. Each task names the `AC:` it satisfies and a `Delegable:` note.

**For this spec:** see the sibling `spec.md`.

---
```

## Task Structure

````markdown
### Task N: [Component Name]

**AC:** [AC-N it satisfies, e.g. AC-1, AC-3]
**Delegable:** [yes/no + one-line isolated context an isolated subagent would receive]
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

```python
def function(input):
    return expected
```

- [ ] **Step 4: Run test to verify it passes**

Run: `pytest tests/path/test.py::test_name -v`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add tests/path/test.py src/path/file.py
git commit -m "feat: add specific feature"
```
````

Every `AC-N` defined in `spec.md` must be named by at least one task's `AC:` field — that is the traceability contract the validator and code-review enforce.

## No Placeholders

Every step must contain the actual content an engineer needs. These are **task failures** — never write them:
- "TBD", "TODO", "implement later", "fill in details"
- "Add appropriate error handling" / "add validation" / "handle edge cases"
- "Write tests for the above" (without actual test code)
- "Similar to Task N" (repeat the code — the engineer may be reading tasks out of order)
- Steps that describe what to do without showing how (code blocks required for code steps)
- References to types, functions, or methods not defined in any task

## Remember
- Exact file paths always
- Complete code in every step — if a step changes code, show the code
- Exact commands with expected output
- DRY, YAGNI, TDD, frequent commits

## Self-review the spec — both modes, no human gate

After `spec.md` + `tasks.md` are written, review them before implementation. This runs in **both** `autonomous` and `reviewed`. The user is **not** asked to review — design approval already gated the work.

**Author pass (inline, you):**

1. **Spec coverage** — skim each requirement in `design.md` and each spec section. Can you point to a task that implements it? List and close any gaps.
2. **AC coverage** — every `AC-N` in `spec.md` is referenced by at least one task's `AC:` field, and no task cites an `AC-N` that does not exist.
3. **Placeholder scan** — no `{{}}`, "TBD", "TODO", or "No Placeholders"-list red flags survive.
4. **Type consistency** — types, method signatures, and property names match across tasks (a `clearLayers()` in Task 3 but `clearFullLayers()` in Task 7 is a bug).

Fix issues inline.

**Gates (run in order):**

1. **Mechanical** — run the validator bundled with the `sw` skill: `.agents/skills/sw/scripts/validate-spec.sh <spec-folder>` (in the specwright dev repo it is at `skills/sw/scripts/validate-spec.sh`); a non-zero exit names a structural defect (missing frontmatter key, surviving `{{placeholder}}`, vague-verb AC, or an `AC-N` no task references). Fix and re-run until it exits 0.
2. **Spec-document-reviewer subagent** — dispatch it (see `spec-document-reviewer-prompt.md`) over `spec.md` + `tasks.md`. If Issues Found: fix, re-dispatch, repeat until Approved (max 3 iterations, then surface to human).
3. **`/sw:review-spec`** — the external evaluator (conventions + design compliance, vague ACs, duplication). Fix any `FAIL`.

## Execution Handoff

After the spec self-review passes, follow the `AGENTS.md` `### Spec flow` tail:

- **handoff = yes (either mode)** → print a ```` ```txt ```` **handoff prompt** (a one-paragraph summary + the paths to `design`/`spec`/`tasks` + the mode) and stop. The user runs `/compact` (or opens a new chat) and pastes it to resume. **Never hand off before the artifacts exist.**
- **handoff = no** → implement. **Decide the execution approach yourself** based on task count and complexity — do not ask the user to choose:
  - **Subagent-Driven** (large, 5+ tasks, many files, complex migrations): dispatch a fresh subagent per task, reviewing between tasks before starting the next.
  - **Inline Execution** (small, < 5 tasks, focused changes): execute the tasks in this session, checkpointing after each.
  - Announce which approach you chose and start immediately.
- **Delivery** (after implement → quality gate): `autonomous` opens the PR (`/sw:new-pr`) and runs the `sw:code-review` cycle to `lgtm` on its own; `reviewed` first asks "open the PR and run code-review?", then does the same.
