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
- [[../learnings/memex|Memex — Vannevar Bush's 1945 personal memory extender]] — the canonical name for "externalized, navigable personal memory"; conceptual frame for the `.memex/` vault and the rename of `harness` → `memex`.
- [[../learnings/agents-md-as-map-not-encyclopedia|AGENTS.md is a map, not an encyclopedia]] — keep root agent instructions ≤ 80 lines (target 70–80) and point into `.memex/`; the four failure modes of the monolithic approach.
- [[../learnings/mechanical-enforcement-over-prose|Mechanical enforcement beats prose rules]] — runnable checks > written rules; feedforward + feedback; embed remediation in error messages.
- [[../learnings/vault-link-identity-is-basename-keyed|Vault link identity is basename-keyed — bare filenames need path-qualified wikilinks]] — Obsidian and the GC tooling resolve `[[ ]]` by basename; bare `spec.md` needs the dated folder as discriminator on both link text and resolver identity.

## `#reference` — Environment and commands

- [[../learnings/companion-skill-distribution-topology|A memex companion skill ships in three real copies, not as a command]] — `.agents/skills/memex-<name>` (name=memex-<name>) + `plugins/memex/skills/<name>` (name=<name>) + scaffold; plugin skills are the portable `/memex:` mechanism, commands are Claude-only.
- [[../learnings/quick-validate-needs-pyyaml-via-uv|Run the skill validators with `uv run --with pyyaml`]] — the system `python3` lacks PyYAML; `uv run --quiet --with pyyaml python skills/memex/scripts/quick_validate.py <path>` resolves it ephemerally.
- [[../learnings/validate-vault-mermaid-with-mmdc|Validate vault mermaid with mermaid-cli (no-build, one-off)]] — extract ` ```mermaid ` blocks and render them with `npx @mermaid-js/mermaid-cli -p pptr.json` (no-sandbox puppeteer config); exit 0 = parses, honors the no-build-pipeline rule.

## `#benchmark` — Peer spec-driven tools (comparative analyses)

- [[../learnings/tlc-spec-driven-workflow|tlc-spec-driven — the Tech Lead's Club spec-driven skill]] — memex's markdown sibling: complexity-adaptive Specify→Design→Tasks→Execute, traceability IDs, test-integrity checks, all-prose (no machine enforcement); has a `.html` companion. From the [[../specs/2026-06-14-benchmark-spec-driven-tools/spec|benchmark spec]].
- [[../learnings/openspec-workflow|OpenSpec — the Fission-AI spec-driven CLI]] — the structural opposite: compiled CLI + Zod schemas, gate-free "actions not phases", filesystem-derived state, delta specs that merge into a living source of truth (two distinct archive paths — CLI vs skill); has a `.html` companion.
- [[../learnings/memex-improvement-insights|memex improvement insights (benchmark synthesis)]] — capability comparison + 6 ranked, high-impact-only recommendations (traceability IDs, test-integrity check, spec-conformance verify, mechanical spec validator, scope safety valve, anti-fabrication rule) with a "considered & parked" list; has a `.html` companion.

## `#gotcha` — Things that tripped us up

- [[../learnings/vendoring-a-single-skill-loses-upstream-license|Vendoring a single skill from a multi-skill repo loses the upstream LICENSE]] — license-at-root layouts (xixu-me/skills pattern) drop the notice when only the skill subdir is vendored; restore inside the folder + add a NOTICE.md row.
- [[../learnings/rename-spec-grep-first|Rename specs must start with git grep, never list scope from memory]] — running `git grep` and `find -name` BEFORE writing scope catches files intuition misses; also: distinguish basename-match (`find -name`) from content-match (`grep -rl`) in acceptance criteria.
- [[../learnings/bash-strict-mode-grep-filter|Bash strict mode + grep filter exits 1 — wrap with `\|\| true`]] — `set -euo pipefail` + `grep -Ev` / `grep -c` that produces zero matches kills the script silently; wrap the failing step in a brace block with `\|\| true`, never the whole pipeline.
- [[../learnings/validator-verdict-decoupled-from-findings|A validator's verdict can silently decouple from its findings (pipe subshell)]] — `fail=1` set inside `cmd | while …` dies with the subshell, so the check always concluded PASS; compute the verdict from output captured in the parent shell (`bad=$(…)`).
- [[../learnings/claude-code-extra-known-marketplaces-source-schema|Claude Code `extraKnownMarketplaces` rejects `local` source — use `directory`]] — the discriminated union in settings.json schema accepts `url`/`hostPattern`/`github`/`git`/`npm`/`file`/`directory`; `local` is invalid and Claude Code skips the entire settings file on failure. Cross-check `json.schemastore.org/claude-code-settings.json`, not just the prose docs.
- [[../learnings/claude-code-reserved-marketplace-names|Claude Code reserves marketplace names like `agent-skills` for Anthropic]] — the CLI rejects `claude plugin marketplace add` with `name 'X' is reserved` unless source is `github:anthropics/<repo>`. Always owner-prefix marketplace names (`ribeirogab-agent-skills`) and test `marketplace add` before shipping.
- [[../learnings/memex-marketplace-name-not-reserved|Bare `memex` is NOT a reserved marketplace name]] — confirmed via an isolated-dir `marketplace add` probe; testing a name requires a throwaway path, since adding the repo's own dir no-ops against its existing registration.
- [[../learnings/git-rm-leaves-gitignored-leftovers|`git rm -r <dir>` leaves the dir on disk when it holds gitignored files]] — tracked files are removed but `__pycache__`/`workspace/`/`*.skill` remain; `rm -rf` after `git ls-files <dir>` comes up empty.
- [[../learnings/rename-toward-overloaded-token-verifies-on-old-token|Renaming toward an overloaded token — verify on the OLD token]] — when the rename target is the product name (everywhere), anchor greps/ACs on the old dot-path token (`\.vault`), framed as "old token survives only in frozen specs"; never assert "zero new token".
- [[../learnings/memex-link-copies-have-drifted|The three `memex-link` copies have drifted — not byte-identical]] — plugin fixtures kept pre-bare-filename naming; the scaffold copy's no-dot fixture makes its bundled test FATAL. Capture a baseline `diff -rq` before sweeping; only `.agents`/`plugins` tests run green.
- [[../learnings/skill-for-type-loop-is-legacy-rename-not-scaffolding|SKILL.md's `for type` loop is a legacy rename, not artifact scaffolding]] — it renames slug→bare for flagged legacy folders; keep `plan` in the set (legacy specs predate `design.md`), add new types as a superset. New-spec scaffolding lives in `vault-files.md` + `_template/`, not this loop.
- [[../learnings/validate-spec-flags-template-meta-specs|`validate-spec.sh` flags literal `{{ }}` in prose]] — a spec whose subject is the templates quotes `{{...}}` (even in backticks) and trips check 2; an old-model meta-spec also lacks `scope`. Correct detections, false positives for a template-meta-spec — document the expected FAILs, don't weaken the grep.
- [[../learnings/reconcile-baseline-tracks-upstream-not-merged-local|Three-way reconcile: baseline := upstream hash, never the merged-local hash]] — recording the post-merge local hash makes the next run auto-clobber the merge (it reads `L==B`→stale-clean). After every run `B == U` for all paths; the agent records `U` (not the file it wrote) after a conflict merge. The classifier matrix self-test won't catch a record-step hashing the wrong operand — test it separately.
