# Audit Checklist

Inventory for `sw:init` and `sw:update`. Both hosts share the same per-repository
state. The updater, not ad-hoc edits, decides whether managed state can be created
or migrated.

## Status meanings

- `OK` — the observed state exactly matches the selected mode and installed
  version.
- `MISSING` — the project is new and the deterministic plan can create the item.
- `LEGACY` — every legacy byte matches a recognized Claude-only installation and
  can be migrated.
- `DRIFT` — a managed path, digest, link, profile, mode, or ignore rule differs
  from a recognized shape. Stop; do not overwrite it.

## Read-only classification

Resolve the installed plugin root and run:

```bash
python3 "$SW_PLUGIN_ROOT/scripts/sw_update.py" \
  --plan \
  --project "$PWD" \
  --mode "<shared-or-local>" \
  --format json
```

The plan must report `state`, installed `version`, selected `mode`, diagnostics,
ordered operations, and the complete `plan_id`. It performs no writes and never
fetches or compares remote `main`.

Map states as follows:

- `new` → `MISSING`;
- `legacy-migratable` → `LEGACY`;
- `up-to-date` → `OK`;
- `drifted` → `DRIFT`.

Only `new` and `legacy-migratable` may be applied, and only after explicit
confirmation of the exact displayed `plan_id`. `up-to-date` needs no apply.
`drifted` has no automatic repair.

## Shared-mode inventory

```text
AGENTS.md                                  regular canonical file
CLAUDE.md -> AGENTS.md                     relative symlink
.codex/agents/sw-issue-owner.toml
.codex/agents/sw-spec-document-reviewer.toml
.codex/agents/sw-reviewer.toml
.codex/agents/sw-task-worker.toml          byte-matched installed profiles
.specwright/conventions/README.md          clone-survival signpost
.specwright/issues/.gitkeep
.specwright/milestones/.gitkeep
.gitignore                                 exactly .specwright/worktrees/
```

The canonical file has exactly one bounded `sw:managed` block. Its opening marker
contains the installed calendar version and SHA-256 digest of the exact block body.
Project-owned text before and after the block is unconstrained and preserved.

## Local-mode inventory

```text
AGENTS.override.md                         regular canonical file
CLAUDE.local.md -> AGENTS.override.md      relative symlink
.codex/agents/sw-*.toml                    four byte-matched profiles
.specwright/                               same three vault directories
.gitignore:
  .specwright/worktrees/
  .specwright/
  AGENTS.override.md
  CLAUDE.local.md
  .codex/agents/sw-*.toml
```

Existing project-owned `AGENTS.md`, `CLAUDE.md`, and unrelated `.codex` files may
coexist in local mode and must remain byte-for-byte unchanged.

## Path and content checks

For every audit:

1. Verify the canonical AGENTS path is a regular file, not a symlink.
2. Verify the Claude adapter is a relative symlink to that exact canonical
   filename.
3. Verify one opening marker, one closing marker, and a valid body digest.
4. Verify all four profile files are regular files and byte-match the installed
   templates.
5. Verify exact ignore membership without deleting unrelated project rules.
6. Verify the vault keep-files without overwriting existing conventions or issue
   content.
7. Verify no opposite-mode managed state creates ambiguity.
8. Re-run `--plan`; a healthy project is `up-to-date` with zero operations.

Symlink probing is a required preflight. If the filesystem cannot create the
relative link, report `DRIFT`/failure clearly; never substitute a copied file.

## Report format

```text
## specwright Audit

State: up-to-date
Version: YYYY.M.D
Mode: shared
Plan ID: <complete-plan-id>

| Status | Item | Detail |
|---|---|---|
| OK | AGENTS.md | managed digest valid; project text preserved |
| OK | CLAUDE.md | relative symlink to AGENTS.md |
| OK | .codex/agents/sw-*.toml | four installed profiles match |
| OK | .specwright/ | three vault directories present |
| OK | .gitignore | exact mode rules present once |
```

For `DRIFT`, include every updater diagnostic and stop without writes. For an
applicable plan, display every operation and request exact-plan confirmation
before calling `--apply`.
