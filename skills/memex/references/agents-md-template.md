# AGENTS.md Template

`AGENTS.md` is the universal agent entry point at the repo root — it must work for any AI agent, not just Claude Code. Load this reference when creating, repairing, or auditing it.

## Filling rules

Use the project info gathered in Prerequisites to fill `{{Project Name}}` and the project description. The `## Commands (most used)` section should be populated from detected `package.json` scripts (or equivalents) — list the 5-6 most important.

Do **not** leave `{{placeholders}}` in the final file. Phase 5 validation will catch them.

## Size constraint

The final `AGENTS.md` must be **≤ 80 lines** (target 70–80). The file is loaded into every agent session as the entry-point contract; longer than that and it crowds out conversation context, restates content that belongs in `.vault/`, and starts rotting (see `.vault/learnings/agents-md-as-map-not-encyclopedia.md`). Phase 5 validation enforces the cap.

When trimming to fit:

- Tighten the project-description paragraph rather than dropping required section headers.
- Trim the `## Commands (most used)` list to 5–6 entries — it is a list of the most-used commands, not a catalog.
- Replace any longer narrative inside a section with a one-line pointer into `.vault/` (e.g., "See `.vault/learnings/X.md` for the full story").
- Never drop a required section header — the validator checks for all of them.

## Required section headers

The audit checklist (`references/audit-checklist.md`) checks for these section headers — none may be missing:

- `## Before starting any work`
- `## Work ethic — never the lazy path`
- `## When stuck or in doubt — read the vault first`
- `## After completing any task`
- `## After completing a spec`
- `## Commands (most used)`
- `## Knowledge locations`
- `## Skills and slash commands`

## Template

```markdown
# {{Project Name}} — Agent Instructions

{{One paragraph: what the project is, its tech stack, and repo structure.}}

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
2. If there is at least one useful learning, create an atomic note in `.vault/learnings/` per learning (one concept per note) using `.vault/templates/learning.md`, and link it back to the spec folder with a wikilink. Add each new note to `.vault/_index/learnings.md` under the appropriate category.
3. If nothing non-obvious came up, say so explicitly in the final report ("No new learnings from this spec") — silence is not the same as reflection.

## Commands (most used)

{{Fill from detected package.json scripts — list the 5-6 most important ones}}

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

Memex commands and companion skills both ship through the `memex` plugin from the upstream marketplace `ribeirogab-agent-skills` (declared in this repo's `.claude/settings.json`). Non-Claude agents read canonical skill copies under `.agents/skills/memex-<name>/` (exposed via per-agent symlinks to `.codex/skills/`, `.cursor/skills/`, etc., when those discovery dirs exist).

- **`/memex:brainstorming`** — design exploration before writing a spec.
- **`/memex:writing-plans`** — turn an approved design into a task list.
- **`/memex:recall`** — quick project reconnaissance of the `.vault/` vault.
- **`/memex:link`** — analyze the vault for missing cross-links and propose them interactively.
- **`/memex:spec`** — take the current conversation and enter the spec flow, skipping already-discussed questions.
- **`/memex:review-spec`** — external evaluator that reads `.vault/constitution.md` + a spec and flags violations, vagueness, missing acceptance criteria, and duplication of existing learnings/rules. Run this **after** your own spec self-review and **before** moving to `/memex:writing-plans`.
- **`/memex:sweep`** — manual garbage-collection pass over the vault: orphan learnings, MOC entries pointing nowhere, constitution rules never cited, specs whose `tasks-<slug>.md` is fully checked but `status:` is still `draft`. Run on demand, never automatic.
- **`/memex:learn`** — investigate a topic in the project and save findings as a learning note in `.vault/learnings/`.
```
