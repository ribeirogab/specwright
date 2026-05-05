---
tags:
  - moc
---
# Specs — Map of Content

All specs for agent-skills features, past and current. Specs never get deleted — shipped specs remain as historical record.

## Workflow trigger

Before implementing a user request, ask: "Can I describe the complete solution in one sentence?" If no → use the Spec Kit flow. If yes → go direct. If almost → ask the user.

Template: `[[../specs/_template/spec|_template/spec]]`

## Active

- [[../specs/2026-05-05-memex-canonical-commands/spec-memex-canonical-commands|memex-canonical-commands]] — bring bundled slash commands under the same `.agents/<cmd>` canonical + `.claude/<cmd>` symlink layout that already governs bundled skills, and stop shipping `memex-open-pr`. Draft 2026-05-05.

## Shipped

- [[../specs/2026-05-03-rename-context-to-vault/spec-rename-context-to-vault|rename-context-to-vault]] — renamed the canonical knowledge-base directory from `context/` to `vault/` across the repo and across every artifact the `memex` skill installs into target repos (Hard cut, no back-compat fallback). Aligns with Obsidian's terminology (the directory IS a vault). Shipped 2026-05-03.
- [[../specs/2026-05-03-strengthen-vault-cross-links/spec-strengthen-vault-cross-links|strengthen-vault-cross-links]] — added `related:` to spec template, hardened post-spec backlink rule, extended `/memex-sweep` with isolated-specs detector, backfilled `opensource-readiness`, and shipped new `memex-link` skill for interactive cross-link suggestions. Shipped 2026-05-03.
- [[../specs/2026-05-03-rename-harness-to-memex/spec-rename-harness-to-memex|rename-harness-to-memex]] — full rename of the flagship skill (`harness/` → `memex/`), bundled skills (`harness-*` → `memex-*`), slash commands, and active vault references. Preserves the `harness engineering` literature term and the shipped 2026-04-30 spec. Shipped 2026-05-03.
- [[../specs/2026-04-30-opensource-readiness/spec-opensource-readiness|opensource-readiness]] — added LICENSE, README, CONTRIBUTING, CODE_OF_CONDUCT, SECURITY, NOTICE.md, .github templates, and restored vendored opensource-guide-coach LICENSE so the repo can be safely published as MIT-licensed open source. Shipped 2026-04-30.
