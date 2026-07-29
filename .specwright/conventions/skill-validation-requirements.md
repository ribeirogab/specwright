---
tags:
  - rule
  - workflow
severity: important
applies-to:
  - plugins/sw/skills/<name>/SKILL.md
created: 2026-04-30
---
# Skill validation requirements

A shared skill must be discoverable from the same `plugins/sw/skills/` source by
both host adapters. Validation failures block release even when one host happens to
accept the file.

## Folder and file

- The folder name is kebab-case: lowercase letters, digits, and single hyphens.
- The folder name matches the frontmatter `name`.
- The entry file is exactly `SKILL.md`.
- A skill folder contains no `README.md`; supporting material belongs in
  `references/` or another explicitly bundled resource.
- Workflow behavior lives only in `SKILL.md`. The homonymous Claude command is a
  pure redirect, and the Codex manifest points at the shared skills root.

## Frontmatter

Required:

- `name`: non-empty, at most 64 characters, kebab-case, no leading/trailing or
  repeated hyphen.
- `description`: non-empty, at most 1024 characters, no XML angle brackets, and
  describes both behavior and triggers.

Allowed optional top-level keys:

- `license`
- `compatibility` (at most 500 characters)
- `allowed-tools`
- `metadata`
- `user-invocable` (boolean only)

Any other top-level key is rejected. Nested custom data belongs under `metadata`.

## Dual-host behavior

- User-facing syntax in a shared skill is host-neutral or names both valid
  surfaces: `/sw:*` for Claude Code and `$sw:*` for Codex.
- Bundled templates and scripts resolve from the installed plugin root, never from
  a presumed `plugins/sw/` directory in the consumer repository.
- Operational role dispatch uses the stable `sw-*` names shared by Claude agent
  manifests and Codex project profiles.
- Design approval never overrides host permission or approval policy.

## Required checks

```bash
UV_CACHE_DIR=/tmp/specwright-uv-cache \
  uv run --offline --with PyYAML \
  python plugins/sw/scripts/quick_validate.py plugins/sw/skills/<name>

UV_CACHE_DIR=/tmp/specwright-uv-cache \
  uv run --offline --with PyYAML \
  python plugins/sw/scripts/package_skill.py plugins/sw/skills/<name> /tmp

claude plugin validate --strict plugins/sw
```

Package-surface changes also run `bash tests/install/run.sh` and the dual-host
release smoke test.
