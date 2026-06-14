---
tags:
  - learning
related:
  - "[[../specs/2026-06-14-bare-spec-filenames/spec|bare-spec-filenames]]"
  - "[[mechanical-enforcement-over-prose]]"
  - "[[rename-spec-grep-first]]"
created: 2026-06-14
---
# Vault link identity is basename-keyed — bare filenames need path-qualified wikilinks

Both Obsidian and the memex GC tooling (`/memex:link` `find-candidates.sh`, `/memex:sweep` broken-link check) resolve a `[[wikilink]]` by its **basename**, ignoring the folder. That is why spec files historically carried a slug (`spec-<slug>.md`): it made the basename globally unique. To use **bare** `spec.md`/`plan.md`/`tasks.md` instead, the dated folder must become the discriminator on **both** sides: links are path-qualified (`[[YYYY-MM-DD-<slug>/spec|spec]]`) and the tooling computes a folder-relative key (`<folder>/<base>`) for spec-folder files instead of the bare basename. Only `spec`/`plan`/`tasks` collide under bare naming — learnings/conventions/rules keep unique basenames, so their identity stays bare.

## Context

The `bare-spec-filenames` spec reversed the slug-in-filename convention. The slug existed for two reasons — (a) basename uniqueness for links and (b) editor-tab/fuzzy-finder disambiguation. Path-qualified links solve only (a); (b) was knowingly traded away. The single tricky change was `find-candidates.sh`: its `related[]` parser reduced every link to a basename, and its dedup + wikilink-evidence match compared basenames, so two bare `spec.md` files would falsely dedup against each other. A two-spec fixture (link spec A in `related:`, body-link both A and B) proved the false-dedup before the fix and is the regression guard.

## How to Apply

When changing how vault notes are named or linked, remember resolution is basename-first. If you introduce any duplicate basename, you must either (1) keep names unique, or (2) make links path-qualified **and** re-key every resolver (`find-candidates.sh` extraction + dedup + evidence grep; the sweep broken-link resolver) on a folder-relative identity — changing only one side silently breaks dedup or flags false broken links. Drive the resolver change with the `find-candidates.sh` test fixture, which is the only executable test in the repo.
