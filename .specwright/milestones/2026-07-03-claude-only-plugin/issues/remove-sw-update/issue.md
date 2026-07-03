---
feature: remove-sw-update
created: 2026-07-03
status: pending
shipped: null
---
# Remove sw:update — Issue

> The ticket: the approved *why* plus the acceptance criteria and the issue's status. `status:` lives **only** here — `pending | in-progress | shipped | blocked` — and `shipped:` gets the ship date when the PR is open and `/sw:review` reached `lgtm`. The technical *how* (architecture, file structure, tasks) lives in the sibling `spec.md` + `tasks.md`, written just-in-time by `/sw:plan`.

## Purpose

Remove the `sw:update` capability from the plugin: delete its skill directory, delete the `sw-update.sh` script, and remove every mention of `sw:update` from the other files under `plugins/sw/` (skill bodies, the plugin manifest, and any command/skill enumeration).

## Motivation

`sw:update` reconciled scaffolded-into-repo files with upstream. In the plugin-only model nothing is scaffolded-copied except the vault — user content that must never be overwritten — and plugin updates come from Claude Code's own plugin update mechanism. The command is obsolete by construction; leaving it behind is dead surface that confuses adopters and invites broken references.

## Non-Goals

- Restructuring the plugin or relocating assets — owned by `plugin-only-restructure`.
- Rewriting `/sw:init` — owned by `rewrite-sw-init`.
- Removing `sw:update` mentions from `README.md` or the repo's root entry-point document — owned by `docs-and-install-flow` (this issue clears the plugin sources only).

## Acceptance Criteria

Number each criterion sequentially as `AC-N` — the IDs are stable handles that `tasks.md` references (each task names the criteria it satisfies) and that `/sw:review` walks to prove every criterion was delivered. Each criterion must be a binary, observable check that someone other than the implementer can verify in under a minute.

Runtime verification checks each criterion by observed behavior before the PR opens; a criterion the agent cannot verify at runtime is marked `needs-human-verification` with the reason — never silently ticked.

- [ ] **AC-1** The directory `plugins/sw/skills/update/` does not exist.
- [ ] **AC-2** No file named `sw-update.sh` exists anywhere in the repository.
- [ ] **AC-3** `grep -rn` over `plugins/sw/` for the strings `sw:update`, `sw-update`, and `/sw:update` returns zero matches.
- [ ] **AC-4** The plugin manifest and any skill file that enumerates the `/sw:*` command set list no `update` entry.

Tick each `[x]` when verified. An issue is **not shippable** with empty or double-brace-placeholder acceptance criteria — `validate-spec.sh` and `/sw:review-spec` will reject it.
