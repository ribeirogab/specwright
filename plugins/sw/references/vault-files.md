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
| `.specwright/conventions/` | whatever standards the repo wants kept consistent | ensure the directory exists + seed a `README.md` signpost (empty conventions dir only) |
| `.specwright/issues/` | one dated folder per standalone issue | ensure the directory exists + `.gitkeep` |
| `.specwright/milestones/` | one dated folder per milestone | ensure the directory exists + `.gitkeep` |

The scaffolder's whole job for the vault is **make sure the three directories exist and survive a clone** — git tracks no empty directories, so each keeps a tracked file: `issues/` and `milestones/` get a bare `.gitkeep`; `conventions/` gets a short `README.md` signpost that serves the same keep-the-directory purpose and also tells the adopter what the folder is for. Beyond that keep-file the scaffolder writes **no convention rule or standard** into the vault — the signpost declares itself inert (states no rule, applies to no file), and there is no index, tracker, config, or template.

What does **not** live in the vault (do not create any of these):

- Artifact **templates** — they ship with the plugin at `plugins/sw/templates/{issue,spec,tasks,goal,board}.md`. The brainstorm and plan skills generate each artifact from those templates. There is no `_template/` directory in the vault.
- The issue **validator** `validate-spec.sh` — it ships with the plugin under `plugins/sw/scripts/validate-spec.sh`. It is not copied into the vault.
- No editor config, no index or map files, no per-note templates, no workflow guide, no separate issue tracker, and no scripts directory inside `.specwright/`.

---

## `.specwright/conventions/` — the conventions directory

A directory for whatever standards the repo wants kept consistent — code style, architecture, naming, testing, any project preference. The user fills it over time — one file per convention, in whatever shape the project prefers. specwright imposes no template and no required frontmatter on these files.

On first install it holds only the seeded `README.md` signpost — a self-declaring, inert file that keeps the directory tracked and explains what the folder is for. That signpost is the one thing the scaffolder writes here, and only when the directory is empty; it never writes a convention rule, standard, or placeholder content, and never overwrites a conventions dir the user has already populated.

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
    ...             # plus any issue-specific artifacts (e.g. findings.md, evidence/ for validation issues)
```

**Issues are self-contained.** No cross-references between issues and none out of an issue. One carve-out: **evidence-consuming issues** — work whose job is to audit, validate, or consolidate sibling issues — may cite sibling-issue paths as **plain text** (e.g. "the sibling `../2026-06-01-api-audit/learnings.md`"), because their verifiability depends on naming the evidence; link syntax remains banned for them too. Issue **status** lives in each issue's own `issue.md` frontmatter (`status:` and `shipped:`) — there is no separate tracker file that lists or aggregates issues.

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
        ...           # plus any issue-specific artifacts (e.g. findings.md, evidence/ for validation issues)
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

Because issues are self-contained, the files never reference each other by link. When prose needs to point at a sibling, it refers to it by bare name in plain text (e.g. "the sibling `issue.md`"), not by link syntax. The one exception is the evidence-consuming carve-out defined in the standalone-issues section.

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
