---
feature: sample-change
created: 2026-07-31
shipped: null
delivery: null
---
# Sample Change — Change

Fixture: the shape `validate-change.sh` accepts. Every bad fixture beside it
differs from this file in exactly one way.

## Purpose

Give the validator a change that is ready to hand to an agent with no context.

## Motivation

A gate with no passing example cannot prove it accepts anything.

## Non-Goals

Does not exercise the host adapters or the plugin package surface.

## Acceptance Criteria

- [ ] **AC-1** `sample --version` prints `1.2.0` and exits 0.
- [ ] **AC-2** `sample --parse fixtures/empty.json` exits 2 and prints `empty input` on stderr.

## Decisions and discoveries

- **[decision]** Exit code 2 signals malformed input, keeping 1 for runtime failure.
