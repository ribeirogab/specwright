---
feature: role-subagents
created: 2026-07-03
status: shipped
shipped: 2026-07-03
---
# Per-Role Subagents with Model + Effort — Issue

> The ticket: the approved *why* plus the acceptance criteria and the issue's status. `status:` lives **only** here — `pending | in-progress | shipped | blocked` — and `shipped:` gets the ship date when the PR is open and `/sw:review` reached `lgtm`. The technical *how* (architecture, file structure, tasks) lives in the sibling `spec.md` + `tasks.md`, written just-in-time by `/sw:plan`.

## Purpose

Bundle the four **dispatched** workflow roles as first-class subagent definitions in the `sw` plugin, each pinning its own model and reasoning effort. A milestone then conducts with the right model per role — opus for owning an issue and for reviewing, sonnet for grunt implementation — and the right effort, with no repo-level configuration file. Each definition preloads the skill it already runs (`plan`, `review`) via the `skills:` frontmatter field instead of duplicating it.

## Motivation

Today the roles are dispatched as generic subagents that inherit the conducting session's model and effort — there is no way to run the reviewer at opus/xhigh while the task-worker runs at sonnet/medium. A subagent definition pins both `model` and `effort` in its frontmatter — the native place to set them — and the `skills:` field preloads an existing skill's full content into the subagent. So defining each role as a bundled subagent co-locates its model and effort in one file, makes the roles first-class artifacts, reuses the existing skill via `skills:` instead of duplicating the procedure, and needs no `config.json`. This supersedes the earlier ad-hoc practice of recording per-milestone model allocation in `board.md`.

## Non-Goals

- **No model-configuration file.** No `config.json` / `config.local.json` under the plugin or `.specwright/`; model and effort live in the subagent frontmatter. This design was deliberately rejected in favor of native frontmatter.
- **The chat-session roles stay the session.** The milestone orchestrator (`/sw:run`) and the single-issue owner are the interactive chat session — they are NOT turned into subagent definitions and inherit whatever model/effort the session runs.
- **No change to pipeline behavior.** Only *which named subagent* each dispatch spawns changes; the steps, gates, and contracts each role runs are untouched.
- **No new dispatch sites.** `/sw:review-spec`, `/sw:pr`, `/sw:init`, `/sw:brainstorm`, `/sw:spec` dispatch no configured role and are not touched.

## Acceptance Criteria

Number each criterion sequentially as `AC-N` — the IDs are stable handles that `tasks.md` references and that `/sw:review` walks to prove every criterion was delivered. Each criterion is a binary, observable check verifiable in under a minute.

- [x] **AC-1** `plugins/sw/agents/` contains exactly four files — `issue-owner.md`, `task-worker.md`, `spec-document-reviewer.md`, `reviewer.md` — and each has YAML frontmatter with non-empty `name`, `description`, `model`, and `effort` keys.
- [x] **AC-2** The four definitions carry these exact pairs: `issue-owner` → `model: opus` + `effort: xhigh`; `task-worker` → `model: sonnet` + `effort: medium`; `spec-document-reviewer` → `model: opus` + `effort: high`; `reviewer` → `model: opus` + `effort: xhigh`.
- [x] **AC-3** `issue-owner.md` lists `plan` under a `skills:` frontmatter key and `reviewer.md` lists `review`; `task-worker.md` and `spec-document-reviewer.md` have no `skills:` key.
- [x] **AC-4** `plugins/sw/skills/plan/spec-document-reviewer-prompt.md` no longer exists, and the reviewer instructions it held now appear verbatim in the body of `plugins/sw/agents/spec-document-reviewer.md`.
- [x] **AC-5** In `plugins/sw/skills/run/SKILL.md`, the issue-owner dispatch step names the `issue-owner` subagent as the dispatch target rather than describing a generic worker.
- [x] **AC-6** In `plugins/sw/skills/plan/SKILL.md`, Gate 2 names the `spec-document-reviewer` subagent and the fan-out step names the `task-worker` subagent as their dispatch targets, and the file no longer references `spec-document-reviewer-prompt.md`.
- [x] **AC-7** In `plugins/sw/skills/review/SKILL.md`, the three-lane review names the `reviewer` subagent as the dispatch target for each of the three lanes (A/B/C).
- [x] **AC-8** `CLAUDE.md` names `plugins/sw/agents/` as the home of the bundled role subagents, in or beside the "Editing the bundled skills" section.

Tick each `[x]` when verified. Runtime verification checks each criterion by observed behavior (file inspection and the install smoke test) before the PR opens; any criterion requiring a live milestone dispatch that cannot run in the authoring session is marked `needs-human-verification` with the reason.
