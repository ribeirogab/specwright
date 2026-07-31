# Vault files — specifications

`.specwright/` is the per-repository change vault. It has three durable content
directories; worktrees are runtime transport, not records.

## Shape

```text
.specwright/
├── conventions/
│   └── README.md          signpost, created only into an empty directory
├── changes/
│   └── .gitkeep
├── deliveries/
│   └── .gitkeep
└── worktrees/             ignored; created as delivery work is dispatched
```

The scaffolder creates no templates or scripts inside the vault. Bundled
resources stay under `$SW_PLUGIN_ROOT/templates/` and `$SW_PLUGIN_ROOT/scripts/`.
Existing vault content is never overwritten.

## Commit modes

**shared** — the vault is tracked; only `.specwright/worktrees/` is ignored.
Canonical instructions are `AGENTS.md`, with `CLAUDE.md` as its relative symlink.

**local** — the whole vault, `AGENTS.override.md`, and its `CLAUDE.local.md`
symlink are ignored. Existing shared instructions are left untouched.

Role profiles are **not** vault content and never land in a repository. Claude
Code resolves them from the installed plugin; Codex resolves them from
`${CODEX_HOME:-~/.codex}/agents/`, installed once per machine with
`sw_init.py --install-codex-roles`.

For a local-mode delivery dispatch, `sw:delivery` copies into each change
worktree: `AGENTS.override.md`, its `CLAUDE.local.md` symlink, and the change
folder. On return it copies back **only** the change folder — instructions are
conductor-owned state and never sync back from an owner's worktree.

## Changes — flat, always

Every change lives flat under `.specwright/changes/`, whether standalone or part
of a delivery. Membership is the `delivery:` frontmatter key, never directory
nesting:

```text
.specwright/changes/YYYY-MM-DD-<slug>/
├── change.md
├── plan.md
├── pr.md                  only when sw:pr could not reach GitHub
└── ...                    change-specific evidence
```

Each change is self-contained. Files refer to siblings by bare filename in prose,
not links.

### `change.md`

```yaml
---
feature: <kebab-slug>
created: YYYY-MM-DD
status: pending
shipped: null
delivery: null
---
```

`status` is `pending`, `in-progress`, `shipped`, or `blocked`, and lives **only**
here. `shipped` carries the ship date once status is `shipped`. `delivery` is the
parent delivery folder or `null`.

Sections: Purpose, Motivation, Non-Goals, Acceptance Criteria, and **Decisions and
discoveries** — the record of choices the ticket did not settle and non-obvious
facts the work found. That last section is what makes an autonomous `sw:ship` run
auditable.

### `plan.md`

```yaml
---
feature: <kebab-slug>
created: YYYY-MM-DD
scope: low
branch: feat/<kebab-slug>
worktree: null
delivery: null
---
```

`scope` is `low`, `medium`, `high`, or `complex`, and is recorded only. `branch`
is **required**: it is how a session with no conversation context knows where to
work.

Architecture on top, tasks below. Every task block carries exactly three fields:

```markdown
### T1: Task name

**AC:** AC-1, AC-2
**Files:**
- Create: `path/to/file`
**Validation:** command that verifies this task
```

Rules the validator enforces:

- every `AC-N` in `change.md` is claimed by at least one task, and no task names
  a criterion that does not exist;
- `Files:` lists at least one exact repository-relative path;
- `Validation:` is a non-empty command;
- no surviving `{{placeholder}}` in either file.

Task order in the document is execution order. The checkboxes are the resume
state: `sw:implement` continues at the first unticked box.

## Deliveries

```text
.specwright/deliveries/YYYY-MM-DD-<slug>/
└── delivery.md
```

```yaml
---
delivery: <kebab-slug>
created: YYYY-MM-DD
---
```

One file holds both the durable *why* (Purpose, Motivation, Success Criteria,
Non-Goals) and the live state (the change table with its dependency order, the
append-only dispatch log, and the blockers). A delivery's changes are the flat
`.specwright/changes/` folders whose `delivery:` points at it. The change table
holds order and dependencies; it never duplicates a change's `status:`.
