---
name: init
description: "Set up specwright's per-repository content in the current repo: the .specwright/ vault (conventions/, issues/, milestones/), a root CLAUDE.md entry point stating the sw plugin requirement, and the .gitignore worktrees line. Content-only — writes no machine configuration. Idempotent, safe to re-run. Trigger on '/sw:init', 'set up specwright here', 'initialize specwright in this repo'."
---

# init — set up specwright's per-repo content

Every `/sw:*` command already comes from the globally installed `sw` plugin — nothing needs to be copied into a repository for that. What a repository still needs is its own **content**: a `.specwright/` vault to hold conventions, issues, and milestones, and a `CLAUDE.md` entry point that tells any agent session the issue-driven workflow exists. `/sw:init` creates exactly that, and nothing else.

**Announce at start:** "Setting up specwright in this repo..."

## Does not do

This skill never writes machine configuration and never copies tooling into the repo:

- No plugin-trust or plugin-enablement configuration — trusting and enabling the plugin happens once at the Claude Code level, not per-repo.
- No copy of any skill body into the repo — the plugin serves every `/sw:*` command globally.
- No per-agent discovery directory, file, or link of any kind.

If any of that is missing, that is expected — it is not this skill's job.

## Step 1 — scaffold the vault

Ensure `.specwright/` holds exactly three directories:

```bash
mkdir -p .specwright/conventions .specwright/issues .specwright/milestones
[ -f .specwright/issues/.gitkeep ] || : > .specwright/issues/.gitkeep
[ -f .specwright/milestones/.gitkeep ] || : > .specwright/milestones/.gitkeep
```

`.specwright/conventions/` gets a signpost `README.md` — but **only** when the directory has no files in it yet. Never overwrite a `conventions/` directory the user has already populated:

```bash
if [ -z "$(ls -A .specwright/conventions 2>/dev/null)" ]; then
  cat > .specwright/conventions/README.md <<'EOF'
# About this folder — signpost, not a convention

`/sw:review` reads every file in `.specwright/conventions/` as a project standard it
must enforce. This file is the exception on purpose: it states no rule and applies to
no file, so there is nothing here to enforce. Delete it whenever you want.

This folder is yours. Put whatever this repo wants kept consistent — code style,
naming, architecture, testing, domain rules, review preferences, any project-specific
standard. One file per convention, in whatever shape you like; specwright imposes no
template and no required frontmatter.
EOF
fi
```

See `references/vault-files.md` for the full specification of what belongs in each vault directory.

## Step 2 — the CLAUDE.md entry point

If `CLAUDE.md` does not exist at the repo root, generate it from `references/claude-md-template.md`:

1. Determine the project name: read `name` from `package.json` (or the nearest equivalent manifest — `pyproject.toml`, `Cargo.toml`, `go.mod`) if present; otherwise fall back to the repository's root directory name; ask the user only if neither resolves.
2. Fill the template's two placeholders — the display name and the lowercase project-slug form used in the intro sentence.
3. Write the filled result to `CLAUDE.md` at the repo root. Confirm no double-brace placeholder token survives before writing.

If `CLAUDE.md` **already exists**, do not overwrite it. Check whether it already states the plugin requirement:

```bash
grep -q 'claude plugin install sw@specwright' CLAUDE.md
```

When that phrase is absent, append a short block (not the full template) naming both install commands:

```markdown

## specwright plugin required

This repo uses specwright. If `/sw:*` commands are unavailable, install the plugin once:

    claude plugin marketplace add ribeirogab/specwright
    claude plugin install sw@specwright
```

Never touch the rest of an existing `CLAUDE.md` — it is project-authored content.

## Step 3 — the `.gitignore` worktrees line

```bash
touch .gitignore
grep -qxF '.specwright/worktrees/' .gitignore || echo '.specwright/worktrees/' >> .gitignore
```

Idempotent by construction: the `grep -qxF` guard means a second run adds no duplicate line.

## Verify

After scaffolding, run the checks in `references/validation.md` — every check should `PASS`. If any repair was needed, `references/audit-checklist.md` lists the full inventory this skill is responsible for.

## Re-running

`/sw:init` is safe to run again at any time: every step above is additive and idempotent — it fills in what is missing and leaves existing content untouched. Re-run it after a clone, or whenever `references/validation.md` reports a `FAIL`.
