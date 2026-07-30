---
name: init
user-invocable: false
description: "Initialize specwright's project state in shared or local mode: scaffold the .specwright vault, create canonical AGENTS instructions with Claude symlinks, install the four Codex role profiles and the thirteen OpenCode agent and command files, and add only the required ignore rules. Uses the deterministic updater and refuses drift. Trigger on '/sw:init', '$sw:init', '/sw-init', 'set up specwright here', or 'initialize specwright in this repo'."
---

# Init — set up specwright project state

Initialize the current repository for the same specwright workflow across every
supported host. The plugin already provides every workflow skill; this command
creates only project-scoped content:

- the `.specwright/` vault;
- canonical AGENTS instructions and the Claude adapter symlink;
- four `.codex/agents/sw-*.toml` role profiles;
- four `.opencode/agent/sw-*.md` role profiles and nine `.opencode/command/sw-*.md` redirects;
- the exact ignore rules required by the selected mode.

Never install or enable a plugin, edit personal host configuration, copy skill bodies,
or create `.claude/settings.json`.

**Announce at start:** "Setting up specwright's project state..."

## 1. Resolve the installed plugin root

Resolve `SW_PLUGIN_ROOT` before any project write:

1. Use `PLUGIN_ROOT` when it names a directory containing
   `.codex-plugin/plugin.json`.
2. Otherwise use `CLAUDE_PLUGIN_ROOT` when it names a directory containing
   `.claude-plugin/plugin.json`.
3. Otherwise derive it from this loaded file's real path: the plugin root is two
   parents above `skills/init/SKILL.md`.

Require these files beneath the result:

```text
.codex-plugin/plugin.json
scripts/sw_update.py
templates/codex-agents/sw-change-owner.toml
templates/codex-agents/sw-spec-document-reviewer.toml
templates/codex-agents/sw-reviewer.toml
templates/codex-agents/sw-task-worker.toml
templates/opencode-agents/sw-change-owner.md
templates/opencode-agents/sw-spec-document-reviewer.md
templates/opencode-agents/sw-reviewer.md
templates/opencode-agents/sw-task-worker.md
templates/opencode-commands/sw-init.md
templates/opencode-commands/sw-brainstorm.md
templates/opencode-commands/sw-spec.md
templates/opencode-commands/sw-plan.md
templates/opencode-commands/sw-run.md
templates/opencode-commands/sw-review.md
templates/opencode-commands/sw-review-spec.md
templates/opencode-commands/sw-pr.md
templates/opencode-commands/sw-update.md
```

If the root or any required file cannot be resolved, stop before writing and report
the missing path. Do not search remote branches or fetch anything.

## 2. Ask for the project mode

Always ask, including on re-runs:

- **shared** — track `.specwright/`, `AGENTS.md`, `CLAUDE.md -> AGENTS.md`,
  the four `.codex/agents/sw-*.toml` profiles, and the four
  `.opencode/agent/sw-*.md` profiles and nine `.opencode/command/sw-*.md`
  redirects. Ignore only `.specwright/worktrees/`.
- **local** — keep specwright private in this checkout. Use
  `AGENTS.override.md`, `CLAUDE.local.md -> AGENTS.override.md`, the local vault,
  the four role profiles, and the OpenCode agent and command files. Ignore exactly
  `.specwright/worktrees/`, `.specwright/`, `AGENTS.override.md`,
  `CLAUDE.local.md`, `.codex/agents/sw-*.toml`, `.opencode/agent/sw-*.md`, and
  `.opencode/command/sw-*.md`.

Existing project-owned `AGENTS.md`, `CLAUDE.md`, and unrelated `.codex/` files are
valid in local mode and must remain byte-for-byte unchanged. Present paths already
on disk as context, but never infer permission to switch modes or remove tracked
content.

## 3. Build and inspect a read-only plan

Run:

```bash
python3 "$SW_PLUGIN_ROOT/scripts/sw_update.py" \
  --plan \
  --project "$PWD" \
  --mode "<shared-or-local>" \
  --format json
```

This command must complete before the vault is scaffolded. Display:

- `state`, `version`, and `mode`;
- every diagnostic;
- every ordered operation;
- the complete `plan_id`.

Interpret the state:

- `new` — safe to initialize after confirmation;
- `legacy-migratable` — an exact recognized installation can be migrated after
  confirmation;
- `up-to-date` — no managed operation is required;
- `drifted` — stop without writing anything and show the updater diagnostics.

Do not repair drift manually, overwrite a conflicting file, copy instead of
symlinking, or invent a replacement plan.

## 4. Confirm and apply the exact identity

For `new` or `legacy-migratable`, ask one explicit question that includes the mode,
the ordered operations, and the full `plan_id`:

> Apply this exact specwright plan `<plan_id>`?

Only an explicit affirmative response authorizes the apply. Refusal ends the
command without writes. Host sandbox, command, and external-action approval policy
remains authoritative; this confirmation does not override it.

Apply exactly the displayed identity:

```bash
python3 "$SW_PLUGIN_ROOT/scripts/sw_update.py" \
  --apply \
  --expect-plan "<displayed-plan-id>" \
  --project "$PWD" \
  --mode "<same-mode>" \
  --format json
```

If identity verification, preflight, symlink probing, or a write fails, stop and
print the updater diagnostic verbatim. Never retry with a newly computed identity
without displaying it and obtaining a new explicit confirmation.

For `up-to-date`, skip apply and continue to the vault check.

## 5. Scaffold the vault

Only after the managed-state plan is accepted or already up to date, ensure:

```text
.specwright/
├── conventions/
├── changes/
└── deliveries/
```

Create `.gitkeep` in empty `changes/` and `deliveries/`. When `conventions/` has no
files, create `README.md` with this signpost:

```markdown
# About this folder — signpost, not a convention

`sw:review` reads every other file in `.specwright/conventions/` as a project
standard it must enforce. This file intentionally states no rule. Delete it when
the project adds its first convention.

Keep one project-specific convention per file: code style, naming, architecture,
testing, domain rules, review preferences, or any other durable standard.
```

Never overwrite or remove existing vault content. The updater has already installed
the correct ignore rules for local mode.

## Verify

Run the checks in `references/validation.md`, plus all of these:

1. The canonical AGENTS file is a regular file with one valid
   `sw:managed` block.
2. The Claude adapter is a relative symlink to that canonical file.
3. All four `.codex/agents/sw-*.toml` files byte-match the installed templates.
4. All four `.opencode/agent/sw-*.md` and nine `.opencode/command/sw-*.md` files
   byte-match the installed templates.
5. Shared mode ignores only `.specwright/worktrees/` from specwright-managed
   state; local mode ignores all seven exact local patterns.
6. Unrelated `.codex` configuration and project-authored instructions are
   unchanged.
7. A second read-only plan reports `up-to-date` with zero operations.

Report the mode and managed paths created. Do not stage or commit them unless the
user separately authorizes Git actions.
