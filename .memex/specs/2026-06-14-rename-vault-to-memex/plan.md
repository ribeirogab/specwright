---
status: draft
feature: rename-vault-to-memex
created: 2026-06-14
related:
  - "[[2026-06-14-rename-vault-to-memex/spec|spec]]"
  - "[[2026-06-14-rename-vault-to-memex/tasks|tasks]]"
---
# Rename `.vault/` to `.memex/` — Implementation Plan

> **For agentic workers:** Steps use checkbox (`- [ ]`) syntax for tracking. Execute inline (see Execution Approach).

**Goal:** Rename the scaffolded knowledge-vault directory `.vault/` → `.memex/` across this repo and every artifact the memex skill installs, as a hard cut, preserving the conceptual term *vault* and frozen historical spec bodies.

**Architecture:** Pure mechanical rename. `git mv` for the directory (history follows), then a `perl -pi` sweep that replaces the literal dot-path token `\.vault` → `.memex` across explicitly-listed state-describing files. Frozen shipped specs and one historical-narrative learning are excluded by never being in a target list. The `memex-link` test fixtures + scripts flip together so the two working test copies stay green.

**Tech Stack:** bash, `git mv`, `perl -pi` (portable in-place edit, `\.vault` matches the literal dot-token — the conceptual word *vault* has no leading dot and is never touched).

---

## Key principles (apply to every task)

- **Anchor on `\.vault` (leading dot), never the bare word.** `.vault` appears only as the directory path token; `vault` (no dot) is the kept conceptual term and `memex` is the product name — both legitimately everywhere. Every grep/replace uses `\.vault`.
- **`perl -pi -e 's/\.vault/.memex/g'`** is the replace primitive. It catches `.vault/`, bare `.vault` (e.g. `[ ! -d .vault ]`, `test ! -e .vault`), and `.vault/.obsidian/`.
- **Never target `specs/`** — frozen shipped specs keep their ship-time `.vault/` references. No task touches files under the specs directory (except this spec's own AC ticks).
- **Exclude `learnings/sed-rename-pattern-completeness.md`** from the learnings flip — its `.vault/` mentions describe the *result* of the historical `context → .vault/` rename; flipping them would state a falsehood.
- **macOS note:** `perl -pi -e` works without the BSD-`sed` empty-backup quirk. Use it.

## File map

| Area | Files | Task |
|---|---|---|
| Directory + ignore | `.vault/` (→`.memex/`), `.gitignore` | 1 |
| Vault canon + current-state notes | `constitution.md`, `rules.md`, `_index/{specs,learnings}.md`, `templates/*`, `conventions/*`, `learnings/*` (minus the survivor) | 2 |
| Root docs | `AGENTS.md`, `README.md`, `SECURITY.md`, `CONTRIBUTING.md`, `.github/PULL_REQUEST_TEMPLATE.md` | 3 |
| Skill source | `skills/memex/SKILL.md`, `skills/memex/references/*.md` | 4 |
| Companion skills (non-link) | `{.agents/skills/memex-*,plugins/memex/skills/*,skills/memex/scaffold/skills/memex-*}/SKILL.md` (brainstorming, code-review, new-pr, recall, writing-plans), `plugins/memex/commands/*.md` | 5 |
| memex-link (×3 copies) | `scripts/find-candidates.sh`, `tests/fixtures/{.vault,vault}` (→`{.memex,memex}`), `tests/expected-output.json`, `tests/fixtures/.../source-with-filepath.md` | 6 |
| Final sweep + ticks | spec AC, phrase-artifact check, validation | 7 |

## Execution Approach

**Inline execution.** Although there are 7 tasks, they are one tightly-coupled mechanical rename whose risk is judgment (anchor discipline, frozen-spec exclusion, per-occurrence learnings, the pre-existing scaffold/plugin drift) rather than volume. That judgment lives in this session's context; handing one task per fresh subagent would require re-establishing it each time. Execute inline with a commit + verification per task. **REQUIRED SUB-SKILL:** superpowers:executing-plans.

## Baseline to capture before Task 1

Save these so Task 6/7 can prove "no new divergence":

```bash
diff -rq .agents/skills/memex-link/ plugins/memex/skills/link/ > /tmp/baseline-A-vs-plugin.txt 2>&1   # 10 lines
diff -rq .agents/skills/memex-link/ skills/memex/scaffold/skills/memex-link/ > /tmp/baseline-A-vs-scaffold.txt 2>&1   # 3 lines
bash plugins/memex/skills/link/tests/run.sh > /dev/null 2>&1 && echo "plugin link: PASS"   # confirm green baseline
```

(Scaffold copy test is pre-existingly broken — `FATAL: .vault/ not found` — and stays that way; out of scope.)

See `tasks.md` for the step-by-step.
