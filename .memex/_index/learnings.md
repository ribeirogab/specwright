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
- [[../learnings/vault-link-identity-is-basename-keyed|Vault link identity is basename-keyed — bare filenames need path-qualified wikilinks]] — Obsidian and the GC tooling resolve `[[ ]]` by basename; bare `spec.md` needs the dated folder as discriminator on both link text and resolver identity.

## `#reference` — Environment and commands

- [[../learnings/companion-skill-distribution-topology|A memex companion skill ships in three real copies, not as a command]] — `.agents/skills/memex-<name>` (name=memex-<name>) + `plugins/memex/skills/<name>` (name=<name>) + scaffold; plugin skills are the portable `/memex:` mechanism, commands are Claude-only.
- [[../learnings/quick-validate-needs-pyyaml-via-uv|Run the skill validators with `uv run --with pyyaml`]] — the system `python3` lacks PyYAML; `uv run --quiet --with pyyaml python skills/memex/scripts/quick_validate.py <path>` resolves it ephemerally.

## `#gotcha` — Things that tripped us up

- [[../learnings/vendoring-a-single-skill-loses-upstream-license|Vendoring a single skill from a multi-skill repo loses the upstream LICENSE]] — license-at-root layouts (xixu-me/skills pattern) drop the notice when only the skill subdir is vendored; restore inside the folder + add a NOTICE.md row.
- [[../learnings/rename-spec-grep-first|Rename specs must start with git grep, never list scope from memory]] — running `git grep` and `find -name` BEFORE writing scope catches files intuition misses; also: distinguish basename-match (`find -name`) from content-match (`grep -rl`) in acceptance criteria.
- [[../learnings/bash-strict-mode-grep-filter|Bash strict mode + grep filter exits 1 — wrap with `\|\| true`]] — `set -euo pipefail` + `grep -Ev` / `grep -c` that produces zero matches kills the script silently; wrap the failing step in a brace block with `\|\| true`, never the whole pipeline.
- [[../learnings/validator-verdict-decoupled-from-findings|A validator's verdict can silently decouple from its findings (pipe subshell)]] — `fail=1` set inside `cmd | while …` dies with the subshell, so the check always concluded PASS; compute the verdict from output captured in the parent shell (`bad=$(…)`).
- [[../learnings/claude-code-extra-known-marketplaces-source-schema|Claude Code `extraKnownMarketplaces` rejects `local` source — use `directory`]] — the discriminated union in settings.json schema accepts `url`/`hostPattern`/`github`/`git`/`npm`/`file`/`directory`; `local` is invalid and Claude Code skips the entire settings file on failure. Cross-check `json.schemastore.org/claude-code-settings.json`, not just the prose docs.
- [[../learnings/claude-code-reserved-marketplace-names|Claude Code reserves marketplace names like `agent-skills` for Anthropic]] — the CLI rejects `claude plugin marketplace add` with `name 'X' is reserved` unless source is `github:anthropics/<repo>`. Always owner-prefix marketplace names (`ribeirogab-agent-skills`) and test `marketplace add` before shipping.
- [[../learnings/memex-marketplace-name-not-reserved|Bare `memex` is NOT a reserved marketplace name]] — confirmed via an isolated-dir `marketplace add` probe; testing a name requires a throwaway path, since adding the repo's own dir no-ops against its existing registration.
- [[../learnings/git-rm-leaves-gitignored-leftovers|`git rm -r <dir>` leaves the dir on disk when it holds gitignored files]] — tracked files are removed but `__pycache__`/`workspace/`/`*.skill` remain; `rm -rf` after `git ls-files <dir>` comes up empty.
