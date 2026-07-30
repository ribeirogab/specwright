# Validation — Project State

Run after `sw:init` or `sw:update`. Validation is evidence, not an independent
repair engine: do not mutate managed state outside the updater.

## Output format

```text
## specwright Validation

| # | Check | Status |
|---|---|---|
| 1 | updater classification | PASS — up-to-date |
| ... | ... | ... |

Result: 8/8 PASS
```

## Checks

### 1. Read-only plan is stable

```bash
python3 "$SW_PLUGIN_ROOT/scripts/sw_update.py" \
  --plan --project "$PWD" --mode "$MODE" --format json
```

Require `state: up-to-date`, zero operations, and no diagnostics. Run it twice and
require the same `plan_id`. Any other state is a failure; do not auto-repair drift.

### 2. Canonical instructions and managed digest are valid

Resolve:

```bash
if [ "$MODE" = local ]; then
  CANONICAL=AGENTS.override.md
  ADAPTER=CLAUDE.local.md
else
  CANONICAL=AGENTS.md
  ADAPTER=CLAUDE.md
fi
```

The canonical path must be a regular file with exactly one opening
`<!-- sw:managed version=... digest=... -->` marker and one
`<!-- /sw:managed -->` marker. The updater's `up-to-date` classification proves
that the digest matches the body and the installed version.

Project-authored text outside the block has no required heading, size, or host
installation phrase.

### 3. Claude adapter is the exact relative symlink

```bash
[ -L "$ADAPTER" ] || exit 1
[ "$(readlink "$ADAPTER")" = "$CANONICAL" ] || exit 1
```

A regular-file copy is a failure even when bytes match.

### 4. Codex role profiles match installed templates

```bash
for name in \
  sw-issue-owner \
  sw-spec-document-reviewer \
  sw-reviewer \
  sw-task-worker
do
  cmp \
    "$SW_PLUGIN_ROOT/templates/codex-agents/$name.toml" \
    ".codex/agents/$name.toml"
done
```

All four destinations must be regular files. Unrelated `.codex` content must be
unchanged.

### 5. Ignore rules match the selected mode

Shared mode requires exactly:

```text
.specwright/worktrees/
```

Local mode requires exactly:

```text
.specwright/worktrees/
.specwright/
AGENTS.override.md
CLAUDE.local.md
.codex/agents/sw-*.toml
```

Each required line occurs once. Preserve unrelated project rules. Local mode may
coexist with project-owned shared instructions and must not alter them.

### 6. Vault directories survive the selected mode

```bash
test -d .specwright/conventions
test -n "$(find .specwright/conventions -mindepth 1 -maxdepth 1 -type f -print -quit)"
test -f .specwright/issues/.gitkeep
test -f .specwright/milestones/.gitkeep
```

An initially empty conventions directory receives the signpost; an existing
directory keeps its own convention files instead. Never overwrite existing
conventions, issues, milestones, or their artifacts.

### 7. Package surfaces remain host-equivalent

From the plugin repository:

```bash
claude plugin validate --strict plugins/sw
bash tests/install/run.sh package init
bash tests/release/run.sh
```

The source and installed inventories contain the same nine shared skills, and all
nine Claude command files remain pure redirects. Native Codex ingestion runs only
in an isolated environment with `CI_EPHEMERAL_RUNNER=1`.

### 8. Active task topology is schema 2

For every active issue with `tasks.md`, run the issue validator. Require unique
stable IDs, existing acyclic dependencies, mandatory metadata, explicit isolated
file ownership and validation, and no same-wave overlap between independent
isolated tasks.

A shipped historical issue may retain legacy tasks as history. An active legacy
task file is a blocking diagnostic and must be explicitly replanned; neither init
nor update may infer its topology.

## Failure handling

- `new` or `legacy-migratable`: show the ordered plan and complete `plan_id`, then
  ask for explicit apply confirmation.
- `drifted`: show all diagnostics and stop without writes.
- identity mismatch: produce a new read-only plan and obtain new confirmation.
- unsupported symlink, invalid parent, or changed profile source: stop; there is
  no copy or overwrite fallback.
- vault-only missing keep-file: `sw:init` may create it without overwriting
  existing vault content after managed state is accepted or already healthy.
