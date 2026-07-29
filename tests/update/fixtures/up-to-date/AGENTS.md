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
