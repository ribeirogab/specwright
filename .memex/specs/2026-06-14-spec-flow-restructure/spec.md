---
status: draft
feature: spec-flow-restructure
created: 2026-06-14
shipped: null
branch: feat/spec-flow-restructure
mode: autonomous
related:
  - "[[memex-improvement-insights]]"
  - "[[tlc-spec-driven-workflow]]"
  - "[[openspec-workflow]]"
  - "[[mechanical-enforcement-over-prose]]"
  - "[[agents-md-as-map-not-encyclopedia]]"
  - "[[companion-skill-distribution-topology]]"
  - "[[memex-link-copies-have-drifted]]"
  - "[[bash-strict-mode-grep-filter]]"
---
# Spec-Flow Restructure — Spec

**Status:** Draft
**Scope:** Restructure the memex spec-flow artifact model (introduce `design.md`, fuse `spec.md`+`plan.md`, add a `scope` field, add AC traceability IDs + subagent-delegation to `tasks.md`) and implement four benchmark insights (#1 traceability, #2 test-integrity, #3 two-subagent spec-conformance review, #4 a mechanical artifact validator).

## Context

The `2026-06-14-benchmark-spec-driven-tools` benchmark ([[memex-improvement-insights]]) compared memex to `tlc-spec-driven` and `OpenSpec` and surfaced concrete, high-impact gaps. The maintainer has decided to act on them with a single coupled change to the memex workflow itself: reshape the per-spec artifacts and wire in the enforcement insights. The reshape separates the *non-technical* design rationale (a write-up of the already-approved design) from the *technical* spec, fuses the technical spec with the plan to remove a redundant document boundary, and threads acceptance-criteria identifiers through tasks and review so "did we deliver the spec" becomes auditable rather than judgment-based.

This spec is authored under the **current** flow (single `spec.md`, no `design.md`). The new artifact model it defines applies to **future** specs once shipped — there is no chicken-and-egg dependency.

## Problem Statement

memex's current artifacts mix concerns and leave verification open: `spec.md` blends motivation with technical content; the approved design lives only in chat and is never captured as a durable doc; acceptance criteria are an unnumbered checklist with no link to the tasks that satisfy them or proof at review that each was met; the quality gate has no defense against an agent silently deleting/weakening tests to pass; and the spec artifacts are validated only by prose self-review despite the project's own [[mechanical-enforcement-over-prose]] principle. This spec closes those gaps.

## Non-Goals

- **Not** implementing the `scope` field's *behavior*. `scope` is recorded in `spec.md` frontmatter and documented, but for now drives no artifact-skipping; the quick-mode it is reserved for is a future spec. (Insight #5 mid-flight safety valve and #6 anti-fabrication are also out of scope here.)
- **Not** migrating the 11 existing/frozen specs to the new artifact shape. Only `_template/` and the install-time templates change; frozen specs keep their ship-time bodies (per the rename-spec precedents).
- **Not** adding a runtime language dependency. The mechanical validator is a POSIX/bash shell script (memex's sanctioned scripting language) — no Python/`uv`/package requirement for installed repos. It is a **standalone** script, not an extension of the Phase-5 install validator (`references/validation.md`), though Phase-5's own checks are updated for the new template set.
- **Not** changing the human-review model: design approval remains the only human review; there is still no human spec-review gate.
- **Not** a rewrite of the constitution or rules beyond what these changes require.

## Constraints

- **3-copy distribution topology** ([[companion-skill-distribution-topology]]): every companion-skill edit must land identically in `.agents/skills/memex-<name>/`, `plugins/memex/skills/<name>/`, and `skills/memex/scaffold/skills/memex-<name>/`. A `diff -rq` across the three must show only intended differences ([[memex-link-copies-have-drifted]]).
- **`/memex:review-spec` is a Claude plugin command, not a 3-copy skill** — it lives only at `plugins/memex/commands/review-spec.md` and must be updated there (its required-sections list currently demands Context/Problem Statement in `spec.md`, which moves to `design.md`).
- **Scaffold installer wiring**: the bundled-skill copy loop in `skills/memex/SKILL.md` (`SKILL_NAMES` array + the `for type in spec plan tasks` spec-folder loop) and the chmod step for skill scripts are the only copy mechanisms today; shipping a new vault script or changing the template set requires editing those loops, not just dropping files in `scaffold/`.
- **Two template homes must stay in sync**: the dogfood vault `.memex/specs/_template/*` and the install-time templates embedded in `skills/memex/references/vault-files.md`.
- **Two AGENTS.md homes**: the dogfood root `AGENTS.md` and the install template `skills/memex/references/agents-md-template.md`.
- **AGENTS.md stays a map** ([[agents-md-as-map-not-encyclopedia]]) — the reflow must not bloat it; detail goes into `references/` and the skills.
- **Markdown is source of truth; shell for scripts** (constitution). The validator is shell, inspectable, no build step.
- **Bash strictness** ([[bash-strict-mode-grep-filter]]): the validator must handle zero-match greps without dying under `set -euo pipefail`.
- **Test-integrity (#2) targets installed repos**, not the memex repo (which has no test runner) — it lives in the scaffolded quality gate + the portable code-review skill.
- **Autonomous mode**: deliver through to an opened, reviewed (`lgtm`) PR.

## User Stories / Scenarios

1. An agent finishing the brainstorming design writes `design.md` (purpose/motivation/definitions/non-goals) as a write-up of the approved design, then `writing-plans` produces the fused technical `spec.md` + `tasks.md`.
2. A spec author writes acceptance criteria as `AC-1`, `AC-2`, …; each task in `tasks.md` names the `AC-N` it satisfies and whether it is delegable to a subagent and with what isolated context.
3. Before review, an agent runs `.memex/scripts/validate-spec.sh <spec-folder>` and gets a non-zero exit naming the first structural defect (missing frontmatter key, surviving `{{placeholder}}`, vague-verb acceptance criterion, or an `AC-N` no task references).
4. At delivery, `memex:code-review` runs two subagents — the existing law generalist and a spec-conformance reviewer that checks the diff against the spec's `AC-N` for completeness/correctness/coherence — and the main agent merges both verdicts.
5. In an installed repo, the quality gate and code-review flag a silent drop in the touched area's test count or weakened assertions as a blocker.

## Acceptance Criteria

**Artifact model (Phase 1)**

- [ ] `.memex/specs/_template/design.md` exists with frontmatter (`feature`, `spec: "[[spec]]"`, `created`) and the sections Purpose, Motivation, Definitions, Non-Goals.
- [ ] `.memex/specs/_template/plan.md` no longer exists (removed from the dogfood template and from the install templates in `vault-files.md`).
- [ ] `.memex/specs/_template/spec.md` is the technical doc: frontmatter includes `scope: {{low | medium | high | complex}}`; body contains a `design: "[[design]]"` link, Architecture, File Structure, Phase Ordering, an Acceptance Criteria section using `AC-N` IDs, and Risks; it no longer contains Context/Problem Statement/Motivation (those moved to `design.md`).
- [ ] `.memex/specs/_template/tasks.md` shows, per task, an `AC:` field listing the `AC-N` it satisfies and a `Delegable:` field (`yes`/`no` + one-line isolated-context note).
- [ ] `skills/memex/references/vault-files.md` embeds the same four template changes (design.md added, plan.md removed, spec.md technical+scope+AC-N, tasks.md AC+Delegable) so new installs scaffold the new model.
- [ ] `skills/memex/SKILL.md`'s legacy slug→bare rename loop (`for type in spec plan tasks`) is updated to include `design` (→ `spec design plan tasks`); `plan` is **retained** so pre-design-era specs still migrate their filenames to bare names (this loop renames filenames only; it never converts `plan.md` into `design.md`). The current artifact set scaffolds via the `_template/` copy in `vault-files.md`, not a per-type loop.

**Flow + skills (Phase 1)**

- [ ] `AGENTS.md` (root) and `skills/memex/references/agents-md-template.md` describe the reflowed flow: brainstorming → `design.md`; writing-plans → fused `spec.md` + `tasks.md`; the two-subagent code-review; and they reference where validator/test-integrity run. `AGENTS.md` is **≤ 80 lines** (`wc -l` — the enforced cap in `validation.md` check #14; target 45–70).
- [ ] If any AGENTS.md section header changes, `validation.md` check #4's required-header list is updated in lockstep so it neither misses a renamed header nor demands a removed one.
- [ ] `memex-brainstorming/SKILL.md` (all 3 copies) instructs writing `design.md` (not `spec.md`) as the approved-design write-up.
- [ ] `memex-writing-plans/SKILL.md` (all 3 copies) instructs producing the fused technical `spec.md` + `tasks.md` (with `AC-N` refs + `Delegable` annotations).
- [ ] The spec/plan reviewer prompts are reconciled into a single fused-spec reviewer (the standalone plan-document-reviewer is removed or folded), in all 3 copies.
- [ ] `plugins/memex/commands/review-spec.md` is updated: its required-sections check (#3) lists the new `spec.md` sections (no Context/Problem Statement), and it evaluates `design.md` for its Purpose/Motivation/Definitions/Non-Goals sections.
- [ ] The `scope` line in `_template/spec.md` carries an inline note stating it is recorded-only and reserved for a future quick-mode (not yet artifact-gating); the same note appears in `references/vault-files.md`'s embedded copy.

**Code-review two-subagent (Phase 2, insight #3)**

- [ ] `memex-code-review/SKILL.md` (all 3 copies) defines a two-subagent review: a law generalist (existing) and a spec-conformance reviewer that walks the spec's `AC-N` and reports Completeness/Correctness/Coherence; the skill states the main agent merges both verdicts into one of the existing templates.

**Validator (Phase 3, insight #4)**

- [ ] The validator source lives at `skills/memex/scaffold/vault-scripts/validate-spec.sh`; a new copy step in `skills/memex/SKILL.md` writes it to `.memex/scripts/validate-spec.sh` in the target repo and `chmod +x`'s it (mirroring the existing brainstorming-scripts chmod step). The agent-independent install path `.memex/scripts/validate-spec.sh` is what the review-spec flow calls.
- [ ] Running `.memex/scripts/validate-spec.sh <spec-folder>` on a well-formed folder exits 0; on a folder with (a) a missing required frontmatter key, (b) a surviving `{{placeholder}}`, (c) a banned vague verb in an acceptance criterion, or (d) an `AC-N` defined in `spec.md` but referenced by no task in `tasks.md`, it exits non-zero and names the failing check. Each of the four failure cases is demonstrated against a fixture (command + output recorded).
- [ ] The validator runs cleanly under `bash -euo pipefail` on a zero-match grep (no silent death — [[bash-strict-mode-grep-filter]]).
- [ ] `plugins/memex/commands/review-spec.md` invokes `.memex/scripts/validate-spec.sh` as a feedforward gate before the prose review and treats a non-zero exit as a blocking FAIL.
- [ ] `references/audit-checklist.md` and `references/validation.md` list the new `.memex/scripts/validate-spec.sh` as an expected scaffolded file (so an install missing it reports `MISSING`).

**Test-integrity (Phase 4, insight #2)**

- [ ] The scaffolded quality-gate text (`agents-md-template.md`) and `memex-code-review/SKILL.md` (all 3 copies) state the test-integrity rule: in a tested area the test count must not silently drop and assertions must not be weakened/skipped without an in-spec justification; a silent test deletion is classified a blocker. The rule is scoped to installed repos (not the memex repo itself).

**Quality + sync (Phase 5)**

- [ ] `diff -rq` across the three copies of every touched companion skill shows only intended differences (the documented name/path divergences), no accidental drift.
- [ ] The Phase-5 check *commands* (not just prose) are updated for the new template set: `validation.md` check #5 (frontmatter loop over `_template/*.md`) and check #15 (bare-name list) reference `spec/design/tasks` instead of `spec/plan/tasks`; `audit-checklist.md`'s expected-file list (currently `_template/{spec,plan,tasks}.md`) becomes `_template/{spec,design,tasks}.md`; and no Phase-5 check still asserts `_template/plan.md` exists. A fresh scaffold + Phase-5 run reports the new model as `15/15 PASS` (or the new count), not a FAIL.
- [ ] Every mermaid block added to any committed artifact parses via `npx -y @mermaid-js/mermaid-cli` (per [[validate-vault-mermaid-with-mmdc]]); command + clean output recorded.
- [ ] A PR is opened via `/memex:new-pr` and the `memex:code-review` cycle reaches `lgtm`.

## Risks and Mitigations

| Risk | Mitigation |
|---|---|
| The 3 skill copies drift during edits | Edit all three per change; Phase 5 runs `diff -rq` and reconciles; capture a baseline first ([[memex-link-copies-have-drifted]]). |
| AGENTS.md bloats past its cap with the reflow | Keep AGENTS.md a map; push step detail into the skills + `references/`; assert line count in ACs ([[agents-md-as-map-not-encyclopedia]]). |
| Bash validator brittle on YAML/markdown parsing | Keep checks to simple line patterns (grep/awk); guard zero-match greps; test against fixtures for each failing case ([[bash-strict-mode-grep-filter]]). |
| Template homes (dogfood vs vault-files.md) diverge | Treat them as one change; AC requires both updated; Phase 5 cross-checks. |
| Reflowing brainstorming/writing-plans breaks the live dogfood flow | This spec is authored under the old flow; the new flow only applies to future specs; validate the reflow by reading, not by re-running mid-spec. |
| Fusing reviewers loses a check the plan-reviewer had | Diff the two reviewer prompts before folding; carry every distinct check into the fused reviewer. |

## Open Questions

None. The artifact model, the validator medium (shell, no Python), the AC-ID scheme (`AC-N`), the delivery shape (one phased spec), the mode (autonomous), and compaction (yes) are all decided.
