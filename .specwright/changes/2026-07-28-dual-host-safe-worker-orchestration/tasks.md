---
feature: dual-host-safe-worker-orchestration
created: 2026-07-28
tasks_schema: 2
---
# Dual-host Plugin and Safe Worker Orchestration — Tasks

**For this issue:** see the sibling `issue.md` (acceptance criteria) and `spec.md` (technical plan).

> Each task names the `AC:` (acceptance criteria from `issue.md` it satisfies — every `AC-N` must be referenced by at least one task) and `Delegable:` (whether it suits an isolated task worker, and the one-line context that worker would receive). Workers report findings back to the issue owner; only the owner writes `learnings.md`.

This issue dogfoods schema 2 before the validator implementation lands. `Depends on` defines the execution graph, `Files` defines ownership, `Integration` selects owner-inline or isolated-worktree execution, and `Validation` is the task's minimum return evidence.

The initial draft pull request contains only these planning artifacts and, when CLI authentication is unavailable, the durable `pr.md` delivery record. None of the implementation checkboxes below is complete. The current five-check validator passes, but that result is not evidence for the schema-2 check introduced by T9.

## Phase 1: Native package surfaces

### T1: Add native Codex packaging and the canonical version

**AC:** AC-1, AC-3
**Delegable:** yes — add only the dual-host manifest and marketplace files, using the Codex manifest as the calendar-version source.
**Depends on:** none
**Integration:** isolated
**Files:**
- Create: `.agents/plugins/marketplace.json`
- Create: `plugins/sw/.codex-plugin/plugin.json`
- Modify: `.claude-plugin/marketplace.json`
- Modify: `plugins/sw/.claude-plugin/plugin.json`
**Validation:** `python3 -m json.tool` exits 0 for all four JSON files; a Python assertion reports Codex version `2026.7.28`, skills path `./skills/`, and both marketplace sources `./plugins/sw`.

- [x] **Step 1: Write the failing manifest assertion** — load all four JSON paths and assert:

  ```python
  codex_plugin["name"] == "sw"
  codex_plugin["version"] == "2026.7.28"
  codex_plugin["skills"] == "./skills/"
  codex_marketplace["plugins"][0]["source"]["path"] == "./plugins/sw"
  claude_marketplace["plugins"][0]["source"] == "./plugins/sw"
  ```

  Expected before the change: `FileNotFoundError` for the Codex manifest.

- [x] **Step 2: Create `.agents/plugins/marketplace.json`** — include top-level name and display name, local source, `AVAILABLE`, `ON_INSTALL`, and `Productivity`.
- [x] **Step 3: Create `.codex-plugin/plugin.json`** — include `name`, strict-SemVer calendar `version` without zero-padding, `description`, `author.name`, `skills`, and an `interface` with `displayName`, `shortDescription`, `longDescription`, `developerName`, `category`, `capabilities`, and no more than three `defaultPrompt` entries.
- [x] **Step 4: Align Claude metadata** — preserve its accepted shape and local source while describing the dual-host package and nine-entry surface.
- [x] **Step 5: Parse all JSON files** — run `python3 -m json.tool <path> >/dev/null` once per file; expect four zero exits.
- [x] **Step 6: Run the Step 1 assertion** — expect `package manifests: PASS`.
- [x] **Step 7: Commit** — `feat(plugin): add native Codex package metadata`

### T2: Move every workflow implementation into shared skills

**AC:** AC-2
**Delegable:** yes — create shared `spec` and `review-spec` skills and reduce the eight existing Claude commands to redirects without changing workflow behavior.
**Depends on:** none
**Integration:** isolated
**Files:**
- Create: `plugins/sw/skills/spec/SKILL.md`
- Create: `plugins/sw/skills/review-spec/SKILL.md`
- Modify: `plugins/sw/commands/brainstorm.md`
- Modify: `plugins/sw/commands/init.md`
- Modify: `plugins/sw/commands/spec.md`
- Modify: `plugins/sw/commands/plan.md`
- Modify: `plugins/sw/commands/run.md`
- Modify: `plugins/sw/commands/review.md`
- Modify: `plugins/sw/commands/review-spec.md`
- Modify: `plugins/sw/commands/pr.md`
- Modify: `plugins/sw/scripts/quick_validate.py`
- Modify: `NOTICE.md`
- Create: `tests/skills/test_validation.py`
**Validation:** both new skills pass `quick_validate.py`; the validator accepts boolean `user-invocable`, rejects unknown keys, and packages a companion skill; an inventory assertion finds eight commands and eight homonymous skills and rejects workflow sections inside redirects.

- [x] **Step 1: Inventory behavior in `commands/spec.md`** — list its inputs, issue mutations, template use, approval gate, and output in the new skill's checklist.
- [x] **Step 2: Create `skills/spec/SKILL.md`** — move every inventoried behavior under valid `name`, `description`, and invocation frontmatter.
- [x] **Step 3: Compare old and new spec behavior** — use `diff` on normalized bodies; expect only frontmatter/redirect framing differences.
- [x] **Step 4: Inventory behavior in `commands/review-spec.md`** — list target resolution, mechanical pre-check, seven review rows, verdict rules, and output shape.
- [x] **Step 5: Create `skills/review-spec/SKILL.md`** — move every inventoried behavior under valid skill frontmatter.
- [x] **Step 6: Compare old and new review behavior** — use `diff` on normalized bodies; expect only frontmatter/redirect framing differences.
- [x] **Step 7: Normalize eight command files** — keep command frontmatter plus one plugin-root-relative homonymous skill load and argument forwarding.
- [x] **Step 8: Write validator compatibility tests** — cover boolean `user-invocable`, a non-boolean value, an unknown key, and packaging through the same validation path.
- [x] **Step 9: Extend the vendored validator** — validate `user-invocable` as a supported boolean, keep unknown-key rejection strict, and update `NOTICE.md` to record the local change.
- [x] **Step 10: Run the validator tests in an ephemeral dependency environment**

  ```bash
  uv run --with pyyaml python3 tests/skills/test_validation.py
  ```

  Expected: `skill validation: PASS`.

- [x] **Step 11: Validate both skills**

  ```bash
  uv run --with pyyaml python3 plugins/sw/scripts/quick_validate.py plugins/sw/skills/spec
  uv run --with pyyaml python3 plugins/sw/scripts/quick_validate.py plugins/sw/skills/review-spec
  ```

  Expected twice: `Skill is valid!`.

- [x] **Step 12: Run the inventory assertion** — for each workflow name, require one command, one skill, and one `skills/<name>/SKILL.md` reference; reject copied `## Architecture`, `## What to evaluate`, or `## Implement` sections in commands.
- [x] **Step 13: Commit** — `refactor(skills): share every workflow across hosts`

### T3: Create project-scoped role templates and stable identities

**AC:** AC-7
**Delegable:** yes — create four Codex TOML templates and align only role identity/model metadata in the four Claude manifests.
**Depends on:** none
**Integration:** isolated
**Files:**
- Create: `plugins/sw/templates/codex-agents/sw-issue-owner.toml`
- Create: `plugins/sw/templates/codex-agents/sw-spec-document-reviewer.toml`
- Create: `plugins/sw/templates/codex-agents/sw-reviewer.toml`
- Create: `plugins/sw/templates/codex-agents/sw-task-worker.toml`
- Modify: `plugins/sw/agents/issue-owner.md`
- Modify: `plugins/sw/agents/spec-document-reviewer.md`
- Modify: `plugins/sw/agents/reviewer.md`
- Modify: `plugins/sw/agents/task-worker.md`
**Validation:** Python `tomllib` parses four files; an assertion compares exact role names, models, reasoning efforts, and read-only/write sandboxes across host manifests.

- [x] **Step 1: Create `sw-issue-owner.toml`** — set stable name, role description, `gpt-5.6-sol`, high reasoning, workspace-write sandbox, and owner instructions.
- [x] **Step 2: Create `sw-spec-document-reviewer.toml`** — set `gpt-5.6-sol`, high reasoning, read-only sandbox, and plan-document review instructions.
- [x] **Step 3: Create `sw-reviewer.toml`** — set `gpt-5.6-sol`, high reasoning, read-only sandbox, and find-only review instructions.
- [x] **Step 4: Create `sw-task-worker.toml`** — set `gpt-5.6-terra`, medium reasoning, workspace-write sandbox, and isolated-task instructions.
- [x] **Step 5: Align Claude manifest names** — use the same four `sw-*` identities and preserve Claude-native model fields.
- [x] **Step 6: Parse TOML**

  ```bash
  python3 -c 'import pathlib,tomllib; [tomllib.loads(path.read_text()) for path in pathlib.Path("plugins/sw/templates/codex-agents").glob("sw-*.toml")]'
  ```

  Expected: exit 0 with no output.

- [x] **Step 7: Run the role-matrix assertion** — expect `role profiles: PASS` and exactly two read-only profiles.
- [x] **Step 8: Commit** — `feat(agents): add dual-host project roles`

## Phase 2: Managed project state

### T4: Define the neutral AGENTS template and pure update planner

**AC:** AC-3, AC-4, AC-5
**Delegable:** yes — create the host-neutral managed block and read-only project classifier; no apply path or user-facing skill.
**Depends on:** T1, T3
**Integration:** isolated
**Files:**
- Create: `plugins/sw/references/agents-md-template.md`
- Delete: `plugins/sw/references/claude-md-template.md`
- Create: `plugins/sw/scripts/sw_update.py`
- Create: `tests/update/test_plan.py`
- Create: `tests/update/fixtures/new/.gitkeep`
- Create: `tests/update/fixtures/drifted/AGENTS.md`
**Validation:** `python3 tests/update/test_plan.py` passes classification, stable serialization, calendar-version rejection, managed-digest drift, and plan-purity tests.

- [x] **Step 1: Write the neutral template** — include the shared workflow contract, separate `/sw:*` and `$sw:*` invocation surfaces, and host-permission boundary; exclude installation commands.
- [x] **Step 2: Define updater data types**

  ```python
  @dataclass(frozen=True)
  class ObservedPath:
      relative_path: str
      kind: str
      digest_or_target: str | None

  @dataclass(frozen=True)
  class Operation:
      action: str
      relative_path: str
      expected_before: str | None
      desired_after: str

  @dataclass(frozen=True)
  class UpdatePlan:
      state: str
      version: str
      mode: str
      observed: tuple[ObservedPath, ...]
      operations: tuple[Operation, ...]
      plan_id: str
  ```

- [x] **Step 3: Write failing version tests** — accept `2026.7.28`; reject `2026.07.28`, `2026-07-28`, and semantic versions whose components do not represent a valid date.
- [x] **Step 4: Implement manifest version loading** — resolve plugin root from `__file__`, load `.codex-plugin/plugin.json`, validate unpadded calendar SemVer, and return the exact version.
- [x] **Step 5: Write failing snapshot tests** — cover missing, regular, symlink, managed block with matching digest, managed block with mismatched digest, and unexpected path kinds.
- [x] **Step 6: Implement read-only snapshots** — use `lstat`, never follow an unexpected symlink, normalize paths relative to `--project`, and hash regular-file bytes.
- [x] **Step 7: Write failing classification tests** — cover `new`, `up-to-date`, exact legacy shared/local shapes, and every ambiguous/drifted state.
- [x] **Step 8: Implement classification and ordered operations** — inspect canonical instructions, Claude adapters, `.gitignore`, and the four T3 profile templates/destinations.
- [x] **Step 9: Implement deterministic identity** — serialize target version, mode, sorted observations, and ordered operations as canonical JSON and hash it with SHA-256 into `plan_id`.
- [x] **Step 10: Implement `--plan --format text|json`** — output classification, `plan_id`, diagnostics, and ordered operations without opening writable handles.
- [x] **Step 11: Run planner tests** — expect all tests green and identical JSON for two plans over an unchanged fixture.
- [x] **Step 12: Commit** — `feat(update): add deterministic project migration plans`

### T5: Apply only the confirmed update plan atomically

**AC:** AC-4, AC-5, AC-6
**Delegable:** no — extends the planner with mutation, preflight, plan-identity verification, symlink enforcement, and rollback-safe operation ordering.
**Depends on:** T4
**Integration:** inline
**Files:**
- Modify: `plugins/sw/scripts/sw_update.py`
- Modify: `tests/update/test_plan.py`
- Create: `tests/update/fixtures/legacy-shared/CLAUDE.md`
- Create: `tests/update/fixtures/legacy-local/CLAUDE.local.md`
- Create: `tests/update/fixtures/up-to-date/AGENTS.md`
- Create: `tests/update/fixtures/profiles/2026.7.27/sw-issue-owner.toml`
- Create: `tests/update/fixtures/profiles/2026.7.27/sw-spec-document-reviewer.toml`
- Create: `tests/update/fixtures/profiles/2026.7.27/sw-reviewer.toml`
- Create: `tests/update/fixtures/profiles/2026.7.27/sw-task-worker.toml`
**Validation:** updater tests prove identity mismatch, symlink failure, destination collision, legacy migration, preservation outside markers, apply idempotence, and zero writes on every preflight failure.

- [x] **Step 1: Write the identity-mismatch test** — plan a fixture, mutate one observed byte, run `--apply --expect-plan <old-id>`, expect non-zero and an unchanged post-mutation checksum.
- [x] **Step 2: Implement apply identity verification** — rebuild the plan immediately before mutation and compare it with `--expect-plan`; reject absent or unequal IDs.
- [x] **Step 3: Write preflight failure tests** — cover unwritable parent, occupied symlink destination, unsupported symlink creation, invalid profile destination, and drifted managed block.
- [x] **Step 4: Implement complete preflight** — validate every operation and create/remove a disposable sibling symlink before the first managed write.
- [x] **Step 5: Write managed-block preservation tests** — surround the managed block with user bytes, apply a newer template, and assert prefix/suffix byte equality.
- [x] **Step 6: Implement temporary regular files** — write, flush, and rename same-directory temporary files while replacing only the bounded managed block.
- [x] **Step 7: Implement temporary symlinks** — create relative-target temporary links and rename them into recognized adapter paths.
- [x] **Step 8: Implement profile and ignore operations** — install the four T3 templates; in local mode append only exact specwright patterns and preserve unrelated lines/files.
- [x] **Step 9: Implement the operation ledger** — on write-time failure, print completed and pending operations, stop immediately, and leave recoverable temporary material named in the diagnostic.
- [x] **Step 10: Run legacy migration tests** — shared and local fixtures become canonical AGENTS files, Claude symlinks, and four matching profiles.
- [x] **Step 11: Run idempotence** — apply once, plan the resulting `up-to-date` state twice, expect zero operations and identical IDs between those two post-migration plans; the post-migration ID must differ from the confirmed migration ID.
- [x] **Step 12: Commit** — `feat(update): apply only confirmed migration plans`

### T6: Expose dual-host init and explicit update

**AC:** AC-2, AC-4, AC-5, AC-6
**Delegable:** no — connect user-facing init/update skills to the confirmed-plan updater contract.
**Depends on:** T2, T5
**Integration:** inline
**Files:**
- Modify: `plugins/sw/skills/init/SKILL.md`
- Create: `plugins/sw/skills/update/SKILL.md`
- Create: `plugins/sw/commands/update.md`
**Validation:** both skills pass `quick_validate.py`; a text assertion proves update forwards the displayed `plan_id` through `--expect-plan` only after explicit confirmation.

- [x] **Step 1: Rewrite init's entry-point phase** — retain vault creation and mode choice, then run planner/apply for instructions, symlinks, profiles, and exact ignore rules.
- [x] **Step 2: Add init refusal paths** — stop on drift, unrecognized files, or symlink failure and print the updater diagnostic without manual overwrite instructions.
- [x] **Step 3: Create update skill planning** — run JSON plan, display state/diagnostics/operations/`plan_id`, and make no mutation.
- [x] **Step 4: Add explicit confirmation** — ask the user to confirm that exact plan identity; a refusal ends the skill.
- [x] **Step 5: Add confirmed apply** — invoke `--apply --expect-plan <displayed-plan-id>` with the same project and mode.
- [x] **Step 6: Create the Claude update redirect** — use the thin homonymous redirect contract from T2.
- [x] **Step 7: Validate**

  ```bash
  python3 plugins/sw/scripts/quick_validate.py plugins/sw/skills/init
  python3 plugins/sw/scripts/quick_validate.py plugins/sw/skills/update
  ```

  Expected twice: `Skill is valid!`.

- [x] **Step 8: Audit approval wording** — reject any sentence claiming design approval overrides host permissions.
- [x] **Step 9: Commit** — `feat(init): configure both hosts and add sw update`

## Phase 3: Worktree propagation and task topology

### T7: Propagate local dual-host state into issue worktrees

**AC:** AC-8
**Delegable:** yes — update only local-mode worktree copy-in behavior and add a focused sandbox test.
**Depends on:** T3, T6
**Integration:** isolated
**Files:**
- Modify: `plugins/sw/skills/run/SKILL.md`
- Create: `tests/worktrees/test_local_copy.py`
**Validation:** `python3 tests/worktrees/test_local_copy.py` creates a temporary Git worktree and proves canonical instructions, relative Claude symlink, issue vault content, and four profiles are present and ignored.

- [x] **Step 1: Write the failing worktree test** — create a local-mode repository, add a worktree, execute the documented copy-in primitives, and assert the six managed areas.
- [x] **Step 2: Replace contract copy-in** — copy `AGENTS.override.md`, then create `CLAUDE.local.md -> AGENTS.override.md` in the target instead of copying a Claude regular file.
- [x] **Step 3: Add profile copy-in** — create `.codex/agents` and copy exactly `sw-*.toml`.
- [x] **Step 4: Preserve vault transport** — retain issue-folder copy-in and sync-back, with no profile or instruction sync-back.
- [x] **Step 5: Assert ignore scope** — `git status --porcelain` omits managed local paths while a fixture `.codex/project.toml` remains visible.
- [x] **Step 6: Run the test** — expect `local worktree copy: PASS`.
- [x] **Step 7: Commit** — `feat(run): propagate dual-host local state`

### T8: Parse the schema-2 task document

**AC:** AC-9
**Delegable:** yes — update the task template and implement syntax/metadata parsing only; graph and wave validation remain in T9.
**Depends on:** none
**Integration:** isolated
**Files:**
- Modify: `plugins/sw/templates/tasks.md`
- Create: `plugins/sw/scripts/validate_task_topology.py`
- Create: `tests/task-topology/test_parser.py`
- Create: `tests/task-topology/fixtures/valid/tasks.md`
- Create: `tests/task-topology/fixtures/malformed/tasks.md`
**Validation:** `python3 tests/task-topology/test_parser.py` passes stable-ID, required-field, integration-mode, dependency-token, file-path, and validation-command parsing cases.

- [x] **Step 1: Update the template** — add `tasks_schema: 2`, `Tn` headings, and exact `AC`, `Delegable`, `Depends on`, `Files`, `Integration`, and `Validation` fields.
- [x] **Step 2: Define parser data types**

  ```python
  @dataclass(frozen=True)
  class Task:
      task_id: str
      ac_ids: tuple[str, ...]
      delegable: bool
      dependencies: tuple[str, ...]
      files: tuple[str, ...]
      integration: str
      validation: str
  ```

- [x] **Step 3: Write heading/frontmatter tests** — reject missing schema 2, malformed IDs, duplicate IDs, and text outside recognized task blocks.
- [x] **Step 4: Parse headings and scalar fields** — return ordered tasks and line-numbered diagnostics without third-party YAML.
- [x] **Step 5: Write metadata tests** — reject missing/duplicate fields, invalid yes/no, invalid integration values, empty validation, and malformed dependencies.
- [x] **Step 6: Parse metadata** — accept `none` or comma-separated `Tn`; require isolated+delegable and inline+non-delegable pairings.
- [x] **Step 7: Write path tests** — reject absolute paths, traversal, non-repository-relative spellings, and empty ownership for isolated tasks; accept an exact `None` ownership marker only for inline tasks.
- [x] **Step 8: Normalize owned paths** — map inline `None` to an empty tuple; otherwise remove `.` segments and repeated separators while preserving repository-relative case.
- [x] **Step 9: Run parser tests** — expect `task parser: PASS`.
- [x] **Step 10: Commit** — `feat(tasks): parse schema two task metadata`

### T9: Validate dependency waves and file ownership as check 6

**AC:** AC-9
**Delegable:** yes — add graph/collision logic, historical-status behavior, check-6 integration, and deterministic fixtures.
**Depends on:** T8
**Integration:** isolated
**Files:**
- Modify: `plugins/sw/scripts/validate_task_topology.py`
- Modify: `plugins/sw/scripts/validate-spec.sh`
- Modify: `plugins/sw/scripts/fixtures/good/tasks.md`
- Create: `plugins/sw/scripts/fixtures/bad-task-dependency/issue.md`
- Create: `plugins/sw/scripts/fixtures/bad-task-dependency/spec.md`
- Create: `plugins/sw/scripts/fixtures/bad-task-dependency/tasks.md`
- Create: `plugins/sw/scripts/fixtures/bad-task-cycle/issue.md`
- Create: `plugins/sw/scripts/fixtures/bad-task-cycle/spec.md`
- Create: `plugins/sw/scripts/fixtures/bad-task-cycle/tasks.md`
- Create: `plugins/sw/scripts/fixtures/bad-task-collision/issue.md`
- Create: `plugins/sw/scripts/fixtures/bad-task-collision/spec.md`
- Create: `plugins/sw/scripts/fixtures/bad-task-collision/tasks.md`
- Create: `plugins/sw/scripts/fixtures/legacy-shipped/issue.md`
- Create: `plugins/sw/scripts/fixtures/legacy-shipped/spec.md`
- Create: `plugins/sw/scripts/fixtures/legacy-shipped/tasks.md`
- Create: `plugins/sw/scripts/fixtures/legacy-active/issue.md`
- Create: `plugins/sw/scripts/fixtures/legacy-active/spec.md`
- Create: `plugins/sw/scripts/fixtures/legacy-active/tasks.md`
**Validation:** good and shipped-legacy fixtures pass; missing dependency, cycle, independent same-wave collision, and active legacy format each fail check 6 with stable task/path diagnostics.

- [x] **Step 1: Write missing/self-dependency tests** — expect diagnostics naming source and missing/self target.
- [x] **Step 2: Validate dependency references** — compare every edge with parsed IDs before graph traversal.
- [x] **Step 3: Write cycle tests** — cover two-node and transitive cycles; expect all remaining cycle candidates in sorted order.
- [x] **Step 4: Implement topological waves** — repeatedly select ready tasks in document order and return an error when no progress is possible.
- [x] **Step 5: Write collision tests** — reject one normalized path owned by independent isolated tasks in the same wave; permit reuse after a direct or transitive dependency.
- [x] **Step 6: Validate wave ownership** — compare normalized sets only among isolated tasks selected together.
- [x] **Step 7: Write legacy status tests** — shipped schema-1 fixture passes; pending, in-progress, or blocked schema-1 fixture returns an explicit replanning error.
- [x] **Step 8: Implement historical behavior** — read issue frontmatter status before requiring schema 2; never modify the artifact.
- [x] **Step 9: Wire check 6** — preserve checks 1–5, prefix helper output with `FAIL (check 6):`, and count it once regardless of diagnostic count.
- [x] **Step 10: Run all validator fixtures** — assert exact exit status and diagnostic substring per fixture.
- [x] **Step 11: Commit** — `feat(tasks): validate task waves and ownership`

## Phase 4: Owner-controlled worker integration

### T10: Make the issue owner the sole worker integrator

**AC:** AC-9, AC-10
**Delegable:** no — change the plan pipeline and owner/worker authority protocol after schema 2 and local worktree propagation exist.
**Depends on:** T7, T9
**Integration:** inline
**Files:**
- Modify: `plugins/sw/skills/plan/SKILL.md`
- Modify: `plugins/sw/agents/issue-owner.md`
- Modify: `plugins/sw/agents/task-worker.md`
**Validation:** a protocol assertion finds every required branch/worktree input, worker return field, diff/ancestry check, cherry-pick rule, conflict class, integrated wave gate, and authority prohibition.

- [x] **Step 1: Replace the task-writing contract** — require schema 2 fields and run check 6 before the plan commit.
- [x] **Step 2: Add wave selection** — select only dependency-ready, non-overlapping isolated tasks; keep inline tasks on the issue branch.
- [x] **Step 3: Add exact branch provenance** — record issue HEAD, create each task branch from that SHA, and use `.specwright/worktrees/<issue-slug>-<task-id>/`.
- [x] **Step 4: Define the worker dispatch payload** — include task block, base SHA, allowed paths, validation command, and prohibitions on `.specwright`, PRs, integration, and learnings.
- [x] **Step 5: Define the worker return payload** — require ordered commit SHAs, touched paths, commands/results, raw discoveries, and a blocked report when ownership is insufficient.
- [x] **Step 6: Add owner pre-integration checks** — verify commit ancestry/order, `git diff --name-only` scope, task ownership, and validation evidence.
- [x] **Step 7: Add ordered cherry-pick** — integrate only accepted SHAs on the issue branch.
- [x] **Step 8: Classify conflicts** — permit formatting/import-order/lockfile/adjacent-line resolutions with mechanically determined output; reject behavioral choice, overlap, or scope change for replanning.
- [x] **Step 9: Gate wave completion** — run integrated validation before releasing dependents and retain worker worktrees.
- [x] **Step 10: Tighten role manifests** — owner alone edits issue artifacts/branch/PR/learnings; worker alone edits its declared files on its branch.
- [x] **Step 11: Run the protocol assertion** — require the phrases/fields `base SHA`, `ordered commit SHAs`, `touched paths`, `cherry-pick`, `mechanical conflict`, `semantic conflict`, `replan`, and `integrated validation`.
- [x] **Step 12: Commit** — `feat(workers): integrate isolated tasks through issue owners`

## Phase 5: Deterministic and host-native verification

### T11: Validate package inventories and init modes

**AC:** AC-1, AC-2, AC-3, AC-6, AC-7, AC-11
**Delegable:** yes — restructure the existing install suite around manifests, shared inventory, profiles, and shared/local init output.
**Depends on:** T1, T2, T3, T6
**Integration:** isolated
**Files:**
- Modify: `tests/install/run.sh`
- Create: `tests/install/fixtures/projects/shared/.gitkeep`
- Create: `tests/install/fixtures/projects/local/.gitkeep`
**Validation:** `bash tests/install/run.sh package init` exits 0 and prints named passes for manifests, nine skills/redirects, profile matrix, shared output, local ignore scope, and unrelated Codex preservation.

- [x] **Step 1: Extract fixture helpers** — add functions for temporary Git repositories, JSON assertions, symlink assertions, TOML assertions, and named pass/fail output.
- [x] **Step 2: Add manifest assertions** — validate both marketplaces/manifests, unpadded calendar SemVer, and skills path.
- [x] **Step 3: Add inventory assertions** — compare a canonical nine-name list against skill directories and Claude redirects.
- [x] **Step 4: Add profile assertions** — parse four TOML templates and compare the T3 role matrix.
- [x] **Step 5: Add shared init fixture** — verify tracked `AGENTS.md`, relative Claude symlink, vault, and profiles.
- [x] **Step 6: Add local init fixture** — verify exact ignored paths and that unrelated `.codex/project.toml` remains unignored.
- [x] **Step 7: Run package/init groups** — expect all named passes and no dependence on personal host configuration.
- [x] **Step 8: Commit** — `test(install): cover dual-host package and init`

### T12: Validate migrations, plan identity, and local worktree copy

**AC:** AC-4, AC-5, AC-8, AC-11
**Delegable:** no — extend the install suite with updater and worktree fixtures after the focused tests from T5 and T7 pass.
**Depends on:** T5, T6, T7, T11
**Integration:** inline
**Files:**
- Modify: `tests/install/run.sh`
- Create: `tests/install/fixtures/update/new/.gitkeep`
- Create: `tests/install/fixtures/update/up-to-date/AGENTS.md`
- Create: `tests/install/fixtures/update/legacy-shared/.gitkeep`
- Create: `tests/install/fixtures/update/legacy-local/.gitkeep`
- Create: `tests/install/fixtures/update/drifted/AGENTS.md`
- Create: `tests/install/fixtures/update/symlink-unsupported/.gitkeep`
**Validation:** `bash tests/install/run.sh update worktree` exits 0 and proves four states, plan purity, identity mismatch refusal, apply idempotence, drift/symlink zero-write failures, profile drift, and ignored worktree copy-in.

- [x] **Step 1: Add recursive checksums** — snapshot every fixture before and after plan/failure paths.
- [x] **Step 2: Add four-state plans** — assert exact state, stable `plan_id`, diagnostics, and ordered operations.
- [x] **Step 3: Add plan purity** — run each plan twice, compare JSON byte-for-byte, and compare fixture checksums.
- [x] **Step 4: Add identity mismatch** — mutate after planning, apply the old ID, expect non-zero and no updater writes.
- [x] **Step 5: Add legacy applies** — verify canonical AGENTS content, relative Claude symlink, exact profiles, and preserved user bytes.
- [x] **Step 6: Add idempotence** — second plan after apply is `up-to-date` with zero operations.
- [x] **Step 7: Add drift/profile/symlink failures** — expect one clear diagnostic and unchanged checksum for each fixture.
- [x] **Step 8: Invoke the T7 worktree test** — include its pass/fail in the install suite summary.
- [x] **Step 9: Run update/worktree groups** — expect all named passes.
- [x] **Step 10: Commit** — `test(update): cover migration identity and worktrees`

### T13: Add strict host-native release smoke tests

**AC:** AC-1, AC-2, AC-11
**Delegable:** yes — create a release script and ephemeral CI job that exercise Claude validation and Codex marketplace ingestion without touching maintainer state.
**Depends on:** T11, T12
**Integration:** isolated
**Files:**
- Create: `tests/release/run.sh`
- Create: `.github/workflows/release-smoke.yml`
- Modify: `CONTRIBUTING.md`
**Validation:** the workflow runs pinned host CLIs on an ephemeral runner, passes the valid package, and proves missing-manifest and missing-skill copies fail their corresponding host gate.

- [x] **Step 1: Pin CLI versions in the workflow** — install exact Claude Code and Codex versions and print both versions in logs.
- [x] **Step 2: Add Claude strict validation**

  ```bash
  claude plugin validate --strict plugins/sw
  ```

  Expected: exit 0 for the real package and non-zero for a temporary copy without `.claude-plugin/plugin.json`.

- [x] **Step 3: Add Codex native ingestion**

  ```bash
  codex plugin marketplace add "$GITHUB_WORKSPACE"
  codex plugin add sw@specwright --json
  codex plugin list --marketplace specwright --available --json
  ```

  Expected: all commands exit 0 on the ephemeral runner and JSON identifies `sw@specwright`.

- [x] **Step 4: Assert installed inventory** — resolve the installed path from `plugin add --json` and require nine `skills/*/SKILL.md` files.
- [x] **Step 5: Add Codex negative copies** — in temporary directories, remove `.codex-plugin/plugin.json` and one required skill separately; require ingestion or inventory assertion to fail.
- [x] **Step 6: Keep local execution safe** — `tests/release/run.sh` runs read-only/static and Claude checks locally; Codex add/remove operations run only when `CI_EPHEMERAL_RUNNER=1`, otherwise exit with an explanatory skip.
- [x] **Step 7: Document exact release commands and ephemeral-state requirement** in `CONTRIBUTING.md`.
- [x] **Step 8: Commit** — `test(release): require native dual-host ingestion`

## Phase 6: Documentation and dogfood

### T14: Document the dual-host and owner-integration contracts

**AC:** AC-6, AC-7, AC-8, AC-10, AC-12
**Delegable:** no — update cross-cutting public/security/audit documentation after all contracts and release commands are stable.
**Depends on:** T6, T7, T10, T13
**Integration:** inline
**Files:**
- Modify: `README.md`
- Modify: `CONTRIBUTING.md`
- Modify: `SECURITY.md`
- Modify: `plugins/sw/references/audit-checklist.md`
- Modify: `plugins/sw/references/validation.md`
- Modify: `plugins/sw/references/vault-files.md`
- Modify: `plugins/sw/skills/brainstorm/SKILL.md`
- Modify: `plugins/sw/skills/pr/SKILL.md`
- Modify: `plugins/sw/skills/review/SKILL.md`
- Modify: `plugins/sw/skills/run/SKILL.md`
- Modify: `plugins/sw/skills/spec/SKILL.md`
- Modify: `plugins/sw/templates/board.md`
- Modify: `plugins/sw/templates/issue.md`
- Modify: `plugins/sw/templates/spec.md`
- Modify: `.github/ISSUE_TEMPLATE/bug.md`
- Modify: `.github/ISSUE_TEMPLATE/feature_request.md`
- Modify: `.github/PULL_REQUEST_TEMPLATE.md`
- Modify: `.specwright/conventions/README.md`
- Modify: `.specwright/conventions/skill-validation-requirements.md`
**Validation:** a documentation audit finds separate host install/invocation/update paths, canonical AGENTS/symlink modes, explicit permission boundaries, project profiles, local worktree propagation, schema-2 waves, and owner cherry-pick rules.

- [x] **Step 1: Update README installation docs** — describe each native marketplace and the host's exact install command.
- [x] **Step 2: List invocation surfaces** — show eight workflow entries plus `update` as `/sw:*` and `$sw:*`.
- [x] **Step 3: Document update flow** — update the host plugin first, display `plan_id`, explicitly confirm, and apply that identity without remote fetch.
- [x] **Step 4: Document generated state** — shared/local canonical AGENTS files, Claude symlinks, profiles, and exact ignore scope.
- [x] **Step 5: Document permissions** — state that issue/design approval never changes host approval policy.
- [x] **Step 6: Document worker topology** — stable IDs, dependencies, ownership, waves, owner-created branches/worktrees, returned SHAs/evidence, cherry-pick, integrated validation, and conflict rejection.
- [x] **Step 7: Update security/audit checks** — add managed digest, plan identity, symlink preflight, no network migration, profile authority, ancestry/path checks, and host-native release evidence.
- [x] **Step 8: Complete contributor guidance** — extend T13's release instructions with dual-host skill authoring, updater fixture expectations, schema-2 ownership, and owner/worker integration boundaries.
- [x] **Step 9: Run the documentation audit** — search for stale Claude-only update/install claims and unsupported-local-milestone wording; expect no hits.
- [x] **Step 10: Commit** — `docs(workflow): document dual-host worker integration`

### T15: Dogfood the shared dual-host configuration

**AC:** AC-5, AC-6, AC-7, AC-12
**Delegable:** no — apply the finished updater to this repository and commit only its generated shared-mode output.
**Depends on:** T3, T5, T6, T14
**Integration:** inline
**Files:**
- Create: `AGENTS.md`
- Replace with symlink: `CLAUDE.md -> AGENTS.md`
- Create: `.codex/agents/sw-issue-owner.toml`
- Create: `.codex/agents/sw-spec-document-reviewer.toml`
- Create: `.codex/agents/sw-reviewer.toml`
- Create: `.codex/agents/sw-task-worker.toml`
- Delete: `.claude/settings.json`
- Modify: `.gitignore`
- Modify: `tests/update/test_plan.py`
- Create: `tests/update/fixtures/legacy-dogfood/CLAUDE.md`
**Validation:** a second plan reports `up-to-date`; Claude symlink is relative; four profiles match templates byte-for-byte; tracked host-local settings are absent; broad `.codex` ignore rules are absent.

- [x] **Step 1: Run shared-mode plan** — inspect state, operations, and `plan_id`; stop if the repository is not recognized as migratable.
- [x] **Step 2: Apply that identity** — pass the displayed ID with `--expect-plan`.
- [x] **Step 3: Remove tracked `.claude/settings.json` through the migration/dogfood change** — retain personal activation outside version control.
- [x] **Step 4: Verify the symlink** — `readlink CLAUDE.md` prints `AGENTS.md`.
- [x] **Step 5: Compare profiles** — `cmp` each installed file with its template; expect four zero exits.
- [x] **Step 6: Re-plan** — expect `state: up-to-date`, the current version, and zero operations.
- [x] **Step 7: Audit ignore scope** — preserve `.specwright/worktrees/` and reject `.codex/` or `.codex/agents/` blanket rules.
- [x] **Step 8: Commit** — `docs(workflow): dogfood the dual-host contract`

### T16: Run the integrated quality gate

**AC:** AC-1, AC-2, AC-3, AC-4, AC-5, AC-6, AC-7, AC-8, AC-9, AC-10, AC-11, AC-12
**Delegable:** no — the issue owner runs the complete gate on the integrated branch and records per-criterion evidence for delivery.
**Depends on:** T9, T12, T13, T15
**Integration:** inline
**Files:**
- None
**Validation:** all commands below exit 0 or produce the explicitly expected negative-control failure; every AC has observed evidence or a named human-verification reason.

- [x] **Step 1: Validate this issue**

  ```bash
  plugins/sw/scripts/validate-spec.sh .specwright/issues/2026-07-28-dual-host-safe-worker-orchestration
  ```

  Expected: `PASS`.

- [x] **Step 2: Validate nine skills** — run `quick_validate.py` for each skill directory; expect nine `Skill is valid!` lines.
- [x] **Step 3: Package nine skills** — run `package_skill.py` into a temporary directory; require nine archives.
- [x] **Step 4: Validate the validator contract** — run `uv run --with pyyaml python3 tests/skills/test_validation.py`; expect `skill validation: PASS`.
- [x] **Step 5: Run focused Python tests**

  ```bash
  python3 tests/update/test_plan.py
  python3 tests/task-topology/test_parser.py
  python3 tests/worktrees/test_local_copy.py
  ```

  Expected: three zero exits.

- [x] **Step 6: Run deterministic integration**

  ```bash
  bash tests/install/run.sh
  ```

  Expected: all named groups pass.

- [x] **Step 7: Run release smoke** — execute `bash tests/release/run.sh` locally and the ephemeral workflow; record Claude strict output and Codex add/list JSON.
- [x] **Step 8: Run hygiene checks** — `git diff --check`, four JSON parses, four TOML parses, symlink target assertion, stale-language search, and tracked-file inventory.
- [x] **Step 9: Walk AC-1 through AC-12** — record the exact command/fixture that observed each outcome; do not tick criteria proved only by source inspection when runtime evidence is required.
- [x] **Step 10: Review integrated ownership** — compare the final diff against T1–T15 `Files` fields and reject any unrelated or worker-worktree path.
- [x] **Step 11: Commit** — no commit when the gate changes no files; any later evidence-only artifact uses a scoped docs commit.
