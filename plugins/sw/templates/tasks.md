---
feature: {{kebab-slug-of-change}}
created: {{YYYY-MM-DD}}
---
# {{Change Name}} — Tasks

**For this change:** see the sibling `change.md` (acceptance criteria) and `spec.md` (technical plan).

> Each task names the `AC:` (acceptance criteria from `change.md` it satisfies — every `AC-N` must be referenced by at least one task), **Files:** (the file-ownership set — two tasks that share a file never run in the same wave), and `Delegable:` (whether it suits an isolated task worker, and the one-line context that worker would receive). Waves are derived by `/sw:run` from these declarations plus task ordering; they are never persisted as folders. Workers report findings back to the change-owner; only the owner writes `learnings.md`.

## Phase 1: {{name}}

### Task 1: {{name}}

**AC:** {{AC-N it satisfies, e.g. AC-1, AC-2}}
**Files:** {{files this task owns, e.g. `src/foo.ts`, `src/foo.test.ts`}}
**Delegable:** {{yes/no + one-line isolated context the worker would receive}}

- [ ] Step 1: {{action}}
- [ ] Step 2: {{verification}}
- [ ] Step 3: Commit

(repeat as needed)
