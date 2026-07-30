---
milestone: specwright-fixes
created: 2026-07-02
---
# Specwright Fixes — Goal

> The stable *why* of the whole delivery — written once during the milestone brainstorm, after the decomposition is approved. Editing this file afterwards is a **scope change**: the orchestrator never does it on its own; a human decides. The live state (order, dependencies, blockers) lives in the sibling `board.md`; each issue's why lives in its own `issue.md`.

## Purpose

Convert everything the e2e validation milestone proved to be emergent, broken, or unspecified into explicit contract text: the run skill's conduction rules, the issue pipeline's integrity guarantees, the brainstorm's planning-artifact quality bar, install parity between the two documented install paths, and honest documentation. It also delivers one user-requested capability: a standard visual progress panel for long conductions.

## Motivation

The e2e validation milestone (2026-07-02) ran the full workflow against a live fixture and consolidated roughly thirty findings. The severe ones share a shape: agents repeatedly did the right thing that the skill text never asks for (reading a dependency's status from its own branch, reconciling a stale goal with approval) or did the wrong thing the text fails to forbid (rewording an approved acceptance criterion, probing PR creation with a junk payload). Behavior that exists only by good judgment regresses silently; this delivery pins it down while the evidence is fresh.

## Success Criteria

- Every high-severity finding from the validation dossier is closed by shipped contract text, and every medium one is either closed or explicitly declined in the record.
- A conductor following only the run skill's letter would reproduce the behaviors the validation had to observe emerging: round-scoped approvals, branch-aware readiness, executable recovery instructions, state polling instead of waiting on notifications, and goal reconciliation at closeout.
- An issue owner following only the plan and pr skills' letter cannot silently reword an approved criterion, skip recording the self-review gates, or end a degraded delivery without a durable record of what was verified.
- A fresh install performed by the letter of either documented install path yields a working mechanical gate and every documented command form resolving to a real skill.
- During a milestone conduction, progress is readable at a glance in a consistent visual format, and every status update ends with a compact progress line.

## Non-Goals

- No changes to the validation milestone's test plan or fixtures — rerun notes stay in the dossier.
- No changes to session-driving methodology conventions (relay hygiene, verbatim capture); they remain recorded practice, not skill text.
- No new capabilities beyond the progress panel.
- Merging the resulting PRs remains the maintainer's.
