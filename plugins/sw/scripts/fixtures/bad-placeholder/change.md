---
feature: sample-feature
created: 2026-06-14
status: pending
shipped: null
---
# Sample Feature — Change

## Purpose

Demonstrate a well-formed change folder for validator testing.

## Motivation

The validator needs a passing fixture to prove its happy path exits zero.

## Non-Goals

Not a real feature; it exists only to exercise the validator.

## Acceptance Criteria

- [ ] **AC-1** `greet("world")` returns the exact string `Hello, world`.
- [ ] **AC-2** `greet("")` returns HTTP 400 with body `{"code":"EMPTY_NAME"}`.
