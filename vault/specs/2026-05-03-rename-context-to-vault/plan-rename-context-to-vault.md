---
feature: rename-context-to-vault
spec: "[[spec-rename-context-to-vault]]"
created: 2026-05-03
---
# Rename `context/` to `vault/` — Plan

**For this spec:** `[[spec-rename-context-to-vault]]`

**Goal:** Rename the `context/` directory to `vault/` across this repo and across every artifact the `memex` skill installs into target repos. Hard cut.

## Approach

Pure rename. No semantic change. Five phases:

1. **Directory rename** — `git mv context vault` (top-level), then `git mv` the two test fixture directories inside `memex-link/tests/fixtures/context/` to `vault/` (canonical and scaffold).
2. **Bulk substitute** — `sed` across all *active* files (everything except shipped specs and the in-flight spec for this rename) replacing `context/` → `vault/`. Includes AGENTS.md, README.md, constitution, MOCs, templates, conventions, rules, all SKILL.md files, all slash commands, all references/, the bash detector, and `.gitignore`.
3. **Per-occurrence review** — `git grep -l 'context/'` post-bulk-substitute. Confirm only allowed survivors remain (4 shipped/in-flight spec folders + any literature mentions in learnings). Edit any leftover skill-referent mention.
4. **Validation** — run all 16 ACs from the spec + `bash .agents/skills/memex-link/tests/run.sh` + the 15 Phase 5 checks (now expecting `vault/` paths).
5. **Ship + PR** — mark spec shipped, index, capture reflection if applicable, push, open PR.

## Architecture

```
Before:                          After:
context/                         vault/
├── constitution.md              ├── constitution.md
├── _index/*.md                  ├── _index/*.md
├── learnings/*.md               ├── learnings/*.md
├── conventions/*.md             ├── conventions/*.md
├── rules/*.md                   ├── rules/*.md
├── specs/                       ├── specs/
│   ├── _template/               │   ├── _template/
│   ├── 2026-04-30-...           │   ├── 2026-04-30-... (frozen)
│   ├── 2026-05-03-rename-h-m/   │   ├── 2026-05-03-rename-h-m/ (frozen)
│   ├── 2026-05-03-strengthen.../│   ├── 2026-05-03-strengthen.../ (frozen)
│   └── 2026-05-03-rename-c-v/   │   └── 2026-05-03-rename-c-v/ (in-flight; preserves "context/" in narrative)
├── templates/*.md               ├── templates/*.md
└── .obsidian/                   └── .obsidian/

memex-link/tests/fixtures/context/ → memex-link/tests/fixtures/vault/   (× 2 — canonical and scaffold)
```

## File Structure

| Operation | Paths |
|---|---|
| `git mv` directory | `context/` → `vault/`; `.agents/skills/memex-link/tests/fixtures/context/` → `vault/`; `skills/memex/scaffold/skills/memex-link/tests/fixtures/context/` → `vault/` |
| `sed` substitute | `AGENTS.md`, `README.md`, `vault/constitution.md`, `vault/_index/*.md`, `vault/templates/*.md`, `vault/conventions/*.md`, `vault/rules/*.md`, `.gitignore`, `skills/memex/SKILL.md`, `skills/memex/references/*.md`, `.agents/skills/memex-*/SKILL.md`, `.agents/skills/memex-link/scripts/find-candidates.sh`, `skills/memex/scaffold/skills/memex-*/SKILL.md`, `skills/memex/scaffold/skills/memex-link/scripts/find-candidates.sh`, `.claude/commands/memex-*.md`, `skills/memex/scaffold/commands/memex-*.md` |
| Excluded from sed | `vault/specs/2026-04-30-opensource-readiness/*.md` (frozen), `vault/specs/2026-05-03-rename-harness-to-memex/*.md` (frozen), `vault/specs/2026-05-03-strengthen-vault-cross-links/*.md` (frozen), `vault/specs/2026-05-03-rename-context-to-vault/*.md` (in-flight narrative) |
| Per-occurrence | Any `vault/learnings/*.md` mention surviving the bulk pass |

## Phase Ordering

1. **Phase 1 — Directory rename.** `git mv` operations only; no content edits yet. Single commit. Working tree post-commit: `vault/` exists, `context/` does not, but file *contents* still say "context/" all over.
2. **Phase 2 — Bulk substitute.** `sed -i` across active files, excluding the 4 spec folders. Single commit.
3. **Phase 3 — Per-occurrence review.** `git grep -l 'context/'` and edit any leftover skill-referent mention. Commit if anything found.
4. **Phase 4 — Validation.** Run the 16 ACs + tests + Phase 5. Fix any failures.
5. **Phase 5 — Ship.** Mark spec shipped, index, reflection, push, PR.

## Risks / Decisions

- **`sed -i` safety on macOS:** use `sed -i.bak ... && rm *.bak` pattern (BSD sed requires the `.bak` arg).
- **Excluding 4 spec folders from sed:** use `find ... -prune` or explicit file lists, not blanket `vault/specs/`. The in-flight spec must be excluded too.
- **Bash detector test fixtures:** the script's `if [ ! -d context ]` and `find context/...` paths flip in Phase 2's sed pass. The fixture directory is renamed in Phase 1's `git mv`. After both, `tests/run.sh` must still PASS — verified in Phase 4.
- **Wikilinks:** relative wikilinks (`[[../../learnings/X]]`) survive automatically. Spot-check by opening Obsidian post-rename (manual, optional).
- **Branch:** already on `feat/rename-context-to-vault`.
