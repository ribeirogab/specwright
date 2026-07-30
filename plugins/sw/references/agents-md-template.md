# AGENTS.md managed template

`sw_update.py` renders this template into the bounded managed block in a project's
canonical instruction file. It owns only that block; text before or after it belongs
to the project and is preserved by the apply phase.

The renderer substitutes `{{version}}` and `{{digest}}` in the opening marker. The
digest is the SHA-256 digest of the exact block body below, after its version token is
rendered. Do not add installation commands here.

```markdown
<!-- sw:managed version={{version}} digest={{digest}} -->
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
```
