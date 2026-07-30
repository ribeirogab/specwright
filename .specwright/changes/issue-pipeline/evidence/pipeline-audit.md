# Rounds 1+2 Pipeline Audit — per-guarantee evidence

Audited issues: `task-priority` (round 1, branch `feat/task-priority`, base `aaa117b` on `main`) and `list-filters` / `export-json-csv` / `web-page` (round 2, branches stacked on `feat/task-priority` at `b9d7c80`). Issue folders: `.specwright/milestones/2026-07-02-grow-taskr/issues/<slug>/` on each branch. Sources: owner-session git forensics (this session), two read-only task workers (JIT/learnings worker; quality/delivery/hygiene worker — findings reported back, integrated here), live probes (`round2-probes.txt`), session transcripts (`round2-session.md`), and this owner's own runtime corroboration.

## AC-1 — JIT planning + self-review gates

**JIT proof (all four issues PASS):** `spec.md`/`tasks.md` do not exist at each branch's base (`git show <base>:<path>` → `fatal: path ... does not exist`) and first appear in an in-round commit on the issue's own branch:

| Issue | First spec/tasks commit | Timestamp (UTC-3) | First code commit |
|---|---|---|---|
| task-priority | `e84fed8` "plan the task-priority issue" | 03:29:13 | after plan |
| list-filters | `667192b` "plan the list-filters issue" | 10:16:40 | `1854f08` 10:14:20 (**before** the plan commit) |
| export-json-csv | `afb28b6` "plan export-json-csv" | 10:09:03 | `463e1b1` 10:14:25 |
| web-page | `5ae05e2` "plan the web-page issue" | 10:09:35 | `837eb8c` 10:14:27 |

**list-filters commit-order anomaly:** its plan commit (10:16:40) postdates its implementation commits (10:14:20–10:15:33). The plan was nonetheless *written* before the code: an ad-hoc `git status` check run by this owner at ~13:11Z (recorded in this session's transcript — `round2-probes.txt` captures only worktrees/branches/board/statuses, not per-worktree file status) showed `spec.md`/`tasks.md` as untracked files in the list-filters worktree; `round2-probes.txt` independently proves the branch still sat at `b9d7c80` with zero commits at that time. JIT-by-write holds; JIT-by-commit does not. See findings F1.

**Gate execution evidence per issue:**

- task-priority: owner's final report (T4 evidence `../dispatch-parallelism/evidence/round1-session.md` line 170, verbatim): "validate-spec.sh PASS, spec-document-reviewer Approved (thanks for the relay), /sw:review-spec Approved".
- export-json-csv: recorded in-repo — `pr.md:31`: "`validate-spec.sh` on the issue folder: PASS; spec-document-reviewer: Approved; `/sw:review-spec`: Approved." Plus advisory-fold commit `f3cecfa`.
- web-page: advisory-application commit `759641d` "apply spec-reviewer advisories to the web-page plan" + this harness relayed its reviewer's Approved verdict (`round2-session.md`). No pr.md gate line.
- list-filters: **no artifact record** (no pr.md gate line, no advisory commit). The reviewer demonstrably ran — its Approved verdict passed through this harness's relay (`round2-session.md`, item 1) — and the owner's final report claimed a "triple-gated plan", but nothing in the repo records it. See findings F1.

**Verdict: PASS with divergence F1** (JIT proven 4/4; gates ran 4/4 by transcript evidence, but artifact-recorded only 2/4).

## AC-2 — Learnings flow (epoch-seconds fact)

- Producer (`task-priority/learnings.md` on its branch): `git grep -iE "epoch|createdAt|Date.now|seconds"` → **zero hits**. The file's 5 bullets cover taskPriority read-path, PRIORITIES exports, flag parsing, validator wording rule, pr.md degradation — nothing about the storage format.
- Consumer (`export-json-csv/spec.md` on its branch): the fact is cited and respected on 4 distinct lines — line 31 ("the store keeps epoch **seconds**, so multiply by 1000"), line 39, line 59, and the risk table (line 81: pins `1700000000` → `2023-11-14T22:13:20.000Z`). Implementation and tests respect it (AC-2 runtime record in its pr.md; suite green).
- Channel attribution: spec line 31 tags only the `taskPriority`-medium fact as "(inherited learning: ...)". The epoch fact was available to the spec author from three non-learnings channels: the export ticket's own Purpose/Non-Goals ("converted from the stored epoch seconds"), `goal.md:26`, and `lib/tasks.js:25`.

**Verdict: FAIL on the literal criterion's producer half; consumer half PASS.** The learnings *channel* was never exercised for this fact — but not by owner negligence: the priorities issue never touched `createdAt` (nothing to learn), and the fixture had already planted the fact in the consumer's own ticket, making inheritance redundant. See findings F2.

## AC-3 — Quality gate + runtime verification

- Frozen suite: `git diff <base> <branch> -- test/taskr.test.js` **empty on all four branches**.
- Test diffs: one new test file per issue (`priority` +99, `list-filters` +102, `export` +201, `server` +169), **additions only** — zero deleted assert lines, no `.skip`/`.todo`, no loosened equality (worker scan).
- Executed counts (fresh `npm test`, temp `TASKR_FILE`, per worktree): main 5/5 → task-priority 15/15 → list-filters 25/25 → export 30/30 → web-page 27/27, 0 fail, 0 skipped — matching each pr.md's claimed counts exactly. No silent drop anywhere (each branch's count vs its own base: +10, +10, +15, +12).
- Runtime verification records: every `pr.md` carries a per-AC section with concrete observed behavior (exact printed lines, stderr text, exit codes, `shasum`/`cmp`/`xxd` byte checks) — coverage 6/6, 8/8, 8/8, 7/7 vs each ticket. No vague entries.

**Verdict: PASS, no divergences.**

## AC-4 — Web page verification

- The web-page owner verified all 7 ACs via **curl** against a live server (its pr.md: "All verified by starting the server against a scratch `TASKR_FILE` store and observing HTTP responses with `curl`") and ticked all 7 checkboxes. No `needs-human-verification` marker anywhere in its issue.md.
- Honesty against the ticket: the ticket's criteria are HTTP-contract-level by construction — AC-1 even says "(verifiable with `curl`)"; none requires visual rendering. The ticks are therefore evidence-backed, not silent. Whether any of them counts as a "UI criterion" under the plan skill's browser rule is the gap — see findings F3.
- This owner's independent corroboration (web-page worktree at `8958663`, port 4471, seeded store incl. `<script>alert(1)</script>` task): `GET /` → 200 `text/html; charset=utf-8`, table rows `1/buy milk/high/open`, `2/&lt;script&gt;alert(1)&lt;/script&gt;/low/open`, `3/water plants/medium/done`; literal `<script>alert` occurrences from task input in body: 0; `GET /nope` → 404; `POST /` → 405; CLI `add` while running → re-fetch showed the new row (fresh read). Full body captured in this file's source run.
- Browser attempt by this owner: the Chrome-extension MCP refused unattended use (4 connected browsers; selection requires an interactive user question), and the managed-preview route would have required writing a `launch.json` into a repo — out of spec. Corroboration therefore also degraded to curl, with this capability note recorded rather than a silent tick — the exact behavior the criterion mandates.

**Verdict: PASS against the ticket as written (no silent ticks; every tick evidence-backed); divergence F3 against the milestone's browser-verification intent — the fixture contains no criterion that actually requires a browser.**

## AC-5 — Delivery shape

- Exactly one branch and one `pr.md` per issue (worker: folder listings + `pr.md` count = 1 across all four; probes: no second branch ever appeared).
- Fabricated-URL scan on all four branches (`github.com/*/pull|https://github.com` over `.specwright/`): **no hits**.
- Degradation headers: all four pr.md files open with the local-bare-origin declaration and the true base — round-2 ones explicitly "stacked on the unmerged task-priority branch; re-target to `main` after it merges".
- **Shape honesty (reviewer advisory):** in both rounds the degradation was **orchestrator-pre-instructed**, not organically discovered by `/sw:pr`: operator2's three owner-dispatch prompts each contain "the PR step is: push your branch to origin and write a `pr.md` PR record in the issue folder ... See the task-priority issue folder's pr.md for the pattern" (verbatim, its JSONL Agent inputs). The literal criterion's "`/sw:pr` stopped and printed manual steps" path was therefore never exercised in this sandbox — T4 set the precedent in round 1 and round 2 repeated it. See findings F4.

**Verdict: PASS on substance (one delivery per issue, truthful records, zero fabrication); the organic degradation path remains unobserved — F4.**

## AC-6 — Learnings and status hygiene

- All four `learnings.md` are forward-useful facts (invariants, API contracts, gotchas); worker scan found no narration-style bullets. Two cosmetic notes: a garbled clause in task-priority's validator bullet, and two lightly historical-but-rule-encoding bullets (validator reword note; stacked-branch quality-gating) — all still facts.
- `status:` frontmatter outside `issue.md` files: **none on any branch**. `shipped:` dates only in `issue.md`.
- Board Issues table has no status column (readiness delegated to each ticket) — unchanged through both rounds.
- Ticket edits were status flips + checkbox ticks only; **no AC text reworded on any round-2 issue** (T4's Finding 3 pattern did not recur — round-2 tickets contained no validator-tripping words).

**Verdict: PASS.**

## AC-7 — Fan-out on the export issue

- Markers: `export-json-csv/tasks.md` has 4 tasks; 3 marked `Delegable: yes` with one-line worker context each (lines 16, 192, 293), 1 marked `no` (owner gate-closing). ≥ 2 requirement met.
- Execution: the export owner's transcript (`agent-ae941ffb...jsonl`) contains exactly **one** Agent dispatch — its spec-document-reviewer ("Review spec + tasks"). **No task workers were dispatched; all 4 tasks ran inline** (owner tool profile: 20 Bash, 21 Edit, 6 Write, 4 Skill). Same single-Agent profile for the other two owners.
- Learnings discipline: the owner's Write/Edit targets include its own `learnings.md` exactly once; all seven reviewer transcripts in the harness dir show **zero** Write/Edit calls. No sub-agent wrote any learnings file (vacuously true for workers — none existed — and by inspection for reviewers).

**Verdict: FAIL on the literal "evidence shows task workers executing them" clause — with root cause in the expectation, not the owner: the plan skill's fan-out trigger is "large issue, 5+ tasks", and the owner's honest decomposition produced 4 tasks, making inline the skill-compliant choice. The T5/T4 planning assumption ("export issue (5+ tasks ...) fanned out") did not survive contact with the owner's granularity decision. See findings F5.**
