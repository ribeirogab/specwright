---
feature: {{kebab-slug-of-issue}}
created: {{YYYY-MM-DD}}
tasks_schema: 2
---
# {{Issue Name}} — Tasks

**For this issue:** see the sibling `issue.md` (acceptance criteria) and `spec.md` (technical plan).

> Every task has a stable `Tn` identifier and names the `AC:` criteria it satisfies. `Delegable:` begins with `yes` or `no` and may add a concise context after ` — `. `Delegable: yes` tasks use `Integration: isolated` and own explicit repository-relative files. `Delegable: no` tasks use `Integration: inline` and list exactly `- None` when they have no owned files. Workers report findings back to the issue owner; only the owner writes `learnings.md`.

## Phase 1: {{name}}

### T1: {{name}}

**AC:** {{AC-N it satisfies, e.g. AC-1, AC-2}}
**Delegable:** {{yes or no — concise context}}
**Depends on:** none
**Files:**
- Create: `{{repository-relative-path}}`
**Integration:** isolated
**Validation:** {{command that verifies this task}}

- [ ] Step 1: {{action}}
- [ ] Step 2: {{verification}}
- [ ] Step 3: Commit

(repeat as needed)
