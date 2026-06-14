---
feature: benchmark-spec-driven-tools
plan: "[[plan]]"
spec: "[[spec]]"
created: 2026-06-14
---
# Benchmark Spec-Driven Tools — Tasks

**For this plan:** `[[plan]]`

## Phase 1: Spec & Plan

### Task 1: Spec authored and self-reviewed

- [x] Step 1: Write `spec.md` from the template
- [x] Step 2: Self-review — spec-document-reviewer subagent (clarity)
- [x] Step 3: Self-review — `/memex:review-spec` (constitution); address findings
- [x] Step 4: Write `plan.md` + `tasks.md`

## Phase 2: Deep analysis (Workflow, source-grounded)

### Task 2: Analyze + adversarially verify both tools

- [x] Step 1: Workflow fan-out — one analysis subagent per tool, reading the cloned source in `tmp/`, returning a structured, file-path-cited account (phases, artifacts, state/memory model, enforcement mechanisms, sub-agent strategy, lifecycle/archival, install/distribution)
- [x] Step 2: Per tool, an adversarial verify subagent re-reads source and flags any unsupported claim
- [x] Step 3: Collect verified accounts for both tools into the main thread

## Phase 3: Author tool learnings

### Task 3: TLC learning

- [x] Step 1: Write `.memex/learnings/tlc-spec-driven-workflow.md` — template frontmatter, ≥1 mermaid flow diagram, source-cited mechanics, cross-links
- [x] Step 2: Write `.memex/learnings/tlc-spec-driven-workflow.html` — standalone, mermaid via CDN
- [x] Step 3: Commit

### Task 4: OpenSpec learning

- [x] Step 1: Write `.memex/learnings/openspec-workflow.md` — template frontmatter, ≥1 mermaid flow diagram, source-cited mechanics, cross-links
- [x] Step 2: Write `.memex/learnings/openspec-workflow.html` — standalone, mermaid via CDN
- [x] Step 3: Commit

## Phase 4: Synthesize insights

### Task 5: memex improvement insights learning

- [x] Step 1: Re-read both finished tool learnings + memex flow (AGENTS.md, constitution, rules)
- [x] Step 2: Write `.memex/learnings/memex-improvement-insights.md` — capability comparison table (memex/TLC/OpenSpec), ranked ≥3 high-impact recommendations (each naming a memex artifact + behavioral change + impact rating), cross-links to both tool learnings + this spec, ≥1 mermaid diagram
- [x] Step 3: Write `.memex/learnings/memex-improvement-insights.html` — standalone visual companion
- [x] Step 4: Commit

## Phase 5: Wire & verify

### Task 6: Index, cross-link, verify

- [x] Step 1: Add three bullets to `.memex/_index/learnings.md` (path-qualified wikilinks + hooks) under a Benchmarks grouping
- [x] Step 2: Confirm reciprocal cross-links between the three learnings and the spec resolve (basename rules)
- [x] Step 3: Parse-check every mermaid block (`npx -y @mermaid-js/mermaid-cli` one-off, or documented fallback); record command + clean output
- [x] Step 4: `git status` — confirm nothing under `tmp/` is staged/tracked
- [x] Step 5: Commit

## Phase 6: Quality gate + reflect

### Task 7: Quality gate

- [x] Step 1: Run the vault checks relevant to touched areas (link/index integrity; `quick_validate` is for skills, not vault — note if N/A)
- [x] Step 2: Reflect — write a meta-learning to `.memex/learnings/` only if genuinely useful; else record "No new learnings"

## Phase 7: Deliver (autonomous)

### Task 8: PR + review to lgtm

- [ ] Step 1: `/memex:new-pr`
- [ ] Step 2: `memex:code-review` cycle to `lgtm`, hands-off
- [ ] Step 3: Mark spec `status: shipped` + `shipped:` date once merged-ready per flow
