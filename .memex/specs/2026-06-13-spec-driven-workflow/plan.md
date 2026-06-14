---
feature: spec-driven-workflow
spec: "[[2026-06-13-spec-driven-workflow/spec|spec]]"
created: 2026-06-13
---
# Spec-Driven Workflow — Plan

**For this spec:** `[[2026-06-13-spec-driven-workflow/spec|spec]]`

> **For agentic workers:** implement this plan task-by-task from `tasks-spec-driven-workflow.md`. Steps use checkbox (`- [ ]`) syntax. There is no test runner in this repo — "verification" steps are grep/`wc`/shell assertions and the memex validators (`skills/memex/scripts/quick_validate.py`, `package_skill.py`), not unit tests.

**Goal:** Rework the memex spec-driven flow into an explicit 7-step pipeline with an autonomous/reviewed switch, consolidate the non-negotiable rules into a single `.vault/rules.md`, restructure `AGENTS.md` to 5 sections, and add two portable companion skills — `memex-new-pr` and `memex-code-review` — across scaffold + dogfood.

**Architecture:** Almost entirely markdown authoring + repository surgery (`Edit`, `git mv`, `Write`). No executable code. The flow change is encoded at every touchpoint: `AGENTS.md` prose, the `memex-brainstorming` skill (3 copies), the spec template, the two new skills (3 copies each), `.vault/rules.md`, the constitution, and the scaffold/reference mirror. Work proceeds in dependency order: rules file first (everything points at it), then constitution + `AGENTS.md`, then the spec template, then the new skills, then the brainstorming-skill edit, then the reference/scaffold mirror, then quality gate, then PR + code-review cycle.

**Tech Stack:** markdown, bash, `git`, `gh`, Python 3 (only to run the memex skill validators).

---

## Approach

Three orderings are load-bearing:

1. **Rules file precedes everything that links to it.** `AGENTS.md`, the constitution, and the audit checklist all reference `.vault/rules.md`; create it first so no task links to a missing file.
2. **Relocate `skill-validation-requirements.md` before removing `.vault/rules/`.** The note lives inside the directory being deleted; `git mv` it to `.vault/conventions/` first.
3. **New skills before the brainstorming-skill edit references them.** `memex-brainstorming`'s "After the Design" prose names `/memex:new-pr` and `memex:code-review`; build those skills first so the reference is live.

Everything else is grouped by file-area for coherent commits. Each phase ends with a Conventional-Commits commit; **no AI-attribution footer** (constitution; rules.md Git §4).

Cross-agent skills exist in **three real (non-symlink) copies** — confirmed topology, mirror it exactly:
- `.agents/skills/memex-<name>/SKILL.md` — `name: memex-<name>` (canonical, non-Claude agents).
- `plugins/memex/skills/<name>/SKILL.md` — `name: <name>` (plugin copy; surfaces as `/memex:<name>`).
- `skills/memex/scaffold/skills/memex-<name>/SKILL.md` — shipped template.

`.claude/skills/` holds only `memex -> ../../skills/memex` (the skill host); there are **no** per-companion symlinks to create.

## File Structure

**Created:**
- `.vault/rules.md` — single canonical rules file (Philosophy 17 / Git & delivery 5 / Code 2 / Security pointer).
- `.agents/skills/memex-new-pr/SKILL.md`, `plugins/memex/skills/new-pr/SKILL.md`, `skills/memex/scaffold/skills/memex-new-pr/SKILL.md`.
- `.agents/skills/memex-code-review/SKILL.md`, `plugins/memex/skills/code-review/SKILL.md`, `skills/memex/scaffold/skills/memex-code-review/SKILL.md`.

**Moved:**
- `.vault/rules/skill-validation-requirements.md` → `.vault/conventions/skill-validation-requirements.md`.

**Deleted:**
- `.vault/_index/rules.md` (rules MOC — a map over one file adds nothing).
- `.vault/rules/` (now-empty directory).

**Modified:**
- `AGENTS.md` — 5-section restructure (≤ 80 lines).
- `.vault/constitution.md` — `/memex-open-pr` → `/memex:new-pr`; recorded-consent alignment; point detail at `rules.md`.
- `.vault/specs/_template/spec.md` — add `branch:` + `mode:` frontmatter.
- `.vault/_index/home.md` — rules link → `rules.md`.
- `.vault/_index/conventions.md` — add the relocated note.
- `.agents/skills/memex-brainstorming/SKILL.md` + `plugins/memex/skills/brainstorming/SKILL.md` + `skills/memex/scaffold/skills/memex-brainstorming/SKILL.md` — autonomy question + conditional reviews.
- `skills/memex/references/agents-md-template.md` — section list + Template block.
- `skills/memex/references/audit-checklist.md` — required headers (4); `.vault/rules/` → `.vault/rules.md`; drop `_index/rules.md`.
- `skills/memex/references/vault-files.md`, `skills/memex/references/validation.md` — rules-dir → rules-file; flow updates.
- `plugins/memex/commands/spec.md` — mention the autonomy switch.
- the scaffold's vault spec template (mirror of `.vault/specs/_template/spec.md`, wherever it lives under `skills/memex/scaffold/`).

## Phases → spec mapping

| Phase | Spec section | Artifacts |
|---|---|---|
| 1 Rules consolidation | §D | `rules.md`, conventions move, MOC/dir removal, home/conventions index |
| 2 Constitution | §H | `constitution.md` |
| 3 AGENTS.md | §A, §B, §C | `AGENTS.md` |
| 4 Spec template | §G | `_template/spec.md` + scaffold mirror |
| 5 memex-new-pr | §F | 3 skill copies |
| 6 memex-code-review | §E | 3 skill copies |
| 7 memex-brainstorming | §J | 3 skill copies |
| 8 Reference/scaffold mirror | §I | `references/*`, `commands/spec.md` |
| 9 Quality gate | AC block | validators + grep/`wc` checks |
| 10 PR + review cycle | flow steps 6-7 | PR, `memex-code-review` sub-agent to `lgtm` |

## Self-review (plan vs spec)

- Every spec section §A–§J maps to a phase (table above). Acceptance-criteria checks are Phase 9.
- The two new skills are plugin **skills** (3 copies), not commands — no `commands/*.md` created for them (AC asserts their absence).
- The 80-line `AGENTS.md` cap is a Phase 3 verification step (`wc -l`).
- No new test framework is introduced (markdown repo) — verification is grep/`wc`/validators, consistent with the spec's quality-gate definition.
