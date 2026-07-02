---
milestone: e2e-validation
created: 2026-07-02
---
# E2E Validation — Board

> The milestone's live state: issue order, dependencies, dispatch log, and blocker reports. The orchestrator (`/sw:run`) reads and writes this file on every loop turn. Issue `status:` lives in each issue's own `issue.md` frontmatter — it is **never duplicated here**; the board holds only what has no other home.

## Issues

An issue is **ready** when its `issue.md` says `status: pending` and every dependency listed here says `status: shipped` in its own `issue.md`.

| Order | Issue | Depends on |
|---|---|---|
| 1 | sandbox-setup | — |
| 2 | scope-detection | sandbox-setup |
| 3 | milestone-planning | scope-detection |
| 4 | resume | milestone-planning |
| 5 | dispatch-parallelism | resume |
| 6 | issue-pipeline | dispatch-parallelism |
| 7 | circuit-breaker | issue-pipeline |
| 8 | blocked-recovery | circuit-breaker |
| 9 | closeout | blocked-recovery |
| 10 | standalone-regression | closeout |
| 11 | command-surface | sandbox-setup |
| 12 | docs-coherence | — |

## Dispatch Log

Append-only — one line per orchestrator event: date, issue, event (`dispatched` / `shipped` / `blocked` / `resumed`), short note (for `shipped`: the owner's one-line learnings summary and the PR URL).

- 2026-07-02 — sandbox-setup — dispatched — worktree `.specwright/worktrees/sandbox-setup`, branch `chore/e2e-sandbox-setup`
- 2026-07-02 — sandbox-setup — shipped — taskr sandbox live at ~/www/ribeirogab/specwright-sandbox/taskr, 6 ACs runtime-verified, review lgtm; learnings: sandbox origin is a local bare repo (never GitHub); createdAt is UTC epoch seconds; 5-test suite pins oldest-first list order (the trap); storage is JSON at TASKR_FILE; dependency-free (quality gate = npm test); specwright fully installed. findings.md: 2 scaffold divergences (sw skill not self-installed; vault dirs need .gitkeep). PR https://github.com/ribeirogab/specwright/pull/36
- 2026-07-02 — docs-coherence — dispatched — worktree `.specwright/worktrees/docs-coherence`, branch `chore/e2e-docs-coherence`
- 2026-07-02 — scope-detection — dispatched — worktree `.specwright/worktrees/scope-detection`, branch `chore/e2e-scope-detection` (stacked on chore/e2e-sandbox-setup)
- 2026-07-02 — command-surface — dispatched — worktree `.specwright/worktrees/command-surface`, branch `chore/e2e-command-surface` (stacked on chore/e2e-sandbox-setup)
- 2026-07-02 — command-surface — shipped — 8-verb surface audited across repo+sandbox layers, review lgtm; 2 divergences (F1: $sw-spec/$sw-review-spec documented but no canonical .agents/skills copy — canonical layer is 6 skills, not 8; F2: sw scaffolder install path doesn't create the .claude/skills/sw symlink install.sh creates — install paths not equivalent); learnings: plugins materialize only on first trusted session (absent pin ≠ drift); user-global plugin cache retains pre-rename revisions (hits outside audited surfaces ≠ drift). PR https://github.com/ribeirogab/specwright/pull/38
- 2026-07-02 — scope-detection — shipped — both brainstorm cases executed with evidence, 8/10 checks passed, 4 findings, review lgtm; learnings: grow-taskr fixture at sandbox .specwright/milestones/2026-07-02-grow-taskr (commit aaa117b, not pushed to bare origin), resume /sw:run grow-taskr; board has task-priority as the only dependency-free issue (3-way parallel wave opens at round 2 — T5 observes parallelism there); the impossible issue is list-newest-first with three forbidden cheats written in; brainstorm sessions mention pre-existing milestone folders as concurrent-work context; sw-brainstorm SKILL.md self-contradiction found (checklist item 6 vs "never mention it for small work"); fp fixture was disposable — T10 creates its own. PR https://github.com/ribeirogab/specwright/pull/39
- 2026-07-02 — milestone-planning — dispatched — worktree `.specwright/worktrees/milestone-planning`, branch `chore/e2e-milestone-planning` (stacked on chore/e2e-scope-detection)
- 2026-07-02 — milestone-planning — shipped — grow-taskr planning artifacts audited, 2 contract FAILs + 1 evidence gap, review lgtm; learnings: validate-spec.sh planning-stage baseline is exactly one FAIL (spec.md not found); task-priority AC-2 "(short alias works)" trips validator check 4 — its future owner's gate fails on a file it must not edit (expect report/blocked, not thrashing); fixture goal.md carries technical content (charged to brainstorm skill guidance); relayed transcripts can't prove handoff wording — capture driven sessions' handoffs verbatim; vault-files.md:58 "no cross-references" vs evidence-consuming audit issues → propose carve-out. PR https://github.com/ribeirogab/specwright/pull/40
- 2026-07-02 — resume — dispatched — worktree `.specwright/worktrees/resume`, branch `chore/e2e-resume` (stacked on chore/e2e-milestone-planning)
- 2026-07-02 — resume — shipped — both fresh sessions discovered grow-taskr from files alone, correct ready set, held pre-dispatch, sandbox byte-identical, zero divergences, review lgtm; learnings: NL trigger matches by intent; /sw:run batches all round-1 writes behind ONE approval ask — unattended runs have no natural pre-dispatch pause (T4 must not rely on one); holding leaves even the Dispatch Log untouched; driver-identity leaks via SendMessage sender attribution — spawn drivers under neutral names; driver's global user instructions propagate into driven sessions (pt-BR replies ≠ divergence); verbatim capture via jq on subagent JSONL. PR https://github.com/ribeirogab/specwright/pull/41
- 2026-07-02 — dispatch-parallelism — dispatched — worktree `.specwright/worktrees/dispatch-parallelism`, branch `chore/e2e-dispatch-parallelism` (stacked on chore/e2e-resume)
- 2026-07-02 — dispatch-parallelism — shipped — round 1 do grow-taskr conduzido e auditado (dispatch isolado, pureza do orquestrador, board append-only, parada pré-round-2, degradação serial in-place N=1), review lgtm; learnings: sandbox end state = main 7c7f1bc, feat/task-priority b9d7c80 pushed NOT merged (ticket no main segue pending — round 2 a partir do main constrói sem a dependência, hazard T5/Finding 7); delivery sandbox = branch + pr.md; validador seeded resolve por reword unilateral 2/2; aprovação só no spawn prompt (SendMessage é recusado); completions só notificam top-level (pipelines aninhados stallam); nome do driver vaza; pureza provada por proveniência de branch + scan JSONL. PR https://github.com/ribeirogab/specwright/pull/42
- 2026-07-02 — issue-pipeline — dispatched — worktree `.specwright/worktrees/issue-pipeline`, branch `chore/e2e-issue-pipeline` (stacked on chore/e2e-dispatch-parallelism)
- 2026-07-02 — issue-pipeline — shipped — round 2 conduzido (3/3 paralelos, stacked, stop-before-trap) e rounds 1–2 auditados: 6 PASS, 2 FAIL (F2 learnings-flow: fato epoch chegou via ticket/goal/código, nunca via learnings do produtor; F5 fan-out: 4 tarefas < threshold 5 → Delegable nunca dispara), 5 findings, review lgtm; learnings: sandbox end state = main 2da129b, 4 branches empilhados não-mergeados, trap ready/undispatched (branch esperado de feat/list-filters); stacked-branch clause self-executa; owner-stall em reviewer é determinístico 4/4 (orçar 1 relay/reviewer + 1 ping/round); endereçar por agentId; pr.md pré-instruído (organic stop do /sw:pr segue inexercitado); reword de AC não recorreu; browser indisponível unattended (curl + nota é o fallback honesto). PR https://github.com/ribeirogab/specwright/pull/43
- 2026-07-02 — circuit-breaker — shipped — ambos os breakers validados end-to-end (owner bloqueou o trap com 1 falha de gate, protocolo demo→captura→revert, zero cheats; orquestrador logou, copiou o report ao Blockers e o halt run consolidou com a instrução de flip), review lgtm, 2 divergências (Blockers é síntese fiel, não byte-copy — emendar wording da skill; cláusula continuation do AC-3 vácua — reseed de fixture); learnings: dois testes pinam oldest-first; AC impossível não dispara reword (demonstrate-then-revert é o caminho eficiente); halt run é idempotente; name-alias expiry é bidirecional (relays one-way, ler respostas dos artefatos); owner-stall em reviewer 5/5. PR https://github.com/ribeirogab/specwright/pull/44
- 2026-07-02 — blocked-recovery — shipped — recovery fim a fim: halt report auditado (flip instruction presente; gaps: não nomeia checkout nem manda commitar → fix de 1 frase no run skill), edição humana mínima 1be3afa (5 hunks — contradição vive em toda reafirmação, não só no AC), /sw:run fresco logou resumed, limpou Blockers, re-despachou e o trap shipou → grow-taskr 5/5 shipped-on-branch (main 5a9b369, 13 log lines, Blockers _None._), review lgtm; learnings: primeiro uso real do evento resumed; goal.md do sandbox stale por decisão (T8 reconcilia com aprovação); slug-name leak 4ª reprodução (spawnar relay neutro — candidato a promoção); owner-stall 6/6, ping "verify from repository artifacts" é un-staller comprovado. PR https://github.com/ribeirogab/specwright/pull/45
- 2026-07-02 — closeout — shipped — grow-taskr closeout auditado 5/5 PASS (summary append-only, promoção proposta das 7 famílias de learnings, subset aprovado aplicado exatamente — rejeitados provados ausentes, goal.md reconciliado só com aprovação, merges devolvidos ao humano); 1 divergência: a reconciliação de goal.md não tem base textual na run skill (scope guard sem exceção de closeout); sandbox idle em ab65ca0; dossiê consolidado em issues/closeout/dossier.md (~30 entradas, 9 temas, com as 2 melhorias user-requested como itens de primeira classe); recomendação: milestone de fixes com 5 issues (run-skill-contract, run-skill-progress-panel, plan-skill-contract, brainstorm-and-templates, install-parity-and-docs), 4 paralelizáveis. PR https://github.com/ribeirogab/specwright/pull/46
- 2026-07-02 — standalone-regression — dispatched — worktree `.specwright/worktrees/standalone-regression`, branch `chore/e2e-standalone-regression` (stacked on chore/e2e-closeout)
- 2026-07-02 — standalone-regression — shipped — no regression (13/13 stations PASS): single-issue scope organically concluded, three-part batch verbatim, standalone vault path, JIT provable, pipeline a shipped, no design.md anywhere; organic /sw:pr no-GitHub degradation exercised pela primeira vez (2 gaps de skill-text: probe com payload junk em vez de git remote -v pre-flight; sem pr.md durável no stop path); driven sessions não confiam em veredito repassado ("gate é gate"); zsh multios quebra asserts com 2>&1 — redirecionar por stream; interrompido por session limit e retomado sem perda. PR https://github.com/ribeirogab/specwright/pull/47

## Final Summary (2026-07-02)

**12/12 issues shipped. Zero blockers sobreviventes.** A condução atravessou 1 blocked episode (o trap do sandbox, por design — bloqueou e recuperou conforme o contrato), 4+ stalls de notification-routing (todos destravados por watchdog/poll), 1 session-limit interrupt (retomado sem perda) e 4 reproduções do driver-name leak.

| Issue | Teste | PR |
|---|---|---|
| sandbox-setup | — | #36 |
| docs-coherence | T11 | #37 |
| command-surface | T10 | #38 |
| scope-detection | T1 | #39 |
| milestone-planning | T2 | #40 |
| resume | T3 | #41 |
| dispatch-parallelism | T4 | #42 |
| issue-pipeline | T5 | #43 |
| circuit-breaker | T6 | #44 |
| blocked-recovery | T7 | #45 |
| closeout | T8 | #46 |
| standalone-regression | T9 | #47 |

PRs empilhados em cadeia: #36 ← #39 ← #40 ← #41 ← #42 ← #43 ← #44 ← #45 ← #46 ← #47; #37 e #38 na base do milestone/sandbox-setup. Merge de baixo para cima.

**Dossiê consolidado:** `issues/closeout/dossier.md` (~30 entradas, 9 temas, severidades) + findings do T9 anexáveis no brainstorm de fixes. **Recomendação de fixes:** milestone de 5 issues (run-skill-contract, run-skill-progress-panel, plan-skill-contract, brainstorm-and-templates, install-parity-and-docs), 4 paralelizáveis.

**Sandbox (grow-taskr):** 5/5 shipped + help-flag standalone; idle em ab65ca0; 6 branches não-mergeados aguardando o humano.
- 2026-07-02 — closeout — dispatched — worktree `.specwright/worktrees/closeout`, branch `chore/e2e-closeout` (stacked on chore/e2e-blocked-recovery)
- 2026-07-02 — blocked-recovery — dispatched — worktree `.specwright/worktrees/blocked-recovery`, branch `chore/e2e-blocked-recovery` (stacked on chore/e2e-circuit-breaker)
- 2026-07-02 — circuit-breaker — dispatched — worktree `.specwright/worktrees/circuit-breaker`, branch `chore/e2e-circuit-breaker` (stacked on chore/e2e-issue-pipeline)
- 2026-07-02 — docs-coherence — shipped — 5 findings, review lgtm; learnings: validate-spec.sh exit = FAIL-line count (header overstates contract); /sw:spec + /sw:review-spec have no canonical .agents/skills copy (invisible to non-Claude agents); defect fixtures under evidence/ are invisible to check 3 and the run-skill glob (both non-recursive); skill copies may differ only in SKILL.md name: line. PR https://github.com/ribeirogab/specwright/pull/37

## Conduction notes (orchestrator, for the closeout dossier)

- Harness fact (user-approved for the dossier): a spawned agent's NAME alias expires between turns — SendMessage by name fails with "no agent named X addressable"; only the spawn-time agent ID works. The run skill's dispatch/resume guidance should tell conductors to keep the agent ID from the spawn result and resume by ID, never by name.
- Harness fact: background sub-agent completion notifications route to the TOP-LEVEL session, not the spawning agent — nested pipelines (orchestrator → owner → reviewer/lanes) stall unless someone relays; owners degrade to inline execution or the conductor must relay verdicts.

- Skill improvement (user-requested, for the fixes delivery): the run skill should render a visual progress panel — KPI cards (overall %, shipped N/total, in-flight, findings), stacked progress bar (shipped/running/queued), per-issue status-chip list, sub-milestone bars — periodically during long conductions and whenever the user asks for progress; every text update ends with a compact one-liner (`Progresso: ~NN% — X/N shipped · <issue> rodando · Y na fila`). Reference rendering approved by Gabriel on 2026-07-02 in the e2e-validation conduction.
- Skill improvement (from the stall episodes): conduction must be stall-proof — the run skill should tell conductors to poll child/sandbox state directly (files, branches, output mtimes) instead of waiting for completion notifications that only reach the top-level session, and to arm a watchdog that flags N minutes without observable progress.

## Blockers

One entry per blocked issue — the owner's report, copied verbatim. Delete the entry when the issue is unblocked (the Dispatch Log keeps the history).
