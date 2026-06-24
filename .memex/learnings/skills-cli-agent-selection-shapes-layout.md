---
tags:
  - learning
  - reference
related:
  - "[[../specs/2026-06-24-install-script/spec]]"
  - "[[companion-skill-distribution-topology]]"
created: 2026-06-24
---
# skills CLI `-a <agent>` shapes the on-disk install layout

`npx skills add <pkg> --skill <name> -a <agent>` writes a different layout per target agent, and the memex canonical layout (`.agents/skills/<name>/` real files + `.claude/skills/<name>` symlink) is **not** what any single `-a` produces:

- `-a universal` → writes the real files to `.agents/skills/<name>/` (the open agent-skills standard path), **no** `.claude/` symlink.
- `-a claude-code` → **copies** the real files straight into `.claude/skills/<name>/`, with **no** `.agents/` canonical and no symlink.
- `-a "claude-code,universal"` or `-a "claude-code universal"` → rejected as one invalid agent name; `-a` takes a single agent or `*`.
- `-a '*'` → writes `.agents/skills/<name>/` **and** a stray `agent/skills/<name>/` dir, still no `.claude` symlink.

To get `.agents/` canonical + a `.claude/skills/<name>` symlink, install with `-a universal` and create the symlink yourself.

## Context

Discovered building the per-project `install.sh` ([[../specs/2026-06-24-install-script/spec]]). The goal layout was `.agents/skills/memex/` + `.claude/skills/memex -> ../../.agents/skills/memex` + `skills-lock.json`. The plain README command `npx skills add ribeirogab/memex --skill memex` (auto-detecting `claude-code`) produced a real `.claude/skills/memex/` copy instead — divergent from the target. Probing each `-a` value in throwaway dirs revealed the table above.

## How to Apply

For a per-skill canonical-plus-symlink layout, the installer runs:

```sh
npx -y skills add ribeirogab/memex --skill memex -a universal -y </dev/null
mkdir -p .claude/skills
ln -s ../../.agents/skills/memex .claude/skills/memex
```

Verify the result (`.agents/skills/<name>/SKILL.md`, the symlink resolves, `skills-lock.json` exists) rather than trusting a single `-a` flag to lay it out. See [[curl-pipe-sh-stdin-drain]] for the `</dev/null` on the `npx` line.
