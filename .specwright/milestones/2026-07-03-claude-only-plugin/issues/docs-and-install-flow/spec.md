---
feature: docs-and-install-flow
created: 2026-07-03
scope: medium
branch: docs/docs-and-install-flow
worktree: .specwright/worktrees/docs-and-install-flow
milestone: .specwright/milestones/2026-07-03-claude-only-plugin
---
# Docs and Install Flow — Spec

**Issue:** see the sibling `issue.md` (the *why*, the acceptance criteria, and the issue `status:`)
**Scope:** delete the standalone installer and rewrite `README.md` plus the root entry-point document to describe the Claude-only plugin install flow, closing three small sibling-flagged gaps in the same pass.

> **Note on `scope:` frontmatter** — recorded only; nothing branches on it.
>
> **Note on `worktree:` frontmatter** — recorded only.
>
> **Note on `milestone:` frontmatter** — this issue's parent milestone folder.

This is the **technical** spec — the *how*. The non-technical *why*, the acceptance criteria, and the status live in `issue.md`.

## Architecture

No code, no runtime behavior — this issue is pure documentation and repo-hygiene deletion. The approach is a direct rewrite, not an incremental patch: `README.md`'s "Install" section currently describes an agent-agnostic `curl`-piped shell installer that no longer matches the shipped model (the plugin is the only distribution channel; `/sw:init` is the only per-repo step). Rather than patch sentences in place, the affected sections are rewritten wholesale against the plugin-only reality, using the already-converged `AGENTS.md`/`init` skill/`plugins/sw/` layout as the source of truth.

**Entry-point document decision:** the repo currently has `AGENTS.md` (real file) with `CLAUDE.md` as a symlink to it — a leftover of the pre-plugin agent-agnostic era. The `rewrite-sw-init` issue already converged the *scaffolder's output* to a real `CLAUDE.md` with no symlink (confirmed: `plugins/sw/skills/init/SKILL.md` and `plugins/sw/references/claude-md-template.md` generate `CLAUDE.md` directly). This issue converges the **dogfood repo itself** to match: `git mv AGENTS.md CLAUDE.md`, delete the symlink, and update every reference from `AGENTS.md` to `CLAUDE.md` in the entry-point doc's own prose and in `README.md`. This keeps one canonical entry-point filename across both what specwright ships to adopters and what specwright uses on itself — Least Surprise for anyone reading both.

**Content of the entry-point doc:** the fused `AGENTS.md`/`CLAUDE.md` content (workflow spec, issue flow, coding standard, skills/commands list, "Editing the bundled skills" section) is already accurate post-merge (verified: no `.agents/`, no per-agent symlink language, no three-copies rule survive in it — `rewrite-sw-init` already cleaned that prose). The only remaining defect is its command list still names `/sw:update` (removed by the merged `remove-sw-update` issue) and omits `/sw:init` (added by the merged `rewrite-sw-init` issue). Both are one-line fixes in the "Skills and slash commands" list.

**`README.md` rewrite scope:**
- **Install section** — replace the `curl | sh` block with the two `claude plugin` commands followed by `/sw:init`, matching the exact commands `plugins/sw/skills/init/SKILL.md` and `plugins/sw/references/claude-md-template.md` already print to end users.
- **"What you get" section** — the command table gains `/sw:init`, loses `/sw:update`; prose referencing "an `AGENTS.md`" becomes "a `CLAUDE.md`".
- **"Customizing" section** — the sentence pointing at `plugins/sw/references/agents-md-template.md` is stale (that file was renamed `claude-md-template.md` by `rewrite-sw-init`, confirmed via `ls plugins/sw/references/`); the sentence about editing "`### Issue flow`" for new installs is updated to name the current template file and, since `/sw:init` no longer templates the full issue-flow section (it only appends a short plugin-requirement block per `plugins/sw/skills/init/SKILL.md` Step 2), the sentence is corrected to describe what `/sw:init` actually does instead of asserting a stale scaffolding behavior.
- **"Repository layout" section** — drop the `install.sh` line from the tree; the closing sentence "The repository also contains `AGENTS.md` (with its `CLAUDE.md` symlink)..." becomes "...contains `CLAUDE.md`..." (no symlink survives).
- **Top summary line** — drop "Agent-agnostic" from the one-line pitch (non-goal of the milestone: no Codex/Cursor/OpenCode/Aider support).

## File Structure

- **Delete:** `install.sh` — the standalone curl-piped installer, retired now that the plugin is the sole distribution channel (AC-1).
- **Delete:** `tests/install/run.sh` (old content) — its unit tests exercise `install.sh` functions (`marketplace_source`, `merge_with_jq`, `merge_with_python`, `configure_plugin`, `remove_legacy_commands`, `print_next_steps`) that no longer exist. Replaced with a new smoke test (see below) rather than left testing a deleted file.
- **Modify:** `AGENTS.md` → renamed to `CLAUDE.md` via `git mv` (preserves history). Content changes: "Skills and slash commands" list — remove the `/sw:update` bullet, add an `/sw:init` bullet before `/sw:brainstorm` (init runs first, per-repo, before any workflow step); the top summary line stays else identical (already accurate).
- **Delete:** `CLAUDE.md` (the old symlink) — removed as part of the `git mv`/re-creation; the new `CLAUDE.md` is the real file.
- **Modify:** `README.md` — Install section, "What you get" table + prose, Customizing section, Repository layout tree + closing sentence, top pitch line. See Architecture above for exact edits.
- **Modify:** `.github/ISSUE_TEMPLATE/bug.md` — "Component affected" line lists the bundled companions; drop `sw-update` from the parenthetical list, matching the current six companions (init, brainstorm, plan, pr, review, run).
- **Modify:** `.github/ISSUE_TEMPLATE/feature_request.md` — same companion-list fix in "What should specwright do?".
- **Modify:** `plugins/sw/references/vault-files.md` — two stale path mentions in the "What does not live in the vault" bullets: "ship with this skill at `scaffold/templates/{issue,spec,tasks,goal,board}.md`" → `plugins/sw/templates/{issue,spec,tasks,goal,board}.md`; "ship with this skill under `scripts/validate-spec.sh`" → `plugins/sw/scripts/validate-spec.sh`. Confirmed current real paths via `ls plugins/sw/templates/` and `ls plugins/sw/scripts/`.
- **No change:** `plugins/sw/.claude-plugin/plugin.json` — already resolved by the Step 0 merge (`init` in, `update` out).
- **Modify:** `.claude-plugin/marketplace.json` — its `description` string still lists `/sw:update` among the companion skills; while no AC names this file explicitly, it is a live, user-facing doc surface (shown by `claude plugin marketplace` browsing) describing the exact same companion set the entry-point doc and README enumerate, and leaving it stale would contradict AC-3/AC-4's intent the moment anyone reads it next to the corrected docs. Fixed in the same pass as the plugin.json companion-list wording for consistency (`init, brainstorm, plan, run, review, pr`).
- **Modify:** `plugins/sw/commands/spec.md`, `plugins/sw/skills/review/SKILL.md`, `plugins/sw/skills/run/SKILL.md` — flagged by the spec-document-reviewer subagent pass on this issue's own plan: these three **live plugin-behavior files** (not historical `.specwright/` records) generically reference `AGENTS.md` as the name of the entry-point document any adopting repo has — a name the `rewrite-sw-init` issue already retired in favor of `CLAUDE.md` (confirmed: `plugins/sw/references/claude-md-template.md`, the actual source of truth, generates `CLAUDE.md` and never mentions `AGENTS.md`). Left unfixed, `/sw:review`'s own documentation-consistency subagent (C) would very plausibly flag this very PR's `AGENTS.md`→`CLAUDE.md` rename as a doc-staleness regression, since its own instructions in `review/SKILL.md` still say to audit "the `AGENTS.md` homes" and "the three kept-in-sync copies of any touched companion skill" — the latter phrase is itself stale (the three-copies model was eliminated earlier in this milestone by `plugin-only-restructure`). All three files get a one-line/few-line prose swap (`AGENTS.md` → `CLAUDE.md`; drop the "three kept-in-sync copies" clause and its "3 skill copies drifting" sub-clause from `review/SKILL.md`'s Subagent C description, since every companion skill now lives in exactly one copy) — no behavior change beyond correcting the entry-point-document name and removing a description of a retired file-layout model.

## Phase Ordering

1. Delete `install.sh`.
2. Rename `AGENTS.md` → `CLAUDE.md`, delete the old symlink, fix its command list.
3. Rewrite `README.md`.
4. Sweep the three extra-scope files (`.github/ISSUE_TEMPLATE/*.md` ×2, `vault-files.md`) plus `marketplace.json`.
5. Rewrite `tests/install/run.sh` as a plugin-install smoke test.
6. Repo-wide grep verification for every AC.

Single phase in practice — no cross-file dependency blocks parallelizing 2-4, but they are small enough to do sequentially in one pass for a docs-only issue.

## Constraints

- **No behavior change** — this issue touches no `plugins/sw/skills/*/SKILL.md` logic and no `plugins/sw/scripts/validate-spec.sh` logic (other than the test file, which tests behavior, not skills).
- **AC-5 grep scope** — a literal `grep -rn install.sh` over the whole repository, including `.specwright/`, will always find matches: this issue's own `issue.md`/`spec.md`/`tasks.md` must discuss the deleted file to document the deletion, and prior shipped issues' `.specwright/milestones/*/issues/*/` folders (e.g. `install-parity`, `docs-and-validator`, `command-surface`) are historical tickets that describe repo state *at the time they ran* — rewriting them would falsify history, which the vault-files convention (self-contained issues, no retroactive edits) forbids. AC-5's own qualifier — "every documentation pointer to it is removed or updated" — scopes the check to **live documentation**: `README.md`, `CLAUDE.md`, and any other currently-read doc outside `.specwright/`. Runtime verification runs the grep both raw (to show the historical noise is understood, not missed) and with `.specwright/` excluded (the actual pass/fail signal), and calls out the distinction explicitly in the PR body.
- **Banned-literal trap (learned from `rewrite-sw-init`)** — `validate-spec.sh` check 3 greps for the literal double-brace opening marker used by unfilled template placeholders; this spec must never reproduce that literal sequence while describing template placeholders in prose (described in words instead, as done above).
- **Git history preservation** — `AGENTS.md` → `CLAUDE.md` uses `git mv` so the rename is tracked as a rename, not a delete+add.

## User Stories / Scenarios

1. A new adopter reads `README.md`, runs `claude plugin marketplace add ribeirogab/specwright` then `claude plugin install sw@specwright`, opens their repo in Claude Code, and runs `/sw:init` — ending with a `.specwright/` vault and a `CLAUDE.md` entry point, with no shell script ever downloaded or executed.
2. A contributor reading the repo's own `CLAUDE.md` sees the current companion-skill roster (init, brainstorm, plan, run, review, pr) and no dangling `/sw:update` reference.
3. A maintainer filing a bug via `.github/ISSUE_TEMPLATE/bug.md` sees the accurate list of bundled companions and does not select a retired one.

## Acceptance Criteria

The acceptance criteria live in the sibling `issue.md` — the `AC-N` IDs defined there are the contract `tasks.md` references and `/sw:review` walks. Do not duplicate them here; if writing this spec exposed a missing or wrong criterion, fix `issue.md`.

## Risks and Mitigations

| Risk | Mitigation |
|---|---|
| AC-5's repo-wide grep reads as "zero matches anywhere," but historical `.specwright/` records legitimately mention the deleted file | Document the scoping rationale in this spec's Constraints section and in the PR body; verify with both a raw and a `.specwright/`-excluded grep, reporting both counts. |
| Renaming `AGENTS.md` to `CLAUDE.md` could break an external reference this session did not find | Repo-wide grep for `AGENTS.md` after the rename (excluding historical `.specwright/` records) confirms no live doc still points at the old name. |
| `tests/install/run.sh` currently unit-tests functions from a file that is about to be deleted, so the quality gate would break loudly if left as-is | Rewrite it in the same commit series as a smoke test of the new reality (marketplace.json validity, plugin.json validity, `/sw:init`-equivalent vault scaffold, absence of `install.sh`), keeping it meaningful rather than deleting test coverage outright. |

## Open Questions

None.
