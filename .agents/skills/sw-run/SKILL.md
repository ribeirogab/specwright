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

1. **Find ready issues** — every issue whose `issue.md` says `status: pending` and whose board dependencies all say `status: shipped`. Readiness reads each dependency's `issue.md` **from the dependency's own branch** (its worktree or branch checkout): while the dependency's PR is unmerged, the `main` copy still says `pending` — the on-branch copy is the truth.
2. **Dispatch one issue owner per ready issue** — all of them, in parallel, no concurrency cap. Interactive approval asks are scoped to **this round's writes** (its worktrees, branches, commits, pushes, PRs) — never the whole milestone; a later round is a new loop turn and requires a new ask. For each:
   - Branch from `main` — or, when a dependency's PR is not yet merged, stack on the dependency's branch: the owner branches from it, notes the stacked base in the PR body, and re-targets the PR onto `main` after the dependency merges.
   - **Worktree is mandatory for parallel dispatch** — two owners in one working tree trample each other:
     ```bash
     git worktree add .specwright/worktrees/<slug> -b <branch>
     ```
   - The owner's prompt: the issue folder path, the milestone path, the worktree path, and the instruction to run the **plan skill pipeline** end to end (plan → self-review → implement → quality gate → runtime verification → PR → review to `lgtm` → curate `learnings.md` → flip `issue.md` status), returning either `shipped` (+ PR URL + one line per learning) or `blocked` (+ a paste-ready Blockers block — **Why / Tried / Needs** — written by the owner for the board).
   - Append `dispatched` to the board's Dispatch Log.
   - Keep the **agentId** from the spawn result — name aliases expire; address every resume or relay by that ID, never by name. Treat relays as one-way: read the owner's answers from repository artifacts, not from message replies.
3. **Track** — as each owner returns, append the event to the Dispatch Log, and **commit the board after every Dispatch Log append** — not only at round close; an uncommitted line is lost to a crash. On `shipped`: note the learnings one-liners and PR URL. On `blocked`: paste the owner's paste-ready Blockers block (Why / Tried / Needs) into the board's Blockers section **unmodified** — the conductor never composes or restructures it. Owners flip their own `issue.md` status; the orchestrator never edits an `issue.md`.
   - Completion notifications reach only the top-level session — never wait on them. Poll each dispatched owner's **observable state** (repository files, branches, commit and output timestamps) on a cadence of a few minutes; treat silence as still-running only until a state check says otherwise.
   - **Watchdog:** 10 minutes without observable progress from an owner → flag it and verify its state directly; a confirmed stall is resumed by its agentId or re-dispatched.
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
