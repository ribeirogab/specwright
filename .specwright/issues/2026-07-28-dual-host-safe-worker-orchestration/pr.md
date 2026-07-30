## Summary

Adds first-class Claude Code and Codex packaging around one shared nine-skill implementation, a confirmed-plan project migrator, and owner-controlled integration for isolated task workers.

- Adds native manifests and local marketplaces for both hosts, with the Codex manifest as the calendar-version source.
- Makes `AGENTS.md` canonical, keeps Claude entry points as relative symlinks, and installs four project-scoped Codex role profiles.
- Adds deterministic `sw:update` planning and guarded application for new, current, legacy, and drifted projects.
- Adds schema-2 task topology validation and an issue-owner protocol for dependency waves, isolated worktrees, reviewed commit SHAs, and cherry-pick integration.
- Dogfoods the dual-host contract in this repository.

## Issue

- [issue](https://github.com/ribeirogab/specwright/blob/feat/dual-host-safe-worker-orchestration/.specwright/issues/2026-07-28-dual-host-safe-worker-orchestration/issue.md)
- [spec](https://github.com/ribeirogab/specwright/blob/feat/dual-host-safe-worker-orchestration/.specwright/issues/2026-07-28-dual-host-safe-worker-orchestration/spec.md)
- [tasks](https://github.com/ribeirogab/specwright/blob/feat/dual-host-safe-worker-orchestration/.specwright/issues/2026-07-28-dual-host-safe-worker-orchestration/tasks.md)

## Test plan

- [x] `bash tests/install/run.sh`
- [x] `bash tests/release/run.sh`
- [x] `CI_EPHEMERAL_RUNNER=1 bash tests/release/run.sh`
- [x] `python3 tests/update/test_plan.py` — 28 tests
- [x] `python3 tests/task-topology/test_parser.py` — 11 tests
- [x] `python3 tests/worktrees/test_local_copy.py`
- [x] `bash plugins/sw/scripts/validate-spec.sh .specwright/issues/2026-07-28-dual-host-safe-worker-orchestration`
- [x] `quick_validate.py` and `package_skill.py` for all nine skills in an offline PyYAML environment
- [x] `claude plugin validate --strict plugins/sw`
- [x] Codex profile models checked against `codex debug models`
- [x] `bash -n`, `shellcheck`, `actionlint`, JSON parsing, TOML parsing, symlink checks, updater idempotence, and `git diff --check`

## Runtime verification

- **AC-1 — verified:** strict Claude validation exited 0; the ephemeral Codex smoke installed the local marketplace and package and discovered the expected inventory through native Codex commands.
- **AC-2 — verified:** the install suite found exactly nine shared skills and nine homonymous thin Claude redirects; the native Codex resolver returned the same inventory.
- **AC-3 — verified:** manifest assertions accepted `2026.7.28` and `./skills/`; updater tests rejected zero-padded, malformed, and impossible calendar versions.
- **AC-4 — verified:** planner tests observed all four states, stable JSON and plan identities, read-only planning, identity mismatch rejection, and manifest-derived versions. Repository search found no remote fetch or `main` lookup in the updater.
- **AC-5 — verified:** shared and local legacy fixtures migrated to canonical AGENTS files, relative Claude symlinks, and four matching profiles; drift, edited profiles, identity mismatch, and unsupported symlinks exited non-zero without preflight writes.
- **AC-6 — verified:** shared and local initialization fixtures produced the correct canonical files, symlinks, profiles, and exact ignore rules while preserving unrelated `.codex/project.toml`.
- **AC-7 — verified:** `codex debug models` exposed `gpt-5.6-sol` and `gpt-5.6-terra`; host-role assertions found the same four `sw-*` identities, required models and reasoning efforts, two read-only reviewers, and two workspace-write implementers.
- **AC-8 — verified:** `test_local_copy.py` created a real temporary Git worktree and observed the local AGENTS file, relative Claude symlink, issue vault, and all profiles as present and ignored.
- **AC-9 — verified:** the schema-2 parser and sixth validator check accepted valid and shipped-legacy fixtures and rejected missing dependencies, cycles, same-wave file collisions, and active legacy tasks.
- **AC-10 — verified:** protocol assertions and the installed owner/worker profiles require exact issue-HEAD bases, repository-contained worktrees, declared-file diffs, ordered SHAs, owner-only cherry-picks, integrated wave validation, and replanning for semantic conflicts or scope changes.
- **AC-11 — verified:** installation and release suites exercised both positive host paths and negative missing-manifest, missing-skill, and malformed-skill packages through native host validators.
- **AC-12 — verified:** live documentation, templates, audit references, GitHub contribution templates, and dogfooded `AGENTS.md` describe both host surfaces, confirmed updates, symlinks, worker waves, cherry-pick integration, and host permission authority.

## Review

- Rubric and conventions lane: `lgtm. previous blockers resolved.`
- Issue-conformance lane: `lgtm. previous blockers resolved.`
- Documentation-consistency lane: `lgtm. previous blockers resolved.`

## Checklist

- [x] Branch name is descriptive and not `main`.
- [x] `NOTICE.md` records the approved local validator compatibility change.
- [x] Commit messages follow Conventional Commits style.
- [x] No attribution footers appear in commits or this description.
- [x] The pull request remains draft for maintainer review.
