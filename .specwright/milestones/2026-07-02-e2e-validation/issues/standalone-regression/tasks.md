---
feature: standalone-regression
created: 2026-07-02
---
# Standalone Issue Regression (T9) — Tasks

**For this issue:** see the sibling `issue.md` (acceptance criteria) and `spec.md` (technical plan).

> Each task names the `AC:` (acceptance criteria from `issue.md` it satisfies — every `AC-N` must be referenced by at least one task) and `Delegable:` (whether it suits an isolated task worker, and the one-line context that worker would receive). Workers report findings back to the issue owner; only the owner writes `learnings.md`.

## Phase 1: Baseline

### Task 1: Capture the pre-run sandbox state

**AC:** AC-2, AC-4
**Delegable:** no — the baseline anchors every later diff; the owner must observe it directly.

- [ ] Step 1: Record HEAD, cleanliness, remotes: `cd /Users/gabriel/www/ribeirogab/specwright-sandbox/taskr && git log --oneline -1 && git status --porcelain && git remote -v`
  Expected: `ab65ca0 …closeout decisions…`, empty status, origin = `/Users/gabriel/www/ribeirogab/specwright-sandbox/taskr-origin.git`.
- [ ] Step 2: Record the empty standalone vault and the design.md sweep (AC-4 "before" leg): `ls -la .specwright/issues/ && find . -name design.md -not -path './node_modules/*' | wc -l`
  Expected: only `.gitkeep`; sweep count `0`.
- [ ] Step 3: Record the suite and current `--help` behavior: `npm test 2>&1 | grep -E '^ℹ (tests|pass|fail)'` and `node bin/taskr.js --help; echo "exit: $?"`
  Expected: `tests 5 / pass 5 / fail 0`; `usage: taskr <add|list|done> ...` on stderr, exit 1.
- [ ] Step 4: Write all outputs verbatim into `evidence/01-baseline.md`, including the dispatch-context correction (main = 5 tests, not 25).
- [ ] Step 5: Commit on `chore/e2e-standalone-regression`: `git add … && git commit -m "test(e2e): capture standalone-regression baseline"`

## Phase 2: Brainstorm drive

### Task 2: Drive the /sw:brainstorm session to design approval, scope, and the post-design batch

**AC:** AC-1, AC-2, AC-4
**Delegable:** no — the driver persona and reply discipline are the test instrument; splitting it would leak context.

- [ ] Step 1: Compose the spawn prompt for `session-a` (general-purpose, background, cwd `/Users/gabriel/www/ribeirogab/specwright-sandbox/taskr`): interactive-session framing ("you are working with a user; end your turn whenever you need their input"), standing approval for sandbox-local actions, opening user ask embedded in the spawn prompt (spawn prompts carry no sender attribution): "`taskr --help` currently exits 1 with the generic usage error; I want a real `--help` flag that prints usage text — use your brainstorm flow so we design it before building."
- [ ] Step 2: Verify the prompt against the forbidden-terms list from spec.md Architecture (no `design.md`, `pr.md`, degradation/no-remote, scope steering, vault paths, batch shape). Fix and re-check until clean.
- [ ] Step 3: Spawn; save the agentId and JSONL path from the spawn result.
- [ ] Step 4: Converse per the scripted reply plan (spec.md), delivering **every** reply through a fresh neutrally-named relay agent (`maintainer`, `maintainer2`, …) that SendMessages the saved agentId — the slug-named driver never messages the session directly. Answer design questions, approve explicitly, accept the scope suggestion (record if the suggestion is not single-issue), answer the post-design batch in one reply. Poll `/Users/gabriel/www/ribeirogab/specwright-sandbox/taskr/.specwright/issues/` and `git -C … status` between turns instead of waiting.
- [ ] Step 5: Capture verbatim (jq over the JSONL: `select(.type=="assistant") | .message.content[] | select(.type=="text") | .text`): the design summary + approval turn, the scope-conclusion turn, the batch turn (byte-exact), the handoff/continue offer. Also note whether the session's **first turn** references any caller identity (spawn-channel cleanliness data point). Write `evidence/02-brainstorm-session.md`.
- [ ] Step 6: Verify AC-2's first half on disk: `ls /Users/gabriel/www/ribeirogab/specwright-sandbox/taskr/.specwright/issues/` shows exactly one `2026-07-02-<slug>/` with `issue.md` (frontmatter `status:`, numbered AC-N) and **no** `spec.md`/`tasks.md` yet (or, if the session already started planning, prove ordering from the sandbox git history instead).
- [ ] Step 7: Commit the evidence: `git commit -m "test(e2e): capture brainstorm-session evidence"`

## Phase 3: Pipeline drive

### Task 3: Drive the pipeline to shipped and capture the organic /sw:pr station

**AC:** AC-2, AC-3, AC-4
**Delegable:** no — same instrument continuity as Task 2.

- [ ] Step 1: Follow the session's own offer from Task 2 (continue in-session, or spawn `session-b` with the same contract to run `/sw:plan`, its cwd resolved from the worktree/checkout the brainstorm session actually created — observed from sandbox state, never assumed). Record which route ran.
- [ ] Step 2: Poll during planning: `spec.md`/`tasks.md` appear in the issue folder; validator/reviewer gates run. Budget: one relay per reviewer dispatch + one status ping ("verify your state from repository artifacts"), each delivered via a fresh neutral `maintainer*` relay to the agentId if stalled.
- [ ] Step 3: Poll during implementation: feature branch exists, commits land, suite runs. Do not steer.
- [ ] Step 4: At the PR station, capture the session's `/sw:pr` behavior **verbatim** (jq) — the no-remote/local-bare-origin handling, whatever it is. No pre-instruction was given; whatever happens is the observation.
- [ ] Step 5: Confirm completion by artifacts: `/sw:review` verdict `lgtm` in the transcript, `issue.md` `status: shipped` + date on the feature branch, AC checkboxes ticked. Write `evidence/03-pipeline-session.md`.
- [ ] Step 6: Commit: `git commit -m "test(e2e): capture pipeline-session evidence"`

## Phase 4: After-state audit

### Task 4: Sweep the sandbox and prove the AC-2/AC-3/AC-4 facts from artifacts

**AC:** AC-2, AC-3, AC-4
**Delegable:** yes — "run the listed read-only checks in /Users/gabriel/www/ribeirogab/specwright-sandbox/taskr and report raw outputs" (kept inline anyway; < 5 tasks total).

- [ ] Step 1: Vault-path proof: `ls -la .specwright/issues/2026-07-02-<slug>/` (issue.md + spec.md + tasks.md present, milestone path untouched: `ls .specwright/milestones/` unchanged).
- [ ] Step 2: Git-history ordering (AC-2): on the feature branch, `git log --oneline --diff-filter=A -- '.specwright/issues/*/issue.md' '.specwright/issues/*/spec.md'` — issue.md's adding commit predates spec.md/tasks.md's. If they land in the same commit, that is itself a finding (JIT ordering unprovable from history) — record it, do not improvise alternative proof.
- [ ] Step 3: Suite green + no count drop (AC-3): in the session's checkout, `npm test 2>&1 | grep -E '^ℹ (tests|pass|fail)'` — pass == tests, tests > 5 (a `--help` test was added; 5 inherited intact).
- [ ] Step 4: Runtime behavior (AC-3): `node bin/taskr.js --help; echo "exit: $?"` on the feature branch — usage text on stdout, exit 0.
- [ ] Step 5: Delivery shape (AC-3): branch pushed to the local bare origin (`git ls-remote origin`), PR record per the session's degradation path, and `grep -rn "github.com" <issue-folder>` shows no fabricated URL.
- [ ] Step 6: design.md sweep, "after" leg (AC-4): `find /Users/gabriel/www/ribeirogab/specwright-sandbox/taskr -name design.md -not -path '*/node_modules/*'` in the main checkout **and** the session's worktree → nothing; plus a jq scan of the transcripts' **assistant-authored text turns** for the string `design.md` — attribute any hit by turn and source (session-authored vs quoted file/skill content, per the T1 attribute-by-turn precedent) before calling it a failure.
- [ ] Step 7: Write `evidence/04-after-state.md` with all raw outputs; commit: `git commit -m "test(e2e): capture after-state audit evidence"`

## Phase 5: Findings, learnings, ship

### Task 5: Write findings.md

**AC:** AC-5
**Delegable:** no — verdicts require the full run context.

- [ ] Step 1: One verdict line per audit station (spec.md Architecture list): design-approval gate, scope conclusion, three-part batch, vault path, JIT ordering, self-review gates, quality gate, runtime verification, PR degradation, review-to-lgtm, shipped status, design.md sweep.
- [ ] Step 2: For every non-PASS verdict, an **Expected / Observed / Proposed fix** entry (dossier-appendable, per T8).
- [ ] Step 3: Commit: `git commit -m "test(e2e): record standalone-regression findings"`

### Task 6: Curate learnings.md, deliver, and ship

**AC:** AC-3, AC-5
**Delegable:** no — curation is the owner's.

- [ ] Step 1: Write `learnings.md`: the sandbox's final state (branches, worktrees, vault contents) and any non-obvious facts (e.g. the observed organic `/sw:pr` behavior).
- [ ] Step 2: Run the mechanical validator on this issue folder: `skills/sw/scripts/validate-spec.sh <issue-folder>` → exit 0. (Runs during self-review too; re-run here as the pre-PR quality gate — this issue touches no code, so the vault validator is the touched area's only check.)
- [ ] Step 3: Runtime verification pass over AC-1..AC-5 against the evidence files; tick verified boxes in `issue.md`.
- [ ] Step 4: `/sw:pr` with base `chore/e2e-closeout` (stacked — note it in the body). Never fabricate a URL.
- [ ] Step 5: `/sw:review` to `lgtm`.
- [ ] Step 6: Set `issue.md` `status: shipped` + `shipped: 2026-07-02`; commit and push.
