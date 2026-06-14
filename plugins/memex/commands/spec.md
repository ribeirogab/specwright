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

3. **Follow the brainstorming flow normally** — clarifying questions, approaches, design sections, user approval, then **ask the execution mode (autonomous or reviewed)** and record `branch:`/`mode:` in the spec. In **reviewed** mode: write spec → spec self-review loop → user review gate → `/memex:review-spec` external pass → hand off to `memex-writing-plans`. In **autonomous** mode: skip the review loop and the user gate and hand straight off to `memex-writing-plans` (then implement → quality gate → `/memex:new-pr` → `memex:code-review` cycle). See `AGENTS.md` (`## Workflow Spec Driven`).

## If `$ARGUMENTS` is provided

Use it to focus or narrow the spec scope. Examples:

- `/memex:spec focus on the auth part` — scope the spec to just the auth subsystem discussed
- `/memex:spec let's split this into two specs` — decompose before speccing

## Key rule

The conversation is **context, not decisions**. Use it to understand what the user wants, but double-check anything important before writing it into the spec. Assumptions from a casual chat are not the same as validated requirements.
