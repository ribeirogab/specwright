# Resume (T3) — Findings

Test: can a fresh session pick up the grow-taskr milestone from its files alone — via `/sw:run` with no arguments and via natural language ("continue the taskr milestone") — announcing the correct ready set and holding cleanly before any dispatch?

Evidence: `evidence/run-session.md`, `evidence/nl-session.md` (verbatim transcripts), `evidence/sandbox-state.txt` (before/after capture + byte diffs).

## AC-1 — `/sw:run` session: discovery without a path

### Check 1.1 — milestone located without a path argument

**Verdict: PASS.** The only user input was `/sw:run` (no slug, no path — `evidence/run-session.md`, first exchange). The session announced "Milestone localizado: **grow-taskr** (`.specwright/milestones/2026-07-02-grow-taskr/`)" — the locate step's no-argument scan found the single milestone with non-shipped issues on its own.

### Check 1.2 — board/goal/frontmatter actually read

**Verdict: PASS.** The announcement reproduces the board's exact Issues table content (order 1–5, the correct `Depends on` column) and every issue's `status: pending` from the frontmatter — none of which was in any user message. It also derived the round-2 consequence ("quando ela for `shipped`, as ordens 2–4 ficam prontas em paralelo"), which requires the dependency graph, not just the file list.

### Check 1.3 — ready set exactly the dependency-free pending issues

**Verdict: PASS.** Announced ready set: `task-priority` only ("Só a **task-priority** está pronta agora"). That matches the board: the other four all have unmet dependencies (all pending). No issue with unmet dependencies was included; no ready issue was missed.

### Check 1.4 — session stopped before any owner was dispatched

**Verdict: PASS.** The session's intended batch (worktree + dispatch + Dispatch Log append) was announced *before execution* and it asked approval ("Posso executar esse batch?"). The hold reply stopped it; its final turn confirms "nothing was dispatched or written". Corroborated mechanically by AC-3's diffs.

## AC-2 — natural-language session: same behavior

### Check 2.1 — trigger discovery without a skill pointer

**Verdict: PASS.** The NL session's framing named no skill (only "skills live under `.agents/skills/`"); the user message was "continue the taskr milestone". The session found and followed the run skill — its behavior (locate, board table, ready set, batch preview, approval ask) is point-for-point the run skill's loop. Note the trigger match is by intent, not exact text: the skill's trigger list has 'continue the milestone'; the user said "continue the **taskr** milestone".

### Check 2.2 — same ready set, same hold

**Verdict: PASS.** Identical conclusions, independently derived: milestone `grow-taskr` located at the same path, all five issues pending, "A única issue **ready** neste turno é a **task-priority**", batch announced, approval requested ("Posso prosseguir?"), clean hold on request ("Nothing was dispatched or changed: no branch, no worktree, no board edit"). It additionally previewed the future loop turns (3-way parallel wave after `task-priority` ships, then `list-newest-first`) — consistent with the board and with T1's recorded dependency shape.

## AC-3 — sandbox untouched

### Check 3.1 — every issue.md still `status: pending`

**Verdict: PASS.** `evidence/sandbox-state.txt` `## After`: all five `status: pending`, identical to `## Before`.

### Check 3.2 — board Issues table byte-identical

**Verdict: PASS.** The *entire* `board.md` is byte-identical to the pre-test copy (`diff` empty; SHA-256 `1dedb085…` unchanged) — which subsumes the Issues-table check. Dispatch Log and Blockers also untouched: both sessions held before their first write, so nothing was "legitimately logged" either.

### Check 3.3 — repo state unchanged

**Verdict: PASS.** Before and after: clean tree on `main` (ahead 1 of the local origin — the recorded fixture baseline), HEAD `aaa117b`, single worktree, all six milestone-file hashes identical, `npm test` 5/5 pass (no code touched).

## AC-4 — this document

**Verdict: PASS.** One verdict per check above; zero divergences, so no Expected/Observed/Proposed-fix entries are required. The observations below are non-failures recorded for downstream issues.

## Observations (not divergences)

- **O-1 — the approval framing is what produced the hold point.** Both sessions were framed in an approval mode (any non-read action needs user approval), mirroring a permission-prompted CLI. The run skill itself never instructs a pre-dispatch pause; an unattended session would proceed from announcement to dispatch in one turn. The reconciliation with AC-3 worked because the sessions batched *all* first writes (worktree + dispatch + log append) behind one approval ask — so the hold landed before even the "legitimate" Dispatch Log write, leaving the board fully byte-identical. Dispatch-parallelism (T4) must not rely on such a pause existing.
- **O-2 — driver-name leak reproduced (T1 caveat confirmed).** Both sessions saw the driver's agent identity — the NL session's closing message explicitly names "outra sessão sua (`owner-resume`)". The leak can only occur from the first SendMessage on, i.e. *after* the announcement under test, so the discovery evidence is uncontaminated; but a driver name carrying the issue slug is avoidable — future harnesses should spawn under a neutral name.
- **O-3 — driver language propagates.** Both sessions answered in pt-BR (the driver's global chat-language instruction reaches spawned sessions). Content was unaffected; noted so future transcript graders don't misread it as a defect.
