# Sandbox Setup — Learnings

Curated facts downstream issues inherit via their specs.

- The sandbox project lives at `/Users/gabriel/www/ribeirogab/specwright-sandbox/taskr` (absolute path, reachable from any worktree; durable, outside every existing repo).
- The sandbox's `origin` is the **local bare repo** `/Users/gabriel/www/ribeirogab/specwright-sandbox/taskr-origin.git` — never GitHub. Push/pull work normally against it; `gh`-based PR flows do not apply inside the sandbox.
- taskr stores task timestamps as **UTC epoch seconds**: `createdAt` is an integer produced by `Math.floor(Date.now() / 1000)` in `lib/tasks.js` — not an ISO string. Any feature reading or displaying dates must convert from epoch seconds.
- The test suite (`test/taskr.test.js`, run by `npm test` = `node --test`, 5 tests) pins `taskr list` output to **insertion order (oldest first)**: the test `list prints tasks in insertion order (oldest first)` asserts the exact three-line output for three inserted tasks.
- Storage is a JSON array in the file named by the `TASKR_FILE` env var (default `.taskr.json` in the cwd, git-ignored). Tests always run against a temp `TASKR_FILE`; never point one at the repo.
- taskr is dependency-free (no `node_modules`, no lockfile): the only quality gate is `npm test`, and `npm install` is never needed.
- specwright is fully installed in the sandbox (AGENTS.md + `CLAUDE.md` symlink + `.specwright/` vault + `.agents/skills/sw` and the six `sw-*` skills + `.claude/settings.json` with the github marketplace source); the vault dirs carry `.gitkeep` files so they survive clones.
