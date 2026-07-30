---
feature: delivery-change-wave-terminology
created: 2026-07-29
scope: high
branch: refactor/delivery-change-wave-terminology
worktree: null
delivery: null
---
# Delivery, Change, and Wave Terminology — Spec

**Change:** see the sibling `change.md` (the *why*, the acceptance criteria, and the change `status:`)
**Scope:** rename the plugin's vocabulary, artifact layout, validator, and docs from milestone/issue to delivery/change, formalize wave as a derived execution concept, and auto-migrate active legacy work — with an immediate cut and no legacy read support.

This is the **technical** spec — the *how*. The non-technical *why*, the acceptance criteria, and the status live in `change.md`.

## Architecture

### Vocabulary map

| Old | New | Meaning |
|---|---|---|
| milestone | **Delivery** | durable outcome composed of independently shippable changes |
| issue | **Change** | atomic unit of delivery: one branch, one pull request |
| task | **Task** | implementable unit within a change (unchanged) |
| (implicit parallel batch) | **Wave** | dependency-ready, file-disjoint set of isolated tasks that may run in parallel |
| `issue-owner` | `change-owner` | dispatched role owning a change end-to-end |
| `task-worker`, `spec-document-reviewer`, `reviewer` | unchanged | |

### Canonical layout (flat)

```text
.specwright/
├── deliveries/
│   └── YYYY-MM-DD-<slug>/
│       ├── delivery.md      # was goal.md — the delivery's why + status
│       └── board.md         # live state: change order, dependencies, dispatch log
├── changes/
│   └── YYYY-MM-DD-<slug>/
│       ├── change.md        # was issue.md — ticket: why + AC-N + status
│       ├── spec.md
│       ├── tasks.md
│       ├── pr.md            # written by /sw:pr on stop branches
│       └── learnings.md     # optional, written by the change-owner
└── worktrees/
```

- A change references its parent delivery via the `delivery:` frontmatter key (`null` when standalone). The delivery `board.md` references canonical change IDs. **Membership is data, not directory nesting** — no per-delivery `issues/` subfolder exists.
- **Waves are derived, never persisted.** `tasks.md` tasks declare their dependencies and file ownership; `/sw:run` computes waves from that graph at dispatch time. No wave folders, no wave files.

### Cut-over semantics (the decisions, settled)

1. **Vocabulary is final:** Delivery, Change, Task, Wave.
2. **Immediate cut.** Post-migration, tooling (validators, skills, commands) reads and writes only the new vocabulary and layout. Legacy folders remain on disk as dead archive — never rewritten, never read.
3. **Active legacy work moves automatically.** `/sw:init` — already the idempotent setup/repair entry point — detects legacy `.specwright/issues/` and `.specwright/milestones/`. For each legacy artifact whose `status:` is not `shipped`, it moves the folder into the new layout (renaming `issue.md` → `change.md`, `goal.md` → `delivery.md`, adding the `delivery:` key) and updates the parent's board references. Fully shipped legacy folders stay untouched.
4. **No public delivery-conductor.** Delivery orchestration stays inside `/sw:run`; `plugins/sw/agents/` gains no new definition.

### Rename mechanics

The rename is a mechanical pass with one judgement pass on top:

- **Mechanical:** file renames (`issue.md`→`change.md`, `goal.md`→`delivery.md`, `issue-owner.md`→`change-owner.md`), frontmatter key renames (`milestone:`→`delivery:`), path rewrites (`.specwright/issues/`→`.specwright/changes/`, `.specwright/milestones/`→`.specwright/deliveries/`), role-name rewrites in dispatch steps.
- **Judgement:** every prose occurrence of `issue`/`milestone` is classified — specwright artifact (rewrite), external tracker object (keep, qualify as "GitHub issue"/"Linear issue" where ambiguous), or legacy-migration instruction (keep verbatim). `validate-spec.sh`'s own usage/errors/comments get the same treatment.

## File Structure

**`plugins/sw/templates/`** — renamed and rewritten:
- `issue.md` → `change.md` (adds `delivery:` frontmatter key; vocabulary rewrite)
- `goal.md` → `delivery.md` (vocabulary rewrite)
- `spec.md` — frontmatter `milestone:` → `delivery:`; prose rewrite
- `tasks.md` — tasks gain a **Files:** ownership line (enables wave derivation); prose rewrite
- `board.md` — change-order/dependency tables reference changes, not issues

**`plugins/sw/agents/`** — `issue-owner.md` → `change-owner.md`; frontmatter values (`model`, `effort`, `skills:`) preserved; body references updated. No `delivery-conductor.md` added.

**`plugins/sw/skills/`** — vocabulary + path rewrite in `brainstorm` (scope conclusion: standalone change vs delivery), `plan` (reads `change.md`, fan-out context), `run` (delivery conduction, `change-owner` dispatch, wave derivation from task dependency + file ownership), `review`, `review-spec` (reads `change.md`), `pr` (finds the change by `branch:`, writes `pr.md`), `spec`, `init` (scaffolds `changes/` + `deliveries/`; hosts the legacy-migration passage).

**`plugins/sw/commands/`** — thin redirects; only descriptions mentioning issue/milestone are touched. Command names unchanged.

**`plugins/sw/scripts/validate-spec.sh`** — validates `change.md` (required keys `feature`/`created`/`status`, status enum), `spec.md` (`feature`/`created`/`scope`), placeholder/vague-verb/AC-reference checks against `change.md` + `tasks.md`; header comments updated.

**`plugins/sw/references/`** — `vault-files.md`, `audit-checklist.md`, `validation.md`, `claude-md-template.md`: vocabulary + layout rewrite.

**Repo root** — `CLAUDE.md` (workflow + layout + role names), `README.md` (workflow description). `CONTRIBUTING.md` checked and updated only if it names the old terms.

**This vault** — this very folder is the first new-format specimen; legacy `.specwright/issues/` and `.specwright/milestones/` here are fully shipped and stay untouched.

## Phase Ordering

1. **Plugin rename** — templates, agents, skills, commands, references (the bulk; no behavior change).
2. **Validator + migration** — `validate-spec.sh` new-format checks; `init` legacy-migration passage.
3. **Repo docs** — `CLAUDE.md`, `README.md`.
4. **Gates + runtime verification** — mechanical validator, skill quality gate, grep classification, fixture migration, AC walk.

Phases 1–3 are sequential edits on the same files' neighborhood; phase 4 gates the PR.

## Constraints

- Committed artifacts and PR text in English; Conventional Commits; no AI attribution.
- Slash-command names (`/sw:*`) and the four role identities other than `issue-owner` do not change.
- PR #65 (dual-host plugin, safe worker orchestration) is merged; this branch cuts from current `main` and must not regress that behavior — the run-skill rewrite preserves the orchestration mechanics and changes only names.
- This repo's own legacy `.specwright/` folders are fully shipped → nothing moves here; the migration path is verified on a fixture instead.

## User Stories / Scenarios

1. A maintainer says "create an issue for X" — the resulting artifacts land at `.specwright/changes/<date>-x/` and every generated document calls it a **change**; the GitHub issue, if any, is explicitly a "GitHub issue".
2. A maintainer runs `/sw:run <delivery>` — the orchestrator reads the delivery's `board.md`, dispatches the `change-owner` per ready change, and groups each change's tasks into waves derived from declared dependencies and file ownership.
3. A repo with pre-rename specwright artifacts runs `/sw:init` — its in-progress issues/milestones reappear under `changes/`/`deliveries/` with renamed files and a `delivery:` key; its shipped folders are byte-identical before and after.
4. An agent runs `validate-spec.sh` on a new-format change folder — it PASSes; deleting `change.md` makes it FAIL.

## Acceptance Criteria

The acceptance criteria live in the sibling `change.md` — the `AC-N` IDs defined there are the contract `tasks.md` references and `/sw:review` walks. Do not duplicate them here.

## Risks and Mitigations

| Risk | Mitigation |
|---|---|
| A stray `issue`/`milestone` survives the rename and re-introduces ambiguity | AC-3 grep classification over `plugins/sw/`; the three plan self-review gates walk the diff |
| The run-skill rewrite accidentally changes orchestration behavior merged in PR #65 | Behavior-preserving rule stated as a Non-Goal; diff reviewed line-by-line against `main` for the run skill |
| The legacy-migration passage moves a folder that should stay (or vice versa) | AC-5 fixture test with both active and shipped legacy folders; move predicate keys on `status: shipped` only |
| External repos mid-flight on old vocabulary break on plugin update | Accepted by decision (immediate cut); `/sw:init` auto-moves their active work, which is the supported path |
| `issue` also means "GitHub issue" in legit contexts (pr skill, templates) and gets over-renamed | Judgement-pass classification: tracker references stay, qualified as "GitHub issue" where ambiguous |

## Open Questions

None — the four design questions from issue #66 were settled before this spec: vocabulary confirmed; immediate cut; active legacy artifacts moved automatically; delivery-conductor stays internal to `/sw:run`.
