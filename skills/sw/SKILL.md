---
name: sw
description: "Scaffold or audit specwright (AGENTS.md + spec-driven workflow + bundled skills) in any repo — an explicit spec-driven workflow for agents (Claude Code, Codex, Cursor, OpenCode, etc.). Agent-agnostic. Idempotent — safe to run repeatedly. Use when the user wants to set up, verify, or fix specwright in a project."
---

# specwright — Idempotent Spec-Driven Workflow

Set up or audit specwright in the current repo. Safe to run multiple times — it checks what exists, reports what's missing or wrong, asks before making changes, then validates the result.

**Announce at start:** "Auditing specwright..."

## Mode of Operation

This skill is **audit-first, then autonomous**. Audit, report, and proceed to scaffold or repair without further prompting. The one exception is destructive operations (renaming or deleting existing files) — surface those before acting.

1. **Audit** — scan the repo and build a checklist of what exists vs what's expected.
2. **Report** — show the checklist to the user with status per item.
3. **Fix** — if issues are found, scaffold or repair them directly. Confirm only before destructive ops.
4. **Validate** — after any creation or fix (and at the end of an audit-only run), run Phase 5 validation.

If the audit finds nothing wrong **and** validation passes, just say "specwright is healthy." and stop.

## Phase 1 — Audit

Read `references/audit-checklist.md` for the full inventory of files and directories to check, the meaning of each status (`OK` / `MISSING` / `DRIFT`), drift criteria for `AGENTS.md`, the report format, and special handling for date-prefixed spec folders.

Apply each check, then assemble the report described in that reference.

## Phase 2 — Report

Render the audit table per the format in `references/audit-checklist.md`. Summarize:

```
### Summary
- X/Y items OK
- N missing, M drifted
```

If anything is missing or drifted, proceed to Phase 3. If everything was `OK`, skip to Phase 5 (validation).

## Phase 3 — Prerequisites (first-time or fix)

Before creating files, gather project context:

1. Read `package.json`, `README.md`, or any existing docs to understand what the project is.
2. Detect the package manager (`pnpm-workspace.yaml` → pnpm, `yarn.lock` → yarn, `bun.lockb` → bun, else npm).
3. Detect the tech stack (frameworks, languages, deploy targets) from dependencies and config files.

This information is required to fill `AGENTS.md` without surviving placeholders.

## Phase 4 — Scaffold (only the items that need it)

Create or repair only the items the audit flagged. Never touch files that are already `OK`.

### Vault directories

specwright's per-repo vault is `.specwright/` and holds exactly two living things:

- `.specwright/conventions/` — project-specific code/style conventions (populated by you over time).
- `.specwright/specs/` — one dated folder per spec (`YYYY-MM-DD-<slug>/` with `design.md` + `spec.md` + `tasks.md`).

Ensure both directories exist (an empty `conventions/` is fine on first install). The spec **templates** are not scaffolded into the vault — they ship with this skill under `scaffold/spec-templates/` and the brainstorming / writing-plans skills generate specs from there. The spec **validator** ships with this skill under `scripts/validate-spec.sh`; it is not copied into the vault either.

### AGENTS.md

For `AGENTS.md` at the repo root, read `references/agents-md-template.md`. Fill `{{Project Name}}` and `{{project}}` from Prerequisites; the `### Spec flow` and section structure are fixed. The reference lists all required section headers — none may be missing, and the final file must stay ≤ 80 lines.

### CLAUDE.md symlink (Claude Code back-compat)

`AGENTS.md` is the universal agent entry point. Claude Code historically reads `CLAUDE.md` instead, so a symlink at the repo root keeps it satisfied without duplicating content. Other agents ignore the file.

If `CLAUDE.md` does not exist at the repo root:

```bash
ln -s AGENTS.md CLAUDE.md
```

### .gitignore additions

Append this line to the repo's `.gitignore` (skip if already present):

```
# specwright per-spec worktrees (machine-local checkouts)
.specwright/worktrees/
```

### Skills and commands (copy from scaffold/)

All bundled skills live in `scaffold/skills/` alongside this `SKILL.md`.

**Skills** are agent-agnostic and install canonically under `.agents/skills/<name>/` (the open agent skills standard's location, also discoverable by `npx skills` and similar tooling). For each agent-specific discovery directory already present in the repo (`.codex/`, `.cursor/`, `.opencode/`, `.aider/`, `.augment/`, etc.), specwright adds a per-skill symlink so that agent picks up the skill without duplicating files on disk:

```bash
SW_DIR="<directory where this SKILL.md lives>"
SKILL_NAMES=(sw-brainstorming sw-writing-plans sw-new-pr sw-code-review sw-update)

# 1. Canonical install — single source of truth on disk
mkdir -p .agents/skills
for name in "${SKILL_NAMES[@]}"; do
  [ -e ".agents/skills/$name" ] && continue   # idempotent: don't overwrite
  cp -r "$SW_DIR/scaffold/skills/$name" ".agents/skills/$name"
done

# Ensure bundled skill scripts are executable
[ -d .agents/skills/sw-brainstorming/scripts ] && \
  chmod +x .agents/skills/sw-brainstorming/scripts/*.sh

# 2. Per-agent symlinks — only into discovery dirs that already exist
#    (do NOT auto-create agent dirs; their absence means the user does
#    not run that agent in this repo).
#
#    Skip .claude/ — Claude Code gets companion skills through the plugin
#    (sw → specwright), invoked as /sw:brainstorming etc.
#    Creating .claude/skills/sw-brainstorming symlinks here would duplicate
#    the skill under both `/sw-brainstorming` (symlink) and `/sw:brainstorming`
#    (plugin) in Claude Code's slash menu.
for agent_dir in .codex .cursor .opencode .aider .augment; do
  [ -d "$agent_dir" ] || continue
  mkdir -p "$agent_dir/skills"
  for name in "${SKILL_NAMES[@]}"; do
    target="$agent_dir/skills/$name"
    [ -e "$target" ] && continue   # idempotent: keep whatever's there
    ln -s "../../.agents/skills/$name" "$target"
  done
done

# Legacy cleanup: remove any pre-plugin .claude/skills/sw-* symlinks that
# earlier installs created. Plugin provides /sw:<verb> on Claude now.
if [ -d .claude/skills ]; then
  for name in "${SKILL_NAMES[@]}"; do
    rm -f ".claude/skills/$name" 2>/dev/null
  done
  # Remove .claude/skills/ if now empty
  [ -z "$(ls -A .claude/skills 2>/dev/null)" ] && rmdir .claude/skills
fi
```

**Slash commands** ship as a Claude Code plugin published from the upstream marketplace `specwright` (this repo's root `.claude-plugin/marketplace.json`). The slash commands — `/sw:spec`, `/sw:review-spec` — live in `plugins/sw/commands/` upstream and are fetched by Claude Code at workspace-trust time. The skill **does not copy command files into the target repo** — it only declares the marketplace and pre-enables the plugin via `.claude/settings.json`.

The skill does two things at install time, both gated on the target repo having a `.claude/` directory (its absence signals the user does not run Claude Code in this repo):

1. **Remove legacy command files** that earlier installs left behind: `.claude/commands/sw-{spec,review-spec}.md` and `.agents/commands/sw-{spec,review-spec}.md`. This is a non-destructive op — no prompt, no diff. `rm` works for both regular files and symlinks.
2. **Merge marketplace + plugin entries** into `.claude/settings.json`. Read `references/claude-plugin-settings.md` for the canonical coordinates, the JSON shapes, the jq merge recipe (preferred), and the Python fallback.

```bash
# 1. Remove legacy command files.
#    rm works for files and symlinks alike. Missing files are not an error.
for cmd in sw-spec sw-review-spec; do
  rm -f ".claude/commands/$cmd.md" 2>/dev/null
  rm -f ".agents/commands/$cmd.md" 2>/dev/null
done

# Also remove the .agents/commands/ directory if it is now empty.
if [ -d .agents/commands ] && [ -z "$(ls -A .agents/commands 2>/dev/null)" ]; then
  rmdir .agents/commands
fi

# 2. Merge marketplace + plugin entries into .claude/settings.json — only when
#    .claude/ exists in the target repo. Read references/claude-plugin-settings.md
#    for the canonical coordinates, JSON shapes, jq recipe, and Python fallback.
if [ -d .claude ]; then
  # Detect dogfood: if this repo's own .claude-plugin/marketplace.json declares
  # name = "specwright", use the local-path source. Otherwise use github.
  if [ -f .claude-plugin/marketplace.json ] && \
     [ "$(jq -r '.name' .claude-plugin/marketplace.json 2>/dev/null)" = "specwright" ]; then
    MARKETPLACE_SOURCE='{"source":"directory","path":"."}'
  else
    MARKETPLACE_SOURCE='{"source":"github","repo":"ribeirogab/specwright"}'
  fi

  SETTINGS=".claude/settings.json"
  TMP="$(mktemp)"
  if [ -s "$SETTINGS" ]; then
    cp "$SETTINGS" "$TMP"
  else
    echo '{}' > "$TMP"
  fi

  jq --argjson src "$MARKETPLACE_SOURCE" '
    .extraKnownMarketplaces["specwright"] = { "source": $src } |
    .enabledPlugins["sw@specwright"] = true
  ' "$TMP" > "$SETTINGS"
  rm "$TMP"
fi
```

If `jq` is not installed, fall back to the Python recipe documented in `references/claude-plugin-settings.md`. The skill must never overwrite `.claude/settings.json` wholesale — unrelated top-level keys must survive intact.

Rules:
- Skills always go to `.agents/skills/<name>` first (canonical), then symlinked into existing agent dirs.
- Slash commands ship as a Claude Code plugin from the upstream marketplace `specwright`. The skill writes `.claude/settings.json` (extraKnownMarketplaces + enabledPlugins) so Claude Code installs the plugin at workspace-trust time. No command files are copied into the target repo.
- Existing canonical skill files are never overwritten — re-runs are no-ops on already-installed items.
- Legacy `.claude/commands/sw-{spec,review-spec}.md` and `.agents/commands/sw-*.md` files are removed unconditionally on every run. `rm` works for regular files and symlinks.
- Per-agent dirs that do not already exist are not auto-created by the skill copy; only an existing dir signals that agent is in use here.
- `.claude/settings.json` is created if absent (with `{}` as the seed) or merged into if present — every unrelated top-level key survives.

### Spec folder dating (if drift was reported)

If the audit flagged a spec folder without a `YYYY-MM-DD-` prefix, rename it to add the date (pull the date from the spec file's frontmatter `created:` field; ask the user when absent). Renaming tracked files is a destructive operation — surface each detected folder and get explicit user confirmation before renaming. Specs are self-contained (no cross-references between them), so a folder rename needs no link rewriting.

## Phase 5 — Validate

After **any** creation or fix run, and at the end of an audit-only run with all `OK`, execute the validation checklist.

Read `references/validation.md` and run all its checks. Report results as the table specified there. If any check fails, surface the specific reason and ask "Want me to fix the failed checks?" Loop until clean or the user stops.

Validation is non-negotiable — this is what catches `{{placeholders}}` that survived scaffolding, missing AGENTS.md sections, broken symlinks, malformed JSON, and spec folders that slipped past the dating step.

## Final summary (always show at the end)

```
## specwright Audit Complete

- X/Y items OK
- N created, M fixed, K skipped (already correct)
- Validation: all PASS  (or list the FAILs)

{{only if first-time setup:}}
Next steps:
1. Review AGENTS.md — make sure the spec flow and project context fit your team
2. Add project-specific conventions to .specwright/conventions/ as you establish them
3. First feature? Run /sw:spec (or /sw:brainstorming) to start a spec
```
