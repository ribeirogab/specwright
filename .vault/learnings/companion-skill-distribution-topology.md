---
tags:
  - reference
related:
  - "[[spec-spec-driven-workflow]]"
created: 2026-06-13
---
# A memex companion skill ships in three real copies, not as a command

A cross-agent companion skill (`memex-recall`, `memex-link`, `memex-new-pr`, `memex-code-review`, …) exists as **three real, non-symlinked copies** that must be kept in sync, differing only in the frontmatter `name:` field:

1. `.agents/skills/memex-<name>/SKILL.md` — `name: memex-<name>` — the canonical copy non-Claude agents read.
2. `plugins/memex/skills/<name>/SKILL.md` — `name: <name>` — the plugin copy; this is what surfaces as `/memex:<name>` in Claude Code.
3. `skills/memex/scaffold/skills/memex-<name>/SKILL.md` — `name: memex-<name>` — the template shipped to other repos by the `memex` skill.

Plugin **skills** (not commands) are the portable mechanism: a plugin skill is reachable from every agent and gets the `/memex:` namespace automatically, whereas `plugins/memex/commands/*.md` are Claude-Code-only. `.claude/skills/` holds a single `memex -> ../../skills/memex` host symlink — there are no per-companion symlinks to create.

## Context

Discovered while adding `memex-new-pr` and `memex-code-review` in the `[[spec-spec-driven-workflow]]` rework. The spec first described them as `plugins/memex/commands/*.md` — wrong: that would have made them Claude-only and broken the cross-agent goal. Diffing an existing companion (`memex-recall`) revealed the 3-copy topology and the name-field-only difference.

## How to Apply

When adding or editing a companion skill: author the canonical `.agents/skills/memex-<name>/SKILL.md`, then generate the other two — scaffold via `cp` (same name), plugin via `sed 's/^name: memex-<name>$/name: <name>/'`. Verify all three with `diff <(tail -n +3 A) <(tail -n +3 B)` (bodies must be identical) and the correct `name:` each. Never add a `commands/*.md` for something meant to be cross-agent.
