# Vault Files — File Specifications

All concrete file contents the orchestrator writes when scaffolding the `.vault/` vault. Load this reference only when you are creating or repairing one of these files.

## Contents

- [Substitution rules — read first](#substitution-rules--read-first)
- [Obsidian config (3 JSONs)](#obsidian-config)
- [Atomic note templates (3 files)](#atomic-note-templates)
- [Spec templates (3 files) + naming convention](#spec-templates)
- [MOCs (5 files)](#mocs)

---

## Substitution rules — read first

Files in this reference fall into **two distinct groups**. Treat them differently when scaffolding:

### Group A — Templates (keep `{{}}` placeholders intact)

These files are templates that the user/agent will fill **later**, when creating an individual note or spec. Copy them verbatim. **Do NOT substitute any `{{}}` placeholder during scaffolding.**

- `.vault/templates/learning.md` (has `{{title}}`, `{{date}}`, `{{one-paragraph technical insight}}`, …)
- `.vault/templates/rule.md` (has `{{title}}`, `{{category}}`, `{{severity}}`, …)
- `.vault/templates/convention.md` (has `{{title}}`, `{{category}}`, …)
- `.vault/specs/_template/spec.md` (has `{{Feature Name}}`, `{{kebab-slug-of-feature}}`, …)
- `.vault/specs/_template/plan.md` (same)
- `.vault/specs/_template/tasks.md` (same)

### Group B — Project-bound files (substitute `{{Project Name}}` now)

These files describe the current project specifically. Substitute every occurrence of `{{Project Name}}` with the actual project name from Prerequisites **before writing** the file. No `{{}}` placeholder may survive in the written file.

- `.vault/_index/home.md`
- `.vault/_index/specs.md`
- `.vault/_index/learnings.md`
- `.vault/_index/conventions.md`
- `.vault/rules.md`

Surviving `{{Project Name}}` in any Group B file is caught by Phase 5 validation (check #12) and fails the run.

### Group C — Inert (no placeholders to worry about)

- The 3 `.obsidian/*.json` files — pure JSON, no placeholders.

---

## Obsidian config

**`.vault/.obsidian/app.json`:**
```json
{
  "promptDelete": true,
  "alwaysUpdateLinks": true,
  "newLinkFormat": "relative",
  "useMarkdownLinks": false,
  "attachmentFolderPath": "attachments",
  "showLineNumber": true
}
```

**`.vault/.obsidian/appearance.json`:**
```json
{
  "baseFontSize": 16,
  "theme": "obsidian",
  "cssTheme": ""
}
```

**`.vault/.obsidian/core-plugins.json`:**
```json
{
  "file-explorer": true,
  "global-search": true,
  "switcher": true,
  "graph": true,
  "backlink": true,
  "outgoing-link": true,
  "tag-pane": true,
  "page-preview": true,
  "templates": true,
  "note-composer": true,
  "command-palette": true,
  "outline": true,
  "word-count": true,
  "file-recovery": true,
  "canvas": true,
  "properties": true,
  "bookmarks": true,
  "editor-status": true
}
```

---

## Atomic note templates

**`.vault/templates/learning.md`:**
```markdown
---
tags:
  - learning
related:
  - "[[related-note]]"
created: {{date}}
---
# {{title}}

{{one-paragraph technical insight}}

## Context

{{when/where this was discovered — feature, PR, incident, debugging session}}

## How to Apply

{{concrete, actionable instruction: what to do differently next time}}
```

**`.vault/templates/rule.md`:**
```markdown
---
tags:
  - rule
  - {{category: safety | workflow | code-style}}
severity: {{critical | important | advisory}}
applies-to:
  - {{scope}}
created: {{date}}
---
# {{title}}

{{short imperative statement of the rule}}

## Why

{{the reason — usually a past incident, constraint, or strong preference}}

## How to Apply

{{concrete instruction for when/how to apply this rule}}
```

**`.vault/templates/convention.md`:**
```markdown
---
tags:
  - convention
  - {{category}}
applies-to:
  - {{scope}}
created: {{date}}
---
# {{title}}

{{short imperative statement of the convention}}

## Why

{{the reason — clarity, consistency, tooling requirement, or team decision}}

## How to Apply

{{concrete instruction with examples}}
```

---

## Spec templates

**`.vault/specs/_template/spec.md`:**
```markdown
---
status: draft
feature: {{kebab-slug-of-feature}}
created: {{YYYY-MM-DD}}
shipped: null
branch: {{feat/kebab-slug-of-feature}}
mode: {{autonomous | reviewed}}
---
# {{Feature Name}} — Spec

**Status:** Draft
**Scope:** {{one-sentence scope statement}}

## Context

{{why this feature exists, what triggered it, relevant constraints}}

## Problem Statement

{{what specific problem this feature solves}}

## Non-Goals

{{what this feature explicitly does NOT solve — prevents scope creep}}

## Constraints

{{technical, organizational, or timing constraints that shape the solution}}

## User Stories / Scenarios

{{numbered user flows or acceptance scenarios}}

## Acceptance Criteria

Each criterion must be a binary, observable check that someone other than the implementer can verify in under a minute. **No vague verbs** ("works well", "is fast", "is robust", "handles errors gracefully") — replace them with specific, measurable conditions. If a criterion cannot be verified without reading the implementation, it is not an acceptance criterion; rewrite it.

- [ ] {{ e.g. `POST /users` with a duplicate email returns 409 and body `{"code":"DUPLICATE_EMAIL"}` }}
- [ ] {{ e.g. p95 latency for `GET /feed` stays under 200ms with a 1k-row fixture }}
- [ ] {{ e.g. the migration script runs idempotently — running it twice on the same DB yields no diff }}
- [ ] {{ ... }}

Tick each `[x]` when verified. A spec is **not shippable** with empty or `{{placeholder}}` acceptance criteria — `/memex-review-spec` will reject it.

## Risks and Mitigations

| Risk | Mitigation |
|---|---|
| {{risk}} | {{mitigation}} |

## Open Questions

{{use [NEEDS CLARIFICATION: specific question] markers for unresolved points}}
```

**`.vault/specs/_template/plan.md`:**
```markdown
---
feature: {{kebab-slug-of-feature}}
spec: "[[spec-{{kebab-slug-of-feature}}]]"
created: {{YYYY-MM-DD}}
---
# {{Feature Name}} — Plan

**For this spec:** `[[spec-{{kebab-slug-of-feature}}]]`

## Approach

{{2-3 paragraphs: the high-level technical approach and why it was chosen over alternatives}}

## Architecture

{{diagrams, component breakdown, data flow}}

## File Structure

{{files to be created, modified, or deleted, with one-line responsibilities}}

## Phase Ordering

{{if the work has natural phases, list them with dependencies}}

## Risks / Open Decisions

{{list any decisions the task-writer or implementer must make}}
```

**`.vault/specs/_template/tasks.md`:**
```markdown
---
feature: {{kebab-slug-of-feature}}
plan: "[[plan-{{kebab-slug-of-feature}}]]"
spec: "[[spec-{{kebab-slug-of-feature}}]]"
created: {{YYYY-MM-DD}}
---
# {{Feature Name}} — Tasks

**For this plan:** `[[plan-{{kebab-slug-of-feature}}]]`

## Phase 1: {{name}}

### Task 1: {{name}}

- [ ] Step 1: {{action}}
- [ ] Step 2: {{verification}}
- [ ] Step 3: Commit

(repeat as needed)
```

**Spec folder naming convention:** `YYYY-MM-DD-<kebab-slug>/` where `YYYY-MM-DD` is the date the spec was created. Examples: `2026-04-15-user-auth`, `2026-04-16-mobile-responsiveness`, `2026-04-17-api-refactoring`. Use today's date when creating a new spec; if multiple specs are created on the same day, the `<kebab-slug>` disambiguates them. The `_template/` folder is excluded from listings.

**Spec file naming convention:** when copying the template into a new spec folder, rename each file from the generic template name to one that includes the slug — `spec.md` → `spec-<kebab-slug>.md`, `plan.md` → `plan-<kebab-slug>.md`, `tasks.md` → `tasks-<kebab-slug>.md`. The slug is the same `<kebab-slug>` used in the folder name. The reason: agent sessions, editor tabs, and search results often show only the basename, and a vault with many specs would otherwise be a wall of indistinguishable `spec.md` entries. Substitute every occurrence of `{{kebab-slug-of-feature}}` (in frontmatter wikilinks and body cross-refs) with the same slug at the same time. Templates inside `_template/` keep their canonical short names — they are blueprints, not real specs.

---

## MOCs

The MOCs start as skeletons — they grow as notes are added. Use the project info gathered in Prerequisites (see `SKILL.md`) to fill in `{{Project Name}}`.

**`.vault/_index/home.md`:**
```markdown
---
tags:
  - moc
---
# {{Project Name}} — Project Knowledge Vault

This vault contains all project-specific knowledge for {{Project Name}}: constitution, specs, learnings, and rules.

## Where to go

- **[[../constitution|Constitution]]** — non-negotiable project principles. Read before any substantive work.
- **[[specs|Specs MOC]]** — all specs, past and present, indexed by status.
- **[[learnings|Learnings MOC]]** — architecture, patterns, gotchas.
- **[[conventions|Conventions MOC]]** — code style choices the team has made.
- **[[../rules|Rules]]** — non-negotiable operational rules: philosophy, git & delivery, code.

## How to use this vault

- New feature or refactor → copy `../specs/_template/` and fill in.
- New learning discovered → copy `../templates/learning.md` and add to `../learnings/`.
- New convention agreed → copy `../templates/convention.md` and add to `../conventions/`.
- New non-negotiable rule → add it to the relevant section of `../rules.md`.
- Always cross-link notes using Obsidian's `[[ ]]` syntax so backlinks aggregate concepts over time.
```

**`.vault/_index/specs.md`:**
```markdown
---
tags:
  - moc
---
# Specs — Map of Content

All specs for {{Project Name}} features, past and current. Specs never get deleted — shipped specs remain as historical record.

## Workflow trigger

Before implementing a user request, ask: "Can I describe the complete solution in one sentence?" If no → use the Spec Kit flow. If yes → go direct. If almost → ask the user.

Template: `[[../specs/_template/spec|_template/spec]]`

## Active

_No active specs. When a request requires the spec flow, link the new spec here._

## Shipped

_No shipped specs yet._
```

**`.vault/_index/learnings.md`:**
```markdown
---
tags:
  - moc
---
# Learnings — Map of Content

Atomic notes about {{Project Name}}'s architecture, patterns, and gotchas. Categorized by tag.

Learnings here are specific to {{Project Name}}. Code style conventions live in `[[conventions|Conventions MOC]]`.

## `#concept` — Architecture and patterns

_No learnings yet. Add the first one when you discover something non-obvious._

## `#reference` — Environment and commands

_No references yet._

## `#gotcha` — Things that tripped us up

_No gotchas captured yet. Add the first one when you hit a repeatable surprise._
```

**`.vault/_index/conventions.md`:**
```markdown
---
tags:
  - moc
---
# Conventions — Map of Content

Deliberate code style choices that all code in {{Project Name}} must follow. These are not safety rules (those live in the constitution) and not things learned from incidents (those live in learnings). These are team decisions about how code should look and be structured.

## Code style

_No conventions yet. Add the first one when a team decision is made._
```

**`.vault/rules.md`:**
```markdown
---
status: canonical
created: {{YYYY-MM-DD}}
---
# {{Project Name}} — Rules

The non-negotiable operational rules for working in {{Project Name}}: philosophy, git & delivery, and code. These are conduct rules — the *how*. Security and architecture non-negotiables are defined in detail in `.vault/constitution.md`; this file points at them, it does not restate them.

A finding, review, or decision that invokes a rule here cites it by name (e.g. "Meaningful Comments rule", "Explicit Consent rule").

## Philosophy (Unix, ESR)

1. **Rule of Modularity** — write simple parts connected by clean interfaces.
2. **Rule of Clarity** — clarity is better than cleverness.
3. **Rule of Composition** — design programs to be connected to other programs.
4. **Rule of Separation** — separate policy from mechanism; separate interfaces from engines.
5. **Rule of Simplicity** — design for simplicity; add complexity only where you must.
6. **Rule of Parsimony** — write a big program only when it is clear by demonstration that nothing else will do.
7. **Rule of Transparency** — design for visibility to make inspection and debugging easier.
8. **Rule of Robustness** — robustness is the child of transparency and simplicity.
9. **Rule of Representation** — fold knowledge into data so program logic can be stupid and robust.
10. **Rule of Least Surprise** — in interface design, always do the least surprising thing.
11. **Rule of Silence** — when a program has nothing surprising to say, it should say nothing.
12. **Rule of Repair** — when you must fail, fail noisily and as soon as possible.
13. **Rule of Economy** — programmer time is expensive; conserve it in preference to machine time.
14. **Rule of Generation** — avoid hand-hacking; write programs to write programs when you can.
15. **Rule of Optimization** — prototype before polishing. Get it working before you optimize it.
16. **Rule of Diversity** — distrust all claims for "one true way".
17. **Rule of Extensibility** — design for the future, because it will be here sooner than you think.

## Git & delivery

1. **Conventional Commits** — every commit follows Conventional Commits (`feat:`, `fix:`, `docs:`, `chore:`, …). Work starts on a branch cut from `main` and reaches `main` through a PR.
2. **Explicit Consent (recorded form)** — never run `git add`, `git commit`, or `git push` without authorization. A spec's recorded `mode:` **is** that authorization: it consents to committing, pushing the **feature branch**, and opening the PR for that spec's work. Outside a recorded spec, ask. **Never push to `main`/`master`.**
3. **Branch Naming** — follow the repo's existing convention (check `git branch -a`). Never inject tool/author identifiers ("claude", "ai", "assistant", etc.).
4. **No Attribution** — never include agent citations, credits, or footers ("Co-Authored-By", "Generated by …", etc.) in commits, PRs, issues, or any project artifact.
5. **PR via Command** — every PR is opened with `/memex:new-pr`. Never open a PR another way (manual `gh pr create`, the GitHub UI).

## Code

1. **Meaningful Comments** — the default is no comments. Only comment when the *why* is non-obvious: a hidden constraint, a subtle invariant, a workaround for a specific bug, or behavior that would surprise a reader. Never explain *what* the code does (well-named identifiers already do that). Never reference the current task, fix, or callers — that belongs in the PR description and rots over time. If removing the comment would not confuse a future reader, do not write it.
2. **Currency** — use the latest documentation and prefer the latest library versions in new projects.

## Security

Security non-negotiables are defined in detail in `.vault/constitution.md`. A security finding cites the constitution by section.
```
