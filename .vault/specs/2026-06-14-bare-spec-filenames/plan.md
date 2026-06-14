---
feature: bare-spec-filenames
spec: "[[2026-06-14-bare-spec-filenames/spec|spec]]"
created: 2026-06-14
---
# Bare Spec Filenames — Plan

**For this spec:** `[[2026-06-14-bare-spec-filenames/spec|spec]]`

> **For agentic workers:** implement task-by-task from `tasks-bare-spec-filenames.md`. The only executable test is `bash .agents/skills/memex-link/tests/run.sh` (needs `jq`); everything else is verified with `find`/`grep`/`diff`/`wc` and the markdown validators via `uv run --quiet --with pyyaml python skills/memex/scripts/quick_validate.py`.

**Goal:** Reverse memex's spec-file naming convention from `<type>-<slug>.md` to bare `spec.md`/`plan.md`/`tasks.md` ship-wide, keep every wikilink resolvable via path-qualified links (dated folder = discriminator), re-key the `/memex:link` GC tooling on folder-relative identity, and migrate this repo's 10 spec folders.

**Architecture:** Markdown + bash edits only, no new tooling. The `memex-link` `find-candidates.sh` is the one piece of real logic — it moves from basename identity to a folder-relative "link key" for spec-folder files, driven TDD by its fixture harness. Everything else is convention/doc/validator text flipped from slug-form to bare-form, plus a `git mv` migration. Multi-copy skills/scripts are edited canonically (`.agents`) and regenerated to `plugins`/`scaffold`; body-identity is asserted in the quality gate.

**Tech Stack:** bash, awk, sed, git, jq, markdown, `uv` (PyYAML validators).

---

## Approach

The link resolver regex already accepts an optional path prefix, so path-qualified links are *detected* today. The work has two natures: (1) one logic change — make `find-candidates.sh` key spec-folder files (`spec`/`plan`/`tasks`) on `<folder>/<base>` instead of bare basename, so two bare `spec.md` files don't collide in dedup or evidence matching; (2) a large but mechanical text flip — every place that *teaches*, *enforces*, or *documents* the old `<type>-<slug>.md` convention is rewritten to bare-names + path-qualified links, then the 10 existing spec folders are renamed and their inbound links rewritten.

Order matters: make the tooling folder-aware **first** (so migrated links resolve and validators expect bare), then flip convention/skills/docs, then migrate the real vault, then run the quality gate over the migrated result.

The single canonical "link key" rule, applied symmetrically to both a target's path and every `related[]` entry:

> Take the note's path segments. Let `base` = last segment minus `.md`. If `base ∈ {spec, plan, tasks}` → key = `<second-to-last-segment>/<base>` (e.g. `2026-06-14-foo/spec`). Otherwise → key = `base` (e.g. `companion-skill-distribution-topology`).

Learnings/conventions/rules keep bare-basename identity (their basenames are already globally unique); only spec-folder files gain the folder qualifier. This is the minimal change that fixes exactly the collision bare naming introduces (Rule of Simplicity).

## File Structure

**Logic + tests (Phase 1):**
- `.agents/skills/memex-link/scripts/find-candidates.sh` (canonical) → regenerate `plugins/memex/skills/link/scripts/find-candidates.sh` + `skills/memex/scaffold/skills/memex-link/scripts/find-candidates.sh` (byte-identical).
- `.agents/skills/memex-link/tests/fixtures/.vault/specs/…` — migrate the existing slug-named fixture to bare; add a second bare spec folder + a source learning that proves no cross-spec false-dedup.
- `.agents/skills/memex-link/tests/expected-output.json` — add the one new candidate.
- `plugins/memex/commands/sweep.md` — broken-link resolution folder-aware for spec links; check #5 → `spec.md`/`tasks.md`.

**Convention definition (Phase 2):**
- `skills/memex/references/vault-files.md` — "Spec file naming convention" prose (~264) + plan/tasks template blocks (~207–249).
- `.vault/specs/_template/plan.md`, `.vault/specs/_template/tasks.md` — keep bare `[[spec]]`/`[[plan]]` placeholders (reconcile target = already correct on disk; confirm).

**Generating skills (Phase 3):**
- `memex-brainstorming` ×3, `memex-writing-plans` ×3 — write bare filenames + inject `[[<folder>/<type>|<type>]]` sibling links.

**Validator / audit / recipe (Phase 4):**
- `skills/memex/references/validation.md` — invert check #15 + TOC line #10.
- `skills/memex/references/audit-checklist.md` — invert "Spec file naming" section.
- `skills/memex/SKILL.md` — reverse the Phase-4 rename recipe.

**Project law / docs (Phase 5):**
- `.vault/constitution.md`, `skills/memex/references/constitution-template.md` — flow line.
- `skills/memex/references/agents-md-template.md`, `AGENTS.md` — spec-flow step 3.
- `plugins/memex/skills/new-pr/SKILL.md` (+ `.agents` + `scaffold` copies), `plugins/memex/commands/review-spec.md` — filename refs.

**Migration (Phase 6):**
- All 10 `.vault/specs/YYYY-MM-DD-*/` folders — `git mv` + link rewrite.
- `.vault/_index/specs.md` MOC + any inbound learning links.

## Phases → spec mapping

| Phase | Spec § | Output |
|---|---|---|
| 1 GC tooling + tests | §C | folder-aware `find-candidates.sh` ×3, fixtures, sweep |
| 2 convention definition | §A | vault-files.md + templates |
| 3 generating skills | §B | brainstorming ×3, writing-plans ×3 |
| 4 validator/audit/recipe | §D | validation #15, audit-checklist, SKILL.md recipe |
| 5 project law/docs | §E | constitution ×2, AGENTS + template, new-pr ×3, review-spec |
| 6 migration | §F | 10 folders renamed, links rewritten, MOC |
| 7 quality gate | AC | link test, sweep, validators, 3-copy diffs, greps |

## Risks / Open Decisions

- **`find-candidates.sh` is dense bash** — TDD: extend the fixture + expected-output for the two-spec no-false-dedup case and confirm it FAILS on the unmodified script before editing logic (Task 1.1 → 1.3).
- **`sed` over-match on link rewrite** — scope every rewrite to wikilink edges and to the exact 10 known slugs; verify with a before/after sweep (`[[sed-rename-pattern-completeness]]`, `[[rename-spec-grep-first]]`).
- **3-copy drift** — regenerate plugin/scaffold copies in the same task that edits the canonical; assert byte-identity in Phase 7.
- **Self-referential migration** — this spec's own `plan`/`tasks`/`spec` files are renamed bare in Phase 6; `git mv` only files that exist.

## Self-review (plan vs spec)

- Every spec change group §A–§G maps to a phase (table above); §G (sync invariant) is folded into each editing task + asserted in Phase 7.
- Every Acceptance Criterion has a verifying step in Phase 7 (`find` empties, `run.sh` PASS, sweep zero BROKEN, inverted-validator PASS/FAIL spot-check, grep no-hit, 3-copy diffs, ≤80-line AGENTS, vault-files prose).
- No new frontmatter, no new artifact, markdown+bash only — constitution-compliant.
