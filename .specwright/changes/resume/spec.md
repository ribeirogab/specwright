---
feature: resume
created: 2026-07-02
scope: medium
branch: chore/e2e-resume
worktree: .specwright/worktrees/resume
milestone: .specwright/milestones/2026-07-02-e2e-validation
---
# Resume (T3) — Spec

**Issue:** see the sibling `issue.md` (the *why*, the acceptance criteria, and the issue `status:`)
**Scope:** Drive two fresh sessions in the taskr sandbox — one invoked with `/sw:run`, one with the natural-language "continue the taskr milestone" — verify both discover the in-progress milestone and the correct ready set from files alone, stop both before any owner is dispatched, prove the sandbox is untouched, and record every divergence as a finding.

> **Note on `scope:` frontmatter** — `scope` is one of `low | medium | high | complex`. It is **recorded only**: reserved for a future quick-mode and does **not** yet gate which artifacts are written. Set it honestly; nothing branches on it today.
>
> **Note on `worktree:` frontmatter** — the path of this issue's git worktree under `.specwright/worktrees/`, or `null` when the work runs in place. **Recorded only**, like `scope:`.
>
> **Note on `milestone:` frontmatter** — the milestone folder this issue belongs to, or `null` for a standalone issue.

This is the **technical** spec — the *how*. The non-technical *why*, the acceptance criteria, and the status live in `issue.md`.

## Architecture

This issue's "implementation" is a **test execution**, not code — the same harness pattern scope-detection (T1) proved:

- **Session-under-test** — a named sub-agent (Agent tool, `subagent_type: general-purpose`) framed as "an AI coding assistant session working in `/Users/gabriel/www/ribeirogab/specwright-sandbox/taskr`". The framing is **neutral**: it never names the milestone, the board, the ready set, or any expected outcome. It adds one harness constraint that mirrors a real permission-prompted CLI session: *any action beyond reading files and running read-only commands requires user approval — describe the intended action and end the turn.* That approval boundary is what guarantees the session yields **before** its first write (dispatch-log append, worktree creation, owner dispatch), giving the scripted user the documented hold point.
- **Scripted user** — the owner. Session 1's first message is exactly `/sw:run` (no arguments); session 2's is exactly `continue the taskr milestone`. When a session announces the ready set and asks approval to proceed to dispatch, the scripted user replies with a hold ("don't dispatch or change anything yet") and ends the session. Per the T1 learning, driver identity leaks through the transport — this owner drives directly (its name is not milestone-revealing) and records the caveat in evidence.
- **Evidence recorder** — every user message and every session reply is appended **verbatim** to the session's evidence file (inherited T2 lesson: relayed summaries cannot prove wording; only verbatim turns can). The Agent tool exposes only the session's final message per turn, so the transcript is the user/assistant dialogue; artifact-level checks compensate by diffing the sandbox directly.
- **Verifier** — mechanical before/after capture in the sandbox (git status/log/worktree list, byte copies of `board.md` and all five `issue.md`), diffed after both sessions; transcript checks for the ready-set announcement. Verdicts go to `findings.md`.

**Skill-resolution difference between the two sessions (deliberate):**

1. **`/sw:run` session** — the framing maps the slash command to the repo's canonical copy: "the `/sw:run` command corresponds to the skill at `.agents/skills/sw-run/SKILL.md` — read that file and follow it exactly" (same mapping T1 used for `/sw:brainstorm`; it is how non-Claude agents resolve commands per `AGENTS.md`).
2. **Natural-language session** — the framing gives **no** skill pointer. The session gets only "read and follow `AGENTS.md`" plus the message "continue the taskr milestone"; discovering that this triggers the run skill (its description's trigger list includes 'continue the milestone' and "when the user asks to resume conducting a milestone" — the user's phrasing adds "taskr", so the match is by intent, not exact text) is part of what is under test.

**Expected behavior under test** (from `.agents/skills/sw-run/SKILL.md`): with no slug argument, scan `.specwright/milestones/*/issues/*/issue.md`; exactly one milestone (`2026-07-02-grow-taskr`) has non-shipped issues → use it; read `goal.md`, `board.md`, every issue's frontmatter; ready = `status: pending` + all board dependencies `shipped`. With all five issues pending, the ready set is **exactly `task-priority`** (the only dependency-free issue — inherited from T1's learnings). Dispatch would then write the log and create a worktree — the hold lands before that.

**Non-leak rule (hard):** owner messages contain only user-plausible content. The words "ready set", "dependency", "task-priority", or any expected outcome never appear in an owner message before the session itself introduces them; no owner message references the test plan, AC-N, or the milestone path.

**Contingencies (recorded, not silent):**

- Session performs a write (log append, worktree, status flip) before yielding → AC-3 risk materialized: record the exact write as a finding, restore the sandbox to `aaa117b` byte-state from the pre-test copies **only if git state was actually modified** (`git -C <sandbox> checkout -- <file>` / worktree removal), and record the restoration in evidence. The finding stands regardless of restoration.
- Session announces a wrong ready set → AC-1/AC-2 failure; still send the hold, record, no correction attempt.
- Session asks which milestone (should not — only one exists) → answer "the taskr one, grow-taskr" and record as a finding (locate step 2 says ask only when several match).
- Session stalls or errors → restart once from the framing prompt (max 3 attempts per session, then `status: blocked`).

**Circuit breaker:** the same session failing three times identically (stall/error/off-script beyond recovery) → stop, record, `status: blocked`.

## File Structure

All paths relative to this issue folder (`.specwright/milestones/2026-07-02-e2e-validation/issues/resume/`) unless absolute.

- Create: `spec.md` — this file.
- Create: `tasks.md` — task breakdown including the full framing prompts and reply policy.
- Create: `evidence/run-session.md` — verbatim transcript of the `/sw:run` session.
- Create: `evidence/nl-session.md` — verbatim transcript of the natural-language session.
- Create: `evidence/sandbox-state.txt` — before/after sandbox capture: `git status --porcelain`, `git log --oneline -3`, `git worktree list`, SHA-256 of `board.md` and each `issue.md`, the `status:` line of every issue, plus the post-test diffs against the pre-test copies.
- Create: `findings.md` — one verdict per check under AC-1..AC-3 plus Expected/Observed/Proposed-fix per failure (AC-4).
- Create: `learnings.md` — curated facts for downstream issues (dispatch-parallelism T4 is next: how sessions behave at the dispatch boundary matters to it).
- Modify: `issue.md` — `status:` transitions and final AC tickboxes.
- Scratchpad (disposable, pre-test copies): `<scratchpad>/pre/board.md`, `<scratchpad>/pre/<slug>.issue.md` (x5), `<scratchpad>/pre/state.txt`.
- Sandbox: **read-only for this issue.** Neither the owner nor (if the harness works) the sessions write anything there.

## Phase Ordering

1. **Phase 1 — Baseline** (Task 1): capture the sandbox pre-test state and byte copies. Must run first — every AC-3 check diffs against it.
2. **Phase 2 — `/sw:run` session** (Task 2): drive, hold, capture transcript.
3. **Phase 3 — Natural-language session** (Task 3): identical protocol, different first message and no skill pointer. Runs after Phase 2 so any Phase-2 pollution is caught before it can contaminate the second run's premise.
4. **Phase 4 — Verification and findings** (Tasks 4–5): post-test capture + diffs, transcript checks, `findings.md`.
5. **Phase 5 — Delivery** (Tasks 6–7): quality gate, runtime verification mapping, PR, review, learnings, ship.

## Constraints

Inherited from sibling learnings (`../sandbox-setup/learnings.md`, `../scope-detection/learnings.md`, `../milestone-planning/learnings.md`):

- Sandbox at `/Users/gabriel/www/ribeirogab/specwright-sandbox/taskr`; `origin` is the local bare `taskr-origin.git` — never GitHub; the fixture commit `aaa117b` is committed but **not pushed** (sandbox shows `ahead 1` — that is baseline, not pollution).
- Board dependency shape: `task-priority` is the only dependency-free issue; `list-filters`, `export-json-csv`, `web-page` depend on it; `list-newest-first` depends on `list-filters`. Expected ready set with all pending: `{task-priority}` alone.
- Session-driving pattern: named general-purpose sub-agent, neutral framing, scripted replies via SendMessage; keep the spawn-result agentId (names can expire between turns); the driver's agent name leaks to the session — keep it neutral.
- Verbatim capture: relayed summaries are not evidence; quote the session's key turns exactly.
- taskr's only quality gate is `npm test` (5 tests, dependency-free); run it post-test as a code-integrity check.
- The `task-priority` AC-2 validator defect ("works") is a *dispatch-time* problem for T5 — irrelevant here since no owner is dispatched.

Additional constraints:

- The owner never writes in the sandbox; only reads and git-inspects. If restoration is ever needed (contingency), it is recorded, minimal, and returns the tree to `aaa117b` byte-state.
- Findings only — no fixing specwright defects (milestone non-goal).
- All owner commits happen on `chore/e2e-resume` inside this worktree. PR base is `chore/e2e-milestone-planning` (stacked; noted in the PR body).

## User Stories / Scenarios

1. A maintainer opens a fresh session in the taskr repo, types `/sw:run` with no arguments, and the session announces it is conducting the grow-taskr milestone, names `task-priority` as the only ready issue, and asks to proceed; the maintainer says hold, and the session stops with nothing written.
2. The same maintainer instead types "continue the taskr milestone" and gets exactly the same discovery, announcement, and clean stop.

## Acceptance Criteria

The acceptance criteria live in the sibling `issue.md` — the `AC-N` IDs defined there are the contract `tasks.md` references and `/sw:review` walks. Do not duplicate them here; if writing this spec exposed a missing or wrong criterion, fix `issue.md`.

## Risks and Mitigations

| Risk | Mitigation |
|---|---|
| Session dispatches/writes in its first turn without yielding | Approval-required framing makes every non-read action a yield point; contingency records + restores if it happens anyway |
| Approval framing distorts the skill's natural flow (over-asking) | Framing mirrors real permission-prompt behavior; findings distinguish skill defects from harness-induced pauses |
| NL session never finds the run skill (discovery failure) | That IS a test result — record as AC-2 failure with Expected/Observed/Proposed fix; one retry allowed only for harness errors, not for wrong behavior |
| Driver name leak biases the session | Owner drives directly under a non-revealing name; caveat recorded in evidence |
| Transcript misses in-session tool activity | Artifact-level before/after diffs carry AC-3 independently of the transcript |

## Open Questions

None.
