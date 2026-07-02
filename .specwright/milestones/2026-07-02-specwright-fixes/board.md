---
milestone: specwright-fixes
created: 2026-07-02
---
# Specwright Fixes — Board

> The milestone's live state: issue order, dependencies, dispatch log, and blocker reports. The orchestrator (`/sw:run`) reads and writes this file on every loop turn. Issue `status:` lives in each issue's own `issue.md` frontmatter — it is **never duplicated here**; the board holds only what has no other home.

## Issues

An issue is **ready** when its `issue.md` says `status: pending` and every dependency listed here says `status: shipped` in its own `issue.md`.

| Order | Issue | Depends on |
|---|---|---|
| 1 | run-skill-contract | — |
| 2 | issue-pipeline-contract | — |
| 3 | brainstorm-and-templates | — |
| 4 | install-parity | — |
| 5 | run-skill-progress-panel | run-skill-contract |
| 6 | docs-and-validator | install-parity |

Rationale for the two dependencies: run-skill-progress-panel edits the same skill file as run-skill-contract, and docs-and-validator edits the same AGENTS.md template surface as install-parity — serializing them avoids merge conflicts, nothing more.

## Dispatch Log

Append-only — one line per orchestrator event: date, issue, event (`dispatched` / `shipped` / `blocked` / `resumed`), short note (for `shipped`: the owner's one-line learnings summary and the PR URL).

## Blockers

One entry per blocked issue — the owner's report, copied verbatim. Delete the entry when the issue is unblocked (the Dispatch Log keeps the history).
