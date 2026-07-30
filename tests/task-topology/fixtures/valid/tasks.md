---
feature: parser-fixture
created: 2026-07-29
tasks_schema: 2
---
# Parser fixture — Tasks

## Phase 1: Parsing

### T1: Parse metadata

**AC:** AC-1, AC-2
**Delegable:** yes — parser implementation stays isolated from integration work
**Depends on:** none
**Files:**
- Create: `plugins/sw/scripts/validate_task_topology.py`
- Create: tests/task-topology/test_parser.py
**Integration:** isolated
**Validation:** python3 tests/task-topology/test_parser.py

- [ ] Step 1: Parse fields

### T2: Integrate the parser

**AC:** AC-2
**Delegable:** no
**Depends on:** T1
**Files:**
- None
**Integration:** inline
**Validation:** python3 plugins/sw/scripts/validate_task_topology.py tests/task-topology/fixtures/valid/tasks.md

- [ ] Step 1: Integrate

### T3: Replace the Claude adapter

**AC:** AC-2
**Delegable:** no — the issue owner performs the canonical-instruction migration
**Depends on:** T1
**Files:**
- Replace with symlink: `CLAUDE.md -> AGENTS.md`
**Integration:** inline
**Validation:** readlink CLAUDE.md

- [ ] Step 1: Replace the adapter
