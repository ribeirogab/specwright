---
feature: issue-pipeline-contract
created: 2026-07-02
status: in-progress
shipped: null
---
# Issue Pipeline Contract — Issue

> The ticket: the approved *why* plus the acceptance criteria and the issue's status. `status:` lives **only** here — `pending | in-progress | shipped | blocked` — and `shipped:` gets the ship date when the PR is open and `/sw:review` reached `lgtm`. The technical *how* (architecture, file structure, tasks) lives in the sibling `spec.md` + `tasks.md`, written just-in-time by `/sw:plan`.

## Purpose

Close the integrity gaps the e2e validation found in the issue pipeline's two skills: the plan skill (approved tickets are a contract, plan artifacts leave a durable record, "UI criterion" gets a definition, fan-out gets an undefeatable trigger) and the pr skill (degradation checks run as an ordered pre-flight, a degraded delivery still leaves a durable PR record).

## Motivation

Dossier entries 2.1–2.4 with 7.7 (`.specwright/milestones/2026-07-02-e2e-validation/issues/closeout/dossier.md`) plus standalone-regression Divergences 1–2 and the stream-redirection observation (`.specwright/milestones/2026-07-02-e2e-validation/issues/standalone-regression/findings.md`). The `high` here: two independent owners quietly reworded an approved acceptance criterion when the mechanical gate tripped on the ticket itself. T9 additionally showed the pr skill probing with a live `gh pr create` carrying a junk payload — one precondition away from creating a real junk PR — and the degraded path evaporating the quality-gate and runtime-verification record with the session.

## Non-Goals

- Any run, brainstorm, or review skill change.
- Changing `validate-spec.sh` behavior (sibling issue `docs-and-validator`).
- Fixture-side alternatives (dossier's test-plan charges, e.g. a genuinely visual fixture criterion).

## Acceptance Criteria

Number each criterion sequentially as `AC-N` — the IDs are stable handles that `tasks.md` references (each task names the criteria it satisfies) and that `/sw:review` walks to prove every criterion was delivered. Each criterion must be a binary, observable check that someone other than the implementer can verify in under a minute. **No vague verbs** — replace them with specific, measurable conditions.

Runtime verification checks each criterion by observed behavior before the PR opens; a criterion the agent cannot verify at runtime is marked `needs-human-verification` with the reason — never silently ticked.

- [ ] **AC-1** The plan skill's mechanical-gate step states: a gate failure caused by the approved ticket itself means stop and report with the exact validator line, proceeding only after an acknowledged resolution; the owner never rewords an approved criterion; any ticket edit is its own commit naming the changed criterion (dossier 2.1).
- [ ] **AC-2** The plan skill has an explicit commit-the-plan step at the end of the spec-writing stage, and requires the PR body's quality-gate section to name the three plan self-review gates and their outcomes (dossier 2.2).
- [ ] **AC-3** The plan skill defines "UI criterion" as one about rendered appearance or interaction (not HTTP responses or text output), and requires recording the capability gap when an unattended session degrades browser verification to curl (dossier 2.3, 7.7).
- [ ] **AC-4** The fan-out rule keys on delegable-task count — two or more delegable tasks trigger fan-out — replacing the total-task-count threshold (dossier 2.4).
- [ ] **AC-5** The pr skill's degradation section is an ordered pre-flight: inspect `git remote -v` first (non-GitHub or empty means stop before anything else), then check `gh` presence/auth, and only then run `gh pr create`; the text states that `gh pr create` is never invoked as a probe and never with placeholder title or body (T9 Divergence 1).
- [ ] **AC-6** The pr skill's degradation section instructs that on either stop branch the session writes the fully-filled PR body — including quality-gate results and the per-criterion runtime-verification record — to `<issue-folder>/pr.md` and says so in its explanation (T9 Divergence 2).
- [ ] **AC-7** The plan skill's runtime-verification guidance notes that stream-sensitive checks must use per-stream file redirection (e.g. `>out 2>err`) because piping merged streams cannot attribute output (T9 observation).
- [ ] **AC-8** The three shipped copies of both edited skills (`plugins/sw/skills/{plan,pr}/SKILL.md`, `.agents/skills/sw-{plan,pr}/SKILL.md`, `skills/sw/scaffold/skills/sw-{plan,pr}/SKILL.md`) differ only in the frontmatter `name:` line.

Tick each `[x]` when verified. An issue is **not shippable** with empty or double-brace-placeholder acceptance criteria — `validate-spec.sh` and `/sw:review-spec` will reject it.
