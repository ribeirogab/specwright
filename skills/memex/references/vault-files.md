# Vault Files — File Specifications

All concrete file contents the orchestrator writes when scaffolding the `.memex/` vault. Load this reference only when you are creating or repairing one of these files.

## Contents

- [Substitution rules — read first](#substitution-rules--read-first)
- [Obsidian config (3 JSONs)](#obsidian-config)
- [Atomic note templates (2 files)](#atomic-note-templates)
- [Spec templates (3 files) + naming convention](#spec-templates)
- [MOCs (4 files)](#mocs)

---

## Substitution rules — read first

Files in this reference fall into **two distinct groups**. Treat them differently when scaffolding:

### Group A — Templates (keep `{{}}` placeholders intact)

These files are templates that the user/agent will fill **later**, when creating an individual note or spec. Copy them verbatim. **Do NOT substitute any `{{}}` placeholder during scaffolding.**

- `.memex/templates/learning.md` (has `{{title}}`, `{{date}}`, `{{one-paragraph technical insight}}`, …)
- `.memex/templates/convention.md` (has `{{title}}`, `{{category}}`, …)
- `.memex/specs/_template/spec.md` (has `{{Feature Name}}`, `{{kebab-slug-of-feature}}`, …)
- `.memex/specs/_template/design.md` (same)
- `.memex/specs/_template/tasks.md` (same)

### Group B — Project-bound files (substitute `{{Project Name}}` now)

These files describe the current project specifically. Substitute every occurrence of `{{Project Name}}` with the actual project name from Prerequisites **before writing** the file. No `{{}}` placeholder may survive in the written file.

- `.memex/_index/home.md`
- `.memex/_index/specs.md`
- `.memex/_index/learnings.md`
- `.memex/_index/conventions.md`
- `.memex/rules.md`

Surviving `{{Project Name}}` in any Group B file is caught by Phase 5 validation (check #12) and fails the run.

### Group C — Inert (no placeholders to worry about)

- The 3 `.obsidian/*.json` files — pure JSON, no placeholders.

### Group D — Installer-managed (copied or generated, not authored here)

The installer (`skills/memex/SKILL.md`) produces these from the `scaffold/` tree, not from content in this reference. They are the **managed set** that `/memex:update` later reconciles against upstream:

- `.memex/scripts/validate-spec.sh` — copied from `scaffold/vault-scripts/validate-spec.sh`, `chmod +x`. The mechanical spec gate.
- `.memex/scripts/memex-update.sh` — copied from `scaffold/vault-scripts/memex-update.sh`, `chmod +x`. The upstream-reconcile engine behind `/memex:update`.
- `.memex/.update-manifest.json` — generated at install by `memex-update.sh --init-manifest`: a sha256 baseline per managed file (the 7 companion skills' `SKILL.md`, `spec-driven-development.md`, the two scripts, and the `AGENTS.md` `### Spec flow` block). Lets `/memex:update` tell "user edited it" from "upstream changed it". Written only when absent — never clobbered.

---

## Obsidian config

**`.memex/.obsidian/app.json`:**
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

**`.memex/.obsidian/appearance.json`:**
```json
{
  "baseFontSize": 16,
  "theme": "obsidian",
  "cssTheme": ""
}
```

**`.memex/.obsidian/core-plugins.json`:**
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

**`.memex/templates/learning.md`:**
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

**`.memex/templates/convention.md`:**
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

**`.memex/specs/_template/spec.md`:**
```markdown
---
status: draft
feature: {{kebab-slug-of-feature}}
scope: {{low | medium | high | complex}}
created: {{YYYY-MM-DD}}
shipped: null
branch: {{feat/kebab-slug-of-feature}}
mode: {{autonomous | reviewed}}
worktree: {{.memex/worktrees/<slug> | null}}
related: []
---
# {{Feature Name}} — Spec

**Status:** Draft
**Design:** [[design]]
**Scope:** {{one-sentence scope statement}}

> **Note on `scope:` frontmatter** — `scope` is one of `low | medium | high | complex`. It is **recorded only**: reserved for a future quick-mode and does **not** yet gate which artifacts are written. Set it honestly; nothing branches on it today.
>
> **Note on `worktree:` frontmatter** — the path of this spec's git worktree under `.memex/worktrees/`, or `null` when the work runs in place. **Recorded only**: like `scope:`, nothing branches on it and `validate-spec.sh` does not require it.
>
> **Note on `related:` frontmatter** — populate with wikilinks to learnings, conventions, or rules this spec touches, reads, or modifies. Empty `related:` is allowed only if the spec genuinely has no vault dependencies; `/memex:sweep` will flag isolated specs.

This is the **technical** spec — the *how*. The non-technical *why* (purpose, motivation, definitions, non-goals) lives in `[[design]]`.

## Architecture

{{the high-level technical approach and why it was chosen over alternatives; diagrams, component breakdown, data flow}}

## File Structure

{{files to be created, modified, or deleted, with one-line responsibilities}}

## Phase Ordering

{{if the work has natural phases, list them with dependencies; otherwise "Single phase."}}

## Constraints

{{technical, organizational, or timing constraints that shape the solution}}

## User Stories / Scenarios

{{numbered user flows or acceptance scenarios}}

## Acceptance Criteria

Number each criterion `AC-1`, `AC-2`, … — the IDs are stable handles that `tasks.md` references (each task names the `AC-N` it satisfies) and that `memex-code-review` walks to prove every criterion was delivered. Each criterion must be a binary, observable check that someone other than the implementer can verify in under a minute. **No vague verbs** ("works well", "is fast", "is robust", "handles errors gracefully") — replace them with specific, measurable conditions. If a criterion cannot be verified without reading the implementation, it is not an acceptance criterion; rewrite it.

- [ ] **AC-1** {{ e.g. `POST /users` with a duplicate email returns 409 and body `{"code":"DUPLICATE_EMAIL"}` }}
- [ ] **AC-2** {{ e.g. p95 latency for `GET /feed` stays under 200ms with a 1k-row fixture }}
- [ ] **AC-3** {{ e.g. the migration script runs idempotently — running it twice on the same DB yields no diff }}
- [ ] **AC-N** {{ ... }}

Tick each `[x]` when verified. A spec is **not shippable** with empty or `{{placeholder}}` acceptance criteria — `.memex/scripts/validate-spec.sh` and `/memex:review-spec` will reject it.

## Risks and Mitigations

| Risk | Mitigation |
|---|---|
| {{risk}} | {{mitigation}} |

## Open Questions

{{use [NEEDS CLARIFICATION: specific question] markers for unresolved points; write `None.` if there are none — silence is not resolution}}
```

**`.memex/specs/_template/design.md`:**
```markdown
---
feature: {{kebab-slug-of-feature}}
spec: "[[spec]]"
created: {{YYYY-MM-DD}}
---
# {{Feature Name}} — Design

> Non-technical write-up of the **already-approved** design — purpose, motivation, definitions, non-goals. Created after design approval as a durable record of *why*; it is **not** a second human-review gate. The technical *how* (architecture, file structure, acceptance criteria) lives in `[[spec]]`.

## Purpose

{{what this feature is for, in plain language — the outcome a reader should understand without any code context}}

## Motivation

{{why this exists now — what triggered it, what pain it removes, what it unlocks}}

## Definitions

{{domain terms, named concepts, and any vocabulary the spec/tasks rely on — one line each}}

## Non-Goals

{{what this feature explicitly does NOT do — the boundaries that keep scope honest}}
```

**`.memex/specs/_template/tasks.md`:**
```markdown
---
feature: {{kebab-slug-of-feature}}
design: "[[design]]"
spec: "[[spec]]"
created: {{YYYY-MM-DD}}
---
# {{Feature Name}} — Tasks

**For this spec:** `[[spec]]`

> Each task names the `AC:` (acceptance criteria from `[[spec]]` it satisfies — every `AC-N` must be referenced by at least one task) and `Delegable:` (whether it suits an isolated subagent, and the one-line context that subagent would receive).

## Phase 1: {{name}}

### Task 1: {{name}}

**AC:** {{AC-N it satisfies, e.g. AC-1, AC-2}}
**Delegable:** {{yes/no + one-line isolated context the subagent would receive}}

- [ ] Step 1: {{action}}
- [ ] Step 2: {{verification}}
- [ ] Step 3: Commit

(repeat as needed)
```

**Spec folder naming convention:** `YYYY-MM-DD-<kebab-slug>/` where `YYYY-MM-DD` is the date the spec was created. Examples: `2026-04-15-user-auth`, `2026-04-16-mobile-responsiveness`, `2026-04-17-api-refactoring`. Use today's date when creating a new spec; if multiple specs are created on the same day, the `<kebab-slug>` disambiguates them. The `_template/` folder is excluded from listings.

**Spec file naming convention:** the three files inside a spec folder keep **bare** names — `spec.md`, `design.md`, `tasks.md`. The dated folder (`YYYY-MM-DD-<kebab-slug>/`) is the discriminator, so cross-references are **path-qualified wikilinks** that carry the folder: a sibling link is `[[YYYY-MM-DD-<kebab-slug>/spec|spec]]`, and an inbound link from elsewhere in the vault is `[[../specs/YYYY-MM-DD-<kebab-slug>/spec|<kebab-slug>]]`. This keeps every `[[ ]]` globally unique — Obsidian and the `/memex:link` resolver key on the path, not the basename — while filenames stay clean. Templates inside `_template/` keep bare, **unqualified** placeholders (`[[spec]]`, `[[design]]`); the generating skills (`memex-brainstorming`, `memex-writing-plans`) inject the `YYYY-MM-DD-<kebab-slug>/` folder prefix when they copy the template into a real dated folder. Trade-off, accepted deliberately: editor tabs and fuzzy-finder entries show `spec.md` for every spec, distinguished only by their parent folder.

---

## MOCs

The MOCs start as skeletons — they grow as notes are added. Use the project info gathered in Prerequisites (see `SKILL.md`) to fill in `{{Project Name}}`.

**`.memex/_index/home.md`:**
```markdown
---
tags:
  - moc
---
# {{Project Name}} — Project Knowledge Vault

This vault contains all project-specific knowledge for {{Project Name}}: constitution, specs, learnings, and rules.

## Where to go

- **[[../constitution|Constitution]]** — non-negotiable project principles. Read before any substantive work.
- **[[../spec-driven-development|Spec-Driven Development]]** — the full workflow guide: the artifact model, the 9 steps, scope/delegation tables, reviews and gates.
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

**`.memex/_index/specs.md`:**
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

**`.memex/_index/learnings.md`:**
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

**`.memex/_index/conventions.md`:**
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

**`.memex/rules.md`:**
```markdown
---
status: canonical
created: {{YYYY-MM-DD}}
---
# {{Project Name}} — Rules

The non-negotiable operational rules for working in {{Project Name}}: philosophy, git & delivery, and code. These are conduct rules — the *how*. Security and architecture non-negotiables are defined in detail in `.memex/constitution.md`; this file points at them, it does not restate them.

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

Security non-negotiables are defined in detail in `.memex/constitution.md`. A security finding cites the constitution by section.
```
