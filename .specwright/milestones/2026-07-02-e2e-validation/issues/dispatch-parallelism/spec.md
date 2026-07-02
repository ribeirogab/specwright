---
feature: dispatch-parallelism
created: 2026-07-02
scope: high
branch: chore/e2e-dispatch-parallelism
worktree: .specwright/worktrees/dispatch-parallelism
milestone: .specwright/milestones/2026-07-02-e2e-validation
---
# Dispatch and Parallelism (T4) — Spec

**Issue:** see the sibling `issue.md` (the *why*, the acceptance criteria, and the issue `status:`)
**Scope:** Conduct round 1 of the grow-taskr sandbox milestone for real by driving a fresh `/sw:run` session, audit the orchestration (worktree isolation, orchestrator purity, board logging, stop-before-round-2), run the degradation sub-test (no sub-agent support → serial in-place) on a disposable pre-round clone, and record every divergence as a finding.

> **Note on `scope:` frontmatter** — `scope` is one of `low | medium | high | complex`. It is **recorded only**: reserved for a future quick-mode and does **not** yet gate which artifacts are written. Set it honestly; nothing branches on it today.
>
> **Note on `worktree:` frontmatter** — the path of this issue's git worktree under `.specwright/worktrees/`, or `null` when the work runs in place. **Recorded only**, like `scope:`.
>
> **Note on `milestone:` frontmatter** — the milestone folder this issue belongs to, or `null` for a standalone issue.

This is the **technical** spec — the *how*. The non-technical *why*, the acceptance criteria, and the status live in `issue.md`.

## Architecture

This issue's "implementation" is a **test execution**, not code — the harness pattern T1/T3 proved, extended in two ways: the scripted user now **approves** the dispatch batch instead of holding, and the driven session runs **in the background** so the owner can capture mid-round git state (`git worktree list` while owners live).

**Expectation-vs-fixture divergence (known upfront, inherited from T1 Finding 1):** the ticket's Purpose expects round 1 to dispatch three issues (priorities, trap, web page). The actual board says `task-priority` is the **only** dependency-free issue; the 3-way wave (`list-filters`, `export-json-csv`, `web-page`) opens at round 2, and the trap (`list-newest-first`) only after `list-filters`. Round 1 is therefore a **single dispatch**. This spec audits round 1 **as it is** — it does not reach into round 2 to manufacture parallelism (round 2 belongs to T5), and AC-1's "≥ 2 concurrent owners" is recorded in `findings.md` as an expectation-vs-fixture divergence with the parallelism *mechanics* (own worktree, own branch, sub-agent dispatch, overlapping owner/orchestrator lifetimes) audited at N=1.

Harness components:

- **Session-under-test (real round)** — a named background sub-agent (Agent tool, `subagent_type: general-purpose`, `run_in_background: true`) framed as an AI coding assistant session working in `/Users/gabriel/www/ribeirogab/specwright-sandbox/taskr`. Neutral framing: never names the ready set, slugs, expected outcomes, or the test plan. The framing maps `/sw:run` to the sandbox's canonical skill copy (`.agents/skills/sw-run/SKILL.md` — the `AGENTS.md` resolution non-Claude agents use, same mapping T1/T3 used) and adds the approval constraint that mirrors a real permission-prompted CLI session: *any action beyond reading files and running read-only commands requires user approval — describe the intended action and end the turn.* First message: `/sw:run` (no argument — the no-arg discovery path is T3-validated).
- **Scripted user** — the owner, via `SendMessage` (keep the spawn-result agentId; names can expire between turns). Per the T3 learning, `/sw:run` batches all of round 1's writes (worktree add + owner dispatch + Dispatch Log append) behind **one** approval ask — the scripted user approves that batch and lets the round run to completion. When the session reports round-1 outcomes and yields again (asking to proceed to round 2, or asking anything after logging outcomes), the scripted user says stop and ends the session. If the round's owner returns `blocked` and nothing is ready, the session's own report-and-stop is the stop point.
- **Mid-round probe** — while the background session runs, the owner polls the sandbox from outside: `git -C <sandbox> worktree list`, `git -C <sandbox> branch -a`, and the board's Dispatch Log, timestamped into evidence. This is what makes "worktree existed during the round" (AC-1) and "log line appeared before the outcome" (AC-3) observable independently of the transcript.
- **Evidence recorder** — verbatim turn capture via `jq` on the sub-agent's JSONL transcript (`select(.type=="assistant") | .message.content[] | select(.type=="text") | .text` — the T3 recipe); every scripted-user message recorded verbatim too. Relayed paraphrase is not evidence.
- **Purity auditor** — after the round: (a) transcript scan for any orchestrator file edit outside `.specwright/milestones/2026-07-02-grow-taskr/` (tool-use entries in the JSONL, `.message.content[] | select(.type=="tool_use")`, filtered to Write/Edit/mutating Bash); (b) `git -C <sandbox> status --porcelain` on the main tree; (c) per-branch commit walk — every commit on round-1 issue branches must touch only files an owner legitimately owns and be authored from the owner's worktree (commits land on the issue branch, checked out only in `.specwright/worktrees/<slug>`, never on `main`).
- **Degradation harness (AC-4)** — a second, independent driven session in a **disposable clone** taken from the pre-round sandbox (clone before the real round runs; commit `aaa117b` is on `main`, so a plain `git clone <sandbox> <scratchpad>/taskr-degradation` carries the fixture; verify `.agents/skills/sw-run` and the milestone folder survived the clone). Framing adds one line: *sub-agent support is unavailable in this environment — you cannot spawn agents or delegate to sub-agents.* **Remote isolation (hard):** a plain `git clone` of the working sandbox leaves the clone's `origin` pointing at the **live** sandbox, and the sandbox's sw-pr skill pushes to origin — the degradation round could silently write a branch into the real sandbox after the post-round audit, falsifying the end state `learnings.md` hands to the next issue. Before the degradation session starts: `git -C <clone> remote remove origin`, recorded in the evidence (side effect: the clone's `main` loses its upstream, so `ahead 1` no longer displays — expected, not pollution). Expected per the run skill's degradation clause: serial, in-place conduction — same pipeline and gates, no worktrees. One round, then stop. Evidence kept; clone discarded (`rm -rf` of the scratchpad copy only — never the sandbox).

**Expected behavior under test** (from the sandbox's `.agents/skills/sw-run/SKILL.md`): discover grow-taskr; ready set = `{task-priority}`; one approval batch; create `.specwright/worktrees/task-priority` on branch for the issue; dispatch one owner sub-agent; owner runs the issue pipeline (`/sw:plan` → gates → …). Inherited from T2: `task-priority`'s AC-2 "(short alias works)" trips `validate-spec.sh` check 4 — the owner's mechanical gate fails on a file it must not unilaterally edit. The owner reporting **blocked** (or a reasoned resolution routed through the orchestrator) is **valid fixture behavior**, prime T4/T5 evidence — record what actually happens, never intervene. Either owner outcome (shipped or blocked) completes the round; the board must gain one `dispatched` line and one outcome line, appended without rewriting earlier lines.

**Non-leak rule (hard):** scripted-user messages contain only user-plausible content — never "ready set", slugs before the session names them, AC-N, the test plan, or expected outcomes. The driver identity leaks through SendMessage attribution (T1/T3), so driven sessions are spawned under **neutral names** (`maintainer`, `maintainer-b`) — no issue slugs. Driven sessions replying in pt-BR is operator-config bleed (T3), not a divergence.

**Contingencies (recorded, not silent):**

- Session never yields for approval (auto-writes): the batch was going to be approved anyway — record the missing approval gate as a finding, let the round continue.
- Session dispatches without a worktree, or edits code directly: AC-1/AC-2 failure — record, do not correct, let the round finish.
- Nested sub-agent support turns out unavailable to the driven session in the real round: record as a harness limitation finding; the session's own fallback behavior becomes degradation evidence; AC-1's concurrency check is then unverifiable-in-harness (recorded as such, never faked).
- Session stalls or errors: restart once from the framing prompt (max 3 attempts, then `status: blocked`).
- Round 2 dispatch starts before the stop lands: record as a finding with the exact boundary observed; do not let it run further (stop message immediately).

**Circuit breaker:** the same session failing three times identically → stop, record, `status: blocked`.

## File Structure

All paths relative to this issue folder (`.specwright/milestones/2026-07-02-e2e-validation/issues/dispatch-parallelism/`) unless absolute.

- Create: `spec.md` — this file.
- Create: `tasks.md` — task breakdown with the full framing prompts and reply policy.
- Create: `evidence/round1-session.md` — verbatim transcript (both directions) of the real round's driven session.
- Create: `evidence/round1-sandbox-state.txt` — pre-round capture (git status/log/worktree/branches, board + issue.md hashes and status lines), timestamped mid-round probes, and post-round capture with diffs against pre.
- Create: `evidence/purity-audit.md` — the AC-2 audit: transcript tool-use scan, main-tree `git status`, per-branch commit/file walk.
- Create: `evidence/degradation-session.md` — verbatim transcript of the no-sub-agent session.
- Create: `evidence/degradation-state.txt` — clone before/after capture proving no worktrees and in-place serial execution.
- Create: `findings.md` — verdict per AC-1..AC-4 check plus Expected/Observed/Proposed-fix per divergence (AC-5).
- Create: `learnings.md` — facts T5+ inherit: sandbox end state after round 1, which issue shipped/blocked, branches/worktrees left behind, where the trap stands.
- Modify: `issue.md` — `status:` transitions and final AC tickboxes.
- Scratchpad (disposable): `<scratchpad>/pre/` (pre-round byte copies), `<scratchpad>/taskr-degradation/` (the clone, discarded after evidence capture).
- Sandbox: **the round's writes are the deliverable** — round 1 runs for real and the sandbox is left exactly as round 1 left it (worktree, branch, board lines, owner artifacts), precisely documented for T5. The owner itself writes nothing in the sandbox.

## Phase Ordering

1. **Phase 1 — Baseline + clone** (Task 1): pre-round capture and the degradation clone. Must run first — the clone must predate the real round, and every diff needs the baseline.
2. **Phase 2 — Real round** (Task 2): drive `/sw:run`, approve the batch, probe mid-round, stop after outcomes are logged.
3. **Phase 3 — Audits** (Task 3): purity audit, board append-only diff, post-round state capture.
4. **Phase 4 — Degradation round** (Task 4): the no-sub-agent session in the clone; evidence; discard the clone. After Phase 2/3 so a real-round failure doesn't waste the clone run.
5. **Phase 5 — Findings** (Task 5): `findings.md` verdicts.
6. **Phase 6 — Delivery** (Tasks 6–7): quality gate, runtime verification mapping, learnings, PR, review, ship.

## Constraints

Inherited from sibling learnings (`../sandbox-setup/learnings.md`, `../scope-detection/learnings.md`, `../milestone-planning/learnings.md`, `../resume/learnings.md`):

- Sandbox at `/Users/gabriel/www/ribeirogab/specwright-sandbox/taskr`; `origin` is the local bare `taskr-origin.git` — never GitHub; `gh` PR flows do not apply inside the sandbox (owners deliver on branches; absent `gh`, a pushed branch or an unpushed local branch is the sandbox-realistic outcome — record what the owner does).
- Fixture commit `aaa117b` on `main`, committed but **not pushed** (baseline `ahead 1` is not pollution).
- Board shape: `task-priority` alone in round 1 (see Architecture); T5 owns round 2.
- `validate-spec.sh` on a ticket-only folder fails only with `FAIL (check 2): spec.md not found` — baseline, not defect; and `task-priority` AC-2 trips check 4 ("works") — expect the owner's report/blocked path, never thrashing (T2 learning).
- `/sw:run` batches round-1 writes behind one approval ask; no natural pre-dispatch pause in unattended runs (T3 learning) — the approval framing recreates the gate this harness needs.
- Driver identity leaks via SendMessage; spawn under neutral names; keep agentIds (T1/T3).
- Verbatim capture via `jq` over the sub-agent JSONL (T3); pt-BR replies are operator-config bleed, not divergence (T3).
- Capture the driven session's key announcements verbatim — relayed "it printed a handoff" is unverifiable (T2 learning).
- taskr's only quality gate is `npm test` (`node --test`, 5 tests, dependency-free, `TASKR_FILE` temp — never point one at the repo).

Additional constraints:

- Findings only — no fixing specwright defects, no board edits in the sandbox by the owner (milestone non-goal).
- Owner commits happen only on `chore/e2e-dispatch-parallelism` inside this worktree. PR base is `chore/e2e-resume` (stacked; noted in the PR body).
- The clone lives in the scratchpad, and only the clone is deleted — the sandbox is never restored, reset, or cleaned after the real round.

## User Stories / Scenarios

1. A maintainer types `/sw:run` in a fresh taskr session; it announces grow-taskr, names `task-priority` as ready, asks one approval for worktree + dispatch + log; the maintainer approves; an owner runs the full pipeline in `.specwright/worktrees/task-priority` while the orchestrator only watches and writes the board; the outcome lands in the Dispatch Log; asked to continue to round 2, the maintainer says stop and the session ends cleanly.
2. The same flow in an environment without sub-agents: the session says it will conduct serially in place, runs the same pipeline itself with no worktree, logs the same board lines, and stops when told.

## Acceptance Criteria

The acceptance criteria live in the sibling `issue.md` — the `AC-N` IDs defined there are the contract `tasks.md` references and `/sw:review` walks. Do not duplicate them here; if writing this spec exposed a missing or wrong criterion, fix `issue.md`. (Planning exposed that AC-1's "≥ 2 owners" cannot materialize in round 1 of this fixture — for a milestone issue that is a **report**, not a unilateral edit: it is recorded as a finding and in the PR body, and the dispatch prompt already amended the expectation.)

## Risks and Mitigations

| Risk | Mitigation |
|---|---|
| AC-1 concurrency unobservable (fixture gives a 1-issue round) | Known upfront; audit the mechanics at N=1, record the divergence with a proposed fix (re-scope concurrency observation to round 2 / T5) |
| Driven session cannot spawn nested sub-agents | Contingency recorded as harness-limitation finding; fallback behavior doubles as degradation evidence |
| Owner-under-test thrashes on the task-priority validator defect | Expected report/blocked path is valid fixture behavior (T2 learning); the scripted user never coaches — outcome recorded as-is |
| Session starts round 2 before the stop message lands | Background polling + immediate stop at the outcome-logged yield point; if crossed, record the exact boundary as a finding |
| Clone taken after the round would inherit round-1 pollution | Clone is Phase 1, strictly before the real round |
| Transcript misses in-session tool activity | Purity audit is triangulated: JSONL tool-use scan + main-tree git status + per-branch commit walk |
| Long-running round exhausts patience/attempts | Round runs in background; owner polls; 3-identical-failure circuit breaker, then `status: blocked` |

## Open Questions

None.
