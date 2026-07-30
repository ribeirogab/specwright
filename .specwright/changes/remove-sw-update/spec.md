---
feature: remove-sw-update
created: 2026-07-03
scope: low
branch: chore/remove-sw-update
worktree: .specwright/worktrees/remove-sw-update
milestone: .specwright/milestones/2026-07-03-claude-only-plugin
---
# Remove sw:update — Spec

**Issue:** see the sibling `issue.md` (the *why*, the acceptance criteria, and the issue `status:`)
**Scope:** delete two filesystem paths and edit two enumeration points; no logic, no new abstractions.

## Architecture

Pure deletion, no redesign. `sw:update` is a self-contained companion skill (`plugins/sw/skills/update/SKILL.md`) backed by one script (`plugins/sw/scripts/sw-update.sh`); nothing else in the plugin calls into that script or imports from that skill directory, so removing both is a leaf deletion with no dependents to rewire.

The only remaining surface is textual: the plugin manifest's `description` field enumerates the companion skills in prose (`"...companion skills (brainstorm, plan, run, review, pr, update)..."`) and needs `update` dropped from that list. No other skill body or command in this repo's ownership boundary enumerates the `/sw:*` command set — confirmed by grep (see Constraints).

## File Structure

- `plugins/sw/skills/update/` — **delete** (directory, including `SKILL.md`).
- `plugins/sw/scripts/sw-update.sh` — **delete**.
- `plugins/sw/.claude-plugin/plugin.json` — **edit**: drop `update` from the `description` field's companion-skill enumeration.

Untouched (owned by the sibling `rewrite-sw-init` issue, per the file-ownership boundary): `plugins/sw/references/agents-md-template.md`, `plugins/sw/references/validation.md`, `plugins/sw/references/audit-checklist.md`. Each still mentions `sw:update`/`sw-update` after this issue ships; that is expected and documented, not a regression.

## Phase Ordering

Single phase — delete, edit the manifest, verify, then the quality gate.

## Constraints

- Do not touch `plugins/sw/references/*` — owned by `rewrite-sw-init` (parallel sibling issue); editing them here would collide with that issue's rewrite.
- Do not touch `README.md` or the repo root entry-point document — owned by `docs-and-install-flow`.
- Verified by grep before writing this spec: outside `plugins/sw/skills/update/` and `plugins/sw/scripts/sw-update.sh`, the strings `sw:update` / `sw-update` / `/sw:update` appear **only** in the three sibling-owned reference docs above. No other companion-skill body (`brainstorm`, `plan`, `pr`, `review`, `run`) or command (`spec.md`, `review-spec.md`) enumerates `update` as a command/skill name — the few unrelated hits for the bare word "update" in `review/SKILL.md`, `run/SKILL.md`, and `brainstorm/scripts/server.cjs` are ordinary English usage ("re-run... on the updated diff", "Track known files to distinguish new screens from updates"), not `/sw:update` references, and are left alone.
- `tests/install/run.sh` does not reference the update skill or script at all — no test edits required for this deletion. Confirmed by grep before writing tasks.

## User Stories / Scenarios

1. A maintainer runs `/help` (or lists the plugin's skills) after this change ships and no longer sees an `update` companion skill or `/sw:update` command.
2. A maintainer greps the plugin source for `sw-update.sh` and finds nothing anywhere in the repository.
3. A maintainer reads the plugin manifest's description and it lists only the five live companion skills (brainstorm, plan, run, review, pr) plus the two commands, with no `update` entry.
4. The three sibling-owned reference docs still mention `sw:update` until `rewrite-sw-init` ships — this is a known, documented, temporary carve-out, not a bug in this issue.

## Acceptance Criteria

The acceptance criteria live in the sibling `issue.md` — the `AC-N` IDs defined there are the contract `tasks.md` references and `/sw:review` walks. Do not duplicate them here; if writing this spec exposed a missing or wrong criterion, fix `issue.md`.

AC-3 is intentionally a **conditional** clean check: zero matches outside the three named sibling-owned files. This mirrors the historical-record carve-out pattern used by issue #1 (`plugin-only-restructure`, PR #57) for its own AC-3-equivalent — a grep-based cleanliness criterion with a small, explicitly named, documented exception set rather than an unconditional zero-matches bar.

## Risks and Mitigations

| Risk | Mitigation |
|---|---|
| Accidentally editing one of the three sibling-owned reference docs, colliding with `rewrite-sw-init`'s parallel rewrite | Scope every edit in this issue to exactly the two deletions + the manifest edit; grep the diff before commit to confirm no `references/` file changed. |
| Silently loosening `tests/install/run.sh` if it turns out to reference `update` | Re-grep the test file immediately before the quality gate; if a reference exists, update it meaningfully (not just delete the assertion) — confirmed absent in this spec's Constraints section, but re-verified at implementation time per the pipeline's test-integrity rule. |
| AC-3 grep produces an unexpected extra match (e.g., a new file introduced by the parallel sibling merging first) | Re-run the grep immediately before PR open and diff the match list against the exact three-file allowlist; if a fourth match appears, stop and investigate rather than silently expanding the carve-out. |

## Open Questions

None.
