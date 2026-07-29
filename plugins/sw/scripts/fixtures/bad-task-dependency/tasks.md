---
feature: topology-fixture
created: 2026-07-29
tasks_schema: 2
---
# Topology Fixture — Tasks

### T1: Missing dependency

**AC:** AC-1
**Delegable:** yes
**Depends on:** T2
**Files:**
- Create: src/task.py
**Integration:** isolated
**Validation:** python3 -m compileall src/task.py

### T3: Self dependency

**AC:** AC-1
**Delegable:** yes
**Depends on:** T3
**Files:**
- Create: src/self.py
**Integration:** isolated
**Validation:** python3 -m compileall src/self.py
