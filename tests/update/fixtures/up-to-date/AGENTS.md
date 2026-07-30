<!-- sw:managed version=2026.7.30 digest=bd7eb5084ec236be5ba58363717d12ecc7a3e6b2148cf51ab103907bd54edfb5 -->
# specwright

This repository uses specwright's change-driven engineering workflow.

## Workflow

Use the shared workflow skills to explore, specify, plan, implement, validate, and
review changes. Work that needs a durable design follows the change flow in
`.specwright/`; change artifacts are owned by the change owner.

## Command surfaces

Claude Code exposes the workflow as `/sw:*` commands. Codex exposes the same shared
workflow as `$sw:*` skills. OpenCode exposes the same workflow as `/sw-*` commands.
These are host adapters for the same workflow; use the surface available in the
current host.

## Permissions

Host permissions and sandbox policy remain authoritative. Design approval does not
grant permission to write files, run commands, create branches, commit, push, or
access external services.
<!-- /sw:managed -->
