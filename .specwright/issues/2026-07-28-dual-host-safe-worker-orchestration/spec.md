---
feature: dual-host-safe-worker-orchestration
created: 2026-07-28
scope: complex
branch: feat/dual-host-safe-worker-orchestration
worktree: null
milestone: null
---
# Dual-host Plugin and Safe Worker Orchestration — Spec

**Issue:** see the sibling `issue.md` (the *why*, the acceptance criteria, and the issue `status:`)
**Scope:** package one shared specwright workflow natively for Claude Code and Codex, add deterministic project migrations, and make issue owners integrate isolated worker branches through validated dependency waves.

> **Note on `scope:` frontmatter** — `scope` is one of `low | medium | high | complex`. It is **recorded only**: reserved for a future quick-mode and does **not** yet gate which artifacts are written. Set it honestly; nothing branches on it today.
>
> **Note on `worktree:` frontmatter** — the path of this issue's git worktree under `.specwright/worktrees/`, or `null` when the work runs in place. **Recorded only**, like `scope:`.
>
> **Note on `milestone:` frontmatter** — the milestone folder this issue belongs to, or `null` for a standalone issue.

This is the **technical** spec — the *how*. The non-technical *why*, the acceptance criteria, and the status live in `issue.md`.

## Architecture

### Shared workflow core with host adapters

`plugins/sw/skills/` becomes the only location that defines workflow behavior. The six existing skills remain in place, while the implementations currently embedded in `commands/spec.md` and `commands/review-spec.md` move into `skills/spec/SKILL.md` and `skills/review-spec/SKILL.md`. `skills/update/SKILL.md` is the ninth, maintenance-only entry point. Claude command files contain only a redirect that resolves the plugin root and loads the matching skill; Codex reads the skills directory directly from its native manifest. This keeps the user surfaces distinct (`/sw:*` for Claude Code and `$sw:*` for Codex) while guaranteeing behavioral parity.

The Claude package remains described by `.claude-plugin/marketplace.json` and `plugins/sw/.claude-plugin/plugin.json`. Codex adds `.agents/plugins/marketplace.json` and `plugins/sw/.codex-plugin/plugin.json`. The Codex manifest owns the calendar version and declares the skills root. Because Codex validates this field as strict SemVer, the calendar components are not zero-padded: July 28, 2026 is `2026.7.28`, not `2026.07.28`. Tests treat the eight workflow skills and the ninth update skill as one required inventory and compare both host adapters against it.

### Canonical repository instructions and versioned migration

Generated instructions are host-neutral and canonical:

- shared mode: tracked `AGENTS.md`, with tracked `CLAUDE.md -> AGENTS.md`;
- local mode: ignored `AGENTS.override.md`, with ignored `CLAUDE.local.md -> AGENTS.override.md`.

The new `agents-md-template.md` contains a bounded managed block and no installation commands tied to one host. The managed block starts with a versioned marker and content digest and ends with a fixed closing marker. User-owned instructions before and after that block are opaque to specwright and survive every update.

`sw_update.py` is a standard-library-only engine with two mutually exclusive modes. `--plan` reads the installed plugin version from `.codex-plugin/plugin.json`, inspects all managed paths, computes every intended operation in memory, and emits a stable machine-readable summary plus a human-readable classification without writing. It also emits `plan_id`, a SHA-256 digest over the normalized target version, project mode, observed managed-path identities/digests, and ordered operations. The update skill runs `--plan`, displays it, asks for explicit confirmation, and invokes `--apply --expect-plan <plan_id>`. Apply repeats inspection and planning, rejects a different identity before writing, and applies exactly the confirmed plan.

State classification is deterministic:

- `new`: no recognized specwright instruction entry point or managed profiles exist;
- `up-to-date`: managed block version/digest, symlinks, and profiles match the installed plugin;
- `legacy-migratable`: an exact known Claude-only generated entry point is present and no conflicting Codex-managed path exists;
- `drifted`: a managed marker, digest, symlink target, profile, or legacy file differs from a recognized state.

All preconditions, parent-directory writability, symlink capability, and destination collisions are checked before the first mutation. Managed regular files are prepared through same-directory temporary files and atomic replacement; symlinks are prepared under temporary names and renamed into place. A failed preflight writes nothing. A write-time failure reports completed operations and preserves recoverable temporary material rather than continuing. There is no copy fallback for symlinks and no network access.

### Project-scoped role profiles

Four Codex TOML templates live under `plugins/sw/templates/codex-agents/` and are installed under `.codex/agents/`. Their names match the Claude agent manifest names exactly:

- `sw-issue-owner`: `gpt-5.6`, high reasoning, workspace write;
- `sw-spec-document-reviewer`: `gpt-5.6`, high reasoning, read-only;
- `sw-reviewer`: `gpt-5.6`, high reasoning, read-only;
- `sw-task-worker`: `gpt-5.6-terra`, medium reasoning, workspace write.

The profiles contain role-specific developer instructions, not copies of the full skills. Skills dispatch roles by these stable names and therefore do not branch on host aliases. Shared initialization tracks the profiles; local initialization appends only `.codex/agents/sw-*.toml` to `.gitignore`, leaving any unrelated Codex configuration untouched.

### Task topology as validated data

The task template introduces `tasks_schema: 2` and stable headings (`### T1: ...`). Every task records `AC`, `Delegable`, `Depends on`, `Files`, `Integration`, and `Validation`. `Integration: isolated` is valid only with `Delegable: yes`, at least one explicit owned file, a non-empty validation command, and dependencies that resolve to existing IDs.

A standard-library Python helper parses schema-2 task documents and returns diagnostics to `validate-spec.sh` as check 6. It verifies uniqueness, dependency existence, acyclicity, required metadata, and file ownership. It computes dependency waves by repeatedly selecting ready nodes; two isolated tasks that can be selected in the same wave may not claim the same normalized path. A dependency edge permits sequential ownership of the same file in later waves. A shipped issue without `tasks_schema: 2` is historical and passes this new check; any other legacy issue fails with an explicit replanning message. The updater never attempts to synthesize task ownership or dependency edges.

### Owner-controlled isolation and integration

The issue owner is the only role allowed to edit the issue branch, issue artifacts, learnings, or pull request. After committing the plan, the owner parses the validated task graph and dispatches only ready `Integration: isolated` tasks whose owned files do not overlap in that wave. Inline tasks remain on the issue branch.

For each isolated task, the owner:

1. records the current issue HEAD;
2. creates a task branch from that exact commit;
3. creates a sibling worktree under `.specwright/worktrees/<issue-slug>-<task-id>/`;
4. dispatches `sw-task-worker` with the task block, allowed files, base SHA, validation command, and return contract.

The worker changes only its worktree and declared files. It returns ordered commit SHAs, the touched-path list, validation commands and outcomes, and raw discoveries. It never edits `.specwright/`, creates a PR, integrates another branch, or writes learnings.

The owner verifies ancestry, ordered SHAs, diff scope, touched paths, and validation evidence before cherry-picking accepted commits onto the issue branch. It may resolve formatting, import-order, lockfile, or adjacent-line conflicts whose intended result is mechanically determined. A semantic conflict, undeclared path, ownership overlap, behavior choice, or scope change rejects the integration and sends the task back through replanning or redelegation. After each wave, the owner runs the integrated test set before releasing dependent tasks. Worker worktrees remain for inspection until a human removes them.

### Verification layers

`tests/install/run.sh` becomes the deterministic project-fixture suite for manifests, symlinks, ignore rules, profiles, updater behavior, and task topology. Release smoke tests run `claude plugin validate --strict plugins/sw` and a GitHub Actions job on an ephemeral runner. The Codex half uses the host's own ingestion path: `codex plugin marketplace add "$GITHUB_WORKSPACE"`, `codex plugin add sw@specwright --json`, and `codex plugin list --marketplace specwright --available --json`, followed by an assertion over the installed package's nine-skill inventory. Negative copies with a missing manifest or skill must fail ingestion/discovery. Documentation and the repository's own generated entry points are migrated last, so dogfooding exercises the same updater contract shipped to users.

## File Structure

- **Create `.agents/plugins/marketplace.json`** — Codex repository marketplace entry for the local `sw` package, with `AVAILABLE` and `ON_INSTALL` policy and `Productivity` category.
- **Modify `.claude-plugin/marketplace.json`** — describe the dual-host package and complete command inventory.
- **Create `plugins/sw/.codex-plugin/plugin.json`** — native Codex manifest and canonical calendar version.
- **Modify `plugins/sw/.claude-plugin/plugin.json`** — align package description and version-facing documentation with the dual-host surface.
- **Create `plugins/sw/skills/spec/SKILL.md`** — shared spec-authoring implementation moved from the Claude command.
- **Create `plugins/sw/skills/review-spec/SKILL.md`** — shared external plan-review implementation moved from the Claude command.
- **Create `plugins/sw/skills/update/SKILL.md`** — plan/confirm/apply project-update workflow.
- **Modify `plugins/sw/commands/*.md`** — nine homonymous Claude redirects with no independent implementation.
- **Modify `plugins/sw/scripts/quick_validate.py`** — accept and validate Claude's supported `user-invocable` boolean while preserving rejection of unknown frontmatter keys.
- **Modify `NOTICE.md`** — record the approved validator compatibility change to the vendored script.
- **Create `tests/skills/test_validation.py`** — prove supported invocation metadata passes validation and unknown keys still fail.
- **Create `plugins/sw/scripts/sw_update.py`** — standard-library migration planner and applier.
- **Create `plugins/sw/scripts/validate_task_topology.py`** — schema-2 parser and topology/file-ownership validator.
- **Modify `plugins/sw/scripts/validate-spec.sh`** — invoke task-topology validation as check 6 and update exit-code documentation.
- **Replace `plugins/sw/references/claude-md-template.md` with `plugins/sw/references/agents-md-template.md`** — host-neutral, versioned managed instruction block.
- **Create `plugins/sw/templates/codex-agents/sw-*.toml`** — four project-scoped role profile templates.
- **Modify `plugins/sw/agents/*.md`** — stable `sw-*` role names and aligned authority boundaries.
- **Modify `plugins/sw/skills/init/SKILL.md`** — initialize both hosts and delegate managed-path operations to the updater.
- **Modify `plugins/sw/skills/run/SKILL.md`** — copy local canonical instructions, Claude symlink, vault content, and Codex profiles into manual issue worktrees.
- **Modify `plugins/sw/skills/plan/SKILL.md`** — generate schema-2 tasks, compute waves, create isolated task branches/worktrees, review worker output, and integrate by cherry-pick.
- **Modify `plugins/sw/templates/tasks.md`** — schema-2 task contract with stable IDs and integration metadata.
- **Modify `plugins/sw/agents/issue-owner.md`** — sole-integrator protocol and conflict policy.
- **Modify `plugins/sw/agents/task-worker.md`** — isolated branch/worktree authority and structured return contract.
- **Modify `plugins/sw/scripts/fixtures/**`** — migrate the passing fixture and add legacy/topology failure cases.
- **Create `tests/update/test_plan.py` and fixtures** — focused updater classification, identity, preflight, preservation, and idempotence tests.
- **Create `tests/task-topology/test_parser.py` and fixtures** — focused schema-2 parser tests.
- **Create `tests/worktrees/test_local_copy.py`** — real temporary-worktree coverage for ignored local dual-host state.
- **Modify `tests/install/run.sh`** — dual-host, migration, profile, symlink, drift, and task-schema fixture coverage.
- **Create `tests/release/run.sh`** — strict Claude validation plus Codex ingestion/discovery assertions intended for an ephemeral runner.
- **Create `.github/workflows/release-smoke.yml`** — isolated host installation and discovery gate with pinned CLI versions.
- **Modify `README.md`, `CONTRIBUTING.md`, `SECURITY.md`, `plugins/sw/references/audit-checklist.md`, `plugins/sw/references/validation.md`, and `plugins/sw/references/vault-files.md`** — dual-host installation, update, permissions, release, and worker protocol documentation.
- **Create `AGENTS.md` and `.codex/agents/sw-*.toml`** — dogfooded shared configuration generated by the shipped updater.
- **Replace `CLAUDE.md` with the tracked `CLAUDE.md -> AGENTS.md` symlink** — Claude adapter to the canonical instructions.
- **Delete `.claude/settings.json`** — remove tracked host-local state.
- **Modify `.gitignore`** — preserve existing rules and document only generated local-mode paths when required by dogfood fixtures.

## Phase Ordering

1. **Native contracts** — add the Codex manifest/marketplace, establish the calendar version, create stable cross-host role templates, and begin the schema-2 parser in parallel.
2. **Shared skill surface** — move `spec` and `review-spec` into skills and reduce Claude commands to redirects.
3. **Managed project state** — add the neutral `AGENTS` template, deterministic planner, confirmed-plan applier, update skill, and dual-host init behavior.
4. **Safe worktrees and topology** — propagate local configuration into issue worktrees and finish graph/wave/file-ownership validation.
5. **Owner integration and release proof** — implement owner-controlled worker integration, expand deterministic fixtures, and exercise native host ingestion on an ephemeral runner.
6. **Documentation and dogfood** — update public/security/audit contracts, migrate this repository with the shipped updater, and run the integrated gate.

Tasks T1, T2, T3, and T8 form the first parallel wave. The remaining dependencies are encoded directly in `tasks.md`; the validated graph permits T4/T9, T7/T11, and T10/T12 to run as later non-overlapping parallel waves.

## Constraints

- The first release must provide complete Claude Code and Codex parity; compatibility-only discovery is insufficient.
- The Codex manifest version is unpadded `YYYY.M.D` calendar SemVer and is the only migration target source.
- Eight workflow skills plus the update maintenance skill are implemented once under `plugins/sw/skills/`.
- Skill validation runs with PyYAML in an ephemeral `uv` environment and accepts the host-supported `user-invocable` field without weakening unknown-key rejection.
- Symlink support is mandatory; absence is a preflight failure with no partial migration.
- The updater uses only Python's standard library, preserves content outside its managed block, and never accesses the network.
- Project-scoped Codex profiles may not overwrite or ignore unrelated `.codex` configuration.
- Design approval authorizes the specwright workflow but never expands the host's permission or approval policy.
- Only the issue owner writes the issue branch, issue artifacts, learnings, and PR.
- Workers may commit only declared files on their own task branches; integration is owner-reviewed cherry-pick.
- Mechanical conflicts are owner-resolvable; semantic conflicts, overlapping ownership, and scope changes require replanning.
- Existing shipped issues remain immutable historical records.
- No AI attribution appears in project artifacts, commits, or pull requests.

## User Stories / Scenarios

1. **Install for Claude Code** — a user adds the repository marketplace, installs `sw`, and discovers `/sw:init` through `/sw:update`; each command delegates to the shared skill.
2. **Install for Codex** — a user adds the Codex repository marketplace, installs `sw`, and discovers `$sw:init` through `$sw:update` from the native skills path.
3. **Initialize a shared repository** — `sw:init` creates a tracked `AGENTS.md`, Claude symlink, vault, and four Codex profiles without adding tracked host-local settings.
4. **Initialize a private local workflow** — `sw:init` creates ignored override instructions and profiles while leaving unrelated project Codex configuration untouched.
5. **Upgrade a recognized Claude-only repository** — `sw:update --plan` reports `legacy-migratable`; after explicit confirmation, `--apply` creates canonical AGENTS instructions, replaces the old Claude file with a symlink, and installs profiles.
6. **Refuse drift** — a project edits a managed block or profile; planning reports `drifted`, applying exits non-zero, and every pre-existing file remains unchanged.
7. **Run parallel isolated tasks** — the owner dispatches non-overlapping ready tasks into separate worktrees, receives ordered SHAs and evidence, integrates accepted commits, validates the wave, and then releases dependents.
8. **Reject unsafe integration** — a worker touches an undeclared file or a cherry-pick exposes a behavioral choice; the owner rejects the result and requests replanning instead of guessing.
9. **Read historical issues** — an old shipped issue with the previous task format remains valid; changing its status back to active makes validation demand explicit schema-2 replanning.
10. **Release the plugin** — Claude strict validation and Codex marketplace-add/plugin-add/list run on an ephemeral CI runner and verify the complete skill inventory before a release can pass.

## Acceptance Criteria

The acceptance criteria live in the sibling `issue.md` — the `AC-N` IDs defined there are the contract `tasks.md` references and `/sw:review` walks. Do not duplicate them here; if writing this spec exposed a missing or wrong criterion, fix `issue.md`.

## Risks and Mitigations

| Risk | Mitigation |
|---|---|
| Claude and Codex adapters drift even though skills are shared | Generate a canonical skill inventory in tests and require both manifests/redirect sets to match it. |
| A migration partially rewrites repository instructions | Complete all classification, digest, collision, writability, and symlink checks before writes; use temporary siblings and atomic replacement. |
| Project state changes after the user confirms an update plan | Bind apply to the displayed `plan_id` and reject any recomputed identity mismatch before writing. |
| User-authored AGENTS content is overwritten | Restrict updates to a versioned, digested managed block and preserve bytes outside its markers. |
| Legacy recognition accepts an arbitrary user file | Recognize only exact historical generated shapes and classify every ambiguous case as drifted. |
| Local ignore rules hide unrelated Codex settings | Add only `.codex/agents/sw-*.toml`, never `.codex/` or `.codex/agents/`. |
| Task file paths overlap through equivalent spellings | Normalize repository-relative paths, reject traversal/absolute paths, and compare normalized ownership within each wave. |
| Two worker branches are based on different issue states | Record and verify the issue HEAD used for every task branch before reviewing its commits. |
| Cherry-pick conflict resolution changes behavior | Limit owner resolution to mechanically determined output; reject any behavioral choice for replanning. |
| Host CLI behavior changes after this plan is written | Pin both CLIs in the ephemeral smoke job and fail the release when strict Claude validation or native Codex ingestion/discovery changes. |
| Dogfood migration obscures product changes in review | Run it last, keep generated files in a separate task/commit, and verify the updater reproduces them from a clean fixture. |

## Open Questions

None.
