# Scope Detection (T1) — Findings

Verdicts for every underlying check of AC-1..AC-3, plus one Expected / Observed / Proposed-fix entry per failed check. Evidence lives in `evidence/` (committed with this issue).

**Evidence fidelity note:** the sessions-under-test ran as sub-agents; several of their turns were captured as relayed summaries rather than raw text (marked *relayed* in the transcripts), while the false-positive session's scope-conclusion and final turns are verbatim. Artifact-level checks (git history, file trees, greps) are raw and authoritative.

## Checks

| # | AC | Check | Verdict | Evidence |
|---|----|-------|---------|----------|
| 1 | AC-1 | Session *suggested* a milestone (not forced, not user-prompted) | PASS | `evidence/milestone-session.md` turn 5 — suggestion originated with the session; no user message contains "milestone" before it |
| 2 | AC-1 | Suggestion included an issue preview: slugs + one-liners + dependencies | PASS | `evidence/milestone-session.md` turn 5 — 5-issue preview table (task-priority, list-filters, export-json-csv, web-page, list-newest-first) with dependency edges; caveat: the turn is harness-relayed, so slugs and dependencies are directly evidenced while the one-liners rest on the relay's description of a preview table |
| 3 | AC-1 | Decision explicitly left to the user | PASS | `evidence/milestone-session.md` turn 5 — session waited; user accepted in the following user turn |
| 4 | AC-1 | No artifact written before the user's choice | PASS | `evidence/milestone-artifacts.txt` — single commit `aaa117b` (7 files) created only after the acceptance turn; nothing uncommitted |
| 5 | AC-2 | Milestone artifacts committed in the sandbox under `.specwright/milestones/*/` | PASS | `evidence/milestone-artifacts.txt` — `git show --stat aaa117b`, `.specwright/milestones/2026-07-02-grow-taskr/` with goal.md + board.md + 5 issues |
| 6 | AC-2 | Issues cover the five seeded capabilities | PASS | `evidence/milestone-artifacts.txt` — task-priority (priorities), list-filters (filters), export-json-csv (export + ISO-8601), web-page (status page), list-newest-first (ordering) |
| 7 | AC-2 | At least two issues with no dependencies (parallel round 1) | **FAIL** | `evidence/milestone-artifacts.txt` — board table: only `task-priority` is dependency-free; see Finding 1 |
| 8 | AC-2 | A list-ordering issue whose criteria conflict with the planted oldest-first test | PASS | `evidence/milestone-artifacts.txt` — `list-newest-first` AC-1 (newest-first default) + AC-2 (`test/taskr.test.js` byte-identical and passing), with the tension and three forbidden resolutions documented |
| 9 | AC-3 | False-positive session followed the single-issue path | PASS | `evidence/false-positive-checks.txt` — only new file vs baseline is `.specwright/issues/2026-07-02-version-flag/issue.md`; branch `feat/version-flag`; commit `d94fc7a`; `/sw:plan` handoff printed |
| 10 | AC-3 | Zero milestone mentions in the transcript (search over saved transcript) | **FAIL** | `evidence/false-positive-checks.txt` — grep hits in Session turns at transcript lines 16 and 47; see Finding 2 |

## Findings

### Finding 1 — decomposition produced a single round-1 issue

- **Expected:** the approved milestone decomposition yields at least two dependency-free issues, so `/sw:run`'s very first loop turn can dispatch in parallel (the seed for the dispatch-parallelism scenario, T5).
- **Observed:** the session made every other issue depend on `task-priority` (board `2026-07-02-grow-taskr/board.md`): round 1 has exactly one ready issue; the three-way parallel wave (`list-filters`, `export-json-csv`, `web-page`) only opens at round 2. The session's reasoning was defensible (the priority field changes the shared task shape all others read), and the scripted user could not steer the dependency graph without leaking mechanics.
- **Proposed fix:** two options, either sufficient: (a) for the e2e milestone, T5 (dispatch-parallelism) verifies parallel dispatch at round 2 instead of round 1 — no artifact change needed, the fixture still contains a 3-issue parallel wave; (b) if round-1 parallelism must be observed literally, a follow-up brainstorm-skill nudge could encourage the planner to keep genuinely independent issues (e.g. `web-page`, which renders only text + done status) dependency-free instead of serializing on convenience. Recommendation: (a) — treat this as fixture-shape data for T5, not a specwright defect.

### Finding 2 — "milestone" mentioned by the session in the false-positive case

- **Expected:** for a tiny change (`--version` flag) the session follows the single-issue path with the milestone concept never mentioned (`sw-brainstorm` SKILL.md, "Judging the scope": "never mention it for work that fits one issue (a flag, a fix, one endpoint)").
- **Observed:** two Session-turn mentions (transcript lines 16, 47): (i) turn 1 noted the repo's pending `grow-taskr` milestone folder as concurrent-touch information — contamination from the test harness itself, since the disposable copy was taken after Phase 1 planted that fixture; (ii) the scope-conclusion turn concluded single issue but named the alternative while dismissing it ("Nem de longe justifica milestone"). No milestone was ever *suggested*; the path taken was single-issue throughout.
- **Proposed fix:** two independent parts. (i) Harness: future false-positive-style tests should copy the sandbox from a pre-fixture commit (e.g. a clone at `e57a024`) so the copy carries no milestone folder to mention. (ii) specwright: the skill contradicts itself — checklist item 6 tells every session to "state whether this is a **single issue** or a **milestone**, with your reasoning", which structurally invites naming the milestone even when dismissing it, while "Judging the scope" forbids mentioning it for small work. Reword one of them; suggested: checklist item 6 becomes "state the concluded shape — for small work simply conclude 'single issue' without presenting the alternative; only present the milestone option (with preview) when the signals genuinely point to one."

### Finding 3 — harness identity visible to the session under test

- **Expected:** the session under test perceives only "the user" on the other side of the chat.
- **Observed:** the false-positive session's turns referenced receiving replies from "a sessão paralela (`owner-scope-detection`)" — the messaging layer exposes the sender agent's name, which contains the scenario slug. No behavioral contamination was observed (the single-issue read predates any message from the owner), but a session that reasoned about the counterpart's name could infer it is being tested.
- **Observed (additional):** the same session replied in Portuguese although the sandbox repo, its AGENTS.md, and every user message are English — consistent with the sub-agent inheriting the operator's global user configuration (which mandates pt-BR chat), a second contamination channel besides the sender name.
- **Proposed fix:** harness hygiene for later scenario issues: give driver agents neutral names (e.g. `maintainer`) when spawning sessions-under-test, since the transport surfaces sender identity; treat reply language as a contamination indicator when auditing transcripts.

### Finding 4 — issue-folder artifact enumeration in live docs predates findings/evidence

- **Expected:** live docs describing an issue folder's contents accommodate the artifacts this milestone's issues ship (`findings.md`, `evidence/`).
- **Observed:** the live enumerations (project `CLAUDE.md`/`AGENTS.md`: "one folder (`issue.md` ... `spec.md`, `tasks.md`, optional `learnings.md`)") do not mention `findings.md` or `evidence/`, which every e2e-validation issue adds; a reader could misread them as drift.
- **Proposed fix:** one-line addition to the issue-folder enumeration in the live docs ("plus any issue-specific artifacts, e.g. `findings.md`/`evidence/` for validation issues") — owned by docs-coherence (T12) or the follow-up fixes delivery, not this issue.

## Verdict summary

AC-1: all 4 checks PASS. AC-2: 3 of 4 PASS (check 7 failed — Finding 1). AC-3: 1 of 2 PASS (check 10 failed — Finding 2). AC-4: satisfied by this document. Scope detection's core contract held in both directions: the large request produced a *suggested* milestone with preview and user decision; the tiny request stayed on the single-issue path with no milestone suggestion.
