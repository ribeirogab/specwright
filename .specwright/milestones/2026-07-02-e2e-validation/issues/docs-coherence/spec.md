---
feature: docs-coherence
created: 2026-07-02
scope: medium
branch: chore/e2e-docs-coherence
worktree: .specwright/worktrees/docs-coherence
milestone: .specwright/milestones/2026-07-02-e2e-validation
---
# Docs Coherence (T11) — Spec

**Issue:** see the sibling `issue.md` (the *why*, the acceptance criteria, and the issue `status:`)
**Scope:** Audit README.md, AGENTS.md, and the five `skills/sw/references/*.md` against the repo's shipped behavior, exercise `validate-spec.sh` against five fixtures on the new layout, and record every divergence in `findings.md` — no doc fixes.

> **Note on `scope:` frontmatter** — `scope` is one of `low | medium | high | complex`. It is **recorded only**: reserved for a future quick-mode and does **not** yet gate which artifacts are written. Set it honestly; nothing branches on it today.
>
> **Note on `worktree:` frontmatter** — the path of this issue's git worktree under `.specwright/worktrees/`, or `null` when the work runs in place. **Recorded only**, like `scope:`.
>
> **Note on `milestone:` frontmatter** — the milestone folder this issue belongs to, or `null` for a standalone issue.

This is the **technical** spec — the *how*. The non-technical *why*, the acceptance criteria, and the status live in `issue.md`.

## Architecture

This is an audit issue: the deliverable is evidence, not code. Three lanes, each mapping documented claims to a source of truth in the repo, all converging into one `findings.md` in the issue folder.

**Lane A — prose docs (AC-1).** Extract every checkable claim from `README.md` and `AGENTS.md`: counts ("8 commands"), command names (`/sw:*`), paths (`.specwright/{conventions,issues,milestones}`, `.agents/skills/sw-<name>/`, `.specwright/worktrees/<slug>`), artifact names (`issue.md`, `spec.md`, `tasks.md`, `learnings.md`, `goal.md`, `board.md`), and flow steps (brainstorm → scope → plan pipeline → gates → pr → review → shipped). Each claim gets a row in a verdict table: claim (quoted), source of truth (file path), `match`/`mismatch`.

Sources of truth (checked, not assumed):
- Command surface: `plugins/sw/commands/*.md` + `plugins/sw/skills/*/SKILL.md` (the plugin is what Claude Code loads) and `.claude-plugin/marketplace.json` + `plugins/sw/.claude-plugin/plugin.json`.
- Canonical copies for non-Claude agents: `.agents/skills/sw-*/` (currently 6 dirs: brainstorm, plan, pr, review, run, update).
- Vault layout: `.specwright/` in this repo (conventions/, issues/, milestones/, worktrees/) and `skills/sw/references/vault-files.md`.
- Pipeline steps: `plugins/sw/skills/plan/SKILL.md`, `plugins/sw/skills/run/SKILL.md`.
- Templates: `skills/sw/scaffold/templates/*.md`.

**Lane B — skill references (AC-2).** For each of `audit-checklist.md`, `vault-files.md`, `validation.md`, `agents-md-template.md`, `claude-plugin-settings.md`: grep for retired artifacts (`design.md`, `specs/` as a live directory, old skill/command names such as `sw-specify`, `/sw:specify`, `specify`, `sw-design`) and read the full file to confirm the described layout matches the unified issues + milestones layout. Mentions inside explicitly historical/legacy-cleanup notes do not count as violations — quote and classify each hit.

**Lane C — validator behavior (AC-3).** Build five fixtures in the session scratchpad (never in the repo tree), run `skills/sw/scripts/validate-spec.sh` against each, capture exit code + full output, and compare against the documented contract (the script header comment and `references/validation.md`):

| Fixture | Shape | Expected |
|---|---|---|
| `valid-standalone` | full issue folder, spec frontmatter `milestone: null`, every AC-N referenced in tasks.md | exit 0, `PASS: <dir>` |
| `valid-milestone` | full issue folder, spec frontmatter `milestone: .specwright/milestones/...` path | exit 0, `PASS: <dir>` |
| `bad-frontmatter` | issue.md missing `status:` key (and spec.md missing `scope:`) | exit ≥ 1, `FAIL (check 1)` and `FAIL (check 2)` lines naming the missing keys |
| `bad-placeholder` | surviving double-brace placeholder token in spec.md | exit ≥ 1, `FAIL (check 3)` naming file + line |
| `bad-uncovered-ac` | issue.md defines AC-3 that no task references | exit ≥ 1, `FAIL (check 5)` naming the missing AC id |

The exit-code contract per the script: 0 on pass, otherwise the number of failed checks (2 for usage/not-a-directory). Copy the fixtures and the captured outputs into `evidence/` inside the issue folder — the issue folder is the audit's artifact and is committed; the repo tree (skills/, tests/) is not touched.

Existing repo fixtures under `skills/sw/scripts/fixtures/` are a cross-reference (evidence the contract is already exercised), not a substitute: AC-3 demands fresh fixtures on the new layout, built by this audit.

**Convergence — findings.md (AC-4).** One document in the issue folder: the AC-1 verdict tables, the AC-2 per-reference verdicts, the AC-3 run matrix, and one `Expected / Observed / Proposed fix` entry per mismatch. No doc is edited — fixes are proposals only (milestone Non-Goal).

## File Structure

All created files live in the issue folder `.specwright/milestones/2026-07-02-e2e-validation/issues/docs-coherence/`:

- Create: `findings.md` — the audit report: verdict tables + Expected/Observed/Proposed-fix entries.
- Create: `evidence/fixtures/valid-standalone/{issue.md,spec.md,tasks.md}`
- Create: `evidence/fixtures/valid-milestone/{issue.md,spec.md,tasks.md}`
- Create: `evidence/fixtures/bad-frontmatter/{issue.md,spec.md,tasks.md}`
- Create: `evidence/fixtures/bad-placeholder/{issue.md,spec.md,tasks.md}`
- Create: `evidence/fixtures/bad-uncovered-ac/{issue.md,spec.md,tasks.md}`
- Create: `evidence/validate-spec-runs.txt` — per-fixture command, exit code, and full stdout/stderr.
- Modify: `issue.md` — status transitions and AC checkboxes (this file only, never the milestone board).
- Create: `learnings.md` — only if the audit surfaces facts future issues need.

No file outside the issue folder is created or modified.

## Phase Ordering

1. **Phase 1 — Prose-doc audit (Lane A):** README.md, then AGENTS.md; the source-of-truth reads happen here and feed Lane B.
2. **Phase 2 — Reference audit (Lane B):** the five reference files; depends on Phase 1's source-of-truth inventory.
3. **Phase 3 — Validator runs (Lane C):** independent of 1–2 but run after, so findings.md is assembled once.
4. **Phase 4 — findings.md + delivery:** assemble, commit, runtime-verify each AC, PR, review.

## Constraints

- **No doc rewrites** — milestone Non-Goals: divergences become findings, never edits. The only repo files this issue touches are inside its own issue folder.
- **No surface/reachability checks** — command *reachability* (does `/sw:spec` load) is T10's; this issue checks what the docs *claim*, against the files that define behavior.
- Fixtures are **built in the scratchpad** (`/private/tmp/claude-501/...` session scratchpad) and only their final copies land under `evidence/` — nothing under `skills/` or `tests/` changes.
- Work only on branch `chore/e2e-docs-coherence` inside the worktree; PR base is `chore/milestone-e2e-validation` (stacked).
- `bash` used to run `validate-spec.sh` must be invoked with the folder path exactly as documented: `skills/sw/scripts/validate-spec.sh <issue-folder>`.

## User Stories / Scenarios

1. A maintainer opens `findings.md` and, for any README/AGENTS claim, sees the quoted claim, the file that proves or disproves it, and a verdict — without re-deriving the audit.
2. A future fixes-issue owner picks any `mismatch` entry and has Expected/Observed/Proposed-fix, enough to patch the doc without re-reading this session.
3. A skeptic re-runs `bash skills/sw/scripts/validate-spec.sh evidence/fixtures/valid-standalone` from the issue folder and reproduces the exit code recorded in `evidence/validate-spec-runs.txt`.

## Acceptance Criteria

The acceptance criteria live in the sibling `issue.md` — the `AC-N` IDs defined there are the contract `tasks.md` references and `/sw:review` walks. Do not duplicate them here; if writing this spec exposed a missing or wrong criterion, fix `issue.md`.

## Risks and Mitigations

| Risk | Mitigation |
|---|---|
| Claim inventory misses claims (audit blind spots) | Enumerate claims mechanically first (grep for counts, `/sw:`, backticked paths) and then read line-by-line; the verdict table quotes each claim so omissions are visible. |
| "Retired artifact" false positives (historical notes) | AC-2 explicitly exempts historical/legacy-cleanup notes; every hit is quoted with its surrounding context and classified rather than pattern-matched blindly. |
| Fixture outputs differ by environment (bash version, awk) | Record the exact command, cwd, and `bash --version` line in `evidence/validate-spec-runs.txt`; expectations come from the script's own header contract. |
| Findings drift into fixes (scope creep) | findings.md carries proposals only; the quality gate re-checks `git status` shows no modified file outside the issue folder. |

## Open Questions

None.
