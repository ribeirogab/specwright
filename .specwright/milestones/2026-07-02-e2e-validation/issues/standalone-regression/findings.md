# Standalone Issue Regression (T9) — Findings

One verdict per audit station; every non-PASS gets an Expected / Observed / Proposed-fix entry. These seed the fixes brainstorm (append to the T8 dossier — its consolidation note expects them).

## Verdict map

| # | Station | Verdict | Evidence |
|---|---------|---------|----------|
| 1 | Design conversation before decisions (converse first) | PASS | evidence/02 Turn 1: exploration + 4 questions + a tension, zero proposals |
| 2 | Design approval as the only human gate | PASS | evidence/02 Turn 2: full design presented, explicit approval requested and given |
| 3 | Scope concluded single issue; milestone never suggested | PASS | evidence/02 Turn 3: "Escopo: issue única [...] Nada aqui sugere milestone"; the only other milestone token is Turn 1's concurrent-work mention (allowed, T1 precedent) |
| 4 | Post-design batch: exactly branch + worktree + handoff, one message | PASS | evidence/02 Turn 3, byte-exact: three numbered decisions, nothing else |
| 5 | issue.md under `.specwright/issues/YYYY-MM-DD-<slug>/` (standalone vault path) | PASS | evidence/04 §1: `2026-07-02-help-flag/`, milestone tree untouched |
| 6 | JIT spec.md + tasks.md after planning starts (git history) | PASS | evidence/04 §2: issue commit `5b163f2` predates plan artifacts (`2dcc275`); note below |
| 7 | Self-review gates (validate-spec.sh, spec-reviewer, /sw:review-spec) | PASS | evidence/03: all three ran; reviewer Approved — confirmed by the session directly with its subagent |
| 8 | Quality gate: suite green, no count drop, no weakened assertions | PASS | evidence/04 §3: 9/9, 5 inherited intact, TDD visible in commits |
| 9 | Runtime verification by observed behavior per AC | PASS | evidence/04 §4 + evidence/03 (per-AC record, explicit stream redirection) |
| 10 | Delivery via /sw:pr's documented no-GitHub degradation | PASS (2 divergence notes) | evidence/03: push → `gh pr create` fails on non-GitHub remote → stop + explain + manual steps, zero fabricated URLs — first organic exercise of dossier 6.4 |
| 11 | /sw:review to lgtm | PASS | evidence/03: 3 lanes, nit fixed, pre-existing convention question correctly scoped out → lgtm |
| 12 | status: shipped + date, ACs ticked | PASS | evidence/04 §7 |
| 13 | design.md dead (files before/after + transcript) | PASS | evidence/01 + evidence/04 §6: 0 files, 0 assistant-authored mentions |

**Standalone-path regression verdict: none.** Every station of the single-issue flow behaved per the unified layout; the old format never appeared.

## Divergences (Expected / Observed / Proposed fix)

### Divergence 1 — /sw:pr probes with a live `gh pr create` instead of inspecting the remote first

- **Expected:** per `sw-pr` SKILL.md's Degradation section, "No GitHub remote (`git remote -v` empty or non-GitHub) → stop and explain" — detection should come from inspecting `git remote -v` (which the session had already fetched in its context-gathering step), before any create attempt.
- **Observed:** the session ran `gh pr create --base main --title "test" --body "test" --assignee @me` as a failure probe (junk payload, `; true` to swallow the error). Harmless here — but against a repo whose `origin` IS a GitHub remote while some other precondition is off, this creates a real junk PR titled "test". `gh auth status` had already succeeded ("gh ok"), so only the remote's non-GitHub-ness saved the probe from side effects.
- **Proposed fix:** in `sw-pr` SKILL.md, make the degradation checks an ordered pre-flight: (1) `git remote -v` — non-GitHub/empty → stop before anything else; (2) `gh` presence/auth → stop with manual steps; only then `gh pr create`, and never with placeholder title/body. One sentence: "Run the two degradation checks before `gh pr create`; never invoke `gh pr create` as a probe."

### Divergence 2 — the organic degradation leaves the PR record with no durable home

- **Expected (by intent):** the PR body is the documented carrier of the quality-gate results and the per-AC runtime-verification record. Milestone rounds preserved that record in a `pr.md` in the issue folder — but that shape was orchestrator-pre-instructed (T5 learning), not skill text.
- **Observed:** the organic path ("stop and explain") produced no `pr.md`; the runtime-verification record and would-be PR body live only in the session transcript and its final chat summary. The vault keeps `issue.md`/`spec.md`/`tasks.md`/`learnings.md`, but the delivery record — exactly what `/sw:review`'s issue-conformance lane and a future auditor want — evaporates with the session.
- **Proposed fix:** extend `sw-pr` SKILL.md's Degradation section: when stopping (either branch), write the fully-filled PR body (template or embedded fallback, including quality gate + runtime verification) to `<issue-folder>/pr.md` and say so — aligning the organic path with the milestone rounds' proven artifact shape.

## Dossier-bound observations (not divergences)

- **Notification misrouting, 7th reproduction:** the driven session's spec-reviewer completion notified the top-level session, not the dispatching owner; the budgeted verdict relay was needed (consistent with owner-stall 6/6, now 7/7).
- **Relayed verdicts are independently re-verified (new, positive):** "gate é gate — vou confirmar o veredito direto com o subagente" — the session refused to close a gate on a third-party relay and re-confirmed with its own reviewer. Relays un-stall; artifacts (or the child itself) remain the source of truth. Strengthens the poll-observable-state doctrine.
- **zsh multios makes piped stream checks inconclusive:** the session's first `2>&1 | …` runtime check could not attribute output to stdout vs stderr; it switched to explicit per-stream file redirection (`>/tmp/out 2>/tmp/err`). Worth a line in runtime-verification guidance for stream-sensitive ACs.
- **Plan artifacts committed at ship, not at plan:** JIT ordering stayed provable (issue commit strictly first), but a stricter auditor would prefer the plan skill to say when `spec.md`/`tasks.md` should be committed. Currently unspecified — the session's choice was legitimate.
- **Dispatch-context drift:** T9's dispatch described the sandbox suite as "25 tests, newest-first" — that is the unmerged `feat/list-newest-first` branch tip, not `main` (5 tests, oldest-first). Baseline re-verification caught it (evidence/01); no impact.
- **pt-BR replies throughout:** operator-config bleed (T2), not divergence.
