---
name: sw-run
description: "Conduct a specwright milestone: read the board, dispatch every ready issue to an issue-owner sub-agent (parallel, one worktree each), track progress, apply circuit breakers, and close out with a final report and learnings promotion. Resumable from any fresh session. Trigger on '/sw:run', 'run the milestone', 'continue the milestone', or when the user asks to resume conducting a milestone."
---

# run — the milestone orchestrator

Conduct a milestone from its board to done. The orchestrator is a **pure conductor**: it reads and writes milestone state, dispatches issue owners, tracks, reports, and escalates. It **never touches code** — not one file outside the milestone folder. If you catch yourself about to implement something, stop: that work belongs to an issue owner.

**Announce at start:** "Conducting the milestone..."

## Locate the milestone

1. `$ARGUMENTS` names a slug → `.specwright/milestones/*<slug>*/`.
2. Otherwise scan `.specwright/milestones/*/issues/*/issue.md` — exactly one milestone has issues not yet `shipped` → use it; several → ask which.
3. Read `goal.md`, `board.md`, and every issue's `issue.md` frontmatter. All state lives in these files — that is why any fresh session can resume with this skill and nothing else.

## The loop

Repeat until no issue is ready and none is running:

1. **Find ready issues** — every issue whose `issue.md` says `status: pending` and whose board dependencies all say `status: shipped`.
2. **Dispatch one issue owner per ready issue** — all of them, in parallel, no concurrency cap. For each:
   - Branch from `main` — or from the dependency's branch when the board says this issue depends on a not-yet-merged one (a stacked PR; the owner notes it in the PR body).
   - **Worktree is mandatory for parallel dispatch** — two owners in one working tree trample each other:
     ```bash
     git worktree add .specwright/worktrees/<slug> -b <branch>
     ```
   - The owner's prompt: the issue folder path, the milestone path, the worktree path, and the instruction to run the **plan skill pipeline** end to end (plan → self-review → implement → quality gate → runtime verification → PR → review to `lgtm` → curate `learnings.md` → flip `issue.md` status), returning either `shipped` (+ PR URL + one line per learning) or `blocked` (+ the report: why / tried / needs).
   - Append `dispatched` to the board's Dispatch Log.
3. **Track** — as each owner returns, append the event to the Dispatch Log. On `shipped`: note the learnings one-liners and PR URL. On `blocked`: copy the owner's report verbatim into the board's Blockers section. Owners flip their own `issue.md` status; the orchestrator never edits an `issue.md`.
4. **Re-evaluate** — newly shipped issues may make others ready (and their learnings now feed those issues' plans). Go to 1.

## Circuit breakers

- **Owner-level (enforced by the plan skill, restated in the dispatch prompt):** the same gate or criterion failing **three times identically** → stop, write the report, set `status: blocked`, return. No thrashing, no "one more try".
- **Orchestrator-level:** a blocked issue never blocks the loop — skip to the next ready issue. The loop **halts** only when nothing is ready and nothing is running:
  - **All issues shipped** → closeout (below).
  - **Only blocked issues left** → print a consolidated blockers report (every Blockers entry + what each needs from the human) and stop. When the human resolves a blocker, they set the issue back to `status: pending` (or edit its `issue.md`) and re-run this skill.
- **Scope guard:** the orchestrator never creates or removes issues, never reorders the board's dependencies, and never edits `goal.md`. Concluding the decomposition was wrong IS a blocker — report it and stop.

## Closeout (all shipped)

1. Append a final summary to the board: issues shipped, PR URLs, blockers survived.
2. **Promote durable learnings** — read every issue's `learnings.md`; propose the facts that outlive the milestone (data formats, invariants, conventions) for promotion into the area `AGENTS.md` or `.specwright/conventions/`. **Apply only what the user approves.** Ephemeral learnings stay in the issue folders as history.
3. Report to the user: the milestone is done; merging the PRs is theirs.

## Degradation — no sub-agent support

When the agent cannot spawn sub-agents, the session itself acts as each issue's owner, **serially, one issue at a time**: same pipeline, same gates, same circuit breakers, same learnings. Worktrees are unnecessary in serial conduction (work in place on each issue's branch). Everything else — the board, the log, the blocker reports — is identical.

## Boundaries

- Never edit code, tests, or docs outside the milestone folder — dispatch an owner.
- Never approve reviews or merge PRs — `lgtm` comes from `/sw:review` inside each issue's pipeline; merging is the human's.
- Never rewrite Dispatch Log history — it is append-only.
- Natural language works: "continue the milestone" in a fresh session must behave exactly like `/sw:run`.
