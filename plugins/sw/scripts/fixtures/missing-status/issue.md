---
feature: sample-feature
created: 2026-06-14
shipped: null
---
# Sample Feature — Issue

## Purpose

Exercise the validator's check-1 behavior when `status:` is absent.

## Motivation

A single defect — the missing `status:` key — must count as exactly one failed
check (exit 1), not two, and must not collide with the usage/error exit 2.

## Non-Goals

Not a real feature; it exists only to exercise the validator.

## Acceptance Criteria

- [ ] **AC-1** `greet("world")` returns the exact string `Hello, world`.
- [ ] **AC-2** `greet("")` returns HTTP 400 with body `{"code":"EMPTY_NAME"}`.
