---
feature: install-parity
created: 2026-07-02
scope: medium
branch: fix/install-parity
worktree: .specwright/worktrees/install-parity
milestone: .specwright/milestones/2026-07-02-specwright-fixes
---
# Install Parity — Spec

**Issue:** see the sibling `issue.md` (the *why*, the acceptance criteria, and the issue `status:`)
**Scope:** Bring the scaffolder's Phase 4 to parity with `install.sh` and the docs: self-install the `sw` skill, create the Claude Code discovery symlink, ship canonical `sw-spec`/`sw-review-spec` skills, and make the vault directories clone-proof.

> **Note on `scope:` frontmatter** — `scope` is one of `low | medium | high | complex`. It is **recorded only**: reserved for a future quick-mode and does **not** yet gate which artifacts are written. Set it honestly; nothing branches on it today.
>
> **Note on `worktree:` frontmatter** — the path of this issue's git worktree under `.specwright/worktrees/`, or `null` when the work runs in place. **Recorded only**, like `scope:`.
>
> **Note on `milestone:` frontmatter** — the milestone folder this issue belongs to, or `null` for a standalone issue.

This is the **technical** spec — the *how*. The non-technical *why*, the acceptance criteria, and the status live in `issue.md`.

## Architecture

The scaffolder is prose-plus-bash: `skills/sw/SKILL.md` Phase 4 contains the executable install procedure an agent runs verbatim, and `references/audit-checklist.md` defines what the audit inventories. There is no build pipeline — the fix is edits to those two documents plus new skill files. `install.sh` is the parity reference (it already self-installs `sw` via the skills CLI and creates the `.claude/skills/sw` symlink) and is **not modified**.

Four changes, all on the scaffolder/install surface:

1. **Self-copy of the `sw` skill (dossier 4.1).** A new Phase 4 subsection, placed before the companion-skills copy loop, copies the directory where the running `SKILL.md` lives (`$SW_DIR`) to `.agents/skills/sw/` — including `scaffold/` and `scripts/` — and re-asserts the executable bit on `scripts/*.sh`. Idempotency: skip when `.agents/skills/sw` already exists (which is also the no-op case when the skill is already running from `.agents/skills/sw`, i.e. an `install.sh` install). After this, `.agents/skills/sw/scripts/validate-spec.sh` — the exact path `sw-plan` and `/sw:review-spec` invoke — exists and is executable on a by-the-letter fresh scaffold.

2. **Claude Code discovery symlink (dossier 4.2).** The same subsection creates `.claude/skills/sw -> ../../.agents/skills/sw`, mirroring `install.sh` exactly: `mkdir -p .claude/skills`; replace an existing symlink in place; a non-symlink collision is surfaced, never clobbered. This is deliberately **not** gated on a pre-existing `.claude/` (unlike the plugin-settings merge): `install.sh` creates it unconditionally and the README promises the layout, so a fresh scaffold in a clean directory must contain it. The existing "legacy cleanup" loop only removes `SKILL_NAMES` entries and `rmdir`s `.claude/skills` only when empty — the `sw` symlink is not in `SKILL_NAMES`, so the cleanup cannot remove it, and its presence makes the `rmdir` a guarded no-op.

3. **Canonical `sw-spec` / `sw-review-spec` skills (dossier 4.3, parity option).** Two new skill directories in both trees the six companions already occupy: `skills/sw/scaffold/skills/sw-{spec,review-spec}/SKILL.md` (shipped by the scaffolder) and `.agents/skills/sw-{spec,review-spec}/SKILL.md` (this repo's dogfood copy, byte-identical to the scaffold copy — the established invariant: all six existing companions are `diff -rq`-identical across the two trees). Content derives from `plugins/sw/commands/{spec,review-spec}.md`: the body is kept verbatim; only the frontmatter converts from command shape (`description` + `argument-hint`) to skill shape (`name` + `description`), matching the other companions. `$ARGUMENTS` stays — companion skills already use it (see `sw-pr`). `SKILL_NAMES` in Phase 4 grows from 6 to 8 entries, which transitively gives the new skills the canonical install, the per-agent symlinks (`.codex/`, `.cursor/`, … 
— what makes `$sw-spec`/`@sw-review-spec` resolve), and the harmless legacy `.claude/skills/` cleanup. Claude Code keeps getting `spec`/`review-spec` from the plugin commands; the Claude-skip rationale in the copy loop is unchanged.

4. **Clone-proof vault (dossier 4.4).** The Phase 4 "Vault directories" section gains an idempotent `mkdir -p` + `touch .specwright/{conventions,issues,milestones}/.gitkeep` so git tracks the three vault directories and a fresh install survives a re-clone.

**Audit surface (dossier 4.1's second half).** `references/audit-checklist.md`'s inventory adds `.agents/skills/sw/` (the self-installed scaffolder, with the validator path called out), the `.claude/skills/sw` symlink check, and the two new companion skill directories, so re-runs detect a pre-parity install as `MISSING` and repair it.

**Rejected alternative:** scoping the docs down to six skills (dossier 4.3 option a) — explicitly rejected at the fixes brainstorm; the recorded decision is real parity.

## File Structure

- Modify: `skills/sw/SKILL.md` — Phase 4: vault `.gitkeep` step; new "Install the `sw` skill itself (self-copy + Claude Code symlink)" subsection; `SKILL_NAMES` 6 → 8; Rules list gains the self-install + symlink bullets.
- Modify: `skills/sw/references/audit-checklist.md` — inventory adds `.agents/skills/sw/`, `.claude/skills/sw` symlink, `sw-spec`, `sw-review-spec`.
- Create: `skills/sw/scaffold/skills/sw-spec/SKILL.md` — canonical spec-entry skill, body from `plugins/sw/commands/spec.md`.
- Create: `skills/sw/scaffold/skills/sw-review-spec/SKILL.md` — canonical external-evaluator skill, body from `plugins/sw/commands/review-spec.md`.
- Create: `.agents/skills/sw-spec/SKILL.md` — dogfood copy, byte-identical to the scaffold copy.
- Create: `.agents/skills/sw-review-spec/SKILL.md` — dogfood copy, byte-identical to the scaffold copy.

Not touched (scope guard): `install.sh`, `README.md`, `references/agents-md-template.md`, `references/validation.md`, `scripts/validate-spec.sh`, `plugins/`, the six existing companion skills, `tests/`.

## Phase Ordering

1. New skill files first (`sw-spec`, `sw-review-spec` in both trees) — self-contained, no dependencies.
2. `skills/sw/SKILL.md` Phase 4 edits (self-copy, symlink, `SKILL_NAMES`, `.gitkeep`) — reference the files from 1.
3. `references/audit-checklist.md` inventory — audits the layout 1+2 produce.
4. Runtime verification: execute the updated Phase 4 procedure in a throwaway fixture; verify each AC by observed behavior.

## Constraints

- The scaffolder must stay idempotent: every new step is guarded (`[ -e ] && continue` / `mkdir -p` / `touch` on an existing file is a no-op) and a re-run over a healthy install changes nothing.
- The self-copy must be a no-op when the skill already runs from `.agents/skills/sw` (an `install.sh`-produced layout) — guaranteed by the existence guard.
- Never gate the `.claude/skills/sw` symlink on `.claude/` existing; never clobber a non-symlink at that path (mirror `install.sh`'s `fail` with a surfaced report — the skill's "surface destructive ops" rule).
- The two new skills must not be added to `plugins/sw/skills/` — Claude Code gets `/sw:spec` and `/sw:review-spec` as plugin *commands*; duplicating them as plugin skills would double the slash-menu entries.
- Sibling issue `docs-and-validator` stacks on this branch for AGENTS.md-template/README/validator wording — those files stay untouched here even where their text is now satisfiable.
- No shipped sibling has a `learnings.md` yet (all run in parallel); nothing to inherit.

## User Stories / Scenarios

1. **Fresh by-the-letter scaffold.** An agent with the `sw` skill runs Phase 4 in a clean repo: afterwards `.agents/skills/sw/scripts/validate-spec.sh` exists and is executable, `.claude/skills/sw` resolves to the installed skill, all eight `sw-<verb>` companion skills exist under `.agents/skills/`, and `.specwright/{conventions,issues,milestones}/` each contain `.gitkeep`.
2. **First issue on a fresh install.** The issue owner reaches the mechanical gate; `.agents/skills/sw/scripts/validate-spec.sh <folder>` runs and exits 0/non-zero — no "file not found".
3. **Codex/Cursor user follows AGENTS.md.** `$sw-spec`, `$sw-review-spec`, `@sw-spec`, `@sw-review-spec` each resolve to a real skill directory — eight verbs, eight skills.
4. **Clone survival.** A compliant fresh install is committed and re-cloned; the three vault directories still exist and the audit reports them `OK`.
5. **Re-run over a healthy install.** Phase 4 executes again; nothing is overwritten, no duplicate entries, exit clean.

## Acceptance Criteria

The acceptance criteria live in the sibling `issue.md` — the `AC-N` IDs defined there are the contract `tasks.md` references and `/sw:review` walks. Do not duplicate them here; if writing this spec exposed a missing or wrong criterion, fix `issue.md`.

## Risks and Mitigations

| Risk | Mitigation |
|---|---|
| Self-copy recurses when `$SW_DIR` is already `.agents/skills/sw` | Existence guard skips the copy; verified in runtime verification by re-running the procedure over its own output |
| `cp -r` drops the executable bit on some filesystems | Explicit `chmod +x .agents/skills/sw/scripts/*.sh` after the copy, mirroring the existing companion-skills chmod |
| Legacy `.claude/skills` cleanup removes the new symlink or `rmdir`s the directory | Cleanup loop iterates `SKILL_NAMES` only (`sw` is not a member); `rmdir` runs only when the dir is empty — the `sw` symlink keeps it non-empty; asserted in runtime verification |
| Scaffold copy and dogfood copy of the new skills drift | Byte-identical files written once and `diff -rq`-checked in the quality gate, same invariant the six existing companions hold |
| Doc-shaped procedure drifts from what an agent actually executes | Runtime verification executes the exact Phase 4 bash blocks from the updated SKILL.md against a fixture |

## Open Questions

None.
