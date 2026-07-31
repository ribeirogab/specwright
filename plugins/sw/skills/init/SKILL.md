---
name: init
user-invocable: false
description: "Use when explicitly invoked to set up specwright in a repository: scaffold the .specwright vault, add the specwright section to the canonical AGENTS instructions with its Claude symlink, install the two Codex role profiles, and add the ignore rules for the chosen mode. Idempotent — re-running it is the upgrade. Trigger on '/sw:init', '$sw:init', 'set up specwright here', or 'initialize specwright in this repo'."
---

# init — set up specwright in this repository

The plugin already provides every workflow skill. This command creates only
project-scoped content, and only what is missing:

- the `.specwright/` vault;
- a `## specwright` section in the canonical AGENTS instructions, plus the Claude
  adapter symlink;
- the two `.codex/agents/sw-*.toml` role profiles;
- the ignore rules for the chosen mode.

It never installs or enables a plugin, edits personal host configuration, copies
skill bodies, or creates `.claude/settings.json`.

**Announce at start:** "Setting up specwright..."

## 1. Resolve the plugin root

Resolve `SW_PLUGIN_ROOT` before any project write:

1. use `PLUGIN_ROOT` when it contains `.codex-plugin/plugin.json`;
2. otherwise use `CLAUDE_PLUGIN_ROOT` when it contains `.claude-plugin/plugin.json`;
3. otherwise derive it from this loaded `skills/init/SKILL.md` real path — the
   plugin root is two parents above the `skills/init/` directory.

Require `scripts/sw_init.py` and both `templates/codex-agents/sw-*.toml` beneath
that root. Stop before writing if resolution fails, and report the missing path.
Never look for bundled resources inside the target repository.

## 2. Pick the mode

Ask once, unless `$ARGUMENTS` already says `shared` or `local`:

- **shared** — specwright state is versioned with the project. Tracks
  `.specwright/`, `AGENTS.md`, `CLAUDE.md -> AGENTS.md`, and the two Codex
  profiles. Ignores only `.specwright/worktrees/`. Pick this for your own repo.
- **local** — specwright state stays private to this checkout. Uses
  `AGENTS.override.md`, `CLAUDE.local.md -> AGENTS.override.md`, and ignores the
  whole vault, both instruction paths, and the profiles. Pick this for a repo you
  cannot or would rather not commit workflow artifacts to.

The canonical instruction file is always the `AGENTS*` path; the `CLAUDE*` path is
only a compatibility symlink, never the source of truth.

## 3. Run the scaffolder

```bash
python3 "$SW_PLUGIN_ROOT/scripts/sw_init.py" \
  --project "$PWD" \
  --mode "<shared-or-local>"
```

It reports every path as `created`, `updated`, or `present`, and writes nothing
that already exists. Show its output.

A **conflict** — reported with a non-zero exit and nothing written — means a path
exists in a shape specwright cannot use, most often a `CLAUDE.md` that is a
regular file where the adapter symlink belongs. Relay the conflict verbatim and
let the maintainer decide; never move, delete, or overwrite their file to clear
it, and never fall back to copying a file where a symlink is required.

## 4. Verify

```bash
python3 "$SW_PLUGIN_ROOT/scripts/sw_init.py" --project "$PWD" --mode "<mode>"
```

A second run must report every path as `present` and create nothing. Then confirm:

- the canonical AGENTS file is a regular file containing one `## specwright` section;
- the Claude adapter is a relative symlink to it (`readlink` returns the bare filename);
- `.specwright/` holds `conventions/`, `changes/`, and `deliveries/`;
- in local mode, `git check-ignore` reports the vault, both instruction paths, and
  the profiles as ignored, while unrelated project files are not.

## Then

Report the mode and the paths created. Do not stage or commit them unless the
maintainer separately authorizes Git actions.

The two `.codex/agents/sw-*.toml` profiles are the only way to give Codex its
roles — a plugin cannot supply them, so they are written per repository even
though their content never varies. In Codex, they also stay inert until the
maintainer enables the subagent feature, which ships disabled: mention
`codex features enable multi_agent_v2` when reporting on a machine that has
Codex. Without it the roles simply never spawn, and `sw:delivery` and
`sw:review` run their passes inline instead.

Say what comes next: **`/sw:change`** (`$sw:change` in Codex) turns a conversation
into a change. The `## specwright` section now tells this repository's agents to
offer that command rather than starting the workflow on their own.
