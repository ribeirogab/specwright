# Vault Files — File Specifications

Everything the scaffolder writes into a target repo's `.specwright/` vault. specwright is spec-driven-only: the vault holds **exactly two directories** and nothing else. Load this reference only when you are creating or repairing the vault.

## Contents

- [What the vault is — read first](#what-the-vault-is--read-first)
- [`.specwright/conventions/` — the conventions directory](#specwrightconventions--the-conventions-directory)
- [`.specwright/specs/` — the specs directory](#specwrightspecs--the-specs-directory)
- [Spec-folder naming convention](#spec-folder-naming-convention)
- [Bare-filename rule](#bare-filename-rule)
- [Spec frontmatter shape](#spec-frontmatter-shape)

---

## What the vault is — read first

`.specwright/` is the per-repo vault. It contains two living directories and nothing else:

| Path | What it is | Scaffolder action |
|---|---|---|
| `.specwright/conventions/` | project-specific code/style conventions | ensure the directory exists (empty is fine) |
| `.specwright/specs/` | one dated folder per spec | ensure the directory exists |

The scaffolder's whole job for the vault is **make sure both directories exist**. It does not write any seed files, index, tracker, config, or template into the vault.

What does **not** live in the vault (do not create any of these):

- Spec **templates** — they ship with this skill at `scaffold/spec-templates/{design,spec,tasks}.md`. The brainstorming and writing-plans skills generate each spec's `design.md` / `spec.md` / `tasks.md` from those templates. There is no `_template/` directory in the vault.
- The spec **validator** `validate-spec.sh` — it ships with this skill under `scripts/validate-spec.sh`. It is not copied into the vault.
- No editor config, no index or map files, no per-note templates, no workflow guide, no separate spec tracker, and no scripts directory inside `.specwright/`.

---

## `.specwright/conventions/` — the conventions directory

A directory for project-specific code and style conventions. The user fills it over time — one file per convention, in whatever shape the project prefers. specwright imposes no template and no required frontmatter on these files.

On first install it is **empty**, and that is correct. The scaffolder only ensures the directory exists; it never writes a placeholder or seed file into it.

---

## `.specwright/specs/` — the specs directory

The home for every spec. Each spec is a **dated folder** holding three files:

```
.specwright/specs/
  YYYY-MM-DD-<slug>/
    design.md
    spec.md
    tasks.md
```

- `design.md` — the non-technical write-up of the already-approved design: purpose, motivation, definitions, non-goals.
- `spec.md` — the technical spec: architecture, file structure, phases, and `AC-N` acceptance criteria.
- `tasks.md` — the task breakdown, each task naming its `AC:` and `Delegable:`.

The scaffolder only ensures `.specwright/specs/` exists. The three files inside a spec folder are generated later by the brainstorming and writing-plans skills from `scaffold/spec-templates/`, not written at scaffold time.

**Specs are self-contained.** There are no cross-references between specs and no cross-references out of a spec: no cross-reference frontmatter, no cross-spec links of any kind. Each spec stands alone in its dated folder. Spec **status** lives in each spec's own `spec.md` frontmatter (`status:` and `shipped:`) — there is no separate tracker file that lists or aggregates specs.

---

## Spec-folder naming convention

A spec folder is named `YYYY-MM-DD-<slug>/`, where:

- `YYYY-MM-DD` is the date the spec was created (use today's date when creating a new spec).
- `<slug>` is a short kebab-case slug of the feature.

Examples: `2026-04-15-user-auth`, `2026-04-16-mobile-responsiveness`, `2026-04-17-api-refactoring`.

The dated folder is the **only** discriminator between specs. If two specs are created on the same day, the `<slug>` keeps them distinct. There is no excluded or reserved folder inside `.specwright/specs/` — every folder there is a real spec.

---

## Bare-filename rule

The three files inside a spec folder keep **bare** names — `design.md`, `spec.md`, `tasks.md` — for every spec. They are never suffixed with the slug (no `spec-<slug>.md`, no `design-<slug>.md`, no `tasks-<slug>.md`). The dated folder already makes each path unique, so the filenames stay clean and identical across all specs.

Because specs are self-contained, the files never reference each other by link. When a spec's prose needs to point at a sibling, it refers to it by its bare name in plain text (e.g. "the sibling `spec.md`", "see `design.md`"), not by any link syntax.

---

## Spec frontmatter shape

The generating skills write the frontmatter; the scaffolder does not. This is the shape each file carries, documented here so a repair can recognize a correct spec.

**`spec.md` frontmatter** — carries the spec's status and recorded workflow choices:

```yaml
---
status: draft        # draft | shipped
feature: <kebab-slug-of-feature>
scope: low           # low | medium | high | complex  (recorded only)
created: YYYY-MM-DD
shipped: null        # the ship date once status is shipped, else null
branch: feat/<kebab-slug-of-feature>
mode: autonomous     # autonomous | reviewed
worktree: null       # .specwright/worktrees/<slug> | null  (recorded only)
---
```

`status:` and `shipped:` are the source of truth for whether a spec is shipped — flip `status:` to `shipped` and set `shipped:` to the ship date when it lands. No external tracker mirrors this.

**`design.md` frontmatter:**

```yaml
---
feature: <kebab-slug-of-feature>
created: YYYY-MM-DD
---
```

**`tasks.md` frontmatter:**

```yaml
---
feature: <kebab-slug-of-feature>
created: YYYY-MM-DD
---
```

None of the three carries any cross-reference frontmatter — specs do not link to each other or to anything else in the repo.
