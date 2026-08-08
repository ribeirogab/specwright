---
feature: {{kebab-slug-of-change}}
---
# {{Change Name}} — Design

**Proposal:** see the sibling `proposal.md` for the *why*, the acceptance criteria, and the change `status:`.

> The technical *how*, written for **an agent with no memory of the conversation that produced it**. This file is written once and read many times: it is the architecture, not the progress. The task checklist and its checkboxes live in `tasks.md`, so a run in flight churns that file and leaves this one alone — an edit here after implementation starts is an architecture change, and it should be as visible as one.
>
> This file exists only when `tasks.md` declares a `scope:` other than `low`. A `low`-scope change carries its constraints in `tasks.md` and nothing else; inventing an architecture document for work that has no architecture is overhead, not rigor.

## Architecture

{{the technical approach and why it beat the alternatives; component breakdown, data flow, the patterns of this codebase it follows}}

## File Structure

{{every file created, modified, or deleted, with a one-line responsibility each}}

## Phase Ordering

{{natural phases with their dependencies, or "Single phase."}}

## Constraints

{{technical, organizational, or timing constraints that shape the solution — including any recorded in a sibling change's decisions}}
