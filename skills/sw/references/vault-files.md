# Vault Files — File Specifications

Everything the scaffolder writes into a target repo's `.specwright/` vault. specwright is issue-driven-only: the vault holds **exactly three directories** and nothing else. Load this reference only when you are creating or repairing the vault.

## Contents

- [What the vault is — read first](#what-the-vault-is--read-first)
- [`.specwright/conventions/` — the conventions directory](#specwrightconventions--the-conventions-directory)
- [`.specwright/issues/` — standalone issues](#specwrightissues--standalone-issues)
- [`.specwright/milestones/` — milestones](#specwrightmilestones--milestones)
- [Folder naming conventions](#folder-naming-conventions)
- [Bare-filename rule](#bare-filename-rule)
- [Frontmatter shapes](#frontmatter-shapes)

---

## What the vault is — read first

`.specwright/` is the per-repo vault. It contains three living directories and nothing else:

| Path | What it is | Scaffolder action |
|---|---|---|
| `.specwright/conventions/` | project-specific code/style conventions | ensure the directory exists (empty is fine) |
| `.specwright/issues/` | one dated folder per standalone issue | ensure the directory exists |
| `.specwright/milestones/` | one dated folder per milestone | ensure the directory exists |

The scaffolder's whole job for the vault is **make sure the three directories exist**. It does not write any seed files, index, tracker, config, or template into the vault.

What does **not** live in the vault (do not create any of these):

- Artifact **templates** — they ship with this skill at `scaffold/templates/{issue,spec,tasks,goal,board}.md`. The brainstorm and plan skills generate each artifact from those templates. There is no `_template/` directory in the vault.
- The issue **validator** `validate-spec.sh` — it ships with this skill under `scripts/validate-spec.sh`. It is not copied into the vault.
- No editor config, no index or map files, no per-note templates, no workflow guide, no separate issue tracker, and no scripts directory inside `.specwright/`.

---

## `.specwright/conventions/` — the conventions directory

A directory for project-specific code and style conventions. The user fills it over time — one file per convention, in whatever shape the project prefers. specwright imposes no template and no required frontmatter on these files.

On first install it is **empty**, and that is correct. The scaffolder only ensures the directory exists; it never writes a placeholder or seed file into it.

---

## `.specwright/issues/` — standalone issues

The home for every standalone issue (work that is not part of a milestone). Each issue is a **dated folder**:

```
.specwright/issues/
  YYYY-MM-DD-<slug>/
    issue.md        # the ticket: purpose, motivation, non-goals, AC-N, status
    spec.md         # the technical plan (written just-in-time by the plan skill)
    tasks.md        # the task breakdown, each task naming its AC: and Delegable:
    learnings.md    # optional: curated non-obvious facts (written by the issue owner)
```

**Issues are self-contained.** No cross-references between issues and none out of an issue. Issue **status** lives in each issue's own `issue.md` frontmatter (`status:` and `shipped:`) — there is no separate tracker file that lists or aggregates issues.

---

## `.specwright/milestones/` — milestones

The home for every milestone (a large delivery decomposed into issues, conducted by the run skill). Each milestone is a **dated folder**:

```
.specwright/milestones/
  YYYY-MM-DD-<slug>/
    goal.md         # the stable why: purpose, motivation, success criteria, non-goals
    board.md        # the live state: issue order, dependencies, dispatch log, blockers
    issues/
      <slug>/       # plain slug — no date, no number prefix (order lives on the board)
        issue.md
        spec.md
        tasks.md
        learnings.md
```

Milestone issue folders have exactly the same shape as standalone issues — only their location differs. `board.md` never duplicates issue status; it holds only what has no other home (order, dependencies, dispatch log, blocker reports).

---

## Folder naming conventions

- Standalone issues and milestones: `YYYY-MM-DD-<kebab-slug>/` — the date the folder was created plus a short slug. Examples: `2026-04-15-user-auth`, `2026-04-16-coupon-system`.
- Issue folders **inside** a milestone's `issues/`: plain `<kebab-slug>/` — order and dependencies are board data, and encoding order into folder names (e.g. `01-`) invites drift the moment an issue is inserted.

The dated folder is the only discriminator between siblings; two same-day creations stay distinct by slug.

---

## Bare-filename rule

The files inside an issue folder keep **bare** names — `issue.md`, `spec.md`, `tasks.md`, `learnings.md` — for every issue. They are never suffixed with the slug (no `spec-<slug>.md`). The folder already makes each path unique.

Because issues are self-contained, the files never reference each other by link. When prose needs to point at a sibling, it refers to it by bare name in plain text (e.g. "the sibling `issue.md`"), not by link syntax.

---

## Frontmatter shapes

The generating skills write the frontmatter; the scaffolder does not. Documented here so a repair can recognize a correct artifact.

**`issue.md` frontmatter** — the only home of the issue's status:

```yaml
---
feature: <kebab-slug-of-issue>
created: YYYY-MM-DD
status: pending      # pending | in-progress | shipped | blocked
shipped: null        # the ship date once status is shipped, else null
---
```

`status:` and `shipped:` here are the source of truth for whether an issue is shipped — no other file mirrors them.

**`spec.md` frontmatter:**

```yaml
---
feature: <kebab-slug-of-issue>
created: YYYY-MM-DD
scope: low           # low | medium | high | complex  (recorded only)
branch: feat/<kebab-slug-of-issue>
worktree: null       # .specwright/worktrees/<slug> | null  (recorded only)
milestone: null      # .specwright/milestones/YYYY-MM-DD-<slug> | null
---
```

**`tasks.md` frontmatter:**

```yaml
---
feature: <kebab-slug-of-issue>
created: YYYY-MM-DD
---
```

**`goal.md` / `board.md` frontmatter:**

```yaml
---
milestone: <kebab-slug-of-milestone>
created: YYYY-MM-DD
---
```

None carries any cross-reference frontmatter — issues do not link to each other or to anything else in the repo.
