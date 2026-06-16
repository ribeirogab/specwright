---
feature: rename-compact-to-handoff
spec: "[[2026-06-16-rename-compact-to-handoff/spec|spec]]"
created: 2026-06-16
---
# Rename `compact` → `handoff` — Design

> Non-technical write-up of the **already-approved** design — purpose, motivation, definitions, non-goals. Created after design approval as a durable record of *why*; it is **not** a second human-review gate. The technical *how* lives in `[[2026-06-16-rename-compact-to-handoff/spec|spec]]`.

## Purpose

Rename the third post-design question of the spec flow — the optional context break between planning and implementation — from **`compact`** to **`handoff`** across all live memex docs and skills. The mechanic is unchanged: after `design`/`spec`/`tasks` exist, the agent prints a `txt` resume prompt and stops so the user can `/compact` (or open a new chat) and continue with a clean context. Only the *name* of the choice changes.

## Motivation

`compact` was borrowed from the Claude Code `/compact` command. It names the *mechanism* (one harness control among several), not the *intent*. The intent is to **hand the plan off to a fresh context**. The word also tied a portable, agent-agnostic concept to one agent's command vocabulary. The docs already half-used the better word ("Compact handoff", "prints a handoff prompt"), so the rename drops the redundant `compact` qualifier and keeps `handoff` — the word that already carried the meaning.

## Definitions

- **handoff** (noun / label) — the post-design choice and the step: emit a resume prompt, stop, resume in fresh context. Replaces `compact` as the concept name.
- **hand off** (verb) — to perform the handoff ("whether to **hand off** before implementing", "never hand off before the artifacts exist").
- **`/compact`** — the literal Claude Code harness command. Unchanged; still referenced as the user-side action ("you `/compact` or open a new chat").

## Non-Goals

- **No behavior change.** The seam, the timing ("after artifacts exist, never before"), the both-modes applicability, and the no-auto-compact rule all stay exactly as they were.
- **No new frontmatter.** The handoff preference remains a run-time choice carried in the conversation, not persisted to `spec.md`.
- **No rewriting of history.** Shipped specs under `.memex/specs/**` and notes under `.memex/learnings/**` keep their ship-time wording (`compact`) as an immutable record.
- **No touching unrelated `compact`.** The "compact list" phrasing in the recall skill is a different sense of the word and stays.
- **Not dropping the `/compact` literal.** The real harness command keeps its name.
