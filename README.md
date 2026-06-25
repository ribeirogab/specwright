# specwright

`specwright` gives any repository an explicit **spec-driven workflow** — every non-trivial change runs through one pipeline: brainstorm → design → spec + tasks → implement → quality gate → PR → review-to-`lgtm`. Agent-agnostic and self-hosting.

---

## Install

From your project root:

```bash
curl -fsSL https://raw.githubusercontent.com/ribeirogab/specwright/main/install.sh | sh
```

This:

- installs the scaffolder skill — `.agents/skills/sw/`, plus the `.claude/skills/sw` symlink, and
- enables the `sw` plugin in `.claude/settings.json`.

Then open the repo in your agent and run `/sw` to audit and scaffold the `.specwright/` vault. The plugin commands (`/sw:spec`, `/sw:new-pr`, …) load once Claude Code trusts the workspace.

## Use

Point an agent at any repo where you want specwright installed:

> "Audit specwright in this repo and scaffold whatever is missing."

The skill is audit-first, autonomous-fix, and safe to re-run. After the first run the repo has a working `.specwright/` vault, the bundled `sw-*` companion skills, the `/sw:*` slash commands, and an `AGENTS.md` — all dogfood-tested by specwright's own validator.

**Source:** [`skills/sw/SKILL.md`](skills/sw/SKILL.md)

## What you get

After install the repo has:

- an **`AGENTS.md`** describing the spec-driven workflow,
- a **`.specwright/` vault** holding just `conventions/` (project-specific conventions) and `specs/` (dated spec folders), and
- a set of **`/sw:*` commands** and companion skills:

| Command | What it does |
|---|---|
| `/sw` | Scaffold or audit specwright in the current repo — set up, verify, or fix. Idempotent. |
| `/sw:brainstorming` | Explore intent and design before any non-trivial change → `design.md`. |
| `/sw:spec` | Turn the current conversation into a spec and enter the flow. |
| `/sw:writing-plans` | Turn an approved design into the technical `spec.md` + `tasks.md`. |
| `/sw:review-spec` | External-evaluator pass over a spec — flags vagueness, scope creep, design drift. |
| `/sw:new-pr` | Open the spec's PR — branch/base, push, PR template, Conventional-Commit title. |
| `/sw:code-review` | Review the branch diff with find-only subagents until `lgtm`. |
| `/sw:update` | Sync the installed specwright with upstream without clobbering local edits. |

## How the flow works

Every non-trivial change runs through one pipeline. **Design approval is the only human review** — everything after it can run on its own.

```mermaid
flowchart TD
    A([sw-brainstorming: explore + design → design.md]) --> B{Design approved?}
    B -- "no, revise" --> A
    B -- yes --> C["Post-design batch:<br/>branch + mode + worktree + handoff?"]
    C --> D[Create branch]
    D --> E["sw-writing-plans: spec + tasks<br/>then self-reviews the spec<br/>spec-document-reviewer + sw:review-spec + validate-spec.sh<br/>both modes — no human spec review"]
    E --> G{handoff?}
    G -- yes --> H["Print txt handoff, then stop<br/>you /compact or open a new chat, paste, resume"]
    G -- no --> K[Implement]
    H --> K
    K --> L[Quality gate]
    L --> N{mode = autonomous?}
    N -- yes --> O["Deliver: sw:new-pr + sw:code-review to lgtm → shipped"]
    N -- "no (reviewed)" --> P{Open the PR and run code-review?}
    P -- yes --> O
```

A few things worth knowing:

- **One human gate.** You approve the design — nothing else. The agent reviews its *own* spec (the spec-document-reviewer subagent + `/sw:review-spec` + the `validate-spec.sh` mechanical gate), in both modes.
- **The post-design batch.** Right after design approval, one batch asks four things: the **branch name**, the **mode**, whether to use a **worktree**, and whether to **hand off**.
- **Two modes.** The mode decides only the **delivery**: `autonomous` opens the PR and runs code-review to `lgtm` on its own; `reviewed` does the same but asks first (*"open the PR and run code-review?"*). It is recorded in the spec and counts as consent to commit/push that feature branch.
- **Worktree.** A specwright-native checkout under `.specwright/worktrees/` — default yes, unless you're already inside a linked worktree.
- **Handoff (either mode).** Once design/spec/tasks are written, the agent prints a handoff prompt so you can `/compact` (or open a new chat) and implement with a clean context.

## Customizing

The workflow ships with opinionated defaults — all plain markdown, so change them to fit your team.

Companion skills live in **three kept-in-sync copies**:

- `.agents/skills/sw-<name>/` — canonical, what non-Claude agents read,
- `plugins/sw/skills/<name>/` — the Claude Code plugin copy,
- `skills/sw/scaffold/skills/sw-<name>/` — what new installs receive.

Edit the copy your agent loads. To change what **future** installs get, edit the `scaffold/` copy too — and keep the three in sync.

- **PR conventions (`/sw:new-pr`)** — title/body format, the draft-vs-ready choice, labels, the PR-template fill, push behavior all live in the `sw-new-pr` `SKILL.md`. Edit it to change how PRs are opened (e.g. write the body in another language, change the default base branch, or add labels).
- **Code-review rules (`/sw:code-review`)** — there are two levers. (1) **Project conventions** the reviewer reads: your installed repo's `.specwright/conventions/` — edit those to change the project-specific standard. (2) **The universal rubric** — the embedded rubric and severity classes (`blocker`/`suggestion`/`nitpick`/`question`), the blocker calibration, and the output format — live in the `sw-code-review` `SKILL.md` (Unix philosophy + meaningful comments + security are baked into code-review now).
- **The spec-flow steps** — the flow is documented in `AGENTS.md` under `### Spec flow`. To change the steps for an already-installed repo, edit that block; to change what new installs get, edit `### Spec flow` in `skills/sw/references/agents-md-template.md` (keep the two consistent). The `autonomous`/`reviewed` switch is wired across the three `sw-brainstorming` `SKILL.md` copies and the spec template's `branch:`/`mode:` fields, so deeper changes to mode behavior touch those too.

## Repository layout

```
specwright/
├── skills/sw/               # the scaffolder skill: SKILL.md, references/, scaffold/, scripts/
├── plugins/sw/              # Claude Code plugin — /sw:* commands (commands/) + companion skills (skills/)
├── .claude-plugin/          # marketplace manifest
├── LICENSE                  # MIT
├── NOTICE.md                # attribution for vendored validator scripts
├── CONTRIBUTING.md
├── CODE_OF_CONDUCT.md
├── SECURITY.md
└── README.md
```

The repository also contains `.agents/`, `.claude/`, and `.specwright/` — local dirs used to dogfood specwright on its own development (the bundled companion skills, the per-agent symlinks, and the maintainer's spec vault). They are not what the installer puts in your repo.

## License

This repository's original work is licensed under the [MIT License](LICENSE). The vendored validator scripts under `skills/sw/scripts/` are Apache-2.0; see [`NOTICE.md`](NOTICE.md) for attribution.

## Contributing

Pull requests welcome — see [`CONTRIBUTING.md`](CONTRIBUTING.md) for scope, the quality bar, and the per-PR checklist. By participating, you agree to the [Code of Conduct](CODE_OF_CONDUCT.md). Security concerns go to [`SECURITY.md`](SECURITY.md).
