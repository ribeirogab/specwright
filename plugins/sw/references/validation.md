# Validation — Phase 5 Checklist

Run this checklist after `/sw:init` scaffolds or repairs a repository. Confirms the per-repo content is structurally sound. Each check is a quick command with a clear pass/fail.

Report results as a table. Any `FAIL` triggers an automatic fix attempt using the recipe under each check, then re-runs the validator. Every fix here is additive (create a missing directory/file, or append a missing line) — none is destructive, so no confirmation is needed before applying it.

## Contents

- [Output format](#output-format)
- [Checks](#checks) — 6 numbered checks (CLAUDE.md placeholder sweep, CLAUDE.md headers, CLAUDE.md size cap, CLAUDE.md plugin requirement, vault directories, .gitignore line)
- [When everything passes](#when-everything-passes)
- [When something fails](#when-something-fails)

## Output format

```
## Phase 5 — Validation

| # | Check | Status |
|---|-------|--------|
| 1 | CLAUDE.md has no surviving placeholders | FAIL — line 14: "{{Project Name}}" |
| ... | ... | ... |

### Result: 5/6 PASS — 1 FAIL needs attention
```

## Checks

### 1. `CLAUDE.md` has no surviving `{{placeholders}}`

```bash
grep -n '{{' CLAUDE.md && echo FAIL || echo PASS
```

FAIL means the scaffold left an unsubstituted placeholder. Fix: ask the user for the missing info and patch the lines reported.

### 2. `CLAUDE.md` contains all required section headers

```bash
required=(
  "## Workflow Spec Driven"
  "## Coding standard"
  "## Skills and slash commands"
)
missing=()
for h in "${required[@]}"; do
  grep -qF "$h" CLAUDE.md || missing+=("$h")
done
[ ${#missing[@]} -eq 0 ] && echo PASS || printf 'FAIL — missing: %s\n' "${missing[@]}"
```

Fix: read `references/claude-md-template.md` and insert the missing sections in the canonical order.

### 3. `CLAUDE.md` is at most 80 lines

The file is loaded into every agent session as the entry-point contract. Letting it grow past 80 lines crowds context and reintroduces the "encyclopedia" anti-pattern that the canonical authoring rules explicitly reject. Target range is 45–70 lines.

```bash
lines=$(wc -l < CLAUDE.md | tr -d ' ')
[ "$lines" -le 80 ] && echo "PASS ($lines lines)" || echo "FAIL ($lines lines, cap 80)"
```

FAIL means `CLAUDE.md` exceeded the cap. Fix: trim the body per the guidance in `references/claude-md-template.md` (`## Size constraint`) — tighten body prose and replace any longer narrative with a one-line pointer into `.specwright/`. Never drop a required section header (check #2 enforces those).

### 4. `CLAUDE.md` declares the `sw` plugin requirement

```bash
grep -q 'claude plugin install sw@specwright' CLAUDE.md && echo PASS || echo FAIL
```

FAIL means the mandatory-plugin line is missing — a repo opened without the plugin installed would have no way to self-diagnose why `/sw:*` commands are unavailable. Fix: append the plugin-requirement block from `references/claude-md-template.md` (`## Skills and slash commands`).

### 5. The three vault directories exist

```bash
[ -f .specwright/conventions/README.md ] && echo "PASS: conventions/" || echo "FAIL: conventions/README.md missing"
[ -f .specwright/issues/.gitkeep ] && echo "PASS: issues/" || echo "FAIL: issues/.gitkeep missing"
[ -f .specwright/milestones/.gitkeep ] && echo "PASS: milestones/" || echo "FAIL: milestones/.gitkeep missing"
```

Fix: create the missing directory and its keep-file per `references/vault-files.md`. Never overwrite an existing `conventions/` directory's contents — only seed `README.md` when the directory is empty.

### 6. `.gitignore` contains the worktrees line exactly once

```bash
count=$(grep -cxF '.specwright/worktrees/' .gitignore 2>/dev/null || echo 0)
[ "$count" -eq 1 ] && echo PASS || echo "FAIL ($count occurrences)"
```

FAIL means the line is missing (0) or duplicated (2+). Fix: for 0, append the line; for 2+, de-duplicate down to one occurrence.

## When everything passes

Report:

```
## Phase 5 — Validation: 6/6 PASS

specwright is structurally sound.
```

## When something fails

Report each FAIL with the specific reason (file path, missing line, line count), then apply the fixes listed under each check above and re-run validation. Loop until clean. Only stop the loop when a check has no auto-repair recipe or the same fix has failed twice — in that case, surface the residual failure to the user with the exact reason.
