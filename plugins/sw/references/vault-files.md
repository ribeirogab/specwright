# Vault Files — File Specifications

`.specwright/` is the per-repository issue vault. It has three durable content
directories; ignored worktrees are runtime transport, not vault records.

## Vault shape

```text
.specwright/
├── conventions/
│   └── README.md
├── issues/
│   └── .gitkeep
├── milestones/
│   └── .gitkeep
└── worktrees/             ignored; created as work is dispatched
```

The scaffolder creates no artifact templates or validators inside the vault.
Resolve the installed plugin root as `SW_PLUGIN_ROOT`; bundled resources stay
under `$SW_PLUGIN_ROOT/templates/` and `$SW_PLUGIN_ROOT/scripts/`.

`conventions/README.md` is an inert signpost created only when the directory is
empty. Existing conventions are never overwritten. Empty `issues/` and
`milestones/` receive `.gitkeep`.

## Commit modes

In **shared** mode the vault is tracked and only `.specwright/worktrees/` is
ignored. Canonical instructions are `AGENTS.md`; `CLAUDE.md` is its relative
symlink. The four project Codex profiles are tracked.

In **local** mode the whole vault, `AGENTS.override.md`, its
`CLAUDE.local.md` relative symlink, the four `.codex/agents/sw-*.toml` profiles,
and worktrees are ignored. Existing shared instructions and unrelated Codex
configuration remain untouched.

For a local-mode milestone dispatch, `sw:run` copies into each issue worktree:

- `AGENTS.override.md`;
- `CLAUDE.local.md -> AGENTS.override.md`;
- the project-installed `.codex/agents/sw-*.toml` files; and
- the issue folder.

On return it copies back only that issue folder. Instructions and profiles are
canonical conductor state and never sync back from a worker/owner worktree.

## Standalone issues

```text
.specwright/issues/YYYY-MM-DD-<slug>/
├── issue.md
├── spec.md
├── tasks.md
├── learnings.md          optional
└── ...                   issue-specific evidence/artifacts
```

Each issue is self-contained. Files refer to siblings by bare filename in prose,
not links. An evidence-consuming issue may name a sibling issue path as plain text
when verifiability requires it; link syntax remains disallowed.

## Milestones

```text
.specwright/milestones/YYYY-MM-DD-<slug>/
├── goal.md
├── board.md
└── issues/
    └── <plain-kebab-slug>/
        ├── issue.md
        ├── spec.md
        ├── tasks.md
        └── learnings.md   optional
```

Milestone issue folders use plain slugs because ordering and dependencies belong
to `board.md`. The board does not duplicate each issue's `status:` or `shipped:`.

## Frontmatter

### `issue.md`

```yaml
---
feature: <kebab-slug>
created: YYYY-MM-DD
status: pending
shipped: null
---
```

`status` is `pending`, `in-progress`, `shipped`, or `blocked`. `shipped` is the
ship date only when status is `shipped`.

### `spec.md`

```yaml
---
feature: <kebab-slug>
created: YYYY-MM-DD
scope: low
branch: feat/<kebab-slug>
worktree: null
milestone: null
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
  overlapping paths.
- Historical shipped issues may retain legacy tasks. Active legacy tasks block
  planning until explicitly rewritten; no updater guesses their topology.

### `goal.md` and `board.md`

```yaml
---
milestone: <kebab-slug>
created: YYYY-MM-DD
---
```

## Issue ownership and worktrees

The issue owner alone edits issue artifacts and integrates the issue branch.
Ready, independent, non-overlapping isolated tasks form a wave. Every worker
branch starts from the same recorded issue HEAD and gets a sibling worktree under
`.specwright/worktrees/`.

A worker changes only declared files and returns the recorded base SHA, ordered
commit SHAs, touched files, validation results, and discoveries. The owner checks
ancestry and scope, reviews the diff, then cherry-picks accepted commits. After a
wave, integrated validation must pass before dependent tasks are released.

Worktrees are retained for inspection and never removed automatically.
