---
feature: brainstorm-and-templates
created: 2026-07-02
scope: medium
branch: fix/brainstorm-and-templates
worktree: .specwright/worktrees/brainstorm-and-templates
milestone: .specwright/milestones/2026-07-02-specwright-fixes
---
# Brainstorm and Templates — Spec

**Issue:** see the sibling `issue.md` (the *why*, the acceptance criteria, and the issue `status:`)
**Scope:** Text-contract edits to the brainstorm skill (three shipped copies), the vault-files reference, and two scaffold templates — no code, no validator, no other skill touched.

> **Note on `scope:` frontmatter** — `scope` is one of `low | medium | high | complex`. It is **recorded only**: reserved for a future quick-mode and does **not** yet gate which artifacts are written. Set it honestly; nothing branches on it today.
>
> **Note on `worktree:` frontmatter** — the path of this issue's git worktree under `.specwright/worktrees/`, or `null` when the work runs in place. **Recorded only**, like `scope:`.
>
> **Note on `milestone:` frontmatter** — the milestone folder this issue belongs to, or `null` for a standalone issue.

This is the **technical** spec — the *how*. The non-technical *why*, the acceptance criteria, and the status live in `issue.md`.

## Architecture

Five dossier findings (3.1–3.5) each map to one localized text change. The brainstorm skill is the canonical edit surface for AC-1..AC-4 and AC-6; the vault-files reference carries AC-5; two scaffold templates get one supporting line each so the rule also lives in the data the planner copies (Rule of Representation).

The brainstorm skill ships as three byte-identical copies except the frontmatter `name:` line (`sw-brainstorm` in `.agents/` and `skills/sw/scaffold/`, `brainstorm` in `plugins/sw/skills/`). Edit strategy: author every change in `.agents/skills/sw-brainstorm/SKILL.md`, then propagate with `cp` and restore the plugin copy's `name: brainstorm` line — never hand-sync three files.

Per-finding placement, chosen to state each rule exactly once and reference it elsewhere (the same discipline AC-4 introduces):

1. **AC-1 (goal in behavior terms)** — the `goal.md` bullet inside "Milestone — batch and artifacts" gets the rule (no file paths, function names, or storage formats), one worked example translating a technical hard constraint into goal-level language, and the sentence that path-level constraints live in issue tickets. The `goal.md` template's Success Criteria placeholder gets a short behavior-terms hint pointing the writer the same way.
2. **AC-2 (validator before commit)** — the milestone artifacts step (the decomposition step) gets the full instruction: run `validate-spec.sh` on each `issues/<slug>/` folder before committing; planning-stage baseline is exactly one check-2 failure (`spec.md not found`, the spec is just-in-time); anything else is the planner's to fix. The single-issue artifact step gets one sentence referencing the same rule so standalone tickets get the same gate without restating the baseline.
3. **AC-3 (scope conclusion)** — checklist item 6 is reworded: small work concludes "single issue" plainly, no milestone alternative presented; the milestone option (with decomposition preview) appears only when the scope signals point to one. Stays consistent with the existing "Judging the scope" section, which already says "never mention it for work that fits one issue".
4. **AC-4 (state a constraint once)** — a new bullet in "Writing acceptance criteria (the loop's exit condition)": state a hard constraint once and reference it elsewhere; every restatement is an amendment hazard. The `issue.md` template's Acceptance Criteria preamble gets the same rule in one sentence, since that preamble is the ticket-writing guidance every generated ticket carries.
5. **AC-5 (vault-files carve-out)** — the "Issues are self-contained" paragraph in `skills/sw/references/vault-files.md` gets the carve-out: evidence-consuming issues (audit, validation, consolidation work) may cite sibling-issue paths as plain text; link syntax remains banned. The Bare-filename-rule section, where the link ban lives, gets a one-line reference to the carve-out instead of a restatement.

## File Structure

- Modify: `.agents/skills/sw-brainstorm/SKILL.md` — canonical brainstorm copy; AC-1, AC-2, AC-3, AC-4 edits authored here.
- Modify: `plugins/sw/skills/brainstorm/SKILL.md` — propagated copy, `name: brainstorm` frontmatter (AC-6).
- Modify: `skills/sw/scaffold/skills/sw-brainstorm/SKILL.md` — propagated copy, identical to the `.agents/` one (AC-6).
- Modify: `skills/sw/references/vault-files.md` — AC-5 carve-out.
- Modify: `skills/sw/scaffold/templates/goal.md` — Success Criteria placeholder hint (supports AC-1).
- Modify: `skills/sw/scaffold/templates/issue.md` — state-once rule in the AC preamble (supports AC-4).

No files created or deleted.

## Phase Ordering

1. **Phase 1 — canonical skill edits:** all four brainstorm-skill changes in `.agents/skills/sw-brainstorm/SKILL.md`.
2. **Phase 2 — propagation:** copy to the plugin and scaffold locations, restore the plugin `name:` line, diff-verify AC-6.
3. **Phase 3 — reference and templates:** `vault-files.md` carve-out, `goal.md` and `issue.md` template lines.
4. **Phase 4 — verification:** quality gate (repo test suite) + runtime verification of every AC by grep/diff/validator run.

Phases 1–3 have no interdependencies beyond 2 following 1; ordered for review clarity.

## Constraints

- Three sibling issues run in parallel (`run-skill-contract`, `issue-pipeline-contract`, `install-parity`): do not touch the sw-run/sw-plan/sw-pr skills, the scaffolder install logic, `validate-spec.sh`, or the README. Adjacent problems become candidate learnings, not fixes.
- The `AC-N` in `issue.md` are the approved contract — never reworded.
- The brainstorm skill's three copies must end byte-identical except the frontmatter `name:` line (AC-6).
- The dot process-flow diagram in the skill keeps its scope diamond — it charts the possible paths of the flow; AC-3 governs what the agent *presents to the user*, which is checklist item 6's text.

## User Stories / Scenarios

1. A planner finishes a milestone brainstorm and writes `goal.md`: the skill's goal-writing bullet stops them from naming test files or on-disk formats and shows how to translate that constraint into behavior terms (dossier 3.1).
2. A planner decomposes a milestone into issue tickets: before committing, the skill has them run `validate-spec.sh` on each folder; a check-4 vague-verb hit is fixed at planning time instead of detonating in a future owner's gate (dossier 3.2).
3. A user brainstorms a one-endpoint fix: the agent concludes "single issue" without ever presenting the milestone alternative (dossier 3.3).
4. A planner writes a ticket with a hard constraint: the guidance has them state it once and reference it, so a later rescope is a one-hunk amendment (dossier 3.4).
5. An audit-style issue must cite a sibling issue's evidence file: `vault-files.md` now permits the plain-text path citation while still banning link syntax (dossier 3.5).

## Acceptance Criteria

The acceptance criteria live in the sibling `issue.md` — the `AC-N` IDs defined there are the contract `tasks.md` references and `/sw:review` walks. Do not duplicate them here; if writing this spec exposed a missing or wrong criterion, fix `issue.md`.

## Risks and Mitigations

| Risk | Mitigation |
|---|---|
| Copy drift between the three brainstorm files (AC-6 breaks) | Author in one file, propagate with `cp`, restore `name:` with a single `sed`-style edit, then `diff` all three pairs as a scripted check |
| Template edits introduce a stray double-brace opener that trips check 3 for future tickets | Templates legitimately contain double-brace placeholders; new prose lines are added outside them, and the AC-4/AC-1 hint lines contain no braces |
| Worked example in AC-1 reads as a new rule contradicting existing skill text | Example is derived from the dossier's own observed failure (test-file path in Success Criteria) and placed inside the existing `goal.md` bullet, not as a new section |
| Restating the validator baseline in two skill sections recreates the 3.4 hazard | Full rule stated once (milestone step); single-issue step references it in one sentence |

## Open Questions

None.
