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

Read `references/audit-checklist.md` for the full inventory of files and directories to check, the meaning of each status (`OK` / `MISSING` / `DRIFT`), drift criteria for `AGENTS.md` and `vault/constitution.md`, the report format, and special handling for date-prefixed spec folders.

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

This information is required to fill `AGENTS.md` and `vault/constitution.md` without surviving placeholders.

## Phase 4 — Scaffold (only the items that need it)

Create or repair only the items the audit flagged. Never touch files that are already `OK`.

### Vault files

For `.obsidian/*.json`, atomic note templates (`templates/learning.md`, `rule.md`, `convention.md`), spec templates (`_template/spec.md`, `plan.md`, `tasks.md`), and the five MOCs in `_index/`, read `references/vault-files.md` and write each file from the spec there. Use the project name from Prerequisites to substitute `{{Project Name}}` in MOCs.

### Constitution

For `vault/constitution.md`, read `references/constitution-template.md`. It contains the template **and** filling rules — this is the most important file in the vault and must not be left with `{{placeholders}}`. If you don't have enough info to fill a section, ask the user; never commit unsubstituted placeholders.

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
vault/.obsidian/
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
for agent_dir in .claude .codex .cursor .opencode .aider .augment; do
  [ -d "$agent_dir" ] || continue
  mkdir -p "$agent_dir/skills"
  for name in "${SKILL_NAMES[@]}"; do
    target="$agent_dir/skills/$name"
    [ -e "$target" ] && continue   # idempotent: keep whatever's there
    ln -s "../../.agents/skills/$name" "$target"
  done
done
```

**Slash commands** install canonically under `.agents/commands/<cmd>.md` (single source of truth on disk, agent-agnostic location) and are exposed via per-agent symlinks. Slash-command UI is a Claude Code-specific concept today — no other current agent has an equivalent — so the symlink loop targets only `.claude/commands/`. If `.claude/` does not exist in the repo, the canonical files are still installed (they are the source of truth) but no symlinks are created. The workflows the commands encode are useful in any agent; users on other agents invoke them via prose prompts, not via `/foo` syntax.

```bash
COMMAND_NAMES=(memex-learn memex-spec memex-review-spec memex-sweep)

# 1. Canonical install — single source of truth on disk
mkdir -p .agents/commands
for cmd in "${COMMAND_NAMES[@]}"; do
  [ -e ".agents/commands/$cmd.md" ] && continue   # idempotent: don't overwrite
  cp "$MEMEX_DIR/scaffold/commands/$cmd.md" ".agents/commands/$cmd.md"
done

# 2. Per-agent symlinks — only into .claude/ (slash commands are Claude-only).
#    Migration: if a regular file already sits at the symlink target, drop it
#    and replace with a symlink. Policy is "scaffold sempre vence" — no diff,
#    no prompt. Order matters: [ -L ] before [ -f ] because [ -f ] resolves
#    through symlinks on macOS and would otherwise rm a working symlink.
if [ -d .claude ]; then
  mkdir -p .claude/commands
  for cmd in "${COMMAND_NAMES[@]}"; do
    target=".claude/commands/$cmd.md"
    if [ -L "$target" ]; then
      continue                                     # already symlink — leave it
    elif [ -f "$target" ]; then
      rm "$target"                                 # real file → drop (migration)
    fi
    ln -s "../../.agents/commands/$cmd.md" "$target"
  done
fi
```

Rules:
- Skills always go to `.agents/skills/<name>` first (canonical), then symlinked into existing agent dirs.
- Commands always go to `.agents/commands/<cmd>.md` first (canonical), then symlinked into `.claude/commands/` if `.claude/` exists. Slash commands are Claude-only today — no Codex/Cursor equivalent — so the symlink loop is single-agent.
- Existing canonical files are never overwritten — re-runs are no-ops on already-installed items.
- Existing regular files at a command symlink target are removed and replaced with a symlink (migration path). Existing symlinks are left alone.
- Per-agent dirs that do not already exist are not auto-created by the skill copy; only an existing dir signals that agent is in use here.

### Spec folder migration (if drift was reported)

If the audit flagged any spec folder without a `YYYY-MM-DD-` prefix, migrate per the rules in `references/audit-checklist.md` (pull date from the spec file's frontmatter `created:` field, ask user when absent, never rename without confirmation).

### Spec file rename migration (if drift was reported)

If the audit detected a spec folder containing generic `spec.md` / `plan.md` / `tasks.md` files (instead of the `<type>-<slug>.md` convention), migrate the folder. Renaming tracked files is a destructive operation — surface each detected folder, get explicit user confirmation per folder, then run the recipe below.

For each confirmed `<spec_dir>` (e.g. `vault/specs/2026-04-30-opensource-readiness/`):

```bash
spec_dir="<the folder, e.g. vault/specs/2026-04-30-opensource-readiness>"
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
  vault/_index/specs.md && rm vault/_index/specs.md.bak
```

After the recipe runs, also `grep -rln "\[\[spec\]\]\|\[\[plan\]\]\|\[\[tasks\]\]" vault/learnings/ vault/conventions/ vault/rules/` to surface any external wikilinks that might have pointed at the old basenames; update those manually with the user's confirmation (those references are not always intra-spec — they could legitimately mean "the spec template").

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
1. Review vault/constitution.md — make sure it captures your non-negotiables
2. Run the project and start adding learnings to vault/learnings/
3. First feature? Copy vault/specs/_template/ and start a spec
```
