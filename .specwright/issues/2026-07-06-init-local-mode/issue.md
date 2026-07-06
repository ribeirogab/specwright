---
feature: init-local-mode
created: 2026-07-06
status: pending
shipped: null
---
# Init Local Mode — Issue

> The ticket: the approved *why* plus the acceptance criteria and the issue's status. `status:` lives **only** here — `pending | in-progress | shipped | blocked` — and `shipped:` gets the ship date when the PR is open and `/sw:review` reached `lgtm`. The technical *how* (architecture, file structure, tasks) lives in the sibling `spec.md` + `tasks.md`, written just-in-time by `/sw:plan`.

## Purpose

Give `/sw:init` two commit modes and always ask which one to use: `shared` (today's behavior — committed `CLAUDE.md` and committed `.specwright/` vault) and `local` (an uncommitted setup — the entry point is written to `CLAUDE.local.md` and both `.specwright/` and `CLAUDE.local.md` are added to `.gitignore`). This lets a developer adopt specwright inside a repository they do not own, keeping every specwright artifact out of the team's commits while still getting the full single-issue pipeline.

## Motivation

specwright's `/sw:init` today writes a committed `CLAUDE.md` and commits the whole `.specwright/` vault — it assumes the adopter controls the repo's conventions. Someone on a team that has not adopted specwright cannot commit those artifacts, but still wants the workflow for their own work. `CLAUDE.local.md` is auto-loaded by Claude Code (confirmed in the official memory docs) and is the sanctioned home for local, uncommitted project instructions, so a `local` mode is the natural fit. The only hard constraint the adopter stated: the *content* of `.specwright/` and `CLAUDE.local.md` must never be committed — a change to `.gitignore` reaching the team's PR is acceptable.

## Non-Goals

- **Milestone-flow support for `local` mode.** `git worktree add` does not materialize untracked files, so under `local` mode the `CLAUDE.local.md` contract and the issue folder are absent inside the worktrees `/sw:run` creates. Making `/sw:run` copy the entry point and the issue folder into each worktree, plus `/sw:pr`'s fallback for artifact links that cannot resolve to committed GitHub URLs, is deferred to a follow-up issue. This issue only adds the AC-8 guard so `local` + milestone fails safe instead of degrading silently.
- **The `.git/info/exclude` mechanism** — rejected; a `.gitignore` change that reaches the team's PR is acceptable, so the ordinary committed `.gitignore` is used.
- **Any change to `shared`-mode behavior** — pinned unchanged by AC-2.

## Acceptance Criteria

Number each criterion sequentially as `AC-N` — the IDs are stable handles that `tasks.md` references (each task names the criteria it satisfies) and that `/sw:review` walks to prove every criterion was delivered. Each criterion must be a binary, observable check that someone other than the implementer can verify in under a minute.

Runtime verification checks each criterion by observed behavior before the PR opens; a criterion the agent cannot verify at runtime is marked `needs-human-verification` with the reason — never silently ticked.

- [ ] **AC-1** Running `/sw:init` prompts the user to choose the commit mode (`shared` or `local`) before it writes the entry point or edits `.gitignore` — on a fresh repo and on a re-run alike.
- [ ] **AC-2** Choosing `shared` produces the same files as before this change: a committed `CLAUDE.md`, a committed `.specwright/` vault, and only `.specwright/worktrees/` appended to `.gitignore` — no other file differs from a pre-change `/sw:init` run.
- [ ] **AC-3** Choosing `local` writes the entry point to `CLAUDE.local.md`, creates and edits no `CLAUDE.md`, and appends both `.specwright/` and `CLAUDE.local.md` to `.gitignore`.
- [ ] **AC-4** After a `local` init, `git status --porcelain` lists no path under `.specwright/` and does not list `CLAUDE.local.md`, and `git check-ignore .specwright/ CLAUDE.local.md` prints both paths.
- [ ] **AC-5** Re-running `/sw:init` and choosing the mode that already matches the on-disk state adds no duplicate `.gitignore` line and overwrites no existing `CLAUDE.local.md`, `CLAUDE.md`, or vault content — a second run in the same mode leaves an empty `git diff`.
- [ ] **AC-6** Re-running `/sw:init` and choosing a mode that differs from the on-disk state changes no file until the user confirms: init first prints the migration consequences and waits for explicit confirmation.
- [ ] **AC-7** The init self-audit (`plugins/sw/references/validation.md`) reports a `local`-initialized repo as valid: the entry-point checks that today match the literal `CLAUDE.md` recognize `CLAUDE.local.md` as the entry point in `local` mode.
- [ ] **AC-8** Invoking `/sw:run` in a `local`-mode repo halts with a message stating milestone conduction is not supported in `local` mode yet and dispatches no issue owner.
- [ ] **AC-9** Each doc that describes what `/sw:init` writes — `README.md`, `plugins/sw/commands/init.md`, `plugins/sw/references/audit-checklist.md`, `plugins/sw/references/claude-md-template.md`, `plugins/sw/references/vault-files.md`, and the repo's dogfood `CLAUDE.md` — describes both modes and names `CLAUDE.local.md` plus the two `local`-mode `.gitignore` lines.

Tick each `[x]` when verified. An issue is **not shippable** with empty or double-brace-placeholder acceptance criteria — `validate-spec.sh` and `/sw:review-spec` will reject it.
