---
status: draft
feature: benchmark-spec-driven-tools
created: 2026-06-14
shipped: null
branch: docs/benchmark-spec-driven-tools
mode: autonomous
related:
  - "[[tlc-spec-driven-workflow]]"
  - "[[openspec-workflow]]"
  - "[[memex-improvement-insights]]"
  - "[[agents-md-as-map-not-encyclopedia]]"
  - "[[mechanical-enforcement-over-prose]]"
  - "[[companion-skill-distribution-topology]]"
---
# Benchmark Spec-Driven Tools — Spec

**Status:** Draft
**Scope:** Deeply analyze two comparable spec-driven workflow tools (`tlc-spec-driven` and `OpenSpec`), capture each as a detailed visual learning, then distill one insights learning of concrete, high-impact improvements for memex.

## Context

memex is a spec-driven workflow tool: it scaffolds a `.memex/` vault and an `AGENTS.md` that runs every non-trivial change through `brainstorm → spec → plan → tasks → implement → quality gate → PR → review`. Two other tools occupy adjacent ground and have made different design choices worth learning from:

- **`tlc-spec-driven`** (Tech Lead's Club) — a single markdown skill, like memex, but with a 4-phase auto-sizing pipeline (Specify → Design → Tasks → Execute), brownfield codebase mapping, persistent `STATE.md` memory, and explicit sub-agent delegation rules. Same medium as memex (markdown skill), different workflow shape.
- **`OpenSpec`** (Fission-AI) — a TypeScript CLI (`openspec`) with a change-proposal model, JSON schemas, validation commands, an archive lifecycle, and multi-agent/multi-tool config generation. Different medium (compiled CLI + schemas), heavier on mechanical enforcement.

Studying how each structures the same fundamental problem — turning intent into verified, shipped change with durable memory — surfaces design moves memex can adopt. The maintainer wants this captured as durable, *visual* vault knowledge (mermaid + optional HTML), not a throwaway chat answer.

## Problem Statement

memex's design decisions are currently informed mostly by first principles and the harness-engineering literature. There is no captured comparative analysis of how peer spec-driven tools solve the same problems, so improvement ideas are ad-hoc. This spec produces (a) two reference learnings that document how each peer tool actually works, end-to-end, in a form a reader can grasp at a glance, and (b) one insights learning that converts that comparison into a short list of concrete, high-impact changes to the memex flow.

## Non-Goals

- **Not** implementing any change to the memex skill, AGENTS.md, plugin, or scaffold. This spec produces *analysis and recommendations only* — implementing the insights is future, separate specs.
- **Not** an exhaustive line-by-line code audit of either tool's source. Depth target is "understand how the developer-facing flow works and every meaningful design decision behind it," not "document every function."
- **Not** a marketing/popularity comparison (stars, downloads, adoption). The benchmark is about workflow design and mechanics.
- **Not** vendoring or copying either tool's code/content into memex. The cloned repos live in `tmp/` (gitignored) and are not committed.
- **Not** a generic PKM/spec-tooling survey. Only the two named tools.

## Constraints

- **Markdown is source of truth** (constitution): each learning is a `.md` file; the `.html` companion is an optional visual enhancement that must not be the sole home of any fact.
- **Vault conventions**: learnings follow `.memex/templates/learning.md` frontmatter (`tags`, `related`, `created`), are indexed in `.memex/_index/learnings.md`, and cross-link via `[[wikilink]]`. Link identity is basename-keyed (see [[vault-link-identity-is-basename-keyed]]).
- **English** for all committed artifacts (constitution).
- **Knowledge layering** (constitution): these learnings are memex-specific reference (a benchmark done to evolve memex), not generic patterns — framed accordingly.
- **No new repo tooling**: HTML files are standalone (self-contained, open in a browser, no build step, no external runtime deps beyond a CDN mermaid script).
- **Autonomous mode**: deliver through to an opened, reviewed PR without further human input.

## User Stories / Scenarios

1. A maintainer evaluating a memex change opens `.memex/learnings/tlc-spec-driven-workflow.md`, sees a mermaid diagram of the full TLC flow, and understands TLC's auto-sizing pipeline without reading TLC's source.
2. Same for `.memex/learnings/openspec-workflow.md` and OpenSpec's change-proposal lifecycle.
3. A maintainer planning the next memex iteration opens `.memex/learnings/memex-improvement-insights.md`, sees a side-by-side capability comparison and a ranked list of concrete improvements, each tagged with impact and the source tool that inspired it.
4. A reader who prefers visuals opens the matching `.html` file next to any of the three learnings and gets a richer rendered view (rendered mermaid, comparison tables, flow visuals).

## Acceptance Criteria

- [ ] `.memex/learnings/tlc-spec-driven-workflow.md` exists, follows the learning template frontmatter (`tags`, `related`, `created: 2026-06-14`), and contains at least one mermaid diagram of TLC's development flow.
- [ ] `.memex/learnings/openspec-workflow.md` exists, follows the template frontmatter, and contains at least one mermaid diagram of OpenSpec's development/change-proposal flow.
- [ ] `.memex/learnings/memex-improvement-insights.md` exists, follows the template frontmatter, cross-links both tool learnings via `[[wikilink]]`, and contains (a) a capability comparison table across memex / TLC / OpenSpec and (b) a ranked list of ≥3 concrete improvement recommendations, each of which names a specific memex artifact (AGENTS.md section, a named skill, the spec/learning template, etc.), states the concrete behavioral change to that artifact, and carries an explicit impact rating (high/medium). Recommendations with small or unclear impact are dropped, not listed.
- [ ] Each of the three `.md` learnings has a sibling `.html` file of the same basename (`tlc-spec-driven-workflow.html`, `openspec-workflow.html`, `memex-improvement-insights.html`) that opens standalone in a browser and renders its mermaid diagram(s).
- [ ] Every mermaid code block across all three `.md` files parses without error, verified by running `npx -y @mermaid-js/mermaid-cli` (one-off via `npx`, never installed to the repo root — honors the no-build-pipeline constitution rule) over each extracted diagram; the exact command and its clean exit-0 output are recorded in a task note / the PR description. A manual browser glance does not satisfy this criterion.
- [ ] All three learnings are indexed in `.memex/_index/learnings.md` under an appropriate section, each as a one-line bullet with a path-qualified wikilink and a hook.
- [ ] The three learnings cross-link each other where relevant via `[[wikilink]]`, and the insights learning links back to this spec (`[[spec]]` path-qualified per basename rules).
- [ ] The insights learning contains only recommendations that change the memex flow/process; each names the concrete memex artifact it would touch (AGENTS.md section, a skill, the spec template, etc.) and the specific behavioral change. No vague "consider improving X" entries.
- [ ] `tmp/` clones are not committed: `git status` shows no files under `tmp/` staged or tracked by this branch.
- [ ] A PR is opened via `/memex:new-pr` and the `memex:code-review` cycle reaches `lgtm`.

## Risks and Mitigations

| Risk | Mitigation |
|---|---|
| Subagents produce shallow or inaccurate analysis (hallucinated mechanics) | Each analysis subagent works from the actual cloned source in `tmp/`, cites file paths, and a verification subagent adversarially checks claims against the source before the learning is finalized. |
| Insights learning becomes a wishlist of low-impact ideas | Acceptance criteria force an explicit impact rating + named target artifact per item; insights with small/unclear impact are dropped, per the user's directive. |
| HTML files duplicate/diverge from the `.md` source of truth | `.md` holds every fact; `.html` is presentation only. Mermaid source is identical in both. |
| Mermaid diagrams fail to render (syntax errors) | Mandatory parse-check acceptance criterion across all diagrams before PR. |
| Learnings drift from vault conventions (frontmatter, indexing, links) | Reuse `.memex/templates/learning.md`; run the vault link/index checks; spec self-review covers it. |
| Knowledge-layering objection (competitor analysis vs. memex-specific) | Frame the two tool learnings explicitly as a memex benchmark whose purpose is to evolve memex; the insights learning is unambiguously memex-specific. |

## Open Questions

None. The user specified the deliverable shape (two tool learnings + one insights learning, all visual with mermaid, optional HTML), the mode (autonomous), and the stopping condition (PR opened and reviewed).
