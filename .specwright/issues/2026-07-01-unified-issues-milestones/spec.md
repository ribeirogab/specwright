---
feature: unified-issues-milestones
created: 2026-07-01
scope: complex
branch: feat/unified-issues-milestones
worktree: null
milestone: null
---
# Unified Issues + Milestones — Spec

**Status:** Shipped
**Design:** see the sibling `design.md`
**Scope:** Replace the spec-folder flow with issues as the single unit of work, rename the command surface to eight imperative verbs, and add the milestone layer (goal/board/issues) with a `/sw:run` orchestrator loop.

This is the **technical** spec — the *how*. The non-technical *why* lives in `design.md`.

> **Note:** this spec itself still uses the OLD artifact layout (`design.md` under `.specwright/specs/`) — it is the last one that does. Historical folders are migrated by a separate session driven by `tmp/migration-handoff.txt` (the file lives at the repo's main checkout root, not in this worktree); this delivery changes the tooling only.

## Architecture

The delivery rewrites specwright's markdown "programs" (skills, commands, templates, one shell validator) around a single unit — the issue — and adds one new program (the `run` orchestrator). No runtime code exists; the architecture is the file layout plus the contracts between skills:

1. **Artifact grammar (foundation).** An issue folder is identical everywhere: `issue.md` (ticket: purpose, motivation, non-goals, `AC-N`, and the only `status:` field) + `spec.md` (technical plan; `AC` section moves out) + `tasks.md` + optional `learnings.md`. Standalone issues live in `.specwright/issues/YYYY-MM-DD-<slug>/`; milestone issues in `.specwright/milestones/YYYY-MM-DD-<slug>/issues/<slug>/` (no number prefix — order lives on the board). A milestone adds `goal.md` (stable why) and `board.md` (live state: order, dependencies, blocker reports, dispatch log; never duplicates issue status).
2. **Skill contracts.** `brainstorm` assesses scope and writes either one `issue.md` (single-issue batch: branch + worktree + handoff) or the milestone set `goal.md` + `board.md` + N `issue.md` (batch: worktree only; ends with a mandatory handoff — the planning session never conducts). `plan` turns one `issue.md` (+ shipped issues' `learnings.md` in a milestone) into `spec.md` + `tasks.md`, self-reviewed by the existing three gates. The pipeline gains a **runtime verification** step between the quality gate and the PR. `review` keeps its three find-only lanes, tracing `AC-N` from `issue.md`. `pr` opens the PR (consent = the approved design; the mode knob is deleted). `run` is the orchestrator: dispatch all ready issues to owner subagents (one worktree each), track on the board, apply circuit breakers, close out with a final report + learnings promotion.
3. **Distribution.** Each skill exists in three synchronized copies (`plugins/sw/skills/<name>/`, `.agents/skills/sw-<name>/`, `skills/sw/scaffold/skills/sw-<name>/`) differing only in the frontmatter `name:` line. The `sw` installer scaffolds the vault (`.specwright/{issues,milestones,conventions}`), copies skills, and wires the Claude plugin.

Chosen over the alternative (keeping `specs/` alongside `issues/`) because two vocabularies for one artifact would force every skill and doc to explain both forever.

## File Structure

Renames (git mv; content rewritten in place afterwards):

- `plugins/sw/skills/brainstorming/` → `plugins/sw/skills/brainstorm/` (and `writing-plans/`→`plan/`, `code-review/`→`review/`, `new-pr/`→`pr/`; `update/` keeps its name) — same for the `.agents/skills/sw-*` and `skills/sw/scaffold/skills/sw-*` copies.
- `skills/sw/scaffold/spec-templates/` → `skills/sw/scaffold/templates/`.

Created:

- `skills/sw/scaffold/templates/issue.md` — ticket template: frontmatter `feature/created/status/shipped`, sections Purpose, Motivation, Non-Goals, Acceptance Criteria (`AC-N` checkboxes).
- `skills/sw/scaffold/templates/goal.md` — milestone why: Purpose, Motivation, Success Criteria, Non-Goals.
- `skills/sw/scaffold/templates/board.md` — live state: Issues table (order, slug, dependencies), Dispatch Log, Blockers.
- `plugins/sw/skills/run/SKILL.md` (+ `.agents/skills/sw-run/`, `skills/sw/scaffold/skills/sw-run/`) — the orchestrator skill.

Modified (content):

- `skills/sw/scaffold/templates/spec.md` — frontmatter drops `status/shipped/mode`, gains `milestone:`; Acceptance Criteria section replaced by a pointer to `issue.md`.
- `skills/sw/scaffold/templates/tasks.md` — header references `issue.md`.
- `skills/sw/scripts/validate-spec.sh` — validates the issue folder: `issue.md` frontmatter (`feature/created/status` + status enum), placeholders across all four files, vague-verb ACs in `issue.md`, `AC-N` coverage from `issue.md` → `tasks.md`, `spec.md` frontmatter (`feature/created/scope` + scope enum).
- `skills/sw/scripts/fixtures/*` — `design.md` → `issue.md` in all five fixtures; frontmatters updated.
- All six skill SKILL.md bodies (three copies each) — new flow content per the contracts above; `plugins/sw/skills/plan/spec-document-reviewer-prompt.md` — `design.md` → `issue.md`.
- `plugins/sw/commands/spec.md`, `plugins/sw/commands/review-spec.md` — new paths, artifact names, no mode.
- `skills/sw/SKILL.md` + `skills/sw/references/{audit-checklist,validation,vault-files,agents-md-template}.md` — vault dirs, SKILL_NAMES, template paths, AGENTS.md workflow section.
- `AGENTS.md` (root, ≤ 80 lines), `README.md`, `.specwright/conventions/skill-validation-requirements.md`, `tests/install/run.sh`, `install.sh` (if they reference renamed names/paths).
- `skills/sw/scripts/sw-update.sh` — the `managed_pairs` skill list and self-test fixtures use the new six names; `plugins/sw/.claude-plugin/plugin.json` + `.claude-plugin/marketplace.json` — descriptions name the new commands.

Deleted:

- `skills/sw/scaffold/spec-templates/design.md` (template) — replaced by `issue.md`.

## Phase Ordering

1. **Foundation** — templates + validator + fixtures (the grammar everything else references).
2. **Core skills** — rename and rewrite `brainstorm`, `plan`, `review`, `pr`, `update` (+ reviewer prompt, plugin commands) in `plugins/sw/`.
3. **Orchestrator** — the new `run` skill in `plugins/sw/`.
4. **Installer** — `skills/sw/SKILL.md` + references + `tests/install` + `install.sh`.
5. **Docs + sync** — `AGENTS.md`, `README.md`, conventions; then sync the three skill copies and run the full gate.

Phases 2–3 depend on 1; 4–5 depend on 2–3.

## Constraints

- Agent-agnostic: every behavior must be expressible as markdown instructions + POSIX shell; sub-agent dispatch always degrades to serial inline execution.
- The three skill copies may differ only in the frontmatter `name:` line (existing sync convention).
- `AGENTS.md` (root and scaffolded template) must stay ≤ 80 lines.
- Frozen history under `.specwright/specs/` and the `tmp/` handoffs are exempt from reference sweeps — they are migrated later, not rewritten here.
- All committed artifacts in English; no AI attribution anywhere.

## User Stories / Scenarios

1. A dev brainstorms a large feature; the agent suggests structuring it as a milestone, the dev approves the decomposition once, answers one batch question (worktree), receives a handoff, and later `/sw:run` conducts every issue to an open PR with `lgtm` — the dev returns to merge PRs or to a blocker report.
2. A dev brainstorms a small fix; the agent keeps it a standalone issue, asks branch + worktree + handoff, and the pipeline runs to a reviewed PR.
3. An issue fails its quality gate three times identically; it is marked `blocked` with a report on the board, the orchestrator moves on, and the milestone halts only when nothing is ready.
4. A later issue's `spec.md` references a fact recorded in an earlier issue's `learnings.md` without the dev re-explaining anything.

## Acceptance Criteria

Verification commands assume the repo root; "live files" excludes `.specwright/specs/`, `tmp/`, and `.git/`.

- [x] **AC-1** `grep -rn 'specwright/specs' --include='*.md' --include='*.sh' . | grep -v '^\./\.specwright/specs/' | grep -v '^\./tmp/'` returns zero hits.
- [x] **AC-2** `ls skills/sw/scaffold/templates/` prints exactly `board.md goal.md issue.md spec.md tasks.md`; `find . -path ./.git -prune -o -name 'design.md' -print` finds files only under `.specwright/specs/`.
- [x] **AC-3** `skills/sw/scripts/validate-spec.sh skills/sw/scripts/fixtures/good` exits 0, and each of the four `fixtures/bad-*` folders makes it exit non-zero; `fixtures/good/issue.md` exists with `status:` in frontmatter.
- [x] **AC-4** `ls plugins/sw/skills/` prints exactly `brainstorm plan pr review run update` (alphabetical); `ls .agents/skills/` and `ls skills/sw/scaffold/skills/` print the same six names with the `sw-` prefix; no directory named `brainstorming`, `writing-plans`, `code-review`, or `new-pr` exists in the repo.
- [x] **AC-5** `grep -rEln 'mode:|\`autonomous\`|\`reviewed\`' plugins/sw/ .agents/skills/ skills/sw/` returns zero files (the mode knob and its backticked value tokens are gone; the plain English word "reviewed" in prose is allowed), and `plugins/sw/skills/brainstorm/SKILL.md` contains both batch definitions: the single-issue batch (branch + worktree + handoff) and the milestone batch (worktree only, mandatory handoff).
- [x] **AC-6** `grep -rn 'design\.md' plugins/sw/ .agents/skills/ skills/sw/ AGENTS.md README.md` returns zero hits, and `plugins/sw/skills/plan/SKILL.md` names `issue.md` as input and instructs reading shipped issues' `learnings.md` when the issue belongs to a milestone.
- [x] **AC-7** `grep -rln 'needs-human-verification' plugins/sw/skills/` lists at least `plan/SKILL.md` and `review/SKILL.md`, and `plan/SKILL.md` places runtime verification between the quality gate and the PR step.
- [x] **AC-8** `plugins/sw/skills/run/SKILL.md` exists and contains, verbatim as section topics: the ready rule (`pending` + all dependencies `shipped`), parallel dispatch with one worktree per issue, serial inline degradation, the three-identical-failures circuit breaker writing a blocker report to `board.md`, and closeout with learnings promotion requiring user approval.
- [x] **AC-9** For each of the six skills, `diff` between the three copies (after stripping the `name:` frontmatter line) reports no differences.
- [x] **AC-10** The README commands table lists exactly `brainstorm, spec, plan, run, review, review-spec, pr, update`, and `wc -l < AGENTS.md` ≤ 80 with the flow section naming issues, milestones, `board.md`, and `/sw:run`.
- [x] **AC-11** `tests/install/run.sh` exits 0.
- [x] **AC-12** `skills/sw/SKILL.md` scaffolds `.specwright/issues/`, `.specwright/milestones/`, and `.specwright/conventions/` (no `.specwright/specs/`), and its `SKILL_NAMES` array is exactly the six new `sw-*` names.

## Risks and Mitigations

| Risk | Mitigation |
|---|---|
| Renamed commands break repos that installed the old skill names | `/sw:update` reconciles installed copies; the migration handoff (`tmp/migration-handoff.txt`) sweeps target repos; old names are removed, not aliased, so failures are loud, not silent |
| Grep-based ACs flag legitimate historical mentions | AC sweeps exclude `.specwright/specs/` and `tmp/` explicitly |
| The orchestrator skill over-promises on agents without sub-agent support | Degradation to serial inline execution is a first-class section of `run/SKILL.md`, mirroring the review skill's existing degradation pattern |
| Three-copy sync drift | Final phase syncs copies mechanically from `plugins/sw/skills/` and AC-9 diffs them |
| `AGENTS.md` overflows 80 lines with the new flow | The mermaid moves detail into skills; AGENTS.md keeps only the decision rule + flow outline |

## Open Questions

None.
