---
feature: sandbox-setup
created: 2026-07-02
scope: medium
branch: chore/e2e-sandbox-setup
worktree: .specwright/worktrees/sandbox-setup
milestone: .specwright/milestones/2026-07-02-e2e-validation
---
# Sandbox Setup — Spec

**Issue:** see the sibling `issue.md` (the *why*, the acceptance criteria, and the issue `status:`)
**Scope:** Build the durable `taskr` sandbox project (dependency-free Node CLI + passing test suite + local-only git + full specwright install) that every downstream milestone issue tests against.

> **Note on `scope:` frontmatter** — `scope` is one of `low | medium | high | complex`. It is **recorded only**: reserved for a future quick-mode and does **not** yet gate which artifacts are written. Set it honestly; nothing branches on it today.
>
> **Note on `worktree:` frontmatter** — the path of this issue's git worktree under `.specwright/worktrees/`, or `null` when the work runs in place. **Recorded only**, like `scope:`.
>
> **Note on `milestone:` frontmatter** — the milestone folder this issue belongs to, or `null` for a standalone issue.

This is the **technical** spec — the *how*. The non-technical *why*, the acceptance criteria, and the status live in `issue.md`.

## Architecture

Two deliverable surfaces, one outside the repo and one inside it:

1. **The sandbox** (outside any existing repo, durable): `/Users/gabriel/www/ribeirogab/specwright-sandbox/` containing
   - `taskr/` — the synthetic project: a dependency-free Node (v24, ESM) todo-list CLI with three commands (`add`, `list`, `done`), JSON-file storage controlled by the `TASKR_FILE` env var (default `.taskr.json` in the cwd), and a `node --test` suite run by `npm test`. Its own git repo, initialized on `main`, single bootstrap commit, `origin` = the sibling bare repo.
   - `taskr-origin.git` — a bare git repo (`git init --bare`) acting as `origin`. Sits **next to** `taskr/`, never inside it, so `git remote -v` shows a local absolute path and nothing can ever be published to GitHub.
2. **The issue artifacts** (inside the specwright worktree, on branch `chore/e2e-sandbox-setup`): this `spec.md`, `tasks.md`, `learnings.md` (AC-6), `findings.md` (divergences observed while following `skills/sw/SKILL.md`), and the `issue.md` status flips.

### taskr design

- **Data model**: the store file is a JSON array of `{ "id": <int>, "text": <string>, "createdAt": <int>, "done": <bool> }`. `id` is `max(id)+1` starting at 1. `createdAt` is `Math.floor(Date.now() / 1000)` — UTC epoch seconds, an integer, never an ISO string. This is the **learning seed**: it is implemented plainly, with no comment or README mention calling attention to it (issue Purpose demands the seeds stay silent).
- **Layering** (Rule of Separation — interface vs engine):
  - `lib/tasks.js` — the engine: `loadTasks()`, `saveTasks(tasks)`, `addTask(text)`, `listTasks()`, `completeTask(id)`. Storage path resolution (`TASKR_FILE` or `./.taskr.json`) lives here. Missing/empty store file loads as `[]`.
  - `bin/taskr.js` — the CLI: parses `process.argv`, dispatches to the engine, formats output, sets exit codes. `add` with no text, `done` with an unknown/missing id, and unknown commands print an error/usage to stderr and exit 1.
- **CLI contract** (documented in the sandbox README, verified by AC-2):
  - `taskr add <text…>` → appends a task, prints `Added task <id>: <text>`.
  - `taskr list` → prints one line per task in stored (insertion) order: `[ ] <id> <text>` or `[x] <id> <text>`; prints `No tasks.` when empty.
  - `taskr done <id>` → sets `done: true`, prints `Completed task <id>: <text>`; unknown id → stderr `No task with id <id>` + exit 1.
- **Test suite** (`test/taskr.test.js`, `node:test` runner via `npm test` = `node --test`): each test spawns the real CLI (`execFileSync(process.execPath, [bin, …])`) against a fresh temp `TASKR_FILE` under `fs.mkdtempSync` — black-box, no importing internals. Five tests:
  1. `add` stores the task and its `createdAt` is an integer within ±60 s of now (also asserts `typeof === 'number'`, which excludes ISO strings) — inspects the JSON file directly.
  2. `list` prints tasks in insertion order, oldest first — the **trap seed** (AC-1): adds three tasks, asserts the three output lines appear in insertion order. Named plainly ("list prints tasks in insertion order (oldest first)"), no meta-commentary.
  3. `done` marks a task completed: JSON shows `done: true` and `list` renders `[x]` for it.
  4. `done` with an unknown id exits non-zero and prints the error to stderr.
  5. `list` with no tasks prints `No tasks.`.

### Git topology (AC-3)

```
specwright-sandbox/
├── taskr-origin.git      # bare, created first: git init --bare
└── taskr/                # git init -b main; git remote add origin <absolute path to taskr-origin.git>
```

One bootstrap commit on `main` containing the entire sandbox (CLI, tests, README, specwright install), then `git push -u origin main`. Commit message: `chore: bootstrap taskr sandbox with specwright` — Conventional Commit, no AI attribution.

### specwright install (AC-4, AC-5) — exactly as `skills/sw/SKILL.md` Phase 4 prescribes

Executed inside `taskr/`, sourcing scaffold content from this worktree's `skills/sw/`:

1. **Vault**: `mkdir -p .specwright/{conventions,issues,milestones}` with a `.gitkeep` in each so the empty dirs survive the bootstrap commit and any future clone.
2. **AGENTS.md**: instantiate `skills/sw/references/agents-md-template.md` with `Project Name = taskr`, `project = taskr`; all three required headers (`## Workflow Spec Driven`, `## Coding standard`, `## Skills and slash commands`), ≤ 80 lines.
3. **CLAUDE.md**: `ln -s AGENTS.md CLAUDE.md`.
4. **.gitignore**: the specwright block (`.specwright/worktrees/`) plus taskr noise (`.taskr.json`, `node_modules/`).
5. **Canonical skills**: copy this worktree's `skills/sw/` → `.agents/skills/sw/` (the installed `sw` skill itself — AC-4 names it and AC-5 exercises its `scripts/validate-spec.sh`; in target repos `/sw:plan` resolves the validator at exactly that path), then the six scaffold skills `skills/sw/scaffold/skills/sw-{brainstorm,plan,pr,review,run,update}` → `.agents/skills/<name>/`. `chmod +x .agents/skills/sw-brainstorm/scripts/*.sh` and `.agents/skills/sw/scripts/validate-spec.sh`. No `.codex/`/`.cursor/`/etc. dirs exist in a fresh sandbox → no per-agent symlinks (per the scaffold: never auto-create agent dirs).
6. **Claude plugin settings**: `mkdir -p .claude` (the sandbox is driven by Claude Code sessions in every downstream issue, so the gate signal is genuinely true), then the jq merge from `references/claude-plugin-settings.md` with the **github** source (`{"source":"github","repo":"ribeirogab/specwright"}` — the sandbox has no `.claude-plugin/marketplace.json`, so it is a target repo, not dogfood) and `enabledPlugins["sw@specwright"] = true`.

### Divergence capture

While following `skills/sw/SKILL.md`, any gap between what the doc prescribes and what the sandbox needs (already spotted: the scaffold never states how the `sw` skill itself lands in the target repo's `.agents/skills/sw/`, yet the audit in AC-4 and `/sw:plan`'s validator path assume it is there) is recorded in this issue folder's `findings.md` as Expected / Observed / Proposed fix — per the milestone goal's success criteria.

## File Structure

Sandbox (created, outside the repo — the deliverable):

- Create: `/Users/gabriel/www/ribeirogab/specwright-sandbox/taskr-origin.git/` — bare repo, the local `origin`.
- Create: `/Users/gabriel/www/ribeirogab/specwright-sandbox/taskr/package.json` — name/version/bin/`"type": "module"`/`"test": "node --test"`.
- Create: `/Users/gabriel/www/ribeirogab/specwright-sandbox/taskr/bin/taskr.js` — CLI dispatch, output formatting, exit codes.
- Create: `/Users/gabriel/www/ribeirogab/specwright-sandbox/taskr/lib/tasks.js` — storage + add/list/done engine (epoch-seconds `createdAt`).
- Create: `/Users/gabriel/www/ribeirogab/specwright-sandbox/taskr/test/taskr.test.js` — five black-box tests incl. the oldest-first assertion.
- Create: `/Users/gabriel/www/ribeirogab/specwright-sandbox/taskr/README.md` — documents `add`/`list`/`done`, `TASKR_FILE`, `npm test`.
- Create: `/Users/gabriel/www/ribeirogab/specwright-sandbox/taskr/.gitignore`, `AGENTS.md`, `CLAUDE.md` (symlink), `.specwright/{conventions,issues,milestones}/.gitkeep`, `.agents/skills/{sw,sw-brainstorm,sw-plan,sw-pr,sw-review,sw-run,sw-update}/`, `.claude/settings.json` — the specwright install.

Repo worktree (this issue's branch):

- Create: `.specwright/milestones/2026-07-02-e2e-validation/issues/sandbox-setup/spec.md` (this file)
- Create: `.specwright/milestones/2026-07-02-e2e-validation/issues/sandbox-setup/tasks.md`
- Create: `.specwright/milestones/2026-07-02-e2e-validation/issues/sandbox-setup/learnings.md` — AC-6: sandbox absolute path, local-origin convention, both scenario seeds.
- Create: `.specwright/milestones/2026-07-02-e2e-validation/issues/sandbox-setup/findings.md` — documented-vs-observed divergences (Expected / Observed / Proposed fix).
- Modify: `.specwright/milestones/2026-07-02-e2e-validation/issues/sandbox-setup/issue.md` — `status:` flips and AC checkboxes.

## Phase Ordering

1. **Phase 1 — taskr project** (Tasks 1–3): package + failing tests → implementation → green suite. TDD: the suite exists and fails before `lib/`/`bin/` exist.
2. **Phase 2 — git topology** (Task 4): bare origin + `git init -b main` + remote. Depends on nothing in Phase 1 but committing waits for Phase 3.
3. **Phase 3 — specwright install** (Tasks 5–6): vault, AGENTS.md, symlink, .gitignore, skills, settings. Requires the repo dir to exist (Phase 1).
4. **Phase 4 — bootstrap commit + verification** (Tasks 7–8): single commit, push, then runtime-verify every AC.
5. **Phase 5 — artifacts + delivery** (Tasks 9–10): learnings.md, findings.md, issue status, PR, review.

## Constraints

- **Dependency-free**: no npm packages, dev or otherwise — `node:test` is the runner, `package-lock.json` is unnecessary and absent (`npm test` never installs).
- **No GitHub for the sandbox**: `origin` must be a local absolute path; nothing under `specwright-sandbox/` may reference `github.com`.
- **Silent seeds**: no comment, README line, or test description may flag the epoch-seconds choice or the ordering test as special.
- **Single bootstrap commit** on `main` (AC-3) — all sandbox content lands in one commit.
- **Scaffold fidelity**: the install follows `skills/sw/SKILL.md` Phase 4 semantics (idempotent copies, no per-agent dirs created, settings merged via jq preserving unrelated keys); deviations become findings, not improvisations.
- The sandbox path must be reachable from other issue owners' worktrees → everything anchored at the absolute `/Users/gabriel/www/ribeirogab/specwright-sandbox/`.
- Node runtime: v24.11.0 (supports `node --test`, ESM, `util.parseArgs` if needed — plain argv slicing suffices).

## User Stories / Scenarios

1. A downstream issue owner opens `~/www/ribeirogab/specwright-sandbox/taskr`, runs `npm test`, sees ≥ 4 green tests, and starts a specwright session that discovers AGENTS.md and the `sw-*` skills.
2. A later sandbox issue adds a feature whose spec inherits (via this issue's `learnings.md`) the fact that timestamps are epoch seconds — without rediscovering it from source.
3. The circuit-breaker scenario (T-series) demands newest-first `list` output while forbidding test edits; the baked-in oldest-first test forces the documented three-strikes stop.
4. `git push` inside the sandbox lands on the local bare repo; no network, no GitHub.

## Acceptance Criteria

The acceptance criteria live in the sibling `issue.md` — the `AC-N` IDs defined there are the contract `tasks.md` references and `/sw:review` walks. Do not duplicate them here; if writing this spec exposed a missing or wrong criterion, fix `issue.md`.

## Risks and Mitigations

| Risk | Mitigation |
|---|---|
| Sandbox home (`~/www/ribeirogab/specwright-sandbox`) collides with an existing dir | Checked before writing: path does not exist; tasks create it fresh and never `rm -rf` anything pre-existing. |
| Empty vault dirs vanish from the bootstrap commit (git ignores empty dirs), breaking AC-4 after a future clone | `.gitkeep` in each of the three vault dirs. |
| `CLAUDE.md` symlink committed as a regular file (core.symlinks off) | Verify with `readlink CLAUDE.md` = `AGENTS.md` and `git ls-files -s CLAUDE.md` showing mode `120000` after the commit. |
| Seeds accidentally advertised (comment/README/test name flagging them) | Post-implementation grep for `epoch`, `seed`, `trap`, `intentional` across the sandbox; test names stay behavioral. |
| `npm test` recursion or discovery quirks | `"test": "node --test"` auto-discovers `test/*.test.js`; verified by running it in Phase 1. |

## Open Questions

None.
