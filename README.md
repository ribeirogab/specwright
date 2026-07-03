# specwright

`specwright` gives any repository an explicit **issue-driven workflow** — every non-trivial change becomes an **issue** (1 issue = 1 branch = 1 PR) running through one pipeline: brainstorm → issue → spec + tasks → implement → quality gate → runtime verification → PR → review-to-`lgtm`. Large deliveries become **milestones**: a goal, a live board, and issues conducted in a loop by an orchestrator. Agent-agnostic and self-hosting.

---

## Install

From your project root:

```bash
curl -fsSL https://raw.githubusercontent.com/ribeirogab/specwright/main/install.sh | sh
```

This:

- installs the scaffolder skill — `.agents/skills/sw/`, plus the `.claude/skills/sw` symlink, and
- enables the `sw` plugin in `.claude/settings.json`.

Then open the repo in your agent and run `/sw` to audit and scaffold the `.specwright/` vault. The plugin commands (`/sw:spec`, `/sw:pr`, …) load once Claude Code trusts the workspace.

## Use

Point an agent at any repo where you want specwright installed:

> "Audit specwright in this repo and scaffold whatever is missing."

The skill is audit-first, autonomous-fix, and safe to re-run. After the first run the repo has a working `.specwright/` vault, the bundled `sw-*` companion skills, the `/sw:*` slash commands, and an `AGENTS.md` — all dogfood-tested by specwright's own validator.

**Source:** [`skills/sw/SKILL.md`](skills/sw/SKILL.md)

## What you get

After install the repo has:

- an **`AGENTS.md`** describing the issue-driven workflow,
- a **`.specwright/` vault** holding `conventions/` (whatever standards the repo wants kept consistent — you fill it, `/sw:review` enforces it), `issues/` (dated standalone-issue folders), `milestones/` (dated milestone folders), and `models.md` (per-role model routing — see [Model routing](#model-routing)), and
- a set of **`/sw:*` commands** and companion skills:

| Command | What it does |
|---|---|
| `/sw` | Scaffold or audit specwright in the current repo — set up, verify, or fix. Idempotent. |
| `/sw:brainstorm` | Explore intent and design before any non-trivial change → an issue or a milestone. |
| `/sw:spec` | Turn the current conversation into an issue and enter the flow. |
| `/sw:plan` | The issue pipeline: just-in-time `spec.md` + `tasks.md`, gates, delivery. |
| `/sw:run` | Conduct a milestone: dispatch every ready issue, track the board, close out. |
| `/sw:review` | Review the branch diff with find-only subagents until `lgtm`. |
| `/sw:review-spec` | External-evaluator pass over an issue's plan — flags vagueness, scope creep, drift. |
| `/sw:pr` | Open the issue's PR — branch/base, push, PR template, Conventional-Commit title. |
| `/sw:update` | Sync the installed specwright with upstream without clobbering local edits. |

## How the flow works

Every non-trivial change runs through one pipeline. **Design approval is the only human review** — everything after it runs on its own; your other control points are merging the PRs and the circuit-breaker reports.

```mermaid
flowchart TD
    A(["sw:brainstorm — explore + design"]) --> B{"Design approved?"}
    B -- "no, revise" --> A
    B -- yes --> C{"Scope: single issue or milestone?<br/>(agent suggests, you decide)"}
    C -- "single issue" --> D["Batch: branch + worktree + handoff<br/>→ issues/YYYY-MM-DD-slug/issue.md"]
    D --> E["sw:plan — just-in-time spec + tasks<br/>self-reviewed: reviewer subagent +<br/>sw:review-spec + validate-spec.sh"]
    E --> F["Implement → quality gate →<br/>runtime verification (run it for real;<br/>UI via browser or needs-human-verification)"]
    F --> G(["sw:pr + sw:review to lgtm → shipped"])
    C -- milestone --> H["Batch: worktree<br/>→ goal.md + board.md + N issue.md<br/>→ mandatory handoff, planning stops"]
    H --> I["sw:run — the orchestrator loop:<br/>dispatch every ready issue to an owner<br/>(parallel, one worktree each) → each owner<br/>runs the pipeline → learnings feed later issues"]
    I --> G
```

A few things worth knowing:

- **One human gate.** You approve the design — nothing else. The agent reviews its *own* plan (the spec-document-reviewer subagent + `/sw:review-spec` + the `validate-spec.sh` mechanical gate). Design approval is the standing consent to commit, push, open the PR, and review to `lgtm`.
- **Issues everywhere.** The unit of work is one folder — `issue.md` (ticket + `AC-N` + `status:`), `spec.md`, `tasks.md`, optional `learnings.md`, plus any issue-specific artifacts (e.g. `findings.md`, `evidence/`) — identical standalone and inside milestones.
- **Milestones run as a loop.** The orchestrator (`/sw:run`) never touches code: it dispatches issue owners, tracks the live `board.md`, carries curated learnings from shipped issues into later plans, and stops on circuit breakers (three identical failures → `blocked` + a report) instead of thrashing.
- **Runtime verification.** Before any PR, the agent executes what it built and checks each `AC-N` by observed behavior — UI through a browser when the agent has one, otherwise the criterion is marked `needs-human-verification`, never faked.
- **Worktree.** A specwright-native checkout under `.specwright/worktrees/` — default yes; mandatory for parallel milestone dispatch.
- **Handoff.** Fresh context per phase: optional for a standalone issue, mandatory after milestone planning (the planning session never conducts — `/sw:run` resumes from the board in any new session).

## Roles

Every non-trivial change runs through the pipeline as a handful of well-defined **roles**. Four are **spawned** as sub-agents and can each be routed to a specific model (see [Model routing](#model-routing)); the orchestrator is the top-level session you launch.

| Role | Skill | What it does | Spawned by |
|---|---|---|---|
| **orchestrator** | `/sw:run` | Conducts a milestone — reads the board, dispatches issues, tracks, escalates; never touches code | — (it *is* the session you launch) |
| **issue owner** | `/sw:plan` | Owns one issue end to end: plan → implement → gates → runtime verification → PR → review → learnings | the orchestrator (milestone), or it *is* the session (standalone issue) |
| **task worker** | fan-out inside `/sw:plan` | Implements one `Delegable: yes` task and reports findings back; never writes learnings | the issue owner |
| **spec reviewer** | self-review inside `/sw:plan` | Judges whether `spec.md` + `tasks.md` are ready to implement | the issue owner |
| **code reviewer** | `/sw:review` | Three find-only lanes — rubric+conventions, issue-conformance, docs-consistency — merged to `lgtm` | the issue owner |

**Top-level session vs spawned.** The orchestrator (and a standalone issue owner) *is* the session you launched — its model is whatever you started your agent with (`inherit`), and no config changes that. The four spawned roles can each be routed to a specific model.

## Model routing

`.specwright/models.md` routes each **spawned** role to a model — issue owner and reviewers on a strong model, task workers on a cheaper one, say — without editing any skill. It stays **agent-agnostic** through two layers:

- **`Roles → tier`** (policy) — maps each role to a vendor-neutral **tier** (`deep` / `balanced` / `fast`). It names no model, so it is portable across agents.
- **`Bindings`** (mechanism) — one subsection per agent (`### claude`, `### codex`, …) mapping each `tier → model + effort`. Only `claude` ships filled.

A skill about to spawn a role resolves `role → tier → the binding for the agent it is running as`, and spawns on that model. Two rules keep it safe:

- **`model` is live; `effort` is advisory.** The model is applied on the spawn today. The `effort` column is recorded intent — it goes live when the runtime supports per-spawn effort, with no change to the file.
- **No binding → inherit.** A role whose tier has no binding for the current agent — or a repo with no `models.md` at all — runs on the inherited session model. Routing is opt-in and purely additive.

**Extend to another agent** by adding a `### <agent>` subsection under `Bindings` that maps the same tiers to that agent's models. No skill edits are needed — the skills only ever name roles and tiers.

## Customizing

The workflow ships with opinionated defaults — all plain markdown, so change them to fit your team.

Companion skills live in **three kept-in-sync copies**:

- `.agents/skills/sw-<name>/` — canonical, what non-Claude agents read,
- `plugins/sw/skills/<name>/` — the Claude Code plugin copy,
- `skills/sw/scaffold/skills/sw-<name>/` — what new installs receive.

Edit the copy your agent loads. To change what **future** installs get, edit the `scaffold/` copy too — and keep the three in sync.

- **PR conventions (`/sw:pr`)** — title/body format, the draft-vs-ready choice, labels, the PR-template fill, push behavior all live in the `sw-pr` `SKILL.md`. Edit it to change how PRs are opened (e.g. write the body in another language, change the default base branch, or add labels).
- **Review rules (`/sw:review`)** — there are two levers. (1) **Project conventions** the reviewer reads: your installed repo's `.specwright/conventions/` — edit those to change the project-specific standard. (2) **The universal rubric** — the embedded rubric and severity classes (`blocker`/`suggestion`/`nitpick`/`question`), the blocker calibration, and the output format — live in the `sw-review` `SKILL.md` (Unix philosophy + meaningful comments + security are baked in).
- **Orchestration (`/sw:run`)** — the dispatch rules, circuit-breaker thresholds, and closeout behavior live in the `sw-run` `SKILL.md`; the board/goal/issue shapes live in `skills/sw/scaffold/templates/`.
- **The issue-flow steps** — the flow is documented in `AGENTS.md` under `### Issue flow`. To change the steps for an already-installed repo, edit that block; to change what new installs get, edit `### Issue flow` in `skills/sw/references/agents-md-template.md` (keep the two consistent).

## Repository layout

```
specwright/
├── install.sh               # the one-line installer (curl-piped from main)
├── skills/sw/               # the scaffolder skill: SKILL.md, references/, scaffold/, scripts/
├── plugins/sw/              # Claude Code plugin — /sw:* commands (commands/) + companion skills (skills/)
├── .claude-plugin/          # marketplace manifest
├── tests/                   # install smoke tests
├── LICENSE                  # MIT
├── NOTICE.md                # attribution for the two vendored Apache-2.0 scripts
├── CONTRIBUTING.md
├── CODE_OF_CONDUCT.md
├── SECURITY.md
└── README.md
```

The repository also contains `AGENTS.md` (with its `CLAUDE.md` symlink), `.agents/`, `.claude/`, and `.specwright/` — files and dirs used to dogfood specwright on its own development (the entry-point contract, the bundled companion skills, the per-agent symlinks, and the maintainer's spec vault). They are not what the installer puts in your repo.

## License

This repository's original work is licensed under the [MIT License](LICENSE). The two vendored scripts under `skills/sw/scripts/` (`quick_validate.py`, `package_skill.py`) are Apache-2.0; see [`NOTICE.md`](NOTICE.md) for attribution.

## Contributing

Pull requests welcome — see [`CONTRIBUTING.md`](CONTRIBUTING.md) for scope, the quality bar, and the per-PR checklist. By participating, you agree to the [Code of Conduct](CODE_OF_CONDUCT.md). Security concerns go to [`SECURITY.md`](SECURITY.md).
