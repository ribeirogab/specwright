---
name: run
user-invocable: false
description: "Conduct a specwright delivery: read the board, dispatch every ready change to the sw-change-owner role (parallel, one worktree each), track progress, apply circuit breakers, and close out with delivery reconciliation, learnings promotion, and a final report. Resumable from any fresh session. Trigger on '/sw:run', '$sw:run', '/sw-run', 'run the delivery', 'continue the delivery', or when the user asks to resume conducting a delivery."
---

# run — the delivery orchestrator

Conduct a delivery from its board to done. The orchestrator is a **pure conductor**: it reads and writes delivery state, dispatches change owners, tracks, reports, and escalates. It **never touches code** — not one file outside the delivery folder. If you catch yourself about to implement something, stop: that work belongs to a change owner.

**Announce at start:** "Conducting the delivery..."

## Preflight — commit mode

Detect the commit mode before locating anything, and set `mode` for the loop below:

```bash
if git check-ignore -q .specwright/deliveries; then
  mode=local
  [ -d .specwright/deliveries ] || { echo "local-mode vault not found in this checkout; invoke sw:run from the checkout where you initialized specwright in local mode"; exit 1; }
else
  mode=shared
fi
```

- **`shared`** → conduct as normal; git carries the artifacts across worktrees.
- **`local`** → the vault, `AGENTS.override.md`, its `CLAUDE.local.md` adapter, the `sw-*` Codex role profiles, and the `.opencode/agent/sw-*.md` and `.opencode/command/sw-*.md` files are git-ignored, so `git worktree add` cannot carry them into an owner's worktree and git cannot sync an owner's artifacts back. specwright bridges the owner contract and change folder with an explicit copy in, then transports only the change folder back out (the loop's local-mode branches below); because the `.gitignore` lines are committed in `local` mode, every copied artifact lands git-ignored in the worktree, so an owner never commits it.
  - The `git check-ignore` probe reports `local` from **any** worktree (the `.gitignore` is committed and present in every checkout). The separate `[ -d .specwright/deliveries ]` test asks whether *this* checkout actually holds the vault — in `local` mode the vault lives only where `sw:init` ran.
  - **Vault absent here** → **stop** with the message above and dispatch nothing: an externally-created worktree (e.g. one under `.claude/worktrees/`) is not the conductor's home.
  - **Vault present** → this checkout is the **canonical vault**; conduct with the loop's local-mode adaptations.

## Locate the delivery

1. `$ARGUMENTS` names a slug → `.specwright/deliveries/*<slug>*/`.
2. Otherwise scan `.specwright/changes/*/change.md` — exactly one delivery has changes (linked by their `delivery:` frontmatter) not yet `shipped` → use it; several → ask which.
3. Read `delivery.md`, `board.md`, and every change's `change.md` frontmatter. All state lives in these files — that is why any fresh session can resume with this skill and nothing else.

## The loop

Repeat until no change is ready and none is running:

1. **Find ready changes** — every change whose `change.md` says `status: pending` and whose board dependencies all say `status: shipped`. In `shared` mode readiness reads each dependency's `change.md` **from the dependency's own branch** (its worktree or branch checkout): while the dependency's PR is unmerged, the `main` copy still says `pending` — the on-branch copy is the truth. In **`local`** mode there is no on-branch copy (the artifacts are git-ignored); readiness reads each dependency's `status:` from the **canonical vault** — this checkout's own `.specwright/`, kept current by the sync-back in Track.
2. **Dispatch one change owner per ready change** — all of them, in parallel, no concurrency cap. Interactive approval asks are scoped to **this round's writes** (its worktrees, branches, commits, pushes, PRs) — never the whole delivery; a later round is a new loop turn and requires a new ask. For each:
   - Branch from `main` — or, when a dependency's PR is not yet merged, stack on the dependency's branch: the owner branches from it, notes the stacked base in the PR body, and re-targets the PR onto `main` after the dependency merges.
   - **Worktree is mandatory for parallel dispatch** — two owners in one working tree trample each other:
     ```bash
     git worktree add .specwright/worktrees/<slug> -b <branch>
     ```
    - **In `local` mode, copy the tri-host contract and change folder into the new worktree** right after creating it — otherwise the owner starts without its instructions, Claude adapter, Codex role profiles, OpenCode agent and command files, or change (git carries only tracked content). All copied paths land git-ignored in the worktree (the `.gitignore` lines are committed), so the owner never commits them. `<slug>` is the change slug you fill per dispatch; `$CHANGE_REL` is the change folder's repo-relative path (`.specwright/changes/<date>-<slug>`):
      ```bash
      if [ "$mode" = local ]; then
        WORKTREE=".specwright/worktrees/<slug>"
        cp AGENTS.override.md "$WORKTREE/AGENTS.override.md"
        ln -s AGENTS.override.md "$WORKTREE/CLAUDE.local.md"
        mkdir -p "$WORKTREE/.codex/agents"
        cp .codex/agents/sw-*.toml "$WORKTREE/.codex/agents/"
        mkdir -p "$WORKTREE/.opencode/agent" "$WORKTREE/.opencode/command"
        cp .opencode/agent/sw-*.md "$WORKTREE/.opencode/agent/"
        cp .opencode/command/sw-*.md "$WORKTREE/.opencode/command/"
        mkdir -p ".specwright/worktrees/<slug>/$CHANGE_REL"
        cp -R "$CHANGE_REL/." ".specwright/worktrees/<slug>/$CHANGE_REL/"
      fi
      ```
   - **Dispatch the `sw-change-owner` subagent** — it pins the owner's model + effort and routes into the shared `sw:plan` workflow. Its prompt is just the coordinates: the change folder path, the delivery path, and the worktree path. The pipeline it runs (plan → self-review → implement → quality gate → runtime verification → PR → review to `lgtm` → curate `learnings.md` → flip `change.md` status) and the return contract — `shipped` (+ PR URL + one line per learning) or `blocked` (+ a paste-ready Blockers block, **Why / Tried / Needs**, written by the owner for the board) — live in the role definition and shared workflow, not this prompt. Inside the change, the owner derives **waves** from the schema-2 task graph (`Depends on:` + `Files:` ownership): a wave is a dependency-ready, file-disjoint set of isolated tasks that may run in parallel — computed at dispatch time, never persisted.
   - Append `dispatched` to the board's Dispatch Log and commit — the per-append commit rule (Track, below) starts with this first append.
   - Keep the **agentId** from the spawn result — name aliases expire; address every resume or relay by that ID, never by name. Treat relays as one-way: read the owner's answers from repository artifacts, not from message replies.
3. **Track** — as each owner returns, append the event to the Dispatch Log, and **commit the board after every Dispatch Log append** — not only at round close; an uncommitted line is lost to a crash. On `shipped`: note the learnings one-liners and PR URL. On `blocked`: paste the owner's paste-ready Blockers block (Why / Tried / Needs) into the board's Blockers section **unmodified** — the conductor never composes or restructures it. Owners flip their own `change.md` status; the orchestrator never edits a `change.md`.
    - **In `local` mode, sync only the returned owner's change folder back into the canonical vault first** — this is how the owner's flipped `status:` and its `spec.md`/`tasks.md`/`learnings.md` reach the vault (git-ignored artifacts have no branch to carry them, and readiness reads the vault). Never sync instructions, Codex profiles, or OpenCode files back: they are canonical conductor state, not owner output.
     ```bash
     if [ "$mode" = local ]; then
       cp -R ".specwright/worktrees/<slug>/$CHANGE_REL/." "$CHANGE_REL/"
     fi
     ```
     This is **transport, not authorship** — the orchestrator moves the owner's own files to the canonical location (git's stand-in) and never composes or edits their content, so the boundary above holds. Also in `local` mode the board is git-ignored, so the per-append **commit** is a no-op; the board persists by file write in the canonical vault (there is no branch to lose an uncommitted line to).
   - Completion notifications reach only the top-level session — never wait on them. Poll each dispatched owner's **observable state** (repository files, branches, commit and output timestamps) on a cadence of a few minutes; treat silence as still-running only until a state check says otherwise.
   - **Watchdog:** 10 minutes without observable progress from an owner → flag it and verify its state directly; a confirmed stall is resumed by its agentId or re-dispatched.
4. **Re-evaluate** — newly shipped changes may make others ready (and their learnings now feed those changes' plans). Go to 1.

## Progress reporting

A long conduction that only speaks in prose leaves the maintainer in the dark. Surface state as a **visual progress panel**, and end every text status update with a **compact progress line**. Render the panel with whatever visual capability the session has — the reference rendering is the visualize `show_widget`, flat claude.ai style — but the contract below is the *structure and the content*, never a specific renderer: a session with a visual widget draws the panel, a session without one emits the same content as a text table (see Degradation, below). Describe what to render, not which tool to call.

**When to render the panel** — two triggers:

- On **any progress question** from the maintainer ("how's it going?", "status?", "onde estamos?") — render on demand, mid-round, without waiting for a boundary.
- At **round transitions** — at the loop's re-evaluate step, when a round has just closed and the next is about to open.

**Panel structure**, top to bottom:

1. **KPI row** — four metric cards: **overall weighted %** (shipped changes plus the in-flight fraction, not just the shipped count); **shipped count** `N / total` with the PR range; **in-progress count** with which change(s) are running; **findings-in-dossier count**.
2. **Overall stacked progress bar** — three segments in one bar: shipped (green, reference `#1D9E75`), in-flight (amber, reference `#EF9F27`), queued (the surface/track color); caption `X shipped · Y rodando · Z na fila`.
3. **Per-change row list, in board order** — one row per change: an **88px status-chip pill** (`shipped` / `rodando` / `na fila`), then the change name (weight up when active or done), then a **muted one-liner** (its test id, key result, or PR number).
4. **Sub-delivery section(s)** below a hairline — the same stacked-bar shape plus a one-line status, when the delivery has sub-deliveries.

The reference hex palette records the approved look so a future renderer reproduces it; the **structure** — which elements, in which order, carrying which metrics — is the contract, not any hex value.

**Compact progress line** — every text status update during conduction **ends with a one-line summary**, so the maintainer reads progress at a glance even without the full panel. It carries, in order: overall **%**, shipped **X of N**, the **currently running change(s)**, and the **queued count**. Reference format:

```
Progresso: ~NN% — X/N shipped · <current> rodando (~NN%) · Y na fila
```

The line's **language follows the conversation** — the reference above is pt-BR because that conduction was pt-BR; an English conduction writes the English equivalent with the same fields in the same order. Fill the fields from live state; never omit the line from a status update.

**Degradation — no visual rendering capability.** A session that cannot draw the panel does **not** skip the update: it emits the panel content as a **text table** — the four KPI numbers, then one table row per change (chip label, name, one-liner) — followed by the compact line. The update is never silently dropped; only its rendering degrades.

## Circuit breakers

- **Owner-level (enforced by the plan skill, restated in the dispatch prompt):** the same gate or criterion failing **three times identically** → stop, write the report, set `status: blocked`, return. No thrashing, no "one more try".
- **Orchestrator-level:** a blocked change never blocks the loop — skip to the next ready change. The loop **halts** only when nothing is ready and nothing is running:
  - **All changes shipped** → closeout (below).
  - **Only blocked changes left** → print a consolidated blockers report (every Blockers entry + what each needs from the human) and stop. Each entry's recovery line must be executable by a maintainer ignorant of the branch mechanics and must sweep the rest of the ticket for restatements of the dropped constraint. In shared mode, name the exact `change.md` inside the change checkout, set `status:` back to `pending`, and commit the edit on that change branch. In local mode, name the canonical ignored `change.md` in the orchestrator vault, set `status:` back to `pending`, and do not create a Git commit. Then re-run this skill.
- **Scope guard (conduction loop):** while the loop runs, the orchestrator never creates or removes changes, never reorders the board's dependencies, and never edits `delivery.md` — the one exception is closeout's delivery reconciliation, applied only with the maintainer's approval. Concluding the decomposition was wrong IS a blocker — report it and stop.

## Closeout (all shipped)

1. **Reconcile `delivery.md`** — flag any statement superseded by decisions recorded during conduction (board notes, blocker resolutions); propose the reconciling edit; **apply only with the maintainer's approval**. Nothing superseded → say so and move on.
2. **Promote durable learnings** — read every change's `learnings.md`; propose the facts that outlive the delivery (data formats, invariants, conventions) for promotion into the applicable canonical `AGENTS.md`/`AGENTS.override.md` or `.specwright/conventions/`. **Apply only what the user approves.** Ephemeral learnings stay in the change folders as history. Never edit a Claude adapter symlink as the source.
3. Append a final summary to the board: changes shipped, PR URLs, blockers survived. Written **after** the reconciliation and promotion approvals above; if a draft went in earlier, amend only within the appended summary section — the rest of the board stays frozen.
4. Report to the user: the delivery is done; merging the PRs is theirs.

## Degradation — no sub-agent support

When the agent cannot spawn sub-agents, the session itself acts as each change's owner, **serially, one change at a time**: same pipeline, same gates, same circuit breakers, same learnings. Worktrees are unnecessary in serial conduction (work in place on each change's branch). Everything else — the board, the log, the blocker reports — is identical.

## Boundaries

- Never edit code, tests, or docs outside the delivery folder — dispatch an owner.
- Never approve reviews or merge PRs — `lgtm` comes from the `sw:review` workflow inside each change's pipeline; merging is the human's.
- Never rewrite Dispatch Log history — it is append-only.
- Natural language works: "continue the delivery" in a fresh session must behave exactly like the explicit host surface (`/sw:run` in Claude Code, `$sw:run` in Codex, `/sw-run` in OpenCode).
