---
tags:
  - learning
  - gotcha
related:
  - "[[../specs/2026-06-14-spec-flow-restructure/spec|spec-flow-restructure]]"
  - "[[mechanical-enforcement-over-prose]]"
created: 2026-06-14
---
# `validate-spec.sh` flags literal `{{ }}` in prose — a spec *about* templates trips it

`validate-spec.sh` check 2 greps (`grep -F '{{'`) for the literal `{{` anywhere in `spec.md`/`design.md`/`tasks.md`, and check 1 requires the `scope` frontmatter key. A spec whose *subject* is the templates legitimately quotes `{{kebab-slug-of-feature}}` and `{{placeholder}}` in prose — even inside backticks, the substring `{{` is still there — so the validator reports them. If that meta-spec was also authored under the old artifact model, it has no `scope` key either. These are correct detections but false positives for a template-meta-spec.

## Context

Running the new validator against its own authoring spec (`spec-flow-restructure`, written under the old model) produced 3 FAILs: missing `scope`, plus `{{` quoted in `spec.md` and `tasks.md` where the prose describes the new templates. Expected — the meta-spec describes the new templates verbatim and predates the `scope` field.

## How to Apply

The validator gates **new-model** specs. Don't force a spec that documents the templates to pass it — record the expected FAILs instead (as this spec's verification did). Any future spec that must legitimately mention `{{...}}` will trip check 2; that is by design, not a validator bug. If template-meta-specs become common, consider an opt-out marker rather than weakening the grep.
