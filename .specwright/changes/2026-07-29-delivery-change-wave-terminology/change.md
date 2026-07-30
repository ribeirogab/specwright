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

Rename specwright's workflow vocabulary and artifact layout to tracker-neutral terms — **Delivery** (was milestone), **Change** (was issue), **Task** (unchanged), **Wave** (new execution concept: a dependency-ready, file-disjoint set of isolated tasks that may run in parallel) — across the plugin's templates, skills, agents, scripts, references, and repo docs. Every change gets one canonical flat path under `.specwright/changes/`; delivery membership is frontmatter data, not directory nesting. This repo's own legacy vault migrates in this same change (paths renamed, contents untouched); after it, the tooling speaks only the new vocabulary and the plugin carries zero legacy remnants.

## Motivation

Specwright currently uses `milestone` and `issue` for its local workflow artifacts. Those names collide with external planning and tracking systems — especially Linear — and make prompts like "create an issue" or "run the milestone" ambiguous: it is unclear whether a conversation refers to a specwright artifact or an external tracker object. A tracker-neutral vocabulary removes the ambiguity, gives every change one canonical path regardless of delivery membership, makes agent roles and authority easier to explain, keeps `wave` as a precise execution concept (derived from the task dependency and file-ownership graph, never persisted as folders), and forces future tracker integrations to use explicit names like "Linear issue".

## Non-Goals

- **No content rewrites during migration.** The vault migration renames paths only (`git mv`, `issue.md` → `change.md`, `goal.md` → `delivery.md`); the content of every shipped artifact stays byte-identical. Git history is preserved by the move.
- **No legacy remnant in the plugin.** After this change, `plugins/sw/` contains zero legacy vocabulary, zero legacy paths, and zero migration logic — no compatibility shims, no "also reads the old layout" branches, no migration passages in any skill, template, agent, command, script, or reference. The only permitted occurrences of `issue` name external tracker objects (e.g. GitHub issues).
- **No legacy read support.** Validators, skills, and commands address only the new vocabulary and layout from the moment this change ships.
- **No pipeline behavior change beyond names and layout.** The steps, gates, and contracts of brainstorm → spec → plan → run → review → pr stay as they are; only the vocabulary, paths, and wave formalization change.
- **No public `delivery-conductor` role.** Delivery orchestration remains an internal responsibility of `/sw:run`; no new agent definition is added.
- **No slash-command renames.** `/sw:brainstorm`, `/sw:spec`, `/sw:plan`, `/sw:run`, `/sw:review`, `/sw:review-spec`, `/sw:pr`, `/sw:init` keep their names.
- **No tracker integration work.** This change renames specwright's own artifacts only; GitHub/Linear integration behavior is out of scope.

## Acceptance Criteria

Number each criterion sequentially as `AC-N` — the IDs are stable handles that `tasks.md` references and that `/sw:review` walks to prove every criterion was delivered. Each criterion is a binary, observable check verifiable in under a minute.

- [ ] **AC-1** `plugins/sw/templates/` contains exactly `change.md`, `delivery.md`, `board.md`, `spec.md`, and `tasks.md` — no `issue.md`, no `goal.md` — and the `change.md` template frontmatter carries a `delivery:` key.
- [ ] **AC-2** `plugins/sw/agents/` contains `change-owner.md` and no `issue-owner.md`; `change-owner.md` preserves the old definition's frontmatter values (`model: opus`, `effort: xhigh`, `skills:` listing `plan`).
- [ ] **AC-3** Grepping `plugins/sw/` for `milestone`, `issue-owner`, and specwright-artifact uses of `issue` yields **zero** hits; the only permitted `issue` occurrences name external tracker objects (e.g. "GitHub issue") — every hit is classified during verification.
- [ ] **AC-4** `plugins/sw/scripts/validate-spec.sh` prints `PASS` on a new-format change folder (`change.md` + `spec.md` + `tasks.md` with valid frontmatter), fails when `change.md` is missing, and no longer requires `issue.md`.
- [ ] **AC-5** This repo's vault is fully migrated: `.specwright/issues/` and `.specwright/milestones/` no longer exist; every artifact they held lives under `.specwright/changes/` or `.specwright/deliveries/`, with `issue.md`/`goal.md` renamed to `change.md`/`delivery.md` and every moved file's content byte-identical to its pre-move blob (verified via `git diff` showing renames only).
- [ ] **AC-6** No template or skill generates a per-delivery `issues/` subfolder: changes are written flat at `.specwright/changes/YYYY-MM-DD-<slug>/`, deliveries at `.specwright/deliveries/YYYY-MM-DD-<slug>/` with `delivery.md` + `board.md`.
- [ ] **AC-7** `plugins/sw/skills/run/SKILL.md` derives waves from the task dependency and file-ownership graph (no persisted wave folders) and names `change-owner` as its dispatch target; `plugins/sw/agents/` contains no `delivery-conductor.md`.
- [ ] **AC-8** `CLAUDE.md` and `README.md` describe the workflow using only Delivery/Change/Task/Wave vocabulary and the flat `.specwright/changes/` + `.specwright/deliveries/` layout.
- [ ] **AC-9** The new-version `validate-spec.sh` prints `PASS` for this change's own folder, `.specwright/changes/2026-07-29-delivery-change-wave-terminology/` — the first new-format specimen.
- [ ] **AC-10** Durable automated coverage ships with the change: a `tests/validate-spec/run.sh` suite (same conventions as `tests/install/` — ephemeral fixtures, `run.sh` entry point) asserts `PASS` on a new-format folder, failure when `change.md` is missing, and the status/scope enums; the suite exits 0 and `tests/install/run.sh` keeps passing unmodified.

Tick each `[x]` when verified. Runtime verification checks each criterion by observed behavior before the PR opens; a criterion the agent cannot verify at runtime is marked `needs-human-verification` with the reason — never silently ticked.
