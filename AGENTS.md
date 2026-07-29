# specwright — Agent Instructions

Instructions for AI coding assistants and developers working on the specwright codebase.

**Never give up on the right solution.**

This repo builds and ships specwright (a markdown + shell skill repo, no build pipeline) and dogfoods the issue-driven workflow on itself.

<!-- sw:managed version=2026.7.28 digest=817541586297fe96f9514fa0ac988fcd97650e6a4681717f89eb7774f5697549 -->
# specwright

This repository uses specwright's issue-driven engineering workflow.

## Workflow

Use the shared workflow skills to explore, specify, plan, implement, validate, and
review changes. Work that needs a durable design follows the issue flow in
`.specwright/`; issue artifacts are owned by the issue owner.

## Command surfaces

Claude Code exposes the workflow as `/sw:*` commands. Codex exposes the same shared
workflow as `$sw:*` skills. These are host adapters for the same workflow; use the
surface available in the current host.

## Permissions

Host permissions and sandbox policy remain authoritative. Design approval does not
grant permission to write files, run commands, create branches, commit, push, or
access external services.
<!-- /sw:managed -->

### Editing the bundled skills

Every companion skill's `SKILL.md` lives exactly **once**, under `plugins/sw/skills/<name>/` — no copy to keep in sync. Each companion skill is `user-invocable: false` (hidden from the `/` menu) and paired with a thin command at `plugins/sw/commands/<name>.md` that only reads and runs the skill's `SKILL.md`; that pairing is what makes every entry point surface as `/sw:<name>` in the picker (never a bare `/<name>`). Edit the `SKILL.md` for behavior — the command is a pure redirect and rarely changes. The artifact templates live at `plugins/sw/templates/`, the mechanical validator at `plugins/sw/scripts/validate-spec.sh`, and the reference docs at `plugins/sw/references/`. The bundled role subagents — `issue-owner`, `task-worker`, `spec-document-reviewer`, `reviewer` — live at `plugins/sw/agents/`, each pinning its `model` + `effort` and preloading (via `skills:`) the skill it runs.