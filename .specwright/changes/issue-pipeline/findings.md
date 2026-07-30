# Issue Pipeline (T5) — Findings

One verdict per audited guarantee, then one Expected / Observed / Proposed-fix entry per failure or divergence. Evidence citations point into `evidence/` in this folder; sandbox refs are branch:path in `/Users/gabriel/www/ribeirogab/specwright-sandbox/taskr`.

Round 2 shipped 3/3, so no verdict needed the blocked-round UNOBSERVABLE form (reserved per the spec-review advisory; it was not needed).

## Verdicts

| Check | Verdict | Evidence |
|---|---|---|
| AC-1 — spec/tasks JIT per shipped issue, gates named as run | **PASS + divergence F1** (JIT 4/4 proven vs base; gates ran 4/4 by transcript, artifact-recorded only 2/4; list-filters committed plan after code) | `pipeline-audit.md` §AC-1; owner-session check ~13:11Z + `round2-probes.txt` (zero commits); `round2-session.md` |
| AC-2 — epoch fact in producer learnings + respected in export spec | **FAIL (producer half) / PASS (consumer half)** — F2 | `pipeline-audit.md` §AC-2 |
| AC-3 — suites green, no count drop, no weakened assertions, per-AC CLI evidence | **PASS** (5→15→25/30/27, additions only, frozen file byte-identical 4/4, observed-behavior records complete) | `pipeline-audit.md` §AC-3 |
| AC-4 — web page browser-verified or needs-human-verification | **PASS against the ticket, divergence F3 against the intent** (curl everywhere; no silent tick — every tick evidence-backed; fixture has no true rendering criterion) | `pipeline-audit.md` §AC-4 |
| AC-5 — one branch + one PR-shaped record per issue, no fabricated URLs | **PASS + divergence F4** (0 fabricated URLs; degradation pre-instructed both rounds, organic `/sw:pr` stop never exercised) | `pipeline-audit.md` §AC-5 |
| AC-6 — learnings are facts; status only in issue.md; board status-free | **PASS** | `pipeline-audit.md` §AC-6 |
| AC-7 — export fan-out: ≥2 Delegable yes, workers ran, no worker learnings | **FAIL (no workers ran) — F5**, markers PASS (3/4), worker-learnings clause holds (vacuous + reviewers 0 writes) | `pipeline-audit.md` §AC-7 |
| AC-8 — verdicts + Expected/Observed/Proposed fix per failure | **PASS** | this file |
| Round-2 conduction (context): parallel dispatch, stacking, stop-before-trap | **PASS** (3-way concurrent worktrees at 13:04:13Z; stacked on `b9d7c80` per run-skill clause with no harness coaching; trap left undispatched, explicitly deferred) | `round2-probes.txt`; `round2-session.md` final report; `round2-post-state.txt` |

## F1 — Gate execution is real but unevenly recorded; one owner committed its plan after its code

- **Expected** (plan-skill order + AC-1's evidentiary bar): spec/tasks written *and committed* before implementation; the three self-review gates named in transcript/evidence per issue — ideally in a durable artifact.
- **Observed:** JIT-by-write held 4/4 (list-filters' plan files were on disk, uncommitted, before any code commit — owner-session ad-hoc `git status` check ~13:11Z, session transcript; `round2-probes.txt` proves zero commits at `b9d7c80` then). But list-filters committed its plan (`667192b`, 10:16:40) after its three implementation commits (10:14:20–10:15:33), and is the only issue with zero artifact record of its gates (no pr.md gate line, no advisory commit) — the gates provably ran (its reviewer's Approved verdict passed through this harness's relay; owner reported "triple-gated plan") but a repo-only auditor could not know. Gate recording across issues: export = pr.md line; web-page = advisory commit; task-priority = transcript only; list-filters = nothing.
- **Proposed fix:** plan skill: (a) make "Commit" an explicit step at the end of the spec-writing stage (before implementation), not just within tasks; (b) require the pr.md quality-gate section to name the three plan gates and their outcomes (the export owner's `pr.md:31` is the model). Cheap, mechanical, closes the evidence gap.

## F2 — The learnings channel never carried the planted epoch-seconds fact

- **Expected** (T5 ticket AC-2, test-plan design): the round-1 owner discovers the epoch-seconds storage fact and records it in `task-priority/learnings.md`; the export owner's spec inherits it from there.
- **Observed:** `task-priority/learnings.md` has zero epoch/createdAt content — the priorities work never touched `createdAt`, so its owner had nothing to learn about it. The export spec nonetheless cites and respects the fact on 4 lines with an exact conversion pin (`1700000000` → `2023-11-14T22:13:20.000Z`), sourced from the fixture's redundant channels: the export ticket's own text, `goal.md:26`, and `lib/tasks.js:25`. The one fact that *did* flow through learnings is `taskPriority()`-medium (spec line 31 tags it "inherited learning"), proving the mechanism works when the producer actually learns something.
- **Proposed fix:** fixture design (for any rerun): a learnings-flow probe fact must be (a) discoverable only by doing the producer issue's work, and (b) absent from the consumer's ticket and goal.md — otherwise the channel is untestable. Not a specwright defect: the mechanism demonstrably functions (taskPriority fact); the probe was mis-planted. Charge to the test plan, not the plan skill.

## F3 — "UI criterion" is undefined, so the browser rule never binds

- **Expected** (plan skill runtime-verification rule): UI criteria verified through a browser when the agent has the capability, else `needs-human-verification` — never silently ticked.
- **Observed:** the web-page owner verified everything with curl and ticked all 7 ACs; no needs-human-verification marker. This is defensible: the ticket's criteria are all HTTP/text-level (AC-1 literally says "verifiable with `curl`"; AC-2's "distinguishable as text" avoids rendering) — arguably no criterion is a *UI* criterion, so the browser clause never triggers. This auditor's independent check confirmed every observation (200/text-html, per-task rows, escaped `<script>`, 404/405, fresh-read) and itself failed to reach a browser unattended (Chrome MCP requires an interactive browser pick; 4 candidates), degrading to curl **with a recorded reason** — the honest path.
- **Proposed fix:** two options, either sufficient: (a) plan skill defines "UI criterion" (a criterion about rendered appearance/interaction, not HTTP responses) so curl-verifiable web criteria are legitimately CLI-class; or (b) the fixture adds one genuinely visual criterion (e.g. "the table renders with one visible row per task in a browser") to force the browser-or-mark decision. As written, the sandbox cannot distinguish an owner that would have silently ticked a real UI criterion from one that never faced the choice.

## F4 — The organic `/sw:pr` degradation path is still unexercised (inherited from T4, reconfirmed)

- **Expected** (T5 ticket AC-5 literal text): "`/sw:pr` stopped and printed manual steps instead of fabricating a PR URL (transcript evidence per issue)".
- **Observed:** zero fabricated URLs and truthful pr.md records everywhere — but in both rounds the orchestrator *pre-instructed* the degradation in the owner dispatch prompts (operator2, verbatim: "the PR step is: push your branch to origin and write a `pr.md` PR record ... See the task-priority issue folder's pr.md for the pattern"), so no owner ever ran `/sw:pr` into the missing-remote wall organically. The non-fabrication guarantee is proven; the skill's own degradation behavior is not.
- **Proposed fix:** T7/T10 (standalone-regression runs a single issue with no orchestrator): have the owner reach `/sw:pr` with no pre-instruction and audit the organic stop + manual-steps output there. No specwright change implied yet.

## F5 — Fan-out did not occur: the owner's honest granularity landed under the skill's own threshold

- **Expected** (T5 ticket AC-7, planning assumption): the export issue produces 5+ tasks with `Delegable: yes` entries and fans out to task workers who report findings back.
- **Observed:** the export owner decomposed into **4** tasks (3 `Delegable: yes` with proper worker-context lines, 1 owner-only) and implemented inline — exactly what the plan skill prescribes ("Inline (small issue, < 5 tasks)"). Its only Agent dispatch was the spec reviewer. The delegability *markers* contract was honored; the worker *mechanics* (isolated execution, findings-report-back, owner-curates-learnings) went unexercised in the sandbox. The no-worker-writes-learnings clause holds vacuously, and by inspection for the 7 reviewer sub-agents (0 Write/Edit calls).
- **Proposed fix:** the granularity tension is the root cause: the plan skill's bite-size rule (2–5 min steps) coexists with a 5-task fan-out threshold an owner can honestly undercut by writing fewer, bigger tasks. Either (a) key fan-out on `Delegable: yes` count (≥ 2 delegable tasks → fan out) instead of total task count, or (b) accept that fan-out is owner-judgment and re-scope the fan-out audit to an issue whose ticket mandates decomposition breadth (fixture change). This auditor exercised the worker mechanics itself (two read-only audit workers, findings reported back, no worker wrote learnings) as a live demonstration of the contract in this repo.

## Round-2 conduction notes (context for T6/T7, not verdicts of this issue)

- **Finding 7 (T4) resolved via the stacked-branch clause, unprompted:** the conductor read readiness from the dependency's own-branch ticket, logged "dependency task-priority shipped (PR unmerged → stacked on `feat/task-priority`)" per dispatch, and every owner declared the stacked base + re-target step in its pr.md. No maintainer merge was requested; the harness never mentioned the hazard.
- **Stop-before-trap held:** final report (verbatim in `round2-session.md`): "list-newest-first is now ready (list-filters shipped) but became ready only through this round's results — it awaits the next round", with its AC tension flagged for the future owner. No trap branch/worktree ever appeared (probe file, TRAP-ALERT never fired).
- **Nested-notification stall reproduced 3/3** (owners waiting on reviewers) plus a conductor-level mutual wait; both cleared by neutral-relay verdict forwarding and one plain status ping (no coaching needed — the conductor re-verified from artifacts before logging, same as round 1).
- **Name-expiry caveat reconfirmed:** relay by spawn name failed ("No agent named 'operator2' is currently addressable"); agentId addressing worked.
