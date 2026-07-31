# Validation — project state

Run after `sw:init`. Validation is evidence, not a repair engine: it reports, it
does not fix.

## Output format

```text
## specwright Validation

| # | Check | Status |
|---|---|---|
| 1 | scaffolder is idempotent | PASS |
| ... | ... | ... |

Result: 6/6 PASS
```

## Checks

### 1. The scaffolder is idempotent

```bash
python3 "$SW_PLUGIN_ROOT/scripts/sw_init.py" --project "$PWD" --mode "$MODE"
```

A second run must report every path as `present`, create nothing, and exit 0. A
`CONFLICT` line means a path exists in a shape specwright cannot use; nothing was
written, and resolving it is the maintainer's call.

### 2. Canonical instructions carry the section

```bash
if [ "$MODE" = local ]; then
  CANONICAL=AGENTS.override.md
  ADAPTER=CLAUDE.local.md
else
  CANONICAL=AGENTS.md
  ADAPTER=CLAUDE.md
fi

grep -c '^## specwright$' "$CANONICAL"
```

The canonical path is a regular file containing exactly one `## specwright`
heading. Everything else in that file belongs to the project — the scaffolder
appends the section once and never touches the file again, so there is no digest
to verify and no drift to detect.

### 3. The Claude adapter is the exact relative symlink

```bash
[ -L "$ADAPTER" ] || exit 1
[ "$(readlink "$ADAPTER")" = "$CANONICAL" ] || exit 1
```

A regular-file copy is a failure even when the bytes match.

### 4. Codex role profiles are installed

```bash
for name in sw-change-owner sw-reviewer; do
  test -f ".codex/agents/$name.toml"
done
```

Both must be regular files. A profile whose content differs from the bundled
template is reported as `present (differs from template)` and left alone — an
edited profile is the maintainer's, not drift. Unrelated `.codex` content must be
unchanged.

### 5. Ignore rules match the mode

Shared mode requires exactly one specwright line:

```text
.specwright/worktrees/
```

Local mode requires exactly five:

```text
.specwright/worktrees/
.specwright/
AGENTS.override.md
CLAUDE.local.md
.codex/agents/sw-*.toml
```

Each occurs once; unrelated project rules are preserved. Local mode may coexist
with project-owned shared instructions and must not alter them.

### 6. The vault survives

```bash
test -d .specwright/conventions
test -f .specwright/changes/.gitkeep
test -f .specwright/deliveries/.gitkeep
```

An initially empty `conventions/` receives the signpost; a directory that already
holds conventions keeps them.

## Package surfaces

From the plugin repository:

```bash
claude plugin validate --strict plugins/sw
bash tests/install/run.sh
bash tests/validate-change/run.sh
bash tests/release/run.sh
```

The source and installed inventories contain the same eight skills, and all eight
Claude command files remain pure redirects. Native Codex ingestion runs only in an
isolated environment with `CI_EPHEMERAL_RUNNER=1`.

## Change artifacts

For any change with a plan, run the handoff gate:

```bash
"$SW_PLUGIN_ROOT/scripts/validate-change.sh" .specwright/changes/<folder>
```

It answers one question — can an agent with no conversation context implement
this? — across six checks: `change.md` frontmatter and status enum, `plan.md`
frontmatter with a named branch, surviving placeholders, vague acceptance-criteria
verbs, `AC-N` traceability in both directions, and task metadata.
