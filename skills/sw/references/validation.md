# Validation — Phase 5 Checklist

Run this checklist after **any** scaffold or fix run, and at the end of an audit even when nothing was missing. Confirms the specwright install is structurally sound. Each check is a quick command with a clear pass/fail.

Report results as a table. Any `FAIL` triggers an automatic fix attempt using the recipe under each check, then re-runs the validator. The orchestrator does not prompt the user before fixing — it loops until the table is clean or it determines a check cannot be auto-repaired.

> The bundled Python helpers (`scripts/quick_validate.py`, `scripts/package_skill.py`) need **PyYAML**; on a clean machine run them via `uv run --with pyyaml python …` or after `pip install pyyaml`. The bash checks below have no such dependency.

## Contents

- [Output format](#output-format)
- [Checks](#checks) — 11 numbered checks (CLAUDE.md symlink, AGENTS.md placeholder sweep, AGENTS.md headers, AGENTS.md size cap, issue frontmatter, folder naming, bare filenames, canonical skills installed, bundled scripts executable, Claude plugin settings, templates + validator bundled in the skill)
- [When everything passes](#when-everything-passes)
- [When something fails](#when-something-fails)

## Output format

```
## Phase 5 — Validation

| # | Check | Status |
|---|-------|--------|
| 1 | CLAUDE.md symlink resolves to AGENTS.md | PASS |
| 2 | AGENTS.md has no surviving placeholders | FAIL — line 14: "{{Project Name}}" |
| ... | ... | ... |

### Result: 10/11 PASS — 1 FAIL needs attention
```

## Checks

### 1. `CLAUDE.md` symlink resolves to `AGENTS.md`

```bash
[ "$(readlink CLAUDE.md)" = "AGENTS.md" ] && echo PASS || echo FAIL
```

FAIL means `CLAUDE.md` is missing, is a regular file, or points elsewhere. Fix: remove and recreate with `ln -s AGENTS.md CLAUDE.md`.

### 2. `AGENTS.md` has no surviving `{{placeholders}}`

```bash
grep -n '{{' AGENTS.md && echo FAIL || echo PASS
```

FAIL means the scaffold left unsubstituted placeholders. Fix: ask the user for the missing info and patch the lines reported.

### 3. `AGENTS.md` contains all required section headers

```bash
required=(
  "## Workflow Spec Driven"
  "## Coding standard"
  "## Skills and slash commands"
)
missing=()
for h in "${required[@]}"; do
  grep -qF "$h" AGENTS.md || missing+=("$h")
done
[ ${#missing[@]} -eq 0 ] && echo PASS || printf 'FAIL — missing: %s\n' "${missing[@]}"
```

Fix: read `references/agents-md-template.md` and insert the missing sections in the canonical order.

### 4. `AGENTS.md` is at most 80 lines

The file is loaded into every agent session as the entry-point contract. Letting it grow past 80 lines crowds context and reintroduces the "encyclopedia" anti-pattern that the canonical authoring rules explicitly reject. Target range is 45–70 lines.

```bash
lines=$(wc -l < AGENTS.md | tr -d ' ')
[ "$lines" -le 80 ] && echo "PASS ($lines lines)" || echo "FAIL ($lines lines, cap 80)"
```

FAIL means `AGENTS.md` exceeded the cap. Fix: trim the body per the guidance in `references/agents-md-template.md` (`## Size constraint`) — tighten body prose and replace any longer narrative with a one-line pointer into `.specwright/`. Never drop a required section header (check #3 enforces those).

### 5. Issue frontmatter valid

For each `issue.md` under either tree, confirm the file begins with `---` and contains a closing `---` with the expected fields between them.

```bash
for f in .specwright/issues/[0-9]*-*/issue.md .specwright/milestones/[0-9]*-*/issues/*/issue.md; do
  [ -e "$f" ] || continue
  head -1 "$f" | grep -q '^---$' || { echo "FAIL: $f missing opening fence"; continue; }
  awk '/^---$/{n++} n==2{exit} {print}' "$f" | grep -qE '^(feature|status):' \
    || echo "FAIL: $f missing expected frontmatter field"
done
```

Fix: repair the offending issue's frontmatter to open with `---`, close with `---`, and carry `feature:` and `status:` fields.

### 6. Top-level folders carry the date prefix

```bash
{ ls .specwright/issues/ 2>/dev/null; ls .specwright/milestones/ 2>/dev/null; } \
  | grep -vE '^[0-9]{4}-[0-9]{2}-[0-9]{2}-' \
  && echo FAIL || echo PASS
```

FAIL lists the offending folder names. Fix: rename per the migration prompt in `references/audit-checklist.md`. (Issue folders **inside** a milestone's `issues/` are plain slugs by design and are not checked here.)

### 7. Issue folders use bare `issue.md` / `spec.md` / `tasks.md` / `learnings.md`

The folder is the discriminator; a surviving `<type>-<slug>.md` file is drift from before the bare-filename convention.

```bash
bad=$(find .specwright/issues .specwright/milestones -type f \
  \( -name 'issue-*.md' -o -name 'spec-*.md' -o -name 'tasks-*.md' -o -name 'learnings-*.md' \) 2>/dev/null)
[ -z "$bad" ] && echo PASS || { echo "FAIL:"; echo "$bad"; }
```

FAIL lists the offending slug-named paths. Fix: `git mv` each file to its bare name. Issues are self-contained — no link rewriting is needed. Renames are destructive — confirm with the user once per folder before running.

### 8. Skills installed at the canonical location — each has its `SKILL.md`

Skills are canonically under `.agents/skills/<name>/`. Per-agent symlinks (`.codex/skills/<name>`, etc.) are bonus exposure, not the source of truth.

```bash
for s in sw-brainstorm sw-plan sw-pr sw-review sw-run sw-update; do
  [ -f ".agents/skills/$s/SKILL.md" ] && echo "PASS: $s" || echo "FAIL: $s"
done
```

Fix: re-run the skills copy block from `SKILL.md` (Scaffolding section).

### 9. Bundled skill scripts are executable

```bash
fail=0
for f in .agents/skills/sw-brainstorm/scripts/*.sh; do
  [ -e "$f" ] || continue
  [ -x "$f" ] || { echo "FAIL: $f not executable"; fail=1; }
done
[ $fail -eq 0 ] && echo PASS
```

Fix: `chmod +x .agents/skills/sw-brainstorm/scripts/*.sh`.

### 10. Claude plugin settings present (when `.claude/` exists)

Slash commands ship as a Claude Code plugin from the upstream marketplace `specwright`. When the target repo has a `.claude/` directory, `.claude/settings.json` must declare both `extraKnownMarketplaces["specwright"]` (with any non-empty `source` object) and `enabledPlugins["sw@specwright"] = true`. If `.claude/` is absent, this check trivially PASSes — the user does not run Claude Code here, so no settings.json is required.

```bash
if [ ! -d .claude ]; then
  echo PASS
elif [ ! -f .claude/settings.json ]; then
  echo FAIL
else
  has_mp=$(jq 'has("extraKnownMarketplaces") and (.extraKnownMarketplaces | has("specwright"))' .claude/settings.json 2>/dev/null)
  has_src=$(jq '.extraKnownMarketplaces["specwright"].source != null' .claude/settings.json 2>/dev/null)
  has_plugin=$(jq '.enabledPlugins["sw@specwright"] == true' .claude/settings.json 2>/dev/null)
  if [ "$has_mp" = "true" ] && [ "$has_src" = "true" ] && [ "$has_plugin" = "true" ]; then
    echo PASS
  else
    echo FAIL
  fi
fi
```

Fix: re-run the settings.json merge block from `SKILL.md` (Phase 4), which uses the jq recipe in `references/claude-plugin-settings.md`. If `jq` is unavailable, fall back to the Python recipe in the same reference.

### 11. Artifact templates and validator bundled in the skill

The artifact templates and the mechanical issue validator ship **inside this skill**, not in the target vault. Confirm they are present so the brainstorm / plan skills can generate issues and the review step can validate them.

```bash
SW_DIR="<directory where the sw SKILL.md lives>"
fail=0
for t in issue spec tasks goal board; do
  [ -f "$SW_DIR/scaffold/templates/$t.md" ] || { echo "FAIL: missing templates/$t.md"; fail=1; }
done
[ -x "$SW_DIR/scripts/validate-spec.sh" ] || { echo "FAIL: scripts/validate-spec.sh missing or not executable"; fail=1; }
[ $fail -eq 0 ] && echo PASS
```

FAIL means the skill bundle is incomplete. Fix: restore the missing files from upstream (`/sw:update`) — the templates live at `scaffold/templates/{issue,spec,tasks,goal,board}.md` and the validator at `scripts/validate-spec.sh` (`chmod +x` it).

## When everything passes

Report:

```
## Phase 5 — Validation: 11/11 PASS

specwright is structurally sound.
```

## When something fails

Report each FAIL with the specific reason (file path, missing line, parse error), then apply the fixes listed under each check above and re-run validation. Loop until clean. Only stop the loop when a check has no auto-repair recipe or the same fix has failed twice — in that case, surface the residual failure to the user with the exact reason.
