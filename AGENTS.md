# memex — Agent Instructions

Instructions for AI coding assistants and developers working on the memex codebase.

**Never give up on the right solution.**

## Workflow Spec Driven

Before any work, read `.memex/_index/home.md` (project knowledge), `.memex/constitution.md` (non-negotiables), and `.memex/rules.md` (operational rules).

Implementing, modifying, or creating something? Ask: "Can I describe the complete solution in one sentence?"
- **Yes** → implement directly.
- **Almost** (1-2 open decisions) → ask the user: spec or go direct?
- **No** → enter the Spec flow.

If the user is asking, investigating, or exploring — just answer.

### Spec flow

1. `memex-brainstorming` → design exploration. After the design is approved, the **post-design batch** confirms the **branch name**, the **mode** (`autonomous` / `reviewed`), and whether to **compact**. Brainstorming writes `design.md` (non-technical: purpose, motivation, definitions, non-goals) — the durable write-up of the approved design, not a second review gate.
2. Create the branch. **One branch + one PR per spec** — design, spec, tasks, implementation, and learnings all live in it.
3. `memex-writing-plans` → the fused technical `spec.md` (architecture, file structure, phases, `AC-N` acceptance criteria; records `scope:`/`branch:`/`mode:`) + `tasks.md` (each task names its `AC:` + `Delegable:`). The agent **reviews its own spec** — the spec-document-reviewer subagent (clarity) **and** `/memex:review-spec` (constitution + the `validate-spec.sh` mechanical gate); both run in **both** modes. **No human spec review** — design approval is the only human review.
4. **Compact handoff (either mode)** — if compact was chosen, once design/spec/tasks are written print a `txt` handoff prompt (summary + the three paths + mode) and stop; you `/compact` or open a new chat and paste it to resume. Never compact before the artifacts exist.
5. **Implement.**
6. **Quality gate.** Detect the touched modules' code-quality processes (test, lint, typecheck, build — Makefile, `package.json` scripts, the area's CI) and run them all; nothing you did may break them. Logic added or changed in a tested area without a test → write the missing tests first. **Test integrity:** in a tested area the test count must not silently drop and assertions must not be weakened, skipped, or deleted to pass the gate without an in-spec justification.
7. Reflect; write learnings to `.memex/learnings/` if genuinely useful, without asking — part of delivery. Nothing useful → say "No new learnings".
8. **Deliver.** `autonomous` → open the PR (`/memex:new-pr`) and run the `memex:code-review` cycle — several specialized review subagents that must **all** reach `lgtm` (their roles live in the skill) — hands-off, the recorded mode tells the agent to finish alone. `reviewed` → after reflect, ask "open the PR and run code-review?", then the same on your go-ahead.
9. **Ship the spec.** **PR opened + code-review `lgtm` = shipped.** On `lgtm`, set the spec's frontmatter `status: shipped` + `shipped:` date and move its entry to **Shipped** in `.memex/_index/specs.md`. Do this on the spec's own branch (part of its PR) — not after merge; the later merge to `main` is the maintainer's.

## Non-negotiable rules

All in `.memex/rules.md` — philosophy, git, security, code. Security and architecture are detailed in `.memex/constitution.md`.

## Vault — read from it, write to it

`.memex/` is the project brain. Stuck? Search `learnings/`, `conventions/`, `rules.md`, the relevant spec, and the constitution **before** guessing or asking the user. A non-obvious discovery (gotcha, constraint, surprising behavior) → an atomic note in `.memex/learnings/` (template in `.memex/templates/`), indexed in `.memex/_index/learnings.md`, linked to its spec with a wikilink — without asking permission. On a shipped spec, run the reflection step: one note per non-obvious thing, or say "No new learnings".

## Skills and slash commands

Commands + companion skills ship through the `memex` plugin (marketplace `memex`, in `.claude/settings.json`). Non-Claude agents read canonical copies under `.agents/skills/memex-<name>/`.
- **`/memex:brainstorming`** — design exploration; asks autonomous/reviewed after design approval.
- **`/memex:writing-plans`** — turn an approved design into the technical spec + tasks.
- **`/memex:recall`** / **`/memex:link`** — vault reconnaissance / cross-link analysis.
- **`/memex:spec`** — enter the spec flow from the conversation.
- **`/memex:review-spec`** — external evaluator spec pass (agent self-review, both modes).
- **`/memex:new-pr`** — open the PR per the spec's mode.
- **`/memex:code-review`** — bespoke, portable review cycle to `lgtm`.
- **`/memex:sweep`** / **`/memex:learn`** — vault GC / investigate-and-save.
