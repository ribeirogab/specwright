# specwright

`specwright` (`sw`) is a dual-host plugin for Claude Code and Codex. It gives a
repository one explicit, change-driven engineering workflow:

> brainstorm → change → spec + tasks → implementation → integrated validation →
> runtime verification → PR → review

One change owns one branch and one PR. Larger outcomes become deliveries with a
durable goal, a board, and multiple changes conducted by an orchestrator.

The implementation of every workflow lives once under
[`plugins/sw/skills/`](plugins/sw/skills/). Claude Code exposes thin `/sw:*`
command adapters; Codex discovers the same skills as `$sw:*`.

## Install

### Claude Code

```bash
claude plugin marketplace add ribeirogab/specwright
claude plugin install sw@specwright
```

Reload plugins or restart Claude Code after installation.

### Codex

```bash
codex plugin marketplace add ribeirogab/specwright
codex plugin add sw@specwright
```

Both hosts install the same package and the same nine skills.

## Initialize a repository

Run the host surface available in the current session:

```text
Claude Code: /sw:init
Codex:       $sw:init
```

`sw:init` first asks for a mode and displays a read-only, deterministic plan.
Only an explicit confirmation of that exact `plan_id` permits the apply step.
Host permissions and sandbox approvals remain authoritative.

- **shared** tracks `.specwright/`, `AGENTS.md`, the relative
  `CLAUDE.md -> AGENTS.md` symlink, and four `.codex/agents/sw-*.toml` role
  profiles. Only `.specwright/worktrees/` is ignored.
- **local** keeps specwright state private in the checkout. It uses
  `AGENTS.override.md`, the relative
  `CLAUDE.local.md -> AGENTS.override.md` symlink, a local vault, and the same
  four profiles. The vault, both local instruction paths, the `sw-*` profiles,
  and worktrees are ignored.

`AGENTS.md` or `AGENTS.override.md` is always the canonical instruction file.
The corresponding `CLAUDE*.md` path is only a compatibility symlink. There is no
regular-file fallback: a filesystem that cannot create symlinks is rejected
before managed state is changed.

Initialization never edits personal host configuration, installs plugins, copies
skill implementations, or creates `.claude/settings.json`. It preserves
project-authored instructions outside the versioned `sw:managed` block and
unrelated `.codex` configuration.

## Update

Update the installed plugin with the native host mechanism first:

```bash
# Claude Code
claude plugin update sw@specwright

# Codex
codex plugin marketplace upgrade specwright
codex plugin add sw@specwright
```

Then migrate each initialized repository:

```text
Claude Code: /sw:update
Codex:       $sw:update
```

`sw:update` reads the target version from the already installed Codex manifest.
It never fetches or compares remote `main`. Its `--plan` phase is read-only and
classifies the checkout as `new`, `legacy-migratable`, `up-to-date`, or
`drifted`. For a migration, it shows every operation and the complete `plan_id`,
requires explicit confirmation, then applies only that unchanged identity.

The updater owns only:

- the bounded, digest-protected `sw:managed` block in the canonical AGENTS file;
- the relative Claude adapter symlink;
- the four `.codex/agents/sw-*.toml` profiles; and
- the exact specwright `.gitignore` rules for the selected mode.

Project text outside the managed block is preserved byte-for-byte. Unexpected
shapes, modified managed digests, plan identity changes, invalid profile sources,
or unavailable symlinks fail noisily before apply; drift is never overwritten.

## Command parity

| Workflow | Claude Code | Codex | Purpose |
|---|---|---|---|
| Initialize | `/sw:init` | `$sw:init` | Plan and create dual-host project state. |
| Brainstorm | `/sw:brainstorm` | `$sw:brainstorm` | Explore intent and approve a design. |
| Specify | `/sw:spec` | `$sw:spec` | Turn the current design into a change or delivery. |
| Plan | `/sw:plan` | `$sw:plan` | Produce schema-2 tasks, implement, and validate a change. |
| Conduct | `/sw:run` | `$sw:run` | Dispatch ready delivery changes and maintain the board. |
| Review | `/sw:review` | `$sw:review` | Review a branch diff with read-only specialist roles. |
| Review spec | `/sw:review-spec` | `$sw:review-spec` | Evaluate a change plan for clarity and conformance. |
| Pull request | `/sw:pr` | `$sw:pr` | Push and open the change PR using repository conventions. |
| Update | `/sw:update` | `$sw:update` | Plan and apply a versioned project migration. |

Natural-language requests can trigger the same Codex skills. Explicit `$sw:*`
invocation is useful when the desired entry point should be unambiguous.

## Project state after initialization

```text
.
├── AGENTS.md                         # shared canonical instructions
├── CLAUDE.md -> AGENTS.md            # shared Claude adapter
├── .codex/agents/
│   ├── sw-change-owner.toml
│   ├── sw-reviewer.toml
│   ├── sw-spec-document-reviewer.toml
│   └── sw-task-worker.toml
└── .specwright/
    ├── conventions/
    ├── changes/
    ├── deliveries/
    └── worktrees/                    # ignored worker/change checkouts
```

Local mode substitutes `AGENTS.override.md` and
`CLAUDE.local.md -> AGENTS.override.md`; all specwright-local state is ignored.
Existing shared instructions may coexist and remain untouched.

## Change flow and worker integration

Design approval authorizes continuation of the specwright workflow, but it never
overrides either host's file, command, Git, network, or external-action approval
policy.

Each active `tasks.md` uses `tasks_schema: 2`. Every task has:

- a stable `Tn` ID;
- `Delegable`, `Depends on`, `Files`, `Integration`, and `Validation`;
- explicit repository-relative ownership for `Integration: isolated`; and
- valid, acyclic dependencies.

The validator rejects missing metadata, unknown dependencies, cycles, and file
overlap between independent isolated tasks in the same dependency wave. Historical
shipped changes remain valid records; an active schema-1 task file must be explicitly
replanned because the updater cannot infer ownership or dependencies safely.

A **change owner** is the sole editor and integrator of the change branch,
change artifacts, learnings, and PR. It forms a **wave** — a dependency-ready,
file-disjoint set of isolated tasks that may run in parallel — from currently
ready, pairwise non-overlapping isolated tasks. Waves are derived at dispatch
time, never persisted. Every worker receives a branch at the wave's exact
change HEAD and a sibling worktree under `.specwright/worktrees/`.

A **task worker** may edit only its declared files in its own branch/worktree. It
does not edit change artifacts, create a PR, integrate branches, or write learnings.
It returns its base SHA, ordered commit SHAs, validations, touched files, and
discoveries. The owner verifies ancestry and scope, reviews the diff, and
cherry-picks accepted commits. Mechanical conflicts may be resolved by the owner;
semantic conflicts, ownership overlap, and scope changes require rejection and
replanning. Integrated validation after every wave gates dependent tasks.

Worker worktrees are retained for inspection and are never removed automatically.

In local mode, `sw:run` copies the canonical local instructions, their Claude
symlink, the project-installed `sw-*` Codex profiles, and the change folder into a
change worktree. On return it copies back only the change folder; instructions and
profiles remain conductor-owned state.

## Repository layout

```text
specwright/
├── .agents/plugins/                 # Codex marketplace
├── .claude-plugin/                  # Claude marketplace
├── plugins/sw/
│   ├── .claude-plugin/              # Claude package manifest
│   ├── .codex-plugin/               # Codex package manifest + calendar version
│   ├── agents/                      # Claude role adapters
│   ├── commands/                    # thin Claude redirects
│   ├── skills/                      # single workflow implementation
│   ├── templates/                   # change/delivery and Codex role templates
│   ├── scripts/                     # validators and deterministic updater
│   └── references/
├── tests/
└── .specwright/                     # dogfooded project vault
```

## Customize and contribute

Project-specific review rules belong in `.specwright/conventions/`. Shared
workflow behavior belongs in the relevant `plugins/sw/skills/<name>/SKILL.md`;
do not add host-specific behavior to a command redirect. Claude role manifests
and Codex TOML templates use the same role names:

| Role | Codex model/effort | Sandbox |
|---|---|---|
| `sw-change-owner` | `gpt-5.6-sol`, high | workspace write |
| `sw-spec-document-reviewer` | `gpt-5.6-sol`, high | read-only |
| `sw-reviewer` | `gpt-5.6-sol`, high | read-only |
| `sw-task-worker` | `gpt-5.6-terra`, medium | workspace write |

See [`CONTRIBUTING.md`](CONTRIBUTING.md) for the validation matrix and release
gates. Security reports follow [`SECURITY.md`](SECURITY.md).

## License

Original work is licensed under the [MIT License](LICENSE). Vendored Apache-2.0
scripts are documented in [`NOTICE.md`](NOTICE.md).
