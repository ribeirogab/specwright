---
feature: run-skill-contract
created: 2026-07-02
status: in-progress
shipped: null
---
# Run Skill Contract — Issue

> The ticket: the approved *why* plus the acceptance criteria and the issue's status. `status:` lives **only** here — `pending | in-progress | shipped | blocked` — and `shipped:` gets the ship date when the PR is open and `/sw:review` reached `lgtm`. The technical *how* (architecture, file structure, tasks) lives in the sibling `spec.md` + `tasks.md`, written just-in-time by `/sw:plan`.

## Purpose

Make the run skill's conduction contract explicit where the e2e validation proved the correct behavior is emergent, missing, or unexecutable: approval scoping, dispatch-log durability, branch-aware readiness, blocker-report fidelity, recovery instructions, closeout goal reconciliation, state-poll conduction with a watchdog, and agent addressing.

## Motivation

Dossier entries 1.1–1.6, 7.1, 7.2, 8.2 (`.specwright/milestones/2026-07-02-e2e-validation/issues/closeout/dossier.md`) — including every `high`-severity conduction finding. Four independent owners and two conductors did the right thing the skill never asks for (stacking on an unmerged dependency's branch, reconciling a stale goal with approval); the halt report's recovery line was not executable by a maintainer ignorant of the branch mechanics; and every round with dispatches reproduced the notification stall (7/7 after T9). Behavior that exists only by good judgment regresses silently.

## Non-Goals

- The visual progress panel (sibling issue `run-skill-progress-panel`, which depends on this one).
- Any change to plan, pr, brainstorm, or review skills.
- Session-driving methodology conventions (dossier 7.3–7.6) — recorded practice, not skill text.

## Acceptance Criteria

Number each criterion sequentially as `AC-N` — the IDs are stable handles that `tasks.md` references (each task names the criteria it satisfies) and that `/sw:review` walks to prove every criterion was delivered. Each criterion must be a binary, observable check that someone other than the implementer can verify in under a minute. **No vague verbs** — replace them with specific, measurable conditions.

Runtime verification checks each criterion by observed behavior before the PR opens; a criterion the agent cannot verify at runtime is marked `needs-human-verification` with the reason — never silently ticked.

- [x] **AC-1** The run skill's dispatch step states that interactive approval asks cover only the current round's writes, and that a later round is a new loop turn requiring a new ask (dossier 1.1).
- [x] **AC-2** The run skill's track step instructs committing the board after every Dispatch Log append, not only at round close (dossier 1.2).
- [x] **AC-3** The ready rule states that readiness reads the dependency's own-branch `issue.md`, and that an unmerged dependency means the new issue's branch stacks on the dependency's branch with a re-target step after the dependency merges (dossier 1.3).
- [x] **AC-4** The blocked-issue flow requires the owner to deliver a paste-ready Blockers block (Why/Tried/Needs) that the conductor pastes into the board unmodified, and the skill text no longer claims a "verbatim copy" the conductor composes (dossier 1.4).
- [x] **AC-5** The escalation contract requires the blocked report's recovery line to name the exact `issue.md` path inside the issue's own checkout, to instruct committing the edit on the issue's branch, and to remind the maintainer to sweep the ticket for restatements of the dropped constraint (dossier 1.5).
- [x] **AC-6** The closeout step includes goal reconciliation — flag any goal statement superseded by recorded decisions, propose the reconciling edit, apply only with the maintainer's approval — and the "never edits goal" scope guard is scoped to the conduction loop with closeout-with-approval as the stated exception (dossier 1.6, 9.1).
- [x] **AC-7** The closeout step states when the milestone summary is written relative to the promotion/reconciliation approvals: either deferred until after them, or amendable only within the appended section (dossier 9.2).
- [x] **AC-8** The conduction guidance instructs polling each dispatched agent's observable state (repository files, branches, output timestamps) on a cadence, treating silence as still-running only until a state check says otherwise, and arming a watchdog that flags a stated number of minutes without observable progress (dossier 7.1, 8.2).
- [x] **AC-9** The dispatch/resume guidance instructs keeping the agentId from the spawn result, addressing resumes and relays by that ID and never by name, treating relays as one-way, and reading answers from repository artifacts (dossier 7.2).
- [x] **AC-10** The run skill's three shipped copies (`plugins/sw/skills/run/SKILL.md`, `.agents/skills/sw-run/SKILL.md`, `skills/sw/scaffold/skills/sw-run/SKILL.md`) differ only in the frontmatter `name:` line, and the board template's Blockers wording matches AC-4's contract.

Tick each `[x]` when verified. An issue is **not shippable** with empty or double-brace-placeholder acceptance criteria — `validate-spec.sh` and `/sw:review-spec` will reject it.
