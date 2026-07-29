---
milestone: {{kebab-slug-of-milestone}}
created: {{YYYY-MM-DD}}
---
# {{Milestone Name}} — Board

> The milestone's live state: issue order, dependencies, dispatch log, and blocker reports. The `sw:run` orchestrator reads and writes this file on every loop turn. Issue `status:` lives in each issue's own `issue.md` frontmatter — it is **never duplicated here**; the board holds only what has no other home.

## Issues

An issue is **ready** when its `issue.md` says `status: pending` and every dependency listed here says `status: shipped` in its own `issue.md` — read from the dependency's own branch while its PR is unmerged (the `main` copy stays `pending` until merge).

| Order | Issue | Depends on |
|---|---|---|
| 1 | {{slug}} | — |
| 2 | {{slug}} | {{slug}} |

## Dispatch Log

Append-only — one line per orchestrator event: date, issue, event (`dispatched` / `shipped` / `blocked` / `resumed`), short note (for `shipped`: the owner's one-line learnings summary and the PR URL).

- {{YYYY-MM-DD}} — {{slug}} — dispatched — {{note}}

## Blockers

One entry per blocked issue — the owner's paste-ready Blockers block (Why / Tried / Needs), pasted unmodified. Delete the entry when the issue is unblocked (the Dispatch Log keeps the history).

### {{slug}}

- **Why:** {{the gate or AC that failed three times identically}}
- **Tried:** {{the distinct attempts, one line each}}
- **Needs:** {{what the human must decide or provide}}
