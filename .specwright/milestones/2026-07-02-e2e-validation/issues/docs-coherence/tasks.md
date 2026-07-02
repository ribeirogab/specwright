---
feature: docs-coherence
created: 2026-07-02
---
# Docs Coherence (T11) — Tasks

**For this issue:** see the sibling `issue.md` (acceptance criteria) and `spec.md` (technical plan).

> Each task names the `AC:` (acceptance criteria from `issue.md` it satisfies — every `AC-N` must be referenced by at least one task) and `Delegable:` (whether it suits an isolated task worker, and the one-line context that worker would receive). Workers report findings back to the issue owner; only the owner writes `learnings.md`.

## Phase 1: Prose-doc audit

### Task 1: README.md claim audit

**AC:** AC-1, AC-4
**Delegable:** no — the claim inventory feeds every later task; the owner needs it firsthand.
**Files:**
- Read: `README.md`
- Read (sources of truth): `plugins/sw/commands/`, `plugins/sw/skills/*/SKILL.md`, `.claude-plugin/marketplace.json`, `plugins/sw/.claude-plugin/plugin.json`, `.agents/skills/`, `skills/sw/scaffold/templates/`, `install.sh`, `.specwright/`

- [ ] Step 1: Read `README.md` fully; list every claim naming a count, command, path, or flow step, each quoted verbatim.
- [ ] Step 2: Enumerate the actual command surface: `ls plugins/sw/commands/ plugins/sw/skills/ .agents/skills/` and read `plugins/sw/.claude-plugin/plugin.json` + `.claude-plugin/marketplace.json`.
- [ ] Step 3: Check each claim against its source of truth; record `match`/`mismatch` per claim in a working table (scratchpad).

### Task 2: AGENTS.md claim audit

**AC:** AC-1, AC-4
**Delegable:** no — reuses Task 1's source-of-truth inventory.
**Files:**
- Read: `AGENTS.md`
- Read (sources of truth): same inventory as Task 1, plus `plugins/sw/skills/plan/SKILL.md` and `plugins/sw/skills/run/SKILL.md` for pipeline/flow-step claims.

- [ ] Step 1: Read `AGENTS.md` fully; list every count, command-name, path, and flow-step claim, quoted verbatim.
- [ ] Step 2: Check each claim against the Task 1 inventory plus the plan/run SKILL.md flow descriptions; record `match`/`mismatch`.
- [ ] Step 3: Cross-check `AGENTS.md` against the repo's `CLAUDE.md` (they document the same contract) and note any drift between the two as a claim row.

## Phase 2: Reference audit

### Task 3: `skills/sw/references/*.md` retired-artifact and layout audit

**AC:** AC-2, AC-4
**Delegable:** no — verdicts require the Phase 1 layout inventory.
**Files:**
- Read: `skills/sw/references/audit-checklist.md`, `skills/sw/references/vault-files.md`, `skills/sw/references/validation.md`, `skills/sw/references/agents-md-template.md`, `skills/sw/references/claude-plugin-settings.md`

- [ ] Step 1: Mechanical sweep for retired artifacts across the five files.

Run: `grep -n -E 'design\.md|specs/|sw-specify|sw:specify|/sw:design|spec-flow' skills/sw/references/*.md`
Expected: zero hits, or hits that sit inside explicitly historical/legacy-cleanup notes (each hit gets quoted and classified in findings.md).

- [ ] Step 2: Read each of the five files fully; verify every described path, artifact shape, and count matches the current layout (`.specwright/{conventions,issues,milestones,worktrees}`, issue folder = `issue.md` + `spec.md` + `tasks.md` + optional `learnings.md`, milestone = `goal.md` + `board.md` + `issues/<slug>/`).
- [ ] Step 3: Record one verdict per reference file (clean / N violations, each quoted) in the working table.

## Phase 3: Validator behavior

### Task 4: Build fixtures and run `validate-spec.sh`

**AC:** AC-3, AC-4
**Delegable:** yes — context: "Build the five fixture issue folders described in spec.md Lane C in a scratch dir, run `bash skills/sw/scripts/validate-spec.sh <fixture>` on each from the worktree root, capture exit codes + output verbatim."
**Files:**
- Read: `skills/sw/scripts/validate-spec.sh`, `skills/sw/references/validation.md`, `skills/sw/scripts/fixtures/` (cross-reference only)
- Create: `<issue-folder>/evidence/fixtures/{valid-standalone,valid-milestone,bad-frontmatter,bad-placeholder,bad-uncovered-ac}/{issue.md,spec.md,tasks.md}`
- Create: `<issue-folder>/evidence/validate-spec-runs.txt`

- [ ] Step 1: Build the five fixtures in the scratchpad, per the spec's Lane C table. `valid-standalone`: complete minimal issue folder, spec frontmatter `milestone: null`, ACs AC-1..AC-2 each referenced by a task. `valid-milestone`: same but `milestone: .specwright/milestones/2026-07-02-fixture/`. `bad-frontmatter`: delete `status:` from issue.md and `scope:` from spec.md. `bad-placeholder`: leave a double-brace placeholder token in spec.md. `bad-uncovered-ac`: issue.md defines AC-3 that tasks.md never mentions.
- [ ] Step 2: Run the validator on each fixture and capture everything.

Run (from the worktree root, per fixture): `bash skills/sw/scripts/validate-spec.sh <scratch>/fixtures/<name>; echo "exit=$?"`
Expected: `valid-standalone` and `valid-milestone` → `PASS: <dir>`, exit=0. `bad-frontmatter` → three FAIL lines and exit=3: check 1 fires twice (missing `status:` key, then the empty status value failing the enum) and check 2 once (missing `scope:` key) — the script counts `fail()` invocations (FAIL lines), not distinct checks. `bad-placeholder` → a `FAIL (check 3)` line reporting a surviving placeholder in spec.md with its line number, exit=1. `bad-uncovered-ac` → `FAIL (check 5): AC defined in issue.md but referenced by no task: AC-3`, exit=1.

- [ ] Step 3: Compare observed exit codes/messages against the script header contract and `references/validation.md`; any divergence becomes an Expected/Observed/Proposed-fix entry. Compare against the literal counting behavior (exit = number of `fail()` invocations / FAIL lines): the header's "exits with the number of failed checks" wording diverges when one check fails twice — that divergence itself is a findings.md candidate.
- [ ] Step 4: Copy the fixtures and the captured run log into `<issue-folder>/evidence/` (fixtures under `evidence/fixtures/`, log as `evidence/validate-spec-runs.txt`).

## Phase 4: Findings and delivery

### Task 5: Assemble `findings.md` and commit

**AC:** AC-1, AC-2, AC-3, AC-4
**Delegable:** no — curation is the owner's.
**Files:**
- Create: `<issue-folder>/findings.md`

- [ ] Step 1: Write `findings.md`: (a) README.md verdict table, (b) AGENTS.md verdict table, (c) per-reference verdicts with quoted hits, (d) validator run matrix, (e) one `Expected / Observed / Proposed fix` block per mismatch.
- [ ] Step 2: Verify scope containment.

Run: `git status --porcelain`
Expected: only paths under `.specwright/milestones/2026-07-02-e2e-validation/issues/docs-coherence/`.

- [ ] Step 3: Commit the issue folder (spec, tasks, findings, evidence, issue.md status) on `chore/e2e-docs-coherence`.

### Task 6: Runtime verification and ship

**AC:** AC-1, AC-2, AC-3, AC-4
**Delegable:** no.
**Files:**
- Modify: `<issue-folder>/issue.md` (checkboxes, status)
- Create: `<issue-folder>/learnings.md` (only if qualifying facts exist)

- [ ] Step 1: Re-verify each AC by observed artifact: AC-1 — findings.md contains both verdict tables with every claim quoted; AC-2 — five per-reference verdicts present; AC-3 — re-run one valid and one defective fixture from `evidence/fixtures/` and confirm the recorded exit codes reproduce; AC-4 — every `mismatch` row has an Expected/Observed/Proposed-fix block.
- [ ] Step 2: Tick the verified `AC-N` checkboxes in `issue.md`.
- [ ] Step 3: Open the PR with `/sw:pr` (base `chore/milestone-e2e-validation`, stacked — note it in the body) and run `/sw:review` to `lgtm`.
- [ ] Step 4: Curate `learnings.md` (facts only), set `status: shipped` + date in `issue.md`, commit.
