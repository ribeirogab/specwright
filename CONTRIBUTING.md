# Contributing

Thanks for contributing to `specwright`. The maintenance model is solo,
best-effort, and has no SLA; a polite follow-up after a couple of weeks is welcome.

## Scope

In scope:

- shared workflow skills under `plugins/sw/skills/`;
- thin Claude redirects under `plugins/sw/commands/`;
- Claude and Codex manifests and marketplaces;
- role manifests/templates, project templates, updater, validators, tests, and
  documentation; and
- dogfooded issue artifacts when they are part of the proposed workflow change.

Unrelated skills, broad governance proposals, personal host settings, generated
evaluation workspaces, and edits to unrelated historical `.specwright/` artifacts
are out of scope.

## Development rules

1. File an issue before a non-trivial change.
2. Implement workflow behavior once in
   `plugins/sw/skills/<name>/SKILL.md`. A Claude command is a pure redirect to
   that skill; Codex discovers the same directory from its manifest.
3. Keep host adapters minimal and preserve the same nine-entry inventory.
4. Keep project-managed instructions host-neutral. `AGENTS*.md` is canonical;
   `CLAUDE*.md` is a relative symlink.
5. Treat `.codex/agents/sw-*.toml` as generated project profiles. Change their
   source templates and migration tests together.
6. Never make update logic fetch a remote branch. The installed Codex manifest is
   the version source.
7. Never weaken exact-plan confirmation, digest checking, atomic preflight, or
   the symlink requirement to make a migration pass.

## Skill and package validation

Run the authoring checks for every modified skill:

```bash
python3 plugins/sw/scripts/quick_validate.py plugins/sw/skills/<skill>
python3 plugins/sw/scripts/package_skill.py plugins/sw/skills/<skill> /tmp
```

Then validate both package structures and the complete install/update matrix:

```bash
claude plugin validate --strict plugins/sw
bash tests/install/run.sh package init
bash tests/install/run.sh update worktree
python3 tests/update/test_plan.py
python3 tests/worktrees/test_local_copy.py
python3 tests/task-topology/test_parser.py
```

`tests/install/run.sh` covers both manifests and marketplaces, exact skill and
redirect inventories, shared/local initialization, symlinks, ignore rules,
profile generation, migrations, drift, plan purity, and worktree transport.

Changes to `tasks.md`, planning, or worker orchestration must keep schema 2
coherent across the template, parser, mechanical validator, plan skill, owner
role, and worker role. The validator must continue to reject duplicate IDs,
missing/unknown/cyclic dependencies, missing isolated metadata, and ownership
collisions within a dependency wave.

## Dual-host release smoke test

The local release gate validates the nine-skill inventory and Claude's native
strict package parser without modifying Codex state:

```bash
bash tests/release/run.sh
```

The Codex ingestion test changes marketplace/plugin state, so run it only in a
disposable environment:

```bash
CI_EPHEMERAL_RUNNER=1 bash tests/release/run.sh
```

CI installs the pinned host CLIs, adds a temporary Codex marketplace, installs
`sw@specwright`, checks the installed nine-skill inventory, and exercises negative
fixtures for missing Claude/Codex manifests and a missing required skill. A host
that cannot recognize the package blocks release.

## Updater fixtures

Updater tests must prove both safety and identity:

- `--plan` performs no writes;
- the same observed state produces the same ordered operations and `plan_id`;
- `--apply` requires the displayed `--expect-plan`;
- changes after planning invalidate that identity;
- project text outside the managed block and unrelated `.codex` files survive;
- recognized Claude-only legacy shapes migrate;
- unrecognized or edited managed shapes are `drifted` and are not overwritten;
- profiles byte-match the installed templates; and
- unavailable symlinks fail before managed writes, with no copy fallback.

Do not add a fixture that teaches the updater to guess ownership, dependencies, or
task topology for an active legacy issue. Replanning is the required repair.

## Owner/worker changes

The issue owner is the only integrator. A worker branch must start at the recorded
wave base, own only declared files, and return ordered commits and validation
evidence. Any protocol change must test:

- base ancestry and touched-path checks before integration;
- owner review before cherry-pick;
- rejection of semantic conflict, ownership overlap, and scope change;
- integrated validation between waves; and
- retention of task worktrees.

## Pull request checklist

- [ ] The branch is descriptive and is not `main`.
- [ ] Modified skills pass `quick_validate.py` and `package_skill.py`.
- [ ] Claude strict validation and the relevant install/update tests pass.
- [ ] The dual-host release smoke test passes when package surfaces change.
- [ ] `NOTICE.md` is updated when vendored content changes.
- [ ] Project artifacts and documentation agree with the implemented contract.
- [ ] Commit messages follow Conventional Commits.
- [ ] Commits and PR text contain no AI-attribution footers.

## Reporting bugs and security issues

Public bugs belong in the issue tracker with the host/version, reproduction, and
expected versus actual result. Vulnerabilities must be reported privately using
[`SECURITY.md`](SECURITY.md).

Participation is governed by the [Contributor Covenant 2.1](CODE_OF_CONDUCT.md).
