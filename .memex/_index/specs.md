---
tags:
  - moc
---
# Specs — Map of Content

All specs for memex features, past and current. Specs never get deleted — shipped specs remain as historical record.

## Workflow trigger

Before implementing a user request, ask: "Can I describe the complete solution in one sentence?" If no → use the Spec Kit flow. If yes → go direct. If almost → ask the user.

Template: `[[../specs/_template/spec|_template/spec]]`

## Active

- [[../specs/2026-06-14-benchmark-spec-driven-tools/spec|benchmark-spec-driven-tools]] — deep, source-grounded benchmark of two peer spec-driven tools (`tlc-spec-driven`, `OpenSpec`): two reference learnings (md + visual html, mermaid flows) plus a synthesis learning of ranked, high-impact improvements for memex. Analysis-only — implementing the insights is left to future specs. Draft 2026-06-14.
- [[../specs/2026-05-05-memex-canonical-commands/spec|memex-canonical-commands]] — bring bundled slash commands under the same `.agents/<cmd>` canonical + `.claude/<cmd>` symlink layout that already governs bundled skills, and stop shipping `memex-open-pr`. Draft 2026-05-05.

## Shipped

- [[../specs/2026-06-14-spec-flow-restructure/spec|spec-flow-restructure]] — restructured the per-spec artifact model (new non-technical `design.md`; `spec.md` fused with the plan into the technical doc, gaining a recorded-only `scope` field + `AC-N` traceability; `tasks.md` gains `AC:`/`Delegable:`; `plan.md` removed) and wired four benchmark insights: AC traceability, a test-integrity rule, a two-subagent (project-law + spec-conformance) code-review, and a shell `validate-spec.sh` gate (no language dependency) run by `/memex:review-spec`. Also set the lifecycle rule: PR opened + code-review `lgtm` = shipped. Shipped 2026-06-14.
- [[../specs/2026-06-14-rename-vault-to-memex/spec|rename-vault-to-memex]] — renamed the scaffolded knowledge-vault directory `.vault/` → `.memex/` across the repo and every artifact the `memex` skill installs, so the directory announces the tool that owns it (like `.git/`). Hard cut, no back-compat. Directory + path references only — the conceptual term *vault* and conceptual filenames stay; frozen shipped specs keep their ship-time `.vault/` bodies. Verification anchored on the old dot-path token since `memex` is the overloaded product name. Shipped 2026-06-14.
- [[../specs/2026-06-14-bare-spec-filenames/spec|bare-spec-filenames]] — reversed the spec-file naming convention from `<type>-<slug>.md` to bare `spec.md`/`plan.md`/`tasks.md` ship-wide; the dated folder became the link discriminator (path-qualified wikilinks) and `find-candidates.sh` re-keys on folder-relative identity. Migrated the 10 existing spec folders, inverted validation check #15 + audit + the rename recipe. Shipped 2026-06-14.
- [[../specs/2026-06-13-dedicate-repo-to-memex/spec|dedicate-repo-to-memex]] — converted the repo from a personal multi-skill library into a memex-only repository: deleted every non-memex skill (`skill-improver`, vendored `skill-creator`/`opensource-guide-coach`), renamed the project identity `agent-skills → memex` (repo slug, marketplace `ribeirogab-agent-skills → memex`, titles, install commands, embedded refs), relocated the skill-validation scripts into `skills/memex/scripts/`, and rewrote the constitution/docs/vault. GitHub repo rename (`gh repo rename memex`) is a maintainer handoff step. Shipped 2026-06-13.
- [[../specs/2026-05-15-memex-claude-plugin-namespace/spec|memex-claude-plugin-namespace]] — migrated the four bundled slash commands from `.agents/commands/` + `.claude/commands/` symlinks to a Claude Code plugin shipped from this repo as marketplace `agent-skills`. Memex skill stops writing command files and instead writes `.claude/settings.json` so the plugin installs at workspace-trust time. Invocation changes from `/memex-spec` to `/memex:spec` etc. Constitution scope amended. Shipped 2026-05-15.
- [[../specs/2026-05-03-rename-context-to-vault/spec|rename-context-to-vault]] — renamed the canonical knowledge-base directory from `context/` to `.vault/` across the repo and across every artifact the `memex` skill installs into target repos (Hard cut, no back-compat fallback). Aligns with Obsidian's terminology (the directory IS a vault). Shipped 2026-05-03. (The directory was later renamed `.vault/` → `.memex/`; see `[[../specs/2026-06-14-rename-vault-to-memex/spec|rename-vault-to-memex]]`.)
- [[../specs/2026-05-03-strengthen-vault-cross-links/spec|strengthen-vault-cross-links]] — added `related:` to spec template, hardened post-spec backlink rule, extended `/memex-sweep` with isolated-specs detector, backfilled `opensource-readiness`, and shipped new `memex-link` skill for interactive cross-link suggestions. Shipped 2026-05-03.
- [[../specs/2026-05-03-rename-harness-to-memex/spec|rename-harness-to-memex]] — full rename of the flagship skill (`harness/` → `memex/`), bundled skills (`harness-*` → `memex-*`), slash commands, and active vault references. Preserves the `harness engineering` literature term and the shipped 2026-04-30 spec. Shipped 2026-05-03.
- [[../specs/2026-04-30-opensource-readiness/spec|opensource-readiness]] — added LICENSE, README, CONTRIBUTING, CODE_OF_CONDUCT, SECURITY, NOTICE.md, .github templates, and restored vendored opensource-guide-coach LICENSE so the repo can be safely published as MIT-licensed open source. Shipped 2026-04-30.
