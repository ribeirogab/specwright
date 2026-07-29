---
feature: topology-fixture
created: 2026-07-29
tasks_schema: 2
---
# Topology Fixture — Tasks

### T1: First owner

**AC:** AC-1
**Delegable:** yes
**Depends on:** none
**Files:**
- Modify: ./src//shared.py
**Integration:** isolated
**Validation:** python3 -m compileall src/shared.py

### T2: Second owner

**AC:** AC-1
**Delegable:** yes
**Depends on:** none
**Files:**
- Modify: src/shared.py
**Integration:** isolated
**Validation:** python3 -m compileall src/shared.py
