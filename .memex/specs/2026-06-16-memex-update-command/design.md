---
feature: memex-update-command
spec: "[[2026-06-16-memex-update-command/spec|spec]]"
created: 2026-06-16
---
# /memex:update — Design

> Non-technical write-up of the **already-approved** design — purpose, motivation, definitions, non-goals. Created after design approval as a durable record of *why*; it is **not** a second human-review gate. The technical *how* lives in `[[2026-06-16-memex-update-command/spec|spec]]`.

## Purpose

Give an installed memex a one-command way to pull upstream changes to its scaffolded content without clobbering local edits. `/memex:update` fetches the current upstream memex, compares it against the installed files through a recorded baseline, **auto-applies** changes to files the user never touched, and **agent-merges** changes into files the user did edit — then reports what it did. It closes the gap that the audit leaves open: today the audit detects only *structural* drift (missing headers, malformed frontmatter, wrong filenames), so a *content* change like a terminology rename is invisible and never propagates.

## Motivation

When upstream memex changes scaffolded content, every installed repo is a stale, disconnected fork. The motivating case: the `compact` → `handoff` rename had to be re-applied **by hand across 8 files in each installed repo** (AGENTS.md, the brainstorming + writing-plans companion skills, the spec-driven-development guide, and the bundled skill source). Re-running the installer does not help — it is audit-first and "never overwrites a healthy file," and its drift check is structural only. There is no version link between an install and upstream, so nothing knows a file is stale-but-otherwise-untouched and therefore safe to refresh. The result is silent staleness: installs drift further from upstream with every release, and the only remedy is manual, per-file, per-repo edits.

## Definitions

- **Managed file** — a scaffolded item that `/memex:update` reconciles: the companion skills' `SKILL.md`, `spec-driven-development.md`, the scaffolded scripts (`validate-spec.sh`, `memex-update.sh`), and the **`### Spec flow` block** of `AGENTS.md`. Upstream owns these, and each is backed by a **discrete file** in the upstream `skills/memex/scaffold/` tree (or `references/agents-md-template.md` for the AGENTS block) — that is what makes a clean hash-diff possible.
- **Living vault content** — files the user/agent fills over time: `_index/*` MOCs, `learnings/`, `conventions/`, `specs/`, and the per-repo intro of `AGENTS.md`. **Never** managed.
- **Baseline (`B`)** — the content hash of each managed file as last installed or updated, recorded in the **manifest**. The reference point that distinguishes "user edited this" from "upstream changed this".
- **Manifest** — a tracked file (`.memex/.update-manifest.json`) mapping each managed path (and the AGENTS.md spec-flow block) to its baseline `sha256`.
- **Three-way classify** — per file, compare local (`L`), baseline (`B`), upstream (`U`): `L==U` current; `L==B & B!=U` stale-clean (auto re-copy); `L!=B & B==U` local-only (leave); `L!=B & B!=U` conflict (agent merge: keep local edits + apply the `B→U` delta).
- **Self-fetch** — the command fetches the current upstream memex itself (network) each run; reconcile then runs against that.

## Non-Goals

- **No constitution management (v1).** `AGENTS.md` is covered only through its fixed `### Spec flow` block; `constitution.md` is out of scope for the first version.
- **No prose-embedded scaffold content (v1).** The spec/note templates, `rules.md`, the `_index/*` MOCs, and the constitution are *generated from reference prose* (`vault-files.md`, `constitution-template.md`) at install, not copied from a discrete scaffold file. With no single upstream file to hash, they need a different reconcile mechanism — deferred to a later version. v1 manages only file-backed scaffold items.
- **No touching of living vault content.** `_index/*`, `learnings/`, `conventions/`, `specs/`, and the per-repo `AGENTS.md` intro are never read-for-overwrite.
- **No auto-commit / no PR.** `/memex:update` edits the working tree and reports; the user reviews `git diff` and commits. It is a maintenance command, not the spec-flow delivery (`/memex:new-pr` stays the only PR path).
- **No offline mode.** The user chose self-fetch; with no network the command stops and reports rather than guessing.
- **Not a replacement for the audit.** The structural audit stays as-is; `/memex:update` adds the content-reconcile layer beside it.
- **No plugin-command updates.** The `/memex:*` slash commands ship from the marketplace plugin and update through it, not through this command.
