---
feature: local-milestone-support
created: 2026-07-06
status: in-progress
shipped: null
---
# Local Milestone Support — Issue

> The ticket: the approved *why* plus the acceptance criteria and the issue's status. `status:` lives **only** here — `pending | in-progress | shipped | blocked` — and `shipped:` gets the ship date when the PR is open and `/sw:review` reached `lgtm`. The technical *how* (architecture, file structure, tasks) lives in the sibling `spec.md` + `tasks.md`, written just-in-time by `/sw:plan`.

## Purpose

Let `/sw:run` conduct milestones — and `/sw:pr` open PRs — in a `local`-mode repo, where the `.specwright/` vault and `CLAUDE.local.md` are git-ignored and therefore do not propagate to the worktrees `/sw:run` creates. `/sw:run` resolves the canonical vault from the checkout it runs in, copies each ready issue's folder plus the `CLAUDE.local.md` contract into the worktree it dispatches an owner into, and syncs the owner's updated folder back into the canonical vault on return — replacing git-as-sync (which cannot carry git-ignored artifacts) with an explicit file copy in and out.

## Motivation

The init-local-mode issue (PR #63) added a `local` commit mode but deferred milestone support: `/sw:run` today merely refuses to conduct in `local` mode as a fail-safe. That blocks the milestone flow — the main value of `local` mode for a larger delivery. The root constraint (verified; see the sibling `../2026-07-06-init-local-mode/learnings.md`): `git worktree add` materializes only tracked content, so a git-ignored `CLAUDE.local.md` and `.specwright/` never reach a dispatched owner's worktree. Because the `.gitignore` lines themselves *are* committed in `local` mode, files copied into a worktree stay git-ignored there — so specwright can copy the artifacts in and out without the owner ever committing them by accident.

## Non-Goals

- **Home-dir import of the contract** (`@~/.claude/specwright-<repo>.md` so `CLAUDE.local.md` loads in any worktree, including externally-created ones). Deferred — milestone conduction is covered by copying the contract into the worktrees `/sw:run` creates, and the orchestrator runs from the vault-holding checkout, so the contract loads there.
- **Magically locating the vault from a worktree that lacks it.** `/sw:run` requires being invoked from the checkout that holds the vault (where `/sw:init local` ran); invoked elsewhere it stops with a clear message (AC-1) rather than guessing.
- **Any change to `shared`-mode conduction or PR behavior** — pinned unchanged by AC-7.

## Acceptance Criteria

Number each criterion sequentially as `AC-N` — the IDs are stable handles that `tasks.md` references and that `/sw:review` walks to prove every criterion was delivered. Each criterion must be a binary, observable check that someone other than the implementer can verify in under a minute.

Runtime verification checks each criterion by observed behavior before the PR opens; a criterion the agent cannot verify at runtime is marked `needs-human-verification` with the reason — never silently ticked.

- [ ] **AC-1** In `local` mode, `/sw:run` invoked from a checkout that has no `.specwright/` vault stops with a message that names the fix (run it from the checkout where `/sw:init local` ran) and dispatches no owner.
- [ ] **AC-2** In `local` mode, `/sw:run` invoked from the vault-holding checkout proceeds to conduct — it does not hit the unconditional local-mode refusal that PR #63 added; that refusal is replaced by the AC-1 conditional stop.
- [ ] **AC-3** When `/sw:run` dispatches an owner in `local` mode, it copies `CLAUDE.local.md` and the ready issue's folder into the new worktree after `git worktree add`, and both are git-ignored in that worktree (`git status --porcelain` in the worktree lists neither the copied `CLAUDE.local.md` nor the copied issue folder as a path to commit).
- [ ] **AC-4** After an owner returns in `local` mode, its updated issue folder (the `status:` it flipped in `issue.md`, plus `spec.md`/`tasks.md`/`learnings.md`) is synced back into the canonical vault — the canonical `issue.md` reflects the owner's final `status:`.
- [ ] **AC-5** In `local` mode, `/sw:run` reads each dependency's readiness `status:` from the canonical vault, not from a dependency branch checkout.
- [ ] **AC-6** In `local` mode, `/sw:pr` emits no GitHub-URL links to `issue.md`/`spec.md`/`tasks.md` (which would 404 for un-pushed files); it omits them or inlines a short artifact summary instead.
- [ ] **AC-7** `shared`-mode conduction and PR behavior are unchanged: every `local`-mode branch above is gated behind local-mode detection, and a `shared` run of `/sw:run` and `/sw:pr` produces the same behavior as before this change.
- [ ] **AC-8** The docs that stated `local` mode does not support milestones — `plugins/sw/references/claude-md-template.md` and `plugins/sw/references/vault-files.md` (and the `run`/`pr` skill docs) — are updated to describe the now-supported `local`-mode conduction and its copy-in/sync-back model.

Tick each `[x]` when verified. An issue is **not shippable** with empty or double-brace-placeholder acceptance criteria — `validate-spec.sh` and `/sw:review-spec` will reject it.
