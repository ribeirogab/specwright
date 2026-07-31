# Contributing

Thanks for contributing to `specwright`. The maintenance model is solo,
best-effort, and has no SLA; a polite follow-up after a couple of weeks is welcome.

## Scope

In scope:

- shared workflow skills under `plugins/sw/skills/`;
- thin Claude redirects under `plugins/sw/commands/`;
- Claude and Codex manifests and marketplaces;
- role manifests and templates, project templates, the scaffolder, the
  validators, tests, and documentation; and
- dogfooded change artifacts when they are part of the proposed workflow change.

Unrelated skills, broad governance proposals, personal host settings, generated
evaluation workspaces, and edits to unrelated historical `.specwright/` artifacts
are out of scope.

## Development rules

1. File a GitHub issue before a non-trivial change.
2. Implement workflow behavior once in `plugins/sw/skills/<name>/SKILL.md`. A
   Claude command is a pure redirect to that skill; Codex discovers the same
   directory from its manifest.
3. Keep host adapters minimal and preserve the eight-entry inventory.
4. Keep project-managed instructions host-neutral. `AGENTS*.md` is canonical;
   `CLAUDE*.md` is a relative symlink, never a copy.
5. Role profiles are machine-wide, never project files. `sw:init` must not write
   one into a repository; the Codex install is its own explicit mode.
6. A skill description states **when the skill is invoked**. It never instructs
   the model to run the workflow on its own initiative.
7. Each ladder step stops and names its successor. A step that runs the next one
   silently defeats the design.
8. `plan.md` must stay executable by an agent with no conversation context. Any
   change to planning keeps that property and the validator that enforces it.

## Skill and package validation

Run the authoring checks for every modified skill:

```bash
UV_CACHE_DIR=/tmp/specwright-uv-cache uv run --offline --with PyYAML \
  python3 plugins/sw/scripts/quick_validate.py plugins/sw/skills/<skill>
UV_CACHE_DIR=/tmp/specwright-uv-cache uv run --offline --with PyYAML \
  python3 plugins/sw/scripts/package_skill.py plugins/sw/skills/<skill> /tmp
UV_CACHE_DIR=/tmp/specwright-uv-cache uv run --offline --with PyYAML \
  python3 tests/skills/test_validation.py
bash tests/validate-change/run.sh
```

Then validate both package structures and the initialization matrix:

```bash
claude plugin validate --strict plugins/sw
bash tests/install/run.sh
```

`tests/install/run.sh` covers both manifests and marketplaces, the exact skill
and redirect inventories, the ladder's successor links, the two role identities
with their sandboxes, shared and local initialization, symlinks, ignore rules,
the machine-wide Codex role install, scaffolder idempotency, and the conflict
path that writes nothing.

Changes to the change or plan artifacts must keep `templates/`,
`scripts/validate-change.sh`, its fixtures, the `plan` skill, and
`references/vault-files.md` coherent. The validator must continue to reject
surviving placeholders, vague acceptance-criteria verbs, an `AC-N` claimed by no
task, a task naming an undefined `AC-N`, a task with no owned path or validation
command, and a plan with no tasks at all.

## Host release smoke test

The local release gate validates the eight-skill inventory and Claude's native
strict package parser without modifying Codex state:

```bash
bash tests/release/run.sh
```

The Codex ingestion test changes marketplace and plugin state, so run it only in
a disposable environment:

```bash
CI_EPHEMERAL_RUNNER=1 bash tests/release/run.sh
```

CI installs the pinned host CLIs, adds a temporary Codex marketplace, installs
`sw@specwright`, checks the installed eight-skill inventory and the profile
models against the native Codex catalog, and exercises negative fixtures for
missing Claude and Codex manifests and for a missing or malformed required skill.
A host that cannot recognize the package blocks release.

## Scaffolder rules

`sw_init.py` creates what is missing and touches nothing that exists. Any change
to it must keep these true, and the install tests must prove them:

- a second run reports every path as `present` and leaves the tree byte-identical;
- a pre-existing canonical instruction file keeps its prose, and the
  `## specwright` section is appended at most once;
- unrelated project files — other instructions, unrelated `.codex` content,
  existing ignore rules — are byte-identical afterwards;
- a path in an unusable shape is reported as a conflict **before** any write, and
  nothing is written at all;
- scaffolding a repository writes nothing outside it — the machine-wide Codex
  role install is a separate mode and never a side effect;
- the Claude adapter is a relative symlink; there is no regular-file fallback.

Do not reintroduce digest-protected blocks, plan identities, or drift
classification. Detection is by path and by heading, so the maintainer owns every
byte after the first run.

## Pull request checklist

- [ ] The branch is descriptive and is not `main`.
- [ ] Modified skills pass `quick_validate.py` and `package_skill.py`.
- [ ] Claude strict validation and the install tests pass.
- [ ] The host release smoke test passes when package surfaces change.
- [ ] `NOTICE.md` is updated when vendored content changes.
- [ ] Project artifacts and documentation agree with the implemented contract.
- [ ] Commit messages follow Conventional Commits.
- [ ] Commits and PR text contain no AI-attribution footers.

## Reporting bugs and security issues

Public bugs belong in the GitHub issue tracker with the host and version, a
reproduction, and the expected versus actual result. Vulnerabilities must be
reported privately using [`SECURITY.md`](SECURITY.md).

Participation is governed by the [Contributor Covenant 2.1](CODE_OF_CONDUCT.md).
