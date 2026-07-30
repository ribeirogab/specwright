# Vault Files — File Specifications

`.specwright/` is the per-repository change vault. It has three durable content
directories; ignored worktrees are runtime transport, not vault records.

## Vault shape

```text
.specwright/
├── conventions/
│   └── README.md
├── changes/
│   └── .gitkeep
├── deliveries/
│   └── .gitkeep
└── worktrees/             ignored; created as work is dispatched
```

The scaffolder creates no artifact templates or validators inside the vault.
Resolve the installed plugin root as `SW_PLUGIN_ROOT`; bundled resources stay
under `$SW_PLUGIN_ROOT/templates/` and `$SW_PLUGIN_ROOT/scripts/`.

`conventions/README.md` is an inert signpost created only when the directory is
empty. Existing conventions are never overwritten. Empty `changes/` and
`deliveries/` receive `.gitkeep`.

## Commit modes

In **shared** mode the vault is tracked and only `.specwright/worktrees/` is
ignored. Canonical instructions are `AGENTS.md`; `CLAUDE.md` is its relative
symlink. The four project Codex profiles are tracked.

In **local** mode the whole vault, `AGENTS.override.md`, its
`CLAUDE.local.md` relative symlink, the four `.codex/agents/sw-*.toml` profiles,
and worktrees are ignored. Existing shared instructions and unrelated Codex
configuration remain untouched.

For a local-mode delivery dispatch, `sw:run` copies into each change worktree:

- `AGENTS.override.md`;
- `CLAUDE.local.md -> AGENTS.override.md`;
- the project-installed `.codex/agents/sw-*.toml` files; and
- the change folder.

On return it copies back only that change folder. Instructions and profiles are
canonical conductor state and never sync back from a worker/owner worktree.

## Changes (flat, always)

Every change lives flat under `.specwright/changes/`, whether it is standalone or
belongs to a delivery — membership is the `delivery:` frontmatter key, never
directory nesting:

```text
.specwright/changes/YYYY-MM-DD-<slug>/
├── change.md
├── spec.md
├── tasks.md
├── learnings.md          optional
└── ...                   change-specific evidence/artifacts
```

Each change is self-contained. Files refer to siblings by bare filename in prose,
not links. An evidence-consuming change may name a sibling change path as plain text
when verifiability requires it; link syntax remains disallowed.

## Deliveries

```text
.specwright/deliveries/YYYY-MM-DD-<slug>/
├── delivery.md
└── board.md
```

A delivery is only its durable goal plus its live board; its changes are the flat
`.specwright/changes/` folders whose `delivery:` points here. The board references
change slugs and holds order and dependencies; it does not duplicate each change's
`status:` or `shipped:`.

## Frontmatter

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

`status` is `pending`, `in-progress`, `shipped`, or `blocked`. `shipped` is the
ship date only when status is `shipped`. `delivery` is the parent delivery folder
path or `null` for a standalone change.

### `spec.md`

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

`scope` is `low`, `medium`, `high`, or `complex`.

### `tasks.md`

```yaml
---
feature: <kebab-slug>
created: YYYY-MM-DD
tasks_schema: 2
---
```

Every active schema-2 task uses:

```markdown
### T1: Task name

**AC:** AC-1, AC-2
**Delegable:** yes — bounded independent implementation
**Depends on:** none
**Files:**
- Create: `path/to/file`
**Integration:** isolated
**Validation:** command that verifies the task
```

Rules:

- IDs are unique stable `Tn` values.
- Dependencies name existing task IDs or `none` and form an acyclic graph.
- `Delegable: yes` pairs with `Integration: isolated`, explicit
  repository-relative files, and a concrete validation command.
- `Delegable: no` pairs with `Integration: inline`; no ownership is written as
  exactly `- None`.
- Independent isolated tasks eligible in the same dependency wave may not own
  overlapping paths. A **wave** — a dependency-ready, file-disjoint set of
  isolated tasks that may run in parallel — is derived from this graph at
  dispatch time and never persisted.
- Historical shipped changes may retain schema-1 tasks. Active schema-1 tasks
  block planning until explicitly rewritten; no updater guesses their topology.

### `delivery.md` and `board.md`

```yaml
---
delivery: <kebab-slug>
created: YYYY-MM-DD
---
```

## Change ownership and worktrees

The change owner alone edits change artifacts and integrates the change branch.
Ready, independent, non-overlapping isolated tasks form a wave. Every worker
branch starts from the same recorded change HEAD and gets a sibling worktree under
`.specwright/worktrees/`.

A worker changes only declared files and returns the recorded base SHA, ordered
commit SHAs, touched files, validation results, and discoveries. The owner checks
ancestry and scope, reviews the diff, then cherry-picks accepted commits. After a
wave, integrated validation must pass before dependent tasks are released.

Worktrees are retained for inspection and never removed automatically.
