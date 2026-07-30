---
milestone: specwright-fixes
created: 2026-07-02
---
# Specwright Fixes — Board

> The milestone's live state: issue order, dependencies, dispatch log, and blocker reports. The orchestrator (`/sw:run`) reads and writes this file on every loop turn. Issue `status:` lives in each issue's own `issue.md` frontmatter — it is **never duplicated here**; the board holds only what has no other home.

## Issues

An issue is **ready** when its `issue.md` says `status: pending` and every dependency listed here says `status: shipped` in its own `issue.md`.

| Order | Issue | Depends on |
|---|---|---|
| 1 | run-skill-contract | — |
| 2 | issue-pipeline-contract | — |
| 3 | brainstorm-and-templates | — |
| 4 | install-parity | — |
| 5 | run-skill-progress-panel | run-skill-contract |
| 6 | docs-and-validator | install-parity |

Rationale for the two dependencies: run-skill-progress-panel edits the same skill file as run-skill-contract, and docs-and-validator edits the same AGENTS.md template surface as install-parity — serializing them avoids merge conflicts, nothing more.

## Dispatch Log

Append-only — one line per orchestrator event: date, issue, event (`dispatched` / `shipped` / `blocked` / `resumed`), short note (for `shipped`: the owner's one-line learnings summary and the PR URL).

- 2026-07-02 · run-skill-contract · dispatched — worktree `.specwright/worktrees/run-skill-contract`, branch `fix/run-skill-contract` (stacked on `claude/bold-bun-74f6ec`, the milestone-planning branch)
- 2026-07-02 · issue-pipeline-contract · dispatched — worktree `.specwright/worktrees/issue-pipeline-contract`, branch `fix/issue-pipeline-contract` (stacked on `claude/bold-bun-74f6ec`)
- 2026-07-02 · brainstorm-and-templates · dispatched — worktree `.specwright/worktrees/brainstorm-and-templates`, branch `fix/brainstorm-and-templates` (stacked on `claude/bold-bun-74f6ec`)
- 2026-07-02 · install-parity · dispatched — worktree `.specwright/worktrees/install-parity`, branch `fix/install-parity` (stacked on `claude/bold-bun-74f6ec`)
- 2026-07-02 · issue-pipeline-contract · shipped — https://github.com/ribeirogab/specwright/pull/50 · learnings: copy-propagation recipe (.agents → scaffold byte-copy → plugin name-line rewrite + diff-verify); use `/usr/bin/python3` for PyYAML tooling; pr-skill push-before-pre-flight follow-up candidate; prefix scratchpad temp files with issue slug; subagent notifications don't wake stopped owners — run gates inline/poll from a live turn
- 2026-07-02 · brainstorm-and-templates · shipped — https://github.com/ribeirogab/specwright/pull/52 · learnings: two scope-barred docs still claim "issues are self-contained" (contradicted by new vault-files carve-out) + review-spec rubric lacks state-once check — follow-ups for docs issue/closeout; validate-spec.sh check 3 trips on literal double-braces in prose; three-copy sync recipe; `/usr/bin/python3` for pyyaml
- 2026-07-02 · run-skill-contract · shipped — https://github.com/ribeirogab/specwright/pull/49 · learnings: sw-run copies byte-identical from line 3 (head-2 + tail rebuild propagates safely); `uv run --with pyyaml` for the validators; board template restates the ready rule (mirror readiness changes); plan skill lacks the paste-ready Why/Tried/Needs blocker block the run skill now requires (follow-up); dogfood PRs must annotate — not silently tick — the "no .specwright edits" checklist item
- 2026-07-02 · run-skill-progress-panel · dispatched — worktree `.specwright/worktrees/run-skill-progress-panel`, branch `feat/run-skill-progress-panel` (stacked on `fix/run-skill-contract`, PR #49 unmerged)
- 2026-07-02 · install-parity · shipped — https://github.com/ribeirogab/specwright/pull/51 · learnings: sw-spec/sw-review-spec ship in exactly two copies (canonical + scaffold; plugin commands cover Claude Code — don't add a third); sw-update managed-set + sw-update.sh:64 still enumerate six companions (follow-up, out of scope); validation.md loops over six skills, misses new install artifacts (→ docs-and-validator); README "three kept-in-sync copies" now inaccurate (→ docs-and-validator); symlink ungated vs settings-merge gated — both intentional; pyyaml via venv
- 2026-07-02 · docs-and-validator · dispatched — worktree `.specwright/worktrees/docs-and-validator`, branch `fix/docs-and-validator` (stacked on `fix/install-parity`, PR #51 unmerged)
- 2026-07-02 · run-skill-progress-panel · dispatched (redispatched under Opus 4.8 after a Fable-5 credit failure aborted the launch with no durable work) — first launch died pre-work
- 2026-07-02 · run-skill-progress-panel · shipped — https://github.com/ribeirogab/specwright/pull/53 · learnings: authoritative panel spec is Gabriel's `progress-panel-standard.md` memory (exact hexes/88px chip/compact-line — board notes only point to it); validate-spec.sh check 3 trips on literal double-braces even inside a task's shell guard (use a bracket class `[{][{]`); head-2/tail recipe makes canonical≡scaffold byte-identical, canonical vs plugin differ only in line-2 name: (two distinct diffs); frame renderer/locale-specific content as a reference example to keep the skill tool-agnostic and satisfy the English-only verbatim-evidence rule
- 2026-07-02 · docs-and-validator · shipped — https://github.com/ribeirogab/specwright/pull/54 · learnings: validate-spec.sh now exits count of distinct failed checks (1–5), exit 2 still reused for usage/dir errors — callers treat any non-zero as "not clean"; status: fails empty (load-bearing), scope: tolerates empty (recorded-only) — intentional asymmetry; validate-spec.sh is single-copy (ships from skills/sw/scripts/, reaches installs via .agents self-copy); agents-md-template diverges from AGENTS.md in exactly one dogfood clause; NOTICE.md lists two Apache files — validate-spec.sh is original MIT; 4 out-of-scope follow-ups recorded

## Final Summary (closeout — 2026-07-02)

**All six issues shipped. 6/6.** Every `issue.md` is `status: shipped` (`shipped: 2026-07-02`) on its own branch.

| # | Issue | PR | Base (stacking) |
|---|---|---|---|
| 1 | run-skill-contract | https://github.com/ribeirogab/specwright/pull/49 | `main` |
| 2 | issue-pipeline-contract | https://github.com/ribeirogab/specwright/pull/50 | `main` |
| 3 | brainstorm-and-templates | https://github.com/ribeirogab/specwright/pull/52 | `main` |
| 4 | install-parity | https://github.com/ribeirogab/specwright/pull/51 | `main` |
| 5 | run-skill-progress-panel | https://github.com/ribeirogab/specwright/pull/53 | stacked on #49 (`fix/run-skill-contract`) |
| 6 | docs-and-validator | https://github.com/ribeirogab/specwright/pull/54 | stacked on #51 (PR base `main`; merge after #51) |

**Recommended merge order (maintainer's):** #49, #50, #51, #52 (round 1, independent, any order) → then #53 (after #49) and #54 (after #51). Each PR's diff vs `main` carries the milestone-planning commit `4aecc98` and, for #53/#54, their base PR's commits until those land.

**Blockers survived:** none — zero issues blocked. Every owner reached `lgtm`.

**Merged:** 2026-07-02 — the maintainer directed merging the whole milestone to `main`; all six PRs (#49–#54) merged in dependency order (independents first, then #53 after #49 and #54 after #51). PR #54 also carries a maintainer-requested follow-up commit making `.specwright/conventions/` self-explaining (seeds a signpost, generic role wording, docs reconciled). Worktrees under `.specwright/worktrees/` are left in place by design.

**Conduction incidents (non-blocking):** (1) the dossier-7.1 notification stall reproduced at this nesting level — all four round-1 owners stopped mid-pipeline waiting on a subagent/watcher/poller that would never wake them; each was resumed with a standing "never end your turn to wait; run gates inline" instruction, and the round-2 owners carried that rule from the start. (2) Both round-2 owners' first launch died pre-work on a Fable-5 usage-credit exhaustion; the maintainer switched the session to Opus 4.8 and they were redispatched fresh (worktrees were clean, no durable residue).

## Goal reconciliation (closeout contract, per shipped run-skill-contract)

The `goal.md` Success Criteria are met by the shipped contract text: every high-severity dossier finding (conduction 1.1–1.6/7.1/7.2/8.2, pipeline 2.1–2.4/7.7, brainstorm 3.1–3.5, install 4.1–4.4, docs 5.1–5.5, panel 8.1) is closed by a merged-pending PR, and no medium item was left silently open — the ones not closed are explicitly recorded as follow-ups below. No `goal.md` edit is warranted: the delivery matches the approved why. The follow-ups are **net-new** gaps surfaced *by* this conduction (the contracts hardened here exposed adjacent under-specification), not pre-existing dossier items left unclosed.

## Conduction notes

- Post-ship review-lane findings on issue-pipeline-contract (PR #50), for downstream issues and closeout:
  - Artifact enumerations omit the new conditional `pr.md` degraded-delivery record in: AGENTS.md:20 (CLAUDE.md symlinks to it), README.md:73, `skills/sw/references/agents-md-template.md:51`, `skills/sw/references/vault-files.md:55` (+ line 94). → feed to docs-and-validator's owner (its surface).
  - Review-skill gap: lane B checks the PR body only for the runtime-verification record; the plan skill now also requires the PR body to name the three self-review gates + outcomes — review contract not extended. → follow-up candidate, out of milestone scope.
  - pr-skill ordering question: "Push the branch if needed" runs `git ls-remote`/`git push` before pre-flight check 1 inspects `git remote -v`. Owner logged the same as a follow-up candidate. → follow-up candidate, out of approved ACs.

- **Consolidated follow-up backlog (net-new gaps surfaced during this conduction — seed for a next milestone; none in this milestone's scope):**
  1. `skills/sw/references/validation.md` Phase-5 check 8 still loops over the six original companions and checks none of the new install artifacts (self-installed `sw` + executable validator, `.claude/skills/sw` symlink, vault `.gitkeep`s). install-parity deferred it to docs-and-validator, whose Non-Goals barred adding checks — needs its own issue.
  2. `/sw:update` never reconciles `sw-spec`/`sw-review-spec`: the managed-set table in all three `sw-update` copies and the hardcoded loop in `skills/sw/scripts/sw-update.sh:64` still enumerate six companions.
  3. plan skill's circuit-breaker never mandates the paste-ready Why/Tried/Needs Blockers block that the shipped run skill now requires the conductor to paste unmodified.
  4. review skill lane B checks the PR body only for the runtime-verification record, not the three self-review gates the shipped plan skill now requires to be named there.
  5. pr skill's `## Push the branch if needed` runs `git push` before the new ordered pre-flight inspects `git remote -v` — a non-GitHub remote isn't stopped before the network write.
  6. README "three kept-in-sync copies" is inaccurate for the two-copy `sw-spec`/`sw-review-spec` pair.
  7. The degraded-delivery `pr.md` artifact is absent from the `vault-files.md` issue-folder enumeration.
  8. The "a rename needs no cross-reference rewriting" claim in `skills/sw/SKILL.md` and `references/audit-checklist.md` now contradicts PR #52's evidence-consuming carve-out.

- **Durable-learning promotion candidates (closeout step 2 — apply only with maintainer approval):**
  - Copy-propagation convention (the recurring one, hit by 4 issues): every companion `SKILL.md` ships in three copies (`.agents/skills/sw-<name>/` canonical → `skills/sw/scaffold/skills/sw-<name>/` byte-identical → `plugins/sw/skills/<name>/` with only line-2 `name:` rewritten); `sw-spec`/`sw-review-spec` ship in two (canonical + scaffold; Claude Code gets them as plugin commands); `validate-spec.sh` is single-copy. Edit canonical, propagate, verify with `diff`.
  - Dev-env: `quick_validate.py`/`package_skill.py` need PyYAML — use `/usr/bin/python3` or `uv run --with pyyaml`.
  - Authoring gotcha: `validate-spec.sh` check 3 trips on a literal double-brace anywhere in issue artifacts (even prose/shell guards) — write "double-brace placeholder" or use a bracket class `[{][{]`.
  - Dogfooding: the PR template's "No edits under `.specwright/`/`.agents/`/`.claude/`" item cannot be honestly ticked by a dogfood PR — annotate it intentionally unticked.

## Blockers

One entry per blocked issue — the owner's report, copied verbatim. Delete the entry when the issue is unblocked (the Dispatch Log keeps the history).
