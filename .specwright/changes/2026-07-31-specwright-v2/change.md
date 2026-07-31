---
feature: specwright-v2
created: 2026-07-31
status: in-progress
shipped: null
delivery: null
---
# specwright v2 — Change

> The ticket: the approved *why* plus the acceptance criteria and the change's status. The technical *how* lives in the sibling `plan.md`.

## Purpose

Turn specwright from a pipeline the model executes end to end into a ladder the
maintainer climbs one command at a time. Each step produces one artifact, stops,
and names the next command. The maintainer chooses when to climb, with which
model, in which session — including handing a finished plan to an agent that has
no conversation context at all.

## Motivation

The v1 workflow auto-triggered (`You MUST use this before any creative work`) and
ran ticket-to-shipped in a single `plan` invocation of 315 lines. Three
consequences: the maintainer never typed a `/sw:*` command because the model
dispatched the flow itself; no checkpoint existed at which to switch models
between thinking work and executing work; and every change — however small —
carried multi-agent orchestration machinery (task waves, per-task worktrees,
cherry-pick integration, schema-2 topology validation) built for a scale that a
solo maintainer never reaches.

The machinery that does earn its keep is one level up: a large outcome
decomposed into changes, each conducted in parallel by its own owner. That
survives. The per-task parallelism inside a single change does not.

## Non-Goals

- Does not change the review standard, the blocker calibration, or the review
  output templates.
- Does not remove runtime verification, acceptance-criteria traceability, or the
  English-only rule for committed artifacts.
- Does not migrate historical `.specwright/changes/` or `.specwright/deliveries/`
  artifacts; shipped records keep their ship-time shape.
- Does not add a v1-to-v2 project migration path; `sw:init` is idempotent and
  re-running it is the upgrade.

## Acceptance Criteria

- [ ] **AC-1** `find plugins/sw/skills -mindepth 1 -maxdepth 1 -type d` lists exactly eight names: `change`, `delivery`, `implement`, `init`, `plan`, `pr`, `review`, `ship`. `plugins/sw/commands/` holds exactly the eight homonymous `.md` redirects.
- [ ] **AC-2** `grep -ril opencode` over tracked files outside `.specwright/changes/` and `.specwright/deliveries/` returns no match, and `.opencode/` does not exist in the repository.
- [ ] **AC-3** `plugins/sw/agents/` holds exactly `change-owner.md` and `reviewer.md`; `plugins/sw/templates/codex-agents/` holds exactly `sw-change-owner.toml` and `sw-reviewer.toml`.
- [ ] **AC-4** `plugins/sw/templates/` holds exactly `change.md`, `plan.md`, `delivery.md`, and the `codex-agents/` directory. `spec.md`, `tasks.md`, `board.md`, `opencode-agents/`, and `opencode-commands/` are absent.
- [ ] **AC-5** `plugins/sw/scripts/validate-change.sh` exits 0 printing `PASS` on the `ready` fixture, and exits non-zero naming the defect on each of the `bad-placeholder`, `bad-unref-ac`, `bad-vague-verb`, `bad-task-metadata`, and `missing-status` fixtures. `validate-spec.sh`, `validate_task_topology.py`, and `sw_update.py` are absent.
- [ ] **AC-6** `python3 plugins/sw/scripts/sw_init.py --project <empty-git-repo> --mode shared` creates the vault, the `## specwright` section in `AGENTS.md`, the `CLAUDE.md -> AGENTS.md` relative symlink, both `.codex/agents/sw-*.toml` profiles, and the `.specwright/worktrees/` ignore line. A second run reports every path as `present`, performs zero writes, and leaves the directory tree byte-identical.
- [ ] **AC-7** With `--mode local`, `sw_init.py` writes `AGENTS.override.md`, the `CLAUDE.local.md -> AGENTS.override.md` relative symlink, and exactly five ignore lines: `.specwright/worktrees/`, `.specwright/`, `AGENTS.override.md`, `CLAUDE.local.md`, `.codex/agents/sw-*.toml`. A pre-existing `AGENTS.md` and an unrelated `.codex/project.toml` remain byte-identical.
- [ ] **AC-8** No `SKILL.md` frontmatter description contains `You MUST`, and the text `sw:managed` appears in no tracked file outside `.specwright/changes/` and `.specwright/deliveries/`.
- [ ] **AC-9** Every `SKILL.md` other than `review`, `pr`, and `delivery` names its successor command: `change` names `/sw:plan`, `plan` names `/sw:implement`, `implement` names `/sw:pr`, `pr` names `/sw:review`, `init` names `/sw:change`.
- [ ] **AC-10** `bash tests/install/run.sh`, `bash tests/validate-change/run.sh`, `bash tests/release/run.sh`, and `python3 tests/skills/test_validation.py` each exit 0. `claude plugin validate --strict plugins/sw` exits 0.
- [ ] **AC-11** `python3 plugins/sw/scripts/quick_validate.py <dir>` prints `Skill is valid!` and exits 0 for all eight skill directories.

Tick each `[x]` when verified.

## Decisions and discoveries

Decisions taken while implementing, and non-obvious facts found on the way.

- **[decision]** `init` keeps a deterministic Python scaffolder (`sw_init.py`) instead of becoming pure prose instructions. The ceremony that died is the *updater* — `plan_id` confirmation, managed-block digests, drift classification, symlink-unsupported refusal. Mechanical, idempotent file creation stays because it is what makes AC-6 and AC-7 verifiable at all; prose instructions cannot be tested.
- **[decision]** The `## specwright` section in the canonical AGENTS file is written once and never touched again. `init` detects it by heading, not by digest, so the maintainer can rewrite the text freely without any tool reporting drift.
- **[decision]** Review collapses from three subagent dispatches to one. The three questions (rubric+conventions, change-conformance, documentation-consistency) survive as three required dimensions of a single reviewer pass — the lanes existed to parallelize, and one reviewer covering a checklist costs less than three dispatches plus a merge.
- **[decision]** `ship` and `delivery` do not duplicate the ladder's instructions. Each names the step skills in order and states only what differs — autonomy for `ship`, decomposition and parallel dispatch for `delivery`. One implementation of every step, as in v1.
- **[decision]** The quality gate moved out of every edit and into the ladder. The AGENTS section tells the agent to run tests and lint at `implement`/`ship` or on request, and to stop after a direct edit reporting what was not verified — so a trivial change no longer drags a full gate behind it.
