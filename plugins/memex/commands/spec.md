---
description: Turn the current conversation into a spec using the memex-brainstorming flow
argument-hint: <optional: topic or direction to focus on>
---

# Spec — Refine and Formalize

Take what was discussed so far in this conversation and enter the spec flow.

**Announce at start:** "Entering spec flow..."

## What to do

1. **Summarize the conversation so far** — extract the key decisions, constraints, and open questions that emerged from the discussion. Present a 3-5 bullet summary and ask: "Is this a fair read of where we landed?"

2. **Enter the `memex-brainstorming` skill** — use the conversation as context, but run the full flow. The prior discussion gives you a head start, not a shortcut. If something important was mentioned casually, confirm it explicitly before locking it into the spec.

3. **Follow the brainstorming flow normally** — clarifying questions, approaches, design sections, design approval (the **only** human review). Then, in one batch, ask exactly four things: confirm the **branch name**, the **mode** (`autonomous`/`reviewed`), whether to use a **worktree** (under `.memex/worktrees/`), and whether to **hand off** before implementing. Record `branch:`/`mode:`/`worktree:` in the spec. Brainstorming writes `design.md` (non-technical: purpose, motivation, definitions, non-goals) and hands off to `memex-writing-plans`, which writes the fused technical `spec.md` + `tasks.md` and **self-reviews the spec in both modes** — the spec-document-reviewer subagent + `/memex:review-spec` + the `validate-spec.sh` mechanical gate (there is **no human spec-review gate**). After design/spec/tasks: **handoff (either mode)** → print a `txt` handoff and stop, else implement → quality gate → reflect; then **deliver per mode** — `autonomous` opens the PR (`/memex:new-pr`) + runs `memex:code-review` to `lgtm` on its own; `reviewed` first asks "open the PR and run code-review?". See `AGENTS.md` (`## Workflow Spec Driven`).

## If `$ARGUMENTS` is provided

Use it to focus or narrow the spec scope. Examples:

- `/memex:spec focus on the auth part` — scope the spec to just the auth subsystem discussed
- `/memex:spec let's split this into two specs` — decompose before speccing

## Key rule

The conversation is **context, not decisions**. Use it to understand what the user wants, but double-check anything important before writing it into the spec. Assumptions from a casual chat are not the same as validated requirements.
