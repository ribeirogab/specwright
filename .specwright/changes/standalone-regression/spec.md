---
feature: standalone-regression
created: 2026-07-02
scope: high
branch: chore/e2e-standalone-regression
worktree: .specwright/worktrees/standalone-regression
milestone: .specwright/milestones/2026-07-02-e2e-validation
---
# Standalone Issue Regression (T9) — Spec

**Issue:** see the sibling `issue.md` (the *why*, the acceptance criteria, and the issue `status:`)
**Scope:** Drive one `/sw:brainstorm`-to-shipped standalone-issue pass ("add a `--help` flag") in the idle taskr sandbox and audit every station of the single-issue flow, producing evidence, findings, and learnings — fixing nothing in specwright.

> **Note on `scope:` frontmatter** — `scope` is one of `low | medium | high | complex`. It is **recorded only**: reserved for a future quick-mode and does **not** yet gate which artifacts are written. Set it honestly; nothing branches on it today.
>
> **Note on `worktree:` frontmatter** — the path of this issue's git worktree under `.specwright/worktrees/`, or `null` when the work runs in place. **Recorded only**, like `scope:`.
>
> **Note on `milestone:` frontmatter** — the milestone folder this issue belongs to, or `null` for a standalone issue.

This is the **technical** spec — the *how*. The non-technical *why*, the acceptance criteria, and the status live in `issue.md`.

## Architecture

A **driver/driven harness**, same shape as scope-detection (T1) and resume (T2): this session (the driver) spawns one general-purpose sub-agent (the **driven session**) whose cwd is the sandbox, plays the user with scripted replies, polls repository state between turns, and captures key turns verbatim with `jq` from the sub-agent's JSONL transcript. The driver never edits sandbox files; every sandbox mutation must come from the driven session.

**Driven-session contract (folds in every applicable inherited learning):**

- **Neutral naming on the SENDER side, always** — the 4x-reproduced leak channel is the sender's SendMessage attribution, and this issue's driver is itself a slug-named dispatchee (T4: "naming the agents you spawn neutrally does not cover the name you were dispatched under"; T7: never SendMessage a session under test from a slug-named session). Therefore: (a) the opening user ask travels in the **spawn prompt**, which carries no sender name (T2); (b) **every** subsequent driver→driven message — all scripted replies, not just pings — is delivered by a fresh neutrally-named relay agent (`maintainer`, falling back to `maintainer2`, `maintainer3`, … if a name is still held) that SendMessages the driven session's **spawn-result agentId** and returns (T8-proven: arrives as `from="maintainer8"`-style, no slug leak, applied verbatim); (c) the driver never SendMessages the driven session directly. Relays are one-way — the driven session's answers are read from its JSONL transcript, never from relay replies. Driven sessions get neutral names too (`session-a` for the brainstorm; `session-b` if a handoff spawns a second session).
- **Standing approval + conduction rules live in the spawn prompt** (SendMessage approvals are categorically refused — T4, 2 refusals on record): unattended mode, standing approval for all sandbox-local actions (branch, worktree, commits, push to the local origin), "end your turn whenever you need the user".
- **Zero outcome leakage** — the spawn prompt and every scripted reply name only the user-visible ask ("`taskr --help` should print usage text"). Forbidden in all driver→driven text: `design.md`, `pr.md`, "degradation", "no-remote", "single issue", "milestone" (as a scope suggestion), vault paths, expected batch shape. The organic `/sw:pr` no-remote stop is unexercised anywhere (dossier 6.4) — this run must reach `/sw:pr` with **no pre-instruction** about PR mechanics.
- **Address by agentId, never by name** (names expire — T5); treat every relay as one-way (alias expiry is a race — T8); poll observable state (files, branches, `issue.md` status) instead of waiting on child notifications (owner-stall 6/6); budget one relay per reviewer dispatch the driven session makes, plus one status ping.
- **pt-BR replies from the driven session are operator-config bleed** (T2) — transcript graders must not read them as divergence.

**Scripted reply plan (the driver's user persona):**

1. Opening ask: `--help` today falls into the generic-usage error path (stderr, exit 1); the user wants a real `--help` flag printing usage text. Ask to design it together, invoking the brainstorm flow.
2. Design conversation: answer questions as an opinionated-but-flexible user (converse first, decide at the end); approve the design explicitly when the session presents it.
3. Scope conclusion: the session suggests, the user decides — accept a single-issue suggestion. A milestone **suggestion** is a FAIL filed under the scope-conclusion station (it violates the issue's Non-Goal, not AC-1's batch shape; a milestone *mention* as concurrent-work context is fine — T1 precedent); do not steer either way beforehand.
4. Post-design batch: answer whatever the session asks in one reply (branch name: accept its suggestion; worktree: yes; handoff: follow what the session itself offers — continue in-session or hand off to `/sw:plan`; either is valid, record which; on a handoff, spawn a second driven session (`session-b`, same contract) whose cwd is the checkout the brainstorm session **actually created** — resolve the worktree path from observed sandbox state, never assume it).
5. Pipeline: no steering; relay reviewer verdicts within budget; capture the `/sw:pr` station verbatim.

**Audit stations (each maps to an AC):** design-approval gate honored (converse→approve), scope = single issue (AC-1 context), batch = exactly branch + worktree + handoff (AC-1), `issue.md` under `.specwright/issues/YYYY-MM-DD-<slug>/` with `spec.md`/`tasks.md` appearing only after planning starts — proven by git history (AC-2), pipeline to `lgtm` + `status: shipped` with suite green, `--help` runtime-verified, PR delivered via the documented no-GitHub degradation with zero fabricated URLs (AC-3), no `design.md` ever + no transcript mention (AC-4), findings verdicts (AC-5).

## File Structure

All driver-side artifacts live in this issue's folder (`.specwright/milestones/2026-07-02-e2e-validation/issues/standalone-regression/`), committed on `chore/e2e-standalone-regression`:

- Create: `evidence/01-baseline.md` — pre-run sandbox state: HEAD, clean tree, empty `.specwright/issues/`, design.md sweep = 0, suite = 5 tests, current `--help` behavior (stderr + exit 1).
- Create: `evidence/02-brainstorm-session.md` — verbatim key turns: design conversation, approval, scope conclusion, the post-design batch (byte-exact — AC-1's evidence), handoff wording.
- Create: `evidence/03-pipeline-session.md` — verbatim key turns: plan gates, quality gate, runtime verification, the organic `/sw:pr` no-remote behavior, review verdict, ship.
- Create: `evidence/04-after-state.md` — post-run sweeps: vault-path listing, git-history ordering of issue.md vs spec.md/tasks.md, suite result on the feature branch, `status: shipped` proof, design.md sweep = 0, fabricated-URL grep.
- Create: `findings.md` — verdict per audit station; Expected / Observed / Proposed fix per divergence (seeds the fixes brainstorm per T8's dossier).
- Create: `learnings.md` — final sandbox state + non-obvious facts.
- Modify: `issue.md` — status flips + AC ticks.

Sandbox files (`/Users/gabriel/www/ribeirogab/specwright-sandbox/taskr`): mutated **only** by the driven session(s); left exactly as the session leaves them, documented in `learnings.md`.

## Phase Ordering

1. **Baseline** — capture pre-run state (design.md sweep before, empty issues dir). No dependencies.
2. **Brainstorm drive** — spawn `session-a`, run the design conversation to approval, scope, batch (replies via neutral relays). Depends on 1.
3. **Pipeline drive** — per the session's own offer, continue in-session or hand off; drive to `status: shipped`. Depends on 2.
4. **After-state audit** — sweeps and git-history proofs. Depends on 3.
5. **Findings + learnings + ship** — write `findings.md`, `learnings.md`, PR, review, flip status. Depends on 4.

## Constraints

- **Findings only** — no fixes to specwright skills/templates, no sandbox edits by the driver. Divergences go to `findings.md`.
- **Sandbox truth vs dispatch context:** `main` (`ab65ca0`) has **5 tests** and oldest-first ordering — the "25 tests, newest-first" in the dispatch describes the unmerged `feat/list-newest-first` branch. The driven session branches from `main`; audit test counts against `main`'s 5 (T5: audit against the branch's own base). Record the correction in findings context, not as a divergence.
- Sandbox origin is the local bare repo `taskr-origin.git` — `gh` flows do not apply; `/sw:pr` must degrade per its own documented path, unprompted. Never any fabricated PR URL, in the sandbox or in this issue's PR.
- The five grow-taskr worktrees and unmerged branches are inert history — the driven session must not need them; if it trips on them, that is a finding.
- `.specwright/conventions/store-and-constants.md` exists in the sandbox — the driven session's plan/review gates may cite it; `--help` touches no store format, so a violation report there would be a finding.
- Driver circuit breaker: the same failure three times identically → stop, report, `status: blocked`.
- Milestone-issue AC rule: if planning exposes a wrong AC, report to the orchestrator — never edit `issue.md`'s ACs unilaterally.
- **AC-3 contingency (spec-reviewer advisory, recorded):** AC-3 presumes the organic `/sw:pr` behavior matches its documented no-GitHub degradation. If the observed behavior diverges (dossier 6.4 flags the organic path as unknown), AC-3 cannot tick — record the divergence in `findings.md`, leave AC-3 unticked, and surface the AC conflict in the return to the orchestrator instead of editing the AC.

## User Stories / Scenarios

1. A taskr user runs `taskr --help` and gets usage text on stdout with exit 0 (the driven session's deliverable; verified by executing the CLI).
2. A specwright maintainer reads `evidence/02-brainstorm-session.md` and can check AC-1 (three-part batch, nothing else) against byte-exact quoted turns.
3. A maintainer reads `findings.md` at the fixes brainstorm and gets one Expected/Observed/Proposed-fix entry per divergence, appendable to the T8 dossier.
4. A future issue reads `learnings.md` and knows the sandbox's exact final state without re-deriving it.

## Acceptance Criteria

The acceptance criteria live in the sibling `issue.md` — the `AC-N` IDs defined there are the contract `tasks.md` references and `/sw:review` walks. Do not duplicate them here; if writing this spec exposed a missing or wrong criterion, fix `issue.md`.

## Risks and Mitigations

| Risk | Mitigation |
|---|---|
| Driven session stalls waiting on its own sub-agents (owner-stall, 6/6 on record) | Poll sandbox state every check cycle; budget one relay per reviewer dispatch + one status ping to the agentId ("verify state from repository artifacts" — proven un-staller) |
| Driver name/expected-outcome leak contaminates the run | The driver never SendMessages the driven session directly: opening ask in the spawn prompt (no sender attribution), every later reply via a fresh neutral `maintainer*` relay to the agentId; pre-send checklist over every reply against the forbidden-terms list |
| Session asks for an approval mid-pipeline despite standing approval | Reply granting it as the user (a scripted-reply, not a SendMessage-approval violation — the refusal precedent concerns permission prompts, not conversational answers per T8) and record the ask in findings if the spawn prompt already covered it |
| `/sw:pr` organic no-remote behavior diverges (fabricated URL, silent skip) | Capture verbatim; that is exactly the unexercised path this issue exists to observe — findings entry, dossier-bound |
| JSONL transcript path unknown until spawn | The Agent tool result names the output file; fall back to `~/.claude/projects/` scan by session id; capture turns incrementally, not only at the end |

## Open Questions

None.
