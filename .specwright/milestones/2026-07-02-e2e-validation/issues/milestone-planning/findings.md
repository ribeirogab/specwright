# Milestone Planning (T2) — Findings

Audit of the grow-taskr planning artifacts against the planning contract.

- **Fixture:** `/Users/gabriel/www/ribeirogab/specwright-sandbox/taskr/.specwright/milestones/2026-07-02-grow-taskr/` at sandbox commit `aaa117b` (verified before the audit: `git log -1` + clean `git status`; the fixture is exactly what the scope-detection brainstorm left behind).
- **Transcript evidence:** `../scope-detection/evidence/milestone-session.md` + `milestone-artifacts.txt`. Per that file's own recording convention (line 5), user messages are verbatim; session turns are **relayed summaries**. Every transcript-based verdict below carries an evidence tier: `verbatim` (quoted session text), `relay` (faithful summary — supports "consistent with the contract", never verbatim proof), or `physical` (state observable in the sandbox itself, independent of the transcript).
- **Validator baseline:** `validate-spec.sh` check 2 hard-fails when `spec.md` is absent, and check 5 needs `tasks.md`. Planning-stage tickets legitimately have neither (they are written just-in-time by `/sw:plan`), so the expected outcome per fixture folder is exit 1 with exactly one `FAIL (check 2): spec.md not found` line. That line is the planning-stage baseline, **not a defect**; any additional FAIL line is a real divergence. Raw runs: `evidence/validate-spec-runs.txt`.
- The sandbox is read-only for this audit — findings only, nothing fixed. Proposed fixes target the upstream skill/template that produced the artifact, never the fixture.

Verdict summary: 2 checks FAIL (goal.md technical content; task-priority vague-verb), 1 sub-check inconclusive on an evidence gap (handoff naming the milestone path), everything else PASS.

## 1. goal.md (AC-1)

**Section inventory — PASS.** Purpose (l.9), Motivation (l.13), Success Criteria (l.17), Non-Goals (l.23) all present with real content (`evidence/fixture-checks.txt`, sections block).

**Zero technical content — FAIL.** Sweep hits judged one by one (`evidence/fixture-checks.txt`):

- l.11, l.15, l.19 (`add`/`list`/`done`, `taskr list`, JSON/CSV, ISO-8601, "only Node and the taskr CLI"): **acceptable** — user-facing CLI surface and export formats the maintainer asked for verbatim; product scope, not implementation.
- l.7 blockquote (`board.md`, `issue.md`): **acceptable** — scaffold template prose, not milestone content.
- l.20, l.21, l.25, l.26: **divergences** — file paths and storage formats, explicitly banned by the contract.

### Divergence 1.1 — file paths in Success Criteria

- **Expected:** milestone-level success criteria with no file paths (contract: "no file paths, function names, storage formats, or other technical content").
- **Observed:** `goal.md` l.20 — "`npm test` is green on every issue's PR with the pre-existing `test/taskr.test.js` byte-for-byte untouched"; l.21 — "`package.json` still declares zero runtime dependencies". Two file paths and a tooling command in the Success Criteria section. (Turn 6 of the transcript relays this was deliberate: goal.md success criteria "including the frozen-test hard constraint + zero dependencies".)
- **Proposed fix:** in the brainstorm skill's milestone-writing step, require goal.md success criteria to be phrased in behavior terms — e.g. "the pre-existing test suite passes unchanged on every issue's PR" and "the tool remains free of runtime dependencies" — and relocate path-level constraints (`test/taskr.test.js` untouched, `package.json` dependency-free) to each issue's Non-Goals/ACs, where they already live in this fixture. The skill text should give one worked example of translating a technical hard constraint into a goal-level phrasing.

### Divergence 1.2 — storage format in Non-Goals

- **Expected:** goal.md Non-Goals free of storage formats and field names.
- **Observed:** l.25 — "Touching `test/taskr.test.js` in any way"; l.26 — "the store file format (`createdAt` stays epoch seconds; tasks without `priority` stay valid and are read as `medium`)". A file path, a field name, and its on-disk representation.
- **Proposed fix:** same upstream change as 1.1 — goal-level non-goals in behavior terms ("no migration of existing stored tasks; older tasks keep working"), with the `createdAt`/epoch-seconds detail left to the issue tickets (task-priority and export-json-csv already carry it).

## 2. board.md (AC-2)

**PASS on all four sub-checks** (`evidence/fixture-checks.txt`, board block):

- Issues table (l.13–19) carries order + dependencies; columns are `Order | Issue | Depends on` — **no status column**.
- Status-word sweep hits (l.7, l.11, l.23, l.27) are all meta-prose: where `status:` lives (issue.md), the readiness definition, and the Dispatch Log line format. No per-issue status text anywhere.
- Dispatch Log (l.21) and Blockers (l.25) present and **empty** (only the template's descriptive prose; the entry-extraction check returned "no entries" for both).
- Dependencies match the shape recorded in the scope-detection learnings: `task-priority` sole root; `list-filters`, `export-json-csv`, `web-page` each depend only on `task-priority`; `list-newest-first` depends on `list-filters`.

## 3. Issue tickets (AC-3)

Mechanical evidence: `evidence/validate-spec-runs.txt`. All five folders: `issue.md` exists; frontmatter `status: pending` (plus `feature`/`created`/`shipped: null`); slugs plain kebab, no number prefixes; AC-N numbered sequentially from AC-1 with no gaps; no double-brace placeholder survivors. Validator: four folders exit 1 with only the check-2 baseline line — PASS under the baseline interpretation. ACs are binary and observable throughout (exact commands, exact outputs, exact store contents).

**One divergence:** `task-priority` exits 2 — check 4 fires beyond the baseline.

### Divergence 3.1 — banned vague-verb word in task-priority AC-2

- **Expected:** every ticket passes the mechanical checks that apply at planning stage (contract: "`validate-spec.sh` accepts each issue folder's ticket or names the defect"); the ticket template itself bans vague verbs in ACs.
- **Observed:** validator output `FAIL (check 4): vague verb in acceptance criterion` on task-priority AC-2: "taskr add -p low water plants stores the task with priority low **(short alias works)**". The criterion is substantively binary and observable — the trip is the word "works" in the parenthetical gloss — but the check is a word-list check, and the defect is operational: when this issue's owner runs `/sw:plan`, their mechanical gate will fail check 4 on a file they must not unilaterally edit (AC changes are scope changes), forcing a report-and-wait loop the planning session could have avoided.
- **Proposed fix:** the brainstorm skill's milestone-decomposition step should run `validate-spec.sh` on each issue folder it writes and fix wording trips before committing (the check-2 baseline is expected and ignorable at that stage; anything else is the planner's to fix). Cheapest immediate wording: "(short alias `-p` accepted)".

**Advisory observation (outside the audited contract):** `export-json-csv` (Purpose: "Formatting lives in a pure module (`lib/export.js`)") and `web-page` (Purpose: "The HTTP handler lives in `lib/server.js` ... `bin/taskr.js` only wires it") pin implementation structure inside the ticket, which the ticket header itself assigns to the just-in-time `spec.md`. AC-3's contract doesn't audit ticket technicality, so no verdict — recorded for the milestone closeout to weigh.

## 4. Scope-detection transcript (AC-4)

Evidence tiers per the header note. Source: `../scope-detection/evidence/milestone-session.md` (turns cited), `milestone-artifacts.txt`, and the sandbox itself.

- **Post-design batch asked exactly one thing (worktrees) — PASS (relay).** Turn 5: "asked ONLY the worktree question (issue owners in worktrees, default yes) as the post-design batch". The verbatim user reply (l.72, "Agreed — go with the milestone. And yes to worktrees, use the default.") answers exactly two things: the scope suggestion (left as a decision, not a batch question) and the worktree question — consistent with a single-question batch. No verbatim session text; relay-consistent, not verbatim-proven.
- **Handoff names `/sw:run` as the resume command — PASS (relay).** Turn 6: "Printed the handoff — resume in a fresh session with `/sw:run grow-taskr` — and explicitly stopped." Matches the learnings' recorded resume command.
- **Handoff names the milestone path — INCONCLUSIVE (evidence gap).** Turn 6 names the milestone folder (`.specwright/milestones/2026-07-02-grow-taskr/`) when describing the artifacts written, but never states the printed handoff text itself contained the path. A relay gap is not a violation: no divergence is charged to the planning session.
  - **Expected (of the evidence, not the fixture):** the saved transcript lets an auditor confirm each handoff element verbatim.
  - **Observed:** all session turns relayed; the handoff's exact text was not captured.
  - **Proposed fix:** session-driving issues in this milestone should capture the final handoff verbatim (ask the driven session to print it as its last message and copy the raw text into evidence, or have the driver quote it) — an evidence-capture convention for the e2e harness, worth a line in the milestone's learnings.
- **No conduction after the handoff — PASS (relay + physical).** Relay: turn 6 ends with "explicitly stopped: the planning session never conducts", followed by "(session ended)"; no dispatch language, sub-agent spawns, or code edits in the tail. Physical corroboration, independent of the relay: the sandbox history is exactly `e57a024` (bootstrap) → `aaa117b` (7 planning files, 260 insertions, nothing else); `git status` clean; `npm test` still 5/5 after the session (`milestone-artifacts.txt`); no `.specwright/worktrees/` entries exist in the sandbox. A conducting session would have left implementation commits, worktrees, or dirty state — none present.

## 5. Deliverable completeness (AC-5)

Every contract check above carries a recorded verdict; each of the three divergences (1.1, 1.2, 3.1) carries Expected / Observed / Proposed fix; the one inconclusive sub-check (4, milestone-path) is recorded as an evidence gap with the same structure pointed at the harness. Raw evidence: `evidence/validate-spec-runs.txt`, `evidence/fixture-checks.txt`.
