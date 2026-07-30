---
feature: docs-and-validator
created: 2026-07-02
scope: medium
branch: fix/docs-and-validator
worktree: .specwright/worktrees/docs-and-validator
milestone: .specwright/milestones/2026-07-02-specwright-fixes
---
# Docs and Validator — Spec

**Issue:** see the sibling `issue.md` (the *why*, the acceptance criteria, and the issue `status:`)
**Scope:** make the mechanical validator's documented exit semantics true, and reconcile three README statements plus the AGENTS.md template so the docs describe what actually ships.

> **Note on `scope:` frontmatter** — recorded only; nothing branches on it today. `medium` reflects one real code change (the validator) plus four surgical doc edits across shared surfaces stacked on unmerged siblings.
>
> **Note on `worktree:` frontmatter** — this issue runs in `.specwright/worktrees/docs-and-validator`.
>
> **Note on `milestone:` frontmatter** — part of the `specwright-fixes` milestone.

This is the **technical** spec — the *how*. The non-technical *why*, the acceptance criteria, and the status live in `issue.md`.

## Architecture

Five independent, mostly-textual changes. Only one touches executable surface (`validate-spec.sh`); the rest are prose reconciliations of docs against shipped reality. All five are traceable to dossier entries 5.1–5.5.

### AC-1 — validator exit semantics (the only code change)

`skills/sw/scripts/validate-spec.sh` promises in its header "exits with the number of failed **checks**" but the counter (`fail()`) increments once per **FAIL line**, and check 1 emits **two** FAIL lines for a single missing/empty `status:` (missing-key path *and* the enum path both fire). One defect ⇒ exit 2 — which also collides with the reserved usage/error exit 2 (`usage()` and the not-a-directory guard both `exit 2`).

Chosen resolution (issue.md AC-1 option (b), "the counter dedupes per check"): make the exit code equal the number of **distinct failed checks**, so the header's original wording becomes literally true.

- **Per-check dedup.** Introduce a `fail_check()` guard that records at most one failure per check number (tracked in a small `failed_checks` set/string), while still printing every diagnostic FAIL line for the human. `fails` counts distinct checks, not lines. This keeps the transparent multi-line diagnostics (Rule of Transparency) while making the exit code a check count (Rule of Least Surprise vs the header).
- **Check-1 empty-value asymmetry — deliberate decision.** `status:` is load-bearing (the pipeline and audit read it to decide readiness), so an **empty or missing** `status:` is a real defect and **must fail** — unlike `scope:` (check 2), which is recorded-only and is deliberately allowed to be blank (`""` is in check 2's enum). The asymmetry is therefore **kept, but documented** as intentional, and de-duplicated: a missing `status:` key fires check 1 **once**, not twice (the enum check is skipped when the key is absent, since the missing-key line already reports the same root defect). This is recorded in the header's Checks section.
- **Exit-2 / usage collision — noted in the header.** Because the failed-check count ranges 1–5 and the usage/operational-error exit is also 2, an exit of 2 is ambiguous between "two checks failed" and "bad invocation". The header gains an explicit note: operational errors (bad usage, missing directory) print a `usage:`/`FAIL:` line to **stderr** and exit 2; check failures print `FAIL (check N)` / `FAILED:` lines to **stdout**/stderr and exit with the failed-check count (1–5) — so callers distinguish them by the message channel and content, and should treat any non-zero exit as "not clean" (which is exactly what all in-repo callers already do: they loop `until it exits 0`).

No new checks; no check removed; the five checks and their meanings are unchanged (issue.md Non-Goals).

### AC-2 — sync `agents-md-template.md` Issue flow to AGENTS.md, minus the dogfood clause

The template's `### Issue flow` section lags the evolved `AGENTS.md` (dossier 5.2: seven divergent hunks). Bring the template's Issue-flow prose + mermaid + the two following sections into line with `AGENTS.md`, with **one deliberate exclusion**: the dogfood-only phrase "in this repo's `.claude/settings.json`" stays out of the template's Skills-and-slash-commands intro (the template ships to arbitrary repos; that clause is specwright-repo self-reference). After the sync, the two `### Issue flow` bodies match modulo that clause, so any drift comparison over the pair is clean (AC-2).

The specific hunks to lift from `AGENTS.md` into the template:
1. intro: `ticket + AC-N` → `ticket with AC-N`.
2. step 1: add `(converse first, decide at the end)` and `design approval is the **only**`.
3. step 3: `writes the issue's learnings.md (curated facts …)` → `curates the issue's learnings.md (facts …)`.
4. step 3: worktree-guard clause `(.specwright/worktrees/<slug>, git-ignored; specwright creates worktrees, never removes them)`.
5. mermaid node D: `implement<br/>→ quality gate → runtime verification<br/>→ /sw:pr` (replacing `→ gates →`).
6. mermaid node F: `dispatch ready issues to owners<br/>→ each runs the pipeline → learnings<br/>→ loop until done or blocked`.
7. Coding-standard line: `standalone issues in .specwright/issues/` (replacing `issues live in`).

Keep the template's double-brace `Project Name` / `project` placeholders and the enclosing ```markdown fence — those are template mechanics, not content.

### AC-3 — README license sentence names the two Apache-2.0 scripts

Current README (`## License`) reads "The vendored **validator** scripts under `skills/sw/scripts/` are Apache-2.0; see `NOTICE.md`" — "validator" is inaccurate (`validate-spec.sh` is the validator and is original MIT work; the Apache-2.0 portion is the two **packaging/validation helpers** `quick_validate.py` and `package_skill.py`). Reword to name both files explicitly as the Apache-2.0 portion and keep the `NOTICE.md` pointer, matching dossier 5.3's proposed sentence.

### AC-4 — README repository-layout section includes install.sh and tests/

The `## Repository layout` tree omits two shipped top-level entries that exist in the repo (`install.sh`, `tests/`). Add both rows. `AGENTS.md`/`CLAUDE.md` are already covered by the dogfood paragraph immediately below the tree (which names `.agents/`, `.claude/`, `.specwright/`); extend that paragraph to also name `AGENTS.md`/`CLAUDE.md` as dogfood artifacts so the section is complete without listing them as install output (dossier 5.4; the "retitle" alternative is unnecessary once the dogfood paragraph covers them).

### AC-5 — issue-folder enumerations mention issue-specific artifacts

Every place in live docs that enumerates the files of an issue folder currently lists a fixed set (`issue.md` / `spec.md` / `tasks.md` / `learnings.md`) and implies that is exhaustive. Validation-style issues legitimately carry extra artifacts (`findings.md`, `evidence/`). Add a short "plus any issue-specific artifacts (e.g. `findings.md`, `evidence/`)" note to each enumeration in live docs (dossier 5.5).

The enumerations in **live docs** (not fixtures, not scaffold copies of skills that are byte-managed by siblings):
- `skills/sw/references/vault-files.md` — the standalone-issue folder tree (the `.specwright/issues/` code block) and the milestone-issue folder tree (the `issues/<slug>/` code block). The full-detail note lands here (comment lines in the code blocks).
- `README.md` line ~73 — the inline "one folder — `issue.md` …" bullet gets a short "plus any issue-specific artifacts" clause.
- `AGENTS.md` line 20 and the template line 51 — the identical inline "one folder (`issue.md` … optional `learnings.md`)" sentence. Both are live docs that enumerate the folder's files, so both get the **same terse** clause (`+ any issue-specific artifacts`). AGENTS.md has ample headroom under the ≤ 80-line cap (54 lines today), so the terse clause does not risk it. **This edit is coordinated with AC-2:** the clause must be added to *both* `AGENTS.md` line 20 and `agents-md-template.md` line 51 so the AGENTS↔template parity AC-2 establishes stays clean. This is the single place where AC-2 and AC-5 touch the same lines; done together in Task 4 to avoid a two-step drift.

## File Structure

- Modify: `skills/sw/scripts/validate-spec.sh` — dedup the failure counter per check; skip the status enum check when the key is absent; expand the header comment (Checks + exit semantics + collision note). *(AC-1)*
- Modify: `skills/sw/references/agents-md-template.md` — sync the `### Issue flow` block + following two sections to `AGENTS.md`, minus the dogfood settings-path clause *(AC-2)*; add the issue-specific-artifacts clause to the inline folder sentence *(AC-5)*.
- Modify: `AGENTS.md` — add the same issue-specific-artifacts clause to the inline folder sentence (line 20), kept in lockstep with the template so AC-2 parity stays clean *(AC-5)*.
- Modify: `README.md` — license sentence (AC-3); repository-layout tree + dogfood paragraph (AC-4); inline issue-folder enumeration bullet (AC-5).
- Modify: `skills/sw/references/vault-files.md` — add the issue-specific-artifacts note to both folder-tree enumerations. *(AC-5)*

No files created or deleted (besides the new fixture). `validate-spec.sh` is the sole executable change. `AGENTS.md` is edited only for the one-clause AC-5 addition — the Issue-flow prose itself is untouched, so the drift note's "siblings do not edit AGENTS.md" concern is limited to this single, sibling-disjoint line.

## Phase Ordering

Single phase — the five changes are independent and can land in any order. Grouped into commits by AC for review legibility. The validator change is verified against crafted fixtures (runtime verification); the doc changes are verified by observed file content and by re-running `validate-spec.sh` over this very issue folder (it must still exit 0 after the header rewrite).

## Constraints

- **Stacked branch.** `fix/docs-and-validator` stacks on `fix/install-parity` (PR #51, unmerged), which stacks on the milestone-planning commit. The PR diff vs `main` therefore includes PR #51's commits until it merges. Note this in the PR body.
- **Compose with independent siblings.** PRs #49/#50/#52 edit `AGENTS.md`/`README.md`/`vault-files.md`/`audit-checklist.md`/`SKILL.md` on their own branches and merge independently of this one. Confirmed no overlap on the exact hunks this issue edits:
  - AC-3/AC-4/AC-5 touch `README.md` `## License`, `## Repository layout`, and the line-73 bullet — none of which the siblings touch (they edit SKILL.md/audit-checklist/vault-files only, or AGENTS.md not at all).
  - AC-5's `vault-files.md` edits add a note to the two folder-tree **code blocks**; the sibling PR #52 edit to `vault-files.md` touches the **self-containment prose** (the carve-out) and the bare-filename prose, not the code-block file lists — no overlapping hunk. PR #50's `vault-files.md` change is not present (its enumeration still lists four files; the `pr.md` gap is unowned — see Risks).
  - AC-2's template edit is on `agents-md-template.md`, which no sibling touches.
- **Do not touch sw-run / sw-plan / sw-pr / sw-brainstorm skill texts** (sibling `run-skill-progress-panel` owns sw-run; the others are shipped). None of my ACs require it.
- **No AI/Claude attribution** in commits, PR body, or any artifact.
- **Scaffold parity for validate-spec.sh:** the validator ships from `skills/sw/scripts/` only; it is **not** duplicated under `scaffold/skills/` or `plugins/` (confirmed: `.agents/skills/sw/` self-installs by copying `skills/sw/`; there is no second copy of the script to keep in sync). So the AC-1 edit is single-file.
- **Template copies:** `agents-md-template.md` lives only under `skills/sw/references/` (a reference, not a companion skill), so AC-2 is also single-file — no three-copy propagation.
- **README/validation.md:** `references/validation.md`'s check-8 six-skill loop and install-artifact gaps are **install-parity's deferral to me but NOT one of my ACs** — recorded as a learning/follow-up, not fixed here (issue.md Non-Goals: no new checks).

## User Stories / Scenarios

1. A maintainer runs `validate-spec.sh` on an issue folder missing `status:`. They see one `FAIL (check 1)` line and the process exits `1` (one failed check) — not `2`, and not colliding with a usage error. The header explains the exit code and the usage/error channel.
2. A maintainer runs `validate-spec.sh` on a folder with a missing `status:` **and** an unreferenced `AC-N` (two distinct failing checks). Exit is `2`, matching "two checks failed"; the stdout FAIL lines name checks 1 and 5.
3. Someone scaffolds specwright into a fresh repo; the generated `AGENTS.md` (from the synced template) has an Issue-flow section byte-matching the maintained `AGENTS.md` modulo the dogfood settings-path clause and the double-brace `project` fill.
4. A reader of the README understands that `quick_validate.py`/`package_skill.py` are the Apache-2.0 vendored portion, sees `install.sh`/`tests/` in the layout, and (in the reference docs) learns that an issue folder may also carry `findings.md`/`evidence/`.

## Acceptance Criteria

The acceptance criteria live in the sibling `issue.md` — the `AC-N` IDs defined there are the contract `tasks.md` references and `/sw:review` walks. Do not duplicate them here.

## Risks and Mitigations

| Risk | Mitigation |
|---|---|
| The validator header rewrite accidentally changes behavior. | Runtime-verify against crafted fixtures before/after; the five checks' logic is untouched — only the counter dedup + the skip-enum-when-key-missing branch change, both covered by fixtures asserting exact exit codes. |
| `validate-spec.sh` on this issue folder stops exiting 0 after the header edit. | Re-run it over this folder as a runtime-verification step; a header-comment rewrite cannot affect the checks, but verify anyway. |
| An AC-2 template hunk collides with a future AGENTS.md edit by a sibling. | Siblings do not edit `agents-md-template.md`; AGENTS.md itself is not edited by this issue, so no hunk overlap. Noted in the PR body. |
| AC-5's `vault-files.md` note overlaps PR #52's carve-out hunk. | Confirmed disjoint: PR #52 edits prose paragraphs; this edits the two fenced code-block file lists. If a merge conflict still arises, the resolution is trivially additive (keep both). Noted in the PR body. |
| The unowned `pr.md` enumeration gap (conduction note) gets silently absorbed here. | Explicitly out of scope (not an AC; degraded-delivery `pr.md` is issue-pipeline-contract's surface). Recorded as a learning/follow-up, not fixed. |

## Open Questions

None.
