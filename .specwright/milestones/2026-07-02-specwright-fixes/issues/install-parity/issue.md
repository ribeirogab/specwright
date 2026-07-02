---
feature: install-parity
created: 2026-07-02
status: pending
shipped: null
---
# Install Parity — Issue

> The ticket: the approved *why* plus the acceptance criteria and the issue's status. `status:` lives **only** here — `pending | in-progress | shipped | blocked` — and `shipped:` gets the ship date when the PR is open and `/sw:review` reached `lgtm`. The technical *how* (architecture, file structure, tasks) lives in the sibling `spec.md` + `tasks.md`, written just-in-time by `/sw:plan`.

## Purpose

Make a by-the-letter install actually deliver what the docs promise: the scaffolder installs the `sw` skill itself (so the mechanical gate exists on first use), creates the Claude Code discovery symlink, ships canonical `sw-spec`/`sw-review-spec` skills so all eight documented command forms resolve, and keeps the vault directories through a clone.

## Motivation

Dossier entries 4.1–4.4 (`.specwright/milestones/2026-07-02-e2e-validation/issues/closeout/dossier.md`). The `high`: a documented Phase 4 install copies only the six companion skills — nothing installs `sw` itself, so `validate-spec.sh` does not exist at its invoked path and the issue pipeline's mechanical gate is broken on first use. Independently, two audit issues confirmed `$sw-spec`/`$sw-review-spec` (and the `@` forms) are documented in AGENTS.md and reproduced by the template into every new install, yet resolve to nothing. Decision recorded at the fixes brainstorm: real parity — ship the two canonical skills — rather than scoping down the docs.

## Non-Goals

- Rewriting `install.sh` — it already produces the promised layout; this issue brings the scaffolder path to parity with it.
- Doc-drift and validator-wording fixes (sibling issue `docs-and-validator`, which depends on this one for the shared template surface).
- Changing the content or behavior of the six existing companion skills.

## Acceptance Criteria

Number each criterion sequentially as `AC-N` — the IDs are stable handles that `tasks.md` references (each task names the criteria it satisfies) and that `/sw:review` walks to prove every criterion was delivered. Each criterion must be a binary, observable check that someone other than the implementer can verify in under a minute. **No vague verbs** — replace them with specific, measurable conditions.

Runtime verification checks each criterion by observed behavior before the PR opens; a criterion the agent cannot verify at runtime is marked `needs-human-verification` with the reason — never silently ticked.

- [ ] **AC-1** The `sw` skill's scaffold procedure copies the `sw` skill itself — including `scaffold/` and `scripts/` with executable bits preserved — so that after a fresh scaffold in a clean directory, `.agents/skills/sw/scripts/validate-spec.sh` exists and is executable (dossier 4.1).
- [ ] **AC-2** `references/audit-checklist.md` lists `.agents/skills/sw/` as an audited path (dossier 4.1).
- [ ] **AC-3** The scaffold procedure creates the `.claude/skills/sw` symlink the README promises, and a fresh scaffold in a clean directory contains it pointing at the installed skill (dossier 4.2).
- [ ] **AC-4** Canonical `sw-spec` and `sw-review-spec` skills exist in `skills/sw/scaffold/skills/` and `.agents/skills/`, with content equivalent to the plugin commands `plugins/sw/commands/{spec,review-spec}.md`, so every documented `$sw-<verb>`/`@sw-<verb>` form resolves to a real skill — eight verbs total (dossier 4.3, parity option).
- [ ] **AC-5** The scaffold procedure creates `.gitkeep` files in `.specwright/{conventions,issues,milestones}/` idempotently, so the vault directories survive a clone (dossier 4.4).

Tick each `[x]` when verified. An issue is **not shippable** with empty or double-brace-placeholder acceptance criteria — `validate-spec.sh` and `/sw:review-spec` will reject it.
