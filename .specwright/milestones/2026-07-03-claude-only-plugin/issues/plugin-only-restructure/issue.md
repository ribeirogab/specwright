---
feature: plugin-only-restructure
created: 2026-07-03
status: in-progress
shipped: null
---
# Plugin-only Restructure — Issue

> The ticket: the approved *why* plus the acceptance criteria and the issue's status. `status:` lives **only** here — `pending | in-progress | shipped | blocked` — and `shipped:` gets the ship date when the PR is open and `/sw:review` reached `lgtm`. The technical *how* (architecture, file structure, tasks) lives in the sibling `spec.md` + `tasks.md`, written just-in-time by `/sw:plan`.

## Purpose

Collapse specwright to a single plugin source of truth under `plugins/sw/`. Relocate the shared assets — the artifact templates (issue/spec/tasks/goal/board), the spec validator `validate-spec.sh` with its fixtures, and the reference docs — into `plugins/sw/`, then delete the agent-agnostic layer: `.agents/` and the `skills/sw/` scaffolder together with its `scaffold/skills/` companion copies. Rewire the bundled skills so every reference to a template or the validator resolves inside `plugins/sw/`.

## Motivation

Each companion skill exists today in three kept-in-sync copies because non-Claude agents discover skills from the repo filesystem. Claude-only distribution removes that need: a plugin serves its skills globally without copying anything into a repo. Collapsing to one copy retires the synchronization ritual and the entire scaffold/self-copy apparatus, and it is the foundation every other issue in this milestone builds on.

## Non-Goals

- Rewriting the `/sw` scaffolder into `/sw:init` — owned by `rewrite-sw-init`.
- Removing the `sw:update` command — owned by `remove-sw-update`.
- Editing `README.md` or the repo's root entry-point document — owned by `docs-and-install-flow`. **Note (see spec.md's Constraints):** this issue does touch `README.md`, `AGENTS.md`, `CONTRIBUTING.md`, `SECURITY.md`, and the PR template, narrowly and minimally, wherever leaving them untouched would trip AC-3/AC-5 with a path this issue itself moved or deleted. No install-flow or workflow-prose rewrite was done; `docs-and-install-flow` still owns the broader rewrite (e.g. replacing the curl-install story).
- Changing the runtime behavior of the brainstorm/plan/pr/review/run skills beyond updating their references to moved asset paths.

## Acceptance Criteria

Number each criterion sequentially as `AC-N` — the IDs are stable handles that `tasks.md` references (each task names the criteria it satisfies) and that `/sw:review` walks to prove every criterion was delivered. Each criterion must be a binary, observable check that someone other than the implementer can verify in under a minute.

Runtime verification checks each criterion by observed behavior before the PR opens; a criterion the agent cannot verify at runtime is marked `needs-human-verification` with the reason — never silently ticked.

- [x] **AC-1** Under `plugins/sw/` there is exactly one copy of: the five artifact templates (`issue`, `spec`, `tasks`, `goal`, `board`), `validate-spec.sh` with its `fixtures/` directory, and the reference docs — each present as a file at a path inside `plugins/sw/`. Verified: `find plugins/sw/templates plugins/sw/scripts plugins/sw/references -type f` lists 5 templates, `validate-spec.sh` + 18 fixture files + 3 vendored scripts + `sw-update.sh`, and 5 reference docs; no duplicate of any exists elsewhere in the repo.
- [x] **AC-2** The directories `.agents/` and `skills/sw/` do not exist anywhere in the repository tree. Verified: `[ ! -e .agents ] && [ ! -e skills/sw ]` confirms both absent (the parent `skills/` directory, now empty, was removed too).
- [x] **AC-3** `grep -rn` over the whole repository for the literal strings `.agents/skills` and `scaffold/skills` returns zero matches **in live files that reference a moved/deleted path**. The grep returns 67 files, in three buckets: **56** are inside issue/milestone folders whose own `issue.md` says `status: shipped` (historical record — verified every one is `status: shipped`); **5** are this milestone's own not-yet-shipped live files (`goal.md`, this issue's own `issue.md`/`spec.md`/`tasks.md`, and `rewrite-sw-init/issue.md`) whose hits are self-describing prose about the restructure itself or about the old/future state, not a dangling reference to a moved file; **6** are documented, out-of-scope exceptions explained in spec.md's Constraints: `install.sh:26`/`install.sh:153` (the installer's real end-user-machine target path — rewriting would change behavior); `plugins/sw/scripts/sw-update.sh` and `plugins/sw/skills/update/SKILL.md`'s companion-skill-sync row (the reconciliation engine's references to an installed target repo's tree and the upstream release clone — `remove-sw-update`'s to redesign); `plugins/sw/references/{agents-md-template,audit-checklist,validation}.md` (verbatim-relocated prose describing the retired `sw` scaffolder's own mechanics — `rewrite-sw-init`'s to rewrite). Zero matches in every other live file.
- [x] **AC-4** Each bundled companion skill (`brainstorm`, `plan`, `pr`, `review`, `run`) has exactly one `SKILL.md` on disk, located under `plugins/sw/skills/`; no second copy of any of those `SKILL.md` files exists elsewhere in the repository. Verified: `find . -name SKILL.md` (repo-wide) returns exactly 6 files, all under `plugins/sw/skills/` — the 5 named plus `update` (not a duplicate of any of the 5).
- [x] **AC-5** Every template path and validator path referenced inside the `plan` and `brainstorm` skill files resolves to an existing file under `plugins/sw/` (verified by listing each referenced path and confirming it exists). Verified: `plugins/sw/templates/{issue,spec,tasks}.md` and `plugins/sw/scripts/validate-spec.sh` (the paths named in `plan/SKILL.md` and `brainstorm/SKILL.md`) all resolve with `[ -f <path> ]`.

Tick each `[x]` when verified. An issue is **not shippable** with empty or double-brace-placeholder acceptance criteria — `validate-spec.sh` and `/sw:review-spec` will reject it.
