---
feature: docs-and-validator
created: 2026-07-02
status: shipped
shipped: 2026-07-02
---
# Docs and Validator — Issue

> The ticket: the approved *why* plus the acceptance criteria and the issue's status. `status:` lives **only** here — `pending | in-progress | shipped | blocked` — and `shipped:` gets the ship date when the PR is open and `/sw:review` reached `lgtm`. The technical *how* (architecture, file structure, tasks) lives in the sibling `spec.md` + `tasks.md`, written just-in-time by `/sw:plan`.

## Purpose

Make the documentation and the mechanical validator say what is true: the validator's header matches its exit semantics, the AGENTS.md template matches the evolved AGENTS.md, and the README's license and layout sections match what ships.

## Motivation

Dossier entries 5.1–5.5 (`.specwright/milestones/2026-07-02-e2e-validation/issues/closeout/dossier.md`). The validator promises "exits with the number of failed checks" but counts FAIL lines (one missing `status:` key fires check 1 twice, exit 2 — colliding with the reserved usage exit); the template lags AGENTS.md by seven hunks, so every new install starts drifted; and three README statements mislabel or omit shipped content.

## Non-Goals

- Changing which checks the validator performs or adding new checks — this issue reconciles wording and counting semantics, plus the one deliberate decision on check 1's empty-value behavior.
- Scaffolder or canonical-skill changes (sibling issue `install-parity`, which this issue depends on for the shared template surface).

## Acceptance Criteria

Number each criterion sequentially as `AC-N` — the IDs are stable handles that `tasks.md` references (each task names the criteria it satisfies) and that `/sw:review` walks to prove every criterion was delivered. Each criterion must be a binary, observable check that someone other than the implementer can verify in under a minute. **No vague verbs** — replace them with specific, measurable conditions.

Runtime verification checks each criterion by observed behavior before the PR opens; a criterion the agent cannot verify at runtime is marked `needs-human-verification` with the reason — never silently ticked.

- [x] **AC-1** `validate-spec.sh`'s header and trailer match its actual exit semantics — either the wording becomes "failures reported (one per FAIL line)" or the counter dedupes per check — the check-1 vs check-2 empty-value asymmetry is resolved by a deliberate documented choice, and the collision with the reserved usage exit 2 is noted in the header (dossier 5.1).
- [x] **AC-2** `references/agents-md-template.md`'s Issue flow section matches the current AGENTS.md minus the dogfood-only clause, and the audit's DRIFT check over the pair reports clean (dossier 5.2).
- [x] **AC-3** The README license sentence names the two vendored scripts under `skills/sw/scripts/` (`quick_validate.py`, `package_skill.py`) as the Apache-2.0 portion and points to `NOTICE.md` (dossier 5.3).
- [x] **AC-4** The README repository-layout section includes `install.sh` and `tests/` entries, with `AGENTS.md`/`CLAUDE.md` either listed or covered by the dogfood paragraph with the section retitled accordingly (dossier 5.4).
- [x] **AC-5** Every issue-folder enumeration in live docs mentions that issue-specific artifacts may also be present (e.g. `findings.md`, `evidence/`) (dossier 5.5).

Tick each `[x]` when verified. An issue is **not shippable** with empty or double-brace-placeholder acceptance criteria — `validate-spec.sh` and `/sw:review-spec` will reject it.
