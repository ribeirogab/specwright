---
tags:
  - learning
  - concept
related:
  - "[[harness-engineering-foundations]]"
  - "[[agents-md-as-map-not-encyclopedia]]"
created: 2026-05-03
---
# Memex — Vannevar Bush's 1945 personal memory extender

The **memex** is the device Vannevar Bush proposed in his July 1945 *Atlantic* essay *As We May Think*: a desk-sized machine that stores all of a person's books, records, and communications, and lets the user weave **associative trails** between any two items so that future-you can re-traverse the path. Bush's framing — *associative indexing*, persistent trails, an extension of personal memory rather than a replacement for it — predates and prefigures hypertext, the wiki, and today's PKM tools (Obsidian, Roam, Logseq). It is the canonical name in computing history for "the thing that gives one person a durable, navigable, externalized memory."

## Context

Surfaced while choosing a name for the `harness` skill in this repo. The skill scaffolds a `context/` vault — atomic notes, MOCs, wikilinks, an Obsidian-compatible layout — which is structurally and *conceptually* a memex: it externalizes the agent's project memory and lets future sessions re-traverse the trails left behind. "Harness" described the mechanism (idempotent scaffolder); "memex" describes the *artifact it produces and the role it plays for the agent*. Bush's essay also explicitly framed the memex as an *augmentation of human thought*, which mirrors how this vault augments an agent's reasoning across sessions.

## How to Apply

When explaining what this skill does — to a user, in a README, in `AGENTS.md` — anchor the pitch in the memex frame, not the scaffolder frame: "it installs a memex into your repo so any agent (Claude Code, Codex, Cursor, OpenCode) gets persistent project memory." That framing answers *why* before *what* and connects the skill to a 80-year intellectual lineage instead of presenting it as one more dotfile generator. When naming sibling skills/commands, prefer terms that fit the memex metaphor (trails, traces, recall, recollection) over generic tooling words (config, init, setup).
