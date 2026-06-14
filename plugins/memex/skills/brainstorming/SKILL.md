---
name: brainstorming
description: "You MUST use this before any creative work - creating features, building components, adding functionality, or modifying behavior. Explores user intent, requirements and design before implementation."
---

# Brainstorming Ideas Into Designs

Help turn ideas into fully formed designs and specs through natural collaborative dialogue.

Start by understanding the current project context, then ask questions one at a time to refine the idea. Once you understand what you're building, present the design and get user approval.

<HARD-GATE>
Do NOT invoke any implementation skill, write any code, scaffold any project, or take any implementation action until you have presented a design and the user has approved it. This applies to EVERY project regardless of perceived simplicity.
</HARD-GATE>

## Anti-Pattern: "This Is Too Simple To Need A Design"

Every project goes through this process. A todo list, a single-function utility, a config change — all of them. "Simple" projects are where unexamined assumptions cause the most wasted work. The design can be short (a few sentences for truly simple projects), but you MUST present it and get approval.

## Checklist

You MUST create a task for each of these items and complete them in order:

1. **Explore project context** — check files, docs, recent commits
2. **Offer visual companion** (if topic will involve visual questions) — this is its own message, not combined with a clarifying question. See the Visual Companion section below.
3. **Ask clarifying questions** — one at a time, understand purpose/constraints/success criteria
4. **Propose 2-3 approaches** — with trade-offs and your recommendation
5. **Present design** — in sections scaled to their complexity, get user approval after each section
6. **Post-design batch** — once the design is approved, ask in **one** batch exactly three things: confirm the **branch name**, choose the **mode** (`autonomous` | `reviewed`), and whether to **compact** before implementing. Record the branch + mode — writing-plans writes them into `spec.md` frontmatter when it creates the technical spec.
7. **Write the design doc** — save the non-technical write-up of the approved design to `.memex/specs/YYYY-MM-DD-<slug>/design.md` (Purpose/Motivation/Definitions/Non-Goals) and commit. This captures *why*; it is **not** a second human-review gate.
8. **Transition to implementation** — invoke writing-plans skill → it writes the fused technical `spec.md` + `tasks.md`, **self-reviews the spec** (spec-document-reviewer subagent + `/memex:review-spec` + `validate-spec.sh`, both modes, no human gate), then follows the `AGENTS.md` `### Spec flow` tail: **compact (either mode)** → after design/spec/tasks exist, print a ```` ```txt ```` handoff prompt and stop (never compact earlier); otherwise implement → quality gate → reflect, then **deliver per mode** — `autonomous` opens the PR + runs the `memex:code-review` cycle to `lgtm` on its own; `reviewed` first asks "open the PR and run code-review?".

## Process Flow

```dot
digraph brainstorming {
    "Explore project context" [shape=box];
    "Visual questions ahead?" [shape=diamond];
    "Offer Visual Companion\n(own message, no other content)" [shape=box];
    "Ask clarifying questions" [shape=box];
    "Propose 2-3 approaches" [shape=box];
    "Present design sections" [shape=box];
    "User approves design?" [shape=diamond];
    "Post-design batch\n(branch + mode + compact)" [shape=box];
    "Write design doc (design.md)" [shape=box];
    "Invoke writing-plans skill" [shape=doublecircle];

    "Explore project context" -> "Visual questions ahead?";
    "Visual questions ahead?" -> "Offer Visual Companion\n(own message, no other content)" [label="yes"];
    "Visual questions ahead?" -> "Ask clarifying questions" [label="no"];
    "Offer Visual Companion\n(own message, no other content)" -> "Ask clarifying questions";
    "Ask clarifying questions" -> "Propose 2-3 approaches";
    "Propose 2-3 approaches" -> "Present design sections";
    "Present design sections" -> "User approves design?";
    "User approves design?" -> "Present design sections" [label="no, revise"];
    "User approves design?" -> "Post-design batch\n(branch + mode + compact)" [label="yes"];
    "Post-design batch\n(branch + mode + compact)" -> "Write design doc (design.md)";
    "Write design doc (design.md)" -> "Invoke writing-plans skill";
}
```

**The terminal state is invoking writing-plans.** Do NOT invoke frontend-design, mcp-builder, or any other implementation skill. The ONLY skill you invoke after brainstorming is writing-plans.

## The Process

**Understanding the idea:**

- Check out the current project state first (files, docs, recent commits)
- Before asking detailed questions, assess scope: if the request describes multiple independent subsystems (e.g., "build a platform with chat, file storage, billing, and analytics"), flag this immediately. Don't spend questions refining details of a project that needs to be decomposed first.
- If the project is too large for a single spec, help the user decompose into sub-projects: what are the independent pieces, how do they relate, what order should they be built? Then brainstorm the first sub-project through the normal design flow. Each sub-project gets its own spec → plan → implementation cycle.
- For appropriately-scoped projects, ask questions one at a time to refine the idea
- Prefer multiple choice questions when possible, but open-ended is fine too
- Only one question per message - if a topic needs more exploration, break it into multiple questions
- Focus on understanding: purpose, constraints, success criteria

**Exploring approaches:**

- Propose 2-3 different approaches with trade-offs
- Present options conversationally with your recommendation and reasoning
- Lead with your recommended option and explain why

**Presenting the design:**

- Once you believe you understand what you're building, present the design
- Scale each section to its complexity: a few sentences if straightforward, up to 200-300 words if nuanced
- Ask after each section whether it looks right so far
- Cover: architecture, components, data flow, error handling, testing
- Be ready to go back and clarify if something doesn't make sense

**Design for isolation and clarity:**

- Break the system into smaller units that each have one clear purpose, communicate through well-defined interfaces, and can be understood and tested independently
- For each unit, you should be able to answer: what does it do, how do you use it, and what does it depend on?
- Can someone understand what a unit does without reading its internals? Can you change the internals without breaking consumers? If not, the boundaries need work.
- Smaller, well-bounded units are also easier for you to work with - you reason better about code you can hold in context at once, and your edits are more reliable when files are focused. When a file grows large, that's often a signal that it's doing too much.

**Working in existing codebases:**

- Explore the current structure before proposing changes. Follow existing patterns.
- Where existing code has problems that affect the work (e.g., a file that's grown too large, unclear boundaries, tangled responsibilities), include targeted improvements as part of the design - the way a good developer improves code they're working in.
- Don't propose unrelated refactoring. Stay focused on what serves the current goal.

## After the Design

**Post-design batch (ask once, right after the design is approved):**
In **one** batch, ask exactly three things: confirm the **branch name**, choose the **mode** (`autonomous` | `reviewed`), and whether to **compact** before implementing. Record the branch and mode — writing-plans writes them into `spec.md` frontmatter when it creates the technical spec; the recorded `mode:` is registered consent for the feature branch (per `.memex/rules.md`, Git §2). There is no PR question; a PR is always the delivery — the mode only decides whether the agent opens it on its own.

- **`autonomous`** — the recorded mode tells the agent to run all the way to delivery on its own: write design → writing-plans (spec + tasks + self-review) → implement → quality gate → reflect → open the PR (`/memex:new-pr`) → `memex:code-review` cycle to `lgtm`, with no further prompts.
- **`reviewed`** — identical up to and including reflect; then, before delivery, the agent **asks** "open the PR and run code-review?" and proceeds on your go-ahead.

Both modes self-review the spec and may use the compact handoff. The design-approval gate (step 5) is the **only** human review and is **never** skipped — there is **no** human spec-review gate and no "start implementation" gate.

**Documentation:**

- Write the non-technical design write-up to `.memex/specs/YYYY-MM-DD-<slug>/design.md` — Purpose, Motivation, Definitions, Non-Goals. This is a durable record of the approved design's *why*; the technical *how* (architecture, file structure, acceptance criteria) is produced next by writing-plans in `spec.md`.
  - (User preferences for spec location override this default)
- Use elements-of-style:writing-clearly-and-concisely skill if available
- Commit `design.md` to git
- The spec **self-review** (spec-document-reviewer subagent + `/memex:review-spec` + `.memex/scripts/validate-spec.sh`) is **not** run here — it runs inside writing-plans, after the technical `spec.md` exists. There is no human spec-review gate; design approval already gated the work.

**Implementation handoff:**

- Invoke the writing-plans skill — it writes the fused technical `spec.md` + `tasks.md` and self-reviews the spec. Do NOT invoke any other skill — writing-plans is the next step.
- Once design + spec + tasks exist, follow the `AGENTS.md` `### Spec flow` tail:
  - **compact = yes (either mode)** → print a ```` ```txt ```` **handoff prompt** (a one-paragraph summary + the paths to `design`/`spec`/`tasks` + the mode) and stop. The user runs `/compact` (or opens a new chat) and pastes it to resume. **Never compact before the artifacts exist** — the preference was recorded up front; the handoff is produced only now.
  - **compact = no** → implement straight away.
  - **Delivery** (after implement → quality gate → reflect): `autonomous` opens the PR (`/memex:new-pr`) and runs the `memex:code-review` cycle to `lgtm` on its own; `reviewed` first asks "open the PR and run code-review?", then does the same.

## Key Principles

- **One question at a time** - Don't overwhelm with multiple questions
- **Multiple choice preferred** - Easier to answer than open-ended when possible
- **YAGNI ruthlessly** - Remove unnecessary features from all designs
- **Explore alternatives** - Always propose 2-3 approaches before settling
- **Incremental validation** - Present design, get approval before moving on
- **Be flexible** - Go back and clarify when something doesn't make sense

## Visual Companion

A browser-based companion for showing mockups, diagrams, and visual options during brainstorming. Available as a tool — not a mode. Accepting the companion means it's available for questions that benefit from visual treatment; it does NOT mean every question goes through the browser.

**Offering the companion:** When you anticipate that upcoming questions will involve visual content (mockups, layouts, diagrams), offer it once for consent:
> "Some of what we're working on might be easier to explain if I can show it to you in a web browser. I can put together mockups, diagrams, comparisons, and other visuals as we go. This feature is still new and can be token-intensive. Want to try it? (Requires opening a local URL)"

**This offer MUST be its own message.** Do not combine it with clarifying questions, context summaries, or any other content. The message should contain ONLY the offer above and nothing else. Wait for the user's response before continuing. If they decline, proceed with text-only brainstorming.

**Per-question decision:** Even after the user accepts, decide FOR EACH QUESTION whether to use the browser or the terminal. The test: **would the user understand this better by seeing it than reading it?**

- **Use the browser** for content that IS visual — mockups, wireframes, layout comparisons, architecture diagrams, side-by-side visual designs
- **Use the terminal** for content that is text — requirements questions, conceptual choices, tradeoff lists, A/B/C/D text options, scope decisions

A question about a UI topic is not automatically a visual question. "What does personality mean in this context?" is a conceptual question — use the terminal. "Which wizard layout works better?" is a visual question — use the browser.

If they agree to the companion, read the detailed guide before proceeding:
`skills/brainstorming/visual-companion.md`
