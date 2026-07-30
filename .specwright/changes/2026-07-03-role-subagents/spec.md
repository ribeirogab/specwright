---
feature: role-subagents
created: 2026-07-03
scope: medium
branch: claude/awesome-carson-f4f2b9
worktree: null
milestone: null
---
# Per-Role Subagents with Model + Effort — Spec

**Issue:** see the sibling `issue.md` (the *why*, the acceptance criteria, and the issue `status:`)
**Scope:** Add four bundled plugin subagent definitions carrying per-role model + effort, and repoint the three dispatch sites at them by name.

This is the **technical** spec — the *how*. The non-technical *why*, the acceptance criteria, and the status live in `issue.md`.

## Architecture

**Platform mechanism (verified against the Claude Code docs).** A subagent definition pins both `model` and `effort` in its frontmatter — the native place to set per-role reasoning effort and model together. A plugin ships subagents as Markdown files under an `agents/` directory at the plugin root; they are **auto-discovered** on install exactly like `skills/` and `commands/`, so `plugin.json` needs no change (the optional `agents` manifest key only *overrides* the default location). Plugin-shipped agents support `name`, `description`, `model`, `effort`, `maxTurns`, `tools`, `disallowedTools`, `skills`, `memory`, `background`, `isolation`; they do **not** support `hooks`, `mcpServers`, or `permissionMode` — none of which these roles need. The `skills:` frontmatter field preloads a listed skill's full content into the subagent's context at startup, so a role definition can **reference** the skill it already runs instead of duplicating the procedure.

**The design.** Each of the four *dispatched* roles becomes one thin `agents/<role>.md`: frontmatter picks `model` + `effort` (and `skills:` where a skill exists), and the body is a short standing system prompt. The skill remains the single source of the *procedure*; the agent only chooses model/effort and, via `skills:`, preloads that procedure. The two *chat-session* roles — the milestone orchestrator (`/sw:run`) and the single-issue owner — are the interactive session and get **no** definition; they inherit the session's model/effort. No `config.json` is introduced; it was the deliberately-rejected alternative — the subagent frontmatter already co-locates model and effort per role, so a separate runtime config would only add a parsing/merge layer and split the two knobs across two homes.

**Dispatch rewiring.** The three dispatching skills change only their dispatch *target*: they name the bundled subagent instead of describing a generic worker. Procedures, gates, contracts, and lane definitions are untouched. The `reviewer` role is **one** agent dispatched three times — once per review lane (A/B/C) — with the lane named in the dispatch prompt; the lane rubric stays in `review/SKILL.md`.

**Role → definition map:**

| Agent file | `model` | `effort` | `skills:` | Body source | Dispatched by |
|---|---|---|---|---|---|
| `issue-owner.md` | opus | xhigh | `plan` | new short prompt (run the plan pipeline, return shipped/blocked) | `/sw:run` |
| `task-worker.md` | sonnet | medium | — | new short prompt (implement one task, report findings, never write learnings.md) | `/sw:plan` fan-out |
| `spec-document-reviewer.md` | opus | high | — | migrated verbatim from `spec-document-reviewer-prompt.md` | `/sw:plan` Gate 2 |
| `reviewer.md` | opus | xhigh | `review` | new short prompt (one find-only lane, stay in your lane) | `/sw:review` ×3 |

## File Structure

**Created:**
- `plugins/sw/agents/issue-owner.md` — issue-owner role definition.
- `plugins/sw/agents/task-worker.md` — task-worker role definition.
- `plugins/sw/agents/spec-document-reviewer.md` — spec-reviewer role definition; body is the migrated prompt.
- `plugins/sw/agents/reviewer.md` — find-only reviewer lane definition.

**Modified:**
- `plugins/sw/skills/run/SKILL.md` — dispatch step names `issue-owner`; the "run the plan pipeline" instruction moves to the agent + preloaded `plan`, shrinking the dispatch prompt to the paths + shipped/blocked contract.
- `plugins/sw/skills/plan/SKILL.md` — Gate 2 names `spec-document-reviewer`; fan-out names `task-worker`; drop the `spec-document-reviewer-prompt.md` reference.
- `plugins/sw/skills/review/SKILL.md` — the three-lane section names `reviewer` as the dispatched subagent per lane.
- `CLAUDE.md` — the "Editing the bundled skills" paragraph names `plugins/sw/agents/` as the home of the bundled role subagents (kept to one concise sentence; the file's 80-line cap must hold).
- `tests/install/run.sh` — assert the four agent files exist and carry the agreed `model`/`effort` (and the two `skills:` preloads), giving AC-1/AC-2/AC-3 a durable mechanical check.

**Deleted:**
- `plugins/sw/skills/plan/spec-document-reviewer-prompt.md` — content migrates into the agent body.

## Phase Ordering

1. **Phase 1 — bundle the four definitions** (`agents/*.md`); includes migrating + deleting the spec-reviewer prompt.
2. **Phase 2 — rewire the three dispatch sites** (`run`, `plan`, `review`). Depends on Phase 1 (targets must exist and be named correctly).
3. **Phase 3 — docs + test coverage** (`CLAUDE.md`, `tests/install/run.sh`). Depends on Phase 1 (asserts the files it created).

## Constraints

- Plugin agents cannot carry `hooks` / `mcpServers` / `permissionMode` (unsupported for plugin-shipped agents) — irrelevant to these roles.
- The migrated `spec-document-reviewer` body must preserve the current prompt content so its behavior is unchanged (AC-4 requires verbatim carry-over).
- All committed artifacts are in English (agent bodies, skill edits) — chat may be pt-BR, files may not.
- `CLAUDE.md` stays within its 80-line cap; the addition is one sentence.
- `agents/` changes require `/reload-plugins` or a restart to take effect in a live session (does not affect correctness of the shipped files).

## User Stories / Scenarios

1. A maintainer runs `/sw:run` on a milestone; each ready issue's owner is dispatched as the `issue-owner` subagent and conducts at opus/xhigh; its fan-out task-workers run at sonnet/medium; its `/sw:review` lanes run at opus/xhigh — all without the maintainer setting any model.
2. A maintainer edits the model/effort of a role by editing one `agents/<role>.md` frontmatter — no code, no config file.
3. `claude plugin validate` reports the plugin (including the four new agents' frontmatter) as valid.

## Acceptance Criteria

The acceptance criteria live in the sibling `issue.md` — the `AC-N` IDs defined there are the contract `tasks.md` references and `/sw:review` walks. Do not duplicate them here.

## Risks and Mitigations

| Risk | Mitigation |
|---|---|
| Invalid agent frontmatter → plugin fails to load | `claude plugin validate` in runtime verification (when the CLI is available) + the extended `tests/install/run.sh` assertions on each file's required keys. |
| `skills: [plan]` / `skills: [review]` (×3 lanes) preload a lot of context | Accepted and recorded; the preload is exactly the knowledge each role needs. Documented so a future issue can drop the preload for lazy `Skill`-tool loading if context pressure appears. |
| Doc lane flags `plugin.json` / `marketplace.json` descriptions as omitting agents | Those descriptions enumerate the **user-invokable** surface (`/sw:*` commands + skills); the agents are internal dispatch machinery, not entry points, so their omission is correct — noted here so review does not treat it as staleness. |
| Live per-role dispatch cannot be exercised in the authoring session (needs an installed plugin + `/reload-plugins`, and a full milestone) | AC-1..AC-8 are verified by file inspection + smoke test + `claude plugin validate`; the end-to-end "owner actually dispatched at opus/xhigh" is marked `needs-human-verification` in `issue.md` with that reason. |

## Open Questions

None.
