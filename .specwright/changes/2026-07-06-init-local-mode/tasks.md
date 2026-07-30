---
feature: init-local-mode
created: 2026-07-06
---
# Init Local Mode — Tasks

**For this issue:** see the sibling `issue.md` (acceptance criteria) and `spec.md` (technical plan).

> Each task names the `AC:` (acceptance criteria from `issue.md` it satisfies — every `AC-N` referenced by at least one task) and `Delegable:` (whether it suits an isolated task worker, and the one-line context that worker would receive). This is a markdown-and-embedded-shell change: the skills are executed by an agent, so verification runs the prescribed shell against throwaway sandbox repos rather than a unit-test suite.

## Phase 1: Core behavior

### Task 1: `/sw:init` commit-mode prompt, entry point, and gitignore

**AC:** AC-1, AC-2, AC-3, AC-4, AC-5, AC-6
**Delegable:** no — defines the mode semantics every other file describes; the owner keeps it.
**Files:**
- Modify: `plugins/sw/skills/init/SKILL.md`

- [ ] **Step 1: Insert "Step 2 — choose the commit mode" before the current Step 2**

  Add a section that: (a) detects the established mode, (b) always asks the user shared/local, (c) branches. Detection snippet (filename-based — no reliance on `git`):

  ```bash
  if grep -q 'claude plugin install sw@specwright' CLAUDE.local.md 2>/dev/null; then
    established=local
  elif grep -q 'claude plugin install sw@specwright' CLAUDE.md 2>/dev/null; then
    established=shared
  else
    established=none
  fi
  ```

  Prose rules to state in the section:
  - **Always ask** which mode — `shared` (committed `CLAUDE.md` + committed vault) or `local` (`CLAUDE.local.md` + git-ignored vault, for a repo you don't own) — even on a re-run (AC-1). Present `established` as the current-state context.
  - `established=none` or chosen == `established` → proceed to Step 3/Step 4 in the chosen mode (idempotent on re-run — AC-5).
  - chosen != `established` → **guard-only migration** (AC-6): print the detected current mode, the consequences of switching, and the exact manual commands to switch (e.g. `git rm --cached -r .specwright` to untrack the vault, moving `CLAUDE.md` ⇄ `CLAUDE.local.md`, editing `.gitignore`), then **stop** — write nothing. State plainly that init never auto-migrates.

- [ ] **Step 2: Renumber the entry-point step to "Step 3" and parameterize it on `ENTRY`**

  Define `ENTRY=CLAUDE.md` for `shared`, `ENTRY=CLAUDE.local.md` for `local`. Replace the literal `CLAUDE.md` in this step's prose and its `grep -q 'claude plugin install sw@specwright' CLAUDE.md` snippet with `$ENTRY`. Add one sentence: in `local` mode init writes only `CLAUDE.local.md` and never creates or edits `CLAUDE.md` (a team's `CLAUDE.md` is left untouched) — AC-3.

- [ ] **Step 3: Renumber the gitignore step to "Step 4" and add the local-mode lines**

  Keep the existing `.specwright/worktrees/` snippet unchanged and applied in **both** modes. Append, for `local` mode only:

  ```bash
  for line in '.specwright/' 'CLAUDE.local.md'; do
    if ! grep -qxF "$line" .gitignore; then
      [ -s .gitignore ] && [ -z "$(tail -c1 .gitignore)" ] || printf '\n' >> .gitignore
      echo "$line" >> .gitignore
    fi
  done
  ```

  State that these make `.specwright/` and `CLAUDE.local.md` git-ignored (AC-4), reuse the same `grep -qxF` + blank-line guard for idempotency (AC-5), and that the blanket `.specwright/` intentionally coexists with `.specwright/worktrees/`.

- [ ] **Step 4: Update the frontmatter `description` and the "Re-running" note**

  Frontmatter `description:` and the "Re-running" section mention the shared/local mode choice. Do not alter the "Does not do" guarantees.

- [ ] **Step 5: Verify `shared` output is unchanged (AC-2) and `local` output is correct (AC-3/AC-4)**

  In a scratch dir, run the prescribed `shared`-mode shell (Steps 3–4 with `ENTRY=CLAUDE.md`) and confirm it produces the same `CLAUDE.md` + single `.specwright/worktrees/` line as today. Then run the `local`-mode shell (`ENTRY=CLAUDE.local.md` + the loop) twice and confirm: `CLAUDE.local.md` exists, no `CLAUDE.md` written, `.gitignore` has `.specwright/` and `CLAUDE.local.md` once each, and a second run is a no-op.

- [ ] **Step 6: Commit** — `feat(init): add local commit mode with always-ask and guard-only migration`

## Phase 2: Fail-safe for milestones

### Task 2: `/sw:run` refuses local mode

**AC:** AC-8
**Delegable:** no — depends on the local-mode detection semantics from Task 1.
**Files:**
- Modify: `plugins/sw/skills/run/SKILL.md`

- [ ] **Step 1: Add a "Preflight — commit mode" block before "Locate the milestone"**

  Instruct the orchestrator to probe whether the vault is git-ignored (local mode) and halt if so:

  ```bash
  git check-ignore -q .specwright/milestones && echo "local mode"
  ```

  If it reports local mode, **halt** with a message that milestone conduction is not supported in `local` mode yet (the single-issue flow is), and dispatch no issue owner (AC-8). Note why: `git worktree add` does not materialize git-ignored files, so owners would start without the contract or their issue folder.

- [ ] **Step 2: Verify the probe** — in a scratch git repo with `.specwright/` git-ignored, confirm `git check-ignore -q .specwright/milestones` exits 0; in a `shared` repo (only `.specwright/worktrees/` ignored), confirm it exits non-zero.

- [ ] **Step 3: Commit** — `feat(run): halt milestone conduction in local mode`

## Phase 3: Self-audit surface

### Task 3: Retarget `validation.md` to the entry-point file and local gitignore lines

**AC:** AC-7
**Delegable:** yes — "Make validation.md checks 1–4 target `$ENTRY` (`CLAUDE.local.md` if present else `CLAUDE.md`) instead of the literal `CLAUDE.md`, and extend check 6 to also assert `.specwright/` and `CLAUDE.local.md` in local mode."
**Files:**
- Modify: `plugins/sw/references/validation.md`

- [ ] **Step 1: Define `ENTRY` at the top of Checks**

  ```bash
  ENTRY=CLAUDE.md
  [ -f CLAUDE.local.md ] && grep -q 'claude plugin install sw@specwright' CLAUDE.local.md && ENTRY=CLAUDE.local.md
  ```

- [ ] **Step 2: Replace the literal `CLAUDE.md` in checks 1–4 with `$ENTRY`** (placeholder sweep, required headers, size cap, plugin-requirement). Update the check titles/prose to say "the entry-point file" where useful.

- [ ] **Step 3: Extend check 6** — in `local` mode (when `$ENTRY = CLAUDE.local.md`), additionally assert `grep -cxF '.specwright/'` and `grep -cxF 'CLAUDE.local.md'` each equal 1. Keep the existing `.specwright/worktrees/` assertion in both modes.

- [ ] **Step 4: Update the Contents blurb** to mention the entry-point file is mode-dependent.

- [ ] **Step 5: Verify** — build a `local`-initialized scratch repo and run all six checks; every one PASSes.

- [ ] **Step 6: Commit** — `docs(references): make validation entry-point checks mode-aware`

## Phase 4: Docs

### Task 4: Update `audit-checklist.md` inventory for both modes

**AC:** AC-9
**Delegable:** yes — "Update audit-checklist.md so the inventory lists the entry point as CLAUDE.md or CLAUDE.local.md (local mode) and .gitignore as containing .specwright/worktrees/ plus, in local mode, .specwright/ and CLAUDE.local.md; adjust the 'That is the complete list' sentence and retarget drift prose to the entry-point file."
**Files:**
- Modify: `plugins/sw/references/audit-checklist.md`

- [ ] **Step 1: Edit the "Files and directories to check" block** — entry point is `CLAUDE.md` *or* `CLAUDE.local.md` (local); `.gitignore` line note covers both modes.
- [ ] **Step 2: Update "That is the complete list."** to name the mode variance.
- [ ] **Step 3: Retarget the drift-detection prose** from `CLAUDE.md` to "the entry-point file".
- [ ] **Step 4: Commit** — `docs(references): audit checklist covers shared and local modes`

### Task 5: Update the remaining docs

**AC:** AC-9
**Delegable:** yes — "Update five docs to describe /sw:init's shared/local commit modes: plugins/sw/references/claude-md-template.md (note the local variant writes CLAUDE.local.md + the worktree caveat), plugins/sw/references/vault-files.md (caveat: local mode git-ignores the vault, so clone-survival/milestone-resumability/PR-linked URLs don't apply), plugins/sw/commands/init.md (frontmatter description, no angle brackets), README.md (Use section + /sw:init table row + a short local-mode paragraph), and the dogfood CLAUDE.md (the /sw:init one-liner, keep the file ≤ 80 lines). Keep them accurate to the semantics in plugins/sw/skills/init/SKILL.md."
**Files:**
- Modify: `plugins/sw/references/claude-md-template.md`
- Modify: `plugins/sw/references/vault-files.md`
- Modify: `plugins/sw/commands/init.md`
- Modify: `README.md`
- Modify: `CLAUDE.md` (repo dogfood — keep ≤ 80 lines)

- [ ] **Step 1: `claude-md-template.md`** — parameterize "written to `CLAUDE.md`" wording; add the local-variant note + the worktree caveat (local entry point doesn't cross worktrees → milestone conduction not supported in local mode yet).
- [ ] **Step 2: `vault-files.md`** — add the git-ignored-vault caveat subsection.
- [ ] **Step 3: `commands/init.md`** — frontmatter `description` mentions the mode choice.
- [ ] **Step 4: `README.md`** — Use section, the `/sw:init` table row, and one short `local`-mode paragraph naming `CLAUDE.local.md` + the two git-ignore lines and that milestone conduction needs `shared` mode.
- [ ] **Step 5: `CLAUDE.md`** — the `/sw:init` one-liner mentions the shared/local choice; confirm the file is still ≤ 80 lines (`wc -l`).
- [ ] **Step 6: Commit** — `docs: document /sw:init shared and local commit modes`

## Phase 5: Runtime verification

### Task 6: Sandbox verification of every mechanical AC

**AC:** AC-1, AC-2, AC-4, AC-5, AC-7, AC-8, AC-9
**Delegable:** no — the issue owner runs runtime verification and records results for the PR body.
**Files:**
- Create (scratchpad, not committed): a throwaway harness that builds sandbox repos and runs the prescribed shell.

- [ ] **Step 1: Shared vs local init** — run the `init/SKILL.md` Step 3/4 shell for each mode in a fresh scratch git repo; assert AC-2 (shared output identical to today), AC-3/AC-4 (local writes `CLAUDE.local.md`, git-ignores both, `git status --porcelain` lists neither, `git check-ignore .specwright/ CLAUDE.local.md` prints both), AC-5 (second same-mode run = empty diff).
- [ ] **Step 2: Validation checks** — run the six updated `validation.md` checks against the local sandbox; all PASS (AC-7).
- [ ] **Step 3: Run guard** — run the `git check-ignore -q .specwright/milestones` probe in the local sandbox (exit 0 → halt) and a shared sandbox (non-zero → proceed) (AC-8).
- [ ] **Step 4: AC-1 / AC-6 inspection** — confirm by reading `init/SKILL.md` that the mode is always asked (AC-1) and that a divergent choice prints-and-stops with no write (AC-6). If the interactive prompt cannot be exercised unattended, mark AC-1/AC-6 `needs-human-verification` in `issue.md` with that reason — never fake a tick.
- [ ] **Step 4b: AC-9 doc sweep** — grep the six doc surfaces (`README.md`, `plugins/sw/commands/init.md`, `plugins/sw/references/audit-checklist.md`, `plugins/sw/references/claude-md-template.md`, `plugins/sw/references/vault-files.md`, dogfood `CLAUDE.md`) and assert each names `CLAUDE.local.md`; confirm the two `local`-mode `.gitignore` lines (`.specwright/`, `CLAUDE.local.md`) are documented where the inventory/README describe what init writes — so AC-9 is observably closed, not only implied by Tasks 4–5.
- [ ] **Step 5: Record results** for the PR body's runtime-verification section, one line per AC with how it was observed.
