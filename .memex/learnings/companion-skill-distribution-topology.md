---
tags:
  - reference
related:
  - "[[2026-06-13-spec-driven-workflow/spec|spec-driven-workflow]]"
created: 2026-06-13
---
# A memex companion skill ships in three real copies, not as a command

A cross-agent companion skill (`memex-recall`, `memex-link`, `memex-new-pr`, `memex-code-review`, …) exists as **three real, non-symlinked copies** that must be kept in sync, differing only in the frontmatter `name:` field:

1. `.agents/skills/memex-<name>/SKILL.md` — `name: memex-<name>` — the canonical copy non-Claude agents read.
2. `plugins/memex/skills/<name>/SKILL.md` — `name: <name>` — the plugin copy; this is what surfaces as `/memex:<name>` in Claude Code.
3. `skills/memex/scaffold/skills/memex-<name>/SKILL.md` — `name: memex-<name>` — the template shipped to other repos by the `memex` skill.

Plugin **skills** (not commands) are the portable mechanism: a plugin skill is reachable from every agent and gets the `/memex:` namespace automatically, whereas `plugins/memex/commands/*.md` are Claude-Code-only. `.claude/skills/` holds a single `memex -> ../../skills/memex` host symlink — there are no per-companion symlinks to create.

## Context

Discovered while adding `memex-new-pr` and `memex-code-review` in the `[[2026-06-13-spec-driven-workflow/spec|spec-driven-workflow]]` rework. The spec first described them as `plugins/memex/commands/*.md` — wrong: that would have made them Claude-only and broken the cross-agent goal. Diffing an existing companion (`memex-recall`) revealed the 3-copy topology and the name-field-only difference.

## Adding a skill also means registering it in the installer (separate gotcha)

Creating the three copies is **not enough** for the skill to reach target repos. The installer and its checks carry a hardcoded skill list in several places that must all be updated, or `/memex` silently scaffolds without the new skill:

- `skills/memex/SKILL.md` — the `SKILL_NAMES=(...)` bash array (drives the copy loop, the per-agent symlink loop, and the legacy-cleanup loop).
- `skills/memex/references/validation.md` — check #9's `for s in ...` skill loop.
- `skills/memex/references/audit-checklist.md` — the canonical `.agents/skills/` list and the plugin-skill enumeration prose.

This was caught only by the E2E scaffold test: the two new skills existed in all three copies but `SKILL_NAMES` still listed the original four, so a fresh install would not have received them.

## How to Apply

When adding or editing a companion skill: (1) author the canonical `.agents/skills/memex-<name>/SKILL.md`, then generate the other two — scaffold via `cp` (same name), plugin via `sed 's/^name: memex-<name>$/name: <name>/'`; (2) register the name in `SKILL_NAMES` (SKILL.md), validation.md check #9, and audit-checklist.md. Verify all three copies with `diff <(tail -n +3 A) <(tail -n +3 B)` (bodies identical) and the correct `name:` each, then run an E2E scaffold into a throwaway repo and confirm the new skill lands in the target's `.agents/skills/`. Never add a `commands/*.md` for something meant to be cross-agent.
