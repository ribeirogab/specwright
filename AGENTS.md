# specwright — Agent Instructions

Instructions for AI coding assistants and developers working on the specwright codebase.

**Never give up on the right solution.**

This repo builds and ships specwright (a markdown + shell skill repo, no build pipeline) and dogfoods the change-driven workflow on itself.

<!-- sw:managed version=2026.7.29 digest=7258e63478a9ee574890baa9287257ad76cea4c4e9f5f21e27c1e307385e9f5b -->
# specwright

This repository uses specwright's change-driven engineering workflow.

## Workflow

Use the shared workflow skills to explore, specify, plan, implement, validate, and
review changes. Work that needs a durable design follows the change flow in
`.specwright/`; change artifacts are owned by the change owner.

## Command surfaces

Claude Code exposes the workflow as `/sw:*` commands. Codex exposes the same shared
workflow as `$sw:*` skills. These are host adapters for the same workflow; use the
surface available in the current host.

## Permissions

Host permissions and sandbox policy remain authoritative. Design approval does not
grant permission to write files, run commands, create branches, commit, push, or
access external services.
<!-- /sw:managed -->

The dogfooded vault follows the canonical flat layout: changes live in
`.specwright/changes/`, deliveries (goal + board) in `.specwright/deliveries/`.

### Editing the bundled skills

Every companion skill's `SKILL.md` lives exactly **once**, under
`plugins/sw/skills/<name>/` — no copy to keep in sync. Each companion skill is
paired with a thin redirect under `plugins/sw/commands/`. Edit the `SKILL.md` for
behavior; the command rarely changes. Templates live under `plugins/sw/templates/`,
the mechanical validator under `plugins/sw/scripts/`, and references under
`plugins/sw/references/`. The stable role identities are `sw-change-owner`,
`sw-task-worker`, `sw-spec-document-reviewer`, and `sw-reviewer`. Their Claude
manifests live under `plugins/sw/agents/`; only the owner and branch reviewer
preload their workflow skill.
