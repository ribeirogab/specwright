# memex — Agent Instructions

Instructions for AI coding assistants and developers working on the memex codebase.

**Never give up on the right solution.**

## Workflow Spec Driven

Before any work, read `.vault/_index/home.md` (project knowledge), `.vault/constitution.md` (non-negotiables), and `.vault/rules.md` (operational rules).

Implementing, modifying, or creating something? Ask: "Can I describe the complete solution in one sentence?"
- **Yes** → implement directly.
- **Almost** (1-2 open decisions) → ask the user: spec or go direct?
- **No** → enter the Spec flow.

If the user is asking, investigating, or exploring — just answer.

### Spec flow

1. `memex-brainstorming` → `spec-<slug>.md`. After the design is approved, brainstorming asks the execution **mode: autonomous or reviewed**; the spec records `branch:` + `mode:`. The recorded mode is registered consent for the feature branch.
2. Create the branch. **One branch + one PR per spec** — spec, plan, tasks, implementation, and learnings all live in it.
3. **reviewed** → `/memex:review-spec` → `memex-writing-plans` → `plan-<slug>.md` + `tasks-<slug>.md` → implement. **autonomous** → skip the review, straight to `memex-writing-plans` → implement.
4. Reflect; write learnings to `.vault/learnings/` if genuinely useful, without asking — part of delivery. Nothing useful → say "No new learnings".
5. **Quality gate.** Detect the touched modules' code-quality processes (test, lint, typecheck, build — Makefile, `package.json` scripts, the area's CI) and run them all; nothing you did may break them. Logic added or changed in a tested area without a test → write the missing tests first.
6. **PR via `/memex:new-pr`.** autonomous → open right after the quality gate; reviewed → wait for the user to validate and ask.
7. **Review cycle.** Dispatch a sub-agent running `memex:code-review` over the branch. Fix the findings that make sense; contest the rest until consensus. Push, request a fresh review, repeat until `lgtm`.

## Non-negotiable rules

All in `.vault/rules.md` — philosophy, git, security, code. Security and architecture are detailed in `.vault/constitution.md`.

## Vault — read from it, write to it

`.vault/` is the project brain. Stuck? Search `learnings/`, `conventions/`, `rules.md`, the relevant spec, and the constitution **before** guessing or asking the user. A non-obvious discovery (gotcha, constraint, surprising behavior) → an atomic note in `.vault/learnings/` (template in `.vault/templates/`), indexed in `.vault/_index/learnings.md`, linked to its spec with a wikilink — without asking permission. On a shipped spec, run the reflection step: one note per non-obvious thing, or say "No new learnings".

## Skills and slash commands

Commands + companion skills ship through the `memex` plugin (marketplace `memex`, in `.claude/settings.json`). Non-Claude agents read canonical copies under `.agents/skills/memex-<name>/`.
- **`/memex:brainstorming`** — design exploration; asks autonomous/reviewed after design approval.
- **`/memex:writing-plans`** — turn an approved design into plan + tasks.
- **`/memex:recall`** / **`/memex:link`** — vault reconnaissance / cross-link analysis.
- **`/memex:spec`** — enter the spec flow from the conversation.
- **`/memex:review-spec`** — external evaluator pass (reviewed mode).
- **`/memex:new-pr`** — open the PR per the spec's mode.
- **`/memex:code-review`** — bespoke, portable review cycle to `lgtm`.
- **`/memex:sweep`** / **`/memex:learn`** — vault GC / investigate-and-save.
