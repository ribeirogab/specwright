---
delivery: {{kebab-slug-of-delivery}}
created: {{YYYY-MM-DD}}
---
# {{Delivery Name}} — Delivery

> The whole outcome: its stable *why* on top, its live state below. The *why* sections are written once, when the decomposition is approved — rewriting them afterwards is a **scope change** only a human decides. The state sections below are the orchestrator's working surface, updated every loop turn. Each change's own *why* lives in its `change.md`.

## Purpose

{{what this delivery delivers as a whole, in plain language}}

## Motivation

{{why this delivery exists now — what triggered it, what it unlocks}}

## Success Criteria

{{delivery-level: how to know the WHOLE delivery is done — not per-change acceptance criteria. In behavior terms only: no file paths, function names, or storage formats — path-level constraints belong in the change tickets. e.g. "a customer can create, apply, and receive a coupon end to end"}}

## Non-Goals

{{what this delivery explicitly does NOT cover}}

## Changes

A change is **ready** when its own `change.md` says `status: pending` and every dependency below says `status: shipped` in its own `change.md`. Status lives there and is **never duplicated here**. In shared mode an unmerged dependency is read from its own branch or worktree, because the copy on `main` still says `pending` until merge; in local mode it is read from the canonical ignored vault in the orchestrator's checkout.

| Order | Change | Depends on |
|---|---|---|
| 1 | {{slug}} | — |
| 2 | {{slug}} | {{slug}} |

## Dispatch log

Append-only — one line per orchestrator event: date, change, event (`dispatched` / `shipped` / `blocked` / `resumed`), and a short note. For `shipped`, the note carries the PR URL and any decision the owner reported that affects another change.

- {{YYYY-MM-DD}} — {{slug}} — dispatched — {{note}}

## Blockers

One entry per blocked change — the owner's paste-ready block, pasted unmodified. Delete the entry when the change is unblocked; the dispatch log keeps the history.

### {{slug}}

- **Why:** {{the gate or criterion that failed three times identically}}
- **Tried:** {{the distinct attempts, one line each}}
- **Needs:** {{what the human must decide or provide}}
