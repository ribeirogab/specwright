# Audit Checklist

Full inventory of what the specwright audit checks. The orchestrator (`SKILL.md`) loads this file at the start of an audit run.

## Contents

- [Status meanings](#status-meanings)
- [Files and directories to check](#files-and-directories-to-check)
- [Additional checks](#additional-checks)
- [AGENTS.md drift detection (required headers + size cap)](#agentsmd-drift-detection-required-headers--size-cap)
- [Frontmatter sanity](#frontmatter-sanity)
- [Report format](#report-format)

## Status meanings

For each item, check existence and content correctness. Report status as:
- `OK` — exists and looks correct
- `MISSING` — doesn't exist at all
- `DRIFT` — exists but content has diverged from expected structure (e.g., malformed spec frontmatter, missing required headers in `AGENTS.md`, a non-date-prefixed spec folder)

## Files and directories to check

```
.specwright/
  .specwright/conventions/    (directory exists)
  .specwright/issues/         (directory exists — holds dated YYYY-MM-DD-<slug>/ issue folders)
  .specwright/milestones/     (directory exists — holds dated YYYY-MM-DD-<slug>/ milestone folders)

AGENTS.md                      (repo root — self-contained issue flow, ≤ 80 lines)
CLAUDE.md                      (symlink → AGENTS.md, Claude Code back-compat)

.agents/skills/sw-brainstorm/  (full directory — design exploration → issue/milestone artifacts)
.agents/skills/sw-plan/        (full directory — the issue pipeline: spec + tasks to delivery)
.agents/skills/sw-pr/          (full directory — opens the issue's PR)
.agents/skills/sw-review/      (full directory — branch review to lgtm)
.agents/skills/sw-run/         (full directory — the milestone orchestrator)
.agents/skills/sw-update/      (full directory — reconciles the install against upstream)

.gitignore                     (contains .specwright/worktrees/)
```

The artifact **templates** (`issue.md` / `spec.md` / `tasks.md` / `goal.md` / `board.md` blueprints) and the mechanical issue **validator** are **not** scaffolded into the vault — they ship with this skill (under `scaffold/templates/` and `scripts/validate-spec.sh`) and are checked by Phase 5 validation, not by this inventory.

### Per-agent skill symlinks (optional, not required) — non-Claude only

For every **non-Claude** agent-specific discovery directory present in the repo (`.codex/`, `.cursor/`, `.opencode/`, `.aider/`, `.augment/`, etc.), each scaffold skill above should also be symlinked into that agent's `skills/` subdirectory so the agent can discover it. Example: when `.codex/` exists, `.codex/skills/sw-brainstorm` is a symlink to `../../.agents/skills/sw-brainstorm`.

**Claude Code is excluded from this loop.** Claude users get the companion skills through the `specwright` plugin (marketplace `specwright`), invoked as `/sw:brainstorm`, `/sw:plan`, `/sw:pr`, `/sw:review`, `/sw:run`, `/sw:update`. Creating `.claude/skills/sw-<name>` symlinks here would surface the same skill twice in `/help` — once as `/sw-brainstorm` (hyphen-form symlink) and once as `/sw:brainstorm` (plugin namespace). Legacy `.claude/skills/sw-<name>` symlinks from pre-plugin installs are detected as `DRIFT` and removed by Phase 4 (`rm` works for symlinks).

A missing per-agent symlink is **not `DRIFT`** — only the canonical files under `.agents/skills/` are required. If a per-agent dir exists but lacks the expected symlinks, the specwright installer re-creates them on the next run (no prompt needed; symlinks are non-destructive). If a per-agent dir does not exist at all, no symlinks are created (the absence signals the user does not run that agent in this repo).

## Additional checks

### Legacy command files to remove (pre-plugin migration)

The pre-plugin specwright installed slash commands as files at:

- `.agents/commands/sw-{spec,review-spec}.md` (canonical)
- `.claude/commands/sw-{spec,review-spec}.md` (symlink)

These are obsolete — slash commands now ship as a Claude Code plugin from the upstream marketplace `specwright`. Any of these files (regular or symlink) is `DRIFT`. Fix: `rm` the file in Phase 4. This is a non-destructive op — no prompt.

If `.agents/commands/` becomes empty after the removals, the directory itself is also removed (`rmdir` succeeds only on empty dirs, so this is safe even if an unrelated file still sits there).

### Claude plugin settings present (when `.claude/` exists)

When the target repo has a `.claude/` directory (signal that the user runs Claude Code in this repo), `.claude/settings.json` must declare:

- `extraKnownMarketplaces["specwright"]` with a non-empty `source` object (either `{ "source": "github", "repo": "ribeirogab/specwright" }` for target repos, or `{ "source": "directory", "path": "." }` for this repo's own dogfood).
- `enabledPlugins["sw@specwright"]` set to `true`.

Detection:

```bash
if [ -d .claude ]; then
  if [ ! -f .claude/settings.json ]; then
    echo "DRIFT — .claude/settings.json missing"
  else
    has_mp=$(jq 'has("extraKnownMarketplaces") and (.extraKnownMarketplaces | has("specwright"))' .claude/settings.json)
    has_plugin=$(jq '.enabledPlugins["sw@specwright"] == true' .claude/settings.json)
    if [ "$has_mp" != "true" ] || [ "$has_plugin" != "true" ]; then
      echo "DRIFT — settings.json missing marketplace or plugin entry"
    fi
  fi
fi
```

If `.claude/` is absent, this check does not run (no signal to gate on). Fix in Phase 4: run the jq merge recipe from `references/claude-plugin-settings.md`.

### CLAUDE.md is a symlink (Claude Code back-compat)

`AGENTS.md` is the universal agent entry point. Claude Code historically reads `CLAUDE.md` instead, so the specwright installer keeps a `CLAUDE.md → AGENTS.md` symlink at the repo root as a back-compat concession. Other agents ignore the file.

`CLAUDE.md` must be a symlink pointing to `AGENTS.md` — not a copy, not a separate file. Verify with `readlink CLAUDE.md` returning `AGENTS.md`. If it is a regular file or points elsewhere, status is `DRIFT`.

### Top-level folder naming follows `YYYY-MM-DD-<kebab-slug>/`

Actively scan `.specwright/issues/` and `.specwright/milestones/` — any top-level folder whose name does **not** start with `YYYY-MM-DD-` is `DRIFT`. Report each non-conforming folder and ask the user, per folder:

> "`<old-name>/` is not date-prefixed. Date prefixes prevent the naming conflicts that numeric prefixes (`01-`, `02-`) cause when multiple issues land in parallel. Rename to `<YYYY-MM-DD>-<slug>/`?"

Pull the date from the folder's `issue.md` (or `goal.md`) frontmatter `created:` field when present; if absent, ask the user. Issues are self-contained — a folder rename needs no cross-reference rewriting. **Never rename without confirmation.**

Issue folders **inside** a milestone's `issues/` are exempt: they use plain slugs by design (order lives on the board). A date or number prefix there is the `DRIFT`, not the absence of one.

### Issue file naming follows bare `issue.md` / `spec.md` / `tasks.md` / `learnings.md`

Inside any issue folder, the files use **bare** names. The folder is the discriminator. A slug-named file — `spec-<slug>.md`, `issue-<slug>.md`, `tasks-<slug>.md` — inside a real issue folder is `DRIFT` from before the bare-filename convention.

**Detection** (run during the audit pass, alongside the date-prefix check):

```bash
find .specwright/issues .specwright/milestones -type f \
  \( -name 'issue-*.md' -o -name 'spec-*.md' -o -name 'tasks-*.md' -o -name 'learnings-*.md' \) 2>/dev/null \
  | while read -r f; do
      type="${f##*/}"; type="${type%%-*}"
      echo "DRIFT: $f → should be $type.md"
    done
```

Report each drift with the source path and the target name. Issues are self-contained, so the fix is a plain rename — `git mv "$f" "$(dirname "$f")/$type.md"` — with no link rewriting. Renaming a tracked file is a destructive operation per the SKILL.md "Mode of Operation" — confirm with the user once per issue folder before applying.

## AGENTS.md drift detection (required headers + size cap)

`AGENTS.md` must contain all of these section headers — missing any one is `DRIFT`:

- `## Workflow Spec Driven`
- `## Coding standard`
- `## Skills and slash commands`

When reporting drift, name the missing section(s) explicitly so the fix step knows what to insert.

`AGENTS.md` must also be **≤ 80 lines** (target range 45–70). The file is loaded into every agent session as the entry-point contract; growing past this cap crowds context and reintroduces the "encyclopedia" anti-pattern that the canonical authoring rules reject. If `AGENTS.md` exceeds 80 lines, status is `DRIFT` and the fix is to trim the body per the guidance in `references/agents-md-template.md` (`## Size constraint`) — never by dropping a required section header.

## Frontmatter sanity

Each issue's `issue.md` must begin with valid YAML frontmatter (between `---` fences) with the expected `feature:` and `status:` fields (`status:` one of `pending|in-progress|shipped|blocked`). Missing or malformed frontmatter is `DRIFT`.

## Report format

```
## specwright Audit

| Status | Item |
|--------|------|
| OK     | AGENTS.md |
| MISSING| .specwright/conventions/ |
| DRIFT  | .specwright/issues/old-feature/ (not date-prefixed) |
| DRIFT  | AGENTS.md (missing section: "## Coding standard") |
| ...    | ... |

### Summary
- X/Y items OK
- N missing, M drifted
```

After rendering this report, the orchestrator proceeds directly to Phase 3 to fix any `MISSING` or `DRIFT` items — no mid-run confirmation. Spec-folder renames (a destructive op) are the only exception and require an explicit prompt per the migration rules above. If everything passes, the orchestrator skips Phase 3 and runs Phase 5 validation (see `references/validation.md`) before reporting "specwright is healthy."
