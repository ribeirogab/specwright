---
feature: {{kebab-slug-of-issue}}
created: {{YYYY-MM-DD}}
scope: {{low | medium | high | complex}}
branch: {{feat/kebab-slug-of-issue}}
worktree: {{.specwright/worktrees/<slug> | null}}
milestone: {{.specwright/milestones/YYYY-MM-DD-<slug> | null}}
---
# {{Issue Name}} — Spec

**Issue:** see the sibling `issue.md` (the *why*, the acceptance criteria, and the issue `status:`)
**Scope:** {{one-sentence scope statement}}

> **Note on `scope:` frontmatter** — `scope` is one of `low | medium | high | complex`. It is **recorded only**: reserved for a future quick-mode and does **not** yet gate which artifacts are written. Set it honestly; nothing branches on it today.
>
> **Note on `worktree:` frontmatter** — the path of this issue's git worktree under `.specwright/worktrees/`, or `null` when the work runs in place. **Recorded only**, like `scope:`.
>
> **Note on `milestone:` frontmatter** — the milestone folder this issue belongs to, or `null` for a standalone issue.

This is the **technical** spec — the *how*. The non-technical *why*, the acceptance criteria, and the status live in `issue.md`.

## Architecture

{{the high-level technical approach and why it was chosen over alternatives; diagrams, component breakdown, data flow}}

## File Structure

{{files to be created, modified, or deleted, with one-line responsibilities}}

## Phase Ordering

{{if the work has natural phases, list them with dependencies; otherwise "Single phase."}}

## Constraints

{{technical, organizational, or timing constraints that shape the solution}}

## User Stories / Scenarios

{{numbered user flows or acceptance scenarios}}

## Acceptance Criteria

The acceptance criteria live in the sibling `issue.md` — the `AC-N` IDs defined there are the contract `tasks.md` references and `/sw:review` walks. Do not duplicate them here; if writing this spec exposed a missing or wrong criterion, fix `issue.md`.

## Risks and Mitigations

| Risk | Mitigation |
|---|---|
| {{risk}} | {{mitigation}} |

## Open Questions

{{use [NEEDS CLARIFICATION: specific question] markers for unresolved points; write `None.` if there are none — silence is not resolution}}
