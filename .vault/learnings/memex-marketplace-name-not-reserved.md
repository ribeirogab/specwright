---
tags:
  - learning
  - gotcha
related:
  - "[[claude-code-reserved-marketplace-names]]"
  - "[[../specs/2026-06-13-dedicate-repo-to-memex/spec]]"
created: 2026-06-13
---
# Bare `memex` is NOT a reserved Claude Code marketplace name

The bare marketplace name `memex` is usable — Claude Code does **not** reserve it. Confirmed 2026-06-13 by writing a throwaway `.claude-plugin/marketplace.json` with `name: memex` into an isolated `/tmp` dir and running `claude plugin marketplace add /tmp/<dir>`: it returned `✔ Successfully added marketplace: memex` with no reservation error. Contrast `agent-skills`, which **is** reserved (see [[claude-code-reserved-marketplace-names]]).

## Context

The `dedicate-repo-to-memex` spec renamed the marketplace `ribeirogab-agent-skills → memex`. Because the prior rename shipped a reserved name and broke at install time, the spec gated the cascade behind a Phase-0 reservation test with `ribeirogab-memex` as the fallback. The test passed, so the repo ships the clean bare name `memex` (marketplace name `memex`, enabled-plugins key `memex@memex`).

Important: testing the name required an **isolated directory**. Running `claude plugin marketplace add ./` in the repo itself short-circuited with `Marketplace 'ribeirogab-agent-skills' already on disk — declared in user settings` — the CLI matched the directory against its existing registration name (from `.claude/settings.json`) rather than re-reading the edited `marketplace.json` `name`. The reservation check only fires when adding a genuinely new name, so the probe must live in a fresh path.

## How to Apply

- `memex` is safe as a marketplace name; no owner prefix needed for it.
- To test whether any candidate marketplace name is reserved, point `claude plugin marketplace add` at a **throwaway dir** whose `marketplace.json` declares that name — not at a directory already registered under a different name (that path no-ops).
- The general rule from [[claude-code-reserved-marketplace-names]] still holds for unknown names: owner-prefix unless you've install-tested the bare name.
