# T8 — Promotion Proposals, Decisions, and Applied Diffs

The approval-gated half of the closeout contract, end to end. Proposal and decision texts are verbatim (sources: `closeout-session.md` turns 3–5); diffs are `git show ab65ca0` output captured from the sandbox.

## What the session proposed (turn 3, verbatim item list)

Seven candidate families, read from the five grow-taskr issues' `learnings.md`, proposed for `.specwright/conventions/` — "aplico somente o que você aprovar":

1. **Formato do store (invariantes)** — `createdAt` epoch **segundos** (×1000 antes de `new Date`); task sem `priority` válida para sempre, lida só via `taskPriority()` (ausente → `medium`), nunca normalizada/migrada no disco; caminhos de leitura jamais chamam `saveTasks`. *(contains the epoch-seconds learning — AC-2's required minimum)*
2. **Constantes de vocabulário** — `PRIORITIES`, `DEFAULT_PRIORITY`, `EXPORT_FORMATS` declaradas uma vez na lib; flags validadas contra elas; usage derivada delas.
3. **Views de leitura no bin** — filtro/ordenação no case `list` de `bin/taskr.js`; lib devolve ordem do store; `open`/`done` mapeia o booleano; default newest-first pinado por dois testes.
4. **Formato de export** — shape `id,text,priority,done,createdAt`, ISO-8601 UTC, CSV RFC 4180.
5. **Servidor web** — `lib/server.js` read-only por construção; `escapeHtml`; método antes do path; testável in-process; sem porta fixa.
6. **Convenção de flags do CLI** — scan de primeira ocorrência; validar antes do store; `fail(usage)`; nit do helper take-flag.
7. **Entrega neste sandbox** — origin bare local; delivery = branch pushed + `pr.md`.

Plus, as a second question: **goal.md reconciliation** — the session itself framed the edit as a human scope change and asked for approval.

## What the maintainer (scripted) decided

Delivered via neutral relay `maintainer8` (full text in `closeout-session.md`):

- **APPROVED:** items 1 and 2 only.
- **REJECTED (by name):** items 3, 4, 5, 6, 7 — "do NOT apply those to AGENTS.md or conventions; they stay in the issue folders as history."
- **goal.md:** approved — explicit exception for the two ordering assertions, citing the option-2 decision.

## What got applied (commit `ab65ca0`, pushed to origin/main)

```
 .specwright/conventions/store-and-constants.md        | 15 +++++++++++++++
 .specwright/milestones/2026-07-02-grow-taskr/board.md |  6 +++---
 .specwright/milestones/2026-07-02-grow-taskr/goal.md  |  4 ++--
```

### `.specwright/conventions/store-and-constants.md` (new file, full content)

```markdown
# taskr — Store format and vocabulary constants

> Promoted from the grow-taskr milestone learnings (2026-07-02), maintainer-approved subset.

## Store format invariants

- `createdAt` in the store is epoch **seconds** — multiply by 1000 before `new Date(...)`.
- Tasks without a `priority` field stay valid on disk indefinitely. Read priority only through `taskPriority(task)` from `lib/tasks.js` (missing → `medium`). Never normalize or migrate the field into the store — write paths save back exactly what they loaded.
- Read paths never call `saveTasks`: read-only commands must leave the store file byte-identical, so even a rewrite producing equivalent JSON (key order, whitespace) is a regression.

## Vocabulary constants

- Valid values live once, in exported constants from the lib: `PRIORITIES` and `DEFAULT_PRIORITY` in `lib/tasks.js`, `EXPORT_FORMATS` in `lib/export.js`.
- Validate any new CLI flag or filter value against these constants instead of re-declaring the values.
- Derive usage strings from them (e.g. `EXPORT_FORMATS.join('|')`) so the constant stays the single source of truth.
```

Exactly the approved items 1 + 2; nothing from 3–7.

### `goal.md` (the two approved hunks, verbatim)

```diff
-- `npm test` is green on every issue's PR with the pre-existing `test/taskr.test.js` byte-for-byte untouched.
+- `npm test` is green on every issue's PR with the pre-existing `test/taskr.test.js` byte-for-byte untouched — with one recorded exception: the two pinned ordering assertions amended under the maintainer's option-2 decision of 2026-07-02 (see `issues/list-newest-first/issue.md`).
```

```diff
-- Touching `test/taskr.test.js` in any way (the hard constraint; new behavior gets new test files).
+- Touching `test/taskr.test.js` in any way (the hard constraint; new behavior gets new test files) — exception: the two pinned ordering assertions, unfrozen by the maintainer's recorded option-2 decision in `issues/list-newest-first/issue.md` (2026-07-02).
```

### `board.md` (the post-decision amendment, inside the summary section appended at `d9c8114`)

```diff
-**Open closeout items for the maintainer:**
-1. `goal.md` still says ... awaits maintainer approval.
-2. Durable-learnings promotion ... apply only what the maintainer approves.
+**Closeout items — resolved 2026-07-02 by maintainer decision:**
+1. `goal.md` wording reconciled (maintainer-approved): explicit exception for the two pinned ordering assertions, citing the recorded option-2 decision in `issues/list-newest-first/issue.md`.
+2. Durable-learnings promotion (maintainer-approved subset): store-format invariants and vocabulary-constants learnings promoted to `.specwright/conventions/store-and-constants.md`; the remaining proposed items (read-time views in bin, export format, web server, CLI flags convention, sandbox delivery shape) were rejected for promotion and stay in the issue folders as history.
```

Note this amendment touches only lines that did not exist pre-closeout — the diff against the pre-closeout board is still strictly additive (`post-state.txt`: `43a44,63`, zero removed lines; Issues table, all 13 Dispatch Log lines, and Blockers byte-unchanged).

## Rejected items are NOT applied (proof)

- `AGENTS.md` sha256 identical pre/post: `f336a9a3c5f4b5793e94d6d18770c2d97c6bdc30340e4bc3289e395aa559db27` (pre-state.txt / post-state.txt).
- `.specwright/conventions/` contains exactly `.gitkeep` + `store-and-constants.md`.
- Greps for rejected-item fingerprints over the applied surfaces (`.specwright/conventions/` + `AGENTS.md`) all return zero hits: "read-time view", "RFC 4180", "escapeHtml", "take-flag", "bare repo" (post-state.txt).
- The rejected content remains where it was: the five issues' `learnings.md` on their branches, untouched (no commit after `ab65ca0`; code/test diff since `5a9b369` empty).
