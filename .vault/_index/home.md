---
tags:
  - moc
---
# memex — Project Knowledge Vault

This vault contains all project-specific knowledge for memex: constitution, specs, learnings, and rules.

## Where to go

- **[[../constitution|Constitution]]** — non-negotiable project principles. Read before any substantive work.
- **[[specs|Specs MOC]]** — all specs, past and present, indexed by status.
- **[[learnings|Learnings MOC]]** — architecture, patterns, gotchas.
- **[[conventions|Conventions MOC]]** — code style choices the team has made.
- **[[../rules|Rules]]** — non-negotiable operational rules: philosophy, git & delivery, code.

## How to use this vault

- New feature or refactor → copy `../specs/_template/` and fill in.
- New learning discovered → copy `../templates/learning.md` and add to `../learnings/`.
- New convention agreed → copy `../templates/convention.md` and add to `../conventions/`.
- New non-negotiable rule → add it to the relevant section of `../rules.md`.
- Always cross-link notes using Obsidian's `[[ ]]` syntax so backlinks aggregate concepts over time.
