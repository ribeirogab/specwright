---
feature: scope-detection
created: 2026-07-02
scope: medium
branch: chore/e2e-scope-detection
worktree: .specwright/worktrees/scope-detection
milestone: .specwright/milestones/2026-07-02-e2e-validation
---
# Scope Detection (T1) — Spec

**Issue:** see the sibling `issue.md` (the *why*, the acceptance criteria, and the issue `status:`)
**Scope:** Drive two `/sw:brainstorm` sessions against the taskr sandbox (one that must conclude a milestone, one that must not), capture transcript evidence, verify the scope-detection contract, and record every divergence as a finding.

> **Note on `scope:` frontmatter** — `scope` is one of `low | medium | high | complex`. It is **recorded only**: reserved for a future quick-mode and does **not** yet gate which artifacts are written. Set it honestly; nothing branches on it today.
>
> **Note on `worktree:` frontmatter** — the path of this issue's git worktree under `.specwright/worktrees/`, or `null` when the work runs in place. **Recorded only**, like `scope:`.
>
> **Note on `milestone:` frontmatter** — the milestone folder this issue belongs to, or `null` for a standalone issue.

This is the **technical** spec — the *how*. The non-technical *why*, the acceptance criteria, and the status live in `issue.md`.

## Architecture

This issue's "implementation" is a **test execution**, not code. The owner acts as a test harness:

- **Session-under-test** — a named sub-agent (Agent tool, `subagent_type: general-purpose`, tools `*`) framed as "an AI coding assistant session working in `/Users/gabriel/www/ribeirogab/specwright-sandbox/taskr`". The framing prompt tells it to read the repo's `AGENTS.md` and to treat the user's first message as `/sw:brainstorm <request>`, following `.agents/skills/sw-brainstorm/SKILL.md`. The framing is **neutral**: it never names expected outcomes (no "milestone", no "single issue", no AC text).
- **Scripted user** — the owner. Each sub-agent turn ends when the session asks the user something; the owner replies via `SendMessage` following the reply policy tables below (requirements steering only — never mechanics, never scope words before the session uses them).
- **Evidence recorder** — after every exchange, the owner appends the user message and the session's visible reply verbatim to the evidence file. The Agent tool only exposes the session's final message per turn, so the transcript is the user/assistant dialogue (tool activity inside the session is not visible); artifact-level checks compensate by inspecting the sandbox git history and files directly.
- **Verifier** — after each session, mechanical checks (grep over transcripts, `git log`/file inspection in the sandbox, `npm test` in the sandbox) produce the AC verdicts, written to `findings.md`.

Chosen over running a real interactive CLI session (no way to script a human), and over a single "simulate both sides" agent (would leak expectations and prove nothing).

**Two cases:**

1. **Milestone case** — runs in the real sandbox `/Users/gabriel/www/ribeirogab/specwright-sandbox/taskr`. Its output (`.specwright/milestones/*/` committed in the sandbox) is the durable fixture for `milestone-planning` (T2) and every run-loop issue — it is **left in place**.
2. **False-positive case** — runs in a disposable copy of the sandbox under the session scratchpad (`<scratchpad>/taskr-fp`), with `origin` repointed to a scratch bare clone so nothing can pollute the shared `taskr-origin.git`. The copy is abandoned in the scratchpad after evidence is extracted (the scratchpad is session-temporary; no `rm -rf` needed).

**Non-leak rule (hard):** every message the owner sends to a session contains only user-plausible content — requirements, answers to the session's questions, approvals. The words "milestone", "single issue", "scope" never appear in an owner message before the session itself introduces them, and no owner message ever references the test plan, AC-N, or expected behavior.

**Contingency (recorded, not silent):** if the milestone-case session concludes a single issue instead of suggesting a milestone, that is an AC-1 failure recorded in `findings.md`; the owner may then send one user-plausible nudge ("that feels like too much for one PR — can it be broken up?") solely to produce the fixture the downstream issues need, and the nudge itself is recorded in the finding. If the session still produces no milestone artifacts after the nudge, the fixture cannot be produced → `status: blocked` report (downstream depends on it).

**Circuit breaker:** a session that stalls (no reply), errors, or goes off-script beyond recovery three times identically → stop, record, `status: blocked`.

## File Structure

All paths relative to this issue folder (`.specwright/milestones/2026-07-02-e2e-validation/issues/scope-detection/`) unless absolute.

- Create: `spec.md` — this file.
- Create: `tasks.md` — the task breakdown, including the full reply-policy script.
- Create: `evidence/milestone-session.md` — verbatim transcript of the milestone-case session (every user message + session reply, in order).
- Create: `evidence/milestone-artifacts.txt` — captured `git log` + `git show --stat` + file listing of the milestone artifacts committed in the sandbox.
- Create: `evidence/false-positive-session.md` — verbatim transcript of the false-positive session.
- Create: `evidence/false-positive-checks.txt` — grep output proving zero milestone mentions + listing of the artifacts the fp session wrote in the disposable copy.
- Create: `findings.md` — one verdict (pass/fail + evidence pointer) per check under AC-1..AC-3, plus Expected/Observed/Proposed-fix entries for failures (AC-4).
- Create: `learnings.md` — curated facts for downstream issues (at minimum: where the sandbox milestone fixture lives and what it contains).
- Modify: `issue.md` — `status:` transitions and final AC tickboxes.
- Sandbox (written by the session-under-test, not by the owner): `/Users/gabriel/www/ribeirogab/specwright-sandbox/taskr/.specwright/milestones/<date>-<slug>/` — the fixture; left exactly as the session commits it.
- Scratchpad (disposable): `<scratchpad>/taskr-fp/` (copy of the sandbox), `<scratchpad>/taskr-fp-origin.git` (scratch bare clone as the copy's `origin`).

## Phase Ordering

1. **Phase 1 — Milestone case** (Tasks 1–3): drive the session, capture evidence, verify AC-1/AC-2. Must run first: its artifacts are the milestone fixture and the false-positive case must not run in the sandbox anyway.
2. **Phase 2 — False-positive case** (Tasks 4–5): disposable copy, drive the session, verify AC-3. Independent of Phase 1's outcome but ordered after it to keep the sandbox untouched by fp debris.
3. **Phase 3 — Findings and delivery** (Tasks 6–8): `findings.md` (AC-4), quality gate + runtime verification, PR/review/learnings/ship.

## Constraints

Inherited from `../sandbox-setup/learnings.md` (facts paid for by the previous issue):

- The sandbox lives at `/Users/gabriel/www/ribeirogab/specwright-sandbox/taskr`; its `origin` is the local bare repo `/Users/gabriel/www/ribeirogab/specwright-sandbox/taskr-origin.git` — never GitHub; `gh`-based flows do not apply inside the sandbox.
- taskr stores `createdAt` as **UTC epoch seconds** (`Math.floor(Date.now()/1000)` in `lib/tasks.js`) — the export requirement of "ISO-8601 dates" therefore forces a conversion, which is exactly the learnings producer/consumer seed the user script must state as a requirement (ISO-8601 in exports) without explaining the epoch detail.
- `test/taskr.test.js` (5 tests, `npm test` = `node --test`) pins `taskr list` to **oldest-first insertion order** — the "newest task first, existing tests untouched" requirement is deliberately impossible; the user script must hold that requirement even if the session pushes back (steering requirements, not mechanics).
- Storage is a JSON array at `TASKR_FILE` (default `.taskr.json`, git-ignored); tests use temp files. taskr is dependency-free; the sandbox's only quality gate is `npm test`.
- specwright is fully installed in the sandbox (AGENTS.md, `.specwright/` vault, `.agents/skills/sw-*` canonical copies) — the session-under-test reads `.agents/skills/sw-brainstorm/SKILL.md`.

Additional constraints:

- The owner never edits sandbox files; only sessions-under-test write there. The owner only reads/inspects.
- Findings only — no fixing specwright defects (milestone non-goal).
- All owner commits happen on `chore/e2e-scope-detection` inside this worktree. The sandbox has its own git history written by the sessions.
- No AI attribution anywhere (owner commits, session prompts must not request attribution either — the session follows the sandbox's own conventions).

## User Stories / Scenarios

1. **Milestone case** — the scripted user asks for the five-capability taskr expansion; the session explores context, clarifies, proposes approaches, presents a design; the user approves; the session **suggests** a milestone with an issue preview (slugs, one-liners, dependencies) and leaves the decision to the user; the user accepts; the session asks its one-batch question (worktrees for issue owners), the user takes the default; the session writes `goal.md` + `board.md` + N `issue.md` in the sandbox, commits, prints the mandatory handoff, and stops.
2. **False-positive case** — the scripted user asks for a `--version` flag in the disposable copy; the session runs the same brainstorm flow, concludes a **single issue** (never mentioning milestones), asks the three-part batch (branch, worktree, handoff), the user answers (accept branch, no worktree, handoff yes); the session writes `.specwright/issues/<date>-<slug>/issue.md`, commits, prints the handoff, and stops.

## Acceptance Criteria

The acceptance criteria live in the sibling `issue.md` — the `AC-N` IDs defined there are the contract `tasks.md` references and `/sw:review` walks. Do not duplicate them here; if writing this spec exposed a missing or wrong criterion, fix `issue.md`.

## Risks and Mitigations

| Risk | Mitigation |
|---|---|
| Session sub-agent doesn't pause for user replies and self-decides | Framing prompt explicitly instructs: end the turn whenever a user answer/approval is needed; never simulate user replies. If it still barrels through, that is itself evidence — record and judge the transcript as-is. |
| Milestone-case session concludes single issue (scope miss) | Recorded as AC-1 failure; one recorded user-plausible nudge to still produce the downstream fixture (see Contingency). |
| False-positive session pushes to the shared bare origin | The disposable copy's `origin` is repointed to a scratch bare clone before the session starts. |
| Owner accidentally leaks expected outcomes | Every user message is pre-written in tasks.md's reply policy or composed under the Non-leak rule; transcripts capture all owner messages, so a leak would be visible evidence and must be recorded as a finding against the test itself. |
| Session modifies taskr code/tests during brainstorm (HARD-GATE violation) | Post-session check: `git -C <sandbox> diff HEAD~..HEAD --stat` and `npm test` still passing with 5 tests; any code change during brainstorm is a finding. |
| Agent/SendMessage turn limits truncate a session | Keep scripted replies compact; if a session dies mid-flow, restart it fresh (max 3 attempts, then blocked). |

## Open Questions

None.
