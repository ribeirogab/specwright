---
feature: command-surface
created: 2026-07-02
scope: medium
branch: chore/e2e-command-surface
worktree: .specwright/worktrees/command-surface
milestone: .specwright/milestones/2026-07-02-e2e-validation
---
# Command Surface (T10) — Spec

**Issue:** see the sibling `issue.md` (the *why*, the acceptance criteria, and the issue `status:`)
**Scope:** Audit-only: verify the 8-verb command surface (brainstorm · spec · plan · run · review · review-spec · pr · update) exists coherently at every documented layer in both the specwright repo and the sandbox install, verify retired names resolve nowhere, and record every divergence in `findings.md` — no fixes.

> **Note on `scope:` frontmatter** — `scope` is one of `low | medium | high | complex`. It is **recorded only**: reserved for a future quick-mode and does **not** yet gate which artifacts are written. Set it honestly; nothing branches on it today.
>
> **Note on `worktree:` frontmatter** — the path of this issue's git worktree under `.specwright/worktrees/`, or `null` when the work runs in place. **Recorded only**, like `scope:`.
>
> **Note on `milestone:` frontmatter** — the milestone folder this issue belongs to, or `null` for a standalone issue.

This is the **technical** spec — the *how*. The non-technical *why*, the acceptance criteria, and the status live in `issue.md`.

## Architecture

This is an evidence-gathering audit, not a code change. The only artifact produced is `findings.md` in this issue folder. The audit walks two installations across four layers and cross-checks them against the docs:

**Surfaces audited**

1. **specwright repo** (this worktree, `/Users/gabriel/www/ribeirogab/specwright/.claude/worktrees/pensive-bose-7ba1c1/.specwright/worktrees/command-surface`):
   - Claude Code plugin: `plugins/sw/commands/*.md` (command stubs) + `plugins/sw/skills/<verb>/SKILL.md` (plugin skills; a plugin skill is also invocable as `/sw:<verb>`).
   - Canonical scaffolded copies: `.agents/skills/sw-<verb>/SKILL.md` (the surface Codex `$sw-<verb>` and Cursor `@sw-<verb>` users get).
   - Legacy locations: `.claude/commands/sw-*.md` must not exist.
2. **Sandbox install** (`/Users/gabriel/www/ribeirogab/specwright-sandbox/taskr`):
   - Canonical copies: `.agents/skills/sw-<verb>/` + the scaffolder `sw` skill.
   - Claude Code side: `.claude/settings.json` marketplace/plugin wiring (the sandbox gets the plugin from the marketplace, so `plugins/` lives in the plugin cache, not the project — the audit records what the project itself carries and what the settings reference).
   - Per-agent discovery dirs and symlinks (e.g. `CLAUDE.md` symlink, any `.codex/`, `.cursor/`, `.opencode/` dirs): every symlink found must resolve; none may point at a retired name.

**Checks per verb × layer**

- Existence: the artifact for the verb is present at the layer (`present`/`absent` + exact path) — AC-1.
- Identity: where the artifact is a skill, `SKILL.md` frontmatter `name:` equals the invocation name at that layer — plugin skills: bare verb (e.g. `plan`); canonical copies: `sw-<verb>` (e.g. `sw-plan`) — AC-2.
- Retirement: zero artifacts/symlinks matching `sw-brainstorming`, `sw-writing-plans`, `sw-new-pr`, `sw-code-review`, and no legacy `.claude/commands/sw-spec.md` / `sw-review-spec.md`; no dangling symlinks under any agent discovery dir — AC-3.
- Doc coherence: every `/sw:<verb>`, `$sw-<verb>`, `@sw-<verb>` mention in the repo docs (`README.md`, `AGENTS.md`, `CLAUDE.md`, `CONTRIBUTING.md`) and the sandbox docs (`AGENTS.md`, `CLAUDE.md`) maps to an existing artifact in the layout that surface actually has; any promise without an artifact (or artifact without a documented invocation) is a finding with the doc line and the missing path — AC-4.

**Method**: every check is a shell command whose output is captured verbatim into `findings.md` (evidence blocks), so each verdict is reproducible. `findings.md` structure: verdict table first (verbs × layers), then a Retired-names section, then a Doc-coherence section, then one `Expected / Observed / Proposed fix` entry per divergence.

**Inherited learnings folded in**

- Sandbox at `/Users/gabriel/www/ribeirogab/specwright-sandbox/taskr`; its origin is a local bare repo — never GitHub; the sandbox is not modified by this audit (read-only access).
- Sandbox is fully installed: AGENTS.md + `CLAUDE.md` symlink + `.agents/skills/sw` + six `sw-*` skills + `.claude/settings.json` with the github marketplace source.
- From docs-coherence (relayed by the orchestrator; its branch is not merged here): `/sw:spec` and `/sw:review-spec` have no canonical `.agents/skills` copy — re-verify independently and record fresh evidence rather than assuming.

## File Structure

- Create: `.specwright/milestones/2026-07-02-e2e-validation/issues/command-surface/findings.md` — the deliverable: verdict table, retired-name sweep, doc-coherence map, Expected/Observed/Proposed-fix per divergence, evidence blocks.
- Modify: `.specwright/milestones/2026-07-02-e2e-validation/issues/command-surface/issue.md` — status transitions + AC checkboxes.
- Create: `.specwright/milestones/2026-07-02-e2e-validation/issues/command-surface/learnings.md` — only if non-obvious facts for future issues emerge.
- Read-only: everything under the repo (`plugins/`, `.agents/`, `skills/`, docs) and the entire sandbox (`/Users/gabriel/www/ribeirogab/specwright-sandbox/taskr`).

## Phase Ordering

1. **Inventory** — enumerate every layer in repo + sandbox (Tasks 1–3): pure data gathering.
2. **Cross-check** — retired names + doc coherence (Tasks 4–5): needs the inventory.
3. **Report** — assemble `findings.md`, verify ACs, ship (Tasks 6–7).

## Constraints

- **Findings only** — the audit never edits the repo surface or the sandbox, even for one-character fixes (milestone non-goal). Fixes are proposed in `findings.md`.
- The sandbox is shared state for parallel milestone issues — strictly read-only there.
- Commits only on `chore/e2e-command-surface`, inside this worktree; PR base is `chore/e2e-sandbox-setup` (stacked).
- The repo is markdown + shell (no build); the quality gate is the repo's own test suite under `tests/` if runnable, plus `validate-spec.sh` for this issue's artifacts.
- The docs-coherence issue (T11) owns prose quality; this issue only checks existence/reachability — do not log wording findings.

## User Stories / Scenarios

1. A maintainer reads `findings.md` and sees, per verb and layer, `present`/`absent` with the exact path checked — no re-running needed to trust a cell (AC-1).
2. A Codex user types `$sw-spec`; the audit tells the maintainer whether that documented invocation actually resolves to a `.agents/skills/sw-spec/` artifact, and if not, files the divergence with the doc line that promises it (AC-2, AC-4).
3. A user greps the install for `sw-brainstorming` after the rename; the audit already proves zero hits — or lists exactly where the corpse lives (AC-3).
4. Each failure in `findings.md` reads Expected / Observed / Proposed fix, so the follow-up fix issue can be written without re-investigation (AC-5).

## Acceptance Criteria

The acceptance criteria live in the sibling `issue.md` — the `AC-N` IDs defined there are the contract `tasks.md` references and `/sw:review` walks. Do not duplicate them here; if writing this spec exposed a missing or wrong criterion, fix `issue.md`.

## Risks and Mitigations

| Risk | Mitigation |
|---|---|
| The plugin cache (marketplace install) differs from the repo's `plugins/` — auditing only the repo copy misses what the sandbox user actually gets | Record the sandbox's `.claude/settings.json` wiring and, if present on this machine, the installed plugin cache path; state explicitly which copy each verdict is about |
| Symlink checks pass on a live tree but the links are dangling relative to another checkout | Use `find -L ... -type l` (dangling detector) plus `ls -l` capture of every symlink target |
| Doc greps miss an invocation spelled unusually (backticks, tables) | Grep the raw patterns `/sw:`, `$sw-`, `@sw-` case-insensitively over all tracked `.md` files, not a curated list of lines |
| Parallel milestone issues mutate the sandbox mid-audit | Capture evidence in one pass per surface and timestamp the evidence blocks |

## Open Questions

None.
