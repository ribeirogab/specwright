---
status: draft
feature: rename-compact-to-handoff
scope: medium
created: 2026-06-16
shipped: null
branch: feat/rename-compact-to-handoff
mode: reviewed
related:
  - "[[rename-spec-grep-first]]"
  - "[[rename-toward-overloaded-token-verifies-on-old-token]]"
---
# Rename `compact` → `handoff` — Spec

**Status:** Draft
**Design:** [[2026-06-16-rename-compact-to-handoff/design|design]]
**Scope:** Rename the post-design "compact" concept to "handoff" across all live memex docs and skills, preserving the `/compact` literal command, unrelated `compact` wording, and frozen spec/learning history.

> **Note on `scope:` frontmatter** — `scope` is one of `low | medium | high | complex`. It is **recorded only**. Set to `medium`: one coherent rename, but spanning 11 live files including three mirrored skill-copy sets and two mermaid/dot diagrams that must stay in sync.
>
> **Note on `related:` frontmatter** — links the two rename-discipline learnings this spec applied: grep-before-scope and verify-on-the-old-token (the old token `compact` collides with the `/compact` command and the "compact list" wording).

> **Note on process** — this spec was **back-filled**. The implementation was done directly first; the user flagged that a change of this blast radius should run through the spec flow. The design (the naming decision) was approved in conversation; this spec records the *how* and the acceptance criteria so the change still ships through the validator + self-review + code-review gates. The miss is captured as a feedback memory.

This is the **technical** spec — the *how*. The non-technical *why* lives in `[[2026-06-16-rename-compact-to-handoff/design|design]]`.

## Architecture

A pure find-and-rename across documentation. There is no code path — the "compact" concept lives only in prose, checklists, tables, and graph diagrams. The transform is lexical with three carve-outs:

1. **Concept → `handoff`.** Every occurrence of `compact` that names the post-design choice/step becomes `handoff` (label/noun) or `hand off` (verb). Examples: `branch + mode + compact` → `branch + mode + handoff`; `whether to **compact**` → `whether to **hand off**`; `**Compact handoff**` step header → `**Handoff**`; `compact = yes|no` → `handoff = yes|no`; mermaid/dot `{compact?}` / `["branch + mode + compact"]` → `handoff`.
2. **`/compact` literal preserved.** The Claude Code command keeps its name; user-side action text ("you `/compact` or open a new chat") is unchanged.
3. **Out-of-scope `compact` untouched.** The recall skill's "compact list" (different sense) and all of `.memex/specs/**` + `.memex/learnings/**` (frozen history) are not edited.

Mirrored skill copies must remain byte-identical in their body (they differ only in the `name:` frontmatter line), so the same edits are applied to all copies of each skill.

## File Structure

Modified (live docs — concept renamed):

- `AGENTS.md` — `### Spec flow` step 1 + step 4 prose, mermaid nodes.
- `skills/memex/references/agents-md-template.md` — same as AGENTS.md (the install template).
- `README.md` — "What you get" flow bullet + the spec-flow mermaid.
- `.memex/spec-driven-development.md` + `skills/memex/scaffold/vault-docs/spec-driven-development.md` — 9-step table + modes table.
- `plugins/memex/commands/spec.md` — flow prose.
- `plugins/memex/skills/brainstorming/SKILL.md` + `.agents/skills/memex-brainstorming/SKILL.md` + `skills/memex/scaffold/skills/memex-brainstorming/SKILL.md` — checklist, "After the Design" prose, dot diagram.
- `plugins/memex/skills/writing-plans/SKILL.md` + `.agents/skills/memex-writing-plans/SKILL.md` + `skills/memex/scaffold/skills/memex-writing-plans/SKILL.md` — "Execution Handoff" section.

Created (this spec):

- `.memex/specs/2026-06-16-rename-compact-to-handoff/{design,spec,tasks}.md`
- `.memex/_index/specs.md` — register the spec entry.

Not modified (carve-outs): the three `*-recall/SKILL.md` copies, `.memex/specs/**` (prior specs), `.memex/learnings/**`.

## Phase Ordering

Single phase. (The edits already landed; the remaining work is the spec artifacts, the gates, and the index entry.)

## Constraints

- **Mirror sync** — the three brainstorming copies, the three writing-plans copies, and the two spec-driven-development copies must each stay identical in body after the rename (memex Phase-5 validator enforces 3-copy identity for skills).
- **No history rewrite** — frozen specs/learnings keep `compact`.
- **`AGENTS.md` ≤ 80 lines** — the rename is length-neutral (no lines added/removed), so the cap is unaffected.

## User Stories / Scenarios

1. A user finishes design approval; the post-design batch asks "branch + mode + **handoff**?" — the word `compact` no longer appears as the question.
2. A user who chose handoff sees the agent print the resume prompt and is told to run `/compact` or open a new chat — the literal command still works and is still named.

## Acceptance Criteria

- [ ] **AC-1** Searching the live docs (the 12 files listed in *File Structure → Modified*) for the token `compact` not immediately preceded by `/` returns zero matches, after excluding the literal string `compact list`. Concretely: `grep -rnoE "(^|[^/])compact[a-z]*"` over those files, piped through `grep -v "compact list"`, is empty. (`CLAUDE.md` is a symlink → `AGENTS.md`, so it is covered transitively.)
- [ ] **AC-2** The `/compact` literal command still appears in the live docs (`grep -rn "/compact"` over the modified files returns ≥ 1 hit), and the brainstorming/writing-plans skills still instruct the user to run `/compact` or open a new chat.
- [ ] **AC-3** The three `*-recall/SKILL.md` copies are unchanged by this work (`git diff` shows no entry for them) and still contain "compact list".
- [ ] **AC-4** No file under `.memex/specs/` (other than this new `2026-06-16-rename-compact-to-handoff/` folder) and no file under `.memex/learnings/` is modified (`git diff --name-only` lists none of them).
- [ ] **AC-5** The mirrored copies are byte-identical in body after the rename: `diff <(tail -n +3 A) <(tail -n +3 B)` is empty for both brainstorming pairs and both writing-plans pairs, and `diff` is empty for the two `spec-driven-development.md` copies.
- [ ] **AC-6** The concept reads as `handoff`: each modified doc that previously had the post-design third question now shows `handoff` as the label (e.g. `branch + mode + handoff`) and `hand off` as the verb (e.g. `whether to **hand off**`), with no remaining `**compact**`, `compact = `, `Compact handoff`, or `{compact?}` concept tokens.
- [ ] **AC-7** `.memex/scripts/validate-spec.sh .memex/specs/2026-06-16-rename-compact-to-handoff` exits 0.
- [ ] **AC-8** The spec is registered in `.memex/_index/specs.md` with a link to `2026-06-16-rename-compact-to-handoff`.

## Risks and Mitigations

| Risk | Mitigation |
|---|---|
| A blanket replace clobbers the `/compact` literal command. | Carve-out 2; AC-2 asserts the literal survives. |
| One mirrored copy drifts from the others. | Same edits applied to every copy; AC-5 diffs them. |
| Frozen history gets "fixed" too. | Carve-out 3; AC-4 asserts no `specs/**` or `learnings/**` change. |
| The unrelated "compact list" wording gets renamed. | AC-1 excludes it; AC-3 asserts the recall copies are untouched. |

## Open Questions

None.
