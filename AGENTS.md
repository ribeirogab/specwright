# agent-skills — Agent Instructions

`agent-skills` is the author's personal library of agent skills and slash commands, written in markdown with occasional shell scripts. The flagship is `skills/memex/`, an idempotent scaffolder that installs an externalized project memory (the "memex") into target repos. There is no build system, no package manager, and no test runner at the repo root — each skill is self-contained under `skills/<name>/`. The repo dogfoods its own memex: scaffolded helper skills live canonically under `.agents/skills/<name>/` and are exposed via per-agent symlinks (`.claude/skills/<name>` → `.agents/skills/<name>`); the `/memex-*` slash commands live in `.claude/commands/` (Claude Code-specific concept).

## Before starting any work

1. **Read `.vault/_index/home.md`** for project-specific knowledge.
2. **Read `.vault/constitution.md`** for non-negotiable principles.
3. **If the user is asking you to implement, modify, or create something**, assess the request: "Can I describe the complete solution in one sentence?"
   - **Yes** → implement directly.
   - **No** → invoke `memex-brainstorming` → `spec-<slug>.md` → self-review the spec → `/memex:review-spec` for an external evaluator pass → `memex-writing-plans` → `plan-<slug>.md` + `tasks-<slug>.md` → implement.
   - **Almost** (1-2 open decisions) → ask the user whether to spec or go direct.

   If the user is asking a question, investigating, or exploring — just answer.

## Work ethic — never the lazy path

When you see two ways to do something — one quick-and-shallow, one correct-and-thorough — **default to correct**. You may *surface* the lighter option to the user with the tradeoffs ("here's a faster path that skips X, here's the proper one that handles X — which do you want?"), but never silently pick the worse one to finish faster. Cutting corners now creates work later, and the user notices. If the task is hard, the answer is to do it right, not to redefine "done" downward.

## When stuck or in doubt — read the vault first

`.vault/` is your project brain. You have been writing to it; **read from it too**. Before grinding on a hard problem, before guessing, before asking the user a question whose answer might already be captured: search `.vault/learnings/`, `.vault/conventions/`, `.vault/rules/`, the relevant spec in `.vault/specs/`, and `.vault/constitution.md`. Use the `memex-recall` skill or grep directly. Reading the vault is the **first move** on a hard problem, not the last. If the vault answers the question, cite the note; if it almost answers it, update the note after you fill the gap.

## After completing any task

If you discovered something non-obvious during implementation — a gotcha, a constraint, a surprising behavior — create an atomic note in `.vault/learnings/` using the template at `.vault/templates/learning.md`. Link it to the relevant spec with a wikilink if applicable. Do this without asking permission.

## After completing a spec

When a spec is shipped (all tasks in `tasks-<slug>.md` done, spec marked `shipped`), always run an explicit reflection step before closing out — do not skip this:

1. Ask yourself: "What did I learn implementing this that wasn't obvious from the spec?" Consider gotchas hit, constraints discovered, surprising framework/library behavior, decisions that reversed mid-implementation, and anything a future implementer would waste time rediscovering.
2. If there is at least one useful learning, create an atomic note in `.vault/learnings/` per learning (one concept per note) using `.vault/templates/learning.md`. The new learning's `related:` field MUST include a wikilink back to the spec — bidirectional backlink is not optional. Symmetrically, if the spec gained a `related:` entry pointing at the new learning, add it. Add each new note to `.vault/_index/learnings.md` under the appropriate category.
3. If nothing non-obvious came up, say so explicitly in the final report ("No new learnings from this spec") — silence is not the same as reflection.

## Commands (most used)

This repo has no package.json and no build system. The most used commands are git workflow and the memex slash commands themselves.

- `git status` / `git diff` — inspect the working tree.
- `git switch -c feat/<name>` — start a new feature branch (never commit directly to `main`).
- `/memex` — invoke this skill (in this repo or any other) to audit/scaffold the memex.
- `/memex:spec` — turn the current conversation into a spec.
- `/memex:sweep` — manual garbage-collection pass over `.vault/`.

Full command catalog: `.vault/learnings/commands-catalog.md` _(create this note after setup)_.

## Knowledge locations

| What | Where |
|---|---|
| Non-negotiable principles | `.vault/constitution.md` |
| Specs (active + shipped) | `.vault/specs/` |
| Architecture, patterns, gotchas | `.vault/learnings/` (indexed by `.vault/_index/learnings.md`) |
| Code style conventions | `.vault/conventions/` (indexed by `.vault/_index/conventions.md`) |
| Project-specific rules | `.vault/rules/` |
| Spec template | `.vault/specs/_template/` |
| Note templates (learning, rule) | `.vault/templates/` |

## Skills and slash commands

> All memex entries shown in Claude Code syntax (plugin namespace `memex:`). Codex users invoke as `$memex-<verb>` via skill mention. Cursor users as `@memex-<verb>` via rule reference.

Memex commands and companion skills both ship through the `memex` plugin from the upstream marketplace `ribeirogab-agent-skills` (declared in `.claude/settings.json`). Non-Claude agents read canonical skill copies under `.agents/skills/memex-<name>/` (exposed via per-agent symlinks to `.codex/skills/`, `.cursor/skills/`, etc., when those discovery dirs exist).

- **`/memex:brainstorming`** — design exploration before writing a spec.
- **`/memex:writing-plans`** — turn an approved design into a task list.
- **`/memex:recall`** — quick project reconnaissance of the `.vault/` vault.
- **`/memex:link`** — analyze the vault for missing cross-links and propose them interactively.
- **`/memex:spec`** — take the current conversation and enter the spec flow, skipping already-discussed questions.
- **`/memex:review-spec`** — external evaluator that reads `.vault/constitution.md` + a spec and flags violations, vagueness, missing acceptance criteria, and duplication of existing learnings/rules. Run this **after** your own spec self-review and **before** moving to `/memex:writing-plans`.
- **`/memex:sweep`** — manual garbage-collection pass over the vault: orphan learnings, MOC entries pointing nowhere, constitution rules never cited, specs whose `tasks-<slug>.md` is fully checked but `status:` is still `draft`. Run on demand, never automatic.
- **`/memex:learn`** — investigate a topic in the project and save findings as a learning note in `.vault/learnings/`.
