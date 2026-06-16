# Validation — Phase 5 Checklist

Run this checklist after **any** scaffold or fix run, and at the end of an audit even when nothing was missing. Confirms the memex is structurally sound. Each check is a quick command with a clear pass/fail.

Report results as a table. Any `FAIL` triggers an automatic fix attempt using the recipe under each check, then re-runs the validator. The orchestrator does not prompt the user before fixing — it loops until the table is clean or it determines a check cannot be auto-repaired.

## Contents

- [Output format](#output-format)
- [Checks](#checks) — 19 numbered checks (CLAUDE.md symlink, placeholder sweeps, AGENTS.md headers, frontmatter, Obsidian JSON, .gitignore, spec folder naming, canonical skills installed, Claude plugin settings, executable scripts, MOC placeholders, spec template Acceptance Criteria, AGENTS.md size cap, spec-file bare naming, spec validator scaffolded, spec-driven-development guide scaffolded, update engine scaffolded, update manifest valid)
- [When everything passes](#when-everything-passes)
- [When something fails](#when-something-fails)

## Output format

```
## Phase 5 — Validation

| # | Check | Status |
|---|-------|--------|
| 1 | CLAUDE.md symlink resolves to AGENTS.md | PASS |
| 2 | constitution.md has no surviving placeholders | FAIL — line 14: "{{Project Name}}" |
| ... | ... | ... |

### Result: 18/19 PASS — 1 FAIL needs attention
```

## Checks

### 1. `CLAUDE.md` symlink resolves to `AGENTS.md`

```bash
[ "$(readlink CLAUDE.md)" = "AGENTS.md" ] && echo PASS || echo FAIL
```

FAIL means `CLAUDE.md` is missing, is a regular file, or points elsewhere. Fix: remove and recreate with `ln -s AGENTS.md CLAUDE.md`.

### 2. `.memex/constitution.md` has no surviving `{{placeholders}}`

```bash
grep -n '{{' .memex/constitution.md && echo FAIL || echo PASS
```

FAIL means the scaffold left unsubstituted placeholders. Fix: ask the user for the missing info and patch the lines reported.

### 3. `AGENTS.md` has no surviving `{{placeholders}}`

```bash
grep -n '{{' AGENTS.md && echo FAIL || echo PASS
```

Same fix as #2.

### 4. `AGENTS.md` contains all required section headers

```bash
required=(
  "## Workflow Spec Driven"
  "## Non-negotiable rules"
  "## Vault — read from it, write to it"
  "## Skills and slash commands"
)
missing=()
for h in "${required[@]}"; do
  grep -qF "$h" AGENTS.md || missing+=("$h")
done
[ ${#missing[@]} -eq 0 ] && echo PASS || printf 'FAIL — missing: %s\n' "${missing[@]}"
```

Fix: read `references/agents-md-template.md` and insert the missing sections in the canonical order.

### 5. Frontmatter valid in MOCs and templates

For each of `.memex/_index/{home,specs,learnings,conventions}.md`, `.memex/rules.md`, `.memex/templates/{learning,convention}.md`, and `.memex/specs/_template/{spec,design,tasks}.md`, confirm the file begins with `---` and contains a closing `---` with at least one expected field (`tags:`, `feature:`, or `status:`) between them.

```bash
for f in .memex/_index/*.md .memex/templates/*.md .memex/specs/_template/*.md; do
  head -1 "$f" | grep -q '^---$' || { echo "FAIL: $f missing opening fence"; continue; }
  awk '/^---$/{n++} n==2{exit} {print}' "$f" | grep -qE '^(tags|feature|status):' \
    || echo "FAIL: $f missing expected frontmatter field"
done
```

Fix: re-create the file from `references/vault-files.md`.

### 6. Obsidian JSON files parse

```bash
for f in .memex/.obsidian/app.json .memex/.obsidian/appearance.json .memex/.obsidian/core-plugins.json; do
  python3 -c "import json,sys; json.load(open('$f'))" 2>/dev/null && echo "PASS: $f" || echo "FAIL: $f"
done
```

Fix: re-write from `references/vault-files.md`.

### 7. `.gitignore` ignores the entire Obsidian config directory

```bash
grep -qE '^.memex/\.obsidian/?$' .gitignore 2>/dev/null && echo PASS || echo FAIL
```

FAIL means `.gitignore` is missing the `.memex/.obsidian/` line (or still has the older fine-grained patterns). Fix: replace any old per-file Obsidian patterns with the single line `.memex/.obsidian/`.

### 8. `.memex/specs/` contains no folder without date prefix

```bash
ls .memex/specs/ 2>/dev/null | grep -vE '^_template$|^[0-9]{4}-[0-9]{2}-[0-9]{2}-' \
  && echo FAIL || echo PASS
```

FAIL lists the offending folder names. Fix: rename per the migration prompt in `references/audit-checklist.md`.

### 9. Skills installed at the canonical location — each has its `SKILL.md`

Skills are canonically under `.agents/skills/<name>/`. Per-agent symlinks (`.claude/skills/<name>`, etc.) are bonus exposure, not the source of truth.

```bash
for s in memex-recall memex-brainstorming memex-writing-plans memex-link memex-new-pr memex-code-review memex-update; do
  [ -f ".agents/skills/$s/SKILL.md" ] && echo "PASS: $s" || echo "FAIL: $s"
done
```

Fix: re-run the skills copy block from `SKILL.md` (Scaffolding section).

### 10. Brainstorming scripts are executable

```bash
fail=0
for f in .agents/skills/memex-brainstorming/scripts/*.sh; do
  [ -x "$f" ] || { echo "FAIL: $f not executable"; fail=1; }
done
[ $fail -eq 0 ] && echo PASS
```

Fix: `chmod +x .agents/skills/memex-brainstorming/scripts/*.sh`.

### 11. Claude plugin settings present (when `.claude/` exists)

Slash commands ship as a Claude Code plugin from the upstream marketplace `memex`. When the target repo has a `.claude/` directory, `.claude/settings.json` must declare both `extraKnownMarketplaces["memex"]` (with any non-empty `source` object) and `enabledPlugins["memex@memex"] = true`. If `.claude/` is absent, this check trivially PASSes — the user does not run Claude Code here, so no settings.json is required.

```bash
if [ ! -d .claude ]; then
  echo PASS
elif [ ! -f .claude/settings.json ]; then
  echo FAIL
else
  has_mp=$(jq 'has("extraKnownMarketplaces") and (.extraKnownMarketplaces | has("memex"))' .claude/settings.json 2>/dev/null)
  has_src=$(jq '.extraKnownMarketplaces["memex"].source != null' .claude/settings.json 2>/dev/null)
  has_plugin=$(jq '.enabledPlugins["memex@memex"] == true' .claude/settings.json 2>/dev/null)
  if [ "$has_mp" = "true" ] && [ "$has_src" = "true" ] && [ "$has_plugin" = "true" ]; then
    echo PASS
  else
    echo FAIL
  fi
fi
```

Fix: re-run the settings.json merge block from `SKILL.md` (Phase 4), which uses the jq recipe in `references/claude-plugin-settings.md`. If `jq` is unavailable, fall back to the Python recipe in the same reference.

### 12. MOCs have no surviving `{{Project Name}}` placeholders

The four MOCs in `.memex/_index/` belong to Group B in `references/vault-files.md` — they must have `{{Project Name}}` substituted with the actual project name. Surviving placeholders here mean the scaffold step skipped a file.

```bash
grep -nH '{{' .memex/_index/*.md && echo FAIL || echo PASS
```

Fix: re-substitute `{{Project Name}}` (and any other surviving `{{}}` placeholder) in the offending file with the project name from Prerequisites. Note: `templates/*.md` and `specs/_template/*.md` are Group A (templates) and **legitimately retain** their `{{}}` placeholders — do not run this check against them.

### 13. Spec template carries an `## Acceptance Criteria` section

Every spec produced from `_template/spec.md` must inherit a structured Acceptance Criteria section so the behaviour harness has something concrete to verify. If the heading was deleted from the template, every future spec loses it silently — `/memex:review-spec` would have nothing to enforce.

```bash
grep -q '^## Acceptance Criteria$' .memex/specs/_template/spec.md \
  && echo PASS \
  || echo "FAIL: missing '## Acceptance Criteria' heading in _template/spec.md"
```

Fix: re-create `_template/spec.md` from the spec block in `references/vault-files.md` — the canonical template includes the section with its rules and examples.

### 14. `AGENTS.md` is at most 80 lines

The file is loaded into every agent session as the entry-point contract. Letting it grow past 80 lines crowds context and reintroduces the "encyclopedia" anti-pattern that the canonical authoring rules explicitly reject (see `.memex/learnings/agents-md-as-map-not-encyclopedia.md`). Target range is 45–70 lines.

```bash
lines=$(wc -l < AGENTS.md | tr -d ' ')
[ "$lines" -le 80 ] && echo "PASS ($lines lines)" || echo "FAIL ($lines lines, cap 80)"
```

FAIL means `AGENTS.md` exceeded the cap. Fix: trim the body per the guidance in `references/agents-md-template.md` (`## Size constraint`) — tighten body prose and replace any longer narrative with a one-line pointer into `.memex/`. Never drop a required section header (check #4 enforces those).

### 15. Spec folders use bare `spec.md` / `design.md` / `tasks.md`

Inside any date-prefixed spec folder, the files use **bare** names — `spec.md`, `design.md`, `tasks.md` (legacy specs predating the design.md split may instead carry a bare `plan.md`). The dated folder is the discriminator and cross-references are path-qualified wikilinks (`[[YYYY-MM-DD-<slug>/spec|spec]]`). A surviving `<type>-<slug>.md` file is drift from before the bare-filename convention.

```bash
bad=$(find .memex/specs -type f \( -name 'spec-*.md' -o -name 'design-*.md' -o -name 'plan-*.md' -o -name 'tasks-*.md' \) 2>/dev/null)
[ -z "$bad" ] && echo PASS || { echo "FAIL:"; echo "$bad"; }
```

FAIL lists the offending slug-named paths. Fix: run the spec-file rename migration recipe in `SKILL.md` (Phase 4 → "Spec file rename migration") for each affected folder. The recipe `git mv`s the files to bare names, rewrites `[[<type>-<slug>]]` wikilinks to the path-qualified `[[<folder>/<type>|<type>]]` form, and updates the `.memex/_index/specs.md` MOC entry. Renames are destructive — confirm with the user once per folder before running.

### 16. Spec validator scaffolded and executable

The mechanical spec validator must be installed at `.memex/scripts/validate-spec.sh` and be executable, so `/memex:review-spec` can run it as a feedforward gate before the prose review.

```bash
[ -x .memex/scripts/validate-spec.sh ] && echo PASS || echo FAIL
```

FAIL means the validator was not scaffolded (or lost its executable bit). Fix: re-run the validator copy step in `SKILL.md` (Scaffolding section), which copies `scaffold/vault-scripts/validate-spec.sh` to `.memex/scripts/validate-spec.sh` and `chmod +x`'s it.

### 17. Spec-driven-development guide scaffolded

The workflow guide must be installed at `.memex/spec-driven-development.md` so every memex repo ships the human-facing explainer of the spec-driven flow (the artifact model, the 9 steps, scope/delegation tables, gates).

```bash
[ -f .memex/spec-driven-development.md ] && echo PASS || echo FAIL
```

FAIL means the guide was not scaffolded. Fix: re-run the guide copy step in `SKILL.md` (Scaffolding section), which copies `scaffold/vault-docs/spec-driven-development.md` to `.memex/spec-driven-development.md`.

### 18. Update engine scaffolded and executable

The `/memex:update` reconcile engine must be installed at `.memex/scripts/memex-update.sh` and be executable, so the update command can run it.

```bash
[ -x .memex/scripts/memex-update.sh ] && echo PASS || echo FAIL
```

FAIL means the engine was not scaffolded (or lost its executable bit). Fix: re-run the update-script copy step in `SKILL.md` (Scaffolding section), which copies `scaffold/vault-scripts/memex-update.sh` to `.memex/scripts/memex-update.sh` and `chmod +x`'s it.

### 19. Update baseline manifest present and valid

The update baseline manifest must exist at `.memex/.update-manifest.json` and parse as JSON, so `/memex:update` runs precise 3-way (stock-vs-edited) instead of degrading to 2-way.

```bash
jq . .memex/.update-manifest.json >/dev/null 2>&1 && echo PASS || echo FAIL
```

FAIL means the manifest is missing or malformed. Fix: run `bash .memex/scripts/memex-update.sh --init-manifest` to regenerate the baseline (records a sha256 per managed file). A legacy install without one self-heals on the first `/memex:update` (2-way first run writes the manifest).

## When everything passes

Report:

```
## Phase 5 — Validation: 19/19 PASS

Memex is structurally sound.
```

## When something fails

Report each FAIL with the specific reason (file path, missing line, parse error), then apply the fixes listed under each check above and re-run validation. Loop until clean. Only stop the loop when a check has no auto-repair recipe or the same fix has failed twice — in that case, surface the residual failure to the user with the exact reason.
