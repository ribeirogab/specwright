---
name: sw-run
description: "Conduct a specwright milestone: read the board, dispatch every ready issue to an issue-owner sub-agent (parallel, one worktree each), track progress, apply circuit breakers, and close out with goal reconciliation, learnings promotion, and a final report. Resumable from any fresh session. Trigger on '/sw:run', 'run the milestone', 'continue the milestone', or when the user asks to resume conducting a milestone."
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
   - **Model routing** — resolve the owner's model via `.specwright/models.md` (role `issue-owner`): role → tier → the binding for your agent, and spawn the owner on that model. No binding for your agent, or no such file → inherit the session model. The `effort` column there is advisory today — do not depend on it.
   - The owner's prompt: the issue folder path, the milestone path, the worktree path, and the instruction to run the **plan skill pipeline** end to end (plan → self-review → implement → quality gate → runtime verification → PR → review to `lgtm` → curate `learnings.md` → flip `issue.md` status), returning either `shipped` (+ PR URL + one line per learning) or `blocked` (+ a paste-ready Blockers block — **Why / Tried / Needs** — written by the owner for the board).
   - Append `dispatched` to the board's Dispatch Log and commit — the per-append commit rule (Track, below) starts with this first append.
   - Keep the **agentId** from the spawn result — name aliases expire; address every resume or relay by that ID, never by name. Treat relays as one-way: read the owner's answers from repository artifacts, not from message replies.
3. **Track** — as each owner returns, append the event to the Dispatch Log, and **commit the board after every Dispatch Log append** — not only at round close; an uncommitted line is lost to a crash. On `shipped`: note the learnings one-liners and PR URL. On `blocked`: paste the owner's paste-ready Blockers block (Why / Tried / Needs) into the board's Blockers section **unmodified** — the conductor never composes or restructures it. Owners flip their own `issue.md` status; the orchestrator never edits an `issue.md`.
   - Completion notifications reach only the top-level session — never wait on them. Poll each dispatched owner's **observable state** (repository files, branches, commit and output timestamps) on a cadence of a few minutes; treat silence as still-running only until a state check says otherwise.
   - **Watchdog:** 10 minutes without observable progress from an owner → flag it and verify its state directly; a confirmed stall is resumed by its agentId or re-dispatched.
4. **Re-evaluate** — newly shipped issues may make others ready (and their learnings now feed those issues' plans). Go to 1.

## Progress reporting

A long conduction that only speaks in prose leaves the maintainer in the dark. Surface state as a **visual progress panel**, and end every text status update with a **compact progress line**. Render the panel with whatever visual capability the session has — the reference rendering is the visualize `show_widget`, flat claude.ai style — but the contract below is the *structure and the content*, never a specific renderer: a session with a visual widget draws the panel, a session without one emits the same content as a text table (see Degradation, below). Describe what to render, not which tool to call.

**When to render the panel** — two triggers:

- On **any progress question** from the maintainer ("how's it going?", "status?", "onde estamos?") — render on demand, mid-round, without waiting for a boundary.
- At **round transitions** — at the loop's re-evaluate step, when a round has just closed and the next is about to open.

**Panel structure**, top to bottom:

1. **KPI row** — four metric cards: **overall weighted %** (shipped issues plus the in-flight fraction, not just the shipped count); **shipped count** `N / total` with the PR range; **in-progress count** with which issue(s) are running; **findings-in-dossier count**.
2. **Overall stacked progress bar** — three segments in one bar: shipped (green, reference `#1D9E75`), in-flight (amber, reference `#EF9F27`), queued (the surface/track color); caption `X shipped · Y rodando · Z na fila`.
3. **Per-issue row list, in board order** — one row per issue: an **88px status-chip pill** (`shipped` / `rodando` / `na fila`), then the issue name (weight up when active or done), then a **muted one-liner** (its test id, key result, or PR number).
4. **Sub-milestone section(s)** below a hairline — the same stacked-bar shape plus a one-line status, when the milestone has sub-milestones.

The reference hex palette records the approved look so a future renderer reproduces it; the **structure** — which elements, in which order, carrying which metrics — is the contract, not any hex value.

**Compact progress line** — every text status update during conduction **ends with a one-line summary**, so the maintainer reads progress at a glance even without the full panel. It carries, in order: overall **%**, shipped **X of N**, the **currently running issue(s)**, and the **queued count**. Reference format:

```
Progresso: ~NN% — X/N shipped · <current> rodando (~NN%) · Y na fila
```

The line's **language follows the conversation** — the reference above is pt-BR because that conduction was pt-BR; an English conduction writes the English equivalent with the same fields in the same order. Fill the fields from live state; never omit the line from a status update.

**Degradation — no visual rendering capability.** A session that cannot draw the panel does **not** skip the update: it emits the panel content as a **text table** — the four KPI numbers, then one table row per issue (chip label, name, one-liner) — followed by the compact line. The update is never silently dropped; only its rendering degrades.

## Circuit breakers

- **Owner-level (enforced by the plan skill, restated in the dispatch prompt):** the same gate or criterion failing **three times identically** → stop, write the report, set `status: blocked`, return. No thrashing, no "one more try".
- **Orchestrator-level:** a blocked issue never blocks the loop — skip to the next ready issue. The loop **halts** only when nothing is ready and nothing is running:
  - **All issues shipped** → closeout (below).
  - **Only blocked issues left** → print a consolidated blockers report (every Blockers entry + what each needs from the human) and stop. Each entry's recovery line must be executable by a maintainer ignorant of the branch mechanics: name the exact `issue.md` path **inside the issue's own checkout** (its worktree or branch — the `main` copy is read by nobody in the loop), instruct editing it per the chosen option and setting `status:` back to `pending`, **committing the edit on the issue's branch**, and sweeping the rest of the ticket for restatements of the dropped constraint (a constraint rarely lives in a single hunk). Then re-run this skill.
- **Scope guard (conduction loop):** while the loop runs, the orchestrator never creates or removes issues, never reorders the board's dependencies, and never edits `goal.md` — the one exception is closeout's goal reconciliation, applied only with the maintainer's approval. Concluding the decomposition was wrong IS a blocker — report it and stop.

## Closeout (all shipped)

1. **Reconcile `goal.md`** — flag any goal statement superseded by decisions recorded during conduction (board notes, blocker resolutions); propose the reconciling edit; **apply only with the maintainer's approval**. Nothing superseded → say so and move on.
2. **Promote durable learnings** — read every issue's `learnings.md`; propose the facts that outlive the milestone (data formats, invariants, conventions) for promotion into the area `AGENTS.md` or `.specwright/conventions/`. **Apply only what the user approves.** Ephemeral learnings stay in the issue folders as history.
3. Append a final summary to the board: issues shipped, PR URLs, blockers survived. Written **after** the reconciliation and promotion approvals above; if a draft went in earlier, amend only within the appended summary section — the rest of the board stays frozen.
4. Report to the user: the milestone is done; merging the PRs is theirs.

## Degradation — no sub-agent support

When the agent cannot spawn sub-agents, the session itself acts as each issue's owner, **serially, one issue at a time**: same pipeline, same gates, same circuit breakers, same learnings. Worktrees are unnecessary in serial conduction (work in place on each issue's branch). Everything else — the board, the log, the blocker reports — is identical.

## Boundaries

- Never edit code, tests, or docs outside the milestone folder — dispatch an owner.
- Never approve reviews or merge PRs — `lgtm` comes from `/sw:review` inside each issue's pipeline; merging is the human's.
- Never rewrite Dispatch Log history — it is append-only.
- Natural language works: "continue the milestone" in a fresh session must behave exactly like `/sw:run`.
