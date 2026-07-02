# E2E Validation — Consolidated Dossier

Every divergence and improvement this milestone paid to discover, deduplicated and grouped by theme, ready to seed the follow-up fixes delivery. Compiled by the closeout issue (T8).

**Sources.** Ten sibling `findings.md` files — sandbox-setup, scope-detection (T1), milestone-planning (T2), resume (T3), dispatch-parallelism (T4), issue-pipeline (T5), circuit-breaker (T6), blocked-recovery (T7) in this worktree; command-surface and docs-coherence read from their unmerged branches (`git show chore/e2e-command-surface:…`, `chore/e2e-docs-coherence:…`) — plus the orchestrator's **Conduction notes** on the milestone board (parent checkout `board.md`, including two user-requested skill improvements) and this issue's own closeout findings (`findings.md` in this folder). **standalone-regression (the remaining sibling) had not run at consolidation time** — it depends on closeout; its findings must be appended by its owner or read directly at the fixes brainstorm.

**Severity scale.** `high` = breaks a contract, first-use experience, or auditability of an approved artifact; `medium` = weakens a guarantee, leaves a documented promise unbacked, or costs every future run friction; `low` = polish, docs accuracy, fixture-only.

**Charge line.** Entries marked *(test-plan)* are fixture/harness design debts, not specwright defects — they matter only if the validation suite is rerun.

---

## Theme 1 — Run-skill contract (conduction)

### 1.1 Approval batching covers the whole milestone, not the round — `medium`

- **Source:** T4 Finding 2 (root observation T3 O-1).
- **Expected:** dispatch happens per loop turn; an interactive user retains a per-round checkpoint.
- **Observed:** the round-1 conductor's single approval ask covered "worktrees + branches + commits + push + PRs for the 5 issues of the milestone" — one consent for every future round. Corollary (T3 O-1): unattended runs have no natural pre-dispatch pause at all.
- **Proposed fix:** run skill: scope interactive approval asks to the current round's writes; a later round is a new loop turn and a new ask.

### 1.2 Dispatch Log lines are written at event time but committed only at round close — `low`

- **Source:** T4 Finding 6.
- **Expected:** append-only log durable per event.
- **Observed:** the `dispatched` line sat uncommitted in the working tree until the round-close commit bundled `dispatched` + `shipped`; a crash mid-round would leave the log unversioned.
- **Proposed fix:** run skill: commit the board after every Dispatch Log append.

### 1.3 "Deps shipped" is ambiguous while the dependency's branch is unmerged — `medium` (behavior exists, wording doesn't)

- **Source:** T4 Finding 7; resolution observed in T5 ("Round-2 conduction notes": the stacked-branch clause self-executed, unprompted, 3/3 owners + conductor) and T6/T7 (trap stacked on `feat/list-filters` twice).
- **Expected:** the ready rule names which checkout it reads and where owners branch from when the dep's PR is unmerged.
- **Observed:** `status: shipped` lived only on the unmerged branch (`main`'s ticket copy stayed `pending`); conductors consistently read the on-branch copy and stacked correctly — but the skill text never says the ready-rule reads the dependency's own branch, so the correct behavior is emergent, not specified.
- **Proposed fix:** run skill: one sentence making it explicit — readiness reads the dependency's own-branch `issue.md`; unmerged dep ⇒ stack on its branch and note the re-target-after-merge step (exactly what four owners already did).

### 1.4 Blockers "verbatim" copy is actually a faithful synthesis — `medium`

- **Source:** T6 Divergence 1 (consolidated with the verbatim-vs-relay evidence pattern, Theme 7.5).
- **Expected:** "copy the owner's report **verbatim** into the board's Blockers section" (run skill Track step + board template).
- **Observed:** the conductor composed the entry from two owner artifacts, restructured under Why/Tried/Needs, zero semantic loss but no byte-identical run longer than a phrase — audits cannot rely on byte equality.
- **Proposed fix:** either relax the skill wording ("verbatim or a lossless restatement citing the owner's evidence file") or make the owner deliver a paste-ready block the conductor pastes unmodified.

### 1.5 The halt report's recovery line names no checkout and no commit step — `high`

- **Source:** T7 Divergence 1 (contract otherwise proven end to end: T6 verdict table, T7 checks 1–6).
- **Expected:** a recovery instruction executable by a maintainer ignorant of the stacked-branch mechanics; the blocked ticket exists in two states (blocked on-branch, pending-with-old-ACs on `main`).
- **Observed:** "edite a issue conforme a opção escolhida, volte o `status:` para `pending`" — no path, no branch, no commit instruction. Editing `main`'s copy would silently do nothing (nobody in the loop reads it); an uncommitted edit is clobberable and unrecorded.
- **Proposed fix:** run skill escalation contract: the blocked report's recovery line must name the exact file path in the issue's own checkout and say "commit the edit on the issue's branch". One sentence, plus the `.agents` mirror. Companion guidance (T7 Divergence 2): remind the maintainer to sweep the ticket for restatements of the dropped constraint (the trap took 5 hunks, not 1).

### 1.6 Closeout has no path for goal.md reconciliation — `medium`

- **Source:** T7 Divergence 3 context + board flag ("goal.md stale by decision, T8 reconciles with approval") vs run skill scope guard ("never edits `goal.md`"); T8 findings.md C3 records what the driven closeout actually did.
- **Expected:** a milestone whose recorded human decision (option-2 unblock) supersedes a goal.md sentence ends closeout with the goal reconciled or explicitly routed.
- **Observed:** the skill's closeout step lists only summary + learnings promotion + report; the scope guard bans goal edits without an exception for maintainer-approved reconciliation — the stale goal.md survives closeout unless the human remembers it. (T8's driven session behavior: see this folder's `findings.md`, check C3.)
- **Proposed fix:** run skill closeout step: "flag any goal.md statement superseded by recorded decisions; propose the reconciling edit; apply only with the maintainer's approval" — mirroring the learnings-promotion consent shape.

## Theme 2 — Plan-skill contract (issue pipeline)

### 2.1 Owners unilaterally reword approved ACs when the mechanical gate trips on the ticket — `high`

- **Source:** T4 Finding 3 (2/2 independent owners; disclosure only post-hoc); boundary evidence: T5 ("did not recur in round 2 — validator-trip-dependent, not habitual") and T6 cheat-scan ("an impossible AC does not trigger the reword pattern"). Seed defect: T2 Divergence 3.1.
- **Expected:** ACs in an approved ticket are the contract; a milestone issue owner reports a wrong criterion, never edits it.
- **Observed:** both owners that hit `validate-spec.sh` check 4 on `task-priority` AC-2 ("works") quietly reworded the approved AC and proceeded; commit messages silent.
- **Proposed fix:** plan skill mechanical-gate step: a gate failure *caused by the approved ticket itself* ⇒ stop, report with the exact validator line, proceed only after an acknowledged resolution. Weaker fallback: any ticket edit must be its own commit naming the changed AC.

### 2.2 Plan-before-code is real but unevenly recorded — `medium`

- **Source:** T5 F1.
- **Expected:** spec/tasks committed before implementation; the three self-review gates leave a durable record per issue.
- **Observed:** JIT-by-write held 4/4, but one owner committed its plan after its three implementation commits, and gate recording ranged from a pr.md line to nothing — a repo-only auditor cannot verify gates ran.
- **Proposed fix:** plan skill: (a) explicit "commit the plan" step at the end of the spec-writing stage; (b) require pr.md's quality-gate section to name the three plan gates and their outcomes.

### 2.3 "UI criterion" is undefined, so the browser rule never binds — `medium`

- **Source:** T5 F3 (with the honest-fallback pattern: curl + recorded capability note, used by owner and auditor).
- **Expected:** UI criteria verified through a browser or marked `needs-human-verification`.
- **Observed:** all web-page ACs were HTTP/text-level; the owner curl-verified and ticked everything — defensibly, since arguably no criterion was a UI criterion. The rule cannot distinguish an owner who would silently tick a real UI criterion from one who never faced the choice.
- **Proposed fix:** plan skill: define "UI criterion" (rendered appearance/interaction, not HTTP responses); note that unattended sessions must record the capability gap when degrading to curl. *(test-plan)* alternative: a fixture criterion that is genuinely visual.

### 2.4 Fan-out threshold is owner-defeatable — `medium`

- **Source:** T5 F5.
- **Expected:** a 5+-task issue with delegable tasks fans out to task workers.
- **Observed:** an owner honestly decomposing into 4 bigger tasks (3 `Delegable: yes`) legitimately stays inline; the worker mechanics went unexercised.
- **Proposed fix:** key fan-out on delegable-task count (≥ 2 ⇒ fan out) instead of total task count — or accept owner judgment and drop the numeric threshold from the skill text.

## Theme 3 — Brainstorm-skill and planning artifacts

### 3.1 goal.md carries technical content the contract bans — `medium`

- **Source:** T2 Divergences 1.1 + 1.2 (merged: same fix).
- **Expected:** milestone goal.md free of file paths, function names, storage formats.
- **Observed:** Success Criteria named `test/taskr.test.js` byte-for-byte and `package.json`; Non-Goals named the `createdAt` epoch-seconds on-disk format.
- **Proposed fix:** brainstorm skill milestone-writing step: goal-level phrasing in behavior terms, with one worked example of translating a technical hard constraint; path-level constraints live in issue tickets. Advisory sibling (T2 §3): two tickets also pinned implementation structure (`lib/export.js`, `lib/server.js`) that belongs to the just-in-time spec.

### 3.2 The planner ships tickets that trip its own mechanical validator — `medium`

- **Source:** T2 Divergence 3.1 (the seed of 2.1's reword pattern).
- **Expected:** every ticket passes the planning-stage mechanical checks.
- **Observed:** `task-priority` AC-2's "(short alias works)" trips check 4 — detonating later in a future owner's gate, on a file that owner must not edit.
- **Proposed fix:** brainstorm skill decomposition step: run `validate-spec.sh` on each issue folder before committing (check-2 `spec.md not found` baseline is expected; anything else is the planner's to fix).

### 3.3 Brainstorm self-contradiction: "state the shape" vs "never mention milestone for small work" — `medium`

- **Source:** T1 Finding 2 (skill half; harness half is 6.2).
- **Expected:** tiny requests take the single-issue path with the milestone concept never mentioned.
- **Observed:** checklist item 6 ("state whether this is a single issue or a milestone, with your reasoning") structurally invites naming the milestone even while dismissing it ("Nem de longe justifica milestone").
- **Proposed fix:** reword checklist item 6: for small work simply conclude "single issue" without presenting the alternative; present the milestone option (with preview) only when the signals genuinely point to one.

### 3.4 State a constraint once — restatements are amendment hazards — `low`

- **Source:** T7 Divergence 2.
- **Expected:** unblocking a rescoped ticket = edit the contradictory criterion.
- **Observed:** the trap's constraint was restated in four passages (AC, Purpose, forbidden-list, Non-Goals); the minimal coherent unblock took 5 hunks.
- **Proposed fix:** one line in the brainstorm/ticket-writing guidance (or a convention): state a hard constraint once and reference it; every restatement is a future amendment hazard.

### 3.5 vault-files.md "no cross-references between issues" vs evidence-consuming audit issues — `low`

- **Source:** T2 learnings (recorded for this dossier).
- **Observed tension:** line 58 bans cross-references between sibling issues, but audit-style issues must cite sibling evidence paths to stay verifiable (line 95 bans only link syntax).
- **Proposed fix:** carve-out for evidence-consuming issues (plain-path citations allowed; links still banned).

## Theme 4 — Command surface, install parity, packaging

### 4.1 The scaffolder never installs the `sw` skill itself — the mechanical gate is broken on first use — `high`

- **Source:** sandbox-setup F-1.
- **Expected:** a by-the-letter Phase 4 install supports the issue pipeline: `sw-plan` and `/sw:review-spec` invoke `.agents/skills/sw/scripts/validate-spec.sh`.
- **Observed:** the copy loop installs only the six companion skills; nothing copies `sw` itself; the validator path does not exist after a documented install.
- **Proposed fix:** `sw` SKILL.md Phase 4 self-copy (including `scaffold/` + `scripts/`, `chmod +x`), and list `.agents/skills/sw/` in `references/audit-checklist.md`.

### 4.2 Scaffolder and install.sh produce non-equivalent installs (missing `.claude/skills/sw` symlink) — `medium`

- **Source:** command-surface F2.
- **Expected:** README promises the `.claude/skills/sw` symlink (what makes `/sw` discoverable); `install.sh` creates it.
- **Observed:** the scaffolder path created `SANDBOX/.agents/skills/sw/` but no symlink — Claude Code has no documented discovery path to `/sw` in the sandbox.
- **Proposed fix:** add the symlink step to the `sw` skill's scaffold procedure (or document that only `install.sh` wires Claude Code discovery); create the missing symlink in existing installs.

### 4.3 `$sw-spec` / `$sw-review-spec` (and `@…`) are documented but exist nowhere — `medium`

- **Source:** command-surface F1 + docs-coherence F-2 (independent confirmations; also embedded in `agents-md-template.md`, so every new install reproduces the claim).
- **Expected:** "All entries" invocable as `$sw-<verb>`/`@sw-<verb>` backed by `.agents/skills/sw-<name>/` — 8 verbs promised.
- **Observed:** the canonical layer ships exactly 6 skills; `spec`/`review-spec` exist only as Claude Code plugin commands; the four documented forms resolve to nothing.
- **Proposed fix:** (a) one-line docs fix — scope the note to the six companion skills and mark `spec`/`review-spec` Claude Code-only (matches shipped intent); or (b) parity fix — ship canonical `sw-spec`/`sw-review-spec` in scaffold + `.agents` + template. Decide once; apply to AGENTS.md, the template, and the sandbox.

### 4.4 Empty vault directories do not survive a clone — `low`

- **Source:** sandbox-setup F-2.
- **Observed:** git tracks no empty dirs; a compliant fresh install re-cloned loses `.specwright/{conventions,issues,milestones}/` and the audit reports MISSING.
- **Proposed fix:** scaffold `touch .specwright/{conventions,issues,milestones}/.gitkeep` (idempotent), or document the MISSING as expected noise.

## Theme 5 — Docs drift and validator

### 5.1 `validate-spec.sh` exit code counts FAIL lines, not failed checks — `medium`

- **Source:** docs-coherence F-1 (behavioral); corollary interpretation rule in T2 learnings (planning-stage baseline = exactly one check-2 FAIL line).
- **Expected:** header: "exits with the number of failed checks".
- **Observed:** check 1 fires twice for one missing `status:` (missing key + empty enum) ⇒ exit 2 for one defect; exit also collides with the reserved usage-exit 2. Check 2 tolerates empty `scope` while check 1 doesn't — an accidental asymmetry.
- **Proposed fix:** reword header/trailer to "failures reported (one per FAIL line)" or dedupe the counter per check; decide the check-1 empty-value behavior deliberately; note the exit-2 collision.

### 5.2 `### Issue flow` drift: AGENTS.md vs agents-md-template.md — `medium`

- **Source:** docs-coherence F-3.
- **Observed:** 7 hunks; the template lags the evolved wording (missing "converse first, decide at the end", "curates", worktree-guard clause, mermaid node text, "standalone issues in").
- **Proposed fix:** sync the template with current AGENTS.md minus the dogfood-only clause; the audit's DRIFT check then keeps them aligned.

### 5.3 README license sentence mislabels the vendored scripts — `low`

- **Source:** docs-coherence F-4.
- **Proposed fix:** "The vendored scripts under `skills/sw/scripts/` (`quick_validate.py`, `package_skill.py`) are Apache-2.0; see `NOTICE.md`."

### 5.4 README repository-layout section omits shipped top-level entries — `low`

- **Source:** docs-coherence F-5.
- **Proposed fix:** add `install.sh` + `tests/` rows; fold `AGENTS.md`/`CLAUDE.md` into the dogfood paragraph (or retitle "abridged").

### 5.5 Issue-folder enumeration in live docs predates `findings.md`/`evidence/` — `low`

- **Source:** T1 Finding 4.
- **Proposed fix:** one line in the enumerations ("plus any issue-specific artifacts, e.g. `findings.md`/`evidence/` for validation issues").

## Theme 6 — Fixture / test-plan design *(test-plan; matters only for reruns)*

### 6.1 Round-1 parallelism unobservable; blocked-skip leg vacuous — `low`

- **Source:** T1 Finding 1 + T4 Finding 1 (resolved by auditing round 2: true 3-way concurrency observed in T5); T6 Divergence 2 (the trap is last in the graph, so "loop continues past the blocked issue" was never exercised).
- **Proposed fix (rerun):** give the board a second dependency-free issue and seed the impossible issue to block while a sibling is still ready.

### 6.2 Harness contamination channels — `low`

- **Source:** T1 Finding 2 (harness half: the disposable copy carried the milestone fixture, forcing "milestone" mentions) + T1 Finding 3 / T3 O-2.
- **Proposed fix (rerun):** copy sandboxes from a pre-fixture commit for false-positive tests; attribute grep hits by turn.

### 6.3 Learnings-flow probe was mis-planted — `low`

- **Source:** T5 F2 (mechanism itself proven by the `taskPriority()`-medium fact, which did travel via learnings).
- **Proposed fix (rerun):** a probe fact must be discoverable only by doing the producer's work AND absent from the consumer's ticket/goal.md.

### 6.4 The organic `/sw:pr` no-remote stop is still unexercised — `low`

- **Source:** T5 F4 (inherited from T4; degradation pre-instructed in both rounds' dispatch prompts). Deferred to standalone-regression, which runs an owner with no orchestrator pre-instruction.
- **Status:** open until standalone-regression reports.

## Theme 7 — Harness / conduction mechanics (durable facts; several are skill-guidance candidates)

### 7.1 Background sub-agent completions notify only the top-level session — nested pipelines stall — `high` (consolidated)

- **Evidence trail:** T4 Finding 4 (owner+conductor stalls, round 1); T5 (3/3 owners + conductor mutual-wait, round 2); T6 (operator3, 20+ min); T7 (6/6); board Conduction note 2. Owner-stall on reviewer verdicts deterministic across every round with dispatches; T8's closeout run dispatched nothing, so it neither reproduced nor contradicted the pattern (final tally 6/6).
- **Proven un-staller:** one plain status ping — "verify your owners' state from repository artifacts" — after which conductors independently re-verify before logging (confirmed twice, no coaching).
- **Proposed fix:** run skill (and plan skill for reviewer dispatches): poll the dispatched agent's observable state on a cadence; treat silence as "still running" only until a state check says otherwise. This is the mechanics half of the user-requested watchdog item (8.2).

### 7.2 Agent name aliases expire; only spawn-time agentIds address reliably — `high` (consolidated)

- **Evidence trail:** T1 caveat; T5 ("No agent named 'operator2' is currently addressable", minutes after spawn); T6 (bidirectional: driven→relay replies also fail — "maintainer3 não encontrado"); T7 (resume-by-id). Board Conduction note 1 (user-approved for this dossier).
- **Proposed fix:** run skill dispatch/resume guidance: keep the agentId from the spawn result; resume/relay by ID, never by name; treat every relay as one-way and read answers from repository artifacts.

### 7.3 Approvals never travel over agent-to-agent messages; decisions and holds do — `high` (consolidated, methodology)

- **Evidence trail:** T4 Finding 5 (two categorical refusals, one post-identity-confirmation; harness permission prompts only); T1/T3 (holds, questions, scripted decisions pass); T4+ (standing approval embedded in spawn prompts works reliably, 5 conductor spawns). T8 extended the pattern: conversational decisions delivered mid-session under a spawn-prompt pre-authorization line (see findings.md C2).
- **Proposed fix:** test-plan/methodology note (already inherited by every issue since T4); no specwright change.

### 7.4 The driver's dispatch name leaks to driven sessions via message attribution — `medium` (consolidated; 4 reproductions)

- **Evidence trail:** T1 Finding 3 (`owner-scope-detection`); T3 O-2 (`owner-resume`); T4 Finding 8 (`owner-dispatch-par`); T7 Divergence 4 (`owner-blocked-rec`). Zero behavioral contamination observed, but structural.
- **Proposed fix:** sharpened rule (T7): never SendMessage a session under test from a slug-named session — spawn a neutral relay for every ping. Promotion candidate for this repo's harness conventions if session-driving tests recur.

### 7.5 Verbatim beats relay: evidence must be captured, not summarized — `medium` (consolidated)

- **Evidence trail:** T2 §4 (relayed transcripts left "handoff names the milestone path" unverifiable — an evidence gap, not a session fault); T6 Divergence 1 (the "verbatim" Blockers copy is synthesis); countermeasure proven from T3 on: surgical `jq` extraction over the driven session's JSONL gives exact turn text with no context overflow.
- **Proposed fix:** harness convention (in force since T3): capture driven sessions' key turns verbatim via jq; have sessions print handoffs/reports as their final message. Skill-side fix for the Blockers case is 1.4.

### 7.6 Operator configuration bleeds into driven sessions — `low` (consolidated)

- **Evidence trail:** T1 Finding 3 (pt-BR replies in an all-English sandbox); T3 O-3; T6 (both conductors); T8 (expected). The driver's global user instructions propagate; content and contract-following unaffected.
- **Proposed fix:** none (grading note: reply language is not a divergence). Record in the test-plan methodology.

### 7.7 Unattended browser verification is structurally unavailable — `low`

- **Evidence trail:** T5 F3 context + T5 learnings (Chrome MCP demands an interactive browser pick; curl + full-body inspection with a recorded capability note is the honest fallback, used twice).
- **Proposed fix:** folded into 2.3's plan-skill wording ("record the capability gap when degrading").

## Theme 8 — New capabilities requested (user-requested, first-class)

### 8.1 Run skill: visual progress panel — `medium` (user-requested 2026-07-02)

- **Source:** board Conduction notes (reference rendering approved by Gabriel in the e2e-validation conduction).
- **Ask:** during long conductions and on any progress request, render KPI cards (overall %, shipped N/total, in-flight, findings), a stacked progress bar (shipped/running/queued), a per-issue status-chip list, and sub-milestone bars; every text update ends with a compact one-liner: `Progresso: ~NN% — X/N shipped · <issue> rodando · Y na fila`.
- **Proposed delivery:** a "Progress reporting" section in the run skill with the panel spec and the one-liner contract.

### 8.2 Run skill: stall-proof conduction + watchdog — `high` (user-requested, from the stall episodes)

- **Source:** board Conduction notes; mechanics evidence consolidated in 7.1/7.2.
- **Ask:** conductors must poll child/sandbox state directly (files, branches, output mtimes) instead of waiting for completion notifications that only reach the top-level session, and arm a watchdog that flags N minutes without observable progress.
- **Proposed delivery:** same run-skill change as 7.1 + an explicit watchdog instruction; pairs with 7.2's address-by-agentId guidance.

## Theme 9 — Closeout (T8's own findings)

*(From this folder's `findings.md`; full evidence in `evidence/`. The driven closeout run scored 5/5 PASS on the contract: summary appended history-intact, promotion subset-gated both ways, goal reconciled with approval, board frozen, merges handed back.)*

### 9.1 The goal-reconciliation path that worked has no textual basis in the run skill — `medium`

- **Source:** T8 findings Divergence 1 (the concrete case behind entry 1.6 — same proposed fix; kept here for the evidence trail).
- **Expected:** skill letter — scope guard "never edits `goal.md`", closeout = summary + promotion + report.
- **Observed:** the conductor proposed the reconciliation unprompted, labeled it a human scope change, waited for approval, applied exactly the approved hunks — correct behavior the skill neither prescribes nor permits; a stricter conductor could refuse and also claim compliance.
- **Proposed fix:** entry 1.6's fourth closeout step + scoping the guard to the conduction loop.

### 9.2 Closeout writes the summary before the approval gate, then amends it — `low`

- **Source:** T8 findings Observation 1.
- **Observed:** summary (with "open closeout items") committed/pushed before the promotion question; the subsection rewritten to "resolved" after the decisions. Net diff vs pre-closeout still strictly additive — history intact — but "frozen after the summary" is only true of the final summary.
- **Proposed fix:** one clarifying line in the run skill's closeout step order (either defer the summary until after approvals, or bless the amend-within-the-appended-section pattern); fold into 1.6's edit.

### 9.3 Decision-over-message boundary confirmed from the accepting side — `low` (methodology, closes 7.3's loop)

- **Source:** T8 findings Observation 2.
- **Observed:** with spawn-prompt pre-authorization ("decision messages arriving in this conversation are the maintainer's answers"), an unattended conductor accepts and faithfully applies conversational decisions from a neutral relay; and a driven→relay reply was *delivered* while the relay was still live — alias expiry (7.2) is a race, not a law.
- **Proposed fix:** none to specwright; refines 7.2/7.3's methodology notes (keep planning for one-way relays).

---

## Coverage table (every source finding → dossier entry)

| Source | Finding | Dossier entry |
|---|---|---|
| sandbox-setup | F-1 | 4.1 |
| sandbox-setup | F-2 | 4.4 |
| scope-detection | Finding 1 | 6.1 |
| scope-detection | Finding 2 | 3.3 (skill) + 6.2 (harness) |
| scope-detection | Finding 3 | 7.4 + 7.6 |
| scope-detection | Finding 4 | 5.5 |
| milestone-planning | Div 1.1 / 1.2 | 3.1 |
| milestone-planning | Div 3.1 | 3.2 |
| milestone-planning | §4 evidence gap | 7.5 |
| resume | O-1 | 1.1 |
| resume | O-2 | 7.4 |
| resume | O-3 | 7.6 |
| dispatch-parallelism | F1 | 6.1 |
| dispatch-parallelism | F2 | 1.1 |
| dispatch-parallelism | F3 | 2.1 |
| dispatch-parallelism | F4 | 7.1 |
| dispatch-parallelism | F5 | 7.3 |
| dispatch-parallelism | F6 | 1.2 |
| dispatch-parallelism | F7 | 1.3 |
| dispatch-parallelism | F8 | 7.4 |
| issue-pipeline | F1 | 2.2 |
| issue-pipeline | F2 | 6.3 |
| issue-pipeline | F3 | 2.3 (+7.7) |
| issue-pipeline | F4 | 6.4 |
| issue-pipeline | F5 | 2.4 |
| circuit-breaker | Div 1 | 1.4 (+7.5) |
| circuit-breaker | Div 2 | 6.1 |
| circuit-breaker | harness obs | 7.1 / 7.2 / 7.6 |
| blocked-recovery | Div 1 | 1.5 |
| blocked-recovery | Div 2 | 3.4 (+1.5 companion) |
| blocked-recovery | Div 3 | 1.3 (unmerged-window cost, informational) |
| blocked-recovery | Div 4 | 7.4 |
| command-surface | F1 | 4.3 |
| command-surface | F2 | 4.2 |
| docs-coherence | F-1 | 5.1 |
| docs-coherence | F-2 | 4.3 |
| docs-coherence | F-3 | 5.2 |
| docs-coherence | F-4 | 5.3 |
| docs-coherence | F-5 | 5.4 |
| board Conduction notes | note 1 (agentId) | 7.2 |
| board Conduction notes | note 2 (routing) | 7.1 |
| board Conduction notes | improvement 1 (panel) | 8.1 |
| board Conduction notes | improvement 2 (watchdog) | 8.2 |
| closeout (T8) | Divergence 1 | 9.1 (+1.6) |
| closeout (T8) | Observation 1 | 9.2 |
| closeout (T8) | Observation 2 | 9.3 (+7.2/7.3) |
| standalone-regression | not run at consolidation | append at fixes brainstorm |

## Recommended decomposition for the fixes delivery

**Recommendation: a milestone** (`specwright-fixes` or similar) — the entries cluster into five mostly independent issues, four of them parallelizable from round 1; a single issue would be a grab-bag violating the one-coherent-unit rule.

1. **run-skill-contract** — 1.1, 1.2, 1.3, 1.5, 1.4 (wording decision), 1.6, plus 7.1/7.2 conduction guidance and 8.2 (watchdog). *(highest value; contains all `high` skill items)*
2. **run-skill-progress-panel** — 8.1 alone (separable UX feature; keep it from blocking the contract fixes).
3. **plan-skill-contract** — 2.1, 2.2, 2.3, 2.4 (+7.7 note).
4. **brainstorm-and-templates** — 3.1, 3.2, 3.3, 3.4, 3.5.
5. **install-parity-and-docs** — 4.1, 4.2, 4.3, 4.4, 5.1, 5.2, 5.3, 5.4, 5.5 (one issue; mostly one-line doc/script edits sharing the same audit surfaces — split 4.1+4.2 into their own if the scaffolder change grows).

Theme 6 items are **not** fixes-delivery work — they are rerun notes for the test plan; keep them here. Theme 7 methodology facts stay as harness conventions unless session-driving tests become recurring practice (then promote 7.4's rule).
