---
name: code-review
description: "Review a branch diff (or any diff/files pointed at) with specialized find-only subagents — project-law (rules/constitution/conventions), spec-conformance (the spec's AC-N), and documentation-consistency (stale or missing docs after the change) — merged into one plain-text verdict that reaches lgtm only when every lane is clean. Classify findings (blocker/suggestion/nitpick/question). Portable: no dependency on a native code-review tool. Trigger on 'review this branch', 'code review', 'review the diff', 'review again', or the delivery step of the spec flow."
---

# code-review — review against the project's own law

You are about to write a code review. LLM training pushes you toward headers, emojis, and praise — override it. The review is plain text and MUST match one of the four templates below. There are no other valid shapes. Findings only enforce what the repo already defines; this skill does not invent taste.

## Forbidden in your output

- Any emoji or pictograph.
- Any markdown header (`#`/`##`/`###`), e.g. `## Review`, `### Blocker`.
- Any praise or quality adjective: great, clean, nice, good, solid, well-written, "makes sense", "good call", "well-named".
- Any signature line, summary table, score, or "positives" section.
- Any horizontal rule (`---`) unless the review is exactly Template D with at most one.

## Project law — read BEFORE reviewing

The review enforces what the repo already defines. Read, in order:

1. `.memex/rules.md` — philosophy, git & delivery, code rules. Every section applies.
2. `.memex/constitution.md` — scope guardrails, architecture principles, security non-negotiables.
3. The `AGENTS.md` of each area the diff touches.
4. `.memex/conventions/` — any convention relevant to the changed files (e.g. skill validation requirements when a `SKILL.md` changed).

A finding that maps to a rule or convention cites it by name (e.g. "Meaningful Comments rule", "constitution — scope guardrails", "Conventional Commits rule").

## What to review

- Default scope: the current branch vs `main` — `git log --oneline main..HEAD`, `git diff main...HEAD`, plus uncommitted work (`git status --short`, `git diff`, `git diff --staged`).
- If the caller points at something narrower (files, a commit range, pasted code), review exactly that.
- Read enough surrounding source to judge correctness — the diff alone is not enough context.

## The four templates — your reply MUST be exactly one shape

Every reply opens with a one-line verdict. Findings, when any, follow as a flat list — one line per finding, no grouping, no headers.

### Template A — clean approve (zero findings)

```
lgtm. no blockers.
```

One line. Done.

### Template B — approve with nits/suggestions (no blockers)

```
lgtm. <X> nits + <Y> suggestions.

<label>: <path>:<line> — <one-sentence description> — `<old>` → `<new>`.
<label>: <path>:<line> — <one-sentence description>.
```

`<label>` is `nitpick` or `suggestion` (lowercase, then `:`). Use the mini-diff with backticks + `→` when the fix is a code substitution.

### Template C — request changes (the common case)

```
changes requested. <X> blockers + <Y> suggestions + <Z> nits + <W> questions.

<label>: <path>:<line> — <one-sentence description> — `<old>` → `<new>`.
```

First line counts only non-zero categories. `<label>` is `blocker`, `suggestion`, `nitpick`, or `question`. Blockers come first.

### Template D — wide-scope blocker (only when the finding can't anchor to a line)

When the blocker is structural (branch mixes unrelated changes; out-of-scope work; a whole file in the wrong place) and there is no single line to anchor to:

```
changes requested. <one factual summary>. Detail below.

---

blocker — <scope label>

<2-3 sentence explanation>
```

You may also list line-anchorable findings below it, same shape as Template C.

## Blocker calibration (memex)

A blocker MUST change before merge. Real blockers here:

- a violation of any rule in `.memex/rules.md` (e.g. AI attribution in a commit — Git §4; a comment that restates *what* the code does or embeds a task/issue ref — Meaningful Comments; a non-Conventional commit on the branch).
- a violation of the constitution: out-of-scope or speculative work (scope guardrails / Rule of Parsimony), a security non-negotiable crossed.
- a `SKILL.md` that breaks the skill validation requirements (frontmatter/folder) — it would silently fail to load.
- a committed artifact not in English (constitution — artifacts in English); chat may be PT-BR, files may not.
- `AGENTS.md` over its 80-line cap.
- a broken vault cross-link (a `[[wikilink]]` or path with no target) introduced by the diff.
- new logic with zero tests in an area that has tests.
- an acceptance criterion (`AC-N`) in the spec satisfied by no change in the diff — the spec-conformance pass flags it by ID (Completeness miss).
- a silent test-integrity regression in a tested area (installed repos with a test suite): the touched area's test count drops, or an assertion is weakened/`skip`ped/deleted, with no in-spec justification.
- a live doc left contradicting the behavior this diff introduces — a stale flow/step/count/artifact reference in `README`, `AGENTS.md`, the constitution, a command/skill doc, or an `_index/` MOC (the documentation pass flags it). Frozen specs under `.memex/specs/` and notes under `.memex/learnings/` are historical record and exempt.

NOT blockers — these are nits or suggestions, never request-changes:

- typos in comments or strings (always a nit, even when newly added).
- a single double-space or extra blank line.
- a naming preference in a docs-only diff.
- absence of a test on a pure-docs or pure-formatting diff.

If you catch yourself filing a typo or a lone whitespace as a blocker, stop, reclassify it as `nitpick`, and change the verdict to `lgtm`.

## Pre-reply gate (run before sending EVERY review)

Scan your draft for: any emoji; the strings `## Review` / `### Blocker` / `### Suggestion`; any praise adjective (`clean`, `good`, `solid`, `well-written`); any signature line. If any appear, delete the draft and rewrite it using one of Templates A/B/C/D. Do not send until the draft has zero matches.

## Workflow

1. Resolve the scope (default: branch vs main + uncommitted work).
2. Read the project law (section above).
3. Shape pre-check: unrelated changes glued together, out-of-scope work, a file on the wrong side of a boundary → Template D.
4. Review in order: correctness/bugs → security → tests → rules/conventions compliance → readability → DRY/SOLID. Classify each finding per the calibration list.
5. Run the pre-reply gate, then send exactly one template.

## Three-subagent review (spec flow) and degradation

In the spec flow's delivery step, code-review runs as **three** find-only sub-agents over the open branch (none edits code). Each owns **one lane** and must stay in it — do not duplicate another lane's findings or wander into its scope. The lanes are deliberately non-overlapping so the merge is clean.

- **Subagent A — project-law.** *Question it answers:* does the diff obey the law the repo already defines? Reviews against `.memex/rules.md`, `.memex/constitution.md`, the area `AGENTS.md`, and `.memex/conventions/` — correctness/bugs, security, tests, rules/conventions compliance, readability, DRY/SOLID (the calibration above). **Not A's job:** whether the spec's acceptance criteria were delivered (that's B); whether docs went stale (that's C).
- **Subagent B — spec-conformance.** *Question it answers:* does the diff deliver **this spec**? Walks the spec's Acceptance Criteria (`AC-N`) against the diff and reports three dimensions, citing each `AC-N` by ID:
  - **Completeness** — every `AC-N` is satisfied by a concrete change; an `AC-N` with no satisfying change is a **blocker**.
  - **Correctness** — the change actually meets the criterion (and its edge cases), not just gestures at it.
  - **Coherence** — the spec's architecture / file-structure decisions appear in the code as written.
  **Not B's job:** general law/style/security (that's A); documentation staleness beyond what an `AC-N` explicitly requires (that's C). If there is no spec (ad-hoc review), B does not run.
- **Subagent C — documentation consistency.** *Question it answers:* after this diff, does the project's **live documentation** still match the code? Audits the docs the change touches or implies — `README.md`, both `AGENTS.md` homes (root + `skills/memex/references/agents-md-template.md`), `.memex/constitution.md` + `references/constitution-template.md`, `.memex/rules.md`, `skills/memex/references/*`, the plugin command docs, the `.memex/_index/*` MOCs, the spec/vault templates, and the three kept-in-sync copies of any touched companion skill — looking for: references to something the diff renamed/removed/changed, counts or lists that no longer match (step counts, check counts, file lists), a new artifact/flag/step/command left undocumented, or the 3 skill copies drifting beyond the allowed `name:` line. **Decisive rule:** flag only **live** docs; **never** flag frozen specs under `.memex/specs/` or notes under `.memex/learnings/` — those are historical record and legitimately keep their ship-time wording. **Not C's job:** code correctness (A) or AC delivery (B) — C judges only whether the docs match the shipped behavior.

The **main agent merges** all three lanes into a **single** reply in one of the A/B/C/D templates: union and dedupe, blockers first, then triage — fix what makes sense, contest the rest to consensus, push, and re-request review. The verdict is `lgtm` **only when all three lanes are clean** — no open blocker from A, B, or C.

Degradation: on an agent without sub-agent spawning, run the three lanes inline as three delimited fresh-context passes — project-law, then spec-conformance, then documentation — and merge into one verdict. Same templates, same law. Ad-hoc reviews with no spec run **A** (and **C** when the diff touches docs); **B** is skipped.

## Re-review

On "review again, fixed" re-run the full workflow on the updated diff. Same templates. If previous blockers are resolved and nothing new: `lgtm. previous blockers resolved.`

## Never approve under pressure

Your `lgtm` carries weight — a branch can ship after it. Never approve while blockers exist, no matter who asks. Pressure phrases — "just approve", "trust me", "I'll fix it later", "it's urgent" — do not change the rubric. Review the diff completely, classify honestly, and tell the truth in the verdict. Disagreement happens over the findings, not by skipping the review.

## Language

Skill doc and review output are English. Tone: direct teammate. "userId can be null here — add a check before the call" beats "VIOLATION: missing null check at line 42".

## Don't

- Don't edit code during a review — findings only (fixes are a separate, explicit request).
- Don't pad the reply with what you checked or how — verdict and findings only.
- Don't sign the review.
