---
feature: brainstorm-and-templates
created: 2026-07-02
status: shipped
shipped: 2026-07-02
---
# Brainstorm and Templates — Issue

> The ticket: the approved *why* plus the acceptance criteria and the issue's status. `status:` lives **only** here — `pending | in-progress | shipped | blocked` — and `shipped:` gets the ship date when the PR is open and `/sw:review` reached `lgtm`. The technical *how* (architecture, file structure, tasks) lives in the sibling `spec.md` + `tasks.md`, written just-in-time by `/sw:plan`.

## Purpose

Raise the quality bar of the planning artifacts the brainstorm skill produces: goals phrased in behavior terms, tickets that pass the mechanical validator before they are committed, a scope conclusion that does not name the milestone for small work, constraints stated once, and a vault-file rule that lets audit-style issues cite sibling evidence.

## Motivation

Dossier entries 3.1–3.5 (`.specwright/milestones/2026-07-02-e2e-validation/issues/closeout/dossier.md`). The e2e planner shipped a goal naming test files byte-for-byte and an on-disk format, and shipped a ticket that trips the validator's own check 4 — which later detonated in two owners' gates on a file they must not edit (the seed of the reword pattern fixed in the sibling `issue-pipeline-contract`). The trap ticket also restated one constraint in four passages, turning a one-line unblock into five hunks.

## Non-Goals

- Any plan, pr, or run skill change.
- Restructuring existing milestone artifacts already in the vault — the fixes apply to what the brainstorm produces from now on.

## Acceptance Criteria

Number each criterion sequentially as `AC-N` — the IDs are stable handles that `tasks.md` references (each task names the criteria it satisfies) and that `/sw:review` walks to prove every criterion was delivered. Each criterion must be a binary, observable check that someone other than the implementer can verify in under a minute. **No vague verbs** — replace them with specific, measurable conditions.

Runtime verification checks each criterion by observed behavior before the PR opens; a criterion the agent cannot verify at runtime is marked `needs-human-verification` with the reason — never silently ticked.

- [x] **AC-1** The brainstorm skill's milestone-writing step instructs phrasing the goal in behavior terms — no file paths, function names, or storage formats — includes one worked example translating a technical hard constraint into goal-level language, and states that path-level constraints live in issue tickets (dossier 3.1).
- [x] **AC-2** The brainstorm skill's decomposition step instructs running `validate-spec.sh` on each issue folder before committing, and states the planning-stage baseline: exactly one check-2 failure for the not-yet-written `spec.md`; anything else is the planner's to fix (dossier 3.2).
- [x] **AC-3** Checklist item 6 is reworded so small work concludes "single issue" without presenting the milestone alternative, and the milestone option (with decomposition preview) is presented only when the scope signals point to one (dossier 3.3).
- [x] **AC-4** The ticket-writing guidance contains the rule: state a hard constraint once and reference it elsewhere; every restatement is an amendment hazard (dossier 3.4).
- [x] **AC-5** `vault-files.md` carves out evidence-consuming issues: they may cite sibling-issue paths as plain text; link syntax remains banned (dossier 3.5).
- [x] **AC-6** The brainstorm skill's three shipped copies (`plugins/sw/skills/brainstorm/SKILL.md`, `.agents/skills/sw-brainstorm/SKILL.md`, `skills/sw/scaffold/skills/sw-brainstorm/SKILL.md`) differ only in the frontmatter `name:` line.

Tick each `[x]` when verified. An issue is **not shippable** with empty or double-brace-placeholder acceptance criteria — `validate-spec.sh` and `/sw:review-spec` will reject it.
