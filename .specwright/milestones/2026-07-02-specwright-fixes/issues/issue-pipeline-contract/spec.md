---
feature: issue-pipeline-contract
created: 2026-07-02
scope: medium
branch: fix/issue-pipeline-contract
worktree: .specwright/worktrees/issue-pipeline-contract
milestone: .specwright/milestones/2026-07-02-specwright-fixes
---
# Issue Pipeline Contract — Spec

**Issue:** see the sibling `issue.md` (the *why*, the acceptance criteria, and the issue `status:`)
**Scope:** Amend the contract text of the plan and pr skills (all three shipped copies each) to close the e2e-validation integrity gaps: ticket-as-contract at the mechanical gate, durable plan/PR records, a binding UI-criterion definition, a delegable-count fan-out trigger, an ordered PR pre-flight, and stream-redirection guidance.

> **Note on `scope:` frontmatter** — `scope` is one of `low | medium | high | complex`. It is **recorded only**: reserved for a future quick-mode and does **not** yet gate which artifacts are written. Set it honestly; nothing branches on it today.
>
> **Note on `worktree:` frontmatter** — the path of this issue's git worktree under `.specwright/worktrees/`, or `null` when the work runs in place. **Recorded only**, like `scope:`.
>
> **Note on `milestone:` frontmatter** — the milestone folder this issue belongs to, or `null` for a standalone issue.

This is the **technical** spec — the *how*. The non-technical *why*, the acceptance criteria, and the status live in `issue.md`.

## Architecture

Markdown-only contract change; no code paths. Two skills are edited, each shipped as three byte-equivalent copies that differ only in the frontmatter `name:` line (`plan`/`pr` in `plugins/sw/skills/`, `sw-plan`/`sw-pr` in `.agents/skills/` and `skills/sw/scaffold/skills/`) — verified true at baseline via `diff`.

Editing strategy: treat `.agents/skills/sw-plan/SKILL.md` and `.agents/skills/sw-pr/SKILL.md` as the working copies, make all content edits there, then propagate mechanically — byte-copy to the scaffold path, byte-copy plus a `name:` line rewrite to the plugin path — and re-verify parity with `diff` (AC-8). This makes drift between copies impossible by construction instead of by care.

The seven contract amendments map to existing sections; no new sections are added to either skill except retitling `sw-pr`'s `## Degradation` to an ordered pre-flight and moving it before `## Create the PR` so the reading order matches the mandated execution order:

| Amendment | Skill | Section touched | Evidence |
|---|---|---|---|
| Ticket-is-contract at the mechanical gate | plan | `Gates` step 1 (Mechanical) | dossier 2.1 |
| Commit-the-plan step + gates named in PR body | plan | end of `Self-review the spec` | dossier 2.2 |
| UI-criterion definition + capability-gap record | plan | `Runtime verification` | dossier 2.3, 7.7 |
| Fan-out keys on delegable-task count | plan | `Implement` | dossier 2.4 |
| Per-stream redirection for stream-sensitive checks | plan | `Runtime verification` | T9 observation |
| Ordered degradation pre-flight, never probe with `gh pr create` | pr | `Degradation` (moved before `Create the PR`) | T9 Divergence 1 |
| Durable `pr.md` record on either stop branch | pr | same pre-flight section | T9 Divergence 2 |

One coherence edit rides along in `sw-pr`'s `Title and body`: the quality-gate section of an issue-driven PR body also names the three plan self-review gate outcomes, so the pr skill asks for exactly what the plan skill now promises (dossier 2.2's recording half).

## File Structure

- Modify: `.agents/skills/sw-plan/SKILL.md` — working copy, all five plan-skill amendments (AC-1, AC-2, AC-3, AC-4, AC-7).
- Modify: `.agents/skills/sw-pr/SKILL.md` — working copy, pre-flight restructure + durable record + body coherence line (AC-5, AC-6).
- Modify: `plugins/sw/skills/plan/SKILL.md` — propagated copy, `name: plan` preserved (AC-8).
- Modify: `plugins/sw/skills/pr/SKILL.md` — propagated copy, `name: pr` preserved (AC-8).
- Modify: `skills/sw/scaffold/skills/sw-plan/SKILL.md` — propagated byte-identical copy (AC-8).
- Modify: `skills/sw/scaffold/skills/sw-pr/SKILL.md` — propagated byte-identical copy (AC-8).

No other file changes. `plugins/sw/commands/` contains no plan/pr command files (only `review-spec.md` and `spec.md`), so the six SKILL.md files are the complete shipped surface.

## Phase Ordering

1. **Plan-skill amendments** — five content edits in `.agents/skills/sw-plan/SKILL.md` (independent sections, ordered top-to-bottom to keep Edit anchors stable).
2. **Pr-skill amendments** — restructure and edits in `.agents/skills/sw-pr/SKILL.md`.
3. **Propagation + parity check** — sync the plugin and scaffold copies from the working copies, `diff`-verify AC-8.

Phase 3 depends on 1 and 2; 1 and 2 are independent of each other.

## Constraints

- Sibling issues run in parallel on the sw-run, sw-brainstorm, scaffolder-install, and docs/validator surfaces — this issue must not touch those files, README, or the issue/goal/board templates (issue.md Non-Goals).
- `validate-spec.sh` behavior is out of scope (sibling `docs-and-validator`); AC-1 wording must not promise validator changes.
- The approved `AC-N` wording in `issue.md` is the contract — the skill text must satisfy each criterion's exact conditions, and this issue must itself demonstrate the no-reword rule it is writing down.
- Frontmatter `name:` lines are the only sanctioned difference between copies; the propagation step must preserve `name: plan` / `name: pr` in the plugin copies.
- Repo quality gate for modified skills: `python skills/sw/scripts/quick_validate.py <skill-path>` and `python skills/sw/scripts/package_skill.py <skill-path> /tmp` per the PR template, plus `tests/install/run.sh` (untouched area, run to prove nothing broke).

## User Stories / Scenarios

1. An issue owner hits a `validate-spec.sh` failure whose cause is the approved ticket: the mechanical-gate text now tells them to stop and report with the exact validator line and wait for an acknowledged resolution — rewording the criterion is explicitly forbidden, and a sanctioned ticket edit must be its own commit naming the changed criterion.
2. An owner finishes spec + tasks and the three gates: the skill now tells them to commit the plan before the first implementation commit, and later to name the three gates and outcomes in the PR body's quality-gate section — a repo-only auditor can verify the gates ran.
3. An owner faces a criterion about rendered appearance: the skill now defines it as a UI criterion (unlike an HTTP/text criterion) and, when an unattended session degrades to curl, requires recording the capability gap.
4. An owner decomposes into 4 tasks of which 3 are `Delegable: yes`: the fan-out trigger now fires on delegable count (≥ 2), not total count, so honest coarse decomposition can no longer bypass the worker mechanics.
5. A session runs `/sw:pr` in a repo with a non-GitHub remote: the ordered pre-flight stops at `git remote -v` before any `gh` invocation, and the fully-filled PR body lands in `<issue-folder>/pr.md` instead of evaporating with the session.
6. An owner runtime-verifies a criterion that distinguishes stdout from stderr: the guidance now says to use per-stream file redirection instead of piping merged streams.

## Acceptance Criteria

The acceptance criteria live in the sibling `issue.md` — the `AC-N` IDs defined there are the contract `tasks.md` references and `/sw:review` walks. Do not duplicate them here; if writing this spec exposed a missing or wrong criterion, fix `issue.md`.

## Risks and Mitigations

| Risk | Mitigation |
|---|---|
| Copy drift: an edit lands in one copy and not the others | Edit only the `.agents/` working copies; propagate by byte-copy (+ `name:` rewrite for plugin copies); `diff`-verify as the final task and as AC-8 runtime verification |
| Moving the pr skill's Degradation section breaks a cross-reference | `grep -rn "Degradation"` across the repo after the edit; the skill's internal references ("Embedded fallback at the bottom of this file") are checked to still hold |
| New plan-skill text contradicts the fan-out sentence in `tasks.md` template or other skills | Scope guard: only grep to confirm no other shipped file states the 5+-task threshold; if one does outside this issue's files, record it as a candidate learning, do not fix |
| Fan-out wording accidentally forbids owner judgment the dossier wanted to preserve | Use the issue's approved wording exactly: delegable-task count ≥ 2 triggers fan-out, replacing the total-task threshold — nothing more |

## Open Questions

None.
