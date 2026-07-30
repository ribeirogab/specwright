---
feature: opencode-host-support
created: 2026-07-29
status: pending
shipped: null
delivery: null
---
# OpenCode Host Support — Change

> The ticket: the approved *why* plus the acceptance criteria and the change's status. `status:` lives **only** here — `pending | in-progress | shipped | blocked` — and `shipped:` gets the ship date when the PR is open and ```sw:review``` reached `lgtm`. The technical *how* (architecture, file structure, tasks) lives in the sibling `spec.md` + `tasks.md`, written just-in-time by ```sw:plan```. Delivery membership is data: `delivery:` holds the parent delivery folder, or `null` for a standalone change.

## Purpose

Make specwright tri-host: an OpenCode session gets the same nine workflow skills, nine explicit `/sw-*` command surfaces, and four `sw-*` specialist roles that Claude Code and Codex get today — installed and migrated per project by the same deterministic updater, with the skills remaining the single implementation and OpenCode becoming a third thin adapter.

## Motivation

specwright is currently dual-host (Claude Code + Codex). OpenCode already reads `AGENTS.md` natively and loads `SKILL.md` files in the exact format this repository ships, so the vault and the workflow implementation work there for free — but nothing else does: there is no documented install path, no explicit command surface (OpenCode derives `/name` from a filename in `.opencode/command/`, with no plugin namespacing), and no project-scoped `sw-*` roles with restricted permissions (OpenCode agents live in `.opencode/agent/` with `mode`/`permission` frontmatter). Users working in OpenCode cannot run the delivery orchestrator, the three-lane review, or the worker delegation with the authority boundaries the workflow depends on. The maintainer's own daily driver is OpenCode, so dogfooding the full workflow requires first-class support.

## Non-Goals

- No npm/TypeScript OpenCode plugin and no build or publish pipeline; distribution stays "clone the repository + `skills.paths`".
- No renaming of skill frontmatter `name:` values to `sw-*`; the skill-name collision caveat in OpenCode is documented, not engineered away in this change.
- No `--hosts` selective-installation flag; managed state is installed tri-host unconditionally, matching today's unconditional dual-host behavior.
- No pinned `model:` in OpenCode agent templates (OpenCode is multi-provider; agents inherit the session model).
- No changes to Claude Code or Codex adapter behavior, manifests, or surfaces.
- No verification of the brainstorm visual companion under OpenCode; its launch instructions stay Claude/Codex-only with an explicit unverified note.

## Acceptance Criteria

Number each criterion sequentially as `AC-N` — the IDs are stable handles that `tasks.md` references (each task names the criteria it satisfies) and that ```sw:review``` walks to prove every criterion was delivered. Each criterion must be a binary, observable check that someone other than the implementer can verify in under a minute. **No vague verbs** ("works well", "is fast", "is robust", "handles errors gracefully") — replace them with specific, measurable conditions. If a criterion cannot be verified without reading the implementation, it is not an acceptance criterion; rewrite it. State a hard constraint once — in the criterion (or Non-Goal) that owns it — and reference it elsewhere; every restatement is an amendment hazard.

Runtime verification checks each criterion by observed behavior before the PR opens; a criterion the agent cannot verify at runtime (e.g. UI without browser capability) is marked `needs-human-verification` with the reason — never silently ticked.

- [ ] **AC-1** `plugins/sw/templates/opencode-commands/` contains exactly nine templates (`sw-init.md`, `sw-brainstorm.md`, `sw-spec.md`, `sw-plan.md`, `sw-run.md`, `sw-review.md`, `sw-review-spec.md`, `sw-pr.md`, `sw-update.md`), each a thin redirect that names its target skill and passes `$ARGUMENTS` through, with no host-specific behavior beyond the redirect.
- [ ] **AC-2** `plugins/sw/templates/opencode-agents/` contains exactly four templates (`sw-change-owner.md`, `sw-task-worker.md`, `sw-reviewer.md`, `sw-spec-document-reviewer.md`), each with `mode: subagent` and no `model:` key in frontmatter; the two reviewer templates deny edits via `permission`, and each body ports the same role contract as its Claude and Codex counterparts.
- [ ] **AC-3** On a fixture project, `sw_update.py --plan` classifies a project missing OpenCode state as not `up-to-date`, lists exactly 13 additional managed operations (4 agents + 9 commands), and `--apply --expect-plan <id>` installs all 13 byte-identical to the installed templates; a second `--plan` then reports `up-to-date` with zero operations.
- [ ] **AC-4** In shared mode the 13 `.opencode/` files are tracked with no new ignore rules; in local mode `.gitignore` gains exactly the patterns covering `.opencode/agent/sw-*.md` and `.opencode/command/sw-*.md`, and the updater installs the files anyway.
- [ ] **AC-5** Modifying any one installed `.opencode/agent/sw-*.md` or `.opencode/command/sw-*.md` file makes `--plan` classify the project as `drifted` and refuse to produce an applicable plan.
- [ ] **AC-6** README gains an OpenCode install subsection (clone + `skills.paths` pointing at `plugins/sw/skills`), the command-parity table gains an OpenCode column with `/sw-*` surfaces for all nine workflows, and the repository-layout section lists the two new template directories.
- [ ] **AC-7** The `sw:managed` block template in `references/agents-md-template.md` names OpenCode as a third command surface (`/sw-*`), and every skill handoff block that today prints only the Claude Code and Codex resume surfaces also prints the OpenCode surface.
- [ ] **AC-8** `references/validation.md`, `references/audit-checklist.md`, and `references/vault-files.md` each cover the 13 OpenCode managed files and their mode-specific ignore rules, and the updater test suites in `tests/` pass with new cases covering install, drift, and `up-to-date` for the OpenCode files.
- [ ] **AC-9** This repository dogfoods the result: its own `.opencode/agent/` and `.opencode/command/` files are installed by the updater, tracked, byte-match the templates, and a real OpenCode session in this checkout discovers the nine `/sw-*` commands and the four `sw-*` agents.

Tick each `[x]` when verified. A change is **not shippable** with empty or double-brace-placeholder acceptance criteria — `validate-spec.sh` and ```sw:review-spec``` will reject it.
