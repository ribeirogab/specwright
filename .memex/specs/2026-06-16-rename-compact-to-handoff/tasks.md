---
feature: rename-compact-to-handoff
design: "[[2026-06-16-rename-compact-to-handoff/design|design]]"
spec: "[[2026-06-16-rename-compact-to-handoff/spec|spec]]"
created: 2026-06-16
---
# Rename `compact` → `handoff` — Tasks

**For this spec:** `[[2026-06-16-rename-compact-to-handoff/spec|spec]]`

> Each task names the `AC:` it satisfies and a `Delegable:` note. This spec was back-filled: the rename edits (Tasks 1–4) already landed before the spec existed; their steps are marked done and the verification steps are the contract the gates re-check.

## Phase 1: Rename the concept

### Task 1: Rename concept in the brainstorming skill (×3 copies)

**AC:** AC-1, AC-5, AC-6
**Delegable:** no — must keep the three copies byte-identical in body; one editor avoids drift.

- [x] Step 1: In all three copies (`plugins/memex/skills/brainstorming/SKILL.md`, `.agents/skills/memex-brainstorming/SKILL.md`, `skills/memex/scaffold/skills/memex-brainstorming/SKILL.md`) replace the concept tokens: `branch + mode + compact` → `branch + mode + handoff`; `whether to **compact** before implementing` → `whether to **hand off** before implementing`; `**compact (either mode)**` → `**handoff (either mode)**`; `never compact earlier` → `never hand off earlier`; `may use the compact handoff` → `may use the handoff`; `**compact = yes\|no**` → `**handoff = yes\|no**`; `Never compact before the artifacts exist` → `Never hand off before the artifacts exist`. Leave `/compact` literal intact.
- [x] Step 2: Verify mirror sync — `diff <(tail -n +3 plugins/memex/skills/brainstorming/SKILL.md) <(tail -n +3 .agents/skills/memex-brainstorming/SKILL.md)` and the scaffold pair are both empty.
- [x] Step 3: Commit (folded into the final back-fill commit).

### Task 2: Rename concept in the writing-plans skill (×3 copies)

**AC:** AC-1, AC-5, AC-6
**Delegable:** no — same byte-identical constraint as Task 1.

- [x] Step 1: In all three writing-plans copies, in the "Execution Handoff" section, replace `**compact = yes\|no**` → `**handoff = yes\|no**` and `Never compact before the artifacts exist.` → `Never hand off before the artifacts exist.`; leave `/compact` literal intact.
- [x] Step 2: Verify the two writing-plans mirror diffs (body) are empty.
- [x] Step 3: Commit (folded).

### Task 3: Rename concept in AGENTS.md, the template, README, and the spec command

**AC:** AC-1, AC-2, AC-6
**Delegable:** no — small, cross-file, needs the carve-out judgment (keep `/compact`).

- [x] Step 1: `AGENTS.md` + `skills/memex/references/agents-md-template.md` — step 1 `whether to **compact**` → `whether to **hand off**`; step 4 header `**Compact handoff (either mode)** — if compact was chosen` → `**Handoff (either mode)** — if handoff was chosen`, and `Never compact before` → `Never hand off before`; mermaid `["branch + mode + compact"]` → `handoff` and `E{"compact?"}` → `E{"handoff?"}`.
- [x] Step 2: `README.md` — bullet `whether to **compact** before implementing` → `hand off`; `**Compact works in either mode**` → `**Handoff works in either mode**`; mermaid `branch + mode + compact?` → `handoff?` and `G{compact?}` → `G{handoff?}`.
- [x] Step 3: `plugins/memex/commands/spec.md` — `whether to **compact** before implementing` → `hand off`; `**compact (either mode)**` → `**handoff (either mode)**`.
- [x] Step 4: Verify `AGENTS.md` is still ≤ 80 lines and the template `### Spec flow` matches AGENTS.md.
- [x] Step 5: Commit (folded).

### Task 4: Rename concept in the spec-driven-development guide (×2 copies)

**AC:** AC-1, AC-5, AC-6
**Delegable:** no — two copies must stay identical.

- [x] Step 1: In `.memex/spec-driven-development.md` and `skills/memex/scaffold/vault-docs/spec-driven-development.md`: 9-step table `(branch + mode + compact)` → `(branch + mode + handoff)`; step-4 row `Compact handoff (if chosen)` → `Handoff (if chosen)`; modes section `may use the **compact handoff**` → `may use the **handoff**`.
- [x] Step 2: Verify the two copies are identical (`diff` empty).
- [x] Step 3: Commit (folded).

## Phase 2: Carve-out and gate verification

### Task 5: Verify carve-outs held

**AC:** AC-1, AC-2, AC-3, AC-4
**Delegable:** yes — read-only verification; context: "run the greps/diffs below in the repo root and report pass/fail".

- [x] Step 1: Strict concept grep — `grep -rnoE "(^|[^/])compact[a-z]*"` over the 12 modified live files | `grep -v "compact list"` is empty (AC-1, AC-6).
- [x] Step 2: `/compact` literal still present — `grep -rn "/compact"` over the modified files ≥ 1 (AC-2).
- [x] Step 3: `git diff --name-only` lists none of the three `*-recall/SKILL.md` files, no `.memex/specs/*` outside the new folder, and no `.memex/learnings/*` (AC-3, AC-4).
- [ ] Step 4: Commit (folded).

### Task 6: Spec artifacts + validator + index

**AC:** AC-7, AC-8
**Delegable:** no — authoring + index edit.

- [x] Step 1: Write `design.md`, `spec.md`, `tasks.md` in `.memex/specs/2026-06-16-rename-compact-to-handoff/`.
- [x] Step 2: Run `.memex/scripts/validate-spec.sh .memex/specs/2026-06-16-rename-compact-to-handoff` → exit 0 (AC-7).
- [x] Step 3: Add the spec entry to `.memex/_index/specs.md` (AC-8).
- [ ] Step 4: Commit the back-fill (spec artifacts + the rename edits together).
