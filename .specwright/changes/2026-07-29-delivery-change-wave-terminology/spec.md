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
3. **Migration is a task of this change, not plugin logic** *(refines the earlier "init migrates automatically" decision, 2026-07-29).* The implementer migrates this repo's own vault inside this PR: `git mv` every `.specwright/issues/<slug>/` to `.specwright/changes/<slug>/` (renaming `issue.md` → `change.md`) and every `.specwright/milestones/<slug>/` to `.specwright/deliveries/<slug>/` (renaming `goal.md` → `delivery.md`, moving its `issues/` children up into `changes/`). Contents stay byte-identical. The plugin itself carries **no** migration logic and **no** legacy references — zero remnants. Other repos upgrading specwright repeat the same one-shot move; it is documented here, not encoded in any skill.
4. **No public delivery-conductor.** Delivery orchestration stays inside `/sw:run`; `plugins/sw/agents/` gains no new definition.

### Rename mechanics

The rename is a mechanical pass with one judgement pass on top:

- **Mechanical:** file renames (`issue.md`→`change.md`, `goal.md`→`delivery.md`, `issue-owner.md`→`change-owner.md`), frontmatter key renames (`milestone:`→`delivery:`), path rewrites (`.specwright/issues/`→`.specwright/changes/`, `.specwright/milestones/`→`.specwright/deliveries/`), role-name rewrites in dispatch steps.
- **Judgement:** every prose occurrence of `issue`/`milestone` is classified — specwright artifact (rewrite) or external tracker object (keep, qualified as "GitHub issue"/"Linear issue" where ambiguous). Zero legacy references survive in `plugins/sw/`. `validate-spec.sh`'s own usage/errors/comments get the same treatment.

## File Structure

**`plugins/sw/templates/`** — renamed and rewritten:
- `issue.md` → `change.md` (adds `delivery:` frontmatter key; vocabulary rewrite)
- `goal.md` → `delivery.md` (vocabulary rewrite)
- `spec.md` — frontmatter `milestone:` → `delivery:`; prose rewrite
- `tasks.md` — tasks gain a **Files:** ownership line (enables wave derivation); prose rewrite
- `board.md` — change-order/dependency tables reference changes, not issues

**`plugins/sw/agents/`** — `issue-owner.md` → `change-owner.md`; frontmatter values (`model`, `effort`, `skills:`) preserved; body references updated. No `delivery-conductor.md` added.

**`plugins/sw/skills/`** — vocabulary + path rewrite in `brainstorm` (scope conclusion: standalone change vs delivery), `plan` (reads `change.md`, fan-out context), `run` (delivery conduction, `change-owner` dispatch, wave derivation from task dependency + file ownership), `review`, `review-spec` (reads `change.md`), `pr` (finds the change by `branch:`, writes `pr.md`), `spec`, `init` (scaffolds `changes/` + `deliveries/`). No skill carries migration logic or legacy references.

**`plugins/sw/commands/`** — thin redirects; only descriptions mentioning issue/milestone are touched. Command names unchanged.

**`plugins/sw/scripts/validate-spec.sh`** — validates `change.md` (required keys `feature`/`created`/`status`, status enum), `spec.md` (`feature`/`created`/`scope`), placeholder/vague-verb/AC-reference checks against `change.md` + `tasks.md`; header comments updated.

**`plugins/sw/references/`** — `vault-files.md`, `audit-checklist.md`, `validation.md`, `claude-md-template.md`: vocabulary + layout rewrite.

**Repo root** — `CLAUDE.md` (workflow + layout + role names), `README.md` (workflow description). `CONTRIBUTING.md` checked and updated only if it names the old terms.

**`tests/`** — durable coverage, following the existing suite conventions (ephemeral fixtures, `run.sh` entry point):
- `tests/validate-spec/run.sh` (new) + fixtures: `PASS` on a new-format change folder, failure when `change.md` is missing, status/scope enum checks.
- `tests/install/run.sh` keeps passing unmodified — install behavior gains no migration logic.

**This vault** — this very folder is the first new-format specimen. The legacy `.specwright/issues/` and `.specwright/milestones/` trees migrate **in this same PR** (paths renamed, contents byte-identical); after merge, `.specwright/` contains only `changes/`, `deliveries/`, `conventions/`, and `worktrees/`.

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
- This repo's own legacy vault migrates in this same PR (paths renamed, contents byte-identical); zero legacy folders remain after merge.

## User Stories / Scenarios

1. A maintainer says "create an issue for X" — the resulting artifacts land at `.specwright/changes/<date>-x/` and every generated document calls it a **change**; the GitHub issue, if any, is explicitly a "GitHub issue".
2. A maintainer runs `/sw:run <delivery>` — the orchestrator reads the delivery's `board.md`, dispatches the `change-owner` per ready change, and groups each change's tasks into waves derived from declared dependencies and file ownership.
3. A maintainer opens this repo after the change ships — `.specwright/` contains no `issues/` or `milestones/` tree; every historical artifact is found at its new `changes/`/`deliveries/` path with identical content, and git history follows the renames.
4. An agent runs `validate-spec.sh` on a new-format change folder — it PASSes; deleting `change.md` makes it FAIL.

## Acceptance Criteria

The acceptance criteria live in the sibling `change.md` — the `AC-N` IDs defined there are the contract `tasks.md` references and `/sw:review` walks. Do not duplicate them here.

## Risks and Mitigations

| Risk | Mitigation |
|---|---|
| A stray `issue`/`milestone` survives the rename and re-introduces ambiguity | AC-3 zero-tolerance grep classification over `plugins/sw/`; the three plan self-review gates walk the diff |
| The run-skill rewrite accidentally changes orchestration behavior merged in PR #65 | Behavior-preserving rule stated as a Non-Goal; diff reviewed line-by-line against `main` for the run skill |
| The vault move accidentally edits artifact content | AC-5 requires byte-identical contents, verified by diffing each moved file against its pre-move blob (renames only) |
| External repos mid-flight on old vocabulary break on plugin update | Accepted by decision (immediate cut); the one-shot move is documented in this spec for maintainers to repeat — it is not encoded in the plugin |
| `issue` also means "GitHub issue" in legit contexts (pr skill, templates) and gets over-renamed | Judgement-pass classification: tracker references stay, qualified as "GitHub issue" where ambiguous |

## Open Questions

None — the design questions from issue #66 were settled before this spec: vocabulary confirmed; immediate cut; the legacy vault migrates as a task of this change (executed by the implementer, never encoded in the plugin — zero legacy remnants in `plugins/sw/`); delivery-conductor stays internal to `/sw:run`.
