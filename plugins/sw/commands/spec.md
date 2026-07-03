---
description: Turn the current conversation into an issue (or milestone) using the specwright brainstorm flow
argument-hint: <optional: topic or direction to focus on>
---

# Spec — Refine and Formalize

Take what was discussed so far in this conversation and enter the issue flow.

**Announce at start:** "Entering the issue flow..."

## What to do

1. **Summarize the conversation so far** — extract the key decisions, constraints, and open questions that emerged from the discussion. Present a 3-5 bullet summary and ask: "Is this a fair read of where we landed?"

2. **Enter the `/sw:brainstorm` skill** — use the conversation as context, but run the full flow. The prior discussion gives you a head start, not a shortcut. If something important was mentioned casually, confirm it explicitly before locking it in.

3. **Follow the brainstorm flow normally** — clarifying conversation, approaches, design sections, design approval (the **only** human review). After approval the brainstorm concludes the **scope** — single issue or milestone (agent suggests, user decides) — runs the matching post-design batch, and writes the artifacts: a standalone `issue.md` under `.specwright/issues/`, or `goal.md` + `board.md` + N `issue.md` under `.specwright/milestones/`. Single issue continues into `/sw:plan` (spec + tasks + self-review, implement, quality gate, runtime verification, `/sw:pr`, `/sw:review` to `lgtm`); a milestone always ends planning with a handoff and is conducted later by `/sw:run`. See `CLAUDE.md` (`## Workflow Spec Driven`).

## If `$ARGUMENTS` is provided

Use it to focus or narrow the scope. Examples:

- `/sw:spec focus on the auth part` — scope the issue to just the auth subsystem discussed
- `/sw:spec let's split this into two issues` — decompose before formalizing

## Key rule

The conversation is **context, not decisions**. Use it to understand what the user wants, but double-check anything important before writing it into the issue. Assumptions from a casual chat are not the same as validated requirements.
