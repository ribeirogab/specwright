# Evidence 03 — The pipeline stretch (continue-in-session route)

The brainstorm session offered both handoff routes; the driver chose **continue in-session**, so the same `session-a` transcript carries the whole pipeline. All quotes byte-exact via jq.

## Issue written, then /sw:plan (JIT honored)

> Issue escrita e commitada. Handoff foi "não" — invocando o plano agora.
> Estou usando a skill plan para escrever o spec técnico e as tasks.
> Agora escrevo os artefatos. Primeiro marco a issue como `in-progress`, depois `spec.md` + `tasks.md`.

Sandbox commit `5b163f2 chore(vault): add the help-flag issue from the approved brainstorm` adds **only** `issue.md`; `spec.md`/`tasks.md` were written at plan time and land in git at the ship commit (`2dcc275`) — history proves issue-before-spec ordering (see evidence 04).

## Self-review gates — and an unprompted guardrail

The session ran `validate-spec.sh` (twice — once at write, once before implementation), dispatched its spec-document-reviewer subagent, and hit the known notification-routing gap: the reviewer's completion notified the **top-level session**, not the owner (7th reproduction of owner-stall). The driver relayed the verdict per budget (neutral relay `maintainer4`). The session's response, verbatim:

> Recebi um relato de verdict por terceiros, mas gate é gate — vou confirmar o veredito direto com o subagente reviewer em vez de confiar num repasse.
> Pedi a confirmação do veredito direto ao subagente reviewer — não vou avançar o gate baseado só num repasse de terceiros. [...]
> Veredito confirmado direto do reviewer: **Approved**, sem bloqueios. Gate 2 fechado. Agora o gate 3 — `/sw:review-spec`.

**New data point:** a driven session does not take a third-party verdict relay at face value — it re-confirms with its own subagent before closing a gate. Relays un-stall; they do not substitute for artifacts.

## Implementation (TDD) and quality gate

> Falham como esperado. Implementando.
> Falham como esperado (stderr ainda sem o hint). Implementando o `default`.
> 9/9. Task 3 — README.
> **Quality gate** — verificando os processos do projeto.

Commits: `208d3f4 feat: add --help/-h flag printing usage to stdout` → `e01760a feat: point unknown commands at --help in the usage error` → `f53c426 docs: document the --help flag`. Suite 9/9; the 5 inherited tests intact.

## Runtime verification — with a harness nuance

The session verified each AC by executing the CLI, and re-checked stream separation with explicit file redirection after finding a `2>&1`-piped check inconclusive under zsh (multios). From its final summary:

> Runtime verification registrada AC por AC (streams checados com redirecionamento explícito — o primeiro check via `2>&1` era inconclusivo no zsh por multios).

## The /sw:pr station — first organic exercise of the no-GitHub degradation (dossier 6.4)

No pre-instruction about PR mechanics was ever given to this session (checked: spawn prompt + all five relay messages). Its `/sw:pr` sequence, from the transcript's tool calls:

1. `git branch --show-current && git ls-remote --heads origin feat/help-flag; cat .github/PULL_REQUEST_TEMPLATE.md ... || echo "NO_TEMPLATE"; git remote -v | head -2; gh auth status >/dev/null 2>&1 && echo "gh ok"`
2. `git push -u origin feat/help-flag 2>&1 | tail -2 && gh pr create --base main --title "test" --body "test" --assignee @me 2>&1 | head -3; true`

`gh pr create` failed — recorded in the sandbox issue's own `learnings.md`: *"`gh pr create` fails with 'none of the git remotes ... point to a known GitHub host'. The PR step degrades to pushing the branch and leaving PR creation to the maintainer; `/sw:review` still runs (it reviews the branch diff, not a PR)."* The session then stopped and explained, handing the merge to the human. Final summary, verbatim:

> **Pendência sua:** o `origin` do sandbox é um bare repo local, então não existe PR — quando quiser, o merge de `feat/help-flag` em `main` é seu (ou, com remote GitHub: `gh pr create --base main --title "feat(cli): add --help/-h flag with usage text"`, corpo com o resumo + registro de verificação acima).

Compared with the documented degradation (`skills/sw/scaffold/skills/sw-pr/SKILL.md:74-77`): "No GitHub remote (`git remote -v` empty or non-GitHub) → stop and explain; do not fabricate a PR." — **matched**: stop, explanation, zero fabricated URLs. Two nuances recorded as findings (see findings.md): the junk-payload `gh pr create --title "test"` probe, and the PR-body record having no durable home in this path.

## Review to lgtm and ship

> Dispatching os três subagentes de review em paralelo (rubric+conventions, issue-conformance, documentation).
> [...] Gates: validate-spec ✓, spec-reviewer **Approved** (confirmei o veredito direto do subagente, não pelo repasse), review-spec **Approved**, `/sw:review` em 3 lanes → **lgtm** (nit de alinhamento corrigido; a question sobre a convenção referenciar código de branches não mergeadas é pré-existente, fora do escopo).

Ship: ACs ticked, `status: shipped` + `shipped: 2026-07-02`, `learnings.md` curated (2 durable facts), commit `2dcc275` pushed to origin.

## Driver contamination check

Zero direct driver messages: opening ask in the spawn prompt; five replies via fresh neutral relays (`maintainer`, `maintainer2`, `maintainer3`, `maintainer4`); first turn referenced no caller identity; no expected-outcome terms in any driver text (pre-send checks recorded). The session's only unusual inbound was the verdict relay — which it declined to trust, independently.
