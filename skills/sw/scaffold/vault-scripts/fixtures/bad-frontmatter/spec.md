---
status: draft
feature: sample-feature
created: 2026-06-14
shipped: null
branch: feat/sample-feature
mode: autonomous
related: []
---
# Sample Feature — Spec

**Status:** Draft
**Design:** [[design]]
**Scope:** A sample spec used to exercise the validator fixtures.

## Architecture

A single module that returns a greeting string.

## File Structure

- Create: `src/greet.ts` — the greeting function.

## Phase Ordering

Single phase.

## Constraints

None beyond the project defaults.

## User Stories / Scenarios

1. A caller invokes greet and receives a greeting.

## Acceptance Criteria

- [ ] **AC-1** `greet("world")` returns the exact string `Hello, world`.
- [ ] **AC-2** `greet("")` returns HTTP 400 with body `{"code":"EMPTY_NAME"}`.

## Risks and Mitigations

| Risk | Mitigation |
|---|---|
| none | none |

## Open Questions

None.
