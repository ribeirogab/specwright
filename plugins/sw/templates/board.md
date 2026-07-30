---
delivery: {{kebab-slug-of-delivery}}
created: {{YYYY-MM-DD}}
---
# {{Delivery Name}} — Board

> The delivery's live state: change order, dependencies, dispatch log, and blocker reports. The `sw:run` orchestrator reads and writes this file on every loop turn. Change `status:` lives in each change's own `change.md` frontmatter — it is **never duplicated here**; the board holds only what has no other home.

## Changes

A change is **ready** when its `change.md` says `status: pending` and every dependency listed here says `status: shipped` in its own `change.md`. In shared mode, read an unmerged dependency from its own branch or worktree because the `main` copy stays `pending` until merge. In local mode, read the canonical ignored vault in the orchestrator checkout; copied worktree vaults are transport snapshots, not delivery state.

| Order | Change | Depends on |
|---|---|---|
| 1 | {{slug}} | — |
| 2 | {{slug}} | {{slug}} |

## Dispatch Log

Append-only — one line per orchestrator event: date, change, event (`dispatched` / `shipped` / `blocked` / `resumed`), short note (for `shipped`: the owner's one-line learnings summary and the PR URL).

- {{YYYY-MM-DD}} — {{slug}} — dispatched — {{note}}

## Blockers

One entry per blocked change — the owner's paste-ready Blockers block (Why / Tried / Needs), pasted unmodified. Delete the entry when the change is unblocked (the Dispatch Log keeps the history).

### {{slug}}

- **Why:** {{the gate or AC that failed three times identically}}
- **Tried:** {{the distinct attempts, one line each}}
- **Needs:** {{what the human must decide or provide}}
