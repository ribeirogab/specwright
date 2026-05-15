---
feature: memex-claude-plugin-namespace
plan: "[[plan-memex-claude-plugin-namespace]]"
spec: "[[spec-memex-claude-plugin-namespace]]"
created: 2026-05-15
---
# Memex Claude Plugin Namespace — Tasks

**For this plan:** `[[plan-memex-claude-plugin-namespace]]`

> All tasks operate on this repo (`/Users/gabriel/www/ribeirogab/agent-skills`). Work on a feature branch — never `main`. The PR is opened at the end (Phase 6) with both the spec and the implementation in the same diff per the maintainer's "ship spec in same PR" rule.

## Phase 0: Branch setup

### Task 0: Confirm feature branch

**Files:** none (git operation only)

- [x] **Step 1: Inspect current branch and tree**

```bash
git rev-parse --abbrev-ref HEAD
git status --short
```

Expected: branch is **not** `main` (this worktree was created off a side branch — `claude/flamboyant-sammet-d6ff1f` or similar is fine). Working tree contains only `.vault/specs/2026-05-15-memex-claude-plugin-namespace/` as untracked.

- [x] **Step 2: If currently on `main`, switch off it**

```bash
# Only if Step 1 reported `main`:
git switch -c feat/memex-claude-plugin-namespace
```

If Step 1 reported a side branch (worktree default), do nothing — keep working on it.

---

## Phase 1: Constitution amendment

### Task 1: Amend `.vault/constitution.md` § Scope guardrails

**Files:**
- Modify: `.vault/constitution.md` (the bullet list under `## Scope guardrails`)

The current `## Scope guardrails` section restricts in-scope paths to `skills/` and `skills/<skill>/scaffold/`. AC17 requires adding `.claude-plugin/marketplace.json` (repo root) and `plugins/<name>/` (repo root) as in-scope.

- [x] **Step 1: Read the current section to confirm the wording**

```bash
sed -n '/^## Scope guardrails$/,/^## /p' .vault/constitution.md | head -20
```

Expected: the section begins with `## Scope guardrails`, lists "In scope", "Out of scope", "Symlink discipline", "No build pipeline".

- [x] **Step 2: Replace the "In scope" bullet**

Find this line:

```
- **In scope**: Claude Code skills (under `skills/`) and the assets they ship to other repos (under `skills/<skill>/scaffold/`).
```

Replace with:

```
- **In scope**: Claude Code skills (under `skills/`) and the assets they ship to other repos (under `skills/<skill>/scaffold/`). Also in scope: the Claude Code marketplace manifest (`.claude-plugin/marketplace.json` at repo root) and Claude Code plugin sources (`plugins/<name>/` at repo root) — these are the Claude Code surface needed to distribute skills' slash commands under a colon namespace.
```

- [x] **Step 3: Verify the change reads correctly**

```bash
grep -A 1 '\*\*In scope\*\*' .vault/constitution.md
```

Expected: the new sentence appears immediately after the original `In scope` description, joined on the same bullet.

- [x] **Step 4: Commit**

```bash
git add .vault/constitution.md
git commit -m "constitution: scope marketplace.json and plugins/ as in-scope"
```

---

## Phase 2: Upstream marketplace surface

### Task 2: Create `.claude-plugin/marketplace.json`

**Files:**
- Create: `.claude-plugin/marketplace.json`

Implements AC1.

- [x] **Step 1: Create the directory**

```bash
mkdir -p .claude-plugin
```

- [x] **Step 2: Write the file**

`.claude-plugin/marketplace.json`:

```json
{
  "name": "agent-skills",
  "owner": {
    "name": "ribeirogab"
  },
  "plugins": [
    {
      "name": "memex",
      "source": "./plugins/memex",
      "description": "Memex slash commands for Claude Code — /memex:spec, /memex:learn, /memex:sweep, /memex:review-spec."
    }
  ]
}
```

- [x] **Step 3: Verify JSON parses and matches AC1**

```bash
jq -r '.name, .owner.name, .plugins[0].name, .plugins[0].source' .claude-plugin/marketplace.json
```

Expected output (exactly four lines):

```
agent-skills
ribeirogab
memex
./plugins/memex
```

- [x] **Step 4: Commit**

```bash
git add .claude-plugin/marketplace.json
git commit -m "feat: declare ribeirogab/agent-skills as a Claude Code marketplace"
```

### Task 3: Create `plugins/memex/.claude-plugin/plugin.json`

**Files:**
- Create: `plugins/memex/.claude-plugin/plugin.json`

Implements AC2.

- [x] **Step 1: Create the directory tree**

```bash
mkdir -p plugins/memex/.claude-plugin
```

- [x] **Step 2: Write the manifest**

`plugins/memex/.claude-plugin/plugin.json`:

```json
{
  "name": "memex",
  "description": "Memex slash commands: spec, learn, sweep, review-spec. Wraps the memex agent-memory workflow as Claude Code plugin commands."
}
```

(No `version` field — git SHA drives versioning per the spec's Non-Goal.)

- [x] **Step 3: Verify AC2**

```bash
jq -r '.name, has("version"), (.description | length > 0)' plugins/memex/.claude-plugin/plugin.json
```

Expected:

```
memex
false
true
```

- [x] **Step 4: Commit**

```bash
git add plugins/memex/.claude-plugin/plugin.json
git commit -m "feat(plugin): add memex plugin manifest"
```

### Task 4: Create plugin command bodies

**Files:**
- Create: `plugins/memex/commands/spec.md`
- Create: `plugins/memex/commands/learn.md`
- Create: `plugins/memex/commands/sweep.md`
- Create: `plugins/memex/commands/review-spec.md`

Implements AC3, AC4. Bodies copied verbatim from the pre-migration `.agents/commands/memex-<verb>.md` files; the only edits are `/memex-<verb>` → `/memex:<verb>` rewrites for the four affected verbs. Companion skill names (`memex-brainstorming`, `memex-writing-plans`, `memex-link`, `memex-recall`) stay hyphenated — they are skills, not commands, and remain in the hyphen form per the spec.

- [x] **Step 1: Create the commands directory**

```bash
mkdir -p plugins/memex/commands
```

- [x] **Step 2: Copy the four current command bodies**

```bash
cp .agents/commands/memex-spec.md         plugins/memex/commands/spec.md
cp .agents/commands/memex-learn.md        plugins/memex/commands/learn.md
cp .agents/commands/memex-sweep.md        plugins/memex/commands/sweep.md
cp .agents/commands/memex-review-spec.md  plugins/memex/commands/review-spec.md
```

- [x] **Step 3: Rewrite `/memex-<verb>` self-references in the four files**

Run a targeted substitution that only touches the four affected verbs (preserves `memex-brainstorming`, `memex-writing-plans`, `memex-link`, `memex-recall`):

```bash
for f in plugins/memex/commands/spec.md plugins/memex/commands/learn.md plugins/memex/commands/sweep.md plugins/memex/commands/review-spec.md; do
  sed -i.bak \
    -e 's|/memex-spec\b|/memex:spec|g' \
    -e 's|/memex-learn\b|/memex:learn|g' \
    -e 's|/memex-sweep\b|/memex:sweep|g' \
    -e 's|/memex-review-spec\b|/memex:review-spec|g' \
    "$f" && rm "$f.bak"
done
```

- [x] **Step 4: Verify no hyphen-form survives for the four affected verbs**

```bash
grep -nE '/memex-(spec|learn|sweep|review-spec)\b' plugins/memex/commands/*.md
```

Expected: no output (grep exits 1).

- [x] **Step 5: Verify companion skill names survived unchanged**

```bash
grep -nE 'memex-(brainstorming|writing-plans|link|recall)' plugins/memex/commands/*.md | head -5
```

Expected: matches inside `spec.md` (mentions `memex-brainstorming`, `memex-writing-plans`) — these stay hyphenated.

- [x] **Step 6: Verify AC4 directory listing**

```bash
ls plugins/memex/commands/
```

Expected: exactly four files, alphabetical:

```
learn.md  review-spec.md  spec.md  sweep.md
```

- [x] **Step 7: Commit**

```bash
git add plugins/memex/commands/
git commit -m "feat(plugin): add memex plugin command bodies (spec, learn, sweep, review-spec)"
```

---

## Phase 3: Memex skill rewrite

### Task 5: Create `skills/memex/references/claude-plugin-settings.md`

**Files:**
- Create: `skills/memex/references/claude-plugin-settings.md`

Implements AC10. This reference must exist before `SKILL.md` (Task 6) cites it.

- [x] **Step 1: Write the reference file**

`skills/memex/references/claude-plugin-settings.md`:

````markdown
# Claude Plugin Settings — Reference

The memex skill writes (or merges into) the target repo's `.claude/settings.json` so that Claude Code installs the upstream marketplace `agent-skills` plus the `memex` plugin at trust time. This reference is the **single source of truth** for the marketplace coordinates, the JSON shapes, and the merge recipe.

## Canonical coordinates

| Key             | Value                       |
| --------------- | --------------------------- |
| Marketplace name | `agent-skills`             |
| Marketplace source (target repos) | `{ "source": "github", "repo": "ribeirogab/agent-skills" }` |
| Marketplace source (this repo dogfood only) | `{ "source": "local", "path": "." }` |
| Plugin name     | `memex`                     |
| Enabled-plugins key | `memex@agent-skills`    |

## JSON shapes

The two keys to write under the top-level object are `extraKnownMarketplaces` and `enabledPlugins`.

`extraKnownMarketplaces["agent-skills"]` (target repos):

```json
{
  "source": {
    "source": "github",
    "repo": "ribeirogab/agent-skills"
  }
}
```

`enabledPlugins["memex@agent-skills"]`:

```json
true
```

## Merge recipe — jq (preferred)

`jq` is the preferred tool because it preserves existing top-level keys and avoids parse-rewrite-write round-trip bugs.

```bash
SETTINGS=".claude/settings.json"
TMP="$(mktemp)"

# Read existing settings (or start from {} if file is absent or empty)
if [ -s "$SETTINGS" ]; then
  cp "$SETTINGS" "$TMP"
else
  echo '{}' > "$TMP"
fi

jq '
  .extraKnownMarketplaces["agent-skills"] = {
    "source": { "source": "github", "repo": "ribeirogab/agent-skills" }
  } |
  .enabledPlugins["memex@agent-skills"] = true
' "$TMP" > "$SETTINGS"

rm "$TMP"
```

The recipe:

- Creates `.claude/settings.json` if absent (`mktemp` + `echo '{}'`).
- Preserves every other top-level key — `jq` only sets the two target paths.
- Overwrites the two target paths if they already exist (idempotent — re-running the recipe converges to the same final state).

## Merge recipe — Python fallback

If `jq` is not installed, use this inline Python snippet. Behaviour matches the jq recipe.

```bash
python3 - <<'PY'
import json, os, pathlib
p = pathlib.Path(".claude/settings.json")
data = json.loads(p.read_text()) if p.exists() and p.read_text().strip() else {}
data.setdefault("extraKnownMarketplaces", {})["agent-skills"] = {
    "source": {"source": "github", "repo": "ribeirogab/agent-skills"}
}
data.setdefault("enabledPlugins", {})["memex@agent-skills"] = True
p.write_text(json.dumps(data, indent=2) + "\n")
PY
```

If neither `jq` nor `python3` is available, the skill must report a clear error and emit the snippet the user should paste manually. The skill **must not** overwrite the file with a templated full-file write — that would clobber unrelated keys.

## Dogfood note (this repo only)

When the memex skill runs **inside `ribeirogab/agent-skills` itself** (the marketplace repo), the dogfood `.claude/settings.json` declares the marketplace source as `{ "source": "local", "path": "." }` instead of the GitHub source above. This keeps the maintainer's inner dev loop fast — local edits to `plugins/memex/` are picked up on `/plugin marketplace update` without commit-push-fetch. The github source is for **target repos** (every other repo). The skill detects this case by checking whether the current repo's `.claude-plugin/marketplace.json` declares `name = "agent-skills"`; if it does, use the local source.

## Trade-off-rejected alternatives (from Architecture Decision 3)

For the historical record so this question is not re-litigated:

1. **Documented manual `/plugin marketplace add` + `/plugin install`** — rejected because every team member would re-run two commands per fresh clone, and the `.claude/settings.json` route gives identical UX with one trust-prompt acceptance.
2. **Skill running `/plugin` commands via bash** — rejected because the `/plugin` slash command is a Claude Code TUI primitive, not a shell command; the skill cannot invoke it from a bash block.
````

- [x] **Step 2: Verify AC10 — file exists, contains canonical coordinates, JSON shapes, jq recipe, Python fallback, two rejected alternatives**

```bash
test -f skills/memex/references/claude-plugin-settings.md && echo PASS_EXISTS
grep -c 'memex@agent-skills' skills/memex/references/claude-plugin-settings.md
grep -q '## Merge recipe — jq (preferred)' skills/memex/references/claude-plugin-settings.md && echo PASS_JQ
grep -q '## Merge recipe — Python fallback' skills/memex/references/claude-plugin-settings.md && echo PASS_PY
grep -c '^[0-9]\. \*\*' skills/memex/references/claude-plugin-settings.md
```

Expected:
```
PASS_EXISTS
(at least 4)
PASS_JQ
PASS_PY
2
```

- [x] **Step 3: Commit**

```bash
git add skills/memex/references/claude-plugin-settings.md
git commit -m "feat(memex): add claude-plugin-settings reference"
```

### Task 6: Rewrite `skills/memex/SKILL.md` Phase 4 commands block

**Files:**
- Modify: `skills/memex/SKILL.md` (between line ~123 `**Slash commands** install canonically...` and line ~159 `Per-agent dirs that do not already exist...`)

Implements AC8, AC9.

- [x] **Step 1: Replace the current "Slash commands" block + its bash recipe with the new legacy-removal + settings.json merge block**

Find the entire block starting at the line:

```markdown
**Slash commands** install canonically under `.agents/commands/<cmd>.md` (single source of truth on disk, agent-agnostic location) and are exposed via per-agent symlinks. Slash-command UI is a Claude Code-specific concept today — no other current agent has an equivalent — so the symlink loop targets only `.claude/commands/`. If `.claude/` does not exist in the repo, the canonical files are still installed (they are the source of truth) but no symlinks are created. The workflows the commands encode are useful in any agent; users on other agents invoke them via prose prompts, not via `/foo` syntax.
```

…and ending at the closing fence of the bash block that follows it (the one ending with `fi`). Replace the entire block (the prose paragraph plus the bash block) with:

````markdown
**Slash commands** ship as a Claude Code plugin published from the upstream marketplace `agent-skills` (this repo's root `.claude-plugin/marketplace.json`). The four slash commands — `/memex:spec`, `/memex:learn`, `/memex:sweep`, `/memex:review-spec` — live in `plugins/memex/commands/` upstream and are fetched by Claude Code at workspace-trust time. The memex skill **does not copy command files into the target repo** — it only declares the marketplace and pre-enables the plugin via `.claude/settings.json`.

The skill does two things at install time, both gated on the target repo having a `.claude/` directory (its absence signals the user does not run Claude Code in this repo):

1. **Remove legacy command files** that pre-plugin memex installs left behind: `.claude/commands/memex-{spec,learn,sweep,review-spec}.md` and `.agents/commands/memex-{spec,learn,sweep,review-spec}.md`. This is a non-destructive op per the existing "scaffold sempre vence" policy — no prompt, no diff. `rm` works for both regular files and symlinks.
2. **Merge marketplace + plugin entries** into `.claude/settings.json`. Read `references/claude-plugin-settings.md` for the canonical coordinates, the JSON shapes, the jq merge recipe (preferred), and the Python fallback.

```bash
# 1. Remove legacy command files for the four affected verbs.
#    rm works for files and symlinks alike. Missing files are not an error.
for cmd in memex-spec memex-learn memex-sweep memex-review-spec; do
  rm -f ".claude/commands/$cmd.md" 2>/dev/null
  rm -f ".agents/commands/$cmd.md" 2>/dev/null
done

# Also remove the .agents/commands/ directory if it is now empty (only the four
# legacy files lived there; if anything else is present, leave it alone).
if [ -d .agents/commands ] && [ -z "$(ls -A .agents/commands 2>/dev/null)" ]; then
  rmdir .agents/commands
fi

# 2. Merge marketplace + plugin entries into .claude/settings.json — only when
#    .claude/ exists in the target repo. Read references/claude-plugin-settings.md
#    for the canonical coordinates, JSON shapes, jq recipe, and Python fallback.
if [ -d .claude ]; then
  # Detect dogfood: if this repo's own .claude-plugin/marketplace.json declares
  # name = "agent-skills", use the local-path source. Otherwise use github.
  if [ -f .claude-plugin/marketplace.json ] && \
     [ "$(jq -r '.name' .claude-plugin/marketplace.json 2>/dev/null)" = "agent-skills" ]; then
    MARKETPLACE_SOURCE='{"source":"local","path":"."}'
  else
    MARKETPLACE_SOURCE='{"source":"github","repo":"ribeirogab/agent-skills"}'
  fi

  SETTINGS=".claude/settings.json"
  TMP="$(mktemp)"
  if [ -s "$SETTINGS" ]; then
    cp "$SETTINGS" "$TMP"
  else
    echo '{}' > "$TMP"
  fi

  jq --argjson src "$MARKETPLACE_SOURCE" '
    .extraKnownMarketplaces["agent-skills"] = { "source": $src } |
    .enabledPlugins["memex@agent-skills"] = true
  ' "$TMP" > "$SETTINGS"
  rm "$TMP"
fi
```

If `jq` is not installed, fall back to the Python recipe documented in `references/claude-plugin-settings.md`. The skill must never overwrite `.claude/settings.json` wholesale — unrelated top-level keys must survive intact.
````

- [x] **Step 2: Update the "Rules" bullet list below the new block**

Find the `Rules:` block (still inside `### Skills and commands (copy from scaffold/)`) and replace the command-specific bullets. The old block reads:

```markdown
Rules:
- Skills always go to `.agents/skills/<name>` first (canonical), then symlinked into existing agent dirs.
- Commands always go to `.agents/commands/<cmd>.md` first (canonical), then symlinked into `.claude/commands/` if `.claude/` exists. Slash commands are Claude-only today — no Codex/Cursor equivalent — so the symlink loop is single-agent.
- Existing canonical files are never overwritten — re-runs are no-ops on already-installed items.
- Existing regular files at a command symlink target are removed and replaced with a symlink (migration path). Existing symlinks are left alone.
- Per-agent dirs that do not already exist are not auto-created by the skill copy; only an existing dir signals that agent is in use here.
```

Replace with:

```markdown
Rules:
- Skills always go to `.agents/skills/<name>` first (canonical), then symlinked into existing agent dirs.
- Slash commands ship as a Claude Code plugin from the upstream marketplace `agent-skills`. The skill writes `.claude/settings.json` (extraKnownMarketplaces + enabledPlugins) so Claude Code installs the plugin at workspace-trust time. No command files are copied into the target repo.
- Existing canonical skill files are never overwritten — re-runs are no-ops on already-installed items.
- Legacy `.claude/commands/memex-{spec,learn,sweep,review-spec}.md` and `.agents/commands/memex-*.md` files (from pre-plugin installs) are removed unconditionally on every run. `rm` works for regular files and symlinks.
- Per-agent dirs that do not already exist are not auto-created by the skill copy; only an existing dir signals that agent is in use here.
- `.claude/settings.json` is created if absent (with `{}` as the seed) or merged into if present — every unrelated top-level key survives.
```

- [x] **Step 3: Verify AC8 — no `.agents/commands` or `.claude/commands` creation in SKILL.md**

```bash
grep -nE '(\.agents/commands|\.claude/commands)' skills/memex/SKILL.md
```

Expected: only **removal** lines (`rm -f`) — no `mkdir -p .agents/commands`, no `cp ... .agents/commands/`, no `ln -s ... .claude/commands/`.

- [x] **Step 4: Verify AC9 — new block contains legacy-removal loop, dogfood detection, and the jq settings merge**

```bash
grep -nE '(rm -f "\.claude/commands|jq --argjson src|MARKETPLACE_SOURCE|extraKnownMarketplaces\["agent-skills"\])' skills/memex/SKILL.md
```

Expected: at least four matches across the new block.

- [x] **Step 5: Commit**

```bash
git add skills/memex/SKILL.md
git commit -m "feat(memex): replace command scaffold block with plugin-via-settings flow"
```

### Task 7: Update `skills/memex/references/audit-checklist.md`

**Files:**
- Modify: `skills/memex/references/audit-checklist.md`

Implements AC11, AC12.

- [x] **Step 1: Remove the four `.agents/commands/memex-*.md` entries from the "Files and directories to check" block**

Find and delete these four lines:

```
.agents/commands/memex-learn.md                 (canonical — slash commands, agent-agnostic location)
.agents/commands/memex-spec.md
.agents/commands/memex-review-spec.md
.agents/commands/memex-sweep.md
```

Verify the surrounding `.agents/skills/...` entries are untouched.

- [x] **Step 2: Delete the entire "Per-agent command symlinks (Claude Code only)" subsection**

Find the heading `### Per-agent command symlinks (Claude Code only)` and delete the heading plus its body (down to the next `### ` or `## ` heading). The deleted body discusses the canonical-plus-symlink command pattern that no longer applies.

- [x] **Step 3: Add a new "Legacy paths to remove" subsection** under `## Additional checks`

Insert this new subsection immediately before the existing `### CLAUDE.md is a symlink (Claude Code back-compat)` heading:

```markdown
### Legacy paths to remove (pre-plugin migration)

The pre-plugin memex installed slash commands as files at:

- `.agents/commands/memex-{spec,learn,sweep,review-spec}.md` (canonical)
- `.claude/commands/memex-{spec,learn,sweep,review-spec}.md` (symlink)

These are obsolete — slash commands now ship as a Claude Code plugin from the upstream marketplace `agent-skills`. Any of these files (regular or symlink) is `DRIFT`. Fix: `rm` the file in Phase 4. This is a non-destructive op per the "scaffold sempre vence" policy — no prompt.

If `.agents/commands/` becomes empty after the removals, the directory itself is also removed (`rmdir` succeeds only on empty dirs, so this is safe even if an unrelated file still sits there).

Legacy `.claude/commands/memex-open-pr.md` is **not** in scope here — orphan policy B from the previous canonical-commands spec leaves it untouched.
```

- [x] **Step 4: Add a new "Claude plugin settings present (when `.claude/` exists)" check** under `## Additional checks`

Insert this new subsection after the new "Legacy paths to remove" block:

````markdown
### Claude plugin settings present (when `.claude/` exists)

When the target repo has a `.claude/` directory (signal that the user runs Claude Code in this repo), `.claude/settings.json` must declare:

- `extraKnownMarketplaces["agent-skills"]` with a non-empty `source` object (either `{ "source": "github", "repo": "ribeirogab/agent-skills" }` for target repos, or `{ "source": "local", "path": "." }` for this repo's own dogfood).
- `enabledPlugins["memex@agent-skills"]` set to `true`.

Detection:

```bash
if [ -d .claude ]; then
  if [ ! -f .claude/settings.json ]; then
    echo "DRIFT — .claude/settings.json missing"
  else
    has_mp=$(jq 'has("extraKnownMarketplaces") and .extraKnownMarketplaces | has("agent-skills")' .claude/settings.json)
    has_plugin=$(jq '.enabledPlugins["memex@agent-skills"] == true' .claude/settings.json)
    if [ "$has_mp" != "true" ] || [ "$has_plugin" != "true" ]; then
      echo "DRIFT — settings.json missing marketplace or plugin entry"
    fi
  fi
fi
```

If `.claude/` is absent, this check does not run (no signal to gate on). Fix in Phase 4: run the jq merge recipe from `references/claude-plugin-settings.md`.
````

- [x] **Step 5: Verify AC11**

```bash
grep -nE '\.agents/commands/memex-(spec|learn|sweep|review-spec)\.md' skills/memex/references/audit-checklist.md
grep -nE '^### Per-agent command symlinks' skills/memex/references/audit-checklist.md
grep -nE '^### Claude plugin settings present' skills/memex/references/audit-checklist.md
```

Expected:
- First grep: no output (entries removed).
- Second grep: no output (subsection deleted).
- Third grep: one match (new subsection added).

- [x] **Step 6: Verify AC12**

```bash
grep -nE '^### Legacy paths to remove' skills/memex/references/audit-checklist.md
```

Expected: one match.

- [x] **Step 7: Commit**

```bash
git add skills/memex/references/audit-checklist.md
git commit -m "feat(memex): audit-checklist drops .agents/commands entries; adds legacy-removal + plugin-settings checks"
```

### Task 8: Update `skills/memex/references/validation.md` Check #11

**Files:**
- Modify: `skills/memex/references/validation.md`

Implements AC13. Total check count stays at 15.

- [x] **Step 1: Replace Check #11's body**

Find `### 11. Canonical commands installed` and the bash block + fix line that follows it. Replace the entire section with:

````markdown
### 11. Claude plugin settings present (when `.claude/` exists)

Slash commands ship as a Claude Code plugin from the upstream marketplace `agent-skills`. When the target repo has a `.claude/` directory, `.claude/settings.json` must declare both `extraKnownMarketplaces["agent-skills"]` (with any non-empty `source` object) and `enabledPlugins["memex@agent-skills"] = true`. If `.claude/` is absent, this check trivially PASSes — the user does not run Claude Code here, so no settings.json is required.

```bash
if [ ! -d .claude ]; then
  echo PASS
elif [ ! -f .claude/settings.json ]; then
  echo FAIL
else
  has_mp=$(jq 'has("extraKnownMarketplaces") and (.extraKnownMarketplaces | has("agent-skills"))' .claude/settings.json 2>/dev/null)
  has_src=$(jq '.extraKnownMarketplaces["agent-skills"].source != null' .claude/settings.json 2>/dev/null)
  has_plugin=$(jq '.enabledPlugins["memex@agent-skills"] == true' .claude/settings.json 2>/dev/null)
  if [ "$has_mp" = "true" ] && [ "$has_src" = "true" ] && [ "$has_plugin" = "true" ]; then
    echo PASS
  else
    echo FAIL
  fi
fi
```

Fix: re-run the settings.json merge block from `SKILL.md` (Phase 4), which uses the jq recipe in `references/claude-plugin-settings.md`. If `jq` is unavailable, fall back to the Python recipe in the same reference.
````

- [x] **Step 2: Verify total check count is still 15**

```bash
grep -cE '^### [0-9]+\. ' skills/memex/references/validation.md
```

Expected: `15`.

- [x] **Step 3: Verify Check #11 no longer references `.agents/commands` or `memex-open-pr`**

```bash
grep -nE '(\.agents/commands|memex-open-pr)' skills/memex/references/validation.md
```

Expected: no output.

- [x] **Step 4: Verify the "Contents" section at the top still names 15 numbered checks**

Read the bullet list under `## Contents` and confirm the line description for Check #11 mentions plugin settings (not canonical commands). If the line still says `canonical skills/commands installed`, edit it to say `Claude plugin settings present`. The original text is at the top of `validation.md` line 10.

- [x] **Step 5: Commit**

```bash
git add skills/memex/references/validation.md
git commit -m "feat(memex): Phase 5 Check #11 validates settings.json plugin entries"
```

### Task 9: Update `skills/memex/references/agents-md-template.md`

**Files:**
- Modify: `skills/memex/references/agents-md-template.md`

Implements AC14.

- [x] **Step 1: Substitute the four affected slash-command forms**

```bash
sed -i.bak \
  -e 's|/memex-spec\b|/memex:spec|g' \
  -e 's|/memex-learn\b|/memex:learn|g' \
  -e 's|/memex-sweep\b|/memex:sweep|g' \
  -e 's|/memex-review-spec\b|/memex:review-spec|g' \
  skills/memex/references/agents-md-template.md && rm skills/memex/references/agents-md-template.md.bak
```

- [x] **Step 2: Verify only slash forms changed; companion skill names survived**

```bash
grep -nE '/memex-(spec|learn|sweep|review-spec)\b' skills/memex/references/agents-md-template.md
grep -nE 'memex-(brainstorming|writing-plans|link|recall)' skills/memex/references/agents-md-template.md | head -5
```

Expected:
- First grep: no output.
- Second grep: at least three matches (the bare-skill-name bullets near `## Skills and slash commands`).

- [x] **Step 3: Add the cross-agent note near the top of `## Skills and slash commands`**

Open `skills/memex/references/agents-md-template.md`, find the heading `## Skills and slash commands`, and insert the following line immediately after the heading (before the first sub-bullet):

```markdown
> Slash commands shown in Claude Code syntax (plugin namespace `memex:`). Codex users invoke as `$memex-<verb>` via skill mention. Cursor users as `@memex-<verb>` via rule reference. Companion skills (`memex-brainstorming`, `memex-writing-plans`, `memex-recall`, `memex-link`) keep the hyphen form on every agent.
```

- [x] **Step 4: Verify the note landed in the right section**

```bash
awk '/^## Skills and slash commands/,/^## /' skills/memex/references/agents-md-template.md | head -5
```

Expected: the blockquote line appears in the first 3–5 lines after the heading.

- [x] **Step 5: Commit**

```bash
git add skills/memex/references/agents-md-template.md
git commit -m "feat(memex): AGENTS.md template uses /memex:verb form + cross-agent note"
```

### Task 10: Delete `skills/memex/scaffold/commands/`

**Files:**
- Delete: `skills/memex/scaffold/commands/` (directory + all contents)

Implements AC16.

- [x] **Step 1: Inspect contents before deletion (sanity)**

```bash
ls skills/memex/scaffold/commands/
```

Expected: `memex-learn.md`, `memex-review-spec.md`, `memex-spec.md`, `memex-sweep.md` (four files — these were never used after Task 6's SKILL.md rewrite because Phase 4 no longer copies them).

- [x] **Step 2: Remove with git**

```bash
git rm -r skills/memex/scaffold/commands/
```

- [x] **Step 3: Verify AC16**

```bash
test ! -d skills/memex/scaffold/commands && echo PASS_DELETED
```

Expected: `PASS_DELETED`.

- [x] **Step 4: Commit**

```bash
git commit -m "chore(memex): drop scaffold/commands/ — plugin source replaces canonical command files"
```

---

## Phase 4: Dogfood this repo

### Task 11: Delete legacy command files from this repo

**Files:**
- Delete: `.claude/commands/memex-spec.md`, `.claude/commands/memex-learn.md`, `.claude/commands/memex-sweep.md`, `.claude/commands/memex-review-spec.md` (all symlinks)
- Delete: `.agents/commands/memex-spec.md`, `.agents/commands/memex-learn.md`, `.agents/commands/memex-sweep.md`, `.agents/commands/memex-review-spec.md` (canonical files)
- Delete: `.agents/commands/` directory (after emptied)

Implements AC5, AC6 for this repo's dogfood.

- [x] **Step 1: Inspect before deletion**

```bash
ls .claude/commands/ .agents/commands/
```

Expected: each lists the four `memex-<verb>.md` entries.

- [x] **Step 2: Remove the eight files**

```bash
git rm .claude/commands/memex-spec.md \
       .claude/commands/memex-learn.md \
       .claude/commands/memex-sweep.md \
       .claude/commands/memex-review-spec.md \
       .agents/commands/memex-spec.md \
       .agents/commands/memex-learn.md \
       .agents/commands/memex-sweep.md \
       .agents/commands/memex-review-spec.md
```

- [x] **Step 3: Remove `.agents/commands/` directory if it is now empty**

```bash
if [ -d .agents/commands ] && [ -z "$(ls -A .agents/commands 2>/dev/null)" ]; then
  rmdir .agents/commands
fi
```

(Use `rmdir` rather than `rm -rf` — `rmdir` refuses if anything unexpected is still present.)

- [x] **Step 4: Verify AC5 and AC6**

```bash
test ! -d .agents/commands && echo PASS_AGENTS_GONE
find .claude/commands -name 'memex-*' 2>/dev/null
```

Expected:
- `PASS_AGENTS_GONE`
- second `find` returns no output.

- [x] **Step 5: Commit**

```bash
git add -A .agents .claude/commands
git commit -m "chore(dogfood): remove legacy .agents/commands and .claude/commands/memex-* symlinks"
```

### Task 12: Create this repo's `.claude/settings.json`

**Files:**
- Create: `.claude/settings.json`

Implements AC7. Uses the local-path dogfood source per AD7.

- [x] **Step 1: Write the settings file**

`.claude/settings.json`:

```json
{
  "extraKnownMarketplaces": {
    "agent-skills": {
      "source": {
        "source": "local",
        "path": "."
      }
    }
  },
  "enabledPlugins": {
    "memex@agent-skills": true
  }
}
```

- [x] **Step 2: Verify AC7**

```bash
jq -c '.extraKnownMarketplaces["agent-skills"].source' .claude/settings.json
jq '.enabledPlugins["memex@agent-skills"]' .claude/settings.json
```

Expected (two lines, in order):

```
{"source":"local","path":"."}
true
```

- [x] **Step 3: Commit**

```bash
git add .claude/settings.json
git commit -m "chore(dogfood): claude settings declare local-path marketplace + enable memex plugin"
```

### Task 13: Substitute slash forms in this repo's `AGENTS.md`

**Files:**
- Modify: `AGENTS.md` (repo root)

Implements AC15.

- [x] **Step 1: Substitute the four affected slash forms**

```bash
sed -i.bak \
  -e 's|/memex-spec\b|/memex:spec|g' \
  -e 's|/memex-learn\b|/memex:learn|g' \
  -e 's|/memex-sweep\b|/memex:sweep|g' \
  -e 's|/memex-review-spec\b|/memex:review-spec|g' \
  AGENTS.md && rm AGENTS.md.bak
```

- [x] **Step 2: Insert the cross-agent note**

Open `AGENTS.md`, find the heading `## Skills and slash commands`, and insert immediately after it:

```markdown
> Slash commands shown in Claude Code syntax (plugin namespace `memex:`). Codex users invoke as `$memex-<verb>` via skill mention. Cursor users as `@memex-<verb>` via rule reference. Companion skills (`memex-brainstorming`, `memex-writing-plans`, `memex-recall`, `memex-link`) keep the hyphen form on every agent.
```

- [x] **Step 3: Verify AC15**

```bash
grep -nE '/memex-(spec|learn|sweep|review-spec)\b' AGENTS.md
grep -nE 'plugin namespace `memex:`' AGENTS.md
wc -l AGENTS.md
```

Expected:
- First grep: no output.
- Second grep: one match.
- `wc -l`: ≤ 80 (Phase 5 Check #14 caps AGENTS.md at 80 lines — the added blockquote should not push it past the cap; if it does, tighten one of the bullet descriptions until the count is ≤ 80).

- [x] **Step 4: Commit**

```bash
git add AGENTS.md
git commit -m "chore(dogfood): AGENTS.md uses /memex:verb form + cross-agent note"
```

---

## Phase 5: Verification

### Task 14: Run memex audit + Phase 5 on this repo

**Files:** none (verification only — read-only audit on real state)

This is the end-to-end behaviour check on the real repo. AC18 (clean) is not satisfied here because this repo has the new dogfood plugin scaffold and AGENTS.md fully populated, but the audit must report 15/15 PASS with **zero filesystem changes**.

- [x] **Step 1: Invoke the memex skill against this repo**

Open Claude Code in this repo (the worktree is fine — memex audits the current working directory) and run:

```
/memex
```

Expected behaviour:

- Phase 1 audit lists every required item as `OK`.
- Phase 2 summary: e.g. `25/25 items OK, 0 missing, 0 drifted` (exact count depends on `references/audit-checklist.md` after Task 7).
- Phase 3 skipped (nothing to fix).
- Phase 5 validation: `15/15 PASS`.
- Final summary: "Memex Audit Complete — Validation: 15/15 PASS" and no `git status` changes outside of any committed work above.

- [x] **Step 2: Spot-check the new Check #11**

Manually run the Check #11 bash block from `skills/memex/references/validation.md` against this repo:

```bash
if [ ! -d .claude ]; then
  echo PASS
elif [ ! -f .claude/settings.json ]; then
  echo FAIL
else
  has_mp=$(jq 'has("extraKnownMarketplaces") and (.extraKnownMarketplaces | has("agent-skills"))' .claude/settings.json 2>/dev/null)
  has_src=$(jq '.extraKnownMarketplaces["agent-skills"].source != null' .claude/settings.json 2>/dev/null)
  has_plugin=$(jq '.enabledPlugins["memex@agent-skills"] == true' .claude/settings.json 2>/dev/null)
  if [ "$has_mp" = "true" ] && [ "$has_src" = "true" ] && [ "$has_plugin" = "true" ]; then
    echo PASS
  else
    echo FAIL
  fi
fi
```

Expected: `PASS`.

- [x] **Step 3: Confirm no uncommitted changes**

```bash
git status --short
```

Expected: no output (clean working tree).

- [x] **Step 4: Verify AC23 — trust-prompt flow installs marketplace + plugin**

This is a one-time manual check in Claude Code (cannot be automated). Open this repo in a Claude Code window that has **not** yet trusted this worktree (e.g., a fresh `claude` invocation in this dir):

1. Accept the workspace trust prompt.
2. Claude Code should display a follow-up prompt: "Install marketplace `agent-skills` and enabled plugin `memex@agent-skills`?" Accept.
3. After acceptance, run `/help` in the Claude Code prompt.

Expected:
- `/help` lists `/memex:spec`, `/memex:learn`, `/memex:sweep`, `/memex:review-spec`.
- `/help` does **not** list `/memex-spec` or any hyphen-form memex command (the four affected verbs only — companion skills like `/memex-brainstorming` legitimately stay hyphenated).
- Each plugin command, when invoked with no arguments, runs its workflow body.

If the prompt does not appear (e.g., older Claude Code version), fall back to the manual install path documented in `skills/memex/references/claude-plugin-settings.md`:

```
/plugin marketplace add ribeirogab/agent-skills
/plugin install memex@agent-skills
/reload-plugins
```

Then re-run `/help` and confirm the four `/memex:<verb>` commands appear.

### Task 15: Scratch test — fresh install with `.claude/` (AC18, AC19)

**Files:** none (scratch dir in `/tmp/`)

- [x] **Step 1: Create a scratch repo with empty `.claude/`**

```bash
mkdir -p /tmp/memex-test-fresh-claude && cd /tmp/memex-test-fresh-claude
git init -q
mkdir -p .claude
echo "{}" > package.json   # so memex Prerequisites have something to read
```

- [x] **Step 2: Invoke the memex skill from Claude Code pointed at this dir**

In Claude Code, change working dir to `/tmp/memex-test-fresh-claude` and run `/memex`.

Expected:
- Vault scaffolds, AGENTS.md created, companion skills under `.agents/skills/` symlinked into `.claude/skills/`.
- No `.claude/commands/` directory is created.
- No `.agents/commands/` directory is created.
- `.claude/settings.json` is created with `extraKnownMarketplaces["agent-skills"]` (github source — this is NOT the dogfood) and `enabledPlugins["memex@agent-skills"] = true`.
- Phase 5: 15/15 PASS.

- [x] **Step 3: Verify**

```bash
cd /tmp/memex-test-fresh-claude
test ! -d .claude/commands && test ! -d .agents/commands && echo PASS_NO_COMMAND_DIRS
jq -c '.extraKnownMarketplaces["agent-skills"].source' .claude/settings.json
jq '.enabledPlugins["memex@agent-skills"]' .claude/settings.json
```

Expected:

```
PASS_NO_COMMAND_DIRS
{"source":"github","repo":"ribeirogab/agent-skills"}
true
```

- [x] **Step 4: Clean up**

```bash
rm -rf /tmp/memex-test-fresh-claude
```

### Task 16: Scratch test — migration from pre-plugin install (AC20)

**Files:** none (scratch dir in `/tmp/`)

- [x] **Step 1: Seed a scratch repo that simulates a pre-plugin install**

```bash
mkdir -p /tmp/memex-test-migration && cd /tmp/memex-test-migration
git init -q
mkdir -p .agents/commands .claude/commands
echo "old spec body"        > .agents/commands/memex-spec.md
echo "old learn body"       > .agents/commands/memex-learn.md
echo "old sweep body"       > .agents/commands/memex-sweep.md
echo "old review-spec body" > .agents/commands/memex-review-spec.md
echo "stale open-pr body"   > .agents/commands/memex-open-pr.md   # orphan policy B
ln -s ../../.agents/commands/memex-spec.md         .claude/commands/memex-spec.md
ln -s ../../.agents/commands/memex-learn.md        .claude/commands/memex-learn.md
ln -s ../../.agents/commands/memex-sweep.md        .claude/commands/memex-sweep.md
ln -s ../../.agents/commands/memex-review-spec.md  .claude/commands/memex-review-spec.md
ln -s ../../.agents/commands/memex-open-pr.md      .claude/commands/memex-open-pr.md
echo "{}" > package.json
```

- [x] **Step 2: Invoke `/memex` against the scratch dir**

In Claude Code, change working dir to `/tmp/memex-test-migration` and run `/memex`.

Expected:
- Eight legacy files removed (`.claude/commands/memex-{spec,learn,sweep,review-spec}.md` + their `.agents/commands/` targets).
- `.claude/commands/memex-open-pr.md` and `.agents/commands/memex-open-pr.md` left untouched (orphan policy B).
- `.agents/commands/` directory NOT removed (because `memex-open-pr.md` is still there).
- `.claude/settings.json` created with github source.
- Phase 5: 15/15 PASS.

- [x] **Step 3: Verify**

```bash
cd /tmp/memex-test-migration
find .claude/commands -name 'memex-spec.md' -o -name 'memex-learn.md' -o -name 'memex-sweep.md' -o -name 'memex-review-spec.md'
find .agents/commands -name 'memex-spec.md' -o -name 'memex-learn.md' -o -name 'memex-sweep.md' -o -name 'memex-review-spec.md'
test -f .agents/commands/memex-open-pr.md && echo PASS_OPEN_PR_INTACT
test -f .claude/commands/memex-open-pr.md && echo PASS_OPEN_PR_SYMLINK_INTACT
jq '.enabledPlugins["memex@agent-skills"]' .claude/settings.json
```

Expected:
- First two `find`s: no output (removed).
- `PASS_OPEN_PR_INTACT`
- `PASS_OPEN_PR_SYMLINK_INTACT`
- `true`

- [x] **Step 4: Clean up**

```bash
rm -rf /tmp/memex-test-migration
```

### Task 17: Scratch test — idempotent re-run (AC22)

**Files:** none (scratch dir in `/tmp/`)

- [x] **Step 1: Stand up the same fresh scratch from Task 15 and run `/memex` once**

(Same Steps 1–2 from Task 15. After that first run completes, **do not delete** the scratch — leave it as-is.)

- [x] **Step 2: Snapshot the filesystem**

```bash
cd /tmp/memex-test-fresh-claude
git add -A
git -c user.email=test@local -c user.name=test commit -q -m "after first memex run"
```

- [x] **Step 3: Re-run `/memex` from Claude Code against the same dir**

Expected: audit reports everything OK, no scaffold/fix steps, Phase 5 reports 15/15 PASS, no filesystem changes.

- [x] **Step 4: Verify diff is empty**

```bash
git status --short
```

Expected: no output.

- [x] **Step 5: Clean up**

```bash
rm -rf /tmp/memex-test-fresh-claude
```

### Task 17b: Scratch test — settings.json merge preserves unrelated keys (AC21)

**Files:** none (scratch dir in `/tmp/`)

- [x] **Step 1: Stand up a scratch repo whose `.claude/settings.json` already has an unrelated top-level key**

```bash
mkdir -p /tmp/memex-test-merge && cd /tmp/memex-test-merge
git init -q
mkdir -p .claude
cat > .claude/settings.json <<'EOF'
{
  "permissions": {
    "allow": ["Bash(npm test:*)"]
  },
  "env": {
    "DEBUG": "0"
  }
}
EOF
echo "{}" > package.json
```

- [x] **Step 2: Invoke `/memex` against the dir**

Run `/memex` from Claude Code with cwd `/tmp/memex-test-merge`.

- [x] **Step 3: Verify pre-existing keys survived and new keys were added**

```bash
cd /tmp/memex-test-merge
jq '.permissions.allow' .claude/settings.json
jq '.env.DEBUG' .claude/settings.json
jq '.extraKnownMarketplaces["agent-skills"].source' .claude/settings.json
jq '.enabledPlugins["memex@agent-skills"]' .claude/settings.json
```

Expected (four lines, in order):

```
[
  "Bash(npm test:*)"
]
"0"
{"source":"github","repo":"ribeirogab/agent-skills"}
true
```

- [x] **Step 4: Clean up**

```bash
rm -rf /tmp/memex-test-merge
```

### Task 18: Scratch test — install without `.claude/` (AC18 no-Claude, Check #11 trivial PASS)

**Files:** none (scratch dir in `/tmp/`)

- [x] **Step 1: Stand up a scratch repo with no `.claude/`**

```bash
mkdir -p /tmp/memex-test-no-claude && cd /tmp/memex-test-no-claude
git init -q
mkdir -p .codex/skills   # signal: user is on Codex, not Claude Code
echo "{}" > package.json
```

- [x] **Step 2: Invoke `/memex` against the dir**

Run `/memex` from Claude Code (the skill audits the current dir regardless of which agent triggered it).

Expected:
- Vault scaffolds, AGENTS.md created, companion skills under `.agents/skills/` symlinked into `.codex/skills/`.
- No `.claude/` directory is created.
- No `.claude/settings.json` is created (no `.claude/` triggers no settings.json).
- Phase 5 Check #11 trivially PASSes (no `.claude/` → echo PASS branch).
- Phase 5: 15/15 PASS.

- [x] **Step 3: Verify**

```bash
cd /tmp/memex-test-no-claude
test ! -d .claude && echo PASS_NO_CLAUDE
test ! -d .agents/commands && echo PASS_NO_COMMANDS
find . -name '*.md' -path '*/.agents/skills/*' | head -3
```

Expected:
- `PASS_NO_CLAUDE`
- `PASS_NO_COMMANDS`
- at least three `SKILL.md` paths under `.agents/skills/`.

- [x] **Step 4: Clean up**

```bash
rm -rf /tmp/memex-test-no-claude
```

---

## Phase 6: PR

### Task 19: Open the PR

**Files:** none (git operation only)

- [x] **Step 1: Verify branch and commits**

```bash
git log --oneline main..HEAD
git status --short
```

Expected:
- Roughly 13–14 commits on the branch (one per task in Phases 1–4).
- Working tree clean.

- [x] **Step 2: Push the branch**

```bash
git push -u origin "$(git rev-parse --abbrev-ref HEAD)"
```

(Never `git push --force` to `main` — and never push to `main` directly per the user's "tudo vai pra main via PR" rule.)

- [x] **Step 3: Open the PR with the spec + implementation in the same diff**

```bash
gh pr create \
  --base main \
  --title "feat: memex plugin namespace — /memex:spec, /memex:learn, /memex:sweep, /memex:review-spec" \
  --body "$(cat <<'EOF'
## Summary

- Make `ribeirogab/agent-skills` a Claude Code marketplace (`.claude-plugin/marketplace.json` + `plugins/memex/`).
- Memex skill stops shipping `.agents/commands/` + `.claude/commands/` symlinks; writes `.claude/settings.json` so Claude Code installs the plugin at workspace-trust time.
- Constitution scope guardrails amended to permit `.claude-plugin/marketplace.json` and `plugins/<name>/`.
- Dogfood applied to this repo with the local-path marketplace source per AD7.

## Spec

- [spec-memex-claude-plugin-namespace.md](.vault/specs/2026-05-15-memex-claude-plugin-namespace/spec-memex-claude-plugin-namespace.md)
- [plan-memex-claude-plugin-namespace.md](.vault/specs/2026-05-15-memex-claude-plugin-namespace/plan-memex-claude-plugin-namespace.md)
- [tasks-memex-claude-plugin-namespace.md](.vault/specs/2026-05-15-memex-claude-plugin-namespace/tasks-memex-claude-plugin-namespace.md)

## Test plan

- [x] Audit on this repo: 15/15 PASS (Task 14)
- [x] Scratch fresh install with `.claude/` (Task 15)
- [x] Scratch migration from pre-plugin install (Task 16)
- [x] Scratch idempotent re-run (Task 17)
- [x] Scratch install without `.claude/` (Task 18)
EOF
)"
```

- [x] **Step 4: Mark the spec `shipped` after merge**

After the PR merges to `main`, in a follow-up edit (same merge commit or a tiny chore commit), set the spec's frontmatter:

```yaml
status: shipped
shipped: 2026-05-15   # actual merge date
```

Per the maintainer's "Ship spec in same PR" rule, the spec status change rides with the implementation PR. If the actual merge date differs from `2026-05-15`, edit the `shipped:` value before merging.

---

## Done

When every task above shows `[x]`:

- All 23 ACs in the spec are observably satisfied.
- This repo's `/memex` audit reports 15/15 PASS.
- Four scratch scenarios verified.
- PR opened with spec + implementation in the same diff.
- Spec frontmatter is `status: shipped`.
- Reflection step per AGENTS.md "After completing a spec" — capture any non-obvious learnings under `.vault/learnings/` and back-link them from the spec's `related:` frontmatter.
