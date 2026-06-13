---
tags:
  - moc
---
# Learnings — Map of Content

Atomic notes about memex's architecture, patterns, and gotchas. Categorized by tag.

Learnings here are specific to memex. Code style conventions live in `[[conventions|Conventions MOC]]`.

## `#concept` — Architecture and patterns

### Harness engineering (the runtime pattern, not skill authoring)

- [[../learnings/harness-engineering-foundations|Harness engineering — the foundation behind this repo]] — the three articles (Anthropic, Fowler, OpenAI) that inform the existing `memex/` skill (the literature pattern is still called *harness engineering*; only the skill was renamed — see [[../learnings/memex]]).
- [[../learnings/memex|Memex — Vannevar Bush's 1945 personal memory extender]] — the canonical name for "externalized, navigable personal memory"; conceptual frame for the `.vault/` vault and the rename of `harness` → `memex`.
- [[../learnings/agents-md-as-map-not-encyclopedia|AGENTS.md is a map, not an encyclopedia]] — keep root agent instructions ~100 lines and point into `.vault/`; the four failure modes of the monolithic approach.
- [[../learnings/mechanical-enforcement-over-prose|Mechanical enforcement beats prose rules]] — runnable checks > written rules; feedforward + feedback; embed remediation in error messages.

## `#reference` — Environment and commands

_No references yet._

## `#gotcha` — Things that tripped us up

- [[../learnings/vendoring-a-single-skill-loses-upstream-license|Vendoring a single skill from a multi-skill repo loses the upstream LICENSE]] — license-at-root layouts (xixu-me/skills pattern) drop the notice when only the skill subdir is vendored; restore inside the folder + add a NOTICE.md row.
- [[../learnings/rename-spec-grep-first|Rename specs must start with git grep, never list scope from memory]] — running `git grep` and `find -name` BEFORE writing scope catches files intuition misses; also: distinguish basename-match (`find -name`) from content-match (`grep -rl`) in acceptance criteria.
- [[../learnings/bash-strict-mode-grep-filter|Bash strict mode + grep filter exits 1 — wrap with `\|\| true`]] — `set -euo pipefail` + `grep -Ev` / `grep -c` that produces zero matches kills the script silently; wrap the failing step in a brace block with `\|\| true`, never the whole pipeline.
- [[../learnings/claude-code-extra-known-marketplaces-source-schema|Claude Code `extraKnownMarketplaces` rejects `local` source — use `directory`]] — the discriminated union in settings.json schema accepts `url`/`hostPattern`/`github`/`git`/`npm`/`file`/`directory`; `local` is invalid and Claude Code skips the entire settings file on failure. Cross-check `json.schemastore.org/claude-code-settings.json`, not just the prose docs.
- [[../learnings/claude-code-reserved-marketplace-names|Claude Code reserves marketplace names like `agent-skills` for Anthropic]] — the CLI rejects `claude plugin marketplace add` with `name 'X' is reserved` unless source is `github:anthropics/<repo>`. Always owner-prefix marketplace names (`ribeirogab-agent-skills`) and test `marketplace add` before shipping.
- [[../learnings/memex-marketplace-name-not-reserved|Bare `memex` is NOT a reserved marketplace name]] — confirmed via an isolated-dir `marketplace add` probe; testing a name requires a throwaway path, since adding the repo's own dir no-ops against its existing registration.
- [[../learnings/git-rm-leaves-gitignored-leftovers|`git rm -r <dir>` leaves the dir on disk when it holds gitignored files]] — tracked files are removed but `__pycache__`/`workspace/`/`*.skill` remain; `rm -rf` after `git ls-files <dir>` comes up empty.
