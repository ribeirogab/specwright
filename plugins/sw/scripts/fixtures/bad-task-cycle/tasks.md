---
feature: topology-fixture
created: 2026-07-29
tasks_schema: 2
---
# Topology Fixture — Tasks

### T1: First cycle member

**AC:** AC-1
**Delegable:** yes
**Depends on:** T2
**Files:**
- Create: src/first.py
**Integration:** isolated
**Validation:** python3 -m compileall src/first.py

### T2: Second cycle member

**AC:** AC-1
**Delegable:** yes
**Depends on:** T1
**Files:**
- Create: src/second.py
**Integration:** isolated
**Validation:** python3 -m compileall src/second.py

### T3: First transitive cycle member

**AC:** AC-1
**Delegable:** yes
**Depends on:** T4
**Files:**
- Create: src/third.py
**Integration:** isolated
**Validation:** python3 -m compileall src/third.py

### T4: Second transitive cycle member

**AC:** AC-1
**Delegable:** yes
**Depends on:** T5
**Files:**
- Create: src/fourth.py
**Integration:** isolated
**Validation:** python3 -m compileall src/fourth.py

### T5: Third transitive cycle member

**AC:** AC-1
**Delegable:** yes
**Depends on:** T3
**Files:**
- Create: src/fifth.py
**Integration:** isolated
**Validation:** python3 -m compileall src/fifth.py
