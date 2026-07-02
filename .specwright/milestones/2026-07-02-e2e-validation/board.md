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

## Blockers

One entry per blocked issue — the owner's report, copied verbatim. Delete the entry when the issue is unblocked (the Dispatch Log keeps the history).
