---
feature: milestone-planning
created: 2026-07-02
---
# Milestone Planning (T2) — Tasks

**For this issue:** see the sibling `issue.md` (acceptance criteria) and `spec.md` (technical plan).

> Each task names the `AC:` (acceptance criteria from `issue.md` it satisfies — every `AC-N` must be referenced by at least one task) and `Delegable:` (whether it suits an isolated task worker, and the one-line context that worker would receive). Workers report findings back to the issue owner; only the owner writes `learnings.md`.

Paths below: `FIXTURE=/Users/gabriel/www/ribeirogab/specwright-sandbox/taskr/.specwright/milestones/2026-07-02-grow-taskr`, `ISSUE=.specwright/milestones/2026-07-02-e2e-validation/issues/milestone-planning` (inside the worktree), `EVID=$ISSUE/evidence`.

## Phase 1: Audit

### Task 1: Pin the fixture and collect mechanical evidence

**AC:** AC-3
**Delegable:** no (owner-run; establishes the evidence baseline every later task cites)
**Files:**
- Create: `$EVID/validate-spec-runs.txt`
- Read: `$FIXTURE/issues/*/`

- [ ] Step 1: Confirm the sandbox HEAD is still `aaa117b` and the tree is clean

Run: `cd /Users/gabriel/www/ribeirogab/specwright-sandbox/taskr && git log --oneline -1 && git status --short`
Expected: `aaa117b chore(vault): plan the grow-taskr milestone — 5 issues from the approved brainstorm` and empty status. If drifted: audit via `git show aaa117b:<path>` and note the drift in findings.md.

- [ ] Step 2: Run the validator over each of the five fixture issue folders, capturing output

Run: `for d in "$FIXTURE"/issues/*/; do echo "== $d"; skills/sw/scripts/validate-spec.sh "$d"; echo "exit=$?"; done > "$EVID/validate-spec-runs.txt" 2>&1` (run from the worktree root; loop must not abort on non-zero exit)
Expected: per folder, exactly one `FAIL (check 2): spec.md not found` line and `exit=1` — the planning-stage baseline. Any other FAIL line is a divergence to record.

- [ ] Step 3: Extract each ticket's frontmatter, slug shape, and AC list into the evidence file

Run: `for d in "$FIXTURE"/issues/*/; do echo "== $(basename "$d")"; awk 'NR==1&&$0=="---"{f=1;next} f&&$0=="---"{exit} f' "$d/issue.md"; grep -En '^- \[[ xX]\] \*\*AC-[0-9]+\*\*' "$d/issue.md" | head -20; done >> "$EVID/validate-spec-runs.txt"`
Expected: five blocks, each with `status: pending` in the frontmatter and numbered AC-N bullets; slugs from `basename` are plain kebab (regex `^[a-z][a-z0-9-]*$`, no `^[0-9]+-` prefix).

### Task 2: Audit goal.md and board.md

**AC:** AC-1, AC-2
**Delegable:** no (small reads; splitting costs more than it saves)
**Files:**
- Create: `$EVID/fixture-checks.txt`
- Read: `$FIXTURE/goal.md`, `$FIXTURE/board.md`

- [ ] Step 1: Read `$FIXTURE/goal.md` in full; record section inventory (Purpose, Motivation, Success Criteria, Non-Goals) and sweep for technical content

Run: `{ echo "== goal.md sections"; grep -n '^#' "$FIXTURE/goal.md"; echo "== technical-content sweep"; grep -nEi '(\.[a-z]{2,4}\b|/[a-z0-9_.-]+/|\(\)|--[a-z-]+|json|csv|\.js|npm|node|regex|API|function|schema|env var)' "$FIXTURE/goal.md" || echo "no hits"; } > "$EVID/fixture-checks.txt"`
Expected: all four sections present; sweep hits are then judged by eye (a hit is only a failure if it is genuinely technical — record the judgment per hit).

- [ ] Step 2: Read `$FIXTURE/board.md` in full; verify Issues table has order + dependencies, no status column/text, Dispatch Log + Blockers present and empty; cross-check dependencies against the inherited shape from the scope-detection learnings (task-priority sole root; list-filters, export-json-csv, web-page depend on it; list-newest-first depends on list-filters)

Run: `{ echo "== board.md"; cat -n "$FIXTURE/board.md"; echo "== status sweep"; grep -nEi 'status|pending|in-progress|shipped|blocked' "$FIXTURE/board.md" || echo "no hits"; } >> "$EVID/fixture-checks.txt"`
Expected: table with order/deps; status sweep hits judged (a column header `Status` or per-issue status text fails AC-2; the word in prose about the *log* may be fine — judge and record); `## Dispatch Log` and `## Blockers` present with no entries.

- [ ] Step 3: Write the AC-1 and AC-2 verdict notes (PASS/FAIL + evidence line refs) into working notes for findings.md

### Task 3: Audit the five issue tickets

**AC:** AC-3
**Delegable:** no (depends on Task 1 evidence)
**Files:**
- Read: `$FIXTURE/issues/*/issue.md`
- Modify: `$EVID/fixture-checks.txt` (append)

- [ ] Step 1: Read each of the five `issue.md` files in full; per ticket judge: frontmatter `status: pending`, AC bullets numbered sequentially and binary (observable, yes/no-checkable), no surviving double-brace template placeholders
- [ ] Step 2: Append the slug-shape check to the evidence file

Run: `ls "$FIXTURE/issues" | grep -Ev '^[a-z][a-z0-9-]*$' && echo "BAD SLUG FOUND" || echo "all slugs plain kebab" ; ls "$FIXTURE/issues" | grep -E '^[0-9]' && echo "NUMBER PREFIX FOUND" || echo "no number prefixes"` (append output to `$EVID/fixture-checks.txt`)
Expected: `all slugs plain kebab` and `no number prefixes`.

- [ ] Step 3: Write the AC-3 verdict notes: per-ticket PASS/FAIL with the validator baseline interpretation (check-2 line expected, anything else a divergence)

### Task 4: Audit the scope-detection transcript

**AC:** AC-4
**Delegable:** no (needs the relay-fidelity framing from the inherited learnings)
**Files:**
- Read: `.specwright/milestones/2026-07-02-e2e-validation/issues/scope-detection/evidence/milestone-session.md`
- Read: `.specwright/milestones/2026-07-02-e2e-validation/issues/scope-detection/evidence/milestone-artifacts.txt`

- [ ] Step 1: Read `milestone-session.md` in full; locate (a) the post-design batch, (b) the handoff, (c) the transcript tail after the handoff
- [ ] Step 2: For each of the three contract points, record the verdict with its evidence tier — `verbatim` when the evidence file quotes session text, `relay` when it summarizes; relay evidence yields "consistent with the contract (relay)" not "proven"
- [ ] Step 3: Check the tail for conduction signs (dispatch language, sub-agent spawns, code edits); record PASS/FAIL + tier

### Task 5: Write findings.md, verify, commit

**AC:** AC-5
**Delegable:** no (aggregates all verdicts; owner writes deliverables)
**Files:**
- Create: `$ISSUE/findings.md`
- Modify: `$ISSUE/issue.md` (tick verified ACs later, at ship)

- [ ] Step 1: Write `$ISSUE/findings.md`: header stating fixture commit + evidence provenance (incl. the relay-fidelity note and the validator-baseline interpretation), then one section per check (goal.md, board.md, tickets, transcript) with PASS/FAIL verdicts and one Expected / Observed / Proposed fix block per failure; proposed fixes name the upstream skill/template, never the fixture
- [ ] Step 2: Verify completeness mechanically

Run: `grep -c '^### ' "$ISSUE/findings.md"` and `grep -En 'Expected|Observed|Proposed' "$ISSUE/findings.md" | head -30`
Expected: at least 4 check sections; every FAIL verdict followed by an Expected/Observed/Proposed-fix block.

- [ ] Step 3: Run the mechanical gate on this issue's own folder

Run: `skills/sw/scripts/validate-spec.sh "$ISSUE"`
Expected: `PASS` (exit 0).

- [ ] Step 4: Commit the audit artifacts on `chore/e2e-milestone-planning`

Run: `git add .specwright/milestones/2026-07-02-e2e-validation/issues/milestone-planning && git commit -m "chore(vault): audit grow-taskr planning artifacts against the planning contract"`
Expected: clean commit, no attribution trailer.
