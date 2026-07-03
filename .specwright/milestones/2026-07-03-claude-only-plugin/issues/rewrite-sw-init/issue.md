---
feature: rewrite-sw-init
created: 2026-07-03
status: shipped
shipped: 2026-07-03
---
# Rewrite /sw as /sw:init — Issue

> The ticket: the approved *why* plus the acceptance criteria and the issue's status. `status:` lives **only** here — `pending | in-progress | shipped | blocked` — and `shipped:` gets the ship date when the PR is open and `/sw:review` reached `lgtm`. The technical *how* (architecture, file structure, tasks) lives in the sibling `spec.md` + `tasks.md`, written just-in-time by `/sw:plan`.

## Purpose

Replace the `/sw` scaffolder skill with a `/sw:init` plugin skill scoped to per-repository content only. It creates the `.specwright/` vault (`conventions/` with its signpost README, `issues/` and `milestones/` each with a `.gitkeep`), writes a `CLAUDE.md` entry point that includes a line declaring the `sw` plugin required (with the two global install commands), and appends the worktrees line to `.gitignore`. It writes no machine configuration: no `.claude/settings.json`, no self-copy, no per-agent symlinks.

## Motivation

With the plugin providing all tooling globally, the only thing a repository still needs is its own content. The old `/sw` conflated installing the tooling — now the plugin's job — with per-repo setup. Stripping it to content-only turns it into a small single-purpose skill and deletes the settings-merge, self-copy, and symlink logic outright. The mandatory-plugin line in `CLAUDE.md` is loaded into agent context, so a repo opened without the plugin declares its own requirement and points at the fix.

## Non-Goals

- Moving shared assets or deleting `.agents/` / `skills/sw/` — done by `plugin-only-restructure` (this issue depends on it).
- Writing or auditing `.claude/settings.json` — removed by design; `/sw:init` never touches it.
- Auto-installing the plugin.
- Documenting the global install flow in `README.md` — owned by `docs-and-install-flow`.

## Acceptance Criteria

Number each criterion sequentially as `AC-N` — the IDs are stable handles that `tasks.md` references (each task names the criteria it satisfies) and that `/sw:review` walks to prove every criterion was delivered. Each criterion must be a binary, observable check that someone other than the implementer can verify in under a minute.

Runtime verification checks each criterion by observed behavior before the PR opens; a criterion the agent cannot verify at runtime is marked `needs-human-verification` with the reason — never silently ticked.

- [x] **AC-1** Running `/sw:init` in a repository with no `.specwright/` creates `.specwright/conventions/` containing the signpost `README.md`, plus `.specwright/issues/` and `.specwright/milestones/` each containing a `.gitkeep`. Verified by executing the skill's documented Step 1 bash literally against a throwaway `git init` scratch repo: `find .specwright -type f` returned exactly `conventions/README.md`, `issues/.gitkeep`, `milestones/.gitkeep`.
- [x] **AC-2** Running `/sw:init` creates a `CLAUDE.md` at the repository root whose text includes the `sw` plugin requirement and both commands `claude plugin marketplace add ribeirogab/specwright` and `claude plugin install sw@specwright`. Verified in the same scratch repo: generated `CLAUDE.md` from `claude-md-template.md` with the directory-name fallback (no `package.json` present); `grep -c` for both install commands returned `1` each.
- [x] **AC-3** Running `/sw:init` appends the line `.specwright/worktrees/` to `.gitignore` when it is absent; a second run adds no duplicate line (the file has exactly one occurrence of that line). Verified: first run appended the line (`grep -cxF` returned `1`); re-ran the same idempotency-guarded step a second time — count stayed `1`, `conventions/README.md` and `CLAUDE.md` byte-identical (md5 unchanged) before and after the second run.
- [x] **AC-4** After `/sw:init` runs in a repository that had no `.claude/`, there is no `.claude/settings.json`, no `.agents/skills/sw` self-copy, and no per-agent skill symlink created by the skill. Verified in the scratch repo: `[ -e .claude/settings.json ]` → absent; `[ -e .agents/skills/sw ]` → absent; `find . -type l` → no symlinks; full post-run tree contained only `.specwright/{conventions/README.md,issues/.gitkeep,milestones/.gitkeep}`, `CLAUDE.md`, `.gitignore`.
- [x] **AC-5** The `sw:init` skill files contain none of the strings `.claude/settings.json`, `extraKnownMarketplaces`, `enabledPlugins`, `self-copy`, or per-agent symlink directory names (`.codex`, `.cursor`, `.opencode`, `.aider`). Verified: `grep -rniE` for all of these over `plugins/sw/skills/init/`, `plugins/sw/references/claude-md-template.md`, `plugins/sw/references/audit-checklist.md`, and `plugins/sw/references/validation.md` returned zero matches.
- [x] **AC-6** The entry-point template shipped with the skill is named for `CLAUDE.md` (e.g. `claude-md-template.md`), and a `CLAUDE.md` generated from it contains no surviving double-brace placeholder token. Verified: `plugins/sw/references/claude-md-template.md` exists at that exact path; a literal-string grep for the open-brace-open-brace marker against the scratch repo's generated `CLAUDE.md` returned zero matches.

**Verification method note:** this sandbox has no live Claude Code plugin harness to invoke a literal `/sw:init` slash command, so verification executed the skill's documented bash steps by hand, exactly as written in `plugins/sw/skills/init/SKILL.md`, against a throwaway `git init` scratch directory (outside this repo) — not `needs-human-verification`, since every operation and its output was directly observed, but the one gap worth naming: an actual end-to-end slash-command invocation through the installed plugin has not been exercised.

Tick each `[x]` when verified. An issue is **not shippable** with empty or double-brace-placeholder acceptance criteria — `validate-spec.sh` and `/sw:review-spec` will reject it.
