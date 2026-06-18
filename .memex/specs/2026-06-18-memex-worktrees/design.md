---
feature: memex-worktrees
spec: "[[2026-06-18-memex-worktrees/spec|spec]]"
created: 2026-06-18
---
# memex worktrees — Design

> Non-technical write-up of the **already-approved** design — purpose, motivation, definitions, non-goals. Created after design approval as a durable record of *why*; it is **not** a second human-review gate. The technical *how* lives in `[[2026-06-18-memex-worktrees/spec|spec]]`.

## Purpose

Add an optional, memex-native **git worktree** per spec. The post-design batch grows from three questions to four: branch name, mode, handoff, and now **worktree (yes/no)**. When the agent chooses to use a worktree, the branch-creation step of the spec flow creates `git worktree add .memex/worktrees/<slug>` (where `<slug>` is the spec's dated-folder slug) and runs the rest of the flow — `design.md`, `spec.md`, `tasks.md`, implementation, learnings, PR — inside it. When it does not, the flow is unchanged: an in-place `git checkout -b <branch>`.

Before asking, the flow **detects** whether it is already inside a linked worktree (e.g. a Claude Code `.claude/worktrees/` checkout). If so it warns the user and recommends **not** creating a second worktree — work where it already is.

## Motivation

A worktree lets a spec's work live in its own checkout, isolated from whatever the main checkout is doing, without stashing or branch-switching churn. Claude Code's harness already offers this under `.claude/worktrees/`, but memex is **agent-agnostic** — Codex, Cursor, OpenCode and others have no such mechanism. A memex-native worktree under `.memex/worktrees/` gives every agent the same portable option, wired into the one place the flow already decides how work is isolated: the post-design batch.

The default is **yes** (create a worktree) because per-spec isolation is the behavior we want to encourage. The one exception is the guard: when the flow is already running inside a linked worktree, nesting a second one is wasteful and confusing, so there it recommends working in place.

## Definitions

- **worktree (the choice)** — the fourth post-design-batch question: whether this spec's work runs in a dedicated git worktree. Recorded optionally as `worktree:` in `spec.md` frontmatter (the path, or absent when unused); recorded-only, like `scope:` — the validator does not require it.
- **`.memex/worktrees/<slug>`** — the location of a spec's worktree. `<slug>` is the same dated-folder slug as `.memex/specs/YYYY-MM-DD-<slug>/`. The directory is git-ignored (mirroring `.claude/worktrees/`).
- **the guard** — the pre-question detection: compare `git rev-parse --git-common-dir` with `git rev-parse --git-dir`; if they differ, the flow is inside a linked worktree. Agent-agnostic — it does not hardcode `.claude`. On a hit, warn and recommend `worktree=no`.

## Non-Goals

- **No automatic removal.** The flow only **creates** a worktree; it never runs `git worktree remove`. Cleanup is the maintainer's, done manually after merge — the merge to `main` is outside the agent's control, and the agent runs inside the very worktree it would remove.
- **No validator change.** `worktree:` is optional and recorded-only; `validate-spec.sh` keeps requiring only `status/feature/created/scope`.
- **No change to the harness worktree.** memex does not touch, wrap, or replace Claude Code's `.claude/worktrees/` mechanism; it adds an independent one and steps aside (via the guard) when the harness's is already in use.
- **Worktree is not mandatory.** It stays a per-spec choice. The default is yes, but the user (and the guard) can decline.
