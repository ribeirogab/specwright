---
status: shipped
feature: rename-harness-to-memex
created: 2026-05-03
shipped: 2026-05-03
---
# Rename Harness Skill to Memex — Spec

**Status:** Shipped (2026-05-03)
**Scope:** Rename the `harness` skill (and every dependent identifier — bundled skills, slash commands, symlinks, vault references) to `memex` across this repo, while preserving the `harness` term where it refers to the published *harness engineering* literature (Fowler / Anthropic / OpenAI 2025-26 essays) rather than this skill.

## Context

The skill formerly called `harness` scaffolds a `context/` vault, atomic-note templates, an `AGENTS.md`, and a set of bundled skills/commands into any repo. The name "harness" was descriptive of the *mechanism* (idempotent scaffolder), but vague — "harness" is also the technical term for the runtime pattern this repo's [[../learnings/harness-engineering-foundations|harness-engineering-foundations]] note describes, leading to terminology collision.

`memex` (Vannevar Bush, *As We May Think*, 1945) is the canonical name for "an externalized, navigable personal memory" — exactly the artifact this skill produces. See [[../learnings/memex|memex]] for the conceptual frame. Renaming separates the skill's identity ("memex") from the technical pattern it implements ("harness engineering"), which removes the collision.

## Problem Statement

The `harness` identifier is overloaded: it names both (a) this repo's flagship skill and (b) a published technical pattern that the skill happens to embody. Users reading `context/learnings/harness-engineering-foundations.md` and `skills/harness/` cannot tell from the name alone that one refers to the literature concept and the other refers to the install command. A clean rename of the skill identifier resolves the ambiguity without disturbing the literature concept.

## Non-Goals

- **Not** renaming the technical pattern. `harness engineering` (literature) stays. `context/learnings/harness-engineering-foundations.md` stays at its current path.
- **Not** rewriting historical spec records. `context/specs/2026-04-30-opensource-readiness/` is shipped and frozen — its references to `harness` are part of the historical record.
- **Not** changing how the skill works internally. This is a rename, not a refactor.
- **Not** updating downstream repos that already ran the old `harness` skill. They keep what they have until they re-run. **Cross-version coexistence note:** if a downstream repo previously installed `harness-*` and then runs the renamed `memex` scaffolder, both directories will coexist (`.agents/skills/harness-*/` alongside `.agents/skills/memex-*/`) because the install loop only checks `[ -e ... ] && continue` — it does not remove old prefixes. Cleaning up legacy `harness-*` is the user's responsibility on those repos.
- **Not** adding a back-compat alias (`/harness-spec` continuing to work alongside `/memex-spec`). Hard cut.

## Constraints

- The repo dogfoods its own scaffolder: `.agents/skills/` is canonical, `.claude/skills/*` are symlinks. Both layers must update atomically — broken symlinks are an automatic acceptance failure.
- `CLAUDE.md` at the repo root is a symlink to `AGENTS.md`; updating `AGENTS.md` propagates.
- Three learning notes (`generator-evaluator-separation.md`, `agents-md-as-map-not-encyclopedia.md`, `mechanical-enforcement-over-prose.md`) cite `harness` in **mixed** contexts — sometimes meaning the skill, sometimes the literature pattern. They require per-occurrence judgment, not global substitution.
- `.agents/skills/harness-brainstorming/scripts/start-server.sh` comments use "harness" to refer to the **parent process** in the Unix process tree — these comments stay as-is (different referent).
- No other agent dirs (`.codex/`, `.cursor/`, etc.) are installed in this repo, so cross-agent symlink updates are limited to `.claude/`.

## User Stories / Scenarios

1. A new contributor reads the README and sees "memex skill installs your project memex" — the name and the artifact agree.
2. A future user runs `/memex-spec` to convert a conversation into a spec. The slash command behaves identically to the previous `/harness-spec`.
3. A user re-runs `/memex` (formerly `/harness`) on a repo previously scaffolded with the old version. *Out of scope* — they would either rename manually or re-scaffold from scratch.
4. A reader opens `context/learnings/harness-engineering-foundations.md`, sees the literature term "harness engineering" preserved, and finds a clarifying paragraph noting that the *skill* renamed to memex but the *pattern* kept its name.

## Acceptance Criteria

- [x] `find . -name "*harness*" -not -path "./.git/*" -not -path "./node_modules/*"` returns **only** these 5 expected paths and nothing else:
  - `./context/learnings/harness-engineering-foundations.md` (literature)
  - `./context/specs/2026-05-03-rename-harness-to-memex` (this spec's folder — slug contains "harness" because that's the topic)
  - `./context/specs/2026-05-03-rename-harness-to-memex/spec.md`
  - `./context/specs/2026-05-03-rename-harness-to-memex/plan.md`
  - `./context/specs/2026-05-03-rename-harness-to-memex/tasks.md`

  Note: the `2026-04-30-opensource-readiness/` folder is preserved as historical record (Non-Goal #2), but its files do **not** match `find -name "*harness*"` because their basenames don't contain that word — only their content does. AC #2 below covers content survivors.
- [x] `grep -rIn "harness" AGENTS.md README.md context/constitution.md context/_index/ context/templates/ context/conventions/ context/rules/` returns zero lines (no leftover skill references in user-facing/active vault docs).
- [x] `grep -rIn "harness" context/learnings/` returns only mentions inside `harness-engineering-foundations.md` and the per-occurrence-reviewed survivors in the three mixed-context notes — every survivor is annotated in the commit message with a one-line justification.
- [x] Every entry under `.claude/skills/` resolves: `for f in .claude/skills/*; do [ -e "$f" ] || echo BROKEN $f; done` prints nothing.
- [x] Every renamed SKILL.md has `name:` matching the new directory: `memex`, `memex-recall`, `memex-brainstorming`, `memex-writing-plans` — verified by `grep -h '^name:' .agents/skills/memex-*/SKILL.md skills/memex/SKILL.md`.
- [x] Every renamed slash command file either has no `name:` field or has one that matches its basename — verified by:

  ```bash
  for f in .claude/commands/memex-*.md; do
    name_field=$(awk '/^name:/{print $2; exit}' "$f")
    [ -z "$name_field" ] || [ "$name_field" = "$(basename "$f" .md)" ] || echo "MISMATCH $f"
  done
  ```

  Expected: empty output. Also `ls .claude/commands/ | grep -E '^harness-'` returns nothing (no leftover prefixes).
- [x] The 15 checks in `skills/memex/references/validation.md` pass (15/15) when run against this repo.
- [x] `git log --oneline | head -1` shows the rename commits on a branch named `feat/rename-harness-to-memex`, **not** `main`.
- [x] A reflection learning note (or an explicit "no new learnings" line in the closing PR description) exists per the project's after-completing-a-spec rule.
- [x] The spec file's frontmatter has `status: shipped` and a non-null `shipped:` date once the work is merged.

## Risks and Mitigations

| Risk | Mitigation |
|---|---|
| `git mv` history lost on bulk renames | Use `git mv` per file/folder, never `mv` followed by `git add`. Verify with `git log --follow` on a sample file after the move. |
| Broken `.claude/skills/` symlinks after rename | Re-create symlinks in the same task that moves the canonical dir. Acceptance check `[ -e "$f" ]` runs in validation. |
| Per-occurrence `harness` mentions misclassified (skill vs. literature) | Read each line in full context (paragraph) before editing. When a mention's referent is ambiguous, default to the *literature* reading and leave it (because over-renaming breaks the literature note's coherence; under-renaming is caught by readers later and is cheaper to fix). |
| `start-server.sh` comments that refer to the parent process accidentally rewritten | Constraint section calls these out by exact line range. Validation grep on `context/` and root files only — `.agents/skills/*/scripts/` is excluded from the rename pass. |
| Slash command in flight (`/memex-spec` etc.) called during the rename | Don't invoke any `/memex-*` or `/harness-*` slash command during the rename window. Use raw shell + Edit only. |
| `CLAUDE.md` accidentally turned into a regular file (lost symlink) | Verify after editing `AGENTS.md`: `test -L CLAUDE.md && readlink CLAUDE.md`. |
| `package.json`, no test runner — can't run automated checks | Validation is the 15-step manual checklist in `skills/memex/references/validation.md`. Acceptance criteria cover it. |

## Open Questions

None. Settled in conversation prior to this spec being written.
