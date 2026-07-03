# Audit Checklist

Full inventory of what `/sw:init` checks before scaffolding, and what a repair pass restores. `/sw:init` is content-only: it never installs or configures tooling — the plugin already provides every `/sw:*` command globally. This checklist covers only what a single repository still needs.

## Contents

- [Status meanings](#status-meanings)
- [Files and directories to check](#files-and-directories-to-check)
- [CLAUDE.md drift detection (required headers + size cap)](#claudemd-drift-detection-required-headers--size-cap)
- [Report format](#report-format)

## Status meanings

For each item, check existence and content correctness. Report status as:
- `OK` — exists and looks correct
- `MISSING` — doesn't exist at all
- `DRIFT` — exists but content has diverged from expected structure (e.g., `CLAUDE.md` missing a required section, or over the size cap)

## Files and directories to check

```
.specwright/
  .specwright/conventions/    (directory exists, contains README.md signpost — clone survival)
  .specwright/issues/         (directory exists, contains .gitkeep — holds dated YYYY-MM-DD-<slug>/ issue folders)
  .specwright/milestones/     (directory exists, contains .gitkeep — holds dated YYYY-MM-DD-<slug>/ milestone folders)

CLAUDE.md                      (repo root — self-contained issue flow + the sw plugin requirement, ≤ 80 lines)

.gitignore                     (contains .specwright/worktrees/)
```

That is the complete list. `/sw:init` writes no machine configuration and creates no per-agent discovery files or links of any kind — every `/sw:*` command is served by the globally installed `sw` plugin, so there is nothing else for a single repository to hold.

The artifact **templates** (`issue.md` / `spec.md` / `tasks.md` / `goal.md` / `board.md` blueprints) and the mechanical issue **validator** are **not** scaffolded into the target repo — they ship with the plugin under `plugins/sw/templates/` and `plugins/sw/scripts/validate-spec.sh`, available to every repo the plugin is installed in.

## CLAUDE.md drift detection (required headers + size cap)

`CLAUDE.md` must contain all of these section headers — missing any one is `DRIFT`:

- `## Workflow Spec Driven`
- `## Coding standard`
- `## Skills and slash commands`

`CLAUDE.md` must also state the `sw` plugin requirement — missing the phrase `claude plugin install sw@specwright` is `DRIFT`.

`CLAUDE.md` must also be **≤ 80 lines** (target range 45–70). The file is loaded into every agent session as the entry-point contract; growing past this cap crowds context and reintroduces the "encyclopedia" anti-pattern that the canonical authoring rules reject. If `CLAUDE.md` exceeds 80 lines, status is `DRIFT` and the fix is to trim the body per the guidance in `references/claude-md-template.md` (`## Size constraint`) — never by dropping a required section header.

## Report format

```
## specwright Audit

| Status | Item |
|--------|------|
| OK     | CLAUDE.md |
| MISSING| .specwright/conventions/ |
| DRIFT  | CLAUDE.md (missing section: "## Coding standard") |
| ...    | ... |

### Summary
- X/Y items OK
- N missing, M drifted
```

After rendering this report, proceed directly to restoring any `MISSING` or `DRIFT` item — no mid-run confirmation needed, since every fix here is additive (create a missing directory or file, or append a missing line) and never destroys existing content. If everything passes, run Phase 5 validation (see `references/validation.md`) before reporting "specwright is healthy."
