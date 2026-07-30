---
name: brainstorm
user-invocable: false
description: "You MUST use this before any creative work - creating features, building components, adding functionality, or modifying behavior. Explores user intent, requirements and design before implementation, concludes whether the work is a single change or a delivery (a large outcome decomposed into changes), and writes the change/delivery artifacts."
---

# Brainstorm — Ideas Into Changes and Deliveries

Help turn ideas into fully formed designs through natural collaborative dialogue, then write them down as **changes** — specwright's single unit of work (1 change = 1 branch = 1 PR). Small work becomes one standalone change; a large outcome becomes a **delivery**: a durable goal, a board, and several changes conducted later by the `sw:run` workflow.

<HARD-GATE>
Do NOT invoke any implementation skill, write any code, scaffold any project, or take any implementation action until you have presented a design and the user has approved it. This applies to EVERY project regardless of perceived simplicity.
</HARD-GATE>

## Anti-Pattern: "This Is Too Simple To Need A Design"

Every project goes through this process. A todo list, a single-function utility, a config change — all of them. "Simple" projects are where unexamined assumptions cause the most wasted work. The design can be short (a few sentences for truly simple projects), but you MUST present it and get approval.

## Anti-Pattern: Forcing Decisions Too Early

A brainstorm is a conversation, not a form. Explore in open prose first — sketch the concept, surface tensions and trade-offs, react to what the user says. Reserve structured multiple-choice questions for genuinely final, well-understood decisions. Never push the user to decide something before the full picture is on the table.

## Checklist

You MUST create a task for each of these items and complete them in order:

1. **Explore project context** — check files, docs, recent commits
2. **Offer visual companion** (if the topic will involve visual questions) — its own message, nothing else in it. See the Visual Companion section below.
3. **Clarify through conversation** — understand purpose, constraints, success criteria; decisions come at the end
4. **Propose 2-3 approaches** — with trade-offs and your recommendation
5. **Present design** — in sections scaled to their complexity, get user approval
6. **Conclude the scope** — after approval: work that fits one change concludes as a **single change**, stated plainly, without presenting the delivery alternative. Suggest a **delivery** — with a preview of the decomposition: change slugs, one-liners, dependencies — only when the scope signals point to one (see Judging the scope). The user decides. The shape of the work is a conclusion of the design, not a command choice.
7. **Post-design batch** — one batch, per shape (see below).
8. **Write the artifacts** — per shape (see below). Commit them.
9. **Next step** — single change: invoke the `sw:plan` workflow. Delivery: print the mandatory handoff and stop.

## Process Flow

```dot
digraph brainstorm {
    "Explore project context" [shape=box];
    "Clarify through conversation" [shape=box];
    "Propose 2-3 approaches" [shape=box];
    "Present design sections" [shape=box];
    "User approves design?" [shape=diamond];
    "Scope: single change or delivery?\n(agent suggests, user decides)" [shape=diamond];
    "Batch: branch + worktree + handoff" [shape=box];
    "Write changes/<date>-<slug>/change.md" [shape=box];
    "Invoke the plan skill" [shape=doublecircle];
    "Batch: worktree" [shape=box];
    "Write delivery.md + board.md + N change.md" [shape=box];
    "Print mandatory handoff, stop\n(resume with sw:run)" [shape=doublecircle];

    "Explore project context" -> "Clarify through conversation";
    "Clarify through conversation" -> "Propose 2-3 approaches";
    "Propose 2-3 approaches" -> "Present design sections";
    "Present design sections" -> "User approves design?";
    "User approves design?" -> "Present design sections" [label="no, revise"];
    "User approves design?" -> "Scope: single change or delivery?\n(agent suggests, user decides)" [label="yes"];
    "Scope: single change or delivery?\n(agent suggests, user decides)" -> "Batch: branch + worktree + handoff" [label="single change"];
    "Batch: branch + worktree + handoff" -> "Write changes/<date>-<slug>/change.md";
    "Write changes/<date>-<slug>/change.md" -> "Invoke the plan skill";
    "Scope: single change or delivery?\n(agent suggests, user decides)" -> "Batch: worktree" [label="delivery"];
    "Batch: worktree" -> "Write delivery.md + board.md + N change.md";
    "Write delivery.md + board.md + N change.md" -> "Print mandatory handoff, stop\n(resume with sw:run)";
}
```

## Judging the scope

While designing, keep asking: does this decompose into several independently shippable changes? Signals of a delivery: the solution spans multiple layers or areas (backend + admin + frontend + email), the decomposition has internal dependencies, no single PR could carry it reviewably. When you see it, **suggest** the delivery with a preview — never force it, and never mention it for work that fits one change (a flag, a fix, one endpoint).

If the user describes something too large even for one delivery, help decompose into deliveries first; each gets its own brainstorm.

## Resolve bundled resources

Before reading a template or invoking the validator, resolve `SW_PLUGIN_ROOT`:

1. use `PLUGIN_ROOT` when it contains `.codex-plugin/plugin.json`;
2. otherwise use `CLAUDE_PLUGIN_ROOT` when it contains
   `.claude-plugin/plugin.json`;
3. otherwise derive the plugin root from this loaded `skills/brainstorm/SKILL.md`
   real path (two parents above the `skills/brainstorm/` directory).

Require `templates/change.md`, `templates/delivery.md`, `templates/board.md`, and
`scripts/validate-spec.sh` beneath that root. Stop before writing when any required
resource is missing. Never resolve bundled resources relative to the target
repository.

## Single change — batch and artifacts

**Batch (one message, exactly three things):** confirm the **branch name**, choose whether to use a **worktree**, and whether to **hand off** before implementing.

**Worktree guard** — before asking, detect whether you are already inside a linked git worktree:

```bash
[ "$(git rev-parse --git-common-dir)" != "$(git rev-parse --git-dir)" ] && echo "already in a linked worktree"
```

- **Already in a linked worktree** → warn the user (name the path) and recommend **no** — work in place.
- **Not in a worktree** → the default is **yes**: `git worktree add .specwright/worktrees/<slug> -b <branch>` and `cd` in before writing the change. specwright only ever **creates** worktrees — never removes one; cleanup is the maintainer's after merge.

When worktree = no, create the branch in place: `git checkout -b <branch>`.

**Artifact:** write `.specwright/changes/YYYY-MM-DD-<slug>/change.md` from
`"$SW_PLUGIN_ROOT/templates/change.md"`: Purpose, Motivation, Non-Goals, numbered
`AC-N` acceptance criteria, frontmatter `status: pending` and `delivery: null`.
This is the durable record of the approved design — not a second review gate. Run
`"$SW_PLUGIN_ROOT/scripts/validate-spec.sh" <change-folder>` before committing —
same baseline as delivery tickets (see Delivery — batch and artifacts). Commit it.

**Next:** handoff = yes → print a ```txt``` handoff (one-paragraph summary + the change path; first line `cd .specwright/worktrees/<slug>` when one was created) and stop — the user resumes in a fresh context. Handoff = no → invoke the plan skill now. Approval of the design authorizes the specwright workflow to continue through delivery without another design review. It never overrides the current host's permission, sandbox, Git, network, credential, or external-action approval policy; obtain every approval that policy requires.

## Delivery — batch and artifacts

**Batch (one message, exactly one thing):** whether change owners run in **worktrees** under `.specwright/worktrees/` (default **yes**; answering no forces serial in-place conduction — parallel dispatch requires worktrees).

**Artifacts:** write the delivery folder plus one flat change folder per change:

- `.specwright/deliveries/YYYY-MM-DD-<slug>/delivery.md` — the delivery's Purpose, Motivation, Success Criteria, Non-Goals. Phrase it in **behavior terms** — no file paths, function names, or storage formats; path-level constraints live in the change tickets. Worked example: the technical hard constraint "`test/taskr.test.js` must pass byte-for-byte unmodified" becomes, at delivery level, "the existing test suite passes without any test being edited" — the ticket that owns the constraint keeps the path. Stable; editing it later is a scope change no agent does alone.
- `.specwright/deliveries/YYYY-MM-DD-<slug>/board.md` — the Changes table (order, slug, depends-on), empty Dispatch Log and Blockers. Order and dependencies live ONLY here.
- `.specwright/changes/YYYY-MM-DD-<slug>/change.md` — one per change, plain kebab slugs (no number prefixes — order is board data), each with Purpose, Non-Goals, `AC-N`, `status: pending`, and `delivery:` set to the delivery folder. Membership is data, not directory nesting: changes live flat under `.specwright/changes/` whether they belong to a delivery or not. The approved decomposition IS the design approval for every change: `sw:run` goes straight to planning, with no brainstorm per change.

Before committing, run `"$SW_PLUGIN_ROOT/scripts/validate-spec.sh"` on **each**
change folder. The planning-stage baseline is **exactly one failure —
check 2, `spec.md not found`** — the spec is written just-in-time later by the
plan skill. Anything else (frontmatter defects, surviving placeholders, vague-verb
criteria) is the planner's to fix before the commit: a ticket that trips the
validator now detonates later in a change owner's gate, on a file that owner must
not edit.

Commit the delivery and change folders.

**Mandatory handoff — the planning session never conducts.** After a long
brainstorm the context is full of exploration: dead ends, rejected decompositions,
half-decisions. The orchestrator must be born clean, reading only the artifacts.
Print a ```txt``` handoff with a one-paragraph summary, the delivery path, and
both valid resume surfaces:

```text
Claude Code: /sw:run <slug>
Codex: $sw:run <slug>
```

Then **stop**. No exceptions, no "start now".

## The Process

**Understanding the idea:**

- Check out the current project state first (files, docs, recent commits)
- Converse in prose; one topic at a time; keep questions open while the picture is forming
- Focus on understanding: purpose, constraints, success criteria

**Exploring approaches:**

- Propose 2-3 different approaches with trade-offs
- Lead with your recommended option and explain why

**Presenting the design:**

- Present in sections scaled to complexity; ask whether each looks right
- Cover: architecture, components, data flow, error handling, testing
- Design for isolation and clarity: units with one purpose, well-defined interfaces, independently understandable. If you can't change a unit's internals without breaking its consumers, the boundaries need work.
- In existing codebases: explore the structure first, follow existing patterns, include targeted improvements where existing problems affect the work — never unrelated refactoring.

**Writing acceptance criteria (the loop's exit condition):**

- Every `AC-N` must be binary, observable, and checkable in under a minute — they are what runtime verification and the `sw:review` workflow later prove. "Make the tests pass" is a good goal; "improve the code" never terminates.
- State a hard constraint **once** — in the criterion (or Non-Goal) that owns it — and reference it from anywhere else that needs it. Every restatement is an amendment hazard: when scope changes, each copy is one more hunk that must be kept coherent.

## Key Principles

- **Converse first, decide at the end** — structured questions only for final, well-understood choices
- **YAGNI ruthlessly** — remove unnecessary features from all designs
- **Explore alternatives** — always propose 2-3 approaches before settling
- **Incremental validation** — present design, get approval before moving on
- **Be flexible** — go back and clarify when something doesn't make sense

## Visual Companion

A browser-based companion for showing mockups, diagrams, and visual options during brainstorming. Available as a tool — not a mode of operation. Accepting it means it's available for questions that benefit from visual treatment; it does NOT mean every question goes through the browser.

**Offering the companion:** when you anticipate visual content (mockups, layouts, diagrams), offer it once for consent:
> "Some of what we're working on might be easier to explain if I can show it to you in a web browser. I can put together mockups, diagrams, comparisons, and other visuals as we go. This feature is still new and can be token-intensive. Want to try it? (Requires opening a local URL)"

**This offer MUST be its own message** — no other content. Wait for the response; if declined, proceed text-only.

**Per-question decision:** even after acceptance, decide per question — would the user understand this better by seeing it than reading it? Browser for content that IS visual (mockups, wireframes, architecture diagrams, side-by-side comparisons); terminal for text (requirements, concepts, trade-off lists, scope decisions).

If they agree, read the sibling `visual-companion.md` before proceeding.
