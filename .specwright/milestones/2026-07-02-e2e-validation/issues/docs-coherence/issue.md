---
feature: docs-coherence
created: 2026-07-02
status: in-progress
shipped: null
---
# Docs Coherence (T11) — Issue

> The ticket: the approved *why* plus the acceptance criteria and the issue's status. `status:` lives **only** here — `pending | in-progress | shipped | blocked` — and `shipped:` gets the ship date when the PR is open and `/sw:review` reached `lgtm`. The technical *how* (architecture, file structure, tasks) lives in the sibling `spec.md` + `tasks.md`, written just-in-time by `/sw:plan`.

## Purpose

Audit the specwright repo's own documentation against the shipped behavior: `README.md`, `AGENTS.md`, and the `sw` skill references (`skills/sw/references/*.md`) must describe the unified issues + milestones workflow as it actually is — command counts and names, the issue flow steps, the milestone loop, the vault layout (`.specwright/{conventions,issues,milestones}`), and the artifact shapes. Every claim naming a count, a path, a command, or a flow step gets checked against the corresponding source of truth in the repo.

`validate-spec.sh` is part of the documented behavior: run it against fixtures on the new layout — a valid standalone issue folder, a valid milestone issue folder, and defective ones (missing frontmatter, placeholder survivors, uncovered `AC-N`) — and verify exit codes and messages match what the docs and skills promise.

## Motivation

Docs that lag the delivery teach every future session the wrong contract — in an agent-driven workflow the docs *are* the runtime. T11 of the test plan.

## Non-Goals

- No rewriting of docs; discrepancies become findings for the fixes follow-up.
- No surface/reachability checks — `command-surface` (T10) owns those.

## Acceptance Criteria

Number each criterion sequentially as `AC-N` — the IDs are stable handles that `tasks.md` references and that `/sw:review` walks to prove every criterion was delivered. Each criterion must be a binary, observable check verifiable in under a minute.

- [x] **AC-1** A claim-by-claim verdict table for README.md and AGENTS.md: every count, command name, path, and flow-step claim mapped to its source of truth with `match`/`mismatch` (mismatches quoted verbatim).
- [x] **AC-2** The `sw` skill references (`audit-checklist.md`, `vault-files.md`, `validation.md`, `agents-md-template.md`, `claude-plugin-settings.md`) describe the current layout — zero mentions of retired artifacts (`design.md`, `specs/` as a live directory, old skill names) outside explicitly historical/legacy-cleanup notes.
- [x] **AC-3** `validate-spec.sh` exits 0 on the two valid fixtures (standalone-shaped and milestone-shaped issue folders) and non-zero with a defect-naming message on each defective fixture; fixtures and outputs saved under `evidence/`.
- [x] **AC-4** `findings.md` has a verdict per check above and one Expected / Observed / Proposed-fix entry per failure.

Tick each `[x]` when verified. An issue is **not shippable** with empty or double-brace-placeholder acceptance criteria — `validate-spec.sh` and `/sw:review-spec` will reject it.
