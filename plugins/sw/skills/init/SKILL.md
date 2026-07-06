---
name: init
user-invocable: false
description: "Set up specwright's per-repository content in the current repo: the .specwright/ vault (conventions/, issues/, milestones/), an entry point stating the sw plugin requirement, and the .gitignore lines. Always asks a commit mode: shared (committed CLAUDE.md and committed vault) or local (git-ignored CLAUDE.local.md and git-ignored vault, for a repo you do not own). Content-only — writes no machine configuration. Idempotent, safe to re-run. Trigger on '/sw:init', 'set up specwright here', 'initialize specwright in this repo'."
---

# init — set up specwright's per-repo content

Every `/sw:*` command already comes from the globally installed `sw` plugin — nothing needs to be copied into a repository for that. What a repository still needs is its own **content**: a `.specwright/` vault to hold conventions, issues, and milestones, and an entry point (`CLAUDE.md`, or `CLAUDE.local.md` in local mode) that tells any agent session the issue-driven workflow exists. `/sw:init` creates exactly that, and nothing else.

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

## Step 2 — choose the commit mode

specwright supports two commit modes, and `/sw:init` **always asks which** — on a fresh repo and on a re-run alike:

- **`shared`** (today's default) — the entry point is a committed `CLAUDE.md` and the whole `.specwright/` vault is committed. For a repo whose conventions you own.
- **`local`** — the entry point is `CLAUDE.local.md` (auto-loaded by Claude Code, never committed) and both `.specwright/` and `CLAUDE.local.md` are git-ignored. For adopting specwright inside a repo you do **not** own, keeping every specwright artifact out of the team's commits. The `.gitignore` change itself may be committed; only the *content* of `.specwright/` and `CLAUDE.local.md` must not be.

Detect the **established** mode from disk — used only to run idempotently or to refuse a divergent switch, never to skip the question:

```bash
if grep -q 'claude plugin install sw@specwright' CLAUDE.local.md 2>/dev/null; then
  established=local
elif grep -q 'claude plugin install sw@specwright' CLAUDE.md 2>/dev/null; then
  established=shared
else
  established=none
fi
```

`local` wins the tie (the check order above): a normal repo never carries both entry points, since each mode writes only its own. Ask the user for the mode, presenting `established` as the current-state context, then branch:

- **`established=none`, or the chosen mode equals `established`** → proceed to Step 3 and Step 4 in the chosen mode. On a matching re-run this is idempotent — the steps fill only what is missing.
- **The chosen mode differs from `established`** → **do not migrate.** Print the detected current mode, the consequences of switching, and the exact manual commands to switch, then **stop without writing anything**:
  - `shared` → `local`: untrack the vault with `git rm --cached -r .specwright` (working-tree files survive), move the entry-point content from `CLAUDE.md` to `CLAUDE.local.md`, and add `.specwright/` plus `CLAUDE.local.md` to `.gitignore`.
  - `local` → `shared`: remove the `.specwright/` and `CLAUDE.local.md` lines from `.gitignore`, move `CLAUDE.local.md` to `CLAUDE.md`, and `git add .specwright`.

  Switching modes is a deliberate manual action because a correct switch removes already-committed content from git — `/sw:init` never does that silently.

## Step 3 — the entry point

The entry-point file depends on the mode chosen in Step 2 — call it `ENTRY`: `CLAUDE.md` in `shared` mode, `CLAUDE.local.md` in `local` mode. In `local` mode `/sw:init` writes only `CLAUDE.local.md` and never creates or edits `CLAUDE.md` — a team's existing `CLAUDE.md` is left untouched.

If `$ENTRY` does not exist at the repo root, generate it from `references/claude-md-template.md`:

1. Determine the project name: read `name` from `package.json` (or the nearest equivalent manifest — `pyproject.toml`, `Cargo.toml`, `go.mod`) if present; otherwise fall back to the repository's root directory name; ask the user only if neither resolves.
2. Fill the template's two placeholders — the display name and the lowercase project-slug form used in the intro sentence.
3. Write the filled result to `$ENTRY` at the repo root. Confirm no double-brace placeholder token survives before writing.

If `$ENTRY` **already exists**, do not overwrite it. Check whether it already states the plugin requirement:

```bash
grep -q 'claude plugin install sw@specwright' "$ENTRY"
```

When that phrase is absent, append a short block (not the full template) naming both install commands:

```markdown

## specwright plugin required

This repo uses specwright. If `/sw:*` commands are unavailable, install the plugin once:

    claude plugin marketplace add ribeirogab/specwright
    claude plugin install sw@specwright
```

Never touch the rest of an existing `$ENTRY` — it is project-authored content.

## Step 4 — the `.gitignore` lines

Always add the worktrees line, in **both** modes:

```bash
touch .gitignore
if ! grep -qxF '.specwright/worktrees/' .gitignore; then
  [ -s .gitignore ] && [ -z "$(tail -c1 .gitignore)" ] || printf '\n' >> .gitignore
  echo '.specwright/worktrees/' >> .gitignore
fi
```

In **`local`** mode only, also git-ignore the vault and the entry point — the blanket `.specwright/` intentionally coexists with the worktrees line above:

```bash
for line in '.specwright/' 'CLAUDE.local.md'; do
  if ! grep -qxF "$line" .gitignore; then
    [ -s .gitignore ] && [ -z "$(tail -c1 .gitignore)" ] || printf '\n' >> .gitignore
    echo "$line" >> .gitignore
  fi
done
```

The blank-line guard matters: appending straight onto a non-empty `.gitignore` that lacks a trailing newline would concatenate onto its last existing line instead of starting a new one — silently mangling an entry the skill must never touch.

Idempotent by construction: each `grep -qxF` guard means a second run adds no duplicate line.

## Verify

After scaffolding, run the checks in `references/validation.md` — every check should `PASS`. If any repair was needed, `references/audit-checklist.md` lists the full inventory this skill is responsible for.

## Re-running

`/sw:init` is safe to run again at any time: every step above is additive and idempotent — it fills in what is missing and leaves existing content untouched. It still **asks the commit mode every run** (Step 2); choosing the mode already on disk is idempotent, while choosing a different one stops with the manual switch instructions and writes nothing. Re-run it after a clone, or whenever `references/validation.md` reports a `FAIL`.
