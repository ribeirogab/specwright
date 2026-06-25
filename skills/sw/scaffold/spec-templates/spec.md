---
status: draft
feature: {{kebab-slug-of-feature}}
scope: {{low | medium | high | complex}}
created: {{YYYY-MM-DD}}
shipped: null
branch: {{feat/kebab-slug-of-feature}}
mode: {{autonomous | reviewed}}
worktree: {{.specwright/worktrees/<slug> | null}}
---
# {{Feature Name}} — Spec

**Status:** Draft
**Design:** see the sibling `design.md`
**Scope:** {{one-sentence scope statement}}

> **Note on `scope:` frontmatter** — `scope` is one of `low | medium | high | complex`. It is **recorded only**: reserved for a future quick-mode and does **not** yet gate which artifacts are written. Set it honestly; nothing branches on it today.
>
> **Note on `worktree:` frontmatter** — the path of this spec's git worktree under `.specwright/worktrees/`, or `null` when the work runs in place. **Recorded only**: like `scope:`, nothing branches on it and `validate-spec.sh` does not require it.

This is the **technical** spec — the *how*. The non-technical *why* (purpose, motivation, definitions, non-goals) lives in `design.md`.

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

Number each criterion `AC-1`, `AC-2`, … — the IDs are stable handles that `tasks.md` references (each task names the `AC-N` it satisfies) and that `/sw:code-review` walks to prove every criterion was delivered. Each criterion must be a binary, observable check that someone other than the implementer can verify in under a minute. **No vague verbs** ("works well", "is fast", "is robust", "handles errors gracefully") — replace them with specific, measurable conditions. If a criterion cannot be verified without reading the implementation, it is not an acceptance criterion; rewrite it.

- [ ] **AC-1** {{ e.g. `POST /users` with a duplicate email returns 409 and body `{"code":"DUPLICATE_EMAIL"}` }}
- [ ] **AC-2** {{ e.g. p95 latency for `GET /feed` stays under 200ms with a 1k-row fixture }}
- [ ] **AC-3** {{ e.g. the migration script runs idempotently — running it twice on the same DB yields no diff }}
- [ ] **AC-N** {{ ... }}

Tick each `[x]` when verified. A spec is **not shippable** with empty or `{{placeholder}}` acceptance criteria — `validate-spec.sh` and `/sw:review-spec` will reject it.

## Risks and Mitigations

| Risk | Mitigation |
|---|---|
| {{risk}} | {{mitigation}} |

## Open Questions

{{use [NEEDS CLARIFICATION: specific question] markers for unresolved points; write `None.` if there are none — silence is not resolution}}
