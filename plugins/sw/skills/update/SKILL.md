---
name: update
user-invocable: false
description: "Plan and apply a versioned specwright project migration for Claude Code and Codex. Reads the installed Codex manifest version, displays a deterministic plan and plan_id, requires explicit confirmation, and applies only that unchanged identity. Refuses drift and never fetches a remote branch. Trigger on '/sw:update', '$sw:update', or 'update specwright in this repo'."
---

# Update — migrate managed project state

Update only specwright-managed project state: the bounded block in the canonical
AGENTS file, the Claude adapter symlink, the four project-scoped Codex profiles,
and exact specwright ignore rules. Preserve every project-owned byte outside the
managed block and every unrelated `.codex` file.

**Announce at start:** "Planning the specwright project update..."

## 1. Resolve the installed plugin root

Resolve `SW_PLUGIN_ROOT` exactly as the init skill does:

1. `PLUGIN_ROOT` with `.codex-plugin/plugin.json`;
2. otherwise `CLAUDE_PLUGIN_ROOT` with `.claude-plugin/plugin.json`;
3. otherwise two parents above this loaded `skills/update/SKILL.md`.

Require `.codex-plugin/plugin.json` and `scripts/sw_update.py`. Stop before any
project write if either is missing. The installed Codex manifest is the only target
version source. Never inspect, fetch, or compare a remote `main` branch.

## 2. Resolve the established mode

Use an explicit `shared` or `local` argument when supplied. Otherwise:

- choose `local` when `AGENTS.override.md` or `CLAUDE.local.md` exists;
- choose `shared` when `AGENTS.md` or `CLAUDE.md` exists;
- if neither mode has an entry point, ask the user;
- if both modes contain specwright-managed entry points, stop and request one
  explicit mode rather than guessing.

Local mode may coexist with project-owned shared instructions; do not modify them.

## 3. Produce the read-only plan

Run:

```bash
python3 "$SW_PLUGIN_ROOT/scripts/sw_update.py" \
  --plan \
  --project "$PWD" \
  --mode "<resolved-mode>" \
  --format json
```

Display all of the following before asking for approval:

- classification: `new`, `legacy-migratable`, `up-to-date`, or `drifted`;
- installed target `version` and selected `mode`;
- diagnostics;
- every ordered operation with its path;
- the complete `plan_id`.

`--plan` is read-only. If it reports `drifted`, stop with its diagnostics and do
not offer an overwrite. If it reports `up-to-date`, report that no migration is
needed and stop.

## 4. Require explicit confirmation

For `new` or `legacy-migratable`, ask:

> Apply exactly plan `<plan_id>` in `<mode>` mode with the operations shown above?

Proceed only after an explicit affirmative response. A general design approval,
earlier Git authorization, or permission from another host is not confirmation of
this update. Host sandbox and command approval policy remains authoritative.

## 5. Apply only the displayed plan

Pass the unchanged displayed identity:

```bash
python3 "$SW_PLUGIN_ROOT/scripts/sw_update.py" \
  --apply \
  --expect-plan "<displayed-plan-id>" \
  --project "$PWD" \
  --mode "<same-mode>" \
  --format json
```

Never call `--apply` without `--expect-plan`, substitute a fresh ID silently, or
continue after a failure. When the project changed after confirmation, show the
identity-mismatch diagnostic, produce a new read-only plan, and request a new
explicit confirmation before any retry.

## 6. Verify

Run `--plan` again with the same project and mode. Success requires:

- state `up-to-date`;
- zero operations;
- one canonical AGENTS regular file and the correct relative Claude symlink;
- four profiles that byte-match the installed templates;
- no change to project-owned instructions or unrelated `.codex` configuration.

Report the applied paths and target version. Do not stage, commit, push, or change a
pull request unless the user separately authorizes those Git actions.
