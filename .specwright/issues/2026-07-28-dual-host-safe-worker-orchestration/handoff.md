# Implementation Handoff — Dual-host Plugin and Safe Worker Orchestration

## Objective

Implement the complete approved issue **Dual-host Plugin and Safe Worker Orchestration** in the existing repository, branch, and draft pull request.

The result must give Claude Code and Codex first-class, release-blocking parity from one shared implementation; add safe, versioned project migration; and make the issue owner the sole integrator of isolated worker branches.

This handoff is intended to be the only initial prompt given to a clean agent session. Treat the linked issue artifacts as the detailed source of truth and this document as the execution, context, and readiness contract.

The originating checkout was `/Users/gabriel/.codex/worktrees/1d75/specwright`, but a clean session may receive another worktree path. Resolve the current repository root first and substitute it for `<repo-root>` everywhere below; do not assume the originating absolute path still exists.

## Mandatory stop/go gate — do not implement before this passes

**Do not edit product files, planning artifacts, tests, or documentation until the preflight below is complete.**

The user requires the implementation to be tested and validated with **both Claude Code and Codex**. Before starting, prove that the session has every tool, permission, isolation mechanism, dependency, and host surface required to finish all tasks and all twelve acceptance criteria.

Preflight may inspect files, consult current official host documentation, create disposable temporary fixtures, and run read-only/baseline commands. It may not begin a partial implementation while a capability is unresolved.

### Required preflight checks

1. **Load instructions and source artifacts**

   Read these files completely:

   - Global instructions: `/Users/gabriel/.codex/AGENTS.md`
   - Current repository instructions: `<repo-root>/CLAUDE.md`
   - Issue: `<repo-root>/.specwright/issues/2026-07-28-dual-host-safe-worker-orchestration/issue.md`
   - Technical spec: `<repo-root>/.specwright/issues/2026-07-28-dual-host-safe-worker-orchestration/spec.md`
   - Task graph: `<repo-root>/.specwright/issues/2026-07-28-dual-host-safe-worker-orchestration/tasks.md`
   - Current PR record: `<repo-root>/.specwright/issues/2026-07-28-dual-host-safe-worker-orchestration/pr.md`
   - This handoff.

   The approved `issue.md`, `spec.md`, and `tasks.md` govern implementation. Do not regenerate or redesign them silently. If current official host behavior contradicts them, report the exact contradiction before implementation.

2. **Confirm Git and PR state**

   Expected:

   ```text
   repository: the current checkout of github.com/ribeirogab/specwright
   branch: feat/dual-host-safe-worker-orchestration
   upstream: origin/feat/dual-host-safe-worker-orchestration
   HEAD: b2059f134f953431569818cb85e78b0f15a7c57b
   base: origin/main at 4f880255fe3880d9ab46449836403bb644ac0291
   PR: https://github.com/ribeirogab/specwright/pull/65
   PR state: open draft
   ```

   PR #65 currently has one planning commit, no reviews, no comments, and no checks. No implementation has started.

   This `handoff.md` was created after the planning commit and may be the only expected untracked file. Preserve it and do not include it in a commit unless the user explicitly authorizes that.

3. **Confirm the local baseline**

   Run:

   ```bash
   bash tests/install/run.sh
   plugins/sw/scripts/validate-spec.sh \
     .specwright/issues/2026-07-28-dual-host-safe-worker-orchestration
   git diff --check
   ```

   Expected before implementation:

   - `tests/install/run.sh` ends with `ALL PASS`.
   - The issue validator prints `PASS`.
   - No product diff exists.

   Empty scaffolding directories from an abandoned attempt were removed on 2026-07-29. In particular, `plugins/sw/skills/update`, `plugins/sw/skills/spec`, `plugins/sw/skills/review-spec`, `plugins/sw/.codex-plugin`, and repo-local `.agents` must be absent before implementation.

4. **Confirm both host toolchains**

   The observed versions on 2026-07-29 were:

   ```text
   Claude Code: 2.1.220
   Codex CLI: 0.146.0-alpha.3.1
   Python: 3.14.4
   Bash: 5.3.9
   ShellCheck: 0.11.0
   uv: 0.11.7
   gh: 2.83.0
   ```

   Verify current versions and current official plugin documentation before pinning release smoke tests. Confirm these commands and their required subcommands are available:

   ```bash
   claude --version
   claude plugin --help
   claude plugin marketplace --help
   claude plugin install --help
   claude plugin validate --help

   codex --version
   codex plugin --help
   codex plugin marketplace --help
   codex plugin add --help
   codex plugin list --help
   ```

5. **Prove that full Claude and Codex validation is achievable**

   Before coding, establish a concrete, isolated execution path for the final host matrix:

   - Claude native strict validation.
   - Claude isolated marketplace installation and discovery of all nine entry points.
   - Codex native manifest validation/ingestion.
   - Codex isolated marketplace installation and discovery of all nine skills.
   - Negative controls for each host: missing manifest and missing required skill/command must fail.
   - No test may mutate the maintainer's personal Claude or Codex plugin state.

   Use an ephemeral CI runner, disposable OS user, or another isolation mechanism supported by the host CLIs. Do not repurpose `HOME`, `CODEX_HOME`, or personal plugin caches to simulate isolation.

   The intended native smoke commands include:

   ```bash
   claude plugin validate --strict plugins/sw
   claude plugin marketplace add "$GITHUB_WORKSPACE"
   claude plugin install sw@specwright --scope local
   claude plugin list
   claude plugin details sw@specwright

   codex plugin marketplace add "$GITHUB_WORKSPACE"
   codex plugin add sw@specwright --json
   codex plugin list --marketplace specwright --available --json
   ```

   Adapt exact flags only after checking the pinned host versions and official documentation. Preserve the required behavior and isolation.

6. **Resolve test dependencies before coding**

   Known preflight problem:

   ```text
   python3 plugins/sw/scripts/quick_validate.py plugins/sw/skills/init
   -> ModuleNotFoundError: No module named 'yaml'

   python3 plugins/sw/scripts/package_skill.py plugins/sw/skills/init /tmp/...
   -> ModuleNotFoundError: No module named 'yaml'
   ```

   `uv` is installed, but an in-sandbox attempt to fetch PyYAML failed because the sandbox could not access the normal cache/network. Prove a safe, reproducible way to run both scripts before implementation. Prefer an ephemeral tool environment or documented project dependency; do not silently add a repository dependency or alter validator policy during preflight.

   Historical PRs #63 and #64 also reported that, once PyYAML was available, the vendored validator rejected the `user-invocable` key used by every companion skill. Reproduce this against the current source. If it still occurs, it is a planning/tooling conflict: report it before implementation and identify whether the validator, task ownership, or validation command must change.

7. **Classify expected red tests separately from environment blockers**

   These current failures are expected product gaps and are in scope:

   - `claude plugin validate --strict plugins/sw` currently fails because the Claude manifest has no `version` and no `author`. T1 must remove both strict warnings.
   - Native Codex manifest/marketplace ingestion cannot pass because those files do not exist yet. T1 creates them.
   - `spec` and `review-spec` are still implemented in Claude command files. T2 moves them into shared skills.
   - `sw:update` is currently absent by design. T4–T6 reintroduce it with a new project-migration purpose.

   Missing executables, inaccessible host state, unavailable isolation, unresolved Python dependencies, unavailable CI, or an unplanned validator conflict are **not** expected red tests. They block implementation.

### Required preflight response

Before changing any implementation file, send one of these reports to the user.

Ready:

```text
Preflight: READY
- Git/PR state: verified
- Baseline: passing
- Claude validation + isolated discovery path: available
- Codex validation + isolated discovery path: available
- Python/skill validation dependencies: available
- Worker/worktree integration capability: available
- Known red tests: all explained by the approved issue

Starting Wave 1.
```

Blocked:

```text
Preflight: BLOCKED
- Exact failing command:
- Exact error:
- Why it prevents 100% completion:
- What was tried:
- Resolution or user decision required:

No implementation has started.
```

If any blocking item exists, stop after the report. Do not implement an "independent" task while waiting.

## Current repository architecture

Specwright is a Markdown + shell/Python plugin repository with no application build pipeline. It dogfoods its issue-driven workflow.

Current package shape:

```text
.claude-plugin/marketplace.json          Claude marketplace
plugins/sw/.claude-plugin/plugin.json   Claude plugin manifest
plugins/sw/commands/                    eight Claude command entry points
plugins/sw/skills/                      six shared skills today
plugins/sw/agents/                      four Claude role definitions
plugins/sw/templates/                   issue/milestone templates
plugins/sw/references/                  generated guidance and audits
plugins/sw/scripts/                     validators and packaging helpers
tests/install/run.sh                    current installation smoke suite
.specwright/                            dogfooded issue vault
CLAUDE.md                               current repository instruction source
```

The current six shared skills are `brainstorm`, `init`, `plan`, `pr`, `review`, and `run`. `spec` and `review-spec` still live as full Claude commands. `update` is absent in the committed baseline.

## Approved outcome and locked decisions

Do not reopen these decisions unless a verified host incompatibility makes one impossible:

1. **Full first-release parity.** Claude Code and Codex are equal supported hosts.
2. **One workflow implementation.** Eight workflow skills plus the maintenance skill `update` live once under `plugins/sw/skills/`.
3. **Thin Claude adapter.** All nine Claude command files redirect to homonymous shared skills.
4. **Native Codex adapter.** Add repo marketplace and `.codex-plugin/plugin.json` with `"skills": "./skills/"`.
5. **Canonical version.** The Codex manifest is the only version source. The approved version is unpadded calendar SemVer `2026.7.28`; do not silently change it because the implementation date is later.
6. **Canonical instructions.**
   - Shared: tracked `AGENTS.md`; tracked `CLAUDE.md -> AGENTS.md`.
   - Local: ignored `AGENTS.override.md`; ignored `CLAUDE.local.md -> AGENTS.override.md`.
7. **Symlinks are mandatory.** No copy fallback. Unsupported symlinks fail before writes.
8. **Versioned project migration.** `sw_update.py --plan` is read-only and emits one state plus deterministic `plan_id`; apply requires `--expect-plan`.
9. **No remote updater fetch.** Project migration reads the installed Codex manifest and never fetches `main`.
10. **Managed boundaries.** Only the versioned managed block, Claude symlinks, exact ignore rules, and `.codex/agents/sw-*.toml` profiles are updater-owned. Preserve user content outside the block and unrelated `.codex` files.
11. **Four stable role names.**
    - `sw-issue-owner`: `gpt-5.6`, high, write.
    - `sw-spec-document-reviewer`: `gpt-5.6`, high, read-only.
    - `sw-reviewer`: `gpt-5.6`, high, read-only.
    - `sw-task-worker`: `gpt-5.6-terra`, medium, write.
12. **Schema-2 tasks.** Stable IDs, AC coverage, dependencies, ownership, integration mode, and validation are mechanically checked.
13. **Historical behavior.** Shipped schema-1 issues remain valid records; active schema-1 issues require explicit replanning.
14. **Owner-only integration.** Workers never edit issue artifacts, PRs, or learnings and never integrate their own branches.
15. **Cherry-pick integration.** Owner reviews ancestry, SHA order, touched paths, diff scope, and evidence before accepting commits.
16. **Conflict policy.** Owner may resolve only mechanically determined conflicts. Semantic conflict, overlap, or scope change requires replanning/redelegation.
17. **Wave gate.** Run integrated validation after every wave before releasing dependents.
18. **Worktree retention.** Never auto-delete worker worktrees.
19. **Host permissions remain authoritative.** Design approval never bypasses host or sandbox permission policy.
20. **No AI attribution** in code, commits, issues, PRs, or docs.

## Relevant history

- [PR #58 — remove the obsolete `/sw:update`](https://github.com/ribeirogab/specwright/pull/58): removed the old updater because plugin-only distribution had no copied implementation to reconcile. This issue reintroduces the name for a different responsibility: versioned migration of project-owned AGENTS/symlink/profile state. Do not restore remote-source reconciliation.
- [PR #61 — bundle role subagents](https://github.com/ribeirogab/specwright/pull/61): introduced the four Claude role definitions and current model/effort assignments. This issue standardizes names across hosts, adds Codex TOMLs, and strengthens owner/worker authority.
- [PR #63 — local commit mode](https://github.com/ribeirogab/specwright/pull/63): introduced shared/local init, `CLAUDE.local.md`, ignored vault state, and guard-only mode switching. This issue replaces the generated entry point with canonical AGENTS files and adds safe automatic legacy migration.
- [PR #64 — conduct local milestones](https://github.com/ribeirogab/specwright/pull/64): added canonical-vault copy-in/sync-back for local worktrees. Preserve that transport model while adding AGENTS override, Claude symlink, and Codex profiles to copy-in.
- [PR #65 — current draft](https://github.com/ribeirogab/specwright/pull/65): contains only the approved planning artifacts at commit `b2059f1`. Continue this PR; do not open another one.

PR #58's removal rationale and PR #63's guard-only migration are historical constraints, not contradictions: the approved issue intentionally supersedes them with a versioned, drift-detecting migration engine.

## Execution graph

`tasks.md` contains the complete file ownership, steps, commands, and expected results. Execute its graph exactly:

| Wave | Tasks | Purpose |
|---|---|---|
| 1 | T1, T2, T3, T8 | Native package metadata, shared skill moves, role templates, task parser |
| 2 | T4, T9 | Pure update planner; topology/wave ownership validation |
| 3 | T5 | Confirmed-plan atomic apply |
| 4 | T6 | Dual-host init and explicit update entry point |
| 5 | T7, T11 | Local worktree propagation; package/init test suite |
| 6 | T10, T12 | Owner integration protocol; updater/worktree integration tests |
| 7 | T13 | Strict native release smoke tests for both hosts |
| 8 | T14 | Public, contributor, security, audit, and validation docs |
| 9 | T15 | Dogfood migration of this repository |
| 10 | T16 | Full integrated gate and per-AC evidence |

T1/T2/T3/T8, T4/T9, T7/T11, and T10/T12 are deliberately non-overlapping parallel waves.

The improved owner/worker protocol is not implemented in the current baseline. Until T10 lands, manually enforce the approved `tasks.md` ownership and return contracts. If the session cannot create/use isolated workers and worktrees as planned, report that during preflight instead of silently flattening the issue into inline execution.

Only the issue owner may edit:

- the issue branch;
- `issue.md`, `spec.md`, `tasks.md`, `pr.md`, and future `learnings.md`;
- the pull request body/state;
- cherry-pick integration and conflict resolution.

Workers may touch only their declared task files on their task branches/worktrees and must return ordered SHAs, touched paths, exact validation results, and discoveries.

Follow the global Git consent rules before creating task branches/worktrees, staging, committing, or pushing. Never push directly to `main`.

## Required verification matrix

Completion requires all of the following. Passing only one host is a release blocker.

### Shared mechanical and regression gates

- Updated `validate-spec.sh` passes checks 1–6 on this active schema-2 issue.
- Existing shipped legacy issues remain valid.
- Active legacy fixture fails with the replanning diagnostic.
- `bash tests/install/run.sh` passes every group with no silent test-count drop.
- Focused updater, task-parser, topology, and worktree tests pass.
- `shellcheck` passes every changed shell script.
- `git diff --check` passes.
- JSON and TOML parsing passes for every manifest/profile.
- Every one of AC-1 through AC-12 has observed evidence.

### Claude Code gate

- Claude marketplace and plugin manifests pass strict native validation.
- The isolated Claude marketplace installs `sw@specwright`.
- Claude discovers nine `/sw:*` entry points.
- Every command is a thin redirect to the correct shared skill.
- Negative missing-manifest and missing-command/skill fixtures fail.
- Shared and local generated instructions are usable by Claude through the required symlinks.

### Codex gate

- Codex marketplace and native plugin manifest pass current native validation/ingestion.
- The isolated Codex marketplace installs `sw@specwright`.
- Codex discovers the same nine `sw:*` skills.
- Four project TOML profiles parse and load with the exact role matrix and sandboxes.
- Negative missing-manifest and missing-skill fixtures fail.
- Shared and local AGENTS discovery uses the canonical files.

### Migration and orchestration gate

- `--plan` is byte-stable and write-free.
- State classification covers new, up-to-date, legacy-migratable, and drifted.
- `--apply --expect-plan` rejects state changes before writing.
- Shared/local Claude-only migrations preserve user bytes and install exact profiles.
- Drift, collision, unsupported symlink, and profile divergence fail with zero updater writes.
- Second post-apply plan is up-to-date and operation-free.
- Local worktree copy-in remains git-ignored and preserves unrelated `.codex` state.
- Task dependencies are unique, existent, acyclic, and wave-safe.
- Independent same-wave ownership collision fails.
- Owner rejects undeclared paths, semantic conflict, overlap, and scope change.
- Integrated validation runs after every accepted wave.

## Known traps

1. **Strict SemVer vs calendar formatting:** `2026.07.28` is invalid strict SemVer because of leading zeroes. Use the approved `2026.7.28`.
2. **Claude strict baseline failure:** the current manifest lacks `version` and `author`. T1 must fix both, not merely add Codex metadata.
3. **PyYAML is not available to system Python:** solve the validator execution path before implementation.
4. **`user-invocable` validator compatibility may still be broken:** reproduce before implementation and report if the plan lacks ownership for the fix.
5. **Do not use personal plugin state for smoke tests:** both host installation/discovery runs belong in an ephemeral environment.
6. **Do not infer Codex support from Claude compatibility discovery:** native Codex manifest, marketplace, ingestion, skills, and profiles are required.
7. **Do not restore the old updater:** no remote branch fetch, no plugin source reconciliation.
8. **Do not broad-ignore `.codex`:** local mode ignores only `.codex/agents/sw-*.toml`.
9. **Do not overwrite user AGENTS content:** only the managed block is mutable.
10. **Do not create fallback copies for Claude:** symlink inability is an explicit failure.
11. **Do not migrate historical task ownership:** shipped issues are records; active legacy issues stop.
12. **Do not auto-remove worktrees.**
13. **Do not mark criteria verified from source inspection when observed behavior is required.**
14. **The PR body is stale after implementation:** it currently says artifacts-only and must be replaced with actual changes, gates, and per-AC runtime evidence.

## GitHub CLI rule for this machine

An injected invalid `GH_TOKEN` can override the valid `ribeirogab` keyring credential.

Run GitHub CLI commands as:

```bash
env -u GH_TOKEN gh ...
```

If authentication fails inside the sandbox, retry the same command with sandbox escalation before concluding that the keyring credential is invalid. Never print tokens.

## Delivery contract

1. Continue branch `feat/dual-host-safe-worker-orchestration` and PR #65.
2. Preserve unrelated/user changes and the handoff file.
3. Commit only with explicit consent required by the global instructions.
4. Keep PR #65 draft during implementation.
5. After each wave, review every integrated diff and run the wave's integrated tests.
6. After T16, update:
   - `issue.md` checkboxes only for runtime-verified ACs;
   - `pr.md` with the real summary, test plan, planning gates, quality gates, and per-AC runtime verification;
   - remote PR #65 body using `env -u GH_TOKEN gh pr edit 65 --body-file ...`;
   - `learnings.md` only with non-obvious facts future issues need.
7. Run the repository review workflow to `lgtm`.
8. Do not mark the PR ready, merge it, delete worktrees, or push to `main` without explicit user instruction.

## Definition of 100% complete

The implementation is complete only when:

- T1 through T16 are implemented and validated in dependency order;
- all twelve acceptance criteria have observed evidence or an explicit, user-accepted human-verification record;
- every deterministic and negative fixture passes as expected;
- native Claude Code validation, isolated installation, and discovery pass;
- native Codex validation/ingestion, isolated installation, and discovery pass;
- no shared/local, historical-issue, existing-skill, or existing-test regression remains;
- the repository dogfoods the generated AGENTS/symlink/profile state;
- the issue validator and full quality gate pass;
- PR #65 accurately reflects the implementation and remains draft pending the user's decision;
- no unresolved blocker, skipped host, weakened assertion, hidden scope change, or fake verification remains.

If the agent cannot prove at preflight that this completion state is achievable in the current session/environment, it must report the blocker before implementation and stop.
