---
feature: dedicate-repo-to-memex
spec: "[[spec-dedicate-repo-to-memex]]"
created: 2026-06-13
---
# Dedicate Repo to Memex — Plan

**For this spec:** `[[spec-dedicate-repo-to-memex]]`

> **For agentic workers:** implement this plan task-by-task from `tasks-dedicate-repo-to-memex.md`. Steps use checkbox (`- [ ]`) syntax. There is no test runner in this repo — "verification" steps are grep/shell assertions and the memex Phase-5 validator, not unit tests.

**Goal:** Convert the repo from a personal multi-skill library into a memex-only repository — delete every non-memex skill, rename the project identity `agent-skills → memex`, relocate the validation scripts into memex, and rewrite the constitution/docs/vault so nothing frames the repo as a collection of skills.

**Architecture:** Pure repository surgery — `git mv`/`git rm`/`Edit`. No code logic changes. The only behavioral surface that changes is memex's *scaffold* layer, where the marketplace name and install slug are string-embedded. Work proceeds in dependency order: resolve the marketplace name first (it gates the rename cascade), relocate scripts before deleting their source skill, then cascade the rename, then rewrite prose, then validate.

**Tech Stack:** markdown, bash, `jq`, `git`, `gh`, Python 3 (only to run the relocated validators).

---

## Approach

This is the third identity-rename in the repo's history (`harness → memex`, `context → vault`, and now `agent-skills → memex`), so the mechanics are well-trodden: grep-first to enumerate every occurrence, `git mv`/`git rm` so history follows, then a repo-wide grep as the acceptance gate. What is new here is (a) a **deletion** dimension (non-memex skills leave) and (b) a **reserved-name gate**: the chosen marketplace name `memex` is exactly the kind of short generic string Claude Code reserves, so the rename must not cascade until the name is install-tested. See `[[../../learnings/claude-code-reserved-marketplace-names|claude-code-reserved-marketplace-names]]`.

Two orderings are load-bearing and must not be reversed:

1. **Phase 0 (name gate) precedes the rename cascade (Phases 3–4).** If `memex` is reserved we fall back to `ribeirogab-memex`, and the fallback name must be the one cascaded — otherwise we rewrite ~25 references twice.
2. **Phase 1 (relocate scripts) precedes Phase 2 (delete skill-improver).** The validators live inside `skills/skill-improver/scripts/`; deleting the skill first destroys them.

Everything else (prose rewrites, vault edits) is independent and could run in any order, but is grouped by file-area to keep commits coherent.

`<MKT>` throughout the tasks doc denotes the marketplace name resolved in Phase 0: either `memex` or the fallback `ribeirogab-memex`. The enabled-plugins key is `memex@<MKT>`.

## File Structure

**Deleted:**
- `skills/skill-improver/` — the second published skill (after its scripts are relocated).
- `.claude/skills/skill-improver` — symlink to the above.
- `.claude/skills/skill-creator/` — vendored Apache-2.0 reference (real dir).
- `.claude/skills/opensource-guide-coach/` — vendored MIT reference (real dir).
- `evals/` — contains only `evals/skill-improver/`.
- `.vault/learnings/{skill-development-workflow,skill-progressive-disclosure,skill-degrees-of-freedom,generator-evaluator-separation}.md` — skill-authoring craft.
- `.vault/conventions/{skill-directory-layout,skill-md-style}.md` — skill-authoring craft.
- `.github/ISSUE_TEMPLATE/skill_request.md` — replaced by `feature_request.md`.

**Created:**
- `skills/memex/scripts/{quick_validate.py,package_skill.py,__init__.py}` — relocated validators (`git mv` from skill-improver).
- `.github/ISSUE_TEMPLATE/feature_request.md` — memex feature / companion request.

**Modified — rename cascade (`agent-skills` / `ribeirogab-agent-skills` / `ribeirogab/agent-skills`):**
- `.claude-plugin/marketplace.json` — marketplace `name`.
- `.claude/settings.json` — `extraKnownMarketplaces` + `enabledPlugins` keys.
- `skills/memex/SKILL.md` — dogfood detection, jq recipe, doc lines (6 occurrences).
- `skills/memex/references/claude-plugin-settings.md` — single-source-of-truth coordinates (many occurrences).
- `skills/memex/references/audit-checklist.md` — Phase-4/5 checks.
- `skills/memex/references/validation.md` — Phase-5 jq checks.
- `skills/memex/references/agents-md-template.md` — the AGENTS.md memex scaffolds into target repos.

**Modified — prose pivot:**
- `README.md` — title, lead, drop `## Skills` + skill-improver section, single install, layout tree.
- `AGENTS.md` — title + opening (`CLAUDE.md` symlink propagates).
- `CONTRIBUTING.md` — scope, quality-bar script paths, out-of-scope wording.
- `SECURITY.md` — "Skills under skills/" → memex.
- `NOTICE.md` — keep Apache-2.0 section (new path), drop maintainer-local section.
- `.github/PULL_REQUEST_TEMPLATE.md` — repoint script paths, drop `## Skills` checkbox, drop `evals/`.

**Modified — constitution + vault:**
- `.vault/constitution.md` — title, "Why exists", scope guardrails.
- `.vault/_index/home.md` — title + framing.
- `.vault/_index/{learnings,conventions,rules,specs}.md` — `agent-skills` → `memex` in MOC headers; remove links to the 6 deleted notes.
- `.vault/learnings/{harness-engineering-foundations,vendoring-a-single-skill-loses-upstream-license,claude-code-extra-known-marketplaces-source-schema}.md` — per-occurrence `agent-skills` review (kept notes).

**Untouched:** `LICENSE`, `CODE_OF_CONDUCT.md`, `plugins/memex/.claude-plugin/plugin.json` (plugin name stays `memex`), all historical specs under `.vault/specs/` (except this one), `.vault/learnings/claude-code-reserved-marketplace-names.md` (documents the old name — frozen).

## Phase Ordering

| Phase | Name | Depends on | Why |
|---|---|---|---|
| 0 | Marketplace-name gate | — | Resolves `<MKT>`; gates 3–4 |
| 1 | Relocate validation scripts | — | Must precede 2 (scripts live in skill-improver) |
| 2 | Delete non-memex skills | 1 | — |
| 3 | Rename cascade (marketplace + slug) | 0 | Uses `<MKT>` |
| 4 | Identity titles | 0 | Uses `<MKT>`/slug |
| 5 | Docs prose pivot | 1, 2 | CONTRIBUTING/PR-template reference new script path; README drops deleted skill |
| 6 | Constitution + vault | 2 | Removes deleted-note links |
| 7 | Validate + GitHub-rename handoff | all | Phase-5 validator; maintainer runs `gh repo rename` |

## Risks / Open Decisions

- **Reserved `memex` name** — mitigated by Phase 0 install test + auto-fallback. The implementer must record the outcome (which `<MKT>` won) before starting Phase 3.
- **Double-rename waste** — if Phase 3 starts before Phase 0 resolves, a fallback forces re-editing every reference. Hard ordering enforced in the tasks doc.
- **Lost script history** — use `git mv` (not `rm`+`add`); a `git log --follow` check is built into Phase 1's verification.
- **Broken `.claude/skills/` symlink** — the `memex` symlink is *preserved*, not recreated; Phase 2 only removes the other three entries. A resolve-check is the phase's verification step.
- **GitHub rename is the maintainer's action** — the implementer prepares everything and hands over the exact `gh repo rename memex` command; the implementer does not run it.
- **Spec status flip + reflection** — ship the `status: shipped` edit and the reflection learning in this same PR (project rule), not a follow-up.
