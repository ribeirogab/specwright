---
tags:
  - moc
---
# Learnings — Map of Content

Atomic notes about agent-skills's architecture, patterns, and gotchas. Categorized by tag.

Learnings here are specific to agent-skills. Code style conventions live in `[[conventions|Conventions MOC]]`.

## `#concept` — Architecture and patterns

### Skill authoring (Anthropic platform)

- [[../learnings/skill-progressive-disclosure|Progressive disclosure — the three-level loading model]] — frontmatter (always loaded) → SKILL.md body (on trigger) → linked files (on demand); why the directory layout exists.
- [[../learnings/skill-degrees-of-freedom|Degrees of freedom — match instruction specificity to task fragility]] — high / medium / low; pick by cost-of-variation; mix levels within one skill.
- [[../learnings/skill-development-workflow|Skill development workflow — eval-first, Claude A / Claude B]] — build evals before docs; iterate one task to working; use a two-Claude feedback loop.

### Harness engineering (the runtime pattern, not skill authoring)

- [[../learnings/harness-engineering-foundations|Harness engineering — the foundation behind this repo]] — the three articles (Anthropic, Fowler, OpenAI) that inform the existing `memex/` skill (the literature pattern is still called *harness engineering*; only the skill was renamed — see [[../learnings/memex]]).
- [[../learnings/memex|Memex — Vannevar Bush's 1945 personal memory extender]] — the canonical name for "externalized, navigable personal memory"; conceptual frame for the `context/` vault and the rename of `harness` → `memex`.
- [[../learnings/agents-md-as-map-not-encyclopedia|AGENTS.md is a map, not an encyclopedia]] — keep root agent instructions ~100 lines and point into `context/`; the four failure modes of the monolithic approach.
- [[../learnings/mechanical-enforcement-over-prose|Mechanical enforcement beats prose rules]] — runnable checks > written rules; feedforward + feedback; embed remediation in error messages.
- [[../learnings/generator-evaluator-separation|Always separate the generator from the evaluator]] — agents praise their own work; ship a calibrated evaluator for any artifact that's graded subjectively.

## `#reference` — Environment and commands

_No references yet._

## `#gotcha` — Things that tripped us up

- [[../learnings/vendoring-a-single-skill-loses-upstream-license|Vendoring a single skill from a multi-skill repo loses the upstream LICENSE]] — license-at-root layouts (xixu-me/skills pattern) drop the notice when only the skill subdir is vendored; restore inside the folder + add a NOTICE.md row.
- [[../learnings/rename-spec-grep-first|Rename specs must start with git grep, never list scope from memory]] — running `git grep` and `find -name` BEFORE writing scope catches files intuition misses; also: distinguish basename-match (`find -name`) from content-match (`grep -rl`) in acceptance criteria.
- [[../learnings/bash-strict-mode-grep-filter|Bash strict mode + grep filter exits 1 — wrap with `\|\| true`]] — `set -euo pipefail` + `grep -Ev` / `grep -c` that produces zero matches kills the script silently; wrap the failing step in a brace block with `\|\| true`, never the whole pipeline.
