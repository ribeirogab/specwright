# Validation — Phase 5 Checklist

Run this checklist after **any** scaffold or fix run, and at the end of an audit even when nothing was missing. Confirms the specwright install is structurally sound. Each check is a quick command with a clear pass/fail.

Report results as a table. Any `FAIL` triggers an automatic fix attempt using the recipe under each check, then re-runs the validator. The orchestrator does not prompt the user before fixing — it loops until the table is clean or it determines a check cannot be auto-repaired.

> The bundled Python helpers (`scripts/quick_validate.py`, `scripts/package_skill.py`) need **PyYAML**; on a clean machine run them via `uv run --with pyyaml python …` or after `pip install pyyaml`. The bash checks below have no such dependency.

## Contents

- [Output format](#output-format)
- [Checks](#checks) — 11 numbered checks (CLAUDE.md symlink, AGENTS.md placeholder sweep, AGENTS.md headers, AGENTS.md size cap, spec frontmatter, spec folder naming, spec-file bare naming, canonical skills installed, bundled scripts executable, Claude plugin settings, spec templates + validator bundled in the skill)
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

### 5. Spec frontmatter valid

For each `spec.md` under a dated spec folder, confirm the file begins with `---` and contains a closing `---` with at least one expected field (`feature:` or `status:`) between them.

```bash
for f in .specwright/specs/[0-9]*-*/spec.md; do
  [ -e "$f" ] || continue
  head -1 "$f" | grep -q '^---$' || { echo "FAIL: $f missing opening fence"; continue; }
  awk '/^---$/{n++} n==2{exit} {print}' "$f" | grep -qE '^(feature|status):' \
    || echo "FAIL: $f missing expected frontmatter field"
done
```

Fix: repair the offending spec's frontmatter to open with `---`, close with `---`, and carry a `feature:` or `status:` field.

### 6. `.specwright/specs/` contains no folder without date prefix

```bash
ls .specwright/specs/ 2>/dev/null | grep -vE '^[0-9]{4}-[0-9]{2}-[0-9]{2}-' \
  && echo FAIL || echo PASS
```

FAIL lists the offending folder names. Fix: rename per the migration prompt in `references/audit-checklist.md`.

### 7. Spec folders use bare `spec.md` / `design.md` / `tasks.md`

Inside any date-prefixed spec folder, the files use **bare** names — `spec.md`, `design.md`, `tasks.md`. The dated folder is the discriminator. A surviving `<type>-<slug>.md` file is drift from before the bare-filename convention.

```bash
bad=$(find .specwright/specs -type f \( -name 'spec-*.md' -o -name 'design-*.md' -o -name 'tasks-*.md' \) 2>/dev/null)
[ -z "$bad" ] && echo PASS || { echo "FAIL:"; echo "$bad"; }
```

FAIL lists the offending slug-named paths. Fix: `git mv` each file to its bare name (`spec.md` / `design.md` / `tasks.md`). Specs are self-contained — no link rewriting is needed. Renames are destructive — confirm with the user once per folder before running.

### 8. Skills installed at the canonical location — each has its `SKILL.md`

Skills are canonically under `.agents/skills/<name>/`. Per-agent symlinks (`.codex/skills/<name>`, etc.) are bonus exposure, not the source of truth.

```bash
for s in sw-brainstorming sw-writing-plans sw-new-pr sw-code-review sw-update; do
  [ -f ".agents/skills/$s/SKILL.md" ] && echo "PASS: $s" || echo "FAIL: $s"
done
```

Fix: re-run the skills copy block from `SKILL.md` (Scaffolding section).

### 9. Bundled skill scripts are executable

```bash
fail=0
for f in .agents/skills/sw-brainstorming/scripts/*.sh; do
  [ -e "$f" ] || continue
  [ -x "$f" ] || { echo "FAIL: $f not executable"; fail=1; }
done
[ $fail -eq 0 ] && echo PASS
```

Fix: `chmod +x .agents/skills/sw-brainstorming/scripts/*.sh`.

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

### 11. Spec templates and validator bundled in the skill

The spec templates and the mechanical spec validator ship **inside this skill**, not in the target vault. Confirm they are present so the brainstorming / writing-plans skills can generate specs and the review step can validate them.

```bash
SW_DIR="<directory where the sw SKILL.md lives>"
fail=0
for t in design spec tasks; do
  [ -f "$SW_DIR/scaffold/spec-templates/$t.md" ] || { echo "FAIL: missing spec-templates/$t.md"; fail=1; }
done
[ -x "$SW_DIR/scripts/validate-spec.sh" ] || { echo "FAIL: scripts/validate-spec.sh missing or not executable"; fail=1; }
[ $fail -eq 0 ] && echo PASS
```

FAIL means the skill bundle is incomplete. Fix: restore the missing files from upstream (`/sw:update`) — the templates live at `scaffold/spec-templates/{design,spec,tasks}.md` and the validator at `scripts/validate-spec.sh` (`chmod +x` it).

## When everything passes

Report:

```
## Phase 5 — Validation: 11/11 PASS

specwright is structurally sound.
```

## When something fails

Report each FAIL with the specific reason (file path, missing line, parse error), then apply the fixes listed under each check above and re-run validation. Loop until clean. Only stop the loop when a check has no auto-repair recipe or the same fix has failed twice — in that case, surface the residual failure to the user with the exact reason.
