# specwright

`specwright` (`sw`) is a plugin for Claude Code and Codex. It gives a repository
a **ladder** you climb one command at a time:

```text
/sw:change  →  /sw:plan  →  /sw:implement  →  /sw:pr  →  /sw:review
 change.md      plan.md         code             PR         lgtm
```

Each step produces one artifact, stops, and names the next command. Nothing runs
until you ask for it — the model may *suggest* a step, never dispatch the whole
flow on its own.

Two wrappers cover the cases where you do not want to climb:

- **`/sw:ship`** runs the whole ladder without stopping, deciding every open
  question itself and recording each decision in `change.md`.
- **`/sw:delivery`** takes an outcome too large for one PR — often a PRD or a
  design document — decomposes it into changes, and conducts them in parallel,
  one owner and one PR each.

A trivial change needs none of this. Edit the code.

The implementation of every workflow lives once under
[`plugins/sw/skills/`](plugins/sw/skills/). Claude Code exposes thin `/sw:*`
command adapters; Codex discovers the same skills as `$sw:*`.

## Why the steps are separate commands

Because the state lives in files, not in the conversation. Two things follow.

**You can change model between steps.** Each step stops, so switching is just
`/model` before the next command — a stronger model where judgment pays off
(`change`, `plan`, `review`), a cheaper one for the bulk of the execution
(`implement`).

**You can hand a plan to an agent that has no context at all.** `plan.md` is
written for a stranger: exact paths, runnable commands, real code in every code
step, and no open questions. A fresh session — another model, another host, next
week — implements it with one command:

```bash
/sw:implement 2026-07-31-cursor-pagination
```

`/sw:plan` checks that before it finishes. If the plan is not self-sufficient,
you find out while you can still fix it.

## Install

### Claude Code

```bash
claude plugin marketplace add ribeirogab/specwright
claude plugin install sw@specwright
```

Reload plugins or restart Claude Code afterwards.

### Codex

```bash
codex plugin marketplace add ribeirogab/specwright
codex plugin add sw@specwright
```

Codex ships subagents disabled, so enable them once:

```bash
codex features enable multi_agent_v2
```

It also reads subagent roles from its own home rather than from a plugin, so
those install once per machine too. `$sw:init` checks for them and prints the
exact command for your install path — it never writes outside a project unless
you ask it to.

Neither step is required: without them `$sw:delivery` and `$sw:review` run their
passes inline instead of spawning.

Both hosts install the same eight skills, and neither writes anything into your
repositories at install time.

## Set up a repository

```text
Claude Code: /sw:init
Codex:       $sw:init
```

`sw:init` asks for a mode, then creates only what is missing. It is idempotent:
re-running it is the upgrade path, and a second run writes nothing.

- **shared** — specwright state is versioned with the project: `.specwright/` and
  `AGENTS.md` with its `CLAUDE.md -> AGENTS.md` symlink. Only
  `.specwright/worktrees/` is ignored.
- **local** — specwright state stays private to the checkout:
  `AGENTS.override.md`, `CLAUDE.local.md -> AGENTS.override.md`, and the vault
  and both instruction paths are git-ignored.

Either way that is the whole footprint: a vault, one instruction file, its
symlink, and the ignore lines. Role profiles are not project state — both hosts
resolve them outside the repository.

The `AGENTS*` file is always canonical; the `CLAUDE*` path is only a
compatibility symlink. Init appends one `## specwright` section to the canonical
file and never touches it again — no digest, no drift check, no managed block.
The text is yours to edit from the moment it lands.

Init never installs a plugin, edits personal host configuration, copies skill
bodies, or creates `.claude/settings.json`. A path that exists in a shape it
cannot use — a `CLAUDE.md` that is a regular file, say — is reported as a
conflict, and nothing is written at all.

## Commands

| Command | Claude Code | Codex | Produces |
|---|---|---|---|
| Set up | `/sw:init` | `$sw:init` | the vault and project instructions |
| Ticket | `/sw:change` | `$sw:change` | `change.md` — purpose, boundaries, `AC-N` |
| Plan | `/sw:plan` | `$sw:plan` | `plan.md` — architecture and tasks |
| Build | `/sw:implement` | `$sw:implement` | code, quality gate, runtime verification |
| Ship it | `/sw:pr` | `$sw:pr` | the pull request |
| Review | `/sw:review` | `$sw:review` | one verdict, to `lgtm` |
| Autonomous | `/sw:ship` | `$sw:ship` | all of the above, no stops |
| Large outcome | `/sw:delivery` | `$sw:delivery` | many changes, conducted in parallel |

`/sw:change` absorbs the design conversation. After a discussion it harvests what
was settled and asks only about what is still open; from a cold start it opens
the exploration itself. Either way it writes the ticket at the end.

## Artifacts

Two files per change, always:

```text
.specwright/
├── changes/2026-07-31-<slug>/
│   ├── change.md                    why, AC-N, decisions and discoveries
│   └── plan.md                      architecture + task checklist
├── deliveries/2026-07-31-<slug>/
│   └── delivery.md                  why + change table + dispatch log + blockers
└── worktrees/                       ignored; one per change during a delivery
```

`change.md` carries the acceptance criteria — binary, observable checks someone
else can verify in under a minute — plus a **Decisions and discoveries** section:
the choices the ticket did not settle and the non-obvious facts the work found.
That section is what makes an autonomous `/sw:ship` run auditable after the fact.

`plan.md` carries the architecture on top and the task checklist below. Each task
names the criteria it satisfies, the files it touches, and one command that
proves it. The checkboxes are the resume state — `/sw:implement` continues at the
first unticked box, which is what lets a run stop and be picked up elsewhere.

The handoff gate enforces the pair:

```bash
plugins/sw/scripts/validate-change.sh .specwright/changes/<folder>
```

Six checks: frontmatter and status enum, a named branch, no surviving
placeholders, no vague criteria verbs, `AC-N` traceability in both directions,
and task metadata. Any of them failing means an agent with no context could not
run the plan.

## Verification

Two rules survive from every earlier version, because they are what make the
workflow worth its overhead:

**Every `AC-N` is verified by observed behavior before the PR opens.** Run the
CLI, call the endpoint, execute the script. Reading the code is not verification.
A criterion that cannot be checked — no browser, no reachable environment — is
marked `needs-human-verification` with its reason, never silently ticked.

**Verification happens at a known step, not on every edit.** The quality gate
runs at `implement` or `ship`, or when you ask for it. After a direct edit
outside the workflow, the agent reports what changed and what it did not verify,
and leaves the decision to you.

## Delivery

`/sw:delivery` handles the case a single PR cannot: a PRD, a design document, a
body of requirements that clearly contains many pieces. It decomposes the
document into changes — shallow on purpose, since each change's own plan is
written later with the benefit of what shipped before it — and dispatches one
`sw-change-owner` per ready change, in parallel, each in its own worktree,
branch, and PR.

Owners report `shipped` with a PR URL, or `blocked` with a paste-ready Why /
Tried / Needs. A blocked change never blocks the loop. The delivery is resumable
from a fresh session: all state lives in `delivery.md` and the changes'
frontmatter.

## Roles

Two, shared by both hosts:

| Role | Dispatched by | Codex sandbox |
|---|---|---|
| `sw-change-owner` | `/sw:delivery`, one per change | workspace write |
| `sw-reviewer` | `/sw:review` | read-only |

Neither pins a model. They inherit the session's, so the model you pick with
`/model` before dispatching is the one that runs — the same choice you make
between ladder steps, applied to the roles. The Codex sandbox is pinned, because
that is a permission boundary rather than a preference: the reviewer must not be
able to write, whatever model runs it.

Both hosts resolve the roles outside your repository — Claude Code from the
installed plugin, Codex from `${CODEX_HOME:-~/.codex}/agents/` after the one-time
install above. Nothing role-related is ever written into a project.

The reviewer covers three dimensions in one pass — rubric and conventions, change
conformance against the `AC-N` and their verification evidence, and documentation
consistency. A branch reaches `lgtm` only when no dimension has an open blocker.

## Repository layout

```text
specwright/
├── .agents/plugins/                 Codex marketplace
├── .claude-plugin/                  Claude marketplace
├── plugins/sw/
│   ├── .claude-plugin/              Claude package manifest
│   ├── .codex-plugin/               Codex package manifest + calendar version
│   ├── agents/                      Claude role manifests
│   ├── commands/                    eight thin Claude redirects
│   ├── skills/                      the single workflow implementation
│   ├── templates/                   change, plan, delivery, Codex roles
│   ├── scripts/                     scaffolder and validators
│   └── references/
├── tests/
└── .specwright/                     dogfooded vault
```

## Customize and contribute

Project-specific review rules live wherever your repository keeps them; list them
under a `## Conventions` heading in the canonical AGENTS instructions and the
reviewer follows the links. Shared workflow behavior goes in the relevant
`plugins/sw/skills/<name>/SKILL.md`; never add host-specific behavior to a
command redirect.

See [`CONTRIBUTING.md`](CONTRIBUTING.md) for the validation matrix and release
gates. Security reports follow [`SECURITY.md`](SECURITY.md).

## License

Original work is licensed under the [MIT License](LICENSE). Vendored Apache-2.0
scripts are documented in [`NOTICE.md`](NOTICE.md).
