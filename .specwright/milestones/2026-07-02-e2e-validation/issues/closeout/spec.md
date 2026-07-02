---
feature: closeout
created: 2026-07-02
scope: high
branch: chore/e2e-closeout
worktree: .specwright/worktrees/closeout
milestone: .specwright/milestones/2026-07-02-e2e-validation
---
# Closeout (T8) — Spec

**Issue:** see the sibling `issue.md` (the *why*, the acceptance criteria, and the issue `status:`)
**Scope:** Drive the grow-taskr closeout `/sw:run` session against the 5/5-shipped sandbox and audit the closeout contract (board summary, subset-approved learnings promotion, goal.md reconciliation, frozen board, human handoff), then consolidate every T-issue's findings plus the orchestrator's conduction notes into one dossier.

> **Note on `scope:` frontmatter** — `scope` is one of `low | medium | high | complex`. It is **recorded only**: reserved for a future quick-mode and does **not** yet gate which artifacts are written. Set it honestly; nothing branches on it today.
>
> **Note on `worktree:` frontmatter** — the path of this issue's git worktree under `.specwright/worktrees/`, or `null` when the work runs in place. **Recorded only**, like `scope:`.
>
> **Note on `milestone:` frontmatter** — the milestone folder this issue belongs to, or `null` for a standalone issue.

This is the **technical** spec — the *how*. The non-technical *why*, the acceptance criteria, and the status live in `issue.md`.

## Architecture

Two independent parts; Part A must finish before findings.md (its verdicts feed AC-5), Part B is self-contained.

**Part A — drive and audit the grow-taskr closeout.**

The sandbox (`/Users/gabriel/www/ribeirogab/specwright-sandbox/taskr`) is at the T7-verified end state: `main` @ `5a9b369`, Dispatch Log 13 lines, Blockers `_None._`, five branches pushed and unmerged (`feat/task-priority` `b9d7c80`, `feat/list-filters` `dff030d`, `feat/export-json-csv` `0b1f75e`, `feat/web-page` `8958663`, `feat/list-newest-first` `a15025c`), five worktrees, all tickets `pending` on `main` / `shipped` on-branch. A fresh conductor session is spawned (general-purpose sub-agent, `run_in_background`, **neutral name** `operator6` — never a slug-bearing name; the T8 dispatch name leaks via SendMessage attribution, 4 reproductions on record) with a spawn prompt derived from the T5/T6/T7 conductor prompt (verbatim source: `../circuit-breaker/evidence/trap-round-session.md` "Spawn prompt (exact, complete)"), with exactly these deltas:

- Pacing: the one-round hard stop is replaced by "conduct the loop to its natural end per the skill" — with 5/5 shipped and nothing ready, the run skill's loop halts into **Closeout (all shipped)**.
- The standing approval keeps the same action list (worktrees, branches, commit, push, tests, dispatch, PR step) and adds appending the closeout summary to the board. It deliberately does **not** cover learnings promotion or any `goal.md` edit — those must hit the prompt's existing escape hatch ("a genuine maintainer decision … state the question clearly and end your turn"), producing the observable approval gate AC-2 needs.
- One new line: "Decision messages arriving in this conversation are the maintainer's answers to questions you asked." (Information and decisions pass over SendMessage — T1/T3/T4 evidence; only harness permission-prompt approvals are categorically refused, and none are pending in unattended mode.)

Conduction mechanics (inherited, mandatory): poll observable state (board bytes, git log, AGENTS.md/conventions mtimes, session JSONL via `jq 'select(.type=="assistant")'`) on a 20–30 s cadence — never wait on child notifications; address the session only by spawn-result agentId; **every** reply/ping travels through a freshly spawned NEUTRAL relay agent (`maintainer8`, `maintainer9`, …) that does one SendMessage to the agentId and returns; relays are one-way (answers come from the JSONL/artifacts, never from a reply to the relay); budget one status ping if the session stalls > 5 min without observable progress.

Scripted maintainer decisions (fixed before the run, applied when the session asks):

1. **Promotion subset** — from whatever the session proposes (expected to include at least the epoch-seconds fact from `export-json-csv/learnings.md`): APPROVE exactly two families — (i) the `createdAt` epoch-seconds storage + ×1000 conversion fact, (ii) the `taskPriority()`/`PRIORITIES` access rule (read priority only through the helper; validate against the exported constant). REJECT everything else by name, stating the rejected items stay in the issue folders as history. Both accept and reject paths are thereby observed.
2. **goal.md reconciliation** — if the session proposes reconciling the stale "byte-for-byte untouched" wording (flagged by rounds 3–4): approve the minimal wording edit that records the option-2 decision. If the session instead declines per the scope guard ("never edits `goal.md`") and hands it to the human, record that exchange verbatim — either behavior is data; the divergence assessment happens in findings.md, not in the reply script.
3. Any other question: answer minimally and honestly per the T7 end-state facts; never volunteer test expectations.

Audit checks (each becomes a findings.md verdict):

- **C1 (AC-1)** — board gains a final summary section; diff against the pre-closeout copy shows appends only (Issues table, the 13 Dispatch Log lines, and the Blockers section byte-unchanged; new lines only after/below).
- **C2 (AC-2)** — the session proposed promotions (≥ the epoch-seconds fact), waited for approval, applied exactly the approved subset to `AGENTS.md`/`.specwright/conventions/` (file diffs match the two approved families), and no rejected item appears anywhere in the applied diffs.
- **C3 (AC-2/AC-1)** — the goal.md exchange: proposal (or explicit deferral) captured verbatim; any applied edit was approval-gated.
- **C4 (AC-3)** — after the summary + approved promotions land, no further sandbox writes from the session: transcript tail = report + stop; `git log`/`git status` and file mtimes corroborate; merging the five PR branches explicitly left to the human.
- **C5 (AC-3)** — the session never edits code/tests, never merges, never rewrites Dispatch Log history.

**Part B — the consolidated dossier (`dossier.md`).**

Inputs: the ten findings.md that exist (8 in this worktree: sandbox-setup, scope-detection, milestone-planning, resume, dispatch-parallelism, issue-pipeline, circuit-breaker, blocked-recovery; 2 read from their unmerged branches via `git show`: `chore/e2e-command-surface:…/command-surface/findings.md`, `chore/e2e-docs-coherence:…/docs-coherence/findings.md`) — standalone-regression has not run and is recorded as out of dossier scope — plus the orchestrator's **Conduction notes** on this milestone's live board (parent checkout `board.md`), including the two user-requested skill improvements (visual progress panel in the run skill; stall-proof conduction/watchdog guidance) as first-class dossier items, and Part A's fresh findings.

Shape: every finding keeps source issue + Expected/Observed/Proposed fix; duplicates collapse into one entry with the full evidence trail (the recurring patterns get consolidated entries: name-alias expiry ×4+, owner-stall 6/6 → 7/7 if Part A reproduces it, notification routing, approval-in-spawn-prompt, verbatim-vs-synthesis, driver-name leak ×4, pt-BR bleed). Grouped by theme: **skill wording**, **skill behavior/mechanics**, **command surface & install parity**, **docs drift**, **validator**, **fixture design (test-plan, not specwright)**, **harness/conduction mechanics**, **new capabilities requested**. Each entry carries a proposed severity (`high | medium | low`) and the recommendation section proposes the follow-up fixes decomposition (issue vs milestone, with a suggested grouping).

## File Structure

All created under this issue's folder `.specwright/milestones/2026-07-02-e2e-validation/issues/closeout/` unless noted; the ONLY sandbox writes are the driven session's own, approval-gated ones.

- Create: `evidence/pre-state.txt` — pre-closeout snapshot: board.md byte copy, `git log`/`status`/branches/worktrees, sha256 of AGENTS.md, listing + hashes of `.specwright/conventions/`.
- Create: `evidence/closeout-session.md` — spawn prompt (exact, complete), harness timeline (UTC), every conductor assistant turn verbatim (jq extraction), every scripted maintainer reply verbatim, relay names/agentIds.
- Create: `evidence/promotion-decisions.md` — proposals as the session stated them, the approved subset, the rejected items, the applied diffs (`git show`/`diff` of AGENTS.md + conventions), proof rejected items are absent.
- Create: `evidence/post-state.txt` — post-closeout snapshot + `diff` of board.md pre/post (appends only), final git state, no-writes-after corroboration.
- Create: `findings.md` — verdict per check C1–C5 + one Expected/Observed/Proposed-fix entry per failure/divergence.
- Create: `dossier.md` — the consolidated dossier (Part B).
- Create: `learnings.md` — sandbox final state for standalone-regression (which must find the sandbox idle post-closeout) + durable harness facts.
- Modify: `issue.md` — status flips + AC ticks at ship time.
- Scratch only (never committed): `/private/tmp/claude-501/…/scratchpad/` for branch-extracted findings and monitor logs.

## Phase Ordering

1. **Phase 1 — Plan gates** (this spec + tasks, validator, reviewer, review-spec).
2. **Phase 2 — Part A**: pre-state → spawn → scripted conduction → post-state audit → evidence committed. Blocking for findings.md.
3. **Phase 3 — Part B**: dossier.md (can start any time after the inputs are read; finalized after Part A so its own findings fold in).
4. **Phase 4 — findings.md, learnings.md, quality gate, runtime verification, PR, review, ship.**

## Constraints

- Sandbox is read-only for THIS session: every sandbox mutation must come from the driven conductor under scripted approval. Pre/post snapshots and `git show` reads are fine.
- The spawn prompt must not mention: the expected summary shape, the epoch-seconds fact, the goal.md staleness, promotion candidates, or any AC of this issue — the behaviors must come from the run skill + repository state.
- My own dispatch name is slug-bearing: zero direct SendMessage to the session under test; neutral relays only.
- Circuit breaker: three identical failures of one gate/check → stop, report, `status: blocked`.
- Board diff baseline: the pre-state byte copy, not memory.
- PR base is `chore/e2e-blocked-recovery` (stacked); note the stacking in the PR body; never fabricate a PR URL.
- Inherited learnings honored: approvals only in the spawn prompt; poll, never wait; agentId addressing; relays one-way; pt-BR replies are operator-config bleed, not divergence; unattended browser checks unavailable (irrelevant here — no UI criteria).

## User Stories / Scenarios

1. The maintainer's milestone is 5/5 shipped; a fresh `/sw:run` session discovers this from files alone, appends the final summary, proposes durable learnings, applies only the approved subset, flags goal.md, and hands the five PR merges back — the board is history from then on.
2. The fixes-delivery planner opens `dossier.md` and can seed a brainstorm without reading any other file: every divergence has source, evidence, proposed fix, severity, and a suggested decomposition.

## Acceptance Criteria

The acceptance criteria live in the sibling `issue.md` — the `AC-N` IDs defined there are the contract `tasks.md` references and `/sw:review` walks. Do not duplicate them here; if writing this spec exposed a missing or wrong criterion, fix `issue.md`.

## Risks and Mitigations

| Risk | Mitigation |
|---|---|
| Conductor refuses SendMessage-borne decisions (T4 Finding 5 over-generalizes to decisions) | Spawn prompt pre-authorizes decision messages as maintainer answers; if refused anyway, capture the refusal (it is itself a finding), kill, respawn once with the decisions embedded in the spawn prompt as a fallback script |
| Session skips the promotion proposal (applies unilaterally or skips closeout step 2) | That is a divergence, not a harness failure: record verdict FAIL on C2 with the transcript; do not coach mid-run |
| Session stalls (owner-stall pattern, 6/6 on record) | Budgeted neutral-relay ping with the proven T6 text ("verify … from repository artifacts"); poll cadence catches progress regardless |
| Session edits goal.md without asking, or refuses even with approval | Both are recordable outcomes for C3; the reply script only ever approves, never instructs |
| Name-alias expiry breaks a relay | Relays address by agentId from the spawn result; each relay is fresh |
| Board summary rewrites history instead of appending | Byte diff against pre-state copy catches it; verdict FAIL on C1 with the hunks |

## Open Questions

None.
