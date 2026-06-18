---
status: draft
feature: memex-worktrees
scope: medium
created: 2026-06-18
shipped: null
branch: feat/memex-worktrees
mode: autonomous
worktree: null
related:
  - "[[2026-06-18-memex-worktrees/design|design]]"
  - "[[validate-spec-flags-template-meta-specs]]"
  - "[[rename-spec-grep-first]]"
---
# memex worktrees — Spec

**Status:** Draft
**Design:** [[2026-06-18-memex-worktrees/design|design]]
**Scope:** Add an optional, memex-native git worktree per spec — a fourth post-design-batch question, a guard that detects an existing linked worktree, the `.memex/worktrees/<slug>` creation mechanic, a git-ignore entry, and an optional `worktree:` frontmatter field — propagated across every mirrored copy of the affected docs.

This is the **technical** spec — the *how*. The non-technical *why* lives in `[[2026-06-18-memex-worktrees/design|design]]`.

## Architecture

This is a **documentation/workflow propagation** change. memex is prose-as-program: the "feature" is a set of instructions the agent follows, kept in several byte-identical mirrors (the live docs the maintainer's agent reads, the Claude plugin copies, and the `scaffold/` copies new installs receive). There is no runtime code and no test framework — the mechanical gate is `.memex/scripts/validate-spec.sh`, and correctness is verified by grep-based acceptance criteria plus mirror-identity diffs, exactly as the prior multi-mirror spec `2026-06-16-rename-compact-to-handoff` did. The grep-first, basename-vs-content discipline for the ACs follows `[[rename-spec-grep-first]]`. Because this spec's subject *is* the spec template, `tasks.md` deliberately does **not** quote the literal doubled-brace placeholder tokens — `validate-spec.sh` check 2 rejects any such pair in a spec's own files; this is the known false-positive documented in `[[validate-spec-flags-template-meta-specs]]`, worked around by rephrasing (not by weakening the grep).

Three concerns, woven into the existing spec flow:

1. **The question** — the post-design batch grows from three to four: branch name, mode, **worktree (yes/no)**, handoff. Lives in the `memex-brainstorming` skill (the asker) and is summarized everywhere the batch is described (AGENTS.md, the agents-md template, the spec-driven-development guide, README, the `/memex:spec` command).

2. **The guard + mechanic** — before asking, the flow detects whether it is already inside a linked git worktree by comparing `git rev-parse --git-common-dir` with `git rev-parse --git-dir` (they differ inside a linked worktree). On a hit it warns and recommends `no`. Otherwise the default is `yes`, and at branch-creation time the flow runs `git worktree add .memex/worktrees/<slug> -b <branch>` and `cd`s in. memex only ever **creates** a worktree; it never removes one. The detection is agent-agnostic — it never hardcodes `.claude`.

3. **The recording + ignore** — `worktree:` is added to the `spec.md` frontmatter template (optional, recorded-only, like `scope:` — the validator is **not** changed). `.memex/worktrees/` is added to the repo `.gitignore` and to the `.gitignore additions` block of `skills/memex/SKILL.md` so new installs ignore it too.

The default flips from today's implicit in-place behavior to **worktree=yes** (except under the guard). This is an intentional behavior change, recorded in the design's Motivation.

## File Structure

**Mirror groups** (edits within a group must keep the files body-identical — see AC-9):

*Brainstorming skill (3 copies, body-identical):*
- Modify: `.agents/skills/memex-brainstorming/SKILL.md` — checklist step 6 (three→four), the dot-graph batch node labels, and the "After the Design" post-design-batch section gain the worktree question + a **Worktree** subsection (guard command, create mechanic, `cd`, create-only) + the handoff `cd` note.
- Modify: `plugins/memex/skills/brainstorming/SKILL.md` — identical edits.
- Modify: `skills/memex/scaffold/skills/memex-brainstorming/SKILL.md` — identical edits.

*Writing-plans skill (3 copies, body-identical):*
- Modify: `.agents/skills/memex-writing-plans/SKILL.md` — line 16 "Work in the spec's branch" → "Work in the spec's branch (or its worktree, if one was created)"; frontmatter-fill section mentions writing `worktree:`.
- Modify: `plugins/memex/skills/writing-plans/SKILL.md` — identical edits.
- Modify: `skills/memex/scaffold/skills/memex-writing-plans/SKILL.md` — identical edits.

*Spec-driven-development guide (2 copies, body-identical):*
- Modify: `.memex/spec-driven-development.md` — flow-table row 1 (batch wording) + row 2 (branch-or-worktree).
- Modify: `skills/memex/scaffold/vault-docs/spec-driven-development.md` — identical edits.

*AGENTS.md and its install template (flow section kept in lockstep):*
- Modify: `AGENTS.md` — Spec flow step 1 (batch confirms four things) + step 2 (create branch, or a worktree under `.memex/worktrees/<slug>`; guard note) + the mermaid batch-node label.
- Modify: `skills/memex/references/agents-md-template.md` — identical Spec-flow edits.

*Spec template (live + scaffold source):*
- Modify: `.memex/specs/_template/spec.md` — add optional `worktree:` key after `mode:` in frontmatter; add a one-line note explaining it is recorded-only.
- Modify: `skills/memex/references/vault-files.md` — the embedded `_template/spec.md` block (the scaffold source) gets the same `worktree:` key + note.

*Gitignore (live + scaffold instruction):*
- Modify: `.gitignore` — append `.memex/worktrees/`.
- Modify: `skills/memex/SKILL.md` — add `.memex/worktrees/` (with a one-line rationale) to the `.gitignore additions` block.

*README + command (batch summaries):*
- Modify: `README.md` — "three things" → "four things" + name the worktree question; update the mermaid batch-node label.
- Modify: `plugins/memex/commands/spec.md` — "three things" → "four things" + name the worktree question.

**Spec artifacts (this folder):**
- Create: `.memex/specs/2026-06-18-memex-worktrees/spec.md` (this file), `tasks.md`.
- Modify: `.memex/_index/specs.md` — register this spec.

**Untouched (non-goals — asserted by AC-8):** `.memex/scripts/validate-spec.sh` and its scaffold copy; any `.claude/worktrees/` harness behavior; existing files under `.memex/specs/` (other than this folder) and `.memex/learnings/`.

## Phase Ordering

1. **Phase 1 — Live mechanic + question.** Brainstorming (3), AGENTS.md + template (2), spec-driven-development (2), writing-plans (3). The substantive wording change.
2. **Phase 2 — Recording + ignore.** Spec template (2: live + vault-files.md), `.gitignore` + SKILL.md block, README + commands/spec.md.
3. **Phase 3 — Self-dogfood + register.** Set this spec's own `worktree:` field honestly (it is `null` — the guard fired, work happened in place), register in `specs.md`, run gates.

Phases are ordering only; no hard dependency forces a pause between them.

## Constraints

- **Mirror identity** — the three brainstorming copies, the three writing-plans copies, and the two spec-driven-development copies must remain body-identical (ignoring each file's own frontmatter). An edit to one is an edit to all in its group.
- **No validator change** — `worktree:` is optional; `validate-spec.sh` keeps requiring only `status/feature/created/scope`. Touching the validator is a non-goal.
- **Agent-agnostic guard** — the detection compares git-dir vs git-common-dir; it must not hardcode `.claude` or any agent-specific path.
- **English in artifacts** — docs and commits are written in English per repo convention.

## User Stories / Scenarios

1. **Fresh checkout, default path** — agent finishes design on `main`, post-design batch asks four questions, worktree defaults to yes, agent runs `git worktree add .memex/worktrees/<slug> -b <branch>`, works there through delivery.
2. **Already in a worktree** — agent is running inside `.claude/worktrees/<x>`; the guard fires, warns the user, recommends `no`; agent creates the branch in place.
3. **New install** — `npx skills add` scaffolds a repo; its `.gitignore` already lists `.memex/worktrees/`, its `_template/spec.md` already carries the optional `worktree:` key, and its `AGENTS.md` describes the four-question batch.

## Acceptance Criteria

- [ ] **AC-1** No live or scaffold doc still describes the batch as three questions, and no batch label still omits worktree. (a) `grep -rn "three things" AGENTS.md README.md plugins/memex/commands/spec.md skills/memex/references/agents-md-template.md .agents/skills/memex-brainstorming/SKILL.md plugins/memex/skills/brainstorming/SKILL.md skills/memex/scaffold/skills/memex-brainstorming/SKILL.md` returns zero matches. (b) `grep -rn "mode + handoff" AGENTS.md README.md skills/memex/references/agents-md-template.md .memex/spec-driven-development.md skills/memex/scaffold/vault-docs/spec-driven-development.md .agents/skills/memex-brainstorming/SKILL.md plugins/memex/skills/brainstorming/SKILL.md skills/memex/scaffold/skills/memex-brainstorming/SKILL.md` returns zero matches — every batch label (prose, mermaid node, or dot-graph) now reads `mode + worktree + handoff`.
- [ ] **AC-2** The four-question batch is documented: each of the three `memex-brainstorming` `SKILL.md` copies contains the token `worktree` at least twice (the checklist step and the After-the-Design section), and `AGENTS.md`, `skills/memex/references/agents-md-template.md`, `README.md`, and `plugins/memex/commands/spec.md` each contain `worktree` at least once.
- [ ] **AC-3** The guard command is present and agent-agnostic: `grep -rl "git-common-dir" .agents/skills/memex-brainstorming/SKILL.md plugins/memex/skills/brainstorming/SKILL.md skills/memex/scaffold/skills/memex-brainstorming/SKILL.md` lists all three copies, and within each the guard paragraph does not contain the literal string `.claude` (the detection is not hardcoded to one agent).
- [ ] **AC-4** The creation mechanic is present: `grep -rn "git worktree add .memex/worktrees/" .agents/skills/memex-brainstorming/SKILL.md plugins/memex/skills/brainstorming/SKILL.md skills/memex/scaffold/skills/memex-brainstorming/SKILL.md` returns at least one hit per file.
- [ ] **AC-5** `.memex/worktrees/` is git-ignored: `grep -qE '^\.memex/worktrees/?$' .gitignore` exits 0, and the `.gitignore additions` block of `skills/memex/SKILL.md` contains a line matching `^\.memex/worktrees/?$`.
- [ ] **AC-6** The optional `worktree:` field exists in both spec-template sources: the frontmatter of `.memex/specs/_template/spec.md` contains a line matching `^worktree:`, and the embedded `_template/spec.md` block in `skills/memex/references/vault-files.md` also contains a `worktree:` line.
- [ ] **AC-7** The writing-plans skill no longer says only "the spec's branch": each of the three `memex-writing-plans` `SKILL.md` copies contains the token `worktree` at least once.
- [ ] **AC-8** Non-goals hold: `git diff --name-only main...HEAD` (or `git diff --name-only` of the branch's changes) lists **neither** `.memex/scripts/validate-spec.sh` **nor** `skills/memex/scaffold/vault-scripts/validate-spec.sh`, lists no file under `.memex/learnings/`, and lists no **frozen spec** under `.memex/specs/` — i.e. no `.memex/specs/` path other than this spec's own `2026-06-18-memex-worktrees/` folder and the shared `_template/spec.md` (whose new `worktree:` field is an intended part of this change, per File Structure).
- [ ] **AC-9** Mirror identity holds after the edits — comparing each pair with frontmatter stripped is empty: the three brainstorming copies are mutually body-identical, the three writing-plans copies are mutually body-identical, and the two `spec-driven-development.md` copies are identical. Concretely, for each skill group, `diff <(sed '1,/^---$/d;1,/^---$/d' A) <(sed '1,/^---$/d;1,/^---$/d' B)` is empty (and likewise for the third copy where a group has three). The two `spec-driven-development.md` files are fully body-identical including frontmatter, so a plain `diff` of the two is empty.
- [ ] **AC-10** `bash .memex/scripts/validate-spec.sh .memex/specs/2026-06-18-memex-worktrees` exits 0, and this spec is registered in `.memex/_index/specs.md` with a link containing `2026-06-18-memex-worktrees`.

Tick each `[x]` when verified. A spec is **not shippable** with empty or unfilled-placeholder acceptance criteria.

## Risks and Mitigations

| Risk | Mitigation |
|---|---|
| A mirror copy is edited but a sibling is missed → drift. | AC-9 diffs every mirror pair with frontmatter stripped; a missed copy makes the diff non-empty. |
| The guard hardcodes `.claude`, breaking for Codex/Cursor. | AC-3 asserts the guard paragraph contains no literal `.claude`; the command keys on git-dir vs git-common-dir. |
| Someone "fixes" the validator to require `worktree:`, breaking older specs. | `worktree:` is documented as optional/recorded-only; AC-8 asserts the validator files are untouched. |
| The default flip to worktree=yes surprises existing users mid-spec. | The guard recommends `no` when already isolated; the behavior change is recorded in the design Motivation and named in the batch question, so the user always chooses explicitly. |

## Open Questions

None.
