---
feature: unified-issues-milestones
created: 2026-07-01
status: shipped
shipped: 2026-07-01
---
# Unified Issues + Milestones — Design

> Non-technical write-up of the **already-approved** design — purpose, motivation, definitions, non-goals. The technical *how* (architecture, file structure, acceptance criteria) lives in the sibling `spec.md`.

## Purpose

Make the **issue** specwright's single unit of work (1 issue = 1 branch = 1 PR), replacing the spec-folder flow entirely, and add a **milestone** layer above it: a large delivery decomposed into issues and conducted end-to-end by an **orchestrator loop** that dispatches issue-owner subagents, tracks progress on a live board, carries knowledge between issues, and stops itself when it stops making progress.

After this delivery a developer has one entry point (`/sw:brainstorm` or `/sw:spec`), and the shape of the work — standalone issue or milestone — is a conclusion of the design conversation, not a command choice. A milestone then runs with exactly one human gate (the decomposition approval); the human returns to merge PRs or when a circuit breaker escalates.

## Motivation

Today the human **is** the loop. A delivery that spans several related specs requires the user to open N brainstorming sessions, re-explain context N times, remember what the next part is, and notice when something broke. Meanwhile each spec starts from zero: nothing carries what spec 1 discovered into spec 2's plan, nothing detects an agent stuck re-trying the same failing fix, and the quality gate is purely static — the code is never run for real before the PR opens.

Loop-engineering practice (June 2026: Steinberger, Osmani, Cherny) names the missing pieces: a testable termination condition per iteration (specwright already has this — the `AC-N`), fresh context per iteration, durable memory between iterations, circuit breakers against stagnation, and escalation reports instead of thrashing. This delivery folds those pieces into specwright's existing pipeline instead of inventing a parallel one.

The unification (specs → issues) exists because running two vocabularies side by side — "specs" standalone, "issues" inside milestones — would make every skill, doc, and template explain both. One unit, one folder shape, everywhere.

## Definitions

- **Issue** — the unit of work: one folder holding `issue.md` (ticket: purpose + acceptance criteria + status), `spec.md` (technical plan), `tasks.md` (implementation steps), and optionally `learnings.md`. One issue = one branch = one PR.
- **`issue.md`** — replaces the old `design.md`: the approved *why* plus `AC-N` and the only home of `status:` (`pending | in-progress | shipped | blocked`).
- **Milestone** — a large delivery grouping issues: `goal.md` (stable why + milestone success criteria), `board.md` (live state: order, dependencies, blocker reports), and `issues/<slug>/` folders.
- **Ready** — an issue whose status is `pending` and whose dependencies are all `shipped`; the orchestrator dispatches every ready issue.
- **Milestone orchestrator** — the `/sw:run` role. Never touches code: reads the board, dispatches issue owners, tracks, records, reports, escalates.
- **Issue owner** — one subagent per issue, owning its whole pipeline (plan → implement → gates → PR → review → learnings). Judges by `tasks.md` whether to implement inline or fan out `Delegable:` tasks to **task workers**, who report findings and never write learnings.
- **Learnings** — non-obvious facts future issues need, curated by the issue owner into the issue's own `learnings.md`. Consumed by `/sw:plan` of later issues. Durable ones are **promoted** to `AGENTS.md`/conventions at milestone closeout, with user approval.
- **Runtime verification** — pipeline step after the quality gate: execute the built thing and check each `AC-N` by observed behavior (browser for UI when the agent has the capability; otherwise mark `needs-human-verification`, never fake it).
- **Circuit breaker** — three identical failures on the same gate/AC → `status: blocked` + a report (why / what was tried / what it needs) on the board; the orchestrator skips to the next ready issue and halts only when none remain.
- **Command surface** — eight imperative commands: `brainstorm · spec · plan · run · review · review-spec · pr · update` (renamed from `brainstorming`, `writing-plans`, `code-review`, `new-pr`).

## Non-Goals

- **No migration of existing spec folders.** `.specwright/specs/` history (including this delivery's own artifacts) is migrated to the new layout in a separate session driven by `tmp/migration-handoff.txt`. This delivery changes the tooling, not the historical data.
- **No mode knob.** `autonomous`/`reviewed` is removed everywhere; there is one path — the loop. Human control = design approval, PR merges, circuit breakers, and interrupting the agent.
- **No concurrency cap.** The orchestrator dispatches all ready issues; the natural limits are dependencies and the user's PR-review queue.
- **No nested sub-issues.** A task that deserves its own PR is a sign the issue was too fat — promote it to an issue on the board.
- **No external shell driver, no cron/scheduling.** The loop is protocol-in-markdown; any fresh session resumes via `/sw:run` because all state lives in files.
- **No Linear/GitHub Issues sync.**
- **No renaming of `spec.md`/`tasks.md`** — the technical artifacts keep their names; only the unit vocabulary and the dead `design.md` change.
