---
feature: rename-harness-to-memex
spec: "[[2026-05-03-rename-harness-to-memex/spec|spec]]"
created: 2026-05-03
---
# Rename Harness Skill to Memex — Plan

**For this spec:** `[[2026-05-03-rename-harness-to-memex/spec|spec]]`

**Goal:** Rename every `harness*` identifier in this repo to `memex*` — files, directories, symlinks, frontmatter, prose, and shell snippets — except where `harness` refers to the published *harness engineering* literature.

## Approach

The work is mechanical, not creative. There are no design decisions left; the spec settles all open questions. The plan ordering is dictated by **referential integrity**: rename the canonical thing first, then the symlinks pointing at it, then the prose mentioning it. Doing it in the reverse order leaves a window with broken symlinks and dangling references.

Use `git mv` for every file/directory move so history follows the file. For symlinks, `git rm` + `ln -s` + `git add` (symlinks are tracked by their target string; `git mv` works on symlinks but the convention here is to recreate so the new target is explicit in the diff). Use the `Edit` tool for content changes — never `sed -i` on tracked files in bulk, because the per-occurrence learning files require human judgment. The exception is one targeted `sed` pass on the SKILL.md shell-snippet variable (`SKILL_NAMES`), where the substitution is unambiguous.

The branch is `feat/rename-harness-to-memex`. All commits land there. The PR is opened via `/memex-open-pr` after the slash commands themselves have been renamed (so the command exists when called).

## Architecture

Three layers of identifiers must agree after the rename:

```
Layer 1: Filesystem identity
  skills/memex/                          (top-level skill, canonical)
  .agents/skills/memex-{recall,brainstorming,writing-plans}/   (bundled, canonical)
  .claude/skills/memex                   (symlink → ../../skills/memex)
  .claude/skills/memex-{recall,brainstorming,writing-plans}    (symlinks → ../../.agents/...)
  .claude/commands/memex-{open-pr,learn,spec,review-spec,sweep}.md

Layer 2: Skill metadata (frontmatter `name:` field — must match dir/file basename)
  Each SKILL.md and each .md command updated.

Layer 3: Prose references (every wikilink, code sample, doc that names the skill)
  AGENTS.md, README.md, context/constitution.md, context/_index/, context/templates/,
  context/conventions/, context/rules/, three mixed-context learning notes.
```

Plus a separate population of files that look like they reference the skill but actually reference the *literature concept* or the *Unix process tree*:
- `context/learnings/harness-engineering-foundations.md` (literature — preserved, augmented with one clarifying paragraph)
- `.agents/skills/memex-brainstorming/scripts/start-server.sh` lines 101-103 (process tree — preserved verbatim)
- `skills/memex/scaffold/skills/memex-brainstorming/scripts/start-server.sh` lines 101-103 (same, in the template copy — preserved verbatim)

A second population is **frozen** (preserved with no edits, no clarifying paragraphs):
- `context/specs/2026-04-30-opensource-readiness/{spec,plan,tasks}-opensource-readiness.md` — shipped historical record.

## File Structure

| Path | Operation | Notes |
|---|---|---|
| `skills/harness/` → `skills/memex/` | `git mv` directory | Top-level skill. |
| `skills/memex/SKILL.md` | Edit | Frontmatter `name:`, `SKILL_NAMES` array, slash-command list, prose. |
| `skills/memex/references/{audit-checklist,agents-md-template,validation,vault-files,constitution-template}.md` | Edit | Prose mentions of the skill name; verify references to slash commands also flip. |
| `skills/memex/scaffold/skills/harness-{recall,brainstorming,writing-plans}/` → `memex-...` | `git mv` × 3 | Templates the scaffolder installs into other repos. |
| `skills/memex/scaffold/skills/memex-*/SKILL.md` | Edit × 3 | Frontmatter `name:`. |
| `skills/memex/scaffold/commands/harness-{open-pr,learn,spec,review-spec,sweep}.md` → `memex-...` | `git mv` × 5 | Slash command templates. |
| `skills/memex/scaffold/commands/memex-*.md` | Edit × 5 | Frontmatter; prose self-references. |
| `.agents/skills/harness-{recall,brainstorming,writing-plans}/` → `memex-...` | `git mv` × 3 | Canonical installed skills. |
| `.agents/skills/memex-*/SKILL.md` | Edit × 3 | Frontmatter `name:`. (Should mirror scaffold copies — verify they stay in sync.) |
| `.claude/skills/{harness,harness-recall,harness-brainstorming,harness-writing-plans}` | `git rm` + `ln -s` + `git add` × 4 | Symlinks. New names; new targets. |
| `.claude/commands/harness-{open-pr,learn,spec,review-spec,sweep}.md` → `memex-...` | `git mv` × 5 | The active slash commands. |
| `.claude/commands/memex-*.md` | Edit × 5 | Frontmatter; prose self-references. |
| `AGENTS.md` | Edit | 16 mentions; surgical replacement skill→memex, prefix harness-→memex-. |
| `CLAUDE.md` | Verify symlink intact | No edit needed. |
| `README.md` | Edit | 9 mentions. |
| `context/constitution.md` | Edit | 7 mentions. |
| `context/_index/learnings.md` | Edit | Already partially updated (memex note added). Verify no other harness references that should flip. |
| `context/_index/specs.md`, `context/_index/conventions.md`, `context/_index/rules.md`, `context/_index/home.md` | Edit if mentions present | Survey first. |
| `context/templates/learning.md`, `context/templates/rule.md`, `context/templates/convention.md` | Edit if mentions present | Survey first. |
| `context/conventions/*.md`, `context/rules/*.md` | Edit if mentions present | Survey first. |
| `context/learnings/generator-evaluator-separation.md` | Edit, per-occurrence | 9 mentions. Each mention reviewed: skill → memex; literature pattern → leave. |
| `context/learnings/agents-md-as-map-not-encyclopedia.md` | Edit, per-occurrence | 5 mentions. |
| `context/learnings/mechanical-enforcement-over-prose.md` | Edit, per-occurrence | 3 mentions. |
| `context/learnings/harness-engineering-foundations.md` | Edit (one paragraph added) | Clarify: skill renamed to memex; pattern stays "harness engineering". |
| `context/specs/2026-04-30-opensource-readiness/*.md` | **No edit** | Frozen historical record. |
| `context/specs/2026-05-03-rename-harness-to-memex/spec-*.md` | Edit at end | `status: shipped`, `shipped: <date>`. |
| `context/_index/specs.md` | Edit at end | Add this spec's index entry. |

## Phase Ordering

Dependencies:

1. **Phase 1 — Branch.** Create `feat/rename-harness-to-memex`. Snapshot baseline counts. No dependency.
2. **Phase 2 — Top-level skill.** `git mv skills/harness skills/memex`, edit its `SKILL.md` and `references/`. Must precede Phase 3 (the bundled-skill canonical paths are referenced inside this file's shell snippets), but those snippets are documentation — no execution dependency. Still, doing this first matches the layering.
3. **Phase 3 — Bundled skills.** Rename canonical `.agents/skills/harness-*` → `memex-*`, then rename scaffold templates `skills/memex/scaffold/skills/harness-*` → `memex-*`. Edit each `SKILL.md` frontmatter. Recreate `.claude/skills/` symlinks last (must point at the new canonical paths).
4. **Phase 4 — Slash commands.** Rename both `.claude/commands/harness-*.md` and `skills/memex/scaffold/commands/harness-*.md`. Update prose. After this phase, `/memex-open-pr` etc. are callable.
5. **Phase 5 — Repo docs and active vault.** `AGENTS.md`, `README.md`, `constitution.md`, `_index/`, `templates/`, `conventions/`, `rules/`. Mechanical replacement.
6. **Phase 6 — Per-occurrence learnings.** Surgical pass on the three mixed-context notes; one-paragraph clarification appended to `harness-engineering-foundations.md`.
7. **Phase 7 — Validation.** Run all acceptance-criteria checks, fix anything that fails, run the 15-step Phase 5 validation from the renamed `skills/memex/SKILL.md`.
8. **Phase 8 — Ship.** Mark spec status, index it, write reflection learning if applicable, open PR via `/memex-open-pr`.

Phases run sequentially. **Commit at the end of each phase** so a mid-flight failure leaves the repo in a coherent (if partially-renamed) state.

## Risks / Open Decisions

- **Decision left to implementer:** the per-occurrence calls in the three mixed-context learning notes. Heuristic: a mention next to "skill", "scaffolder", "the harness skill", "harness-spec", or any code path is the *skill*; a mention next to "Fowler", "Anthropic", "OpenAI", "pattern", "literature", "engineering" is the *concept*. When in doubt, leave it (under-rename is recoverable, over-rename poisons the literature note's coherence).
- **Risk:** `.agents/skills/memex-*/SKILL.md` and `skills/memex/scaffold/skills/memex-*/SKILL.md` should ideally have identical content (one is the install, one is the template). Verify with `diff -r` after Phase 3 — divergence is a bug to fix in this same plan, not a follow-up.
- **Risk:** Acceptance criterion 2 (`grep -rIn "harness" AGENTS.md ...` returns zero) is strict. If a justified mention exists in `context/_index/learnings.md` (e.g., the index entry for `harness-engineering-foundations.md`), the criterion needs to be slightly relaxed — the index entry to the *literature* note is a justified survivor. Treat it as one in validation.
