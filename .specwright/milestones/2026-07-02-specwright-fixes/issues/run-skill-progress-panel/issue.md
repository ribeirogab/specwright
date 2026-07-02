---
feature: run-skill-progress-panel
created: 2026-07-02
status: in-progress
shipped: null
---
# Run Skill Progress Panel — Issue

> The ticket: the approved *why* plus the acceptance criteria and the issue's status. `status:` lives **only** here — `pending | in-progress | shipped | blocked` — and `shipped:` gets the ship date when the PR is open and `/sw:review` reached `lgtm`. The technical *how* (architecture, file structure, tasks) lives in the sibling `spec.md` + `tasks.md`, written just-in-time by `/sw:plan`.

## Purpose

Give the run skill a "Progress reporting" section so that during long conductions the maintainer can read progress at a glance in a consistent visual format, and every text status update ends with a compact progress line.

## Motivation

Dossier entry 8.1 (`.specwright/milestones/2026-07-02-e2e-validation/issues/closeout/dossier.md`), user-requested 2026-07-02: multi-hour orchestration runs leave the maintainer in the dark. A reference rendering was approved during the e2e-validation conduction (recorded in that milestone board's Conduction notes) — this issue transcribes that approved standard into skill text; it does not design a new one.

## Non-Goals

- Any conduction-contract change (sibling issue `run-skill-contract`, which this issue depends on).
- Prescribing a specific rendering technology — the section describes structure and content; the conductor renders with whatever visual capability the session has, degrading to text when none exists.

## Acceptance Criteria

Number each criterion sequentially as `AC-N` — the IDs are stable handles that `tasks.md` references (each task names the criteria it satisfies) and that `/sw:review` walks to prove every criterion was delivered. Each criterion must be a binary, observable check that someone other than the implementer can verify in under a minute. **No vague verbs** — replace them with specific, measurable conditions.

Runtime verification checks each criterion by observed behavior before the PR opens; a criterion the agent cannot verify at runtime is marked `needs-human-verification` with the reason — never silently ticked.

- [x] **AC-1** The run skill contains a "Progress reporting" section specifying the panel structure top to bottom: a KPI row (overall weighted %, shipped count out of total, in-flight count with issue names, findings count), an overall stacked progress bar (shipped / running / queued with caption), a per-issue row list in board order with a status chip and a muted one-liner, and a sub-milestone section with the same bar shape.
- [x] **AC-2** The section states the two triggers: render the panel on any progress question from the maintainer and at round transitions.
- [x] **AC-3** The section mandates that every text status update during conduction ends with a compact one-line summary carrying overall %, shipped X of N, the currently running issue(s), and the queued count — with the line's field format spelled out in the skill and its language following the conversation.
- [x] **AC-4** The section states the degradation rule: sessions without a visual rendering capability emit the panel content as a text table plus the compact line, never skipping the update.
- [x] **AC-5** The run skill's three shipped copies (`plugins/sw/skills/run/SKILL.md`, `.agents/skills/sw-run/SKILL.md`, `skills/sw/scaffold/skills/sw-run/SKILL.md`) differ only in the frontmatter `name:` line.

Tick each `[x]` when verified. An issue is **not shippable** with empty or double-brace-placeholder acceptance criteria — `validate-spec.sh` and `/sw:review-spec` will reject it.
