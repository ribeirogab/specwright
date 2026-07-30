---
milestone: e2e-validation
created: 2026-07-02
---
# E2E Validation — Goal

> The stable *why* of the whole delivery — written once during the milestone brainstorm, after the decomposition is approved. Editing this file afterwards is a **scope change**: the orchestrator never does it on its own; a human decides. The live state (order, dependencies, blockers) lives in the sibling `board.md`; each issue's why lives in its own `issue.md`.

## Purpose

Validate the unified issues + milestones workflow end to end by exercising every contract of specwright — scope detection, milestone planning, `/sw:run` orchestration, the issue pipeline, learnings flow, circuit breakers, blocked recovery, closeout, the standalone-issue path, the command surface, and docs coherence — against a synthetic project (`taskr`, a todo-list CLI), producing a findings dossier for a follow-up fixes delivery.

## Motivation

The unified-issues-milestones delivery shipped (PRs #34 and #35) with per-issue verification but no full dogfood of the milestone loop as a whole. Before conducting real milestones with it, every contract must be observed in practice at least once; each divergence between documented and observed behavior must be captured while the delivery is fresh.

## Success Criteria

- Every scenario of the test plan (T1–T11) was executed against the sandbox and has a written verdict backed by evidence.
- Every failed check exists as a finding in the owning issue's `findings.md` with Expected / Observed / Proposed fix.
- The closeout consolidates all findings into one dossier ready to seed a follow-up fixes issue or milestone.

## Non-Goals

- Fixing the defects found — that is the follow-up delivery, planned from the consolidated findings.
- Testing the installer (`install.sh`) or `/sw:update` beyond the command-surface check.
- Performance, cost, or token-efficiency measurements of the workflow.
