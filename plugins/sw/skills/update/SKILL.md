---
name: update
description: "Sync an installed memex with upstream — reconcile the scaffolded files against the current upstream memex: auto-apply changes to files you never touched, agent-merge the ones you edited, and never touch living vault content. Use when upstream memex changed scaffolded content (a renamed term, a reworded skill) and you want it pulled in without clobbering local edits."
---

# update — Reconcile the installed memex against upstream

Pull upstream changes into an installed memex's **scaffolded** content without clobbering local edits. The deterministic work (fetch, classify, auto-apply the safe cases) is the engine's; you only merge the files that genuinely conflict.

**Announce at start:** "Reconciling memex against upstream..."

## What is managed

Only **file-backed scaffold content**, each compared by sha256 against a tracked baseline (`.memex/.update-manifest.json`):

| Local path | Upstream source (in the clone) |
|---|---|
| `.agents/skills/memex-<name>/SKILL.md` (recall, brainstorming, writing-plans, link, new-pr, code-review, update) | `<clone>/skills/memex/scaffold/skills/memex-<name>/SKILL.md` |
| `.memex/spec-driven-development.md` | `<clone>/skills/memex/scaffold/vault-docs/spec-driven-development.md` |
| `.memex/scripts/validate-spec.sh` | `<clone>/skills/memex/scaffold/vault-scripts/validate-spec.sh` |
| `.memex/scripts/memex-update.sh` | `<clone>/skills/memex/scaffold/vault-scripts/memex-update.sh` |
| the `### Spec flow` block of `AGENTS.md` | the `### Spec flow` block of `<clone>/skills/memex/references/agents-md-template.md` |

**Never touched:** `.memex/_index/*`, `.memex/learnings/*`, `.memex/conventions/*`, `.memex/specs/*`, the per-repo intro and non-spec-flow sections of `AGENTS.md`, and `constitution.md`. Prose-generated content (templates, `rules.md`, MOCs, the constitution) is out of scope — it has no single upstream file to hash.

## Run the engine

```bash
bash .memex/scripts/memex-update.sh --run
```

It fetches the current upstream memex (`git clone --depth 1` — needs network), classifies every managed path, **auto-applies** the safe updates, and prints a report. No network → it stops with a clear message; re-run when online.

Read the report. The first line is the clone location:

```
clone	/tmp/tmp.XXXXXX
```

then one line per managed path: `current` / `updated` / `local-only` / `conflict` + a tab + the path.

- **`current`** — already matches upstream. Nothing to do.
- **`updated`** — the file was untouched since last sync and upstream changed it; the engine already copied the new version in. (For the AGENTS block, only the `### Spec flow` block was replaced; the per-repo intro is intact.)
- **`local-only`** — you edited it; upstream did not. Left as-is.
- **`conflict`** — both you and upstream changed it. Needs a merge (below).

## Merge each conflict

For every `conflict` line, keep the clone path from the report's first line and:

1. Read the local file and its upstream counterpart (the source column above, under `<clone>/…`).
2. Produce a merge that **keeps the local edits and applies the upstream change** — same intent the user customized for, with upstream's new wording/structure folded in. For an `AGENTS.md#spec-flow` conflict, merge only the block between `### Spec flow` and the next `## ` header.
3. Write the merged file.
4. Record the new baseline so the next run is precise (records the upstream hash you reconciled against):

```bash
bash .memex/scripts/memex-update.sh --record <local-path> <clone>
```

You are the only non-deterministic actor, and only on conflicts. If a "conflict" turns out to be a file you don't recognize (e.g. a skill that was never installed locally), treat upstream as the source of truth and write it in.

## First run with no manifest (2-way)

A legacy install (scaffolded before this command existed) has no `.memex/.update-manifest.json`. The first run degrades to **2-way**: files equal to upstream report `current`; everything else reports `conflict` (the engine cannot tell "you edited it" from "upstream changed it" without a baseline). Merge those conflicts as above; the run writes a manifest, so the **next** update is fully 3-way and precise. Say this explicitly when you see an all-`conflict` first run.

## Report the summary

Print counts built from the report's `STATUS\tpath` lines, categorized as **current** / **updated** / **merged** (the conflicts you resolved) / **local-only**, then:

> Review `git diff`, commit when satisfied. **This command never commits and never opens a PR.**

## Boundaries

- **No commit, no push, no PR.** This is a maintenance command, not the spec-flow delivery — `/memex:new-pr` stays the only PR path.
- **Only the managed set.** Never read-for-overwrite anything under the "never touched" list.
- The temp clone is left in place for the merge step; it is disposable (under `/tmp`).
