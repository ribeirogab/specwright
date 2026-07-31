---
feature: {{kebab-slug-of-change}}
created: {{YYYY-MM-DD}}
scope: {{low | medium | high | complex}}
branch: {{feat/kebab-slug-of-change}}
worktree: {{.specwright/worktrees/<slug> | null}}
delivery: {{.specwright/deliveries/YYYY-MM-DD-<slug> | null}}
---
# {{Change Name}} — Plan

**Change:** see the sibling `change.md` for the *why*, the acceptance criteria, and the change `status:`.

> The technical *how*: architecture on top, the task checklist below. Written to be executed by **an agent with no memory of the conversation that produced it** — a fresh session, another model, another host. Every path is exact, every command is runnable, every code step shows the code. An open question here is a defect: resolve it in `change.md`, or record the chosen default under `## Decisions and discoveries` there.
>
> `scope:` is recorded only. `worktree:` is this change's worktree path, or `null` when the work runs in place. `delivery:` is the parent delivery folder, or `null` when standalone.

## Architecture

{{the technical approach and why it beat the alternatives; component breakdown, data flow, the patterns of this codebase it follows}}

## File Structure

{{every file created, modified, or deleted, with a one-line responsibility each}}

## Phase Ordering

{{natural phases with their dependencies, or "Single phase."}}

## Constraints

{{technical, organizational, or timing constraints that shape the solution — including any recorded in a sibling change's decisions}}

## Tasks

Each task names the criteria it satisfies, the files it touches, and the one command that proves it. The checkboxes are the **resume state**: ```sw:implement``` continues at the first unticked box, so a run interrupted mid-task picks up exactly where it stopped.

Steps are one action each (2–5 minutes): write the failing test — run it and watch it fail — write the minimal implementation — run the tests — commit.

**No placeholders.** Never write "TBD", "TODO", "implement later", "add appropriate error handling", "write tests for the above" without the test code, or "similar to T1" instead of repeating the code. A step that describes instead of showing is not a step.

### T1: {{task name}}

**AC:** {{AC-N it satisfies, e.g. AC-1, AC-3}}
**Files:**
- Create: `{{exact/repository-relative/path}}`
- Modify: `{{exact/repository-relative/path}}`
**Validation:** {{one exact command that verifies this task}}

- [ ] Write the failing test

```{{language}}
{{the actual test code}}
```

- [ ] Run it and confirm it fails: `{{exact command}}` → {{expected failure}}
- [ ] Write the minimal implementation
- [ ] Run the tests and confirm they pass: `{{exact command}}`
- [ ] Commit

### T2: {{task name}}

**AC:** {{AC-N}}
**Files:**
- Modify: `{{exact/repository-relative/path}}`
**Validation:** {{one exact command}}

- [ ] {{action}}
- [ ] {{verification}}
- [ ] Commit
