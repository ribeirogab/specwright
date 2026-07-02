---
feature: sandbox-setup
created: 2026-07-02
status: pending
shipped: null
---
# Sandbox Setup — Issue

> The ticket: the approved *why* plus the acceptance criteria and the issue's status. `status:` lives **only** here — `pending | in-progress | shipped | blocked` — and `shipped:` gets the ship date when the PR is open and `/sw:review` reached `lgtm`. The technical *how* (architecture, file structure, tasks) lives in the sibling `spec.md` + `tasks.md`, written just-in-time by `/sw:plan`.

## Purpose

Build the synthetic project every other issue of this milestone tests against: `taskr`, a dependency-free Node todo-list CLI with a genuinely passing test suite, living at `~/www/ribeirogab/specwright-sandbox/taskr` (durable, outside any existing repo), `git init` done on branch `main`, a local bare remote as `origin` (no GitHub — the sandbox must never publish anything), and specwright installed exactly as the scaffold in `skills/sw/SKILL.md` prescribes (canonical `.agents/skills/sw*` copies, `AGENTS.md` from the template, `CLAUDE.md` symlink, `.specwright/` vault, `.gitignore` entries, `.claude/settings.json` plugin merge).

Two scenario seeds must be baked into the base project, without comments or docs calling attention to them:

- **Learning seed** — task timestamps are stored as **UTC epoch seconds** (`Math.floor(Date.now() / 1000)`), not ISO strings. Non-obvious on purpose: later issues verify this fact travels through `learnings.md`.
- **Trap seed** — a test asserting `taskr list` prints tasks in insertion order (oldest first). A later sandbox issue will demand the opposite order while forbidding test edits — the circuit-breaker scenario.

## Motivation

The test plan requires a project "small enough that each issue takes minutes; real enough to have a genuine quality gate". Every downstream issue (T1–T10) drives specwright sessions inside this sandbox; it must exist first, at a path all issue owners can reach from their own worktrees.

## Non-Goals

- No taskr features beyond `add` / `list` / `done` — priorities, filters, export, and the web page are deliberately absent; they are what the sandbox milestone will build.
- No GitHub repository for the sandbox; `origin` is a local bare repo.
- No findings work — this issue produces the fixture, not test verdicts.

## Acceptance Criteria

Number each criterion sequentially as `AC-N` — the IDs are stable handles that `tasks.md` references (each task names the criteria it satisfies) and that `/sw:review` walks to prove every criterion was delivered. Each criterion must be a binary, observable check that someone other than the implementer can verify in under a minute.

- [ ] **AC-1** `npm test` in `~/www/ribeirogab/specwright-sandbox/taskr` exits 0 with at least 4 passing tests, one of which asserts `list` prints tasks oldest-first.
- [ ] **AC-2** `taskr add`, `taskr list`, and `taskr done` behave as documented in the sandbox README when run against a temp `TASKR_FILE`, and stored tasks carry `createdAt` as an integer epoch-seconds value (verified by inspecting the JSON file — no ISO strings).
- [ ] **AC-3** `git -C <sandbox> log --oneline` shows a single bootstrap commit on `main`, and `git remote -v` shows `origin` pointing at a local bare repo path (no `github.com`).
- [ ] **AC-4** The specwright audit passes in the sandbox: `AGENTS.md` (≤ 80 lines, all required sections), `CLAUDE.md` → `AGENTS.md` symlink, `.specwright/{conventions,issues,milestones}/` exist, `.agents/skills/sw/` plus the six `sw-*` skills exist, `.gitignore` contains `.specwright/worktrees/`, and `.claude/settings.json` declares the `specwright` marketplace and enables `sw@specwright`.
- [ ] **AC-5** `.agents/skills/sw/scripts/validate-spec.sh` is executable in the sandbox and exits non-zero with a usage/structural error when pointed at a nonexistent issue folder (proves the validator ships and runs on the new paths).
- [ ] **AC-6** This issue's `learnings.md` records the sandbox absolute path, the local-origin convention, and the two scenario seeds (epoch timestamps, oldest-first list test) so downstream issue specs inherit them.

Tick each `[x]` when verified. An issue is **not shippable** with empty or double-brace-placeholder acceptance criteria — `validate-spec.sh` and `/sw:review-spec` will reject it.
