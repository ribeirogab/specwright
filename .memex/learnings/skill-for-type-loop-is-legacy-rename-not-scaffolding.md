---
tags:
  - learning
  - gotcha
related:
  - "[[../specs/2026-06-14-spec-flow-restructure/spec|spec-flow-restructure]]"
  - "[[vault-link-identity-is-basename-keyed]]"
created: 2026-06-14
---
# `skills/memex/SKILL.md`'s `for type` loop is a legacy slug→bare *rename*, not artifact scaffolding

The `for type in spec design plan tasks` loop under "Spec file rename migration" in `skills/memex/SKILL.md` renames pre-convention slug-named files (`spec-<slug>.md` → `spec.md`) to bare names for folders the audit flags. It is **not** how the current artifact set is created — new specs get their `_template/` from the embedded blocks in `references/vault-files.md`, copied whole. So `plan` must stay in the loop: legacy specs predate the `design.md` split and carry `plan-<slug>.md`; dropping `plan` to "match the new model" silently orphans those files. The loop renames *filenames* only — it never rewrites a `plan.md` body into `design.md` (frozen specs keep their ship-time shape).

## Context

The `spec-flow-restructure` spec's acceptance criterion literally said "update `for type in spec plan tasks` → `spec design tasks`," having mis-identified the loop as a "copy loop." Implementing that verbatim would have regressed the legacy slug→bare migration for `plan` files. Resolved by using the superset `spec design plan tasks` (`design` for the current set, `plan` retained for legacy) and correcting the AC in the spec.

## How to Apply

When a change touches the `for type` loop, treat it as serving legacy folders only. Keep every historical type in the set; add new types as a **superset**, never a replacement. The artifact-set source of truth is `references/vault-files.md` + `.memex/specs/_template/` — change the templates there, not this loop, to evolve what new specs scaffold.
