---
feature: dual-host-safe-worker-orchestration
created: 2026-07-28
status: in-progress
shipped: null
---
# Dual-host Plugin and Safe Worker Orchestration — Issue

> The ticket: the approved *why* plus the acceptance criteria and the issue's status. `status:` lives **only** here — `pending | in-progress | shipped | blocked` — and `shipped:` gets the ship date when the PR is open and `/sw:review` reached `lgtm`. The technical *how* (architecture, file structure, tasks) lives in the sibling `spec.md` + `tasks.md`, written just-in-time by `/sw:plan`.

## Purpose

Make specwright a first-class plugin for both Claude Code and Codex from one shared implementation, with versioned project migration and a safe worker protocol in which the issue owner alone integrates isolated task branches.

## Motivation

The repository currently packages specwright for Claude Code and relies on compatibility behavior when Codex discovers it. Two workflow commands still contain host-specific implementations, generated repository instructions are Claude-specific, project updates have no versioned migration path, and the existing worker contract does not give the issue owner a mechanical way to prevent concurrent workers from colliding. Full dual-host support requires native manifests, host-neutral skills and generated instructions, deterministic migrations, project-scoped Codex role profiles, and explicit ownership of branches, worktrees, files, and integration.

## Non-Goals

- Provide copy-based fallbacks on platforms that cannot create symlinks.
- Fetch migration logic or project templates directly from the remote `main` branch.
- Migrate or infer dependency metadata for historical shipped issues.
- Let task workers edit issue artifacts, integrate their own branches, create pull requests, or curate learnings.
- Automatically delete worker worktrees after integration.
- Relax or bypass either host's permission and approval policy.

## Acceptance Criteria

Number each criterion sequentially as `AC-N` — the IDs are stable handles that `tasks.md` references (each task names the criteria it satisfies) and that `/sw:review` walks to prove every criterion was delivered. Each criterion must be a binary, observable check that someone other than the implementer can verify in under a minute. **No vague verbs** ("works well", "is fast", "is robust", "handles errors gracefully") — replace them with specific, measurable conditions. If a criterion cannot be verified without reading the implementation, it is not an acceptance criterion; rewrite it. State a hard constraint once — in the criterion (or Non-Goal) that owns it — and reference it elsewhere; every restatement is an amendment hazard.

Runtime verification checks each criterion by observed behavior before the PR opens; a criterion the agent cannot verify at runtime (e.g. UI without browser capability) is marked `needs-human-verification` with the reason — never silently ticked.

- [x] **AC-1** `claude plugin validate --strict plugins/sw` exits 0, and an ephemeral Codex runner successfully executes `codex plugin marketplace add <checkout>`, `codex plugin add sw@specwright --json`, and `codex plugin list --marketplace specwright --available --json`; both marketplace manifests resolve the local `sw` package from `./plugins/sw`.
- [x] **AC-2** Both hosts discover the same eight workflow skills (`init`, `brainstorm`, `spec`, `plan`, `run`, `review`, `review-spec`, `pr`) plus the maintenance skill `update`; every Claude command file is a thin redirect to its homonymous shared skill and contains no independent workflow implementation.
- [x] **AC-3** `plugins/sw/.codex-plugin/plugin.json` is the canonical version source, contains a strict-SemVer calendar version in unpadded `YYYY.M.D` form and `"skills": "./skills/"`, and a structural test rejects zero-padded or non-calendar versions and a different skills path.
- [x] **AC-4** `sw_update.py --plan` performs no writes, reports exactly one project state (`new`, `up-to-date`, `legacy-migratable`, or `drifted`), and emits a deterministic `plan_id`; `--apply --expect-plan <plan_id>` recomputes state and rejects a different identity before writing, reads its target version from the installed Codex manifest, and contains no remote fetch or `main`-branch lookup.
- [x] **AC-5** Migration fixtures prove that a recognized Claude-only shared or local installation becomes an `AGENTS.md` or `AGENTS.override.md` canonical file with the matching `CLAUDE*.md` symlink and four `.codex/agents/sw-*.toml` profiles; edited managed content and a symlink-unsupported fixture both fail before modifying the project.
- [x] **AC-6** `sw:init` prepares Claude Code and Codex together: shared mode tracks `AGENTS.md`, its Claude symlink, and four Codex profiles; local mode ignores only `AGENTS.override.md`, `CLAUDE.local.md`, the vault, and `.codex/agents/sw-*.toml` while preserving unrelated `.codex` configuration.
- [x] **AC-7** The installed Codex profiles and Claude agent manifests expose the same four role names; owner and reviewer profiles select the available `gpt-5.6-sol` model with high reasoning, the worker selects `gpt-5.6-terra` with medium reasoning, and only the two reviewer profiles are read-only.
- [x] **AC-8** In local mode, `sw:run` copies `AGENTS.override.md`, the corresponding Claude symlink, the issue vault content, and all four `sw-*.toml` profiles into each manually created issue worktree without making any copied path eligible for commit.
- [x] **AC-9** A schema-2 `tasks.md` requires unique stable task IDs, existing acyclic dependencies, `Delegable`, `Depends on`, `Files`, `Integration`, and `Validation`; the sixth mechanical validator check rejects missing isolated-task metadata and overlapping files between independent tasks in the same executable wave, while a shipped legacy issue remains valid and an active legacy issue is blocked for explicit replanning.
- [x] **AC-10** The issue-owner protocol creates each isolated worker branch from the current issue HEAD, places its worktree under `.specwright/worktrees/`, checks touched files and ordered commit SHAs, cherry-picks only accepted commits, runs integrated validation after every wave, and rejects semantic conflicts, ownership overlap, or scope changes for replanning.
- [x] **AC-11** Installation and release tests cover both manifests, both marketplaces, all nine shared skills and Claude redirects, shared/local symlink and ignore behavior, profile generation and drift, updater states and plan-identity mismatch, legacy migration failures, task dependency cycles, and file collisions; an ephemeral release job fails when either host cannot ingest the package or discover its skills.
- [x] **AC-12** `README.md`, `CONTRIBUTING.md`, `SECURITY.md`, templates, audit/validation references, and this repository's dogfooded configuration document installation and update paths for both hosts, `AGENTS.md` as the canonical instruction file, Claude symlinks, worker waves and cherry-pick integration, and the rule that design approval never overrides host permission policy.

Tick each `[x]` when verified. An issue is **not shippable** with empty or double-brace-placeholder acceptance criteria — `validate-spec.sh` and `/sw:review-spec` will reject it.
