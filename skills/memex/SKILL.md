---
name: memex
description: "Scaffold or audit the memex (vault + AGENTS.md + spec templates + bundled skills) in any repo — an externalized, navigable project memory for agents (Claude Code, Codex, Cursor, OpenCode, etc.). Agent-agnostic. Idempotent — safe to run repeatedly. Use when the user wants to set up, verify, or fix the memex in a project."
---

# Memex — Idempotent Agent Memory Infrastructure

Set up or audit the memex in the current repo. Safe to run multiple times — it checks what exists, reports what's missing or wrong, asks before making changes, then validates the result.

**Announce at start:** "Auditing memex..."

## Mode of Operation

This skill is **audit-first, then autonomous**. Audit, report, and proceed to scaffold or repair without further prompting. The one exception is destructive operations (renaming or deleting existing files) — surface those before acting.

1. **Audit** — scan the repo and build a checklist of what exists vs what's expected.
2. **Report** — show the checklist to the user with status per item.
3. **Fix** — if issues are found, scaffold or repair them directly. Confirm only before destructive ops (e.g., renaming a spec folder).
4. **Validate** — after any creation or fix (and at the end of an audit-only run), run Phase 5 validation.

If the audit finds nothing wrong **and** validation passes, just say "Memex is healthy." and stop.

## Phase 1 — Audit

Read `references/audit-checklist.md` for the full inventory of files and directories to check, the meaning of each status (`OK` / `MISSING` / `DRIFT`), drift criteria for `AGENTS.md` and `.vault/constitution.md`, the report format, and special handling for date-prefixed spec folders.

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

This information is required to fill `AGENTS.md` and `.vault/constitution.md` without surviving placeholders.

## Phase 4 — Scaffold (only the items that need it)

Create or repair only the items the audit flagged. Never touch files that are already `OK`.

### Vault files

For `.obsidian/*.json`, atomic note templates (`templates/learning.md`, `rule.md`, `convention.md`), spec templates (`_template/spec.md`, `plan.md`, `tasks.md`), and the five MOCs in `_index/`, read `references/vault-files.md` and write each file from the spec there. Use the project name from Prerequisites to substitute `{{Project Name}}` in MOCs.

### Constitution

For `.vault/constitution.md`, read `references/constitution-template.md`. It contains the template **and** filling rules — this is the most important file in the vault and must not be left with `{{placeholders}}`. If you don't have enough info to fill a section, ask the user; never commit unsubstituted placeholders.

### AGENTS.md

For `AGENTS.md` at the repo root, read `references/agents-md-template.md`. Fill `{{Project Name}}`, the project description paragraph, and the `## Commands (most used)` section from Prerequisites. The reference lists all required section headers — none may be missing.

### CLAUDE.md symlink (Claude Code back-compat)

`AGENTS.md` is the universal agent entry point. Claude Code historically reads `CLAUDE.md` instead, so a symlink at the repo root keeps it satisfied without duplicating content. Other agents ignore the file.

If `CLAUDE.md` does not exist at the repo root:

```bash
ln -s AGENTS.md CLAUDE.md
```

### .gitignore additions

Append these lines to the repo's `.gitignore` (skip if already present):

```
# Obsidian vault config (machine-local — Obsidian rewrites these on every open)
.vault/.obsidian/
```

Rationale: Obsidian rewrites `app.json`, `appearance.json`, `core-plugins.json`, and the workspace files every time the vault is opened, which creates constant `git status` noise. The memex installer still **creates** the three config JSONs locally during scaffolding (so `useMarkdownLinks: false` / `newLinkFormat: "relative"` are set the first time Obsidian opens — wikilinks in the MOCs depend on this), but they are not tracked. Obsidian preserves existing user settings when it rewrites these files, so the defaults persist locally on subsequent opens.

### Skills and commands (copy from scaffold/)

All bundled skills and commands live in `scaffold/` alongside this `SKILL.md`.

**Skills** are agent-agnostic and install canonically under `.agents/skills/<name>/` (the open agent skills standard's location, also discoverable by `npx skills` and similar tooling). For each agent-specific discovery directory already present in the repo (`.claude/`, `.codex/`, `.cursor/`, `.opencode/`, `.aider/`, `.augment/`, etc.), the memex installer adds a per-skill symlink so that agent picks up the skill without duplicating files on disk:

```bash
MEMEX_DIR="<directory where this SKILL.md lives>"
SKILL_NAMES=(memex-recall memex-brainstorming memex-writing-plans memex-link)

# 1. Canonical install — single source of truth on disk
mkdir -p .agents/skills
for name in "${SKILL_NAMES[@]}"; do
  [ -e ".agents/skills/$name" ] && continue   # idempotent: don't overwrite
  cp -r "$MEMEX_DIR/scaffold/skills/$name" ".agents/skills/$name"
done

# Ensure scripts are executable (only one skill ships scripts today)
[ -d .agents/skills/memex-brainstorming/scripts ] && \
  chmod +x .agents/skills/memex-brainstorming/scripts/*.sh

# 2. Per-agent symlinks — only into discovery dirs that already exist
#    (do NOT auto-create agent dirs; their absence means the user does
#    not run that agent in this repo).
#
#    Skip .claude/ — Claude Code gets companion skills through the plugin
#    (ribeirogab-agent-skills → memex), invoked as /memex:recall etc.
#    Creating .claude/skills/memex-recall symlinks here would duplicate
#    the skill under both `/memex-recall` (symlink) and `/memex:recall`
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

# Legacy cleanup: remove any pre-plugin .claude/skills/memex-* symlinks that
# earlier memex installs created. Plugin provides /memex:<verb> on Claude now.
if [ -d .claude/skills ]; then
  for name in "${SKILL_NAMES[@]}"; do
    rm -f ".claude/skills/$name" 2>/dev/null
  done
  # Remove .claude/skills/ if now empty
  [ -z "$(ls -A .claude/skills 2>/dev/null)" ] && rmdir .claude/skills
fi
```

**Slash commands** ship as a Claude Code plugin published from the upstream marketplace `ribeirogab-agent-skills` (this repo's root `.claude-plugin/marketplace.json`). The four slash commands — `/memex:spec`, `/memex:learn`, `/memex:sweep`, `/memex:review-spec` — live in `plugins/memex/commands/` upstream and are fetched by Claude Code at workspace-trust time. The memex skill **does not copy command files into the target repo** — it only declares the marketplace and pre-enables the plugin via `.claude/settings.json`.

The skill does two things at install time, both gated on the target repo having a `.claude/` directory (its absence signals the user does not run Claude Code in this repo):

1. **Remove legacy command files** that pre-plugin memex installs left behind: `.claude/commands/memex-{spec,learn,sweep,review-spec}.md` and `.agents/commands/memex-{spec,learn,sweep,review-spec}.md`. This is a non-destructive op per the existing "scaffold sempre vence" policy — no prompt, no diff. `rm` works for both regular files and symlinks.
2. **Merge marketplace + plugin entries** into `.claude/settings.json`. Read `references/claude-plugin-settings.md` for the canonical coordinates, the JSON shapes, the jq merge recipe (preferred), and the Python fallback.

```bash
# 1. Remove legacy command files for the four affected verbs.
#    rm works for files and symlinks alike. Missing files are not an error.
for cmd in memex-spec memex-learn memex-sweep memex-review-spec; do
  rm -f ".claude/commands/$cmd.md" 2>/dev/null
  rm -f ".agents/commands/$cmd.md" 2>/dev/null
done

# Also remove the .agents/commands/ directory if it is now empty (only the four
# legacy files lived there; if anything else is present, leave it alone).
if [ -d .agents/commands ] && [ -z "$(ls -A .agents/commands 2>/dev/null)" ]; then
  rmdir .agents/commands
fi

# 2. Merge marketplace + plugin entries into .claude/settings.json — only when
#    .claude/ exists in the target repo. Read references/claude-plugin-settings.md
#    for the canonical coordinates, JSON shapes, jq recipe, and Python fallback.
if [ -d .claude ]; then
  # Detect dogfood: if this repo's own .claude-plugin/marketplace.json declares
  # name = "ribeirogab-agent-skills", use the local-path source. Otherwise use github.
  if [ -f .claude-plugin/marketplace.json ] && \
     [ "$(jq -r '.name' .claude-plugin/marketplace.json 2>/dev/null)" = "ribeirogab-agent-skills" ]; then
    MARKETPLACE_SOURCE='{"source":"directory","path":"."}'
  else
    MARKETPLACE_SOURCE='{"source":"github","repo":"ribeirogab/agent-skills"}'
  fi

  SETTINGS=".claude/settings.json"
  TMP="$(mktemp)"
  if [ -s "$SETTINGS" ]; then
    cp "$SETTINGS" "$TMP"
  else
    echo '{}' > "$TMP"
  fi

  jq --argjson src "$MARKETPLACE_SOURCE" '
    .extraKnownMarketplaces["ribeirogab-agent-skills"] = { "source": $src } |
    .enabledPlugins["memex@ribeirogab-agent-skills"] = true
  ' "$TMP" > "$SETTINGS"
  rm "$TMP"
fi
```

If `jq` is not installed, fall back to the Python recipe documented in `references/claude-plugin-settings.md`. The skill must never overwrite `.claude/settings.json` wholesale — unrelated top-level keys must survive intact.

Rules:
- Skills always go to `.agents/skills/<name>` first (canonical), then symlinked into existing agent dirs.
- Slash commands ship as a Claude Code plugin from the upstream marketplace `ribeirogab-agent-skills`. The skill writes `.claude/settings.json` (extraKnownMarketplaces + enabledPlugins) so Claude Code installs the plugin at workspace-trust time. No command files are copied into the target repo.
- Existing canonical skill files are never overwritten — re-runs are no-ops on already-installed items.
- Legacy `.claude/commands/memex-{spec,learn,sweep,review-spec}.md` and `.agents/commands/memex-*.md` files (from pre-plugin installs) are removed unconditionally on every run. `rm` works for regular files and symlinks.
- Per-agent dirs that do not already exist are not auto-created by the skill copy; only an existing dir signals that agent is in use here.
- `.claude/settings.json` is created if absent (with `{}` as the seed) or merged into if present — every unrelated top-level key survives.

### Spec folder migration (if drift was reported)

If the audit flagged any spec folder without a `YYYY-MM-DD-` prefix, migrate per the rules in `references/audit-checklist.md` (pull date from the spec file's frontmatter `created:` field, ask user when absent, never rename without confirmation).

### Spec file rename migration (if drift was reported)

If the audit detected a spec folder containing generic `spec.md` / `plan.md` / `tasks.md` files (instead of the `<type>-<slug>.md` convention), migrate the folder. Renaming tracked files is a destructive operation — surface each detected folder, get explicit user confirmation per folder, then run the recipe below.

For each confirmed `<spec_dir>` (e.g. `.vault/specs/2026-04-30-opensource-readiness/`):

```bash
spec_dir="<the folder, e.g. .vault/specs/2026-04-30-opensource-readiness>"
slug=$(basename "$spec_dir" | sed 's/^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]-//')

# 1. Rename each generic file to include the slug, preserving git history
for type in spec plan tasks; do
  src="$spec_dir/${type}.md"
  dst="$spec_dir/${type}-${slug}.md"
  [ -f "$src" ] && [ ! -e "$dst" ] && git mv "$src" "$dst"
done

# 2. Update internal wikilinks inside every file in the folder
#    [[spec]] / [[plan]] / [[tasks]] → [[<type>-<slug>]]
for f in "$spec_dir"/*.md; do
  sed -i.bak \
    -e "s/\\[\\[spec\\]\\]/[[spec-${slug}]]/g" \
    -e "s/\\[\\[plan\\]\\]/[[plan-${slug}]]/g" \
    -e "s/\\[\\[tasks\\]\\]/[[tasks-${slug}]]/g" \
    "$f" && rm "$f.bak"
done

# 3. Update the specs MOC entry that pointed at the old basename
folder=$(basename "$spec_dir")
sed -i.bak \
  -e "s|/${folder}/spec\\([|\\]]\\)|/${folder}/spec-${slug}\\1|g" \
  -e "s|/${folder}/plan\\([|\\]]\\)|/${folder}/plan-${slug}\\1|g" \
  -e "s|/${folder}/tasks\\([|\\]]\\)|/${folder}/tasks-${slug}\\1|g" \
  .vault/_index/specs.md && rm .vault/_index/specs.md.bak
```

After the recipe runs, also `grep -rln "\[\[spec\]\]\|\[\[plan\]\]\|\[\[tasks\]\]" .vault/learnings/ .vault/conventions/ .vault/rules/` to surface any external wikilinks that might have pointed at the old basenames; update those manually with the user's confirmation (those references are not always intra-spec — they could legitimately mean "the spec template").

Note for the `sed` `-e` line: `[|\\]]` is a character class matching `|` or `]` — this scopes the replacement to wikilink edges so we do not match `<folder>/spec-tweaks.md` or other longer paths that happen to start with `spec`.

## Phase 5 — Validate

After **any** creation or fix run, and at the end of an audit-only run with all `OK`, execute the validation checklist.

Read `references/validation.md` and run all 15 checks. Report results as the table specified there. If any check fails, surface the specific reason and ask "Want me to fix the failed checks?" Loop until clean or the user stops.

Validation is non-negotiable — this is what catches `{{placeholders}}` that survived scaffolding, missing AGENTS.md sections, broken symlinks, malformed JSON, and spec folders that slipped past the rename step.

## Final summary (always show at the end)

```
## Memex Audit Complete

- X/Y items OK
- N created, M fixed, K skipped (already correct)
- Validation: 15/15 PASS  (or list the FAILs)

{{only if first-time setup:}}
Next steps:
1. Review .vault/constitution.md — make sure it captures your non-negotiables
2. Run the project and start adding learnings to .vault/learnings/
3. First feature? Copy .vault/specs/_template/ and start a spec
```
