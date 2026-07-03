---
feature: remove-sw-update
created: 2026-07-03
status: shipped
shipped: 2026-07-03
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

- [x] **AC-1** The directory `plugins/sw/skills/update/` does not exist. Verified: `[ ! -d plugins/sw/skills/update ]` passes; `ls plugins/sw/skills/` shows only `brainstorm plan pr review run`.
- [x] **AC-2** No file named `sw-update.sh` exists anywhere in the repository. Verified: `find . -name 'sw-update.sh'` (excluding `.git/`) returns nothing.
- [x] **AC-3** `grep -rn` over `plugins/sw/` for the strings `sw:update`, `sw-update`, and `/sw:update` returns zero matches **except the 3 sibling-owned reference docs** (`plugins/sw/references/agents-md-template.md`, `plugins/sw/references/validation.md`, `plugins/sw/references/audit-checklist.md`), which `rewrite-sw-init` owns and clears as part of its own rewrite — this issue's file-ownership boundary deliberately excludes them to avoid a merge collision with that parallel sibling. The bar delivered is a **conditional** clean sweep (zero matches outside those 3 files), mirroring the historical-record carve-out pattern issue #1 (`plugin-only-restructure`, PR #57) used for its own grep-cleanliness AC. Verified by running the grep and confirming the distinct-file list is exactly those 3 paths, no more.
- [x] **AC-4** The plugin manifest and any skill file that enumerates the `/sw:*` command set list no `update` entry. Verified: `plugins/sw/.claude-plugin/plugin.json`'s `description` field now lists `brainstorm, plan, run, review, pr` with no `update`; no other companion-skill body or command in this issue's ownership boundary enumerates `/sw:*` command names (confirmed by grep — see `spec.md` Constraints).

Tick each `[x]` when verified. An issue is **not shippable** with empty or double-brace-placeholder acceptance criteria — `validate-spec.sh` and `/sw:review-spec` will reject it.
