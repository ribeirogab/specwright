---
feature: install-parity
created: 2026-07-02
---
# Install Parity — Tasks

**For this issue:** see the sibling `issue.md` (acceptance criteria) and `spec.md` (technical plan).

> Each task names the `AC:` (acceptance criteria from `issue.md` it satisfies — every `AC-N` must be referenced by at least one task) and `Delegable:` (whether it suits an isolated task worker, and the one-line context that worker would receive). Workers report findings back to the issue owner; only the owner writes `learnings.md`.

## Phase 1: Canonical skills

### Task 1: `sw-spec` canonical skill (both trees)

**AC:** AC-4
**Delegable:** yes — "Create `skills/sw/scaffold/skills/sw-spec/SKILL.md` and a byte-identical `.agents/skills/sw-spec/SKILL.md`: body verbatim from `plugins/sw/commands/spec.md`, frontmatter converted to skill shape (`name: sw-spec` + `description`)."
**Files:**
- Create: `skills/sw/scaffold/skills/sw-spec/SKILL.md`
- Create: `.agents/skills/sw-spec/SKILL.md`

- [x] Step 1: Write `skills/sw/scaffold/skills/sw-spec/SKILL.md` — frontmatter:

```yaml
---
name: sw-spec
description: "Turn the current conversation into an issue (or milestone) using the specwright brainstorm flow — summarizes the discussion, then enters the full brainstorm: design conversation, approval, scope, artifacts. Use when a chat has converged on something worth building."
---
```

Body: everything below the frontmatter of `plugins/sw/commands/spec.md` (line 5 onward), verbatim.
- [x] Step 2: Copy byte-identically: `cp skills/sw/scaffold/skills/sw-spec/SKILL.md .agents/skills/sw-spec/SKILL.md` (create the dir first).
- [x] Step 3: Verify: `diff skills/sw/scaffold/skills/sw-spec/SKILL.md .agents/skills/sw-spec/SKILL.md` → no output; `diff <(tail -n +5 plugins/sw/commands/spec.md) <(tail -n +5 skills/sw/scaffold/skills/sw-spec/SKILL.md)` → no output.
- [x] Step 4: Commit.

### Task 2: `sw-review-spec` canonical skill (both trees)

**AC:** AC-4
**Delegable:** yes — "Create `skills/sw/scaffold/skills/sw-review-spec/SKILL.md` and a byte-identical `.agents/skills/sw-review-spec/SKILL.md`: body verbatim from `plugins/sw/commands/review-spec.md`, frontmatter converted to skill shape (`name: sw-review-spec` + `description`)."
**Files:**
- Create: `skills/sw/scaffold/skills/sw-review-spec/SKILL.md`
- Create: `.agents/skills/sw-review-spec/SKILL.md`

- [x] Step 1: Write `skills/sw/scaffold/skills/sw-review-spec/SKILL.md` — frontmatter:

```yaml
---
name: sw-review-spec
description: "External evaluator that reviews an issue's plan (spec.md + tasks.md) against the project conventions and the approved issue — mechanical validator first, then conventions, testable ACs, required sections, scope discipline, open questions, learnings. Use inside the issue pipeline's self-review, after the plan is written."
---
```

Body: everything below the frontmatter of `plugins/sw/commands/review-spec.md` (line 5 onward), verbatim.
- [x] Step 2: Copy byte-identically: `cp skills/sw/scaffold/skills/sw-review-spec/SKILL.md .agents/skills/sw-review-spec/SKILL.md` (create the dir first).
- [x] Step 3: Verify: `diff skills/sw/scaffold/skills/sw-review-spec/SKILL.md .agents/skills/sw-review-spec/SKILL.md` → no output; `diff <(tail -n +5 plugins/sw/commands/review-spec.md) <(tail -n +5 skills/sw/scaffold/skills/sw-review-spec/SKILL.md)` → no output.
- [x] Step 4: Commit.

## Phase 2: Scaffolder procedure (`skills/sw/SKILL.md`)

### Task 3: Vault `.gitkeep` step

**AC:** AC-5
**Delegable:** no — single edit inside the file Tasks 4–5 also touch; one owner avoids merge noise.
**Files:**
- Modify: `skills/sw/SKILL.md` ("Vault directories" section, after the directory list)

- [x] Step 1: In the "### Vault directories" section, extend the "Ensure all three directories exist" paragraph with the clone-survival rationale and add the idempotent block:

```bash
mkdir -p .specwright/conventions .specwright/issues .specwright/milestones
touch .specwright/conventions/.gitkeep .specwright/issues/.gitkeep .specwright/milestones/.gitkeep
```

- [x] Step 2: Verify: `grep -n ".gitkeep" skills/sw/SKILL.md` shows the three paths.
- [x] Step 3: Commit.

### Task 4: `sw` self-copy + `.claude/skills/sw` symlink subsection

**AC:** AC-1, AC-3
**Delegable:** no — same file as Tasks 3/5.
**Files:**
- Modify: `skills/sw/SKILL.md` (new subsection between ".gitignore additions" and "Skills and commands (copy from scaffold/)")

- [x] Step 1: Insert a new subsection `### The sw skill itself (self-copy + Claude Code symlink)` with the parity rationale (validator must exist at `.agents/skills/sw/scripts/validate-spec.sh`; README-promised symlink; mirrors `install.sh`) and this block:

```bash
SW_DIR="<directory where this SKILL.md lives>"

# 1. Self-copy — the canonical sw install, including scaffold/ and scripts/.
#    No-op when already installed there (e.g. by install.sh, when SW_DIR
#    IS .agents/skills/sw).
mkdir -p .agents/skills
if [ ! -e .agents/skills/sw ]; then
  cp -r "$SW_DIR" .agents/skills/sw
fi
[ -d .agents/skills/sw/scripts ] && chmod +x .agents/skills/sw/scripts/*.sh

# 2. Claude Code discovery symlink — what makes /sw resolvable, exactly as
#    install.sh creates it. Not gated on a pre-existing .claude/.
mkdir -p .claude/skills
if [ -L .claude/skills/sw ]; then
  rm -f .claude/skills/sw
elif [ -e .claude/skills/sw ]; then
  echo "warning: .claude/skills/sw exists and is not a symlink — resolve manually" >&2
fi
[ -e .claude/skills/sw ] || ln -s ../../.agents/skills/sw .claude/skills/sw
```

- [x] Step 2: Verify the legacy-cleanup interplay by reading the existing cleanup loop: it iterates `SKILL_NAMES` only (no `sw` member) and `rmdir`s `.claude/skills` only when empty — no edit needed there.
- [x] Step 3: Commit.

### Task 5: `SKILL_NAMES` 6 → 8 + Rules bullets

**AC:** AC-4, AC-1, AC-3
**Delegable:** no — same file as Tasks 3/4.
**Files:**
- Modify: `skills/sw/SKILL.md` (copy-loop `SKILL_NAMES` array; "Rules:" list)

- [x] Step 1: Change the array to `SKILL_NAMES=(sw-brainstorm sw-plan sw-pr sw-review sw-review-spec sw-run sw-spec sw-update)` and update the prose that names the companion count/set.
- [x] Step 2: Add Rules bullets: the `sw` skill self-installs to `.agents/skills/sw` with `scripts/*.sh` executable; `.claude/skills/sw` is the one sanctioned `.claude/skills/` symlink (companions stay plugin-served on Claude).
- [x] Step 3: Verify: `grep -c "sw-spec" skills/sw/SKILL.md` ≥ 1 inside `SKILL_NAMES`; re-read the Claude-skip comment still scoped to companion skills.
- [x] Step 4: Commit.

## Phase 3: Audit surface

### Task 6: Audit checklist inventory

**AC:** AC-2
**Delegable:** yes — "Add `.agents/skills/sw/` (with the validator path), the `.claude/skills/sw` symlink check, and `sw-spec`/`sw-review-spec` skill dirs to the audited inventory in `skills/sw/references/audit-checklist.md`."
**Files:**
- Modify: `skills/sw/references/audit-checklist.md` ("Files and directories to check" block; symlink-check sections)

- [x] Step 1: In the inventory block, add `.agents/skills/sw/` (full directory — the scaffolder itself; `scripts/validate-spec.sh` must exist and be executable), `.agents/skills/sw-spec/`, `.agents/skills/sw-review-spec/`, and `.claude/skills/sw` (symlink → `../../.agents/skills/sw`).
- [x] Step 2: Reconcile the "Claude Code is excluded" note so the `sw` symlink is the documented exception to the companion-skill exclusion.
- [x] Step 3: Verify: `grep -n ".agents/skills/sw/" skills/sw/references/audit-checklist.md` hits the inventory.
- [x] Step 4: Commit.

## Phase 4: Gates

### Task 7: Quality gate

**AC:** AC-1, AC-2, AC-3, AC-4, AC-5 (regression safety for all)
**Delegable:** no — gatekeeping is the owner's.

- [x] Step 1: Run `bash tests/install/run.sh` → `ALL PASS` (install.sh untouched; proves no collateral).
- [x] Step 2: Run `skills/sw/scripts/validate-spec.sh skills/sw/scripts/fixtures/good` → exit 0, and one `bad-*` fixture → non-zero (validator untouched; proves no collateral).
- [x] Step 3: Parity check: `for s in sw-brainstorm sw-plan sw-pr sw-review sw-review-spec sw-run sw-spec sw-update; do diff -rq ".agents/skills/$s" "skills/sw/scaffold/skills/$s"; done` → no output.
- [x] Step 4: Run `skills/sw/scripts/validate-spec.sh .specwright/milestones/2026-07-02-specwright-fixes/issues/install-parity` → exit 0.
- [x] Step 5: Commit any fixes.

### Task 8: Runtime verification (fresh scaffold fixture)

**AC:** AC-1, AC-2, AC-3, AC-4, AC-5
**Delegable:** no — evidence goes in the PR body; owner runs it.

- [x] Step 1: In the session scratchpad, create a clean fixture repo (`git init fixture`), then execute the updated Phase 4 procedure exactly as written in `skills/sw/SKILL.md` with `SW_DIR=<worktree>/skills/sw`: vault + `.gitkeep` block, self-copy + symlink block, companion copy loop (no agent dirs present → no per-agent symlinks).
- [x] Step 2: AC-1 — `test -x fixture/.agents/skills/sw/scripts/validate-spec.sh` and run it from the fixture root against a copied `good` fixture folder → exit 0 at the documented path.
- [x] Step 3: AC-3 — `readlink fixture/.claude/skills/sw` = `../../.agents/skills/sw` and `test -f fixture/.claude/skills/sw/SKILL.md`.
- [x] Step 4: AC-4 — for each of the eight verbs `brainstorm plan pr review review-spec run spec update`: `test -f fixture/.agents/skills/sw-<verb>/SKILL.md`; content equivalence per Tasks 1–2 Step 3 diffs.
- [x] Step 5: AC-5 — `git -C fixture add -A && git -C fixture commit`; `git clone fixture fixture-clone`; `test -d` each of the three vault dirs in the clone.
- [x] Step 6: Idempotency — re-run the full procedure over the same fixture; `git -C fixture status --porcelain` after re-add → empty (no changes).
- [x] Step 7: AC-2 — `grep -n ".agents/skills/sw/" skills/sw/references/audit-checklist.md` → present in the inventory.
- [x] Step 8: Tick verified `AC-N` boxes in `issue.md`; record the evidence for the PR body. Commit.
