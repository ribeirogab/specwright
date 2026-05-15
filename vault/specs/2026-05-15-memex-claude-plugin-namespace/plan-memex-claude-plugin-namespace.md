---
feature: memex-claude-plugin-namespace
spec: "[[spec-memex-claude-plugin-namespace]]"
created: 2026-05-15
---
# Memex Claude Plugin Namespace — Plan

**For this spec:** `[[spec-memex-claude-plugin-namespace]]`

## Approach

The change has two surfaces:

1. **Upstream — `ribeirogab/agent-skills` becomes a Claude Code marketplace.** Repo root gains `.claude-plugin/marketplace.json` declaring the marketplace `agent-skills`, and `plugins/memex/` containing a plugin manifest plus four command files. The plugin namespace is `memex`, so the four commands resolve as `/memex:spec`, `/memex:learn`, `/memex:sweep`, `/memex:review-spec`. The plugin source is `./plugins/memex` (relative path inside the marketplace repo).

2. **Memex skill — stops shipping slash commands as files; ships settings.json mutation instead.** `skills/memex/SKILL.md` Phase 4 loses the canonical-commands block and the per-agent symlink block. In their place: a legacy-file removal block (delete `.claude/commands/memex-<verb>.md` and `.agents/commands/memex-<verb>.md` for the four affected verbs) plus a settings.json merge block that adds `extraKnownMarketplaces["agent-skills"]` and `enabledPlugins["memex@agent-skills"] = true` when the target repo has a `.claude/` directory. Reference docs (`audit-checklist.md`, `validation.md`, `agents-md-template.md`) are updated to match, and a new reference (`claude-plugin-settings.md`) carries the marketplace coordinates and the jq merge recipe so the orchestrator stays small.

Order of edits matters: every commit must leave the skill runnable and internally consistent. The constitution amendment lands first (so the new paths are in-scope at commit time). Then the upstream marketplace files are created (so the skill, after it stops writing command files, has a real plugin to install). Then the skill rewrite. Then the new reference doc, audit-checklist, validation, and AGENTS.md template updates. Then dogfood (delete legacy, write this repo's settings.json, substitute AGENTS.md). Then verification on scratch test repos.

There is no test runner. "Tests" are `grep`/`jq` assertions on edited files, running `/memex` against scratch directories that simulate the spec's scenarios, and reading the resulting filesystem state. Behaviour verification lives in Phase 5 of the plan.

## Architecture

```
agent-skills/
├── .claude-plugin/
│   └── marketplace.json                       ← NEW (Task 2)
├── plugins/
│   └── memex/
│       ├── .claude-plugin/
│       │   └── plugin.json                    ← NEW (Task 3)
│       └── commands/
│           ├── spec.md                        ← NEW (Task 4)
│           ├── learn.md                       ← NEW (Task 4)
│           ├── sweep.md                       ← NEW (Task 4)
│           └── review-spec.md                 ← NEW (Task 4)
├── skills/
│   └── memex/
│       ├── SKILL.md                           ← Phase 4 rewrite (Task 6)
│       ├── scaffold/
│       │   └── commands/                      ← DELETED in full (Task 10)
│       └── references/
│           ├── claude-plugin-settings.md      ← NEW (Task 5)
│           ├── audit-checklist.md             ← Modified (Task 7)
│           ├── validation.md                  ← Check #11 rewritten (Task 8)
│           └── agents-md-template.md          ← Slash forms + cross-agent note (Task 9)
├── vault/
│   └── constitution.md                        ← Scope guardrails amended (Task 1)
├── .agents/
│   └── commands/                              ← DELETED in full (Task 11, dogfood)
├── .claude/
│   ├── commands/                              ← memex-* entries DELETED (Task 11)
│   └── settings.json                          ← NEW (Task 12, local-path source)
└── AGENTS.md                                  ← Slash forms + cross-agent note (Task 13)
```

Behaviour at install time (after the change):

```
target repo state                       result
──────────────────────────────────────────────────────────────────
fresh repo, .claude/ exists             vault scaffold + companion skills via .agents/skills/
                                        .claude/settings.json written with marketplace + plugin
                                        no .claude/commands/ or .agents/commands/

fresh repo, no .claude/                 vault scaffold + companion skills via .agents/skills/
                                        no .claude/ created (absence = user not on Claude here)
                                        no .claude/commands/ or .agents/commands/

pre-plugin install                      legacy .claude/commands/memex-{spec,learn,sweep,review-spec}.md removed
                                        legacy .agents/commands/memex-*.md removed
                                        .claude/settings.json written/merged with marketplace + plugin

settings.json already had other keys    extraKnownMarketplaces and enabledPlugins merged in,
                                        every other top-level key preserved (jq deep-merge)

second run (idempotent)                 no filesystem changes
```

## File Structure

| Path | Action | One-line responsibility |
|---|---|---|
| `vault/constitution.md` | Modify | Scope guardrails section adds `.claude-plugin/marketplace.json` and `plugins/<name>/` as in-scope (Task 1, AC17). |
| `.claude-plugin/marketplace.json` | Create | Declare marketplace `agent-skills` with one plugin entry `memex` sourced from `./plugins/memex` (Task 2, AC1). |
| `plugins/memex/.claude-plugin/plugin.json` | Create | Plugin manifest with `name = "memex"` and a non-empty description; no `version` field (Task 3, AC2). |
| `plugins/memex/commands/spec.md` | Create | Plugin command body for `/memex:spec` — copy from pre-migration `.agents/commands/memex-spec.md` with self-reference rewrites (Task 4, AC3, AC4). |
| `plugins/memex/commands/learn.md` | Create | Same as above for `/memex:learn` (Task 4). |
| `plugins/memex/commands/sweep.md` | Create | Same for `/memex:sweep` (Task 4). |
| `plugins/memex/commands/review-spec.md` | Create | Same for `/memex:review-spec` (Task 4). |
| `skills/memex/references/claude-plugin-settings.md` | Create | Canonical reference for marketplace coordinates, JSON shapes, jq merge recipe, Python fallback, and two trade-off-rejected alternatives from AD3 (Task 5, AC10). |
| `skills/memex/SKILL.md` | Modify | Replace Phase 4 commands block with: (a) legacy-file removal block; (b) `.claude/settings.json` merge block (only when `.claude/` exists). Reference the new `claude-plugin-settings.md` (Task 6, AC8, AC9). |
| `skills/memex/references/audit-checklist.md` | Modify | Remove `.agents/commands/memex-*.md` entries; delete "Per-agent command symlinks (Claude Code only)" subsection; add "Legacy paths to remove" subsection; add "Claude plugin settings present" check (Task 7, AC11, AC12). |
| `skills/memex/references/validation.md` | Modify | Redefine Check #11 to validate `.claude/settings.json` marketplace + plugin entries when `.claude/` exists, trivially PASS when absent (Task 8, AC13). |
| `skills/memex/references/agents-md-template.md` | Modify | Substitute every `/memex-<verb>` for the four affected verbs with `/memex:<verb>`; add cross-agent note line near top of `## Skills and slash commands` (Task 9, AC14). |
| `skills/memex/scaffold/commands/` | Delete | Directory + four `memex-*.md` files no longer shipped (Task 10, AC16). |
| `.agents/commands/` | Delete | Legacy canonical directory removed from this repo (Task 11, AC5, dogfood). |
| `.claude/commands/memex-spec.md` (+ `learn`, `sweep`, `review-spec`) | Delete | Legacy symlinks removed from this repo (Task 11, AC6, dogfood). |
| `.claude/settings.json` | Create | This repo's dogfood settings — local-path marketplace source per AD7 (Task 12, AC7). |
| `AGENTS.md` (repo root) | Modify | Same substitution as `agents-md-template.md` plus cross-agent note (Task 13, AC15). |

## Phase Ordering

**Phase 0 — Branch setup** (one task; git only).

0. Create feature branch.

**Phase 1 — Constitution amendment** (one task).

1. Amend `vault/constitution.md` § Scope guardrails. Commit. Subsequent paths created in Phase 2 are now in-scope.

**Phase 2 — Upstream marketplace surface** (three tasks, three commits).

2. Create `.claude-plugin/marketplace.json`.
3. Create `plugins/memex/.claude-plugin/plugin.json`.
4. Create the four plugin command files under `plugins/memex/commands/`, copying bodies from the existing `.agents/commands/memex-*.md` files and rewriting any `/memex-<verb>` self-references to `/memex:<verb>`.

**Phase 3 — Memex skill rewrite** (five tasks, five commits).

5. Create `skills/memex/references/claude-plugin-settings.md` (reference must exist before SKILL.md cites it).
6. Rewrite `skills/memex/SKILL.md` Phase 4 commands block (replace with legacy-removal + settings.json merge).
7. Update `skills/memex/references/audit-checklist.md` per AC11, AC12.
8. Update `skills/memex/references/validation.md` Check #11 per AC13.
9. Update `skills/memex/references/agents-md-template.md` per AC14.
10. Delete `skills/memex/scaffold/commands/` per AC16.

**Phase 4 — Dogfood this repo** (three tasks, three commits).

11. Delete `.agents/commands/` and `.claude/commands/memex-*.md` legacy files.
12. Create `.claude/settings.json` with local-path source per AD7.
13. Substitute `/memex-<verb>` → `/memex:<verb>` in this repo's root `AGENTS.md`; add cross-agent note.

**Phase 5 — Verification** (six tasks, no commits — confidence checks).

14. Run memex audit + Phase 5 in this repo (15/15 PASS, no diff) plus trust-prompt UX check (AC23).
15. Scratch test: fresh install with `.claude/` (AC18, AC19).
16. Scratch test: migration from pre-plugin install (AC20).
17. Scratch test: idempotent re-run (AC22).
17b. Scratch test: settings.json merge preserves unrelated keys (AC21).
18. Scratch test: install without `.claude/` (no settings.json created, Check #11 trivially PASS).

**Phase 6 — PR.**

19. Open PR with spec + implementation in the same diff. Mark spec `shipped` after merge.

Total: 20 tasks (0 through 19), 13 commits.

## Risks / Open Decisions

None remain. All forks were settled during brainstorming and recorded in the spec's `Architecture Decisions` section (decisions 1–7). Implementer should not relitigate:

- Plugin hosting is upstream — never copy plugin files into target repos.
- Legacy file handling is hard removal — no deprecation, no coexistence.
- Plugin install path is settings.json auto-config — not manual CLI commands, not bash-driven plugin invocation.
- Marketplace location is this repo — same root, not a separate repo, not a subdir.
- Phase 5 Check #11 redefinition keeps total = 15.
- AGENTS.md command wording is hard-coded Claude form with a one-line cross-agent note.
- Dogfood marketplace source for this repo is local path `.` (not `github:`).

If any of these become uncertain mid-implementation, stop and re-read the spec rather than guessing.
