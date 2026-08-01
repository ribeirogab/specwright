# specwright — Agent Instructions

Instructions for AI coding assistants and developers working on the specwright
codebase.

**Never give up on the right solution.**

This repo builds and ships specwright (a markdown + shell skill repo, no build
pipeline) and dogfoods its own workflow.

## specwright

This repository uses specwright for change-driven work. The vault is
`.specwright/`: changes in `changes/`, deliveries in `deliveries/`, project
conventions in `conventions/`.

- For feature work, suggest `/sw:change` to the user instead of starting the
  workflow yourself. Do not implement a feature without offering it first.
- While a change is in progress, read its `change.md` and `plan.md` before
  touching the code it covers.
- A trivial change needs no artifacts. Edit the code directly.
- Verification — tests, lint, typecheck, build — runs at the `implement` or
  `ship` step, or when the user asks for it. After a direct edit outside the
  workflow, stop and report what changed and what was left unverified; do not
  run gates on your own initiative.

Host surfaces: `/sw:*` in Claude Code, `$sw:*` in Codex. Host permissions and
sandbox policy remain authoritative; nothing here grants permission to write
files, run commands, create branches, commit, push, or reach a network service.

## The ladder

Five steps, each its own command, each stopping and naming the next:

```text
change → plan → implement → pr → review
```

`ship` runs all five without stopping and records its decisions in `change.md`.
`delivery` decomposes a large outcome and conducts one owner per change.

Each change carries exactly two artifacts: `change.md` (why, `AC-N`, decisions)
and `plan.md` (architecture, tasks). `plan.md` is written to be executed by an
agent with no memory of the conversation that produced it — that constraint is
what makes model-switching and cross-session handoff work, and it is enforced by
`plugins/sw/scripts/validate-change.sh`.

## Editing the bundled skills

Every skill's `SKILL.md` lives exactly **once**, under
`plugins/sw/skills/<name>/` — no copy to keep in sync. Each is paired with a thin
redirect under `plugins/sw/commands/`. Edit the `SKILL.md` for behavior; the
command rarely changes. Templates live under `plugins/sw/templates/`, the
scaffolder and validators under `plugins/sw/scripts/`, and references under
`plugins/sw/references/`.

A skill description says **when the skill is invoked**. It never instructs the
model to run the workflow on its own initiative — that auto-dispatch is precisely
what this design removed.

The stable role identities are `sw-change-owner` and `sw-reviewer`. Their Claude
manifests live under `plugins/sw/agents/` and their Codex profiles under
`plugins/sw/templates/codex-agents/`; both preload their workflow skill.
