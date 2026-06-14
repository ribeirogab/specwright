---
feature: benchmark-spec-driven-tools
spec: "[[spec]]"
created: 2026-06-14
---
# Benchmark Spec-Driven Tools — Plan

**For this spec:** `[[spec]]`

## Approach

The work is research-then-synthesis, and the maintainer asked explicitly for subagents to do the deep digging. So the architecture is a **fan-out / verify / synthesize pipeline** run via the Workflow tool, with the cloned source as ground truth:

1. **Fan-out (per tool, in parallel):** one analysis subagent reads the actual cloned source of each tool in `tmp/` and returns a structured account of its workflow — phases, artifacts, state model, enforcement mechanisms, sub-agent strategy, lifecycle — with file-path citations. Running the two tools concurrently is the natural shape: they are independent.
2. **Adversarial verify (per tool):** a second subagent re-reads the source and checks the first's claims, catching hallucinated mechanics before anything is written to the vault. This is the project's "adversarially verify findings" discipline applied to research.
3. **Author the tool learnings:** turn each verified account into a `.md` learning (template frontmatter, mermaid flow diagram(s), cross-links) plus a standalone `.html` companion (rendered mermaid via CDN, comparison-friendly visuals). The `.md` is source of truth; `.html` is presentation.
4. **Synthesize insights:** a final step reads both finished tool learnings + the memex flow (AGENTS.md, constitution, rules) and produces the third learning — a capability comparison table and a ranked, high-impact-only recommendation list, each item naming a concrete memex artifact and behavioral change.
5. **Wire + verify the vault:** index all three in `.memex/_index/learnings.md`, confirm cross-links, parse-check every mermaid block, confirm `tmp/` stays uncommitted.

Why a workflow rather than ad-hoc subagent calls: the deep-analysis step benefits from determinism (clone is fixed, each tool gets the same treatment) and from the verify stage gating the authoring stage. The main thread stays the orchestrator/author so the synthesis is coherent (per TLC's own "planning/synthesis needs full context — don't delegate it" rule, which we are also about to learn from).

Authoring of the `.md`/`.html` files is done by the **main thread** (not subagents) so the three learnings share a consistent voice, frontmatter, and visual system, and so cross-links resolve correctly — synthesis and final wording are exactly the activities TLC flags as "do not delegate."

## Architecture

```
tmp/ (gitignored clones)
  ├── tlc-agent-skills/.../tlc-spec-driven/   ──┐
  └── openspec/                                 │
                                                ▼
           Workflow: analyze → verify  (2 tools in parallel)
                                                │
                          structured, source-cited accounts
                                                ▼
        Main thread authors:                    │
          .memex/learnings/tlc-spec-driven-workflow.{md,html}
          .memex/learnings/openspec-workflow.{md,html}
                                                ▼
        Main thread synthesizes:
          .memex/learnings/memex-improvement-insights.{md,html}
                                                ▼
        Wire: index + cross-links + mermaid parse-check + tmp/ clean
```

## File Structure

**Created (committed):**
- `.memex/specs/2026-06-14-benchmark-spec-driven-tools/spec.md` — this spec (done)
- `.memex/specs/2026-06-14-benchmark-spec-driven-tools/plan.md` — this file
- `.memex/specs/2026-06-14-benchmark-spec-driven-tools/tasks.md` — task breakdown
- `.memex/learnings/tlc-spec-driven-workflow.md` — TLC analysis (+ mermaid)
- `.memex/learnings/tlc-spec-driven-workflow.html` — TLC visual companion
- `.memex/learnings/openspec-workflow.md` — OpenSpec analysis (+ mermaid)
- `.memex/learnings/openspec-workflow.html` — OpenSpec visual companion
- `.memex/learnings/memex-improvement-insights.md` — synthesis (+ mermaid, comparison table)
- `.memex/learnings/memex-improvement-insights.html` — synthesis visual companion

**Modified (committed):**
- `.memex/_index/learnings.md` — add three index bullets
- `.memex/specs/2026-06-14-benchmark-spec-driven-tools/spec.md` — flip `status`/`shipped` at the end if the flow does so

**Used but NOT committed:**
- `tmp/tlc-agent-skills/`, `tmp/openspec/` — clones, gitignored, ground truth for subagents

## Phase Ordering

1. **Spec & plan** (this phase) — spec written + self-reviewed; plan + tasks. *No dependency.*
2. **Deep analysis** — Workflow fan-out: analyze + adversarially verify each tool from source. *Depends on clones existing (done).*
3. **Author tool learnings** — write the two `.md` + `.html` pairs from verified accounts. *Depends on phase 2.*
4. **Synthesize insights** — write the third `.md` + `.html`. *Depends on phase 3 (reads both tool learnings).*
5. **Wire & verify** — index, cross-link, mermaid parse-check, tmp/ clean check. *Depends on phases 3–4.*
6. **Quality gate + reflect** — run vault checks; write meta-learning if genuinely useful. *Depends on phase 5.*
7. **Deliver** — `/memex:new-pr` + `memex:code-review` to `lgtm` (autonomous). *Depends on phase 6.*

## Risks / Open Decisions

- **Mermaid parse check in a no-build repo.** Decision: use `npx -y @mermaid-js/mermaid-cli` one-off (never installed to root). If its headless-chromium download is blocked in the sandbox, fall back to a one-off node parse via the `mermaid`/`@mermaid-js/parser` package; either way the command + clean output is recorded. The HTML files render mermaid from a CDN, which is the user-facing proof.
- **HTML visual system.** Decision: one shared inline-CSS look across the three HTML files (dark theme, mermaid via CDN `https://cdn.jsdelivr.net/npm/mermaid`), no external assets, no build. Self-contained per constitution.
- **Tag taxonomy for the new learnings.** Decision: the two tool analyses tag `learning` + `reference` (they document external tools); insights tags `learning` + `concept`. Index them under a new "Benchmarks" grouping in `learnings.md` to keep them discoverable without polluting the architecture section.
- **Depth ceiling.** Per Non-Goals, stop at "how the flow works + every meaningful design decision," not a function-level audit. The verify stage enforces accuracy, not exhaustiveness.
