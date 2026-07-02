---
feature: command-surface
created: 2026-07-02
status: in-progress
shipped: null
---
# Command Surface (T10) — Issue

> The ticket: the approved *why* plus the acceptance criteria and the issue's status. `status:` lives **only** here — `pending | in-progress | shipped | blocked` — and `shipped:` gets the ship date when the PR is open and `/sw:review` reached `lgtm`. The technical *how* (architecture, file structure, tasks) lives in the sibling `spec.md` + `tasks.md`, written just-in-time by `/sw:plan`.

## Purpose

Verify the installed command surface matches the documented one — all 8 entries respond and the old names are gone. In the sandbox install and in the specwright repo itself, check each of `brainstorm · spec · plan · run · review · review-spec · pr · update` at every layer where the docs claim it exists: the Claude Code plugin (`plugins/sw/commands/` + `plugins/sw/skills/`), the canonical scaffolded copies (`.agents/skills/sw-*` — the surface Codex `$sw-*` and Cursor `@sw-*` users get), and per-agent symlinks where present. Confirm the retired names (`sw-brainstorming`, `sw-writing-plans`, `sw-new-pr`, `sw-code-review`, legacy `.claude/commands/sw-*.md`) resolve nowhere.

Cross-layer coherence is part of the surface: every documented invocation (`/sw:<verb>`, `$sw-<verb>`, `@sw-<verb>`) must map to an existing artifact in the layout the install actually produces — a doc that promises a verb the install does not deliver (or delivers under another shape) is a finding.

## Motivation

The rename and plugin migration left multiple layers (plugin, canonical skills, symlinks, docs) that can drift apart silently; a user's first contact with specwright is this surface. T10 of the test plan.

## Non-Goals

- No prose-quality audit of README/AGENTS.md — `docs-coherence` (T11) owns that; this issue checks existence/reachability of the surface only.
- No fixes; findings only.

## Acceptance Criteria

Number each criterion sequentially as `AC-N` — the IDs are stable handles that `tasks.md` references and that `/sw:review` walks to prove every criterion was delivered. Each criterion must be a binary, observable check verifiable in under a minute.

- [x] **AC-1** A verdict table covers all 8 verbs × the layers the docs claim (plugin command/skill, canonical `.agents/skills/sw-*`, sandbox install), each cell `present`/`absent` with the checked path.
- [x] **AC-2** Every verb documented as a skill has a `SKILL.md` whose frontmatter `name:` matches its invocation name at that layer (plugin: bare verb; canonical: `sw-<verb>`).
- [x] **AC-3** Zero hits for retired names in the sandbox and repo surfaces: no `sw-brainstorming`/`sw-writing-plans`/`sw-new-pr`/`sw-code-review` directories or symlinks, no `.claude/commands/sw-spec.md`/`sw-review-spec.md`, no dangling symlinks under any agent discovery dir.
- [x] **AC-4** Any verb reachable in docs but unreachable in an installed layer (or vice versa) is logged as a finding with the exact doc line and missing path.
- [x] **AC-5** `findings.md` has a verdict per check above and one Expected / Observed / Proposed-fix entry per failure.

Tick each `[x]` when verified. An issue is **not shippable** with empty or double-brace-placeholder acceptance criteria — `validate-spec.sh` and `/sw:review-spec` will reject it.
