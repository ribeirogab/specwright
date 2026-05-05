---
feature: memex-canonical-commands
spec: "[[spec-memex-canonical-commands]]"
created: 2026-05-05
---
# Memex Canonical Commands + Drop `memex-open-pr` — Plan

**For this spec:** `[[spec-memex-canonical-commands]]`

## Approach

The change is entirely contained inside `skills/memex/`. There is no build pipeline, no test runner, no compiled artifacts — just markdown and inline bash. Implementation = five file edits plus one deletion. "Tests" are (a) `grep` assertions on the edited files and (b) running `/memex` against scratch test directories that simulate the three scenarios from the spec (clean install, existing-real-files migration, `.claude/`-absent install) and reading the resulting filesystem state.

The order of edits matters within a session: the scaffold file (`scaffold/commands/memex-open-pr.md`) cannot be deleted before `SKILL.md`'s command loop stops referencing it, otherwise running the skill mid-implementation would `cp` from a missing source and fail. The plan orders edits so that every commit leaves the skill in a runnable, internally-consistent state.

The pattern for canonical commands mirrors the existing skills pattern verbatim: a `COMMAND_NAMES` bash array, an unconditional canonical-copy loop with idempotent skip-if-present, and a `.claude/`-gated symlink loop. The only deviation from skills is the migration branch: when the symlink target already exists as a regular file, the file is removed and replaced with a symlink (skills don't need this branch because nothing pre-2026-05 ever wrote a regular dir at `.claude/skills/<name>`).

## Architecture

```
skills/memex/
├── SKILL.md                        ← Phase 4 commands block rewritten (Task 2)
├── scaffold/
│   └── commands/
│       ├── memex-open-pr.md        ← DELETED (Task 3)
│       ├── memex-learn.md          ← unchanged
│       ├── memex-spec.md           ← unchanged
│       ├── memex-review-spec.md    ← unchanged
│       └── memex-sweep.md          ← unchanged
└── references/
    ├── audit-checklist.md          ← files list + new subsection (Task 4)
    ├── validation.md               ← Check #11 rewrite (Task 5)
    └── agents-md-template.md       ← drop /memex-open-pr line (Task 6)
```

Behavior at install time (after the change):

```
target repo state                       result
──────────────────────────────────────────────────────────────────
fresh repo, .claude/ exists             canonical files in .agents/commands/
                                        symlinks in .claude/commands/

fresh repo, no .claude/                 canonical files in .agents/commands/
                                        no .claude/commands/ created

existing install (real files)           real files in .claude/commands/ removed
                                        canonical files in .agents/commands/
                                        symlinks in .claude/commands/
                                        memex-open-pr.md left intact (orphan)

second run (idempotent)                 no filesystem changes
```

## File Structure

| Path | Action | One-line responsibility |
|---|---|---|
| `skills/memex/SKILL.md` | Modify | Replace Phase 4 commands block with two-step canonical+symlink loop including migration branch |
| `skills/memex/scaffold/commands/memex-open-pr.md` | Delete | Skill no longer ships this command |
| `skills/memex/references/audit-checklist.md` | Modify | Move command entries from `.claude/commands/` (required) to `.agents/commands/` (canonical, required) + add "Per-agent command symlinks" subsection |
| `skills/memex/references/validation.md` | Modify | Redefine Check #11 to validate canonical existence at `.agents/commands/<cmd>.md`; drop `memex-open-pr`; remove N/A branch |
| `skills/memex/references/agents-md-template.md` | Modify | Delete the `/memex-open-pr` bullet from `## Skills and slash commands` |

## Phase Ordering

**Phase 1 — Edit skill** (six tasks, one commit each, every commit leaves skill runnable).

1. Rewrite `SKILL.md` commands block first (so the skill no longer tries to copy `memex-open-pr.md`).
2. Delete the orphaned scaffold file.
3. Update audit-checklist.
4. Update validation.
5. Update agents-md-template.
6. Final grep sweep to confirm no stale `memex-open-pr` references survive anywhere under `skills/memex/`.

**Phase 2 — Verify behavior on scratch repos** (four tasks, no commits — verification only).

7. Fresh install with `.claude/`.
8. Migration on simulated existing install.
9. Idempotency (second run is no-op).
10. Fresh install without `.claude/`.

The verification tasks live in `/tmp/memex-test-*` scratch directories. They are deliberately not committed — they are confidence checks before opening the PR.

## Risks / Open Decisions

None remain. All forks were resolved during brainstorming and recorded in the spec's "Architecture Decisions" section. Implementer should not relitigate:

- Migration policy is "scaffold sempre vence" — no diff/merge.
- Orphan `memex-open-pr.md` policy is "ignore" — no detection, no removal.
- Spec scope is skill-only — do not touch `.claude/commands/` or `AGENTS.md` of this repo.
- Multi-agent loop for commands is intentionally absent.

If any of these become uncertain mid-implementation, stop and re-read the spec rather than guessing.
