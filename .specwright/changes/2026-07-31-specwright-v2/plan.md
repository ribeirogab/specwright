---
feature: specwright-v2
created: 2026-07-31
scope: complex
branch: feat/specwright-v2
worktree: null
delivery: null
---
# specwright v2 — Plan

**Change:** see the sibling `change.md` for the *why* and the `AC-N` contract.

## Architecture

Two structural moves, applied everywhere.

**One ladder, two wrappers.** Five step skills (`change`, `plan`, `implement`,
`pr`, `review`) each own one artifact or one gate, then stop and name the next
command. `ship` and `delivery` are wrappers that reuse those steps rather than
reimplementing them: `ship` runs the ladder without stopping, `delivery`
decomposes a large outcome into changes and dispatches one owner per change, each
running `ship`. `init` scaffolds the project. Every skill body remains the single
implementation of its behavior — the Claude command file stays a pure redirect.

**Nothing self-dispatches.** Skill descriptions become neutral (`Use when
explicitly invoked`), and the project instructions the scaffolder writes tell the
agent to *suggest* a command rather than to run the workflow. The same rule
retires the reflexive quality gate: verification belongs to `implement`/`ship` or
to an explicit request, never to every direct edit.

Two host adapters survive (Claude `/sw:*`, Codex `$sw:*`), two roles survive
(`sw-change-owner` for delivery dispatch, `sw-reviewer` for review), and each
change carries exactly two artifacts (`change.md`, `plan.md`).

The scaffolder shrinks from an updater to a scaffolder. `sw_update.py` classified
projects (`new`/`legacy-migratable`/`up-to-date`/`drifted`), rendered a
digest-protected managed block, and refused to apply a plan whose `plan_id` had
changed. `sw_init.py` replaces it with idempotent creation: create what is
missing, never touch what exists, report both. Detection is by path and by
heading, never by digest, so the maintainer owns every byte after the first run.

Role profiles are not project state in either host. Claude Code resolves them
from the installed plugin; Codex resolves them from `${CODEX_HOME:-~/.codex}/agents/`.
`sw_init.py --install-codex-roles` installs the Codex pair once per machine, as a
separate explicitly requested mode — scaffolding a repository never writes
outside it.

The validator narrows to one question — *can a stranger implement this?* — and is
renamed `validate-change.sh` for the pair it now checks. Schema-2 topology
(`Delegable`, `Integration`, `Depends on`, ownership disjointness) existed to feed
task-worker waves and goes with them; the surviving task metadata is `AC:`,
`Files:`, and `Validation:`.

## File Structure

```text
plugins/sw/
├── agents/                     change-owner.md, reviewer.md
├── commands/                   8 redirects
├── skills/                     change, delivery, implement, init, plan, pr, review, ship
├── templates/
│   ├── change.md, plan.md, delivery.md
│   └── codex-agents/           sw-change-owner.toml, sw-reviewer.toml
├── scripts/
│   ├── sw_init.py              idempotent project scaffolder
│   ├── validate-change.sh      handoff-readiness gate
│   ├── quick_validate.py       (unchanged, vendored)
│   ├── package_skill.py        (unchanged, vendored)
│   └── fixtures/               ready + 5 bad fixtures
└── references/                 validation.md, vault-files.md
tests/
├── install/run.sh              package + init groups
├── validate-change/run.sh      validator cases
├── release/run.sh              host ingestion smoke
└── skills/test_validation.py   vendored-validator unit tests
```

Deleted: `.opencode/`, `plugins/sw/templates/opencode-*/`,
`plugins/sw/scripts/sw_update.py`, `plugins/sw/scripts/validate_task_topology.py`,
`plugins/sw/scripts/validate-spec.sh`, `plugins/sw/agents/task-worker.md`,
`plugins/sw/agents/spec-document-reviewer.md`, `plugins/sw/references/audit-checklist.md`,
`tests/update/`, `tests/task-topology/`, `tests/worktrees/`, `tests/validate-spec/`,
and the `brainstorm`, `spec`, `run`, `update`, `review-spec` skills and commands.

## Phase Ordering

1. Artifacts and mechanics (T1–T3) — templates, validator, scaffolder.
2. Behavior (T4–T6) — skills, roles, commands.
3. Removal and consistency (T7–T9) — OpenCode, tests, docs.

## Constraints

- `claude plugin validate --strict plugins/sw` must pass at every commit that
  touches the package surface.
- Historical `.specwright/` records are immutable; only this change's folder is
  written.
- Committed artifacts are English; no AI attribution anywhere.

## Tasks

### T1: Templates — change.md, plan.md, delivery.md

**AC:** AC-4
**Files:**
- Create: `plugins/sw/templates/plan.md`
- Modify: `plugins/sw/templates/change.md`, `plugins/sw/templates/delivery.md`
- Delete: `plugins/sw/templates/spec.md`, `plugins/sw/templates/tasks.md`, `plugins/sw/templates/board.md`
**Validation:** `ls plugins/sw/templates`

- [x] Fuse `spec.md` + `tasks.md` into `plan.md` (architecture above, tasks below)
- [x] Add the `## Decisions and discoveries` section to `change.md`
- [x] Fold the board's change table, dispatch log, and blockers into `delivery.md`
- [x] Delete the three superseded templates

### T2: Handoff-readiness validator

**AC:** AC-5
**Files:**
- Create: `plugins/sw/scripts/validate-change.sh`, `plugins/sw/scripts/fixtures/*`
- Delete: `plugins/sw/scripts/validate-spec.sh`, `plugins/sw/scripts/validate_task_topology.py`
**Validation:** `bash tests/validate-change/run.sh`

- [x] Write the six checks (change frontmatter+status, plan frontmatter+branch, placeholders, vague verbs, AC traceability, task metadata)
- [x] Rebuild the fixtures as `change.md` + `plan.md` pairs
- [x] Delete the schema-2 validator and its fixtures

### T3: Idempotent scaffolder

**AC:** AC-6, AC-7, AC-12, AC-13
**Files:**
- Create: `plugins/sw/scripts/sw_init.py`
- Delete: `plugins/sw/scripts/sw_update.py`
**Validation:** `bash tests/install/run.sh init`

- [x] Implement create-if-absent for vault, AGENTS section, symlink, ignore lines
- [x] Report every path as `created` or `present`; write nothing on a second run
- [x] Keep role profiles out of the repository; install them machine-wide with `--install-codex-roles`
- [x] Delete the updater

### T4: The eight skills

**AC:** AC-1, AC-8, AC-9, AC-11
**Files:**
- Create: `plugins/sw/skills/{change,implement,ship,delivery}/SKILL.md`
- Modify: `plugins/sw/skills/{init,plan,pr,review}/SKILL.md`
- Delete: `plugins/sw/skills/{brainstorm,spec,run,update,review-spec}/`
**Validation:** `python3 plugins/sw/scripts/quick_validate.py plugins/sw/skills/change`

- [x] Write the five step skills, each ending by naming its successor command
- [x] Write `ship` and `delivery` as wrappers over those steps
- [x] Neutralize every description; remove `You MUST` and the auto-trigger language

### T5: Two roles per host

**AC:** AC-3
**Files:**
- Modify: `plugins/sw/agents/change-owner.md`, `plugins/sw/agents/reviewer.md`, `plugins/sw/templates/codex-agents/sw-change-owner.toml`, `plugins/sw/templates/codex-agents/sw-reviewer.toml`
- Delete: `plugins/sw/agents/task-worker.md`, `plugins/sw/agents/spec-document-reviewer.md`, and their Codex profiles
**Validation:** `ls plugins/sw/agents plugins/sw/templates/codex-agents`

- [x] Rewrite `change-owner` to run `ship` on one change, no waves or workers
- [x] Rewrite `reviewer` to cover the three dimensions in one pass
- [x] Delete the two retired roles from both hosts

### T6: Command redirects

**AC:** AC-1
**Files:**
- Create: `plugins/sw/commands/{change,implement,ship,delivery}.md`
- Delete: `plugins/sw/commands/{brainstorm,spec,run,update,review-spec}.md`
**Validation:** `claude plugin validate --strict plugins/sw`

- [x] One pure redirect per skill, description matching the skill's purpose

### T7: Remove OpenCode and rewrite the references

**AC:** AC-2
**Files:**
- Delete: `.opencode/`, `plugins/sw/templates/opencode-agents/`, `plugins/sw/templates/opencode-commands/`, `plugins/sw/references/audit-checklist.md`, `plugins/sw/references/agents-md-template.md`
- Modify: `plugins/sw/references/validation.md`, `plugins/sw/references/vault-files.md`, `.specwright/conventions/skill-validation-requirements.md`
**Validation:** `grep -ril opencode --exclude-dir=.git .` outside the historical vault

- [x] Delete every OpenCode file and reference
- [x] Rewrite the references for the two-host, two-artifact shape

### T8: Test suite

**AC:** AC-10
**Files:**
- Modify: `tests/install/run.sh`, `tests/release/run.sh`
- Create: `tests/validate-change/run.sh`
- Delete: `tests/update/`, `tests/task-topology/`, `tests/worktrees/`, `tests/validate-spec/`
**Validation:** `bash tests/install/run.sh && bash tests/validate-change/run.sh && bash tests/release/run.sh`

- [x] Rewrite the package group for eight skills and two roles
- [x] Rewrite the init group against `sw_init.py`, including the idempotency assertion
- [x] Delete the suites whose subjects no longer exist

### T9: Documentation

**AC:** AC-2, AC-10
**Files:**
- Modify: `README.md`, `AGENTS.md`, `CONTRIBUTING.md`, `.github/PULL_REQUEST_TEMPLATE.md`, `.github/ISSUE_TEMPLATE/*`, `.github/workflows/release-smoke.yml`, `plugins/sw/.claude-plugin/plugin.json`, `plugins/sw/.codex-plugin/plugin.json`, `.claude-plugin/marketplace.json`, `.agents/plugins/marketplace.json`
**Validation:** `bash tests/install/run.sh package`

- [x] Rewrite the README around the ladder, the two wrappers, and the handoff
- [x] Replace this repo's managed block with a plain `## specwright` section
- [x] Bump both manifests to the release date and update every description
