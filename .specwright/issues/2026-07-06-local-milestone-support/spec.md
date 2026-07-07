---
feature: local-milestone-support
created: 2026-07-06
scope: medium
branch: feat/local-milestone-support
worktree: null
milestone: null
---
# Local Milestone Support — Spec

**Issue:** see the sibling `issue.md` (the *why*, the acceptance criteria, and the issue `status:`)
**Scope:** replace `/sw:run`'s unconditional local-mode refusal with real local-mode conduction (canonical-vault resolution + copy-in on dispatch + sync-back on return + vault-based readiness), add a `/sw:pr` artifact-link fallback for local mode, and update the docs that said local mode does not support milestones.

This is the **technical** spec — the *how*. The non-technical *why*, the acceptance criteria, and the status live in `issue.md`.

## Architecture

Same markdown-and-embedded-shell shape as the init-local-mode issue: the skills are agent-executed prose plus shell probes, and verification runs those probes against sandbox repos.

**The core substitution.** In `shared` mode git is the sync bus: an owner commits `issue.md`/`spec.md` on its branch and `/sw:run` reads a dependency's status "from its branch." In `local` mode the vault and `CLAUDE.local.md` are git-ignored, so git cannot carry them across worktrees. `/sw:run` therefore syncs the spec artifacts by **file copy**, and — crucially — because the `.gitignore` *lines* are committed in `local` mode, any file copied into a worktree is already covered by that committed `.gitignore`, so it stays untracked there and the owner never commits it by accident.

**Commit-mode + vault detection (preflight).** Two independent facts:
- *Is this local mode?* `git check-ignore -q .specwright/milestones` — succeeds whenever the committed `.gitignore` blanket-ignores `.specwright/`, so it reports `local` from **any** worktree (the `.gitignore` is committed and present in every checkout), even one where the vault directory itself is absent.
- *Is the vault present in this checkout?* `[ -d .specwright/milestones ]`. In `local` mode the vault lives only where `/sw:init local` ran; a checkout without it cannot be the conductor's home.

Resolution: `shared` → conduct as today. `local` + vault absent → **stop** (AC-1). `local` + vault present → this checkout is the **canonical vault**; conduct with the copy-in / sync-back adaptations (AC-2).

**Local-mode loop adaptations** (each gated behind the local-mode flag; `shared` untouched — AC-7):
- *Readiness* reads each dependency's `status:` from the **canonical vault** (the conductor's own `.specwright/`), not from a branch checkout — the sync-back keeps it current (AC-5).
- *Dispatch* copies `CLAUDE.local.md` and the ready issue's folder into the new worktree right after `git worktree add`; both land git-ignored there (AC-3).
- *Track* copies the returned owner's issue folder back into the canonical vault — transporting the owner's flipped `status:` + `spec.md`/`tasks.md`/`learnings.md` (AC-4). This is **transport, not authorship**: the orchestrator moves the owner's files to the canonical location (git's stand-in), it does not compose or edit their content — the "never edits an `issue.md`" boundary holds.
- *Board durability*: the per-append board-commit rule is a `shared`-mode crash guard; in `local` mode the board is git-ignored, so it persists by **file write** in the canonical vault (there is no branch to lose an uncommitted line to) — the commit step is a no-op there, documented so it doesn't read as a bug.

**`/sw:pr` link fallback.** `/sw:pr` links `issue.md`/`spec.md`/`tasks.md` as absolute GitHub URLs on the branch. In `local` mode those files are never pushed, so the URLs 404. Detect local mode (the same `git check-ignore` probe) and omit the artifact links, inlining a one-line note that the artifacts live only in the local vault (AC-6). Applies to any local-mode PR, standalone or milestone.

## File Structure

- **Modify `plugins/sw/skills/run/SKILL.md`** — rewrite the "Preflight — commit mode" section (from the #63 unconditional halt to the AC-1/AC-2 conditional); add local-mode branches to loop step 1 (readiness from canonical vault), step 2 (copy-in after `git worktree add`), step 3 (sync-back on return + the board no-op note). Keep every `shared`-mode instruction intact.
- **Modify `plugins/sw/skills/pr/SKILL.md`** — the "Title and body" artifact-link instruction and the embedded-fallback `## Issue` block gain a local-mode branch: omit GitHub URLs, inline a short note (AC-6).
- **Modify `plugins/sw/references/claude-md-template.md`** — the caveat added in #63 ("milestone conduction is not supported in `local` mode yet") becomes a description of the now-supported copy-in/sync-back conduction.
- **Modify `plugins/sw/references/vault-files.md`** — the local-mode note that ended "that is why `/sw:run` refuses to conduct a milestone in local mode" is updated to describe the supported model.

## Phase Ordering

1. **Core** — `run/SKILL.md` preflight + loop adaptations.
2. **PR** — `pr/SKILL.md` link fallback.
3. **Docs** — `claude-md-template.md`, `vault-files.md` (and any residual "not supported yet" wording in `run/SKILL.md`).
4. **Verify** — sandbox the shell primitives (mode+vault detection, copy-in gitignore-status, sync-back); the full multi-agent conduction flow is verified by inspection / marked `needs-human-verification`.

Phases 1–3 are independent doc edits; phase 4 depends on 1.

## Constraints

- **`shared` conduction and PR behavior frozen (AC-7).** Every local-mode instruction is gated behind the local-mode probe; a `shared` run is byte-for-byte the same flow as before.
- **Orchestrator boundary holds.** Copy-in / sync-back is transport of the owner's own files, not authoring — the "never edits an `issue.md`, never touches code outside the milestone folder" boundary is preserved; state this explicitly so a reviewer does not read it as a violation.
- **Copies must stay git-ignored.** Rely on the committed `.gitignore` lines (`.specwright/`, `CLAUDE.local.md`) so a copied-in artifact is never committed by the owner; do not add per-file ignore handling.
- **Detection is `git check-ignore`-based** (git is always present during conduction), consistent with the probe #63 introduced.
- **Stacked branch.** This branch is cut from `feat/init-local-mode` (PR #63, unmerged) because it edits `run/SKILL.md` which #63 already changed; the PR targets `feat/init-local-mode` and re-targets `main` after #63 merges.
- Meaningful-comments and no-AI-attribution conventions apply.

## User Stories / Scenarios

1. **Conduct a milestone in a local-mode repo** — dev ran `/sw:init local`, wrote a milestone, runs `/sw:run` from that checkout. It resolves the canonical vault, dispatches owners into worktrees with the contract + issue folder copied in, syncs each returned folder back, and reads readiness from the canonical vault. Owners' code goes to branches/PRs; the spec artifacts never leave the local vault.
2. **`/sw:run` from a blind worktree** — dev runs `/sw:run` from a claude worktree that lacks the vault; it stops with "run it from the checkout where you ran `/sw:init local`" and dispatches nothing.
3. **PR in local mode** — an owner's `/sw:pr` opens a PR whose body omits the artifact GitHub URLs (un-pushed) and notes the artifacts are local-only.
4. **Shared milestone** — unchanged: git carries the artifacts, readiness reads branches, no copy-in/sync-back.

## Acceptance Criteria

The acceptance criteria live in the sibling `issue.md` — the `AC-N` IDs there are the contract `tasks.md` references and `/sw:review` walks. Do not duplicate them here.

## Risks and Mitigations

| Risk | Mitigation |
|---|---|
| Copy-in/sync-back reads as an orchestrator-boundary violation ("never edits an issue.md") | Frame it as transport of the owner's own files (git's substitute), not authoring; state this in `run/SKILL.md` and the spec. |
| A copied-in artifact gets committed by the owner, leaking the vault into the branch | The `.gitignore` lines are committed in `local` mode, so copies land git-ignored in the worktree; AC-3 asserts `git status` shows neither. |
| `git check-ignore` mode-detection misfires from a worktree without the vault | The probe reads the committed `.gitignore` (present in every checkout), so it reports `local` regardless of vault presence; the separate `[ -d .specwright/milestones ]` check gates AC-1 vs AC-2. |
| The full multi-agent conduction flow (AC-2/AC-4/AC-5) is not runnable in a sandbox | Verify the shell primitives (detection, copy-in gitignore-status, sync-back file transport) in sandbox; mark the end-to-end conduction `needs-human-verification` with the reason rather than faking a tick. |
| Stacked-branch confusion (base is `feat/init-local-mode`, not `main`) | `/sw:pr` targets the dependency branch and re-targets `main` after #63 merges; noted in the PR body. |

## Open Questions

None.
