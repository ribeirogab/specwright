---
name: plan
user-invocable: false
description: "Use when an approved issue (issue.md) needs its technical plan — produces the fused spec.md + tasks.md just-in-time, self-reviews them, then drives the issue pipeline: implement, quality gate, runtime verification, PR, review to lgtm, learnings. The issue owner's skill."
---

# Plan — the issue pipeline, from ticket to shipped

Turn an approved issue (`issue.md`) into the **fused technical `spec.md`** (architecture, file structure, phase ordering) plus the **`tasks.md`** breakdown, then drive the pipeline to delivery. Whoever runs this skill is the **issue owner**: one owner per issue, owning the branch, the artifacts, the gates, and the issue's `learnings.md`.

Assume the implementing engineer has zero context for our codebase and questionable taste: document which files to touch for each task, the code, the docs they might need, and how to test it. DRY. YAGNI. TDD. Frequent commits.

**Announce at start:** "I'm using the plan skill to write the technical spec and tasks."

**Context:** runs after the issue exists — written by the brainstorm (standalone) or
by the milestone decomposition (dispatched by the `run` workflow: `/sw:run` in
Claude Code or `$sw:run` in Codex). Work in the issue's branch — or its worktree
under `.specwright/worktrees/<slug>`, if one was created.

## Locate the issue folder

- Standalone: `.specwright/issues/YYYY-MM-DD-<slug>/`
- Milestone: `.specwright/milestones/YYYY-MM-DD-<milestone-slug>/issues/<slug>/`

`spec.md` and `tasks.md` are written **just-in-time** into that folder, next to `issue.md`. Set `status: in-progress` in `issue.md` when you start.

## Inherit the learnings (milestone issues)

Before writing the spec for an issue that belongs to a milestone, read every **sibling** issue's `learnings.md` whose own `issue.md` says `status: shipped` (`../*/learnings.md`). These are curated, non-obvious facts earlier issues paid to discover — data formats, surprising API behavior, cross-cutting decisions, required workarounds. Fold every applicable one into the spec's Architecture/Constraints. A spec that trips over a recorded learning is a review blocker.

## Scope check

If the issue covers multiple independent subsystems, it should have been decomposed during the brainstorm (or on the milestone board). If it wasn't, stop and suggest splitting — for a milestone issue, that is a **blocked** report, not a unilateral board edit.

## Writing the technical spec (`spec.md`)

Copy the bundled template (`plugins/sw/templates/spec.md`) into the issue folder and fill it:

- **Frontmatter** — `feature`, `created`, `scope:` (your honest sizing: one of `low | medium | high | complex`; recorded only), the issue's `branch:`, `worktree:` (path or `null`), and `milestone:` (the milestone folder or `null`).
- **Architecture / File Structure / Phase Ordering** — the technical *how*. Map which files will be created or modified and what each is responsible for. Units with clear boundaries and one responsibility; smaller focused files over large ones; files that change together live together; follow the existing patterns of the codebase.
- **Acceptance criteria stay in `issue.md`** — the `AC-N` there are the approved contract. Do not duplicate them into the spec. If planning exposes a wrong or missing criterion: for a standalone issue, fix `issue.md` with the user; for a milestone issue, report it — changing approved ACs is a scope change, never a unilateral edit.

## Bite-sized task granularity (`tasks.md`)

**Each step is one action (2-5 minutes):** "Write the failing test" — step. "Run it to make sure it fails" — step. "Implement the minimal code to make the test pass" — step. "Run the tests" — step. "Commit" — step.

**Start `tasks.md` from the bundled template** (`plugins/sw/templates/tasks.md`) — keep its frontmatter and header note verbatim; the template is the single source of truth for the artifact's shape.

**Schema-2 task structure:**

````markdown
### T1: [Component Name]

**AC:** [AC-N it satisfies, e.g. AC-1, AC-3]
**Delegable:** [yes/no — one-line execution context]
**Depends on:** [none or comma-separated stable IDs such as T1, T2]
**Files:**
- Create: `exact/repository-relative/path.py`
- Modify: `exact/repository-relative/path.py`
**Integration:** [isolated or inline]
**Validation:** [one exact command that verifies this task]

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

Every heading has a unique, stable `Tn` ID. Dependencies must name existing IDs
and be acyclic. `Delegable: yes` pairs only with `Integration: isolated`, explicit
owned paths, and a non-empty validation command. `Delegable: no` pairs only with
`Integration: inline`; when it owns no path, `Files:` contains exactly `- None`.
Two independent isolated tasks eligible for the same dependency wave may not own
the same normalized path. A direct or transitive dependency permits sequential
ownership in a later wave.

Every `AC-N` defined in `issue.md` must be named by at least one task's `AC:` field
— the traceability contract the validator and the host's `sw:review` workflow
enforce.

**No placeholders.** Never write: "TBD", "TODO", "implement later", "add appropriate error handling", "write tests for the above" (without actual test code), "similar to Task N" (repeat the code), steps that describe without showing, or references to types/functions no task defines. Exact file paths, complete code in code steps, exact commands with expected output.

## Self-review the spec — no human gate

After `spec.md` + `tasks.md` are written, review them before implementation. The
user is not asked for another design/content review — the issue's approval already
gated the workflow. That approval never overrides the current host's sandbox,
permission, command-approval, Git, or external-action policy.

**Author pass (inline, you):**

1. **Coverage** — every requirement in `issue.md` maps to a task; list and close gaps.
2. **AC coverage** — every `AC-N` in `issue.md` is referenced by at least one task's `AC:` field; no task cites a nonexistent `AC-N`.
3. **Placeholder scan** — no double-brace survivors, no "TBD"/"TODO".
4. **Type consistency** — names and signatures match across tasks.

**Gates (run in order):**

1. **Mechanical** — `plugins/sw/scripts/validate-spec.sh <issue-folder>`; non-zero exit names the structural defect. Fix and re-run until it exits 0 — with one exception: a failure caused by the approved ticket itself (`issue.md`) means **stop and report it with the exact validator `FAIL` line** — to the user (standalone) or in a blocked report to the orchestrator (milestone) — and proceed only after an acknowledged resolution. The owner never rewords an approved criterion; any ticket edit is its own commit naming the changed criterion.
2. **Spec-document-reviewer subagent** — dispatch the `sw-spec-document-reviewer` subagent over `issue.md` + `spec.md` + `tasks.md` (pass the three paths; its rubric and its model + effort live in the agent definition). Fix, re-dispatch until Approved (max 3 iterations, then surface to the human).
3. **`sw:review-spec`** — invoke `/sw:review-spec` in Claude Code or
   `$sw:review-spec` in Codex. Fix every external-evaluator `FAIL`.

**Commit the plan** — when the three gates pass, commit `spec.md` + `tasks.md` (including any gate fixes) before the first implementation commit. The PR body's quality-gate section must name these three gates and their outcomes — a repo-only auditor must be able to verify the gates ran.

## Implement — owner-controlled task integration

The issue owner is the only agent that may edit the issue branch, issue artifacts,
`learnings.md`, or the pull request. Never give a worker the issue worktree. Inline
tasks run only in this owner session. Isolated tasks run only in task-specific
branches and worktrees and reach the issue branch only through owner-reviewed
cherry-picks.

### Build the execution graph

After the plan commit:

1. Parse the validated schema-2 task document and keep document order as the stable
   tie-breaker.
2. Track completed task IDs. A task is ready only when every `Depends on` ID is
   completed.
3. Execute ready `Integration: inline` tasks on the issue branch, one at a time;
   run their `Validation:` command and commit before marking them completed.
4. From the remaining ready `Integration: isolated` tasks, form one wave containing
   only tasks with pairwise-disjoint normalized `Files:` ownership. Check 6 already
   enforces this invariant; any disagreement means stop and replan.
5. Do not release a dependent task until its prior wave has been integrated and
   passed integrated validation.

No number-of-tasks heuristic overrides `Integration:`. One isolated task still gets
its own branch/worktree; ten inline tasks still stay with the owner.

### Create every task branch from one recorded issue HEAD

Immediately before dispatching a wave:

1. Require a clean issue worktree.
2. Record `base SHA` as the exact current issue `HEAD`. Every task in that wave
   starts from this same SHA.
3. Derive a task branch name from the repository's established convention and the
   task ID. Never reuse or reset an unrelated branch.
4. Resolve the shared repository root from the absolute Git common directory, so a
   task worktree is a sibling even when the issue itself already runs in a
   worktree:

   ```bash
   COMMON_GIT_DIR="$(git rev-parse --path-format=absolute --git-common-dir)"
   REPOSITORY_ROOT="$(dirname "$COMMON_GIT_DIR")"
   TASK_WORKTREE="$REPOSITORY_ROOT/.specwright/worktrees/<issue-slug>-<lowercase-task-id>"
   ```

5. Create the task worktree from that exact base:

   ```bash
   git worktree add \
     -b "<task-branch>" \
     "$TASK_WORKTREE" \
     "<base-sha>"
   ```

On resume, inspect an existing branch/worktree and verify its base and task identity;
never overwrite it. Worker worktrees remain after integration for human inspection.
Specwright never removes them automatically.

### Dispatch `sw-task-worker`

Send one worker this complete payload:

- issue slug, task ID, and the exact task block;
- task branch and absolute worktree path;
- the wave's `base SHA`;
- the normalized allowed file paths from `Files:`;
- the exact `Validation:` command;
- project conventions relevant to those paths;
- these prohibitions: no path outside the allowed list, no `.specwright/` artifact,
  no issue branch, no PR, no `learnings.md`, no integration of another branch, and
  no worktree removal.

The worker must stop as `blocked` when the allowed ownership is insufficient. It
never expands scope itself.

Require this return contract:

```text
status: completed | blocked
base SHA: <sha>
ordered commit SHAs:
- <sha>
touched paths:
- <repository-relative path>
validation:
- command: <exact command>
  result: <exit status and material output>
raw discoveries:
- <unfiltered fact, surprise, constraint, or workaround>
blocker: <why / tried / needs, only when blocked>
```

### Review before integration

For each completed worker, before changing the issue branch:

1. Confirm the returned `base SHA` equals the recorded wave base.
2. Verify every returned commit descends from that base, the ordered commit SHAs
   form the task branch's exact non-merge sequence, and the final SHA is its HEAD.
3. Require a clean worker worktree.
4. Compute `git diff --name-only <base-sha>..<final-sha>` and compare it with both
   the returned touched paths and the task's normalized allowed paths. Any
   undeclared path, `.specwright/` path, or ownership overlap rejects the result.
5. Read the complete diff, not only its path list. Confirm it implements only the
   task and that the exact validation command ran successfully with credible
   evidence.
6. Record the worker's raw discoveries for later owner curation; workers never edit
   `learnings.md`.

Reject an unverifiable SHA, merge commit, dirty worktree, path mismatch, missing
evidence, or scope change. Replan or redelegate instead of repairing an unsafe
worker result on the issue branch.

### Cherry-pick accepted commits

On the issue branch, cherry-pick only accepted commits, in the returned order:

```bash
git cherry-pick <first-sha> <next-sha>
```

A **mechanical conflict** has one behaviorally predetermined resolution, limited to
formatting, import order, generated lockfile reconciliation, or adjacent-line
placement. The owner may resolve it, inspect the resulting diff, continue the
cherry-pick, and rerun validation.

A **semantic conflict** requires a behavior choice, changes ownership, overlaps
another task, expands scope, or contradicts the task/spec. Abort that integration
attempt and replan or redelegate; never guess. The same rule applies even when Git
reports no textual conflict but review exposes semantic overlap.

### Gate each wave

After all accepted commits in a wave are present, run every task's validation plus
the integrated validation for the combined touched area. Do not release dependents
until all pass. If integrated validation exposes an interaction, keep dependents
blocked and replan the affected task ownership or implementation. Retain every task
branch/worktree regardless of acceptance so the human can inspect it.

## Quality gate

Detect the touched modules' code-quality processes (test, lint, typecheck, build — Makefile, `package.json` scripts, the area's CI) and run them all; nothing you did may break them. Logic added or changed in a tested area without a test → write the missing tests first. **Test integrity:** the touched area's test count must not silently drop, and assertions must not be weakened, skipped, or deleted to pass the gate without an in-spec justification.

## Runtime verification

After the quality gate and **before the PR**, execute what you built and check every `AC-N` by **observed behavior** — run the CLI, start the server and hit the endpoint, run the script against a fixture. Stream-sensitive checks must use per-stream file redirection (e.g. `>out 2>err`) — piping merged streams cannot attribute output to stdout vs stderr. For UI criteria — a **UI criterion** is one about rendered appearance or interaction, not HTTP responses or text output — verify through a browser when the agent has that capability; an unattended session that degrades browser verification to curl must record the capability gap alongside the result. When a criterion cannot be runtime-verified (no browser, no reachable environment), mark it `needs-human-verification` in `issue.md` with one line of reason — **never silently tick it, never fake a verification**. Record what was verified and how; it goes in the PR body.

**Circuit breaker:** the same gate or criterion failing **three times identically** means stop — do not thrash. Standalone issue: report to the user (why / what you tried / what you need). Milestone issue: write that report, set `status: blocked` in `issue.md`, and return it to the orchestrator.

## Deliver

Invoke the host's `sw:pr` workflow (`/sw:pr` or `$sw:pr`) and then `sw:review`
(`/sw:review` or `$sw:review`) to `lgtm`. The issue approval is standing workflow
consent, not a permission bypass: obtain any approval the current host requires for
Git, network, or external actions. Then:

1. **Curate learnings** — write the issue folder's `learnings.md`: only non-obvious facts **future issues need** (data formats, surprising behaviors, cross-cutting constraints, required workarounds). Not narration of what you did, not internals only this issue touches. No qualifying fact → no file.
2. **Ship** — set `issue.md` `status: shipped` + `shipped:` date, tick the verified `AC-N` checkboxes. On the issue's own branch, part of its PR.
3. Milestone issue: report back one line per learning + the PR URL — the orchestrator logs them on the board.
