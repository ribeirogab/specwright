---
feature: rename-harness-to-memex
plan: "[[plan-rename-harness-to-memex]]"
spec: "[[spec-rename-harness-to-memex]]"
created: 2026-05-03
---
# Rename Harness Skill to Memex — Tasks

**For this plan:** `[[plan-rename-harness-to-memex]]`

> **Execution mode:** Inline. The implementer reads each task in order, executes the steps, and commits at the end of each phase. Do not invoke any `/harness-*` or `/memex-*` slash command during Phases 1-4 — slash command files are mid-flight. Use raw `git`, `Edit`, and shell for everything until Phase 8.
>
> **Parent process safety:** Two files contain the word "harness" in comments referring to the Unix process tree (`PPID` parent), not the skill: `.agents/skills/memex-brainstorming/scripts/start-server.sh` lines 101-103, and the same file under `skills/memex/scaffold/skills/memex-brainstorming/scripts/start-server.sh`. **Do not edit those three lines.** They are excluded from every grep/edit pass below.

---

## Phase 1 — Branch and baseline

### Task 1: Create branch and snapshot baseline

**Files:** none changed yet — preparation only.

- [ ] **Step 1.1**: From repo root, create the feature branch.

  ```bash
  cd /Users/gabriel/www/ribeirogab/agent-skills
  git switch -c feat/rename-harness-to-memex
  ```

  Expected: `Switched to a new branch 'feat/rename-harness-to-memex'`.

- [ ] **Step 1.2**: Capture baseline counts so the validation phase has a "before" to compare against.

  ```bash
  echo "=== Files/dirs named 'harness*' ==="
  find . -name "*harness*" -not -path "./.git/*" -not -path "./node_modules/*" | sort
  echo ""
  echo "=== Total harness mentions in tracked files ==="
  git grep -c harness | awk -F: '{s+=$2} END {print s}'
  ```

  Expected output: ~24 paths, ~150-200 mentions total. Save the output mentally — Phase 7 validates against it.

- [ ] **Step 1.3**: Commit nothing yet. The spec/plan/tasks files for this feature are already on disk; stage them now so they ride on the same branch as the rename.

  ```bash
  git add context/specs/2026-05-03-rename-harness-to-memex/ \
          context/learnings/memex.md \
          context/_index/learnings.md
  git commit -m "spec: rename-harness-to-memex (planning artifacts + memex learning)"
  ```

  Expected: 4 files committed (3 spec docs + 1 learning + the MOC update).

---

## Phase 2 — Top-level skill

### Task 2: Move `skills/harness/` → `skills/memex/`

**Files:**
- Move: `skills/harness/` → `skills/memex/`

- [ ] **Step 2.1**: Move the whole directory with `git mv` so history follows.

  ```bash
  git mv skills/harness skills/memex
  ```

  Expected: no output. `git status` shows ~30+ renames under `skills/memex/`.

- [ ] **Step 2.2**: Verify the symlink at `.claude/skills/harness` is now broken (it pointed at `../../skills/harness`).

  ```bash
  ls -la .claude/skills/harness
  ```

  Expected: still listed, but `[ -e .claude/skills/harness ] && echo OK || echo BROKEN` prints `BROKEN`. **Leave it broken** — it gets recreated in Task 7.

### Task 3: Edit `skills/memex/SKILL.md`

**Files:**
- Modify: `skills/memex/SKILL.md`

- [ ] **Step 3.1**: Update frontmatter `name:` field.

  ```
  Line 2: name: harness  →  name: memex
  ```

  Use `Edit`:
  - old: `name: harness`
  - new: `name: memex`

- [ ] **Step 3.2**: Update frontmatter `description:` (line 3) — replace "agent harness" with "memex" once. Keep the rest of the description intact.

  - old: `description: "Scaffold or audit the agent harness (context/ vault + AGENTS.md + spec templates + bundled skills) in any repo. Agent-agnostic — works with any tool that supports the open agent skills standard (Claude Code, Codex, Cursor, OpenCode, etc.). Idempotent — safe to run repeatedly. Use when the user wants to set up, verify, or fix agent infrastructure in a project."`
  - new: `description: "Scaffold or audit the memex (context/ vault + AGENTS.md + spec templates + bundled skills) in any repo — an externalized, navigable project memory for agents (Claude Code, Codex, Cursor, OpenCode, etc.). Agent-agnostic. Idempotent — safe to run repeatedly. Use when the user wants to set up, verify, or fix the memex in a project."`

- [ ] **Step 3.3**: Update body line 6 heading.

  - old: `# Harness — Idempotent Agent Infrastructure`
  - new: `# Memex — Idempotent Agent Memory Infrastructure`

- [ ] **Step 3.4**: Update body line 8.

  - old: `Set up or audit the agent harness in the current repo.`
  - new: `Set up or audit the memex in the current repo.`

- [ ] **Step 3.5**: Update body line 10.

  - old: `**Announce at start:** "Auditing agent harness..."`
  - new: `**Announce at start:** "Auditing memex..."`

- [ ] **Step 3.6**: Update body line 86 ("The harness still **creates**...") — substitute "memex" once.

  - old: `The harness still **creates** the three config JSONs locally`
  - new: `The memex installer still **creates** the three config JSONs locally`

- [ ] **Step 3.7**: Update body line 92 ("...the harness adds a per-skill symlink...").

  - old: `the harness adds a per-skill symlink so that agent picks up the skill without duplicating files on disk:`
  - new: `the memex installer adds a per-skill symlink so that agent picks up the skill without duplicating files on disk:`

- [ ] **Step 3.8**: Update the `SKILL_NAMES` array (line 96).

  - old: `SKILL_NAMES=(harness-recall harness-brainstorming harness-writing-plans)`
  - new: `SKILL_NAMES=(memex-recall memex-brainstorming memex-writing-plans)`

- [ ] **Step 3.9**: Update the chmod paths (lines 106-107).

  - old (replace_all):
    ```
    [ -d .agents/skills/harness-brainstorming/scripts ] && \
      chmod +x .agents/skills/harness-brainstorming/scripts/*.sh
    ```
  - new:
    ```
    [ -d .agents/skills/memex-brainstorming/scripts ] && \
      chmod +x .agents/skills/memex-brainstorming/scripts/*.sh
    ```

- [ ] **Step 3.10**: Update the slash-command loop (line 128).

  - old: `for cmd in harness-open-pr harness-learn harness-spec harness-review-spec harness-sweep; do`
  - new: `for cmd in memex-open-pr memex-learn memex-spec memex-review-spec memex-sweep; do`

- [ ] **Step 3.11**: Verify zero `harness` mentions remain in the file.

  ```bash
  grep -n "harness" skills/memex/SKILL.md
  ```

  Expected: no output. If anything remains, edit it (a forgotten reference, or a literature mention that should stay — judge each).

### Task 4: Edit `skills/memex/references/*.md`

**Files:**
- Modify: `skills/memex/references/audit-checklist.md`
- Modify: `skills/memex/references/agents-md-template.md`
- Modify: `skills/memex/references/validation.md`
- Modify: `skills/memex/references/vault-files.md`
- Modify: `skills/memex/references/constitution-template.md`

These files are templates: the agent-md-template will be written into other repos as their `AGENTS.md`, the constitution-template becomes their `constitution.md`, etc. Every `harness*` in here is a skill identifier and must flip to `memex*`.

- [ ] **Step 4.1**: Replace every `harness-recall`/`harness-brainstorming`/`harness-writing-plans` with the `memex-` equivalent across all 5 files.

  ```bash
  cd /Users/gabriel/www/ribeirogab/agent-skills
  for f in skills/memex/references/*.md; do
    sed -i.bak \
      -e 's/harness-recall/memex-recall/g' \
      -e 's/harness-brainstorming/memex-brainstorming/g' \
      -e 's/harness-writing-plans/memex-writing-plans/g' \
      "$f" && rm "$f.bak"
  done
  ```

- [ ] **Step 4.2**: Replace every `harness-open-pr`/`harness-learn`/`harness-spec`/`harness-review-spec`/`harness-sweep` with the `memex-` equivalent across all 5 files.

  ```bash
  for f in skills/memex/references/*.md; do
    sed -i.bak \
      -e 's/harness-open-pr/memex-open-pr/g' \
      -e 's/harness-learn/memex-learn/g' \
      -e 's/harness-review-spec/memex-review-spec/g' \
      -e 's/harness-spec/memex-spec/g' \
      -e 's/harness-sweep/memex-sweep/g' \
      "$f" && rm "$f.bak"
  done
  ```

  Order matters: `harness-review-spec` must replace before `harness-spec`, otherwise the longer match is consumed. The `sed` order above handles this (longer patterns first).

- [ ] **Step 4.3**: Inspect the remaining bare `harness` mentions one by one.

  ```bash
  grep -n "harness" skills/memex/references/*.md
  ```

  Expected results to handle (per file):
  - `validation.md` line 3: "...the harness is structurally sound." → flip to "the memex".
  - `validation.md` line 169: "...the behaviour harness has something concrete to verify." — this is the *literature term* (harness = test harness). **KEEP as "harness"**.
  - `audit-checklist.md` line 3: "...harness audit checks." → flip to "memex audit".
  - `audit-checklist.md` line 65: "...the harness re-creates them..." → flip to "the memex installer re-creates them".
  - `audit-checklist.md` line 71: "...the harness keeps a `CLAUDE.md → AGENTS.md` symlink..." → flip to "the memex installer keeps".
  - `audit-checklist.md` line 112: "The harness still scaffolds the three config JSONs..." → flip to "The memex installer still scaffolds".

  Use `Edit` per occurrence — do not bulk-replace bare `harness` (the literature meaning at line 169 of `validation.md` would be lost).

- [ ] **Step 4.4**: Sanity check.

  ```bash
  grep -n "harness" skills/memex/references/*.md
  ```

  Expected: exactly one line — `validation.md:169:...the behaviour harness...`. If any other line remains, fix it.

### Phase 2 commit

- [ ] **Step P2.commit**: Commit the top-level skill rename.

  ```bash
  git add skills/memex/
  git status   # confirm only skills/memex/ paths are staged + the renames
  git commit -m "refactor(skills): rename harness skill to memex (top-level + references)"
  ```

---

## Phase 3 — Bundled skills

### Task 5: Rename canonical `.agents/skills/harness-*` → `memex-*`

**Files:**
- Move: `.agents/skills/harness-recall/` → `.agents/skills/memex-recall/`
- Move: `.agents/skills/harness-brainstorming/` → `.agents/skills/memex-brainstorming/`
- Move: `.agents/skills/harness-writing-plans/` → `.agents/skills/memex-writing-plans/`

- [ ] **Step 5.1**: Move all three.

  ```bash
  for name in recall brainstorming writing-plans; do
    git mv ".agents/skills/harness-$name" ".agents/skills/memex-$name"
  done
  ```

- [ ] **Step 5.2**: Update `name:` frontmatter in each moved SKILL.md.

  For each of `.agents/skills/memex-recall/SKILL.md`, `.agents/skills/memex-brainstorming/SKILL.md`, `.agents/skills/memex-writing-plans/SKILL.md`, use `Edit`:
  - old: `name: harness-recall` (etc.)
  - new: `name: memex-recall` (etc.)

  Match each file's actual basename.

- [ ] **Step 5.3**: Sweep prose mentions inside each canonical SKILL.md and any other .md files in those directories.

  ```bash
  grep -rn "harness" .agents/skills/memex-*/
  ```

  Expected output excludes `start-server.sh` lines 101-103 (process tree comments — leave alone). For everything else, edit per-occurrence: a mention referring to the *skill itself* or *another bundled skill* flips to `memex`; a mention referring to the literature `harness engineering` pattern stays.

- [ ] **Step 5.4**: Verify scripts still work syntactically (no execution test, just shell parse).

  ```bash
  bash -n .agents/skills/memex-brainstorming/scripts/start-server.sh
  bash -n .agents/skills/memex-brainstorming/scripts/stop-server.sh
  ```

  Expected: both exit 0 with no output.

### Task 6: Rename scaffold templates `skills/memex/scaffold/skills/harness-*` → `memex-*`

**Files:**
- Move: `skills/memex/scaffold/skills/harness-{recall,brainstorming,writing-plans}/` → `memex-...`

- [ ] **Step 6.1**: Move all three.

  ```bash
  for name in recall brainstorming writing-plans; do
    git mv "skills/memex/scaffold/skills/harness-$name" "skills/memex/scaffold/skills/memex-$name"
  done
  ```

- [ ] **Step 6.2**: Update `name:` frontmatter in each scaffold-template SKILL.md (same as Step 5.2 but under `skills/memex/scaffold/skills/`).

- [ ] **Step 6.3**: Sweep prose mentions.

  ```bash
  grep -rn "harness" skills/memex/scaffold/skills/memex-*/
  ```

  Same rule as Step 5.3: skill/sibling mentions flip; process-tree comments and literature mentions stay.

- [ ] **Step 6.4**: Verify the canonical and scaffold copies are still in sync (they should be identical in content).

  ```bash
  for name in recall brainstorming writing-plans; do
    diff -r ".agents/skills/memex-$name" "skills/memex/scaffold/skills/memex-$name" \
      || echo "DRIFT: memex-$name diverged"
  done
  ```

  Expected: no `DRIFT` lines, and `diff` output empty (or only lists `.git`-style transient files if any). If divergence exists, decide which copy is canonical (per the architecture: `.agents/skills/<name>/` is the install, `skills/memex/scaffold/skills/<name>/` is the template — they should be identical post-install) and harmonize by copying the correct version over the other. Do not commit divergent copies.

### Task 7: Recreate `.claude/skills/` symlinks

**Files:**
- Remove + recreate: 4 symlinks under `.claude/skills/`.

- [ ] **Step 7.1**: Remove the broken/stale symlinks.

  ```bash
  git rm .claude/skills/harness .claude/skills/harness-recall .claude/skills/harness-brainstorming .claude/skills/harness-writing-plans
  ```

  Expected: 4 files removed.

- [ ] **Step 7.2**: Recreate as `memex` / `memex-*`, pointing at the new canonical paths.

  ```bash
  ln -s ../../skills/memex .claude/skills/memex
  ln -s ../../.agents/skills/memex-recall .claude/skills/memex-recall
  ln -s ../../.agents/skills/memex-brainstorming .claude/skills/memex-brainstorming
  ln -s ../../.agents/skills/memex-writing-plans .claude/skills/memex-writing-plans
  git add .claude/skills/memex .claude/skills/memex-recall .claude/skills/memex-brainstorming .claude/skills/memex-writing-plans
  ```

- [ ] **Step 7.3**: Verify all four resolve.

  ```bash
  for f in .claude/skills/memex .claude/skills/memex-recall .claude/skills/memex-brainstorming .claude/skills/memex-writing-plans; do
    [ -e "$f" ] && echo "OK $f" || echo "BROKEN $f"
  done
  ```

  Expected: 4 lines, all `OK`.

### Phase 3 commit

- [ ] **Step P3.commit**:

  ```bash
  git add .agents/skills skills/memex/scaffold/skills .claude/skills
  git status  # confirm scope
  git commit -m "refactor(skills): rename bundled harness-* skills to memex-* and refresh symlinks"
  ```

---

## Phase 4 — Slash commands

### Task 8: Rename `.claude/commands/harness-*.md` → `memex-*.md`

**Files:**
- Move + edit: `.claude/commands/harness-{open-pr,learn,spec,review-spec,sweep}.md`

- [ ] **Step 8.1**: Move all five.

  ```bash
  for cmd in open-pr learn spec review-spec sweep; do
    git mv ".claude/commands/harness-$cmd.md" ".claude/commands/memex-$cmd.md"
  done
  ```

- [ ] **Step 8.2**: Update `name:` frontmatter (if present) and any prose self-references in each renamed file.

  ```bash
  for f in .claude/commands/memex-*.md; do
    sed -i.bak \
      -e 's/harness-open-pr/memex-open-pr/g' \
      -e 's/harness-learn/memex-learn/g' \
      -e 's/harness-review-spec/memex-review-spec/g' \
      -e 's/harness-spec/memex-spec/g' \
      -e 's/harness-sweep/memex-sweep/g' \
      -e 's/harness-recall/memex-recall/g' \
      -e 's/harness-brainstorming/memex-brainstorming/g' \
      -e 's/harness-writing-plans/memex-writing-plans/g' \
      "$f" && rm "$f.bak"
  done
  ```

- [ ] **Step 8.3**: Inspect remaining bare `harness` mentions and decide per-occurrence.

  ```bash
  grep -n "harness" .claude/commands/memex-*.md
  ```

  Likely candidates:
  - "the harness skill" / "the harness installer" → flip to "the memex skill" / "the memex installer".
  - References to "harness engineering" or the literature → leave.

  Edit each match individually.

### Task 9: Rename scaffold templates `skills/memex/scaffold/commands/harness-*.md` → `memex-*.md`

**Files:**
- Move + edit: `skills/memex/scaffold/commands/harness-{open-pr,learn,spec,review-spec,sweep}.md`

- [ ] **Step 9.1**: Move all five.

  ```bash
  for cmd in open-pr learn spec review-spec sweep; do
    git mv "skills/memex/scaffold/commands/harness-$cmd.md" "skills/memex/scaffold/commands/memex-$cmd.md"
  done
  ```

- [ ] **Step 9.2**: Apply the same `sed` substitution as Step 8.2 to the scaffold copies.

  ```bash
  for f in skills/memex/scaffold/commands/memex-*.md; do
    sed -i.bak \
      -e 's/harness-open-pr/memex-open-pr/g' \
      -e 's/harness-learn/memex-learn/g' \
      -e 's/harness-review-spec/memex-review-spec/g' \
      -e 's/harness-spec/memex-spec/g' \
      -e 's/harness-sweep/memex-sweep/g' \
      -e 's/harness-recall/memex-recall/g' \
      -e 's/harness-brainstorming/memex-brainstorming/g' \
      -e 's/harness-writing-plans/memex-writing-plans/g' \
      "$f" && rm "$f.bak"
  done
  ```

- [ ] **Step 9.3**: Inspect remaining bare `harness` mentions and decide per-occurrence.

- [ ] **Step 9.4**: Verify `.claude/commands/` and `skills/memex/scaffold/commands/` remain in sync.

  ```bash
  diff -r .claude/commands/ skills/memex/scaffold/commands/ \
    | grep -v "Only in" \
    || echo "differs"
  ```

  Note: `Only in` lines are expected if `.claude/commands/` contains items not in scaffold (e.g. a personal command). Verify the matched files are identical.

### Phase 4 commit

- [ ] **Step P4.commit**:

  ```bash
  git add .claude/commands skills/memex/scaffold/commands
  git status
  git commit -m "refactor(commands): rename harness-* slash commands to memex-*"
  ```

---

## Phase 5 — Repo-level docs and active vault

### Task 10: Update `AGENTS.md`

**Files:**
- Modify: `AGENTS.md`

- [ ] **Step 10.1**: Apply the prefix substitutions globally (these are unambiguous — every prefixed name was a skill or command).

  ```bash
  sed -i.bak \
    -e 's|skills/harness/|skills/memex/|g' \
    -e 's|harness-open-pr|memex-open-pr|g' \
    -e 's|harness-learn|memex-learn|g' \
    -e 's|harness-review-spec|memex-review-spec|g' \
    -e 's|harness-spec|memex-spec|g' \
    -e 's|harness-sweep|memex-sweep|g' \
    -e 's|harness-recall|memex-recall|g' \
    -e 's|harness-brainstorming|memex-brainstorming|g' \
    -e 's|harness-writing-plans|memex-writing-plans|g' \
    AGENTS.md && rm AGENTS.md.bak
  ```

- [ ] **Step 10.2**: Inspect remaining bare `harness` mentions and edit per-occurrence.

  ```bash
  grep -n "harness" AGENTS.md
  ```

  Expected mentions to update (line numbers may shift after Step 10.1):
  - "The flagship is `skills/harness/`" — already replaced in 10.1.
  - "/harness" (the slash command for the top-level skill) → flip to `/memex`.
  - "The repo dogfoods its own harness:" → flip to "The repo dogfoods its own memex:".
  - "the most used commands are git workflow and the harness slash commands" → flip to "and the memex slash commands".
  - "/harness — invoke this skill" → flip to "/memex".
  - "audit/scaffold the agent harness" → flip to "audit/scaffold the memex".

  Each via `Edit`. Verify no leftover `harness` after the pass:

  ```bash
  grep -n "harness" AGENTS.md
  ```

  Expected: empty.

### Task 11: Verify `CLAUDE.md` symlink

**Files:**
- Inspect: `CLAUDE.md`

- [ ] **Step 11.1**: Confirm CLAUDE.md is still a symlink to AGENTS.md.

  ```bash
  test -L CLAUDE.md && readlink CLAUDE.md
  ```

  Expected: prints `AGENTS.md`. If the symlink was somehow broken or replaced with a regular file, restore it: `rm CLAUDE.md && ln -s AGENTS.md CLAUDE.md && git add CLAUDE.md`.

### Task 12: Update `README.md`

**Files:**
- Modify: `README.md`

- [ ] **Step 12.1**: Apply prefix substitutions.

  ```bash
  sed -i.bak \
    -e 's|skills/harness/|skills/memex/|g' \
    -e 's|harness-\*|memex-*|g' \
    -e 's|harness-open-pr|memex-open-pr|g' \
    -e 's|harness-learn|memex-learn|g' \
    -e 's|harness-review-spec|memex-review-spec|g' \
    -e 's|harness-spec|memex-spec|g' \
    -e 's|harness-sweep|memex-sweep|g' \
    -e 's|harness-recall|memex-recall|g' \
    -e 's|harness-brainstorming|memex-brainstorming|g' \
    -e 's|harness-writing-plans|memex-writing-plans|g' \
    README.md && rm README.md.bak
  ```

- [ ] **Step 12.2**: Edit per-occurrence what remains.

  ```bash
  grep -n "harness" README.md
  ```

  Expected mentions:
  - Line 11 heading `### \`harness\`` → flip to `### \`memex\``.
  - Line 13 prose: "Idempotently scaffolds an agent harness" → "Idempotently scaffolds a memex".
  - Line 18: `npx skills add ribeirogab/agent-skills --skill harness` → `--skill memex`.
  - Line 21: "where you want the harness installed" → "where you want the memex installed".
  - Line 23: quoted prompt "Audit the harness in this repo" → "Audit the memex in this repo".
  - Line 25: "dogfood-tested by the harness's own 13-check validator" → "dogfood-tested by the memex's own 13-check validator".
  - Line 27: link `[skills/harness/SKILL.md](skills/harness/SKILL.md)` — already flipped in 12.1.
  - Line 58: tree `│   ├── harness/` → `│   ├── memex/`.
  - Line 68: "used by the maintainer to dogfood the harness" → "to dogfood the memex".

  Verify clean:

  ```bash
  grep -n "harness" README.md
  ```

  Expected: empty.

### Task 13: Update `context/constitution.md`

**Files:**
- Modify: `context/constitution.md`

- [ ] **Step 13.1**: Apply prefix substitutions.

  ```bash
  sed -i.bak \
    -e 's|harness-open-pr|memex-open-pr|g' \
    -e 's|harness-learn|memex-learn|g' \
    -e 's|harness-review-spec|memex-review-spec|g' \
    -e 's|harness-spec|memex-spec|g' \
    -e 's|harness-sweep|memex-sweep|g' \
    -e 's|harness-recall|memex-recall|g' \
    -e 's|harness-brainstorming|memex-brainstorming|g' \
    -e 's|harness-writing-plans|memex-writing-plans|g' \
    context/constitution.md && rm context/constitution.md.bak
  ```

- [ ] **Step 13.2**: Edit per-occurrence.

  Mentions to flip (judgment per the spec's "skill vs literature" rule):
  - Line 13: "scaffolding agent harnesses" — refers to *this skill*, flip to "scaffolding memexes".
  - Line 15: "The flagship skill in this repo is `harness/`" → "is `memex/`".
  - Line 27: "the `harness` skill (and any future scaffolding skill)" → "the `memex` skill".
  - Line 35: "`harness` has Phase 5 validation" → "`memex` has Phase 5 validation".
  - Line 48: "how the harness symlink works" → "how the memex symlink works".

  Verify clean:

  ```bash
  grep -n "harness" context/constitution.md
  ```

  Expected: empty.

### Task 14: Sweep `context/_index/`, `context/templates/`, `context/conventions/`, `context/rules/`

**Files:**
- Modify: any file in those four trees that mentions `harness`.

- [ ] **Step 14.1**: Survey first.

  ```bash
  grep -rn "harness" context/_index/ context/templates/ context/conventions/ context/rules/ 2>/dev/null
  ```

  Already-known: `context/_index/learnings.md` contains the index entry pointing at `harness-engineering-foundations.md` — that one **stays** (literature).

- [ ] **Step 14.2**: For each survivor, decide per-occurrence (skill identifier → flip; literature → keep). Use `Edit`.

- [ ] **Step 14.3**: Verify only justified survivors remain.

  ```bash
  grep -rn "harness" context/_index/ context/templates/ context/conventions/ context/rules/ 2>/dev/null
  ```

  Expected: only the literature pointer in `context/_index/learnings.md`.

### Phase 5 commit

- [ ] **Step P5.commit**:

  ```bash
  git add AGENTS.md README.md context/constitution.md context/_index context/templates context/conventions context/rules CLAUDE.md
  git status
  git commit -m "docs: update AGENTS.md, README, constitution, MOCs for harness→memex"
  ```

---

## Phase 6 — Per-occurrence learnings review

### Task 15: Review `context/learnings/generator-evaluator-separation.md`

**Files:**
- Modify: `context/learnings/generator-evaluator-separation.md`

- [ ] **Step 15.1**: List the 9 mentions with two lines of context each.

  ```bash
  grep -n -B1 -A1 "harness" context/learnings/generator-evaluator-separation.md
  ```

- [ ] **Step 15.2**: For each mention, classify:
  - **Skill referent** (the rename target, e.g. "the harness skill", "harness-spec", a code path) → flip to memex.
  - **Literature referent** (Fowler / Anthropic / OpenAI / "harness engineering" / "test harness") → keep.

- [ ] **Step 15.3**: Edit each skill-referent mention via `Edit`. Do not bulk-replace.

- [ ] **Step 15.4**: Run validation grep. Survivors must all be literature.

  ```bash
  grep -n "harness" context/learnings/generator-evaluator-separation.md
  ```

### Task 16: Review `context/learnings/agents-md-as-map-not-encyclopedia.md`

**Files:**
- Modify: `context/learnings/agents-md-as-map-not-encyclopedia.md`

- [ ] **Step 16.1**: List all 5 mentions with surrounding context.

  ```bash
  grep -n -B1 -A1 "harness" context/learnings/agents-md-as-map-not-encyclopedia.md
  ```

- [ ] **Step 16.2**: For each mention, classify:
  - **Skill referent** (the rename target — "the harness skill", `harness-spec`, code paths, file paths under `skills/harness/`) → flip to `memex`.
  - **Literature referent** ("harness engineering", references to Fowler / Anthropic / OpenAI essays, "test harness", the runtime pattern itself) → keep.

- [ ] **Step 16.3**: Edit each skill-referent mention via `Edit`. Do not bulk-replace.

- [ ] **Step 16.4**: Verify survivors are all literature.

  ```bash
  grep -n "harness" context/learnings/agents-md-as-map-not-encyclopedia.md
  ```

  Each remaining line must be defensible as a literature reference. Note in the commit message which lines you preserved and why (one phrase each).

### Task 17: Review `context/learnings/mechanical-enforcement-over-prose.md`

**Files:**
- Modify: `context/learnings/mechanical-enforcement-over-prose.md`

- [ ] **Step 17.1**: List all 3 mentions with surrounding context.

  ```bash
  grep -n -B1 -A1 "harness" context/learnings/mechanical-enforcement-over-prose.md
  ```

- [ ] **Step 17.2**: For each mention, classify:
  - **Skill referent** → flip to `memex`.
  - **Literature referent** → keep.

  Heuristic for this note specifically: it's about *mechanical enforcement* — most likely the surviving mentions are about the enforcement *pattern* (literature), not the install command (skill). Default to keeping unless the line literally names a file path or `/harness-spec`-style command.

- [ ] **Step 17.3**: Edit each skill-referent mention via `Edit`.

- [ ] **Step 17.4**: Verify survivors and note them in the commit message.

  ```bash
  grep -n "harness" context/learnings/mechanical-enforcement-over-prose.md
  ```

### Task 18: Append clarifying paragraph to `context/learnings/harness-engineering-foundations.md`

**Files:**
- Modify: `context/learnings/harness-engineering-foundations.md`

- [ ] **Step 18.1**: Read the file.

- [ ] **Step 18.2**: Append the following paragraph at the end of the body (before any closing wikilinks if present, or as the last paragraph).

  ```markdown
  ## Note on naming (2026-05-03)

  The skill formerly named `harness` in this repo was renamed to `memex` to free the word "harness" for its literature meaning (the runtime pattern documented in this very note — Fowler, Anthropic, OpenAI). The pattern is still called *harness engineering*; the **skill that scaffolds an agent's project memory** is now called `memex` (after Vannevar Bush's 1945 personal memory extender — see [[memex|memex]]). When you read "harness" in this note or in the literature it cites, it always means the technical pattern, never the skill.
  ```

- [ ] **Step 18.3**: Add a `related` link to `[[memex]]` in the frontmatter `related:` list.

  ```yaml
  related:
    - "[[agents-md-as-map-not-encyclopedia]]"
    - "[[mechanical-enforcement-over-prose]]"
    - "[[generator-evaluator-separation]]"
    - "[[memex]]"
  ```

### Phase 6 commit

- [ ] **Step P6.commit**:

  ```bash
  git add context/learnings
  git commit -m "docs(learnings): per-occurrence harness→memex review + harness-engineering note clarification"
  ```

---

## Phase 7 — Validation

### Task 19: Acceptance-criteria checks

**Files:** none modified — read-only verification.

- [ ] **Step 19.1**: AC1 — `find . -name "*harness*"` returns only the allowed paths.

  ```bash
  find . -name "*harness*" -not -path "./.git/*" -not -path "./node_modules/*" | sort
  ```

  Expected output (exactly):
  ```
  ./context/learnings/harness-engineering-foundations.md
  ./context/specs/2026-04-30-opensource-readiness/plan-opensource-readiness.md
  ./context/specs/2026-04-30-opensource-readiness/spec-opensource-readiness.md
  ./context/specs/2026-04-30-opensource-readiness/tasks-opensource-readiness.md
  ```

  Anything else → fix.

- [ ] **Step 19.2**: AC2 — no `harness` in active root docs.

  ```bash
  grep -rIn "harness" AGENTS.md README.md context/constitution.md context/templates/ context/conventions/ context/rules/ 2>/dev/null
  ```

  Expected: empty.

- [ ] **Step 19.3**: AC3 — `_index/learnings.md` survivors are justified (literature pointer).

  ```bash
  grep -n "harness" context/_index/learnings.md
  ```

  Expected: only the index entry pointing at `harness-engineering-foundations`.

- [ ] **Step 19.4**: AC4 — every `.claude/skills/` symlink resolves.

  ```bash
  for f in .claude/skills/*; do
    [ -e "$f" ] || echo "BROKEN $f"
  done
  ```

  Expected: empty (no `BROKEN` lines).

- [ ] **Step 19.5**: AC5 — frontmatter names match dirs/files.

  ```bash
  grep -h '^name:' skills/memex/SKILL.md .agents/skills/memex-*/SKILL.md
  ```

  Expected: 4 lines — `name: memex`, `name: memex-recall`, `name: memex-brainstorming`, `name: memex-writing-plans`.

- [ ] **Step 19.6**: AC6 — slash command files match new prefix.

  ```bash
  ls .claude/commands/ | grep -E '^(harness|memex)-'
  ```

  Expected: only `memex-*.md`. No `harness-*` survivors.

### Task 20: Run the 15-step Phase 5 validation

**Files:** none modified — read-only.

- [ ] **Step 20.1**: Read `skills/memex/references/validation.md`.

- [ ] **Step 20.2**: Execute every check listed there (15 of them) and tabulate results in a scratch buffer.

- [ ] **Step 20.3**: For any check that fails, fix the underlying issue (re-edit the offending file, recreate a symlink, etc.) and re-run that single check until it passes.

- [ ] **Step 20.4**: Final pass — run all 15 again, confirm 15/15 PASS. Save the result table for the PR description.

### Task 21: Commit any validation fixes

- [ ] **Step 21.commit**: If any fixes were committed during validation, use a separate commit.

  ```bash
  git add -A
  git status   # only files modified by validation fixes should be present
  git diff --cached --stat
  git commit -m "fix: validation-driven cleanup for harness→memex rename"
  ```

  If no validation fixes were needed, skip this step.

---

## Phase 8 — Ship

### Task 22: Mark spec status `shipped`

**Files:**
- Modify: `context/specs/2026-05-03-rename-harness-to-memex/spec-rename-harness-to-memex.md`

- [ ] **Step 22.1**: Update the frontmatter:

  - old: `status: draft` and `shipped: null`
  - new: `status: shipped` and `shipped: 2026-05-03` (or the actual ship date — use `date +%Y-%m-%d`).

- [ ] **Step 22.2**: Tick all the `Acceptance Criteria` checkboxes from `[ ]` to `[x]` based on the validated state.

### Task 23: Index the spec

**Files:**
- Modify: `context/_index/specs.md`

- [ ] **Step 23.1**: Add an entry under the appropriate heading (likely "Shipped" or whatever the convention in `_index/specs.md` is).

  ```markdown
  - [[../specs/2026-05-03-rename-harness-to-memex/spec-rename-harness-to-memex|2026-05-03 — Rename harness skill to memex]] — full rename of the skill identifier; preserves the literature term "harness engineering".
  ```

  Read the existing file first to match its format.

### Task 24: Reflection — capture any non-obvious learnings

**Files:**
- Maybe-create: `context/learnings/<some-slug>.md` per the project's after-completing-a-spec rule.

- [ ] **Step 24.1**: Ask: did anything non-obvious come up during the rename? Examples that would warrant a note:
  - A spot where the `sed` ordering caused a silent data-loss bug.
  - A symlink quirk the implementer didn't expect.
  - The realization that `start-server.sh` "harness" comments referred to the parent process, not the skill (this is already captured in the spec's Constraints — only worth a learning if a *new* twist showed up).
  - A tool failure during validation that's worth flagging.

- [ ] **Step 24.2**: If yes, create the note via `context/templates/learning.md` and add to `context/_index/learnings.md`.

- [ ] **Step 24.3**: If nothing non-obvious came up, write a single line in the PR description: "**Reflection:** No new learnings from this spec." (per CLAUDE.md's explicit rule — silence is not the same as reflection.)

### Task 25: Open the PR

**Files:** none modified — git operation.

- [ ] **Step 25.1**: Push the branch.

  ```bash
  git push -u origin feat/rename-harness-to-memex
  ```

- [ ] **Step 25.2**: Open the PR via the renamed slash command.

  Invoke `/memex-open-pr` from the agent. This is the command that was renamed in Phase 4 — it should be active now.

  If `/memex-open-pr` fails (e.g. the agent's slash-command registry hasn't been refreshed mid-session), fall back to:

  ```bash
  gh pr create --title "refactor: rename harness skill to memex" \
    --body "$(cat <<'EOF'
  ## Summary
  - Renames the `harness` skill (and its bundled skills + slash commands) to `memex`.
  - Frees the term "harness" for the published *harness engineering* literature.
  - Adds a learning note `context/learnings/memex.md` and a clarifying paragraph in `harness-engineering-foundations.md`.

  ## Test plan
  - [x] `find . -name "*harness*"` returns only literature/historical paths.
  - [x] `grep harness AGENTS.md README.md context/constitution.md` returns empty.
  - [x] All `.claude/skills/` symlinks resolve.
  - [x] 15/15 validation checks pass per `skills/memex/references/validation.md`.

  Spec: `context/specs/2026-05-03-rename-harness-to-memex/spec-rename-harness-to-memex.md`
  EOF
  )"
  ```

  (Per the project rules — Rule 19 — no Claude attribution in the PR body.)

---

## Done

After Task 25 the PR is open and the rename is complete. The agent declares the spec shipped and reports back to the user with the PR URL.
