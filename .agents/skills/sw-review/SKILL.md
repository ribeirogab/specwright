---
name: sw-review
description: "Review a branch diff (or any diff/files pointed at) with specialized find-only subagents — rubric+conventions (the universal coding standard plus the project's conventions), issue-conformance (the issue's AC-N and its runtime-verification results), and documentation-consistency (stale or missing docs after the change) — merged into one plain-text verdict that reaches lgtm only when every lane is clean. Classify findings (blocker/suggestion/nitpick/question). Portable: no dependency on a native review tool. Trigger on 'review this branch', 'code review', 'review the diff', 'review again', or the delivery step of the issue pipeline."
---

# review — review against the universal standard and the project's conventions

You are about to write a code review. LLM training pushes you toward headers, emojis, and praise — override it. The review is plain text and MUST match one of the four templates below. There are no other valid shapes. Findings only enforce the universal coding standard below and what the repo already defines; this skill does not invent taste.

## Forbidden in your output

- Any emoji or pictograph.
- Any markdown header (`#`/`##`/`###`), e.g. `## Review`, `### Blocker`.
- Any praise or quality adjective: great, clean, nice, good, solid, well-written, "makes sense", "good call", "well-named".
- Any signature line, summary table, score, or "positives" section.
- Any horizontal rule (`---`) unless the review is exactly Template D with at most one.

## The reviewer's standard — read BEFORE reviewing

The review enforces two things, in this order:

1. The **universal coding standard** below — the reviewer's built-in rubric. It always applies.
2. The project-specific `.specwright/conventions/` — any convention relevant to the changed files (e.g. skill validation requirements when a `SKILL.md` changed), plus the `AGENTS.md` of each area the diff touches.

A finding that maps to a rubric rule or a convention cites it by name (e.g. "Meaningful Comments", "Modularity", "skill-validation convention").

## Universal coding standard

The reviewer's built-in rubric. PROJECT-SPECIFIC standards come from `.specwright/conventions/`; the rules here are the floor that always holds. Findings may cite a rubric rule by name (e.g. "Meaningful Comments", "Modularity").

Unix/ESR philosophy rules:

- **Modularity** — simple parts joined by clean interfaces; no tangled cross-coupling.
- **Clarity** — clarity beats cleverness; code reads for the next human.
- **Composition** — design pieces to connect to other pieces.
- **Separation** — separate policy from mechanism, interface from engine.
- **Simplicity** — design for simplicity; add complexity only where forced.
- **Parsimony** — write a big component only when nothing smaller will do; no speculative scope.
- **Transparency** — design for visibility so inspection and debugging stay easy.
- **Robustness** — robustness follows from transparency and simplicity.
- **Representation** — fold knowledge into data so the logic stays stupid and robust.
- **Least Surprise** — do the least surprising thing at every interface.
- **Silence** — when there is nothing surprising to say, say nothing (no noise output, no dead logging).
- **Repair** — when you must fail, fail noisily and as early as possible.
- **Economy** — programmer time is expensive; conserve it over machine time.
- **Generation** — prefer generating code over hand-hacking when you can.
- **Optimization** — prototype before polishing; get it working before making it fast.
- **Diversity** — distrust any claim of the "one true way".
- **Extensibility** — design for the future; it arrives sooner than expected.

Meaningful Comments — default to no comments. Comment only a non-obvious *why*: a hidden constraint, a subtle invariant, a workaround for a specific bug, or behavior that would surprise a reader. Never restate *what* well-named code already says. Never reference the task, fix, PR, or callers ("used by X", "added for Y", "handles issue #123"). If removing the comment wouldn't confuse a future reader, don't write it.

Basic security:

- No secrets or credentials committed or logged (keys, tokens, passwords, connection strings).
- Validate and escape external or untrusted input — guard against injection (SQL, shell, HTML/template, path).
- Never weaken an auth, permission, or trust boundary.
- Fail closed: on error or missing check, deny rather than allow.

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

## Blocker calibration

A blocker MUST change before merge. Real blockers here:

- a violation of a universal-standard rule (e.g. a comment that restates *what* the code does or embeds a task/issue ref — Meaningful Comments; a secret committed or logged — Basic security; untrusted input reaching a sink unescaped — Basic security; speculative out-of-scope scope — Parsimony).
- a violation of a project convention in `.specwright/conventions/` relevant to the changed files.
- a `SKILL.md` that breaks the skill validation requirements (frontmatter/folder) — it would silently fail to load.
- a committed artifact not in English; chat may be PT-BR, files may not.
- `AGENTS.md` over its 80-line cap.
- new logic with zero tests in an area that has tests.
- an acceptance criterion (`AC-N`) in the issue satisfied by no change in the diff — the issue-conformance pass flags it by ID (Completeness miss).
- an `AC-N` ticked as verified with no runtime-verification evidence in the PR body, or a criterion silently skipped instead of marked `needs-human-verification`.
- a silent test-integrity regression in a tested area (installed repos with a test suite): the touched area's test count drops, or an assertion is weakened/`skip`ped/deleted, with no in-spec justification.
- a live doc left contradicting the behavior this diff introduces — a stale flow/step/count/artifact reference in `README`, `AGENTS.md`, a command/skill doc, or a convention (the documentation pass flags it). Shipped issues under `.specwright/issues/` and `.specwright/milestones/` are historical record and exempt.

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
2. Read the reviewer's standard (the universal standard above, plus `.specwright/conventions/` and the touched-area `AGENTS.md`).
3. Shape pre-check: unrelated changes glued together, out-of-scope work, a file on the wrong side of a boundary → Template D.
4. Review in order: correctness/bugs → security → tests → rubric/conventions compliance → readability → DRY/SOLID. Classify each finding per the calibration list.
5. Run the pre-reply gate, then send exactly one template.

## Three-subagent review (issue pipeline) and degradation

In the issue pipeline's delivery step, review runs as **three** find-only sub-agents over the open branch (none edits code). Each owns **one lane** and must stay in it — do not duplicate another lane's findings or wander into its scope. The lanes are deliberately non-overlapping so the merge is clean.

- **Subagent A — rubric + conventions.** *Question it answers:* does the diff obey the universal coding standard and the project's conventions? Reviews against the universal standard above, the area `AGENTS.md`, and `.specwright/conventions/` — correctness/bugs, security, tests, rubric/conventions compliance, readability, DRY/SOLID (the calibration above). **Not A's job:** whether the issue's acceptance criteria were delivered (that's B); whether docs went stale (that's C).
- **Subagent B — issue-conformance.** *Question it answers:* does the diff deliver **this issue**? Walks the issue's Acceptance Criteria (the `AC-N` in `issue.md`) against the diff and reports three dimensions, citing each `AC-N` by ID:
  - **Completeness** — every `AC-N` is satisfied by a concrete change; an `AC-N` with no satisfying change is a **blocker**.
  - **Correctness** — the change actually meets the criterion (and its edge cases), not just gestures at it.
  - **Verification** — the PR body's runtime-verification record covers each `AC-N`: verified by observed behavior, or explicitly marked `needs-human-verification` with a reason. A ticked criterion with neither is a **blocker**.
  - **Coherence** — the spec's architecture / file-structure decisions appear in the code as written.
  **Not B's job:** general rubric/style/security (that's A); documentation staleness beyond what an `AC-N` explicitly requires (that's C). If there is no issue behind the branch (ad-hoc review), B does not run.
- **Subagent C — documentation consistency.** *Question it answers:* after this diff, does the project's **live documentation** still match the code? Audits the docs the change touches or implies — `README.md`, the `AGENTS.md` homes, the convention docs, the plugin command docs, the bundled templates, and the three kept-in-sync copies of any touched companion skill — looking for: references to something the diff renamed/removed/changed, counts or lists that no longer match (step counts, check counts, file lists), a new artifact/flag/step/command left undocumented, or the 3 skill copies drifting beyond the allowed `name:` line. **Decisive rule:** flag only **live** docs; **never** flag shipped issues under `.specwright/issues/` or `.specwright/milestones/` — those are historical record and legitimately keep their ship-time wording. **Not C's job:** code correctness (A) or AC delivery (B) — C judges only whether the docs match the shipped behavior.

The **main agent merges** all three lanes into a **single** reply in one of the A/B/C/D templates: union and dedupe, blockers first, then triage — fix what makes sense, contest the rest to consensus, push, and re-request review. The verdict is `lgtm` **only when all three lanes are clean** — no open blocker from A, B, or C.

Degradation: on an agent without sub-agent spawning, run the three lanes inline as three delimited fresh-context passes — rubric + conventions, then issue-conformance, then documentation — and merge into one verdict. Same templates, same standard. Ad-hoc reviews with no issue run **A** (and **C** when the diff touches docs); **B** is skipped.

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
