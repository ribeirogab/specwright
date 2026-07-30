---
milestone: claude-only-plugin
created: 2026-07-03
---
# Claude-only Plugin — Board

> The milestone's live state: issue order, dependencies, dispatch log, and blocker reports. The orchestrator (`/sw:run`) reads and writes this file on every loop turn. Issue `status:` lives in each issue's own `issue.md` frontmatter — it is **never duplicated here**; the board holds only what has no other home.

## Conduction policy

- **Implementation** runs on **Sonnet 5** at **medium** effort — dispatch every issue-owner sub-agent with that model.
- **Review** (`/sw:review`) runs on **Opus 4.8** at **xhigh** effort.

## Issues

An issue is **ready** when its `issue.md` says `status: pending` and every dependency listed here says `status: shipped` in its own `issue.md` — read from the dependency's own branch while its PR is unmerged (the `main` copy stays `pending` until merge).

| Order | Issue | Depends on |
|---|---|---|
| 1 | plugin-only-restructure | — |
| 2 | rewrite-sw-init | plugin-only-restructure |
| 3 | remove-sw-update | plugin-only-restructure |
| 4 | docs-and-install-flow | rewrite-sw-init, remove-sw-update |

Dispatch order: 1 first; 2 and 3 run in parallel once 1 ships; 4 closes out once 2 and 3 ship.

## Dispatch Log

Append-only — one line per orchestrator event: date, issue, event (`dispatched` / `shipped` / `blocked` / `resumed`), short note (for `shipped`: the owner's one-line learnings summary and the PR URL).

- (none yet)

## Blockers

One entry per blocked issue — the owner's paste-ready Blockers block (Why / Tried / Needs), pasted unmodified. Delete the entry when the issue is unblocked (the Dispatch Log keeps the history).

- None.
