---
feature: malformed-parser-fixture
created: 2026-07-29
tasks_schema: 2
---
# Malformed parser fixture — Tasks

### T1: First task

**AC:** AC-1
**Delegable:** yes
**Depends on:** T0
**Files:**
- Create: ../outside.md
**Integration:** inline
**Validation:**

### T1: Duplicate task

**AC:** AC-2
**Delegable:** sometimes
**Depends on:** T2, nope
**Files:**
- None
**Integration:** isolated
**Validation:** python3 test.py
