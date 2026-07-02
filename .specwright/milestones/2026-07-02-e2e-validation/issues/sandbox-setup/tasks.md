---
feature: sandbox-setup
created: 2026-07-02
---
# Sandbox Setup — Tasks

**For this issue:** see the sibling `issue.md` (acceptance criteria) and `spec.md` (technical plan).

> Each task names the `AC:` (acceptance criteria from `issue.md` it satisfies — every `AC-N` must be referenced by at least one task) and `Delegable:` (whether it suits an isolated task worker, and the one-line context that worker would receive). Workers report findings back to the issue owner; only the owner writes `learnings.md`.

Sandbox root used throughout: `SBX=/Users/gabriel/www/ribeirogab/specwright-sandbox`. Repo worktree: `WT=/Users/gabriel/www/ribeirogab/specwright/.claude/worktrees/pensive-bose-7ba1c1/.specwright/worktrees/sandbox-setup`.

## Phase 1: taskr project

### Task 1: Project skeleton + failing test suite

**AC:** AC-1, AC-2
**Delegable:** no — the whole sandbox is one coherent environment built inline by the owner.
**Files:**
- Create: `/Users/gabriel/www/ribeirogab/specwright-sandbox/taskr/package.json`
- Create: `/Users/gabriel/www/ribeirogab/specwright-sandbox/taskr/README.md`
- Test: `/Users/gabriel/www/ribeirogab/specwright-sandbox/taskr/test/taskr.test.js`

- [ ] **Step 1: Create the directories**

Run: `mkdir -p "$SBX/taskr/bin" "$SBX/taskr/lib" "$SBX/taskr/test"`

- [ ] **Step 2: Write `package.json`**

```json
{
  "name": "taskr",
  "version": "0.1.0",
  "description": "A tiny todo-list CLI",
  "type": "module",
  "bin": { "taskr": "./bin/taskr.js" },
  "scripts": { "test": "node --test" },
  "license": "MIT"
}
```

- [ ] **Step 3: Write `README.md`** — documents the CLI contract AC-2 verifies against

````markdown
# taskr

A tiny todo-list CLI. No dependencies.

## Usage

```
node bin/taskr.js add <text...>   Add a task. Prints: Added task <id>: <text>
node bin/taskr.js list            Print tasks, one per line: "[ ] <id> <text>" ("[x]" when done).
                                  Prints "No tasks." when the list is empty.
node bin/taskr.js done <id>       Complete a task. Prints: Completed task <id>: <text>
```

Tasks are stored as JSON in the file named by the `TASKR_FILE` environment
variable (default: `.taskr.json` in the current directory).

## Tests

```
npm test
```
````

- [ ] **Step 4: Write the failing test suite `test/taskr.test.js`**

```javascript
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import { mkdtempSync, readFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const bin = join(dirname(fileURLToPath(import.meta.url)), '..', 'bin', 'taskr.js');

function freshStore() {
  return join(mkdtempSync(join(tmpdir(), 'taskr-')), 'tasks.json');
}

function run(storeFile, args) {
  return execFileSync(process.execPath, [bin, ...args], {
    env: { ...process.env, TASKR_FILE: storeFile },
    encoding: 'utf8',
  });
}

test('add stores the task with a numeric createdAt close to now', () => {
  const store = freshStore();
  const before = Math.floor(Date.now() / 1000);
  run(store, ['add', 'buy milk']);
  const tasks = JSON.parse(readFileSync(store, 'utf8'));
  assert.equal(tasks.length, 1);
  assert.equal(tasks[0].text, 'buy milk');
  assert.equal(typeof tasks[0].createdAt, 'number');
  assert.ok(Number.isInteger(tasks[0].createdAt));
  assert.ok(Math.abs(tasks[0].createdAt - before) <= 60);
});

test('list prints tasks in insertion order (oldest first)', () => {
  const store = freshStore();
  run(store, ['add', 'first']);
  run(store, ['add', 'second']);
  run(store, ['add', 'third']);
  const lines = run(store, ['list']).trim().split('\n');
  assert.deepEqual(lines, ['[ ] 1 first', '[ ] 2 second', '[ ] 3 third']);
});

test('done marks the task completed', () => {
  const store = freshStore();
  run(store, ['add', 'write tests']);
  const out = run(store, ['done', '1']);
  assert.equal(out.trim(), 'Completed task 1: write tests');
  const tasks = JSON.parse(readFileSync(store, 'utf8'));
  assert.equal(tasks[0].done, true);
  assert.equal(run(store, ['list']).trim(), '[x] 1 write tests');
});

test('done with an unknown id fails with a non-zero exit', () => {
  const store = freshStore();
  run(store, ['add', 'only task']);
  assert.throws(
    () => run(store, ['done', '99']),
    (error) => error.status === 1 && /No task with id 99/.test(error.stderr),
  );
});

test('list with no tasks prints a friendly message', () => {
  const store = freshStore();
  assert.equal(run(store, ['list']).trim(), 'No tasks.');
});
```

- [ ] **Step 5: Run the suite to verify it fails**

Run: `cd "$SBX/taskr" && npm test`
Expected: FAIL — all 5 tests error because `bin/taskr.js` does not exist (`ENOENT`/module not found).

### Task 2: Implement the engine and the CLI

**AC:** AC-1, AC-2
**Delegable:** no — same environment as Task 1.
**Files:**
- Create: `/Users/gabriel/www/ribeirogab/specwright-sandbox/taskr/lib/tasks.js`
- Create: `/Users/gabriel/www/ribeirogab/specwright-sandbox/taskr/bin/taskr.js`

- [ ] **Step 1: Write `lib/tasks.js`**

```javascript
import { readFileSync, writeFileSync, existsSync } from 'node:fs';
import { resolve } from 'node:path';

function storeFile() {
  return resolve(process.env.TASKR_FILE || '.taskr.json');
}

export function loadTasks() {
  const file = storeFile();
  if (!existsSync(file)) return [];
  const raw = readFileSync(file, 'utf8').trim();
  return raw ? JSON.parse(raw) : [];
}

export function saveTasks(tasks) {
  writeFileSync(storeFile(), `${JSON.stringify(tasks, null, 2)}\n`);
}

export function addTask(text) {
  const tasks = loadTasks();
  const id = tasks.reduce((max, task) => Math.max(max, task.id), 0) + 1;
  const task = {
    id,
    text,
    createdAt: Math.floor(Date.now() / 1000),
    done: false,
  };
  tasks.push(task);
  saveTasks(tasks);
  return task;
}

export function listTasks() {
  return loadTasks();
}

export function completeTask(id) {
  const tasks = loadTasks();
  const task = tasks.find((candidate) => candidate.id === id);
  if (!task) return null;
  task.done = true;
  saveTasks(tasks);
  return task;
}
```

- [ ] **Step 2: Write `bin/taskr.js`**

```javascript
#!/usr/bin/env node
import { addTask, listTasks, completeTask } from '../lib/tasks.js';

const [command, ...rest] = process.argv.slice(2);

function fail(message) {
  console.error(message);
  process.exit(1);
}

switch (command) {
  case 'add': {
    const text = rest.join(' ').trim();
    if (!text) fail('usage: taskr add <text...>');
    const task = addTask(text);
    console.log(`Added task ${task.id}: ${task.text}`);
    break;
  }
  case 'list': {
    const tasks = listTasks();
    if (tasks.length === 0) {
      console.log('No tasks.');
      break;
    }
    for (const task of tasks) {
      console.log(`[${task.done ? 'x' : ' '}] ${task.id} ${task.text}`);
    }
    break;
  }
  case 'done': {
    const id = Number.parseInt(rest[0], 10);
    if (Number.isNaN(id)) fail('usage: taskr done <id>');
    const task = completeTask(id);
    if (!task) fail(`No task with id ${id}`);
    console.log(`Completed task ${task.id}: ${task.text}`);
    break;
  }
  default:
    fail('usage: taskr <add|list|done> ...');
}
```

- [ ] **Step 3: Run the suite to verify it passes**

Run: `cd "$SBX/taskr" && npm test`
Expected: PASS — 5/5 tests, exit 0.

### Task 3: Silent-seed sweep

**AC:** AC-1, AC-2
**Delegable:** no.
**Files:**
- Verify (no edits expected): all files under `/Users/gabriel/www/ribeirogab/specwright-sandbox/taskr/{bin,lib,test}/` and `README.md`

- [ ] **Step 1: Grep for seed-flagging language**

Run: `grep -rniE 'epoch|seed|trap|intentional|on purpose|deliberate' "$SBX/taskr/bin" "$SBX/taskr/lib" "$SBX/taskr/test" "$SBX/taskr/README.md"`
Expected: no output (exit 1) — the seeds exist only as plain behavior.

- [ ] **Step 2: Confirm the store carries no ISO strings**

Run: `TASKR_FILE=$(mktemp -d)/t.json; cd "$SBX/taskr" && TASKR_FILE=$TASKR_FILE node bin/taskr.js add probe && cat "$TASKR_FILE"`
Expected: `createdAt` is a bare integer (e.g. `1751500000`), no quotes, no `T`/`Z` datetime shape.

## Phase 2: Git topology

### Task 4: Init repo on main with a local bare origin

**AC:** AC-3
**Delegable:** no.
**Files:**
- Create: `/Users/gabriel/www/ribeirogab/specwright-sandbox/taskr-origin.git/` (bare repo)
- Create: `/Users/gabriel/www/ribeirogab/specwright-sandbox/taskr/.git/` (repo, branch `main`, remote `origin`)

- [ ] **Step 1: Create the bare origin**

Run: `git init --bare "$SBX/taskr-origin.git"`
Expected: `Initialized empty Git repository in .../taskr-origin.git/`

- [ ] **Step 2: Init the work repo on `main` and wire the remote**

Run: `git -C "$SBX/taskr" init -b main && git -C "$SBX/taskr" remote add origin "$SBX/taskr-origin.git"`

- [ ] **Step 3: Verify the remote is local-only**

Run: `git -C "$SBX/taskr" remote -v`
Expected: two lines pointing at `/Users/gabriel/www/ribeirogab/specwright-sandbox/taskr-origin.git`; no `github.com` anywhere.

## Phase 3: specwright install (per `skills/sw/SKILL.md` Phase 4)

### Task 5: Vault, AGENTS.md, CLAUDE.md symlink, .gitignore

**AC:** AC-4
**Delegable:** no.
**Files:**
- Create: `/Users/gabriel/www/ribeirogab/specwright-sandbox/taskr/.specwright/{conventions,issues,milestones}/.gitkeep`
- Create: `/Users/gabriel/www/ribeirogab/specwright-sandbox/taskr/AGENTS.md`
- Create: `/Users/gabriel/www/ribeirogab/specwright-sandbox/taskr/CLAUDE.md` (symlink → `AGENTS.md`)
- Create: `/Users/gabriel/www/ribeirogab/specwright-sandbox/taskr/.gitignore`

- [ ] **Step 1: Vault directories with keep files**

Run: `mkdir -p "$SBX/taskr/.specwright"/{conventions,issues,milestones} && touch "$SBX/taskr/.specwright"/{conventions,issues,milestones}/.gitkeep`

- [ ] **Step 2: Write `AGENTS.md`** from `$WT/skills/sw/references/agents-md-template.md`, substituting `taskr` for both placeholders; keep every fixed section verbatim (`## Workflow Spec Driven`, `### Issue flow`, mermaid block, `## Coding standard`, `## Skills and slash commands`).

- [ ] **Step 3: Verify AGENTS.md size and headers**

Run: `wc -l < "$SBX/taskr/AGENTS.md"; grep -c '^## ' "$SBX/taskr/AGENTS.md"; grep -nE '\{\{' "$SBX/taskr/AGENTS.md" || echo CLEAN`
Expected: ≤ 80 lines; 3 `## ` headers; `CLEAN` (no placeholders).

- [ ] **Step 4: CLAUDE.md symlink**

Run: `ln -s AGENTS.md "$SBX/taskr/CLAUDE.md" && readlink "$SBX/taskr/CLAUDE.md"`
Expected: `AGENTS.md`

- [ ] **Step 5: Write `.gitignore`**

```
# specwright per-spec worktrees (machine-local checkouts)
.specwright/worktrees/

node_modules/
.taskr.json
```

### Task 6: Skills install + Claude plugin settings

**AC:** AC-4, AC-5
**Delegable:** no.
**Files:**
- Create: `/Users/gabriel/www/ribeirogab/specwright-sandbox/taskr/.agents/skills/sw/` (full copy of `$WT/skills/sw/`)
- Create: `/Users/gabriel/www/ribeirogab/specwright-sandbox/taskr/.agents/skills/sw-{brainstorm,plan,pr,review,run,update}/`
- Create: `/Users/gabriel/www/ribeirogab/specwright-sandbox/taskr/.claude/settings.json`

- [ ] **Step 1: Canonical copies**

Run:
```bash
mkdir -p "$SBX/taskr/.agents/skills"
cp -R "$WT/skills/sw" "$SBX/taskr/.agents/skills/sw"
for name in sw-brainstorm sw-plan sw-pr sw-review sw-run sw-update; do
  cp -R "$WT/skills/sw/scaffold/skills/$name" "$SBX/taskr/.agents/skills/$name"
done
chmod +x "$SBX/taskr/.agents/skills/sw-brainstorm/scripts"/*.sh
chmod +x "$SBX/taskr/.agents/skills/sw/scripts/validate-spec.sh" "$SBX/taskr/.agents/skills/sw/scripts/sw-update.sh"
```

- [ ] **Step 2: Verify the six skills + validator**

Run: `for s in sw-brainstorm sw-plan sw-pr sw-review sw-run sw-update; do test -f "$SBX/taskr/.agents/skills/$s/SKILL.md" && echo "OK $s"; done; test -x "$SBX/taskr/.agents/skills/sw/scripts/validate-spec.sh" && echo "OK validator"`
Expected: six `OK sw-*` lines + `OK validator`.

- [ ] **Step 3: Claude settings merge (github source — the sandbox is a target repo, not dogfood)**

Run:
```bash
mkdir -p "$SBX/taskr/.claude"
cd "$SBX/taskr"
SETTINGS=".claude/settings.json"
TMP="$(mktemp)"
if [ -s "$SETTINGS" ]; then cp "$SETTINGS" "$TMP"; else echo '{}' > "$TMP"; fi
jq '
  .extraKnownMarketplaces["specwright"] = {
    "source": { "source": "github", "repo": "ribeirogab/specwright" }
  } |
  .enabledPlugins["sw@specwright"] = true
' "$TMP" > "$SETTINGS"
rm "$TMP"
```

- [ ] **Step 4: Verify the settings keys**

Run: `jq '.extraKnownMarketplaces.specwright.source, .enabledPlugins["sw@specwright"]' "$SBX/taskr/.claude/settings.json"`
Expected: the github source object, then `true`.

## Phase 4: Bootstrap commit + verification

### Task 7: Single bootstrap commit on main, pushed to the local origin

**AC:** AC-3
**Delegable:** no.
**Files:**
- Modify: `/Users/gabriel/www/ribeirogab/specwright-sandbox/taskr/.git/` (one commit, push)

- [ ] **Step 1: Stage and commit everything**

Run: `git -C "$SBX/taskr" add -A && git -C "$SBX/taskr" commit -m "chore: bootstrap taskr sandbox with specwright"`

- [ ] **Step 2: Verify single commit + symlink mode**

Run: `git -C "$SBX/taskr" log --oneline; git -C "$SBX/taskr" ls-files -s CLAUDE.md`
Expected: exactly one log line; `120000 ... CLAUDE.md` (symlink mode).

- [ ] **Step 3: Push**

Run: `git -C "$SBX/taskr" push -u origin main`
Expected: `main -> main`, new branch on the bare origin.

### Task 8: Runtime verification of every AC

**AC:** AC-1, AC-2, AC-3, AC-4, AC-5
**Delegable:** no.
**Files:**
- Verify only (no edits): the whole sandbox.

- [ ] **Step 1: AC-1** — `cd "$SBX/taskr" && npm test; echo "exit=$?"` → exit 0, ≥ 4 passing tests, one named `list prints tasks in insertion order (oldest first)`.
- [ ] **Step 2: AC-2** — against a temp `TASKR_FILE`: run `add "demo one"`, `add "demo two"`, `list`, `done 1`, `list`; outputs match the README contract; `cat` the JSON store and confirm `createdAt` values are bare integers.
- [ ] **Step 3: AC-3** — `git -C "$SBX/taskr" log --oneline` shows one commit on `main`; `git -C "$SBX/taskr" remote -v` shows the local bare path; `git -C "$SBX/taskr-origin.git" log --oneline main` shows the pushed commit.
- [ ] **Step 4: AC-4** — run the audit checks: AGENTS.md ≤ 80 lines with the three required headers, `readlink CLAUDE.md` = `AGENTS.md`, the three vault dirs exist, `.agents/skills/sw` + six `sw-*` present, `.gitignore` contains `.specwright/worktrees/`, settings.json keys verified via jq (validation.md checks 1–4, 8–10).
- [ ] **Step 5: AC-5** — `cd "$SBX/taskr" && .agents/skills/sw/scripts/validate-spec.sh .specwright/issues/does-not-exist; echo "exit=$?"` → prints `FAIL: not a directory: ...`, exit 2 (non-zero). Also `.agents/skills/sw/scripts/validate-spec.sh` with no args → usage, exit 2.
- [ ] **Step 6: Record each observed result** for the PR body's runtime-verification section and tick the verified `AC-N` boxes in `issue.md`.

## Phase 5: Artifacts + delivery

### Task 9: learnings.md + findings.md + issue status

**AC:** AC-6
**Delegable:** no — curating learnings is the owner's job by definition.
**Files:**
- Create: `$WT/.specwright/milestones/2026-07-02-e2e-validation/issues/sandbox-setup/learnings.md`
- Create: `$WT/.specwright/milestones/2026-07-02-e2e-validation/issues/sandbox-setup/findings.md`
- Modify: `$WT/.specwright/milestones/2026-07-02-e2e-validation/issues/sandbox-setup/issue.md` (tick ACs; `status: shipped` + date after lgtm)

- [ ] **Step 1: Write `learnings.md`** — facts only: sandbox absolute path (`/Users/gabriel/www/ribeirogab/specwright-sandbox/taskr`), origin is the local bare repo `/Users/gabriel/www/ribeirogab/specwright-sandbox/taskr-origin.git` (never GitHub), `createdAt` is UTC epoch seconds (integer, `Math.floor(Date.now()/1000)`), the suite pins `list` to insertion order (oldest first) in `test/taskr.test.js`, storage via `TASKR_FILE` env var (default `.taskr.json`).
- [ ] **Step 2: Write `findings.md`** — every documented-vs-observed divergence hit while following `skills/sw/SKILL.md`, one Expected / Observed / Proposed fix block each (known candidate: the scaffold never installs the `sw` skill itself into `.agents/skills/sw/`, yet `/sw:plan` and this milestone's audit expect it there).
- [ ] **Step 3: Run the validator on this issue folder**

Run: `$WT/skills/sw/scripts/validate-spec.sh "$WT/.specwright/milestones/2026-07-02-e2e-validation/issues/sandbox-setup"`
Expected: `PASS`.

- [ ] **Step 4: Commit the issue artifacts on `chore/e2e-sandbox-setup`**

### Task 10: PR + review to lgtm

**AC:** AC-1, AC-2, AC-3, AC-4, AC-5, AC-6
**Delegable:** no.
**Files:**
- Modify: none beyond Task 9's (PR metadata only).

- [ ] **Step 1: `/sw:pr`** — base `chore/milestone-e2e-validation` (stacked; push the base only if PR creation requires it and note the stacking in the body); runtime-verification results from Task 8 in the body; no AI attribution.
- [ ] **Step 2: `/sw:review`** to `lgtm`; fix findings on the branch as they come.
- [ ] **Step 3: Flip `issue.md` to `status: shipped` + `shipped: 2026-07-02`**, tick the AC boxes, commit on the issue branch.
