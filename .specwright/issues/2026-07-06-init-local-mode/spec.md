---
feature: init-local-mode
created: 2026-07-06
scope: medium
branch: feat/init-local-mode
worktree: null
milestone: null
---
# Init Local Mode — Spec

**Issue:** see the sibling `issue.md` (the *why*, the acceptance criteria, and the issue `status:`)
**Scope:** add a `local` commit mode to `/sw:init` — an always-asked choice between today's `shared` mode and an uncommitted `local` mode (entry point in `CLAUDE.local.md`, vault + entry point git-ignored) — with a guard-only migration path and a `/sw:run` refusal in `local` mode, plus the doc/validation surface that goes with it.

This is the **technical** spec — the *how*. The non-technical *why*, the acceptance criteria, and the status live in `issue.md`.

## Architecture

The whole feature is **markdown-and-embedded-shell**: specwright's skills are executed by an agent, not compiled. There is no application code — the "logic" is the prose and the shell snippets inside the skill `SKILL.md` files, and the "tests" are (a) executing those exact shell snippets against throwaway sandbox repos to observe file/gitignore/git-status outcomes and (b) the existing install smoke tests.

Two orthogonal decisions define a mode; both are set by the same `/sw:init` run:

| Decision | `shared` (today) | `local` (new) |
|---|---|---|
| Entry-point file | `CLAUDE.md` (committed) | `CLAUDE.local.md` (git-ignored) |
| Vault `.specwright/` | committed | git-ignored (blanket `.specwright/` line) |

**Mode is always asked, never inferred silently.** `/sw:init` detects the *established* mode from disk only to (a) run idempotently when the choice matches and (b) refuse to auto-migrate when it diverges. The single detection signal is the presence of a specwright entry point named `CLAUDE.local.md`:

- **local established** — `CLAUDE.local.md` exists at the repo root and contains `claude plugin install sw@specwright`.
- **shared established** — no such `CLAUDE.local.md`, and `CLAUDE.md` exists containing `claude plugin install sw@specwright`.
- **fresh** — neither.

`/sw:run`'s guard uses a different, more precise signal because what actually breaks conduction is an *uncommitted vault*: `.specwright/` being git-ignored. It probes `git check-ignore -q .specwright/milestones` (true only under the blanket `.specwright/` line, since `shared` mode only ignores `.specwright/worktrees/`).

**The worktree caveat (why milestone support is deferred).** `git worktree add` materializes only tracked content; a git-ignored `CLAUDE.local.md` and a git-ignored `.specwright/` do not appear inside the worktrees `/sw:run` creates, so a dispatched issue owner would start with neither the specwright contract nor its issue folder. Making `/sw:run` copy those into each worktree is real work and is a Non-Goal here (see `issue.md`); this issue only adds the fail-safe refusal (AC-8).

## File Structure

All paths relative to repo root. No files created except the issue's own `spec.md`/`tasks.md`/`learnings.md`; everything else is a **modify**.

- **Modify `plugins/sw/skills/init/SKILL.md`** — the core change. Insert a new **Step 2 — choose the commit mode** (detect established mode; always ask shared/local; branch: fresh or matching → proceed in that mode, diverging → guard-only migration message + stop). Renumber today's Step 2 → **Step 3 — the entry point**, parameterized on `ENTRY` (`CLAUDE.md` for shared, `CLAUDE.local.md` for local); in `local` mode it never creates or edits `CLAUDE.md`. Renumber today's Step 3 → **Step 4 — the `.gitignore` lines**: always the `.specwright/worktrees/` line (unchanged snippet), and in `local` mode additionally `.specwright/` and `CLAUDE.local.md`, each with the same `grep -qxF` + blank-line idempotency guard. Update the frontmatter `description` and the "Re-running" note to mention the mode.
- **Modify `plugins/sw/references/validation.md`** — define `ENTRY` = `CLAUDE.local.md` when it exists, else `CLAUDE.md`, at the top of Checks. Retarget checks 1–4 (placeholder sweep, required headers, size cap, plugin-requirement) from the literal `CLAUDE.md` to `$ENTRY`. Extend check 6 (`.gitignore`) so that, in `local` mode, it also asserts `.specwright/` and `CLAUDE.local.md` each appear exactly once. Update the contents blurb.
- **Modify `plugins/sw/references/audit-checklist.md`** — the inventory now lists the entry point as `CLAUDE.md` *or* `CLAUDE.local.md` (local), and `.gitignore` as containing `.specwright/worktrees/` plus, in local mode, `.specwright/` and `CLAUDE.local.md`. Adjust "That is the complete list" to name the mode variance. Retarget the drift-detection prose to `$ENTRY`.
- **Modify `plugins/sw/references/claude-md-template.md`** — the template body is mode-neutral (same content, different filename); add one note that in `local` mode the filled result is written to `CLAUDE.local.md`, and a short caveat that `local` mode's git-ignored entry point does not cross worktrees (so milestone conduction is not supported in `local` mode yet). Parameterize the "written to `CLAUDE.md`" wording.
- **Modify `plugins/sw/references/vault-files.md`** — add a caveat subsection: in `local` mode the vault is git-ignored, so the `.gitkeep`/`README` keep-files still exist on disk but are not committed; clone-survival, milestone resumability from a fresh clone, and PR-linked artifact URLs do not apply in that mode.
- **Modify `plugins/sw/skills/run/SKILL.md`** — add a short **Preflight — commit mode** block before "Locate the milestone": probe `git check-ignore -q .specwright/milestones`; if git-ignored (local mode), halt with a message that milestone conduction is not supported in `local` mode yet (the single-issue flow is) and dispatch no owner.
- **Modify `plugins/sw/commands/init.md`** — the frontmatter `description` mentions the mode choice instead of only "a root CLAUDE.md entry point, and the .gitignore worktrees line".
- **Modify `README.md`** — the Use section and the `/sw:init` table row describe both modes; add one short paragraph naming `local` mode (CLAUDE.local.md + the two git-ignore lines) and that milestone conduction needs `shared` mode.
- **Modify `CLAUDE.md`** (repo dogfood) — the `/sw:init` one-liner in "Skills and slash commands" mentions the shared/local mode choice. Keep the file ≤ 80 lines (validation check 3).

## Phase Ordering

1. **Core behavior** — `init/SKILL.md` (Steps 2–4) and `run/SKILL.md` preflight. Everything else describes what these do.
2. **Self-audit surface** — `validation.md` + `audit-checklist.md` retargeted to `$ENTRY` and local-mode gitignore lines.
3. **Docs** — `claude-md-template.md`, `vault-files.md`, `commands/init.md`, `README.md`, dogfood `CLAUDE.md`.
4. **Verify** — sandbox execution of the prescribed shell for shared-init and local-init; run the updated validation checks; run the run-guard probe; run the existing install smoke tests.

Phases 1–3 are all doc edits with no runtime coupling between them, so they may be done in any order; phase 4 depends on 1–2.

## Constraints

- **`shared` output is frozen (AC-2).** Restructuring `init/SKILL.md` must not change the files a `shared` run produces: `CLAUDE.md` content, the single `.specwright/worktrees/` gitignore line, and the vault are byte-for-byte what today's skill writes. The `SKILL.md` *instructions* change; the *output* does not.
- **Idempotency guards are mandatory for every new gitignore line.** Reuse the existing `grep -qxF` + blank-line pattern verbatim for `.specwright/` and `CLAUDE.local.md`, so a same-mode re-run adds no duplicate (AC-5).
- **No auto-migration (AC-6).** A diverging-mode re-run prints consequences + the exact manual switch commands and stops — it writes nothing. A correct switch would `git rm --cached` committed content, which init must never do silently.
- **Detection is filename-based in `init`** (no reliance on `git`, which may be uninitialized), and **`git check-ignore`-based in `run`** (git is always present when a milestone exists).
- **`CLAUDE.md` size cap (≤ 80 lines)** still holds for the dogfood file after its one-line edit.
- **Frontmatter `description` edits** (`init/SKILL.md`, `run/SKILL.md`, `commands/init.md`) must not introduce XML angle brackets `<`/`>` and must stay ≤ 1024 chars — per `.specwright/conventions/skill-validation-requirements.md`, either violation makes the skill silently fail to load. Inside any frontmatter `description:` use bare words (`slug`, `local mode`), never `<slug>`-style tokens.
- Meaningful-comments and no-AI-attribution conventions apply to every edit (embedded shell comments only where a non-obvious *why* clears the bar).

## User Stories / Scenarios

1. **Fresh adopter, team repo they don't own** — runs `/sw:init`, is asked shared/local, picks `local`. Gets `CLAUDE.local.md` (git-ignored) + `.specwright/` scaffolded and git-ignored. `git status` shows nothing to commit for those; their normal code PRs carry no specwright artifacts.
2. **Owner of the repo** — runs `/sw:init`, picks `shared`, gets exactly today's result.
3. **Same-mode re-run** — runs `/sw:init` again, picks the mode already on disk; no duplicate gitignore lines, no overwrites, empty diff.
4. **Diverging re-run** — repo is `shared`, user picks `local`; init prints "this repo is in shared mode; switching to local means … ; run these commands to switch" and stops without changing anything.
5. **Milestone attempt in local mode** — user runs `/sw:run` in a `local` repo; it halts with the not-supported-yet message and dispatches no owner.

## Acceptance Criteria

The acceptance criteria live in the sibling `issue.md` — the `AC-N` IDs defined there are the contract `tasks.md` references and `/sw:review` walks. Do not duplicate them here.

## Risks and Mitigations

| Risk | Mitigation |
|---|---|
| Restructuring `init/SKILL.md` silently changes `shared` output (AC-2 regression) | Runtime verification runs the prescribed shared-mode shell in a sandbox and diffs the produced `CLAUDE.md` + `.gitignore` against the current skill's output; the entry-point Step keeps the exact template path and grep phrase. |
| Blanket `.specwright/` shadows the existing `.specwright/worktrees/` line, tripping validation check 6 | Check 6 matches the literal whole line `.specwright/worktrees/` (`grep -cxF`); a blanket `.specwright/` is a different string and does not affect that count. Keep writing the worktrees line in both modes. |
| `git check-ignore` run guard misfires in a repo whose `.specwright/worktrees/` (but not the vault) is ignored | Probe the vault path `.specwright/milestones`, which is ignored only under the blanket `.specwright/` line, never by the worktrees-only line. |
| Purely conversational criteria (AC-1 always-ask, AC-6 guard message) are not script-observable | Verify them by structural inspection of `init/SKILL.md`; if the interactive prompt cannot be exercised unattended, mark `needs-human-verification` with that reason rather than faking a tick. |

## Open Questions

None.
