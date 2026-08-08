---
feature: sample-change
created: 2026-07-31
scope: low
branch: feat/sample-change
worktree: null
delivery: null
---
# Sample Change — Tasks

**Proposal:** see the sibling `proposal.md`.

## Architecture

A single entry point reads the version constant and the input file. Parsing
failures exit 2 before any work begins, so a malformed input never reaches the
runtime path that owns exit 1.

## File Structure

- `src/sample/cli.py` — argument parsing and the two exit paths.
- `tests/test_cli.py` — one test per acceptance criterion.

## Phase Ordering

Single phase.

## Constraints

Python 3.11 and the standard library only.

## Tasks

### T1: Version flag

**AC:** AC-1
**Files:**
- Modify: `src/sample/cli.py`
- Modify: `tests/test_cli.py`
**Validation:** `pytest tests/test_cli.py::test_version -q`

- [ ] Write the failing test asserting stdout is `1.2.0` and the exit code is 0
- [ ] Run `pytest tests/test_cli.py::test_version -q` and confirm it fails
- [ ] Add the `--version` branch
- [ ] Run `pytest tests/test_cli.py::test_version -q` and confirm it passes
- [ ] Commit

### T2: Empty-input rejection

**AC:** AC-2
**Files:**
- Modify: `src/sample/cli.py`
- Modify: `tests/test_cli.py`
**Validation:** `pytest tests/test_cli.py::test_empty_input -q`

- [ ] Write the failing test asserting exit code 2 and `empty input` on stderr
- [ ] Run `pytest tests/test_cli.py::test_empty_input -q` and confirm it fails
- [ ] Add the guard before the parse call
- [ ] Run `pytest tests/test_cli.py::test_empty_input -q` and confirm it passes
- [ ] Commit
