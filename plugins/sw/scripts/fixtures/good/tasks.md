---
feature: sample-feature
created: 2026-06-14
tasks_schema: 2
---
# Sample Feature — Tasks

**For this issue:** see the sibling issue.md and spec.md.

## Phase 1: Build

### T1: Create greeting module

**AC:** AC-1, AC-2
**Delegable:** yes
**Depends on:** none
**Files:**
- Create: ./src//greet.py
**Integration:** isolated
**Validation:** python3 -m compileall src/greet.py

- [ ] Step 1: Write the greet function.
- [ ] Step 2: Verify the two acceptance criteria.
- [ ] Step 3: Commit.

### T2: Update greeting module

**AC:** AC-1
**Delegable:** yes
**Depends on:** T1
**Files:**
- Modify: src/greet.py
**Integration:** isolated
**Validation:** python3 -m compileall src/greet.py

### T3: Verify greeting module

**AC:** AC-2
**Delegable:** yes
**Depends on:** T2
**Files:**
- Modify: src/./greet.py
**Integration:** isolated
**Validation:** python3 -m compileall src/greet.py
