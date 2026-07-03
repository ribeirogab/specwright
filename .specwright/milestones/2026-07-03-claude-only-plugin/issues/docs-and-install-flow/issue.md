---
feature: docs-and-install-flow
created: 2026-07-03
status: in-progress
shipped: null
---
# Docs and Install Flow — Issue

> The ticket: the approved *why* plus the acceptance criteria and the issue's status. `status:` lives **only** here — `pending | in-progress | shipped | blocked` — and `shipped:` gets the ship date when the PR is open and `/sw:review` reached `lgtm`. The technical *how* (architecture, file structure, tasks) lives in the sibling `spec.md` + `tasks.md`, written just-in-time by `/sw:plan`.

## Purpose

Delete the standalone installer and rewrite the top-level documentation to describe the Claude-only plugin. Installation becomes the two `claude plugin` commands (global, once) followed by `/sw:init` for per-repo setup. Remove the agent-agnostic and curl-based install story from `README.md`, and update the repository's own root entry-point document to drop the three-copies-in-sync editing rule, the agent-agnostic language, and the `sw:update` row.

## Motivation

Once the plugin is the single distribution channel and `/sw:init` handles per-repo content, `install.sh` and the agent-agnostic documentation are stale and actively misleading. The docs must match the shipped model so an adopter follows the one correct path instead of a retired one.

## Non-Goals

- Changing skill behavior or relocating files — owned by the earlier issues in this milestone.
- Building committed project-settings auto-provisioning; it may be described as an optional team step but is not implemented here.

## Acceptance Criteria

Number each criterion sequentially as `AC-N` — the IDs are stable handles that `tasks.md` references (each task names the criteria it satisfies) and that `/sw:review` walks to prove every criterion was delivered. Each criterion must be a binary, observable check that someone other than the implementer can verify in under a minute.

Runtime verification checks each criterion by observed behavior before the PR opens; a criterion the agent cannot verify at runtime is marked `needs-human-verification` with the reason — never silently ticked.

- [x] **AC-1** The file `install.sh` does not exist in the repository. Verified: `[ -f install.sh ]` → absent.
- [x] **AC-2** `README.md` documents installation as the two commands `claude plugin marketplace add ribeirogab/specwright` and `claude plugin install sw@specwright` followed by `/sw:init`, and contains no `curl` piped-to-`sh` install instruction. Verified: both commands and `/sw:init` present in `README.md`'s Install/Use sections; `grep -in curl README.md` → no match.
- [x] **AC-3** Neither `README.md` nor the repository's root entry-point document mentions `.agents/`, per-agent symlinks, the names Codex/Cursor/OpenCode/Aider, or a three-copies-in-sync editing rule. Verified: `grep -in` for all of these over `README.md` and `CLAUDE.md` (the entry-point document — converged from `AGENTS.md`, symlink removed) → no match.
- [x] **AC-4** Neither `README.md` nor the repository's root entry-point document lists a `sw:update` or `/sw:update` command in any command table or prose. Verified: `grep -in sw:update README.md CLAUDE.md` → no match.
- [x] **AC-5** `grep -rn` over the repository for `install.sh` returns no reference to the deleted installer (every documentation pointer to it is removed or updated). Verified with two passes: a raw `grep -rln install\.sh .` returns hits only under `.specwright/` (historical issue records that predate or document the deletion, out of scope by the vault's no-retroactive-edit convention) and this issue's own ticket/spec/tasks; a scoped `grep -rln install\.sh . --exclude-dir=.specwright --exclude-dir=.git` returns only `tests/install/run.sh`, which legitimately names the file to assert its absence. No live documentation pointer to the deleted installer remains.

Tick each `[x]` when verified. An issue is **not shippable** with empty or double-brace-placeholder acceptance criteria — `validate-spec.sh` and `/sw:review-spec` will reject it.
