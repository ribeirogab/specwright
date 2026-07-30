---
name: spec
user-invocable: false
description: "Turn the current conversation into a change or delivery using the specwright brainstorm flow."
---

# Spec — Refine and Formalize

Take what was discussed so far in this conversation and enter the change flow.

**Announce at start:** "Entering the change flow..."

## What to do

1. **Summarize the conversation so far** — extract the key decisions, constraints, and open questions that emerged from the discussion. Present a 3-5 bullet summary and ask: "Is this a fair read of where we landed?"

2. **Enter the `sw:brainstorm` workflow** — use the conversation as context, but run the full flow. The prior discussion gives you a head start, not a shortcut. If something important was mentioned casually, confirm it explicitly before locking it in.

3. **Follow the brainstorm flow normally** — clarifying conversation, approaches, design sections, design approval (the **only** design review; host permission and approval policy still applies to every action). After approval the brainstorm concludes the **scope** — single change or delivery (agent suggests, user decides) — runs the matching post-design batch, and writes the artifacts: a standalone `change.md` under `.specwright/changes/`, or `delivery.md` + `board.md` under `.specwright/deliveries/` plus N `change.md` under `.specwright/changes/`. A single change continues into the plan skill (spec + tasks + self-review, implement, quality gate, runtime verification, PR, review to `lgtm`); a delivery always ends planning with a handoff and is conducted later by the run skill. See the applicable canonical `AGENTS.md` or `AGENTS.override.md`.

## If `$ARGUMENTS` is provided

Use it to focus or narrow the scope. Examples:

- `sw:spec focus on the auth part` — scope the change to just the auth subsystem discussed
- `sw:spec let's split this into two changes` — decompose before formalizing

## Key rule

The conversation is **context, not decisions**. Use it to understand what the user wants, but double-check anything important before writing it into the change. Assumptions from a casual chat are not the same as validated requirements.
