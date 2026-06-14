---
feature: memex-canonical-commands
plan: "[[2026-05-05-memex-canonical-commands/plan|plan]]"
spec: "[[2026-05-05-memex-canonical-commands/spec|spec]]"
created: 2026-05-05
---
# Memex Canonical Commands + Drop `memex-open-pr` — Tasks

**For this plan:** `[[2026-05-05-memex-canonical-commands/plan|plan]]`

> All tasks operate on this repo (`/Users/gabriel/www/ribeirogab/agent-skills`). Work on a feature branch — never `main`. Open PR via `/memex-open-pr` (this repo still has it locally; spec policy B keeps it as an orphan in this repo).

## Phase 0: Branch setup

### Task 0: Create feature branch

**Files:** none (git operation only)

- [ ] **Step 1: Confirm clean working tree**

```bash
git status
```

Expected: `nothing to commit, working tree clean` and current branch `main`.

- [ ] **Step 2: Create branch**

```bash
git switch -c feat/memex-canonical-commands
```

Expected: `Switched to a new branch 'feat/memex-canonical-commands'`.

---

## Phase 1: Edit skill

### Task 1: Rewrite SKILL.md Phase 4 commands block

**Files:**
- Modify: `skills/memex/SKILL.md` (lines 88–139, the "Skills and commands (copy from scaffold/)" section)

This task replaces the existing single-loop command install with the two-step canonical+symlink pattern. The skills block above it (lines 92–121) is unchanged and stays as the reference pattern; this task only touches the commands block (lines 123–134) and the surrounding commentary.

- [ ] **Step 1: Open `skills/memex/SKILL.md` and locate the existing commands block**

The block to replace starts with the line ` **Slash commands** are a Claude Code-specific concept` and ends at the closing fence of the bash block followed by the `Rules:` heading. Confirm by `grep -n 'Slash commands' skills/memex/SKILL.md` — expect a single match around line 123.

- [ ] **Step 2: Replace the block**

Old block (verbatim from current SKILL.md):

````markdown
**Slash commands** are a Claude Code-specific concept (no other current agent has an equivalent), so they install only into `.claude/commands/`. If `.claude/` does not exist in the repo, skip the command copy entirely — the workflows the commands encode are useful in any agent, but the user invokes them via prose prompts on those agents, not via `/foo` syntax.

```bash
if [ -d .claude ]; then
  mkdir -p .claude/commands
  for cmd in memex-open-pr memex-learn memex-spec memex-review-spec memex-sweep; do
    target=".claude/commands/$cmd.md"
    [ -e "$target" ] && continue
    cp "$MEMEX_DIR/scaffold/commands/$cmd.md" "$target"
  done
fi
```
````

New block (replaces the old one in place):

````markdown
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
````

Use Edit to do the replacement. Make sure the surrounding `Rules:` paragraph below is unchanged.

- [ ] **Step 3: Update the "Rules" paragraph below the block**

Old text (current):

```markdown
Rules:
- Skills always go to `.agents/skills/<name>` first (canonical), then symlinked into existing agent dirs.
- Existing files are never overwritten — re-runs are no-ops on already-installed items.
- Per-agent dirs that do not already exist are not auto-created by the skill copy; only an existing dir signals that agent is in use here.
```

New text:

```markdown
Rules:
- Skills always go to `.agents/skills/<name>` first (canonical), then symlinked into existing agent dirs.
- Commands always go to `.agents/commands/<cmd>.md` first (canonical), then symlinked into `.claude/commands/` if `.claude/` exists. Slash commands are Claude-only today — no Codex/Cursor equivalent — so the symlink loop is single-agent.
- Existing canonical files are never overwritten — re-runs are no-ops on already-installed items.
- Existing regular files at a command symlink target are removed and replaced with a symlink (migration path). Existing symlinks are left alone.
- Per-agent dirs that do not already exist are not auto-created by the skill copy; only an existing dir signals that agent is in use here.
```

- [ ] **Step 4: Verify the edit**

```bash
grep -c 'COMMAND_NAMES=' skills/memex/SKILL.md
grep -c 'memex-open-pr' skills/memex/SKILL.md
grep -c '\.agents/commands' skills/memex/SKILL.md
```

Expected output:
- `COMMAND_NAMES=` → `1`
- `memex-open-pr` → `0`
- `.agents/commands` → at least `2` (one in the bash block, one in the Rules section)

- [ ] **Step 5: Commit**

```bash
git add skills/memex/SKILL.md
git commit -m "refactor(memex): canonical commands at .agents/commands + drop open-pr from loop"
```

---

### Task 2: Delete `scaffold/commands/memex-open-pr.md`

**Files:**
- Delete: `skills/memex/scaffold/commands/memex-open-pr.md`

- [ ] **Step 1: Confirm file exists**

```bash
ls skills/memex/scaffold/commands/memex-open-pr.md
```

Expected: file path printed (no error).

- [ ] **Step 2: Delete with `git rm`**

```bash
git rm skills/memex/scaffold/commands/memex-open-pr.md
```

Expected: `rm 'skills/memex/scaffold/commands/memex-open-pr.md'`.

- [ ] **Step 3: Verify**

```bash
ls skills/memex/scaffold/commands/
```

Expected: four files only — `memex-learn.md`, `memex-review-spec.md`, `memex-spec.md`, `memex-sweep.md`.

- [ ] **Step 4: Commit**

```bash
git commit -m "chore(memex): remove memex-open-pr from scaffold (no longer shipped)"
```

---

### Task 3: Update `references/audit-checklist.md`

**Files:**
- Modify: `skills/memex/references/audit-checklist.md` (lines 53–66, the commands block + the "Per-agent skill symlinks" subsection)

- [ ] **Step 1: Replace the commands entries in the file list**

In the fenced code block under `## Files and directories to check`, find these lines:

```
.claude/commands/memex-open-pr.md               (slash commands — Claude Code only)
.claude/commands/memex-learn.md
.claude/commands/memex-spec.md
.claude/commands/memex-review-spec.md
.claude/commands/memex-sweep.md
```

Replace with:

```
.agents/commands/memex-learn.md                 (canonical — slash commands, agent-agnostic location)
.agents/commands/memex-spec.md
.agents/commands/memex-review-spec.md
.agents/commands/memex-sweep.md
```

- [ ] **Step 2: Add a "Per-agent command symlinks" subsection**

Right after the existing `### Per-agent skill symlinks (optional, not required)` subsection (which ends with the paragraph "If a per-agent dir does not exist at all, no symlinks are created (the absence signals the user does not run that agent in this repo)."), add a new subsection:

```markdown
### Per-agent command symlinks (Claude Code only)

Slash commands are a Claude Code-specific concept today — no other current agent has an equivalent. When `.claude/` exists, each canonical command above should also be exposed as a symlink at `.claude/commands/<cmd>.md` pointing to `../../.agents/commands/<cmd>.md`.

A missing per-agent symlink is **not `DRIFT`** — only the canonical files under `.agents/commands/` are required. If `.claude/` exists but a symlink is missing, the memex installer creates it on the next run (no prompt; symlinks are non-destructive).

A regular file at the symlink target IS `DRIFT`. The fix in Phase 4 removes the regular file and creates the symlink — policy is "scaffold sempre vence", no content comparison, no prompt. The user has accepted that any file at this path is owned by the skill.

A symlink that points somewhere wrong (e.g., to a deleted target) is also `DRIFT` — the fix removes the bad symlink and creates a correct one.

If `.claude/` does not exist at all, no symlinks are checked or created (the absence signals the user does not run Claude Code in this repo).
```

- [ ] **Step 3: Verify**

```bash
grep -c 'memex-open-pr' skills/memex/references/audit-checklist.md
grep -c '\.agents/commands/memex-learn\.md' skills/memex/references/audit-checklist.md
grep -c '^### Per-agent command symlinks' skills/memex/references/audit-checklist.md
```

Expected:
- `memex-open-pr` → `0`
- `.agents/commands/memex-learn.md` → `1`
- `### Per-agent command symlinks` → `1`

- [ ] **Step 4: Commit**

```bash
git add skills/memex/references/audit-checklist.md
git commit -m "docs(memex): audit-checklist tracks .agents/commands canonical + symlink subsection"
```

---

### Task 4: Update `references/validation.md` Check #11

**Files:**
- Modify: `skills/memex/references/validation.md` (lines 141–155, the entire Check #11 block)

- [ ] **Step 1: Replace Check #11 in full**

Old block (verbatim from current validation.md):

````markdown
### 11. Commands copied

Slash commands are Claude Code-specific and only install if `.claude/` is present in the repo. If `.claude/` is absent, this check is `N/A`.

```bash
if [ ! -d .claude ]; then
  echo "N/A — no .claude/ directory; commands skipped by design"
else
  for c in memex-open-pr memex-learn memex-spec memex-review-spec memex-sweep; do
    [ -f ".claude/commands/$c.md" ] && echo "PASS: $c" || echo "FAIL: $c"
  done
fi
```

Fix: re-run the commands copy block from `SKILL.md` (Scaffolding section).
````

New block:

````markdown
### 11. Canonical commands installed

Slash commands install canonically under `.agents/commands/<cmd>.md`. The canonical files are the source of truth; `.claude/commands/<cmd>.md` symlinks are bonus exposure and are validated as drift in Phase 1, not here. This check always runs (no `.claude/` gating) and always returns PASS or FAIL.

```bash
for c in memex-learn memex-spec memex-review-spec memex-sweep; do
  [ -f ".agents/commands/$c.md" ] && echo "PASS: $c" || echo "FAIL: $c"
done
```

Fix: re-run the commands copy block from `SKILL.md` (Scaffolding section).
````

- [ ] **Step 2: Verify the check count is still 15**

```bash
grep -c '^### [0-9]' skills/memex/references/validation.md
```

Expected: `15`.

- [ ] **Step 3: Verify content**

```bash
grep -c 'memex-open-pr' skills/memex/references/validation.md
grep -c '\.agents/commands/' skills/memex/references/validation.md
grep -c 'N/A — no \.claude/ directory' skills/memex/references/validation.md
```

Expected:
- `memex-open-pr` → `0`
- `.agents/commands/` → at least `1` (the new check)
- `N/A — no .claude/ directory` → `0`

- [ ] **Step 4: Verify the table-of-contents at top of validation.md still mentions Check #11**

```bash
grep -n 'copied skills/commands' skills/memex/references/validation.md
```

If the line in the contents list at top of file says "copied skills/commands", update that one bullet to read "canonical skills/commands installed" (the contents list lives near line 10 of the file under `## Contents`). Use Edit to make this surgical change.

- [ ] **Step 5: Commit**

```bash
git add skills/memex/references/validation.md
git commit -m "docs(memex): Check #11 validates canonical commands, drops open-pr + N/A branch"
```

---

### Task 5: Update `references/agents-md-template.md`

**Files:**
- Modify: `skills/memex/references/agents-md-template.md` (the `## Skills and slash commands` bullet list, currently 8 entries)

- [ ] **Step 1: Locate the bullet to remove**

```bash
grep -n '/memex-open-pr' skills/memex/references/agents-md-template.md
```

Expected: one match, around line 102, of the form:
` - **`/memex-open-pr`** — **required** command to open pull requests with auto-generated title and description. Always use this command when creating a PR.`

- [ ] **Step 2: Delete that one line**

Use Edit to remove the entire bullet (the line itself) without touching the seven other bullets above and below. Do not leave a blank line in its place — the surrounding bullets are contiguous.

- [ ] **Step 3: Verify**

```bash
grep -c 'memex-open-pr' skills/memex/references/agents-md-template.md
grep -c '^- \*\*' skills/memex/references/agents-md-template.md
```

Expected:
- `memex-open-pr` → `0`
- bullet count → unchanged from "previous count minus 1". Sanity check: the seven remaining bullets must still be `memex-brainstorming`, `memex-writing-plans`, `memex-recall`, `/memex-spec`, `/memex-review-spec`, `/memex-sweep`, `/memex-learn`. Read the section to confirm visually.

- [ ] **Step 4: Commit**

```bash
git add skills/memex/references/agents-md-template.md
git commit -m "docs(memex): drop /memex-open-pr from agents-md-template skills section"
```

---

### Task 6: Final repo-wide grep sweep (AC11)

**Files:** none (read-only verification).

- [ ] **Step 1: Confirm zero references to `memex-open-pr` under `skills/memex/`**

```bash
grep -rln 'memex-open-pr' skills/memex/
```

Expected: no output (exit code 1).

If anything matches, open the offending file and remove the reference. The likely culprits would be a forgotten line in `audit-checklist.md` or `validation.md`. Repeat until clean, then re-commit:

```bash
git add -A
git commit -m "docs(memex): mop up stray memex-open-pr references"
```

(Skip this commit if there were no leftovers — the grep is the spec's AC11 check.)

- [ ] **Step 2: Confirm scaffold has only four commands**

```bash
ls skills/memex/scaffold/commands/ | sort
```

Expected:
```
memex-learn.md
memex-review-spec.md
memex-spec.md
memex-sweep.md
```

(four lines, no `memex-open-pr.md`).

---

## Phase 2: Verify behavior on scratch repos

These tasks do not commit anything to this repo. They simulate the three scenarios from the spec's User Stories and confirm the audit's behavior is as described. Run them inside `/tmp/` so nothing leaks back into `agent-skills/`.

The validating subject in all four tasks is the *current working tree* of `agent-skills/` — the test runs the skill's bash blocks against scratch directories. To execute them, follow this pattern: `cd` into the scratch dir, set `MEMEX_DIR` to the absolute path of the agent-skills repo's `skills/memex/` directory, then paste the bash from `SKILL.md` Phase 4 (skills block + commands block) into the shell.

### Task 7: Scenario 1 — Fresh install with `.claude/` (AC7)

**Files:** scratch only.

- [ ] **Step 1: Set up scratch repo**

```bash
mkdir -p /tmp/memex-test-fresh-claude/.claude
cd /tmp/memex-test-fresh-claude
export MEMEX_DIR=/Users/gabriel/www/ribeirogab/agent-skills/skills/memex
```

- [ ] **Step 2: Run the commands install block from SKILL.md**

Paste this block (copied verbatim from `skills/memex/SKILL.md` Phase 4 commands section, as written in Task 1) into the shell:

```bash
COMMAND_NAMES=(memex-learn memex-spec memex-review-spec memex-sweep)

mkdir -p .agents/commands
for cmd in "${COMMAND_NAMES[@]}"; do
  [ -e ".agents/commands/$cmd.md" ] && continue
  cp "$MEMEX_DIR/scaffold/commands/$cmd.md" ".agents/commands/$cmd.md"
done

if [ -d .claude ]; then
  mkdir -p .claude/commands
  for cmd in "${COMMAND_NAMES[@]}"; do
    target=".claude/commands/$cmd.md"
    if [ -L "$target" ]; then
      continue
    elif [ -f "$target" ]; then
      rm "$target"
    fi
    ln -s "../../.agents/commands/$cmd.md" "$target"
  done
fi
```

- [ ] **Step 3: Verify canonical files**

```bash
ls .agents/commands/ | sort
```

Expected:
```
memex-learn.md
memex-review-spec.md
memex-spec.md
memex-sweep.md
```

- [ ] **Step 4: Verify symlinks**

```bash
for c in memex-learn memex-spec memex-review-spec memex-sweep; do
  printf '%s -> %s\n' "$c" "$(readlink .claude/commands/$c.md)"
done
```

Expected: each line is `<cmd> -> ../../.agents/commands/<cmd>.md`.

- [ ] **Step 5: Verify symlinks resolve**

```bash
for c in memex-learn memex-spec memex-review-spec memex-sweep; do
  [ -f .claude/commands/$c.md ] && echo "OK: $c" || echo "BROKEN: $c"
done
```

Expected: four `OK:` lines.

- [ ] **Step 6: Cleanup**

```bash
cd / && rm -rf /tmp/memex-test-fresh-claude
```

---

### Task 8: Scenario 2 — Migration from existing real files (AC8)

**Files:** scratch only.

- [ ] **Step 1: Set up scratch repo with simulated existing install**

```bash
mkdir -p /tmp/memex-test-migration/.claude/commands
cd /tmp/memex-test-migration
export MEMEX_DIR=/Users/gabriel/www/ribeirogab/agent-skills/skills/memex

# Seed five real files (the four active commands + the orphan)
for c in memex-learn memex-spec memex-review-spec memex-sweep memex-open-pr; do
  echo "stale content for $c" > .claude/commands/$c.md
done

ls -la .claude/commands/
```

Expected: five regular files (no symlinks, no `.agents/` directory yet).

- [ ] **Step 2: Run the install block**

Paste the same bash block printed in Task 7 Step 2 (the `COMMAND_NAMES=(...)` array plus both loops).

- [ ] **Step 3: Verify the four active commands are now symlinks**

```bash
for c in memex-learn memex-spec memex-review-spec memex-sweep; do
  [ -L .claude/commands/$c.md ] && echo "SYMLINK: $c" || echo "REGULAR: $c"
done
```

Expected: four `SYMLINK:` lines.

- [ ] **Step 4: Verify the orphan was NOT touched**

```bash
[ -L .claude/commands/memex-open-pr.md ] && echo "WRONG: now a symlink"
[ -f .claude/commands/memex-open-pr.md ] && [ ! -L .claude/commands/memex-open-pr.md ] \
  && echo "OK: orphan still a regular file"
cat .claude/commands/memex-open-pr.md
```

Expected: `OK: orphan still a regular file`, then `stale content for memex-open-pr`.

- [ ] **Step 5: Verify canonical files are present**

```bash
ls .agents/commands/ | sort
```

Expected: same four-line listing as Task 7 Step 3.

- [ ] **Step 6: Verify canonical content came from scaffold (not from the seeded stale content)**

```bash
diff .agents/commands/memex-learn.md $MEMEX_DIR/scaffold/commands/memex-learn.md
```

Expected: no output (files identical).

- [ ] **Step 7: Cleanup**

```bash
cd / && rm -rf /tmp/memex-test-migration
```

---

### Task 9: Scenario 4 — Idempotency (AC9)

**Files:** scratch only. Continues from a fresh test repo.

- [ ] **Step 1: Set up + run install once**

```bash
mkdir -p /tmp/memex-test-idempotent/.claude
cd /tmp/memex-test-idempotent
export MEMEX_DIR=/Users/gabriel/www/ribeirogab/agent-skills/skills/memex
```

Then paste the bash block printed in Task 7 Step 2 (the `COMMAND_NAMES=(...)` array plus both loops).

- [ ] **Step 2: Snapshot filesystem state**

```bash
find .agents .claude -ls | sort > /tmp/snapshot-before.txt
```

- [ ] **Step 3: Run the install block a second time**

Paste exactly the same block again.

- [ ] **Step 4: Snapshot again and diff**

```bash
find .agents .claude -ls | sort > /tmp/snapshot-after.txt
diff /tmp/snapshot-before.txt /tmp/snapshot-after.txt
```

Expected: no output. Inode numbers must match — the second run must not touch any file.

If `diff` shows any change, the migration branch (`[ -L ]` before `[ -f ]`) is wrong: it is `rm`-ing a working symlink and recreating it. Re-read Task 1 Step 2 and fix the condition order.

- [ ] **Step 5: Cleanup**

```bash
cd / && rm -rf /tmp/memex-test-idempotent /tmp/snapshot-before.txt /tmp/snapshot-after.txt
```

---

### Task 10: Scenario 3 — Fresh install without `.claude/` (AC10)

**Files:** scratch only.

- [ ] **Step 1: Set up scratch repo with no `.claude/`**

```bash
mkdir -p /tmp/memex-test-no-claude
cd /tmp/memex-test-no-claude
export MEMEX_DIR=/Users/gabriel/www/ribeirogab/agent-skills/skills/memex
```

Verify there is no `.claude/` directory:

```bash
[ ! -d .claude ] && echo "OK: no .claude/" || echo "WRONG: .claude exists"
```

- [ ] **Step 2: Run the install block**

Paste the same bash block printed in Task 7 Step 2 (the `COMMAND_NAMES=(...)` array plus both loops). The `.claude/`-gated symlink loop is a no-op here because `.claude/` is absent.

- [ ] **Step 3: Verify canonical files were created**

```bash
ls .agents/commands/ | sort
```

Expected: four-line listing (same as Task 7 Step 3).

- [ ] **Step 4: Verify no `.claude/` was auto-created**

```bash
[ ! -d .claude ] && echo "OK: .claude still absent" || echo "WRONG: .claude was created"
```

Expected: `OK: .claude still absent`.

- [ ] **Step 5: Run validation Check #11 manually against this repo**

```bash
for c in memex-learn memex-spec memex-review-spec memex-sweep; do
  [ -f ".agents/commands/$c.md" ] && echo "PASS: $c" || echo "FAIL: $c"
done
```

Expected: four `PASS:` lines (Check #11 PASSes even with `.claude/` absent).

- [ ] **Step 6: Cleanup**

```bash
cd / && rm -rf /tmp/memex-test-no-claude
```

---

## Phase 3: Open PR

### Task 11: Push branch and open PR

- [ ] **Step 1: Confirm clean tree on the feature branch**

```bash
git status
git log --oneline main..HEAD
```

Expected: working tree clean; the commit list shows the commits made in Phase 1 (one per task that committed).

- [ ] **Step 2: Push branch**

```bash
git push -u origin feat/memex-canonical-commands
```

- [ ] **Step 3: Open PR via `/memex-open-pr`**

Use the slash command. Title should be a one-liner like `Memex: canonical commands at .agents/commands + drop memex-open-pr`. Body should reference the spec at `.vault/specs/2026-05-05-memex-canonical-commands/spec.md` and note that:

- this repo's own `.claude/commands/memex-*.md` files are NOT migrated by this PR (out of scope per the spec — escopo A)
- this repo's `AGENTS.md` `## Commands (most used)` line for `/memex-open-pr` is NOT removed by this PR (out of scope, manual cleanup later)
- this repo's `.claude/commands/memex-open-pr.md` is NOT removed by this PR (orphan policy B, manual cleanup later)

---

## Phase 4: Mark spec as shipped

### Task 12: Update spec status

**Files:**
- Modify: `.vault/specs/2026-05-05-memex-canonical-commands/spec.md` (frontmatter)
- Modify: `.vault/_index/specs.md` (move entry from Active to Shipped)
- Modify: `tasks-memex-canonical-commands.md` (this file — tick all `[ ]` to `[x]`)

After PR merges to `main`:

- [ ] **Step 1: Tick every checkbox in this tasks file**

Use Edit with `replace_all` to change `- [ ]` to `- [x]` across the file.

- [ ] **Step 2: Update spec frontmatter**

In `spec-memex-canonical-commands.md`, change:

```yaml
status: draft
shipped: null
```

to:

```yaml
status: shipped
shipped: 2026-05-05  # or whatever the actual merge date is
```

- [ ] **Step 3: Move the spec entry in the MOC**

In `.vault/_index/specs.md`, cut the line under `## Active` and paste it under `## Shipped` at the top, updating the trailing date.

- [ ] **Step 4: Reflect (per AGENTS.md "After completing a spec")**

Ask yourself: did anything non-obvious come up during implementation? Common candidates:
- The `[ -L ]`-before-`[ -f ]` ordering is the kind of subtlety that would burn a future implementer — if this surprised you, write a learning note at `.vault/learnings/symlink-migration-test-order.md` (or similar) using `.vault/templates/learning.md`.
- If nothing non-obvious came up, say so explicitly in the final report.

- [ ] **Step 5: Commit reflection (if applicable)**

```bash
git add .vault/
git commit -m "docs: ship memex-canonical-commands spec + reflection learnings"
```
