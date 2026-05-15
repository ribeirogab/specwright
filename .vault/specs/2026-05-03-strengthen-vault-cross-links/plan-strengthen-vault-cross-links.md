---
feature: strengthen-vault-cross-links
spec: "[[spec-strengthen-vault-cross-links]]"
created: 2026-05-03
---
# Strengthen Vault Cross-Links — Plan

**For this spec:** `[[spec-strengthen-vault-cross-links]]`

**Goal:** Make the `context/` knowledge graph denser by shipping (1) frontmatter+rule changes that prompt cross-linking at write time, (2) a sweep check that flags isolated specs, (3) a retroactive backfill of the existing island, and (4) a new `/memex-link` skill that detects missing `related:` entries with a deterministic Bash detector and an interactive accept loop.

## Approach

The five components from the spec map to four implementation phases plus validation and ship. Phases are ordered by dependency: lightest edits first (so they're committed and out of the way), then the new skill (the biggest piece), then integration into the memex scaffolder, then end-to-end validation.

The new `memex-link` skill is built TDD — one evidence type per fixture per task, each task adds capability and a test case proves it. The Bash detector grows from "empty array" to "handles all four evidence types + filters" across five iterative tasks. By the time the skill is wired into the slash command and scaffold, the detector is fully tested.

Inline execution: each phase ends in a single commit; no subagent dispatch. The branch is `feat/strengthen-vault-cross-links` (already created).

## Architecture

```
Component 1 — Spec template
  context/specs/_template/spec.md
  └── frontmatter: + related: []
  └── body: + explanatory note about populating it

Component 2 — Workflow rule
  AGENTS.md  (CLAUDE.md auto-propagates via symlink)
  └── ## After completing a spec
      └── tighten "if applicable" → "MUST include a wikilink back to the spec"

Component 3 — Sweep check
  .claude/commands/memex-sweep.md
  skills/memex/scaffold/commands/memex-sweep.md
  └── + ### Isolated specs section (detector logic)

Component 4 — Retroactive backfill
  context/specs/2026-04-30-opensource-readiness/spec-opensource-readiness.md
  └── frontmatter: + related: with one wikilink

Component 5 — New memex-link skill
  .agents/skills/memex-link/                  ← canonical
  ├── SKILL.md                                  (4-phase procedure: detect → classify → present → loop)
  ├── scripts/find-candidates.sh                (deterministic detector, emits JSON array)
  └── tests/
      ├── fixtures/context/                     (mini vault — covers each evidence type + each filter)
      ├── expected-output.json                  (golden JSON for the fixtures)
      └── run.sh                                (cd's into fixtures/, runs script, diffs vs expected)

  .claude/skills/memex-link → ../../.agents/skills/memex-link    ← per-agent symlink

  .claude/commands/memex-link.md                ← thin slash command (delegates to skill)

  skills/memex/scaffold/skills/memex-link/      ← scaffold template (mirror of canonical)
  skills/memex/scaffold/commands/memex-link.md  ← scaffold template

  skills/memex/SKILL.md
  └── SKILL_NAMES array: + memex-link
  └── slash-command loop: + memex-link

  skills/memex/references/audit-checklist.md
  └── inventory: + .agents/skills/memex-link/ + .claude/commands/memex-link.md

  skills/memex/references/validation.md
  └── check #9 hardcoded array: + memex-link
  └── check #11 hardcoded list: + memex-link
```

## File Structure

| Path | Operation | Phase |
|---|---|---|
| `context/specs/_template/spec.md` | Modify (frontmatter + body) | 1 |
| `AGENTS.md` | Modify (one section) | 1 |
| `context/specs/2026-04-30-opensource-readiness/spec-opensource-readiness.md` | Modify (frontmatter only) | 1 |
| `.claude/commands/memex-sweep.md` | Modify (append section) | 2 |
| `skills/memex/scaffold/commands/memex-sweep.md` | Modify (append section, mirror) | 2 |
| `.agents/skills/memex-link/SKILL.md` | Create | 3 |
| `.agents/skills/memex-link/scripts/find-candidates.sh` | Create + grow over 5 tasks | 3 |
| `.agents/skills/memex-link/tests/run.sh` | Create | 3 |
| `.agents/skills/memex-link/tests/expected-output.json` | Create + grow over 5 tasks | 3 |
| `.agents/skills/memex-link/tests/fixtures/context/learnings/*.md` | Create | 3 |
| `.agents/skills/memex-link/tests/fixtures/context/specs/2026-01-01-test/*.md` | Create | 3 |
| `.claude/skills/memex-link` | Create (symlink) | 4 |
| `.claude/commands/memex-link.md` | Create (slash command) | 4 |
| `skills/memex/scaffold/skills/memex-link/` | Create (mirror canonical) | 4 |
| `skills/memex/scaffold/commands/memex-link.md` | Create (mirror) | 4 |
| `skills/memex/SKILL.md` | Modify (SKILL_NAMES + cmd loop) | 5 |
| `skills/memex/references/audit-checklist.md` | Modify (inventory) | 5 |
| `skills/memex/references/validation.md` | Modify (check #9 array + check #11 list) | 5 |

## Phase Ordering

1. **Phase 1 — Static edits (Components 1, 2, 4).** Three tiny edits, one commit. No dependencies between them. Shipping these first means the new convention starts existing immediately for any concurrent work.
2. **Phase 2 — Sweep `### Isolated specs` (Component 3).** Edit two files (canonical + scaffold). One commit. Independent of Phase 1.
3. **Phase 3 — `memex-link` canonical skill (Component 5, part A).** Build the canonical skill at `.agents/skills/memex-link/` from skeleton to fully-tested. TDD across 6 sub-tasks (1 skeleton + 5 evidence/filter cases). Single commit at the end.
4. **Phase 4 — Symlink + slash command + scaffold mirror (Component 5, part B).** Once the canonical works and tests pass, create the per-agent symlink, the slash command, and the scaffold mirrors. One commit.
5. **Phase 5 — Memex scaffolder integration (Component 5, part C).** Update `skills/memex/SKILL.md`, `audit-checklist.md`, `validation.md` to register `memex-link`. One commit.
6. **Phase 6 — Validation.** Run all 19 acceptance criteria from the spec + the 15-step Phase 5 validation from `validation.md` + `tests/run.sh`. Fix anything that fails until clean.
7. **Phase 7 — Ship.** Mark spec `shipped`, index it, run reflection (any new learnings), push, open PR via `/memex-open-pr`.

Phases run sequentially. Commit at the end of each phase so a mid-flight failure leaves the repo in a coherent state.

## Risks / Open Decisions

- **Bash 3 vs Bash 4 compatibility.** macOS ships bash 3.2 by default; bash 4 features (`declare -A`, etc.) won't run on stock systems. Decision: write `find-candidates.sh` to be bash 3.2-compatible — no associative arrays, recompute per iteration. For a 100-note vault that's <2s; the spec already accepted this perf profile in Risks.
- **Implementer must use `git mv` for any moves and avoid `sed -i` on tracked content files.** No moves are planned, but the rule stands. For the validation.md edits, prefer the `Edit` tool over `sed`.
- **Test fixtures live under `.agents/skills/memex-link/tests/fixtures/`.** They must look like a real `context/` vault to the script. The script always expects to be run from a directory containing `context/`; `tests/run.sh` cds into `fixtures/` first.
- **Scaffold byte-equivalence is enforced post-hoc by AC #8.** The implementer must, after Phase 3 produces the canonical, copy it byte-for-byte to `skills/memex/scaffold/skills/memex-link/` in Phase 4. Never edit only one side and forget the other; always edit canonical and re-mirror.
- **Sweep test in validation requires a fixture island.** AC #17 says sweep must flag a constructed test island. Plan: add a tiny fixture spec (under `tests/fixtures/sweep-island/`) for the validation phase, then remove it. Or use the live opensource-readiness spec *before* Phase 1's retroactive edit lands… but Phase 1 lands first, so that won't work. Decision: create a transient fixture in `/tmp` for the sweep test, not committed to repo.
- **`/memex-link` against the live vault during validation is destructive (it edits frontmatter on accept).** Plan: run with `n` (no) to all suggestions during validation, just to verify it produces output and the loop works. Real backfill of the live vault stays a manual follow-up after merge if any new connections are surfaced.
