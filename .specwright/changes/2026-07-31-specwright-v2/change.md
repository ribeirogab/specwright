---
feature: specwright-v2
created: 2026-07-31
status: shipped
shipped: 2026-07-31
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

- [x] **AC-1** `find plugins/sw/skills -mindepth 1 -maxdepth 1 -type d` lists exactly eight names: `change`, `delivery`, `implement`, `init`, `plan`, `pr`, `review`, `ship`. `plugins/sw/commands/` holds exactly the eight homonymous `.md` redirects.
- [x] **AC-2** `.opencode/` does not exist, and `grep -ril opencode` over tracked files outside `.specwright/changes/` and `.specwright/deliveries/` matches only `tests/install/run.sh`, where every match is an `assert_absent` guard proving the removal.
- [x] **AC-3** `plugins/sw/agents/` holds exactly `change-owner.md` and `reviewer.md`; `plugins/sw/templates/codex-agents/` holds exactly `sw-change-owner.toml` and `sw-reviewer.toml`.
- [x] **AC-4** `plugins/sw/templates/` holds exactly `change.md`, `plan.md`, `delivery.md`, and the `codex-agents/` directory. `spec.md`, `tasks.md`, `board.md`, `opencode-agents/`, and `opencode-commands/` are absent.
- [x] **AC-5** `plugins/sw/scripts/validate-change.sh` exits 0 printing `PASS` on the `ready` fixture, and exits non-zero naming the defect on each of the `bad-placeholder`, `bad-unref-ac`, `bad-vague-verb`, `bad-task-metadata`, and `missing-status` fixtures. `validate-spec.sh`, `validate_task_topology.py`, and `sw_update.py` are absent.
- [x] **AC-6** `python3 plugins/sw/scripts/sw_init.py --project <empty-git-repo> --mode shared` creates the vault, the `## specwright` section in `AGENTS.md`, the `CLAUDE.md -> AGENTS.md` relative symlink, and the `.specwright/worktrees/` ignore line — six paths, and no `.codex/` path at all. A second run reports every path as `present`, performs zero writes, and leaves the directory tree byte-identical.
- [x] **AC-7** With `--mode local`, `sw_init.py` writes `AGENTS.override.md`, the `CLAUDE.local.md -> AGENTS.override.md` relative symlink, and exactly four ignore lines: `.specwright/worktrees/`, `.specwright/`, `AGENTS.override.md`, `CLAUDE.local.md`. A pre-existing `AGENTS.md` and an unrelated `.codex/project.toml` remain byte-identical.
- [x] **AC-8** No `SKILL.md` frontmatter description contains `You MUST`, and the text `sw:managed` appears in no tracked file outside `.specwright/changes/` and `.specwright/deliveries/`.
- [x] **AC-9** Each ladder skill names its successor command in its own `SKILL.md`: `init` names `/sw:change`, `change` names `/sw:plan`, `plan` names `/sw:implement`, `implement` names `/sw:pr`, and `pr` names `/sw:review`.
- [x] **AC-10** `bash tests/install/run.sh`, `bash tests/validate-change/run.sh`, `bash tests/release/run.sh`, and `python3 tests/skills/test_validation.py` each exit 0. `claude plugin validate --strict plugins/sw` exits 0.
- [x] **AC-12** No specwright command writes a role profile into a repository: after `sw_init.py --project <repo> --mode shared|local`, `<repo>/.codex` does not exist. Every tracked mention of `.codex/agents` outside `.specwright/changes/` and `.specwright/deliveries/` asserts that absence — `tests/install/run.sh` via `assert_absent` and `plugins/sw/references/validation.md` via `test ! -e`.
- [x] **AC-13** `sw_init.py --install-codex-roles --codex-home <dir>` creates `sw-change-owner.toml` and `sw-reviewer.toml` under `<dir>/agents/`, byte-identical to the bundled templates. A second run reports both as `present` and leaves the tree byte-identical. With `--codex-home` omitted, the destination follows `CODEX_HOME`.
- [x] **AC-11** The repository's canonical skill check — `UV_CACHE_DIR=/tmp/specwright-uv-cache uv run --offline --with PyYAML python3 plugins/sw/scripts/quick_validate.py <dir>` — prints `Skill is valid!` for all eight skill directories.

Tick each `[x]` when verified.

## Decisions and discoveries

Decisions taken while implementing, and non-obvious facts found on the way.

- **[decision]** `init` keeps a deterministic Python scaffolder (`sw_init.py`) instead of becoming pure prose instructions. The ceremony that died is the *updater* — `plan_id` confirmation, managed-block digests, drift classification, symlink-unsupported refusal. Mechanical, idempotent file creation stays because it is what makes AC-6 and AC-7 verifiable at all; prose instructions cannot be tested.
- **[decision]** The `## specwright` section in the canonical AGENTS file is written once and never touched again. `init` detects it by heading, not by digest, so the maintainer can rewrite the text freely without any tool reporting drift.
- **[decision]** Review collapses from three subagent dispatches to one. The three questions (rubric+conventions, change-conformance, documentation-consistency) survive as three required dimensions of a single reviewer pass — the lanes existed to parallelize, and one reviewer covering a checklist costs less than three dispatches plus a merge.
- **[decision]** `ship` and `delivery` do not duplicate the ladder's instructions. Each names the step skills in order and states only what differs — autonomy for `ship`, decomposition and parallel dispatch for `delivery`. One implementation of every step, as in v1.
- **[decision]** AC-2 and AC-12 were both amended during verification to exempt the checks that prove a removal. A guard asserting a path is gone must name that path, so a literal "this string appears nowhere" criterion can never pass while the regression coverage exists. Both now require every surviving mention to *be* an absence assertion, which is what each criterion always meant. Deleting the guards to satisfy the literal wording was the alternative, and it would have traded real coverage — an `assert_absent` on a directory catches a re-added adapter tree that the depth-1 inventory assertions would miss — for a cosmetic grep result.
- **[decision]** `sw:init` stopped writing `.codex/agents/` and the profiles moved to a separate machine-wide mode, `sw_init.py --install-codex-roles`. Their content never varied per repository, so writing them per repository was noise; the only reason it happened was the belief that Codex read them solely from the project, which the A/B runs disproved. The install stays a distinct, explicitly requested mode rather than a step of `init`, because it writes outside the project — scaffolding a repository must never touch the maintainer's machine as a side effect.
- **[decision]** Neither role pins a model or reasoning effort; both inherit the session's. A pin would override the maintainer's own `/model` choice at exactly the moment they made it deliberately — the same "the system decides for you" the ladder removes everywhere else. `sandbox_mode` stays pinned in the Codex profiles because it is a permission boundary, not a preference: the reviewer must not be able to write, whatever model runs it. Verified that Codex accepts a profile with no `model` key before removing it.
- **[decision]** The quality gate moved out of every edit and into the ladder. The AGENTS section tells the agent to run tests and lint at `implement`/`ship` or on request, and to stop after a direct edit reporting what was not verified — so a trivial change no longer drags a full gate behind it.
- **[decision]** No `references/agents-section.md` was written, though the plan listed one. The section text lives in `sw_init.py` as the constant the scaffolder writes; a reference file repeating it would be a second copy to keep in sync — exactly the drift hazard this change removes elsewhere. `references/` keeps `validation.md` and `vault-files.md`.
- **[discovery]** The repository's own tracked `.codex/agents/` profiles are part of the package surface, not just consumer output. Retiring two roles from the templates left this repo shipping installed profiles for roles that no longer exist — a documentation-consistency review caught it, and `tests/install/run.sh` now asserts the dogfooded profiles match the template inventory byte-for-byte.
- **[discovery]** Deleting the `brainstorm` skill also deleted vendored superpowers-derived UI code, which made the `NOTICE.md` attribution describe files that are no longer present. Any change that removes a skill has to be checked against `NOTICE.md`, `SECURITY.md`, and `.gitignore` — those three carry claims about the codebase that no test asserts.
- **[discovery]** Codex resolves subagent roles from **`${CODEX_HOME:-~/.codex}/agents/`**, not only from the project. Four A/B runs of `spawn_agent` settled it: profiles in the project work, profiles in Codex's home work identically with no `.codex/` in the repository at all, a plugin declaring `"agents": "./codex-agents/"` registers nothing, and with neither the `agent_type` parameter does not exist. So role profiles are machine-wide state for both hosts — Claude Code from the installed plugin, Codex from its home — and nothing role-related belongs in a repository.
- **[discovery]** Codex gates subagents behind `multi_agent_v2`, which `codex features list` reports as `stable` but **disabled** by default. In a default session `spawn_agent` is not offered at all, so the installed role profiles are inert and `$sw:delivery` / `$sw:review` take their inline degradation path. Enabling it is `codex features enable multi_agent_v2`.
- **[discovery]** `tests/release/run.sh` gates its native Codex ingestion behind `CI_EPHEMERAL_RUNNER=1` because `codex plugin marketplace add` mutates host state. The suite exits 0 locally by skipping that section, so a green local run is **not** evidence that Codex ingests the package; only the CI job proves it. The new `portable-checks` job covers everything that does not need a host CLI.
