---
feature: local-milestone-support
created: 2026-07-06
---
# Local Milestone Support — Tasks

**For this issue:** see the sibling `issue.md` (acceptance criteria) and `spec.md` (technical plan).

> Each task names the `AC:` (acceptance criteria from `issue.md` it satisfies — every `AC-N` referenced by at least one task) and `Delegable:` (whether it suits an isolated task worker, and the one-line context that worker would receive). Markdown-and-embedded-shell change: verification runs the prescribed shell primitives against throwaway sandbox repos; the full multi-agent conduction flow is verified by inspection.

## Phase 1: Core conduction

### Task 1: `/sw:run` preflight — mode + vault detection

**AC:** AC-1, AC-2
**Delegable:** no — sets the local-mode flag every later step keys off.
**Files:**
- Modify: `plugins/sw/skills/run/SKILL.md` (the "Preflight — commit mode" section)

- [ ] **Step 1: Replace the #63 unconditional halt with the conditional detection**

  ```bash
  if git check-ignore -q .specwright/milestones; then
    mode=local
    [ -d .specwright/milestones ] || { echo "local-mode vault not found in this checkout; run /sw:run from the checkout where you ran /sw:init local"; exit; }
  else
    mode=shared
  fi
  ```

  Prose: `shared` conducts as today (git carries the artifacts). `local` + vault absent → **stop** with the message above, dispatch nothing (AC-1). `local` + vault present → this checkout is the **canonical vault**; conduct with the copy-in / sync-back adaptations flagged in the loop (AC-2). State that the `git check-ignore` probe reports `local` from any worktree (the `.gitignore` is committed), while `[ -d .specwright/milestones ]` tests whether *this* checkout actually holds the vault.

- [ ] **Step 2: Verify** — in a sandbox: local repo with the vault present → proceeds (`mode=local`, no exit); local repo run from a checkout without `.specwright/milestones` → stops with the AC-1 message; shared repo → `mode=shared`.

- [ ] **Step 3: Commit** — `feat(run): detect local mode and resolve the canonical vault`

### Task 2: `/sw:run` loop — copy-in, sync-back, readiness

**AC:** AC-3, AC-4, AC-5
**Delegable:** no — depends on Task 1's `mode` flag and the canonical-vault decision.
**Files:**
- Modify: `plugins/sw/skills/run/SKILL.md` (loop steps 1–3)

- [ ] **Step 1: Readiness from the canonical vault (step 1, AC-5)**

  Add a local-mode branch: in `local` mode, readiness reads each dependency's `status:` from the **canonical vault** (the conductor's own `.specwright/`, kept current by sync-back), not from a dependency branch checkout. Keep the shared-mode "from the dependency's own branch" rule as the `shared` branch.

- [ ] **Step 2: Copy-in on dispatch (step 2, AC-3)**

  After `git worktree add .specwright/worktrees/<slug> -b <branch>`, add a local-mode block that copies the contract and the issue folder into the worktree (`$ISSUE_REL` = the issue folder's repo-relative path, e.g. `.specwright/milestones/<m-slug>/issues/<slug>`):

  ```bash
  if [ "$mode" = local ]; then
    cp CLAUDE.local.md ".specwright/worktrees/<slug>/CLAUDE.local.md"
    mkdir -p ".specwright/worktrees/<slug>/$(dirname "$ISSUE_REL")"
    cp -R "$ISSUE_REL" ".specwright/worktrees/<slug>/$ISSUE_REL"
  fi
  ```

  State that both land git-ignored in the worktree because the `.gitignore` lines are committed, so the owner never commits them (AC-3).

- [ ] **Step 3: Sync-back on return + board no-op note (step 3, AC-4)**

  Add a local-mode branch to Track: when an owner returns, copy its issue folder back into the canonical vault —

  ```bash
  if [ "$mode" = local ]; then
    cp -R ".specwright/worktrees/<slug>/$ISSUE_REL/." "$ISSUE_REL/"
  fi
  ```

  — transporting the owner's flipped `status:` + `spec.md`/`tasks.md`/`learnings.md`. Frame it as **transport, not authorship** (the "never edits an `issue.md`" boundary holds — the orchestrator moves the owner's own files, git's stand-in). Add one sentence that in `local` mode the per-append board **commit** is a no-op (the board is git-ignored); it persists by file write in the canonical vault.

- [ ] **Step 4: Verify** — in a sandbox worktree: `cp` the contract + an issue folder into a worktree whose committed `.gitignore` ignores `.specwright/` + `CLAUDE.local.md`, and confirm `git status --porcelain` in the worktree lists neither (AC-3); edit the copy's `issue.md` status, run the sync-back `cp`, and confirm the canonical `issue.md` reflects it (AC-4).

- [ ] **Step 5: Commit** — `feat(run): copy-in contract and issue folder, sync back in local mode`

## Phase 2: PR

### Task 3: `/sw:pr` artifact-link fallback in local mode

**AC:** AC-6
**Delegable:** yes — "In plugins/sw/skills/pr/SKILL.md, add a local-mode branch (detected by `git check-ignore -q .specwright/milestones`, the same probe /sw:run and #63 use) to the 'Title and body' artifact-link instruction and the embedded-fallback `## Issue` block: in local mode omit the issue.md/spec.md/tasks.md GitHub URLs (un-pushed → 404) and inline a one-line note that the artifacts live only in the local vault."
**Files:**
- Modify: `plugins/sw/skills/pr/SKILL.md`

- [ ] **Step 1: Local-mode branch in the artifact-link instruction** — the "link the issue artifacts as absolute GitHub URLs" line (Title and body) and the embedded-fallback `## Issue` section gain: if `git check-ignore -q .specwright/milestones` (local mode), omit the GitHub URLs and inline "artifacts live in the local (un-pushed) `.specwright/` vault" instead.
- [ ] **Step 2: Verify** — inspect that the shared path is unchanged and the local branch is gated behind the probe; confirm the probe exits 0 in a local sandbox, non-zero in a shared one.
- [ ] **Step 3: Commit** — `feat(pr): omit un-resolvable artifact links in local mode`

## Phase 3: Docs

### Task 4: Update the "not supported yet" docs

**AC:** AC-8
**Delegable:** yes — "Two references stated local mode does not support milestones; update them to describe the now-supported copy-in/sync-back conduction. In plugins/sw/references/claude-md-template.md the caveat 'milestone conduction is not supported in local mode yet — the single-issue flow is' becomes a description that /sw:run supports local milestones by copying the contract + issue folder into each worktree and syncing back. In plugins/sw/references/vault-files.md the note ending 'that is why /sw:run refuses to conduct a milestone in local mode' is updated the same way. Keep them accurate to plugins/sw/skills/run/SKILL.md."
**Files:**
- Modify: `plugins/sw/references/claude-md-template.md`
- Modify: `plugins/sw/references/vault-files.md`
- Modify: `README.md`

- [ ] **Step 1: `claude-md-template.md`** — rewrite the local-mode worktree caveat to describe supported conduction (copy-in + sync-back), dropping "not supported yet".
- [ ] **Step 2: `vault-files.md`** — update the local-mode note to describe supported conduction instead of the refusal.
- [ ] **Step 3: `README.md`** — the "Milestone conduction (`/sw:run`) needs `shared` mode" line (arrived from the merged #63) now describes both modes conducting.
- [ ] **Step 4: Sweep `run/SKILL.md`** for any residual "not supported yet" wording left by Task 1 and fix it.
- [ ] **Step 4: Commit** — `docs(references): local mode now supports milestone conduction`

## Phase 4: Verification

### Task 5: Sandbox primitives + shared no-regression

**AC:** AC-1, AC-2, AC-3, AC-4, AC-5, AC-6, AC-7, AC-8
**Delegable:** no — the issue owner runs runtime verification and records results for the PR body.
**Files:**
- Create (scratchpad, not committed): a harness exercising the prescribed shell.

- [ ] **Step 1: Detection** — mode+vault probe: local+vault → proceed; local+no-vault → AC-1 stop; shared → shared path (AC-1, AC-2).
- [ ] **Step 2: Copy-in gitignore-status** — copies land git-ignored in a worktree whose committed `.gitignore` ignores `.specwright/`+`CLAUDE.local.md`; `git status --porcelain` lists neither (AC-3).
- [ ] **Step 3: Sync-back transport** — editing the worktree copy's `issue.md` status and running the sync-back `cp` updates the canonical `issue.md` (AC-4).
- [ ] **Step 4: `/sw:pr` + shared no-regression** — the local probe gates the pr fallback (AC-6); confirm every local-mode branch in `run`/`pr` is behind the probe so a shared run is unchanged (AC-7); AC-5 (readiness source) verified by inspection of the loop text.
- [ ] **Step 5: AC-8 doc sweep** — `claude-md-template.md`, `vault-files.md`, `run/SKILL.md` no longer say local milestones are unsupported and describe copy-in/sync-back.
- [ ] **Step 6: Mark the end-to-end flow** — full multi-agent local conduction (AC-2/AC-4/AC-5 in a live run) is not sandbox-runnable; mark `needs-human-verification` in `issue.md` with that reason where a criterion is only observable in a live `/sw:run`, never a faked tick. Record all results for the PR body.
