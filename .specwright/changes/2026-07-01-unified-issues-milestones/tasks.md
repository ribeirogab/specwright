---
feature: unified-issues-milestones
created: 2026-07-01
---
# Unified Issues + Milestones — Tasks

**For this spec:** see the sibling `spec.md`.

> **For agentic workers:** implement task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. Each task names the `AC:` it satisfies and a `Delegable:` note. All edits happen in `plugins/sw/` first; the `.agents/skills/` and `skills/sw/scaffold/skills/` copies are synced mechanically in Task 12.

---

## Phase 1: Foundation — templates + validator

### Task 1: New artifact templates

**AC:** AC-2
**Delegable:** no — the templates encode the artifact grammar every later task references; author inline.
**Files:**
- Rename: `skills/sw/scaffold/spec-templates/` → `skills/sw/scaffold/templates/`
- Create: `skills/sw/scaffold/templates/issue.md`, `templates/goal.md`, `templates/board.md`
- Modify: `skills/sw/scaffold/templates/spec.md`, `templates/tasks.md`
- Delete: `skills/sw/scaffold/templates/design.md`

- [ ] Step 1: `git mv skills/sw/scaffold/spec-templates skills/sw/scaffold/templates` and `git rm skills/sw/scaffold/templates/design.md`.
- [ ] Step 2: Write `templates/issue.md` — frontmatter `feature/created/status: pending/shipped: null`; sections: Purpose, Motivation, Non-Goals, Acceptance Criteria (numbered `AC-N` checkboxes, same anti-vagueness note as the old spec template). Note in the body: `status:` lives ONLY here; `shipped:` is set with the date on ship.
- [ ] Step 3: Write `templates/goal.md` — frontmatter `milestone/created`; sections: Purpose, Motivation, Success Criteria (milestone-level, not per-issue), Non-Goals. Note: editing this after approval = scope change, never done by the orchestrator.
- [ ] Step 4: Write `templates/board.md` — frontmatter `milestone/created`; sections: Issues (table: order, slug, depends-on), Dispatch Log (append-only: date, issue, owner event), Blockers (report format: why / tried / needs). Note: never duplicates `status:` (that lives in each `issue.md`).
- [ ] Step 5: Rewrite `templates/spec.md` frontmatter to `feature/created/scope/branch/worktree/milestone: null` (drop `status/shipped/mode`); replace the Acceptance Criteria section body with a pointer: ACs live in the sibling `issue.md`; keep the remaining sections.
- [ ] Step 6: Update `templates/tasks.md` header to reference `issue.md` for ACs; keep `AC:`/`Delegable:` fields.
- [ ] Step 7: Commit.

### Task 2: Validator + fixtures on the new grammar

**AC:** AC-3
**Delegable:** yes — self-contained: rewrite `validate-spec.sh` checks and the five fixtures per the frontmatter shapes in Task 1.
**Files:**
- Modify: `skills/sw/scripts/validate-spec.sh`, `skills/sw/scripts/fixtures/{good,bad-frontmatter,bad-placeholder,bad-unref-ac,bad-vague-verb}/*`

- [ ] Step 1: Rework checks: (1) `issue.md` exists, frontmatter has `feature/created/status`, status ∈ `pending|in-progress|shipped|blocked`; (2) `spec.md` frontmatter has `feature/created/scope`, scope enum unchanged; (3) no surviving double-brace placeholder in `issue.md`/`spec.md`/`tasks.md`/`learnings.md`; (4) vague-verb scan moves to `issue.md`'s Acceptance Criteria section; (5) every `AC-N` in `issue.md` is referenced in `tasks.md`.
- [ ] Step 2: In each fixture, rename `design.md` → `issue.md` with the new frontmatter (move ACs from fixture `spec.md` into `issue.md`); `bad-frontmatter` breaks the status enum; other bads keep their defect.
- [ ] Step 3: Run the validator against all five fixtures; expect good=0, each bad≠0. Commit.

## Phase 2: Core skills (edit `plugins/sw/` only; sync later)

### Task 3: Rename skill directories

**AC:** AC-4
**Delegable:** no — pure `git mv`, seconds of work, ordering matters for later tasks.
**Files:** `plugins/sw/skills/{brainstorming→brainstorm, writing-plans→plan, code-review→review, new-pr→pr}`

- [ ] Step 1: Four `git mv` commands; update each moved `SKILL.md` frontmatter `name:` to the new name. Commit.

### Task 4: `brainstorm` — scope detection, two batches, milestone planning, mandatory handoff

**AC:** AC-5, AC-6
**Delegable:** no — encodes the core flow decisions; needs full design context.
**Files:** Modify `plugins/sw/skills/brainstorm/SKILL.md`

- [ ] Step 1: Rewrite the checklist/flow: explore → clarify (conversation-first; decisions at the end) → approaches → design approval → **scope conclusion** (agent suggests single issue vs milestone with an issue preview; user decides) → per-shape batch → write artifacts → next step.
- [ ] Step 2: Single-issue path: batch = branch + worktree + handoff (no mode anywhere); write `.specwright/issues/YYYY-MM-DD-<slug>/issue.md` from the template; hand to `/sw:plan`.
- [ ] Step 3: Milestone path: decompose into N issues (preview approved with the design); batch = worktree only; write `goal.md` + `board.md` + `issues/<slug>/issue.md` (plain slugs, no number prefix — order lives on the board) under `.specwright/milestones/YYYY-MM-DD-<slug>/`; then print a mandatory ```txt``` handoff (resume with `/sw:run`) and stop — the planning session never conducts.
- [ ] Step 4: Update the dot digraph; keep worktree-guard logic and visual-companion section; purge `design.md`, `mode`, `autonomous`, `reviewed`, `.specwright/specs` references. Commit.

### Task 5: `plan` — issue input, learnings consumption, runtime verification, delivery

**AC:** AC-6, AC-7
**Delegable:** no — pipeline contract.
**Files:** Modify `plugins/sw/skills/plan/SKILL.md`, `plugins/sw/skills/plan/spec-document-reviewer-prompt.md`

- [ ] Step 1: Input = the issue folder's `issue.md`; when the issue sits under a milestone, also read every sibling shipped issue's `learnings.md` (`status: shipped` in its `issue.md`) before writing `spec.md`.
- [ ] Step 2: Templates paths → `skills/sw/scaffold/templates/`; spec frontmatter per Task 1; ACs stay in `issue.md` (tasks reference them there).
- [ ] Step 3: Execution tail: implement (inline vs fan-out of `Delegable:` tasks to workers — workers report findings, never write learnings) → quality gate → **runtime verification** (execute the built thing; check each AC by observed behavior; UI → browser when capable, else mark the AC `needs-human-verification` in the issue and PR — never fake) → `/sw:pr` → `/sw:review` to `lgtm` → owner curates findings into `learnings.md` → set `issue.md` `status: shipped` + `shipped:` date.
- [ ] Step 4: Self-review gates unchanged (validator, spec-document-reviewer, `/sw:review-spec`); update the reviewer prompt's `design.md` mentions to `issue.md`. Purge mode/design.md/spec-path references. Commit.

### Task 6: `review` + `pr` + `update` + plugin commands

**AC:** AC-1, AC-6, AC-7
**Delegable:** yes — mechanical term/path sweep with a short contract: `design.md`→`issue.md`, `.specwright/specs`→`.specwright/issues` (+ milestones), mode logic deleted, frozen-history exemption now "shipped issues".
**Files:** Modify `plugins/sw/skills/review/SKILL.md`, `pr/SKILL.md`, `update/SKILL.md`, `plugins/sw/commands/spec.md`, `plugins/sw/commands/review-spec.md`

- [ ] Step 1: `review`: spec-conformance lane walks `AC-N` from `issue.md`; documentation lane's frozen exemption → shipped issues under `.specwright/issues/` and `.specwright/milestones/`; lane B checks runtime-verification results in the PR body, including any AC marked `needs-human-verification` (the literal token must appear in this SKILL.md); blocker list wording updated (issue frontmatter, not spec).
- [ ] Step 2: `pr`: consent section — mode deleted; the recorded flow (an `issue.md` behind the branch) is the standing consent; ad-hoc still needs explicit invocation. Spec lookup path → issues/milestones; body links issue/spec/tasks.
- [ ] Step 3: `update` + both command files: new names, paths, artifact list; `review-spec` required-sections list: `issue.md` (Purpose, Motivation, Non-Goals, AC) + `spec.md` (Architecture … Open Questions, minus AC). Commit.

## Phase 3: Orchestrator

### Task 7: `run` skill

**AC:** AC-8
**Delegable:** no — the new core program; needs full design context.
**Files:** Create `plugins/sw/skills/run/SKILL.md`

- [ ] Step 1: Write the skill: announce; locate the milestone (argument slug, else the single in-progress milestone, else ask); read `board.md` + issue frontmatters.
- [ ] Step 2: Loop: find **ready** issues (`pending` + all `depends-on` shipped) → dispatch one **issue owner** sub-agent per ready issue in parallel (no cap), each with `git worktree add .specwright/worktrees/<slug> -b <branch>`; owner prompt = the `/sw:plan` pipeline for that issue folder. Orchestrator NEVER edits code — board, dispatch log, and reports only.
- [ ] Step 3: Tracking: append dispatch/finish events to the board's Dispatch Log; owners flip their own `issue.md` status; on `shipped`, note the owner's one-line learnings summary; on `blocked`, copy the owner's report (why / tried / needs) into Blockers.
- [ ] Step 4: Circuit breaker contract for owners: three identical failures of the same gate/AC → stop, report, `status: blocked`. Orchestrator: skip to next ready; halt when none ready and none running — if all shipped: closeout (final report + propose **promoting** durable learnings to `AGENTS.md`/conventions, apply only on user approval); else: consolidated blockers report.
- [ ] Step 5: Degradation: no sub-agent support → the session acts as each issue's owner serially, one issue at a time, same pipeline and breakers. Natural-language resume ("continue the milestone") triggers the same flow. Commit.

## Phase 4: Installer

### Task 8: `sw` installer skill + references

**AC:** AC-1, AC-12
**Delegable:** yes — contract: vault dirs `.specwright/{issues,milestones,conventions}`, SKILL_NAMES = the six new `sw-*` names, `scaffold/templates/`, commands `/sw:spec` + `/sw:review-spec`, next-steps text `/sw:brainstorm`.
**Files:** Modify `skills/sw/SKILL.md`, `skills/sw/references/{audit-checklist,validation,vault-files,agents-md-template}.md`

- [ ] Step 1: Apply the contract across the five files; `agents-md-template.md` workflow section rewritten for issues/milestones/`/sw:run` (template stays ≤ 80 lines when filled).
- [ ] Step 2: Verify with `grep -rn 'specwright/specs\|design\.md\|spec-templates' skills/sw/` → zero hits. Commit.

### Task 9: Install test + install.sh

**AC:** AC-11
**Delegable:** yes — make `tests/install/run.sh` assert the new six skill names, `templates/` path, and vault dirs; check `install.sh` for stale names.
**Files:** Modify `tests/install/run.sh`, `install.sh` (if needed)

- [ ] Step 1: Update assertions; run `tests/install/run.sh` until exit 0. Commit.

## Phase 5: Docs + sync + gate

### Task 10: Root docs

**AC:** AC-10
**Delegable:** no — AGENTS.md is the repo's contract; needs judgment to stay ≤ 80 lines.
**Files:** Modify `AGENTS.md`, `README.md`, `.specwright/conventions/skill-validation-requirements.md`

- [ ] Step 1: Rewrite `AGENTS.md` workflow section: issue as the unit, milestone flow, the eight commands, compact mermaid; `wc -l` ≤ 80.
- [ ] Step 2: README: commands table (8 rows), flow overview, folder layout; conventions doc: rename references. Commit.

### Task 11: Milestone/issue vocabulary sweep

**AC:** AC-1, AC-6
**Delegable:** yes — run the AC-1/AC-6 greps repo-wide (excluding `.specwright/specs/`, `tmp/`) and fix every live hit; also sweep the old skill names.
**Files:** whatever the sweep finds — known extra targets: `skills/sw/scripts/sw-update.sh` (`managed_pairs` list + self-test fixtures), `plugins/sw/.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json` (descriptions name old commands).

- [ ] Step 1: Run both greps plus `grep -rn 'brainstorming\|writing-plans\|new-pr\|code-review' --exclude-dir=.git .` (excluding frozen specs/tmp); fix hits, including the known extra targets; re-run to zero. Commit.

### Task 12: Sync the three copies

**AC:** AC-9, AC-4
**Delegable:** yes — mechanical: for each of the six skills, copy `plugins/sw/skills/<name>/` over `.agents/skills/sw-<name>/` and `skills/sw/scaffold/skills/sw-<name>/`, then restore each copy's `name: sw-<name>` frontmatter line; delete the old-named dirs.
**Files:** `.agents/skills/*`, `skills/sw/scaffold/skills/*`

- [ ] Step 1: Sync + rename; verify with a strip-`name:`-then-`diff` loop over the six skills × three copies → no output. Commit.

### Task 13: Full gate

**AC:** AC-1 … AC-12
**Delegable:** no — final verification belongs to the session.
**Files:** none (verification only)

- [ ] Step 1: Run every AC's verification command from `spec.md`; tick the AC checkboxes as each passes.
- [ ] Step 2: `tests/install/run.sh` + validator fixtures once more; fix anything red; commit.
