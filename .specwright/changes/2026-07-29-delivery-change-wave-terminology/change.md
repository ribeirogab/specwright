---
feature: delivery-change-wave-terminology
created: 2026-07-29
status: in-progress
shipped: null
delivery: null
---
# Delivery, Change, and Wave Terminology — Change

> The ticket: the approved *why* plus the acceptance criteria and the change's status. `status:` lives **only** here — `pending | in-progress | shipped | blocked` — and `shipped:` gets the ship date when the PR is open and `/sw:review` reached `lgtm`. The technical *how* (architecture, file structure, tasks) lives in the sibling `spec.md` + `tasks.md`. Delivery membership is data: the `delivery:` frontmatter key holds the parent delivery folder, or `null` for a standalone change like this one.

**GitHub issue:** https://github.com/ribeirogab/specwright/issues/66

## Purpose

Rename specwright's workflow vocabulary and artifact layout to tracker-neutral terms — **Delivery** (was milestone), **Change** (was issue), **Task** (unchanged), **Wave** (new execution concept: a dependency-ready, file-disjoint set of isolated tasks that may run in parallel) — across the plugin's templates, skills, agents, scripts, references, and repo docs. Every change gets one canonical flat path under `.specwright/changes/`; delivery membership is frontmatter data, not directory nesting. Active legacy work is migrated automatically; after the migration the tooling speaks only the new vocabulary.

## Motivation

Specwright currently uses `milestone` and `issue` for its local workflow artifacts. Those names collide with external planning and tracking systems — especially Linear — and make prompts like "create an issue" or "run the milestone" ambiguous: it is unclear whether a conversation refers to a specwright artifact or an external tracker object. A tracker-neutral vocabulary removes the ambiguity, gives every change one canonical path regardless of delivery membership, makes agent roles and authority easier to explain, keeps `wave` as a precise execution concept (derived from the task dependency and file-ownership graph, never persisted as folders), and forces future tracker integrations to use explicit names like "Linear issue".

## Non-Goals

- **No rewriting shipped history.** Legacy `.specwright/issues/` and `.specwright/milestones/` folders whose work is fully shipped stay on disk, untouched, as archive. Only active (non-shipped) legacy artifacts are moved.
- **No legacy read support.** The cut is immediate: after migration, validators, skills, and commands address only the new vocabulary and layout. Legacy folders are dead archive, not a compatibility surface.
- **No pipeline behavior change beyond names and layout.** The steps, gates, and contracts of brainstorm → spec → plan → run → review → pr stay as they are; only the vocabulary, paths, and wave formalization change.
- **No public `delivery-conductor` role.** Delivery orchestration remains an internal responsibility of `/sw:run`; no new agent definition is added.
- **No slash-command renames.** `/sw:brainstorm`, `/sw:spec`, `/sw:plan`, `/sw:run`, `/sw:review`, `/sw:review-spec`, `/sw:pr`, `/sw:init` keep their names.
- **No tracker integration work.** This change renames specwright's own artifacts only; GitHub/Linear integration behavior is out of scope.

## Acceptance Criteria

Number each criterion sequentially as `AC-N` — the IDs are stable handles that `tasks.md` references and that `/sw:review` walks to prove every criterion was delivered. Each criterion is a binary, observable check verifiable in under a minute.

- [ ] **AC-1** `plugins/sw/templates/` contains exactly `change.md`, `delivery.md`, `board.md`, `spec.md`, and `tasks.md` — no `issue.md`, no `goal.md` — and the `change.md` template frontmatter carries a `delivery:` key.
- [ ] **AC-2** `plugins/sw/agents/` contains `change-owner.md` and no `issue-owner.md`; `change-owner.md` preserves the old definition's frontmatter values (`model: opus`, `effort: xhigh`, `skills:` listing `plan`).
- [ ] **AC-3** Grepping `plugins/sw/` for `milestone`, `issue-owner`, and specwright-artifact uses of `issue` yields hits only inside (a) the designated legacy-migration passage of the `init` skill and (b) references to external tracker objects (e.g. GitHub issues); every hit is classified during verification.
- [ ] **AC-4** `plugins/sw/scripts/validate-spec.sh` prints `PASS` on a new-format change folder (`change.md` + `spec.md` + `tasks.md` with valid frontmatter), fails when `change.md` is missing, and no longer requires `issue.md`.
- [ ] **AC-5** Running `/sw:init` in a fixture repo containing legacy `.specwright/issues/` and `.specwright/milestones/` moves every non-shipped artifact into `.specwright/changes/` and `.specwright/deliveries/`, and leaves folders whose artifacts are all `status: shipped` untouched.
- [ ] **AC-6** No template or skill generates a per-delivery `issues/` subfolder: changes are written flat at `.specwright/changes/YYYY-MM-DD-<slug>/`, deliveries at `.specwright/deliveries/YYYY-MM-DD-<slug>/` with `delivery.md` + `board.md`.
- [ ] **AC-7** `plugins/sw/skills/run/SKILL.md` derives waves from the task dependency and file-ownership graph (no persisted wave folders) and names `change-owner` as its dispatch target; `plugins/sw/agents/` contains no `delivery-conductor.md`.
- [ ] **AC-8** `CLAUDE.md` and `README.md` describe the workflow using only Delivery/Change/Task/Wave vocabulary and the flat `.specwright/changes/` + `.specwright/deliveries/` layout.
- [ ] **AC-9** The new-version `validate-spec.sh` prints `PASS` for this change's own folder, `.specwright/changes/2026-07-29-delivery-change-wave-terminology/` — the first new-format specimen.

Tick each `[x]` when verified. Runtime verification checks each criterion by observed behavior before the PR opens; a criterion the agent cannot verify at runtime is marked `needs-human-verification` with the reason — never silently ticked.
