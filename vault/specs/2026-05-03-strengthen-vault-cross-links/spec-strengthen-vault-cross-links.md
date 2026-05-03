---
status: shipped
feature: strengthen-vault-cross-links
created: 2026-05-03
shipped: 2026-05-03
related:
  - "[[../../learnings/mechanical-enforcement-over-prose]]"
  - "[[../../learnings/harness-engineering-foundations]]"
  - "[[../../learnings/agents-md-as-map-not-encyclopedia]]"
  - "[[../../learnings/memex]]"
  - "[[../../learnings/rename-spec-grep-first]]"
  - "[[../../conventions/skill-directory-layout]]"
  - "[[../../rules/skill-validation-requirements]]"
---
# Strengthen Vault Cross-Links — Spec

**Status:** Shipped (2026-05-03)
**Scope:** Make the `context/` knowledge graph denser by (1) adding a `related:` field to the spec template, (2) hardening the workflow rule that learnings created during a spec must backlink to it, (3) extending `memex-sweep` with an "isolated specs" detector, (4) backfilling the existing shipped `opensource-readiness` spec, and (5) shipping a new `/memex-link` skill+command that uses a deterministic Bash detector plus an inferential agent loop to suggest missing `related:` entries.

## Context

The current vault graph is sparse. A direct survey: only 2 of 9 learnings link back to any spec, and the shipped `opensource-readiness` spec has zero outgoing wikilinks (a complete island in graph terms). The spec template has `feature` / `status` / `created` / `shipped` in frontmatter but no `related:` and no body prompt to populate one. The `AGENTS.md` rule for "After completing a spec" says learnings should link back to the spec "if applicable" — soft enough that it gets skipped under context pressure. There is no detector for islands and no tooling that surfaces missing connections. The combined effect is a graph where specs become workflow units disconnected from the knowledge they produced or consumed.

This spec addresses that with a tightly-scoped bundle: feedforward (template + workflow rule) + feedback (sweep + linker), following the pattern documented in [[../../learnings/mechanical-enforcement-over-prose|mechanical-enforcement-over-prose]] (computational vs inferential modalities) and aligned with the "garbage collection is continuous, not periodic" principle from [[../../learnings/harness-engineering-foundations|harness-engineering-foundations]].

## Problem Statement

New specs and learnings are produced in workflow flow but the cross-links between them are populated *only* if the author manually remembers to add wikilinks. The frontmatter offers no semantic slot for it on specs, the AGENTS.md rule is soft, no command surfaces missing connections, and no check flags isolated specs. Result: the knowledge graph drifts toward the trivial topology of "each spec is its own connected component", which is exactly the failure mode that [[../../learnings/agents-md-as-map-not-encyclopedia|agents-md-as-map-not-encyclopedia]] warns about ("rot becomes invisible").

## Non-Goals

- **Not** adding `tags:` to specs. Confirmed during brainstorming — the structural metadata (`status`, `feature`, dates) already serves the queries that matter for specs (active vs shipped, by-feature, by-recency). Tags would be theoretical use without demand.
- **Not** changing how learnings/conventions/rules cross-link to each other. Their current `related:` mechanism is fine; only specs were missing the field.
- **Not** building a graph-visualization tool. Obsidian's built-in graph view already renders wikilinks; this spec just makes the underlying graph richer.
- **Not** persisting per-user "rejection state" for `/memex-link` suggestions. Adding state means versioning state files; YAGNI. A user who keeps rejecting the same suggestion can simply not look at it (or, eventually, the source's `related:` will grow naturally and the suggestion becomes idempotency-filtered).
- **Not** auto-committing edits accepted by `/memex-link`. The user manually decides when to commit, just like all other vault edits.
- **Not** running `/memex-link` as a git hook on every commit touching `context/`. Violates Rule of Silence — would be noisy 90% of the time. On-demand + post-spec reflection is enough.
- **Not** modifying the existing `_template/spec.md` `related:` field on already-shipped specs other than the explicit retroactive fix on `opensource-readiness`. Other shipped specs (none currently exist besides `rename-harness-to-memex`, which already has `related:`) are not touched.

## Constraints

- **Bash + jq + diff only.** Per constitution Rule of Tooling and the existing pattern in `memex/`: no JS/TS/Python. The `find-candidates.sh` detector and the `tests/run.sh` runner are bash; JSON is parsed with `jq`. If `jq` is not installed, the skill aborts with an install hint.
- **Deterministic detection, inferential presentation.** Detection (extract wikilinks, count term overlap) lives in the bash script and is fully deterministic — same input yields same JSON. Presentation/judgment (filtering noise, driving interactive loop) lives in the skill body and is the only inferential surface. This split matches the canonical taxonomy in [[../../learnings/mechanical-enforcement-over-prose|mechanical-enforcement-over-prose]].
- **Edits only after explicit user confirmation per item.** The skill never auto-edits frontmatter. The original "report mode only" constraint is expanded to permit "edit-after-explicit-y in interactive loop"; auto-edit on a batch is forbidden.
- **Conservative criteria.** Only two confidence buckets emitted: `high` (wikilink to target already exists in source body) and `medium` (filepath mention, exact title mention, or ≥2 shared load-bearing terms across title+H2 headings). No `low` bucket. This avoids the body-term-matching pit that produces noise proportional to vault size.
- **Symmetry with `memex-sweep` and `memex-recall` as bundled vault tooling.** `memex-link` is part of the `memex` scaffold — installed in any repo that runs `/memex`, just like sweep and recall. Per [[../../conventions/skill-directory-layout|skill-directory-layout]], the canonical install path is `.agents/skills/memex-link/` with per-agent symlink, and the slash command goes in `.claude/commands/`.
- **Idempotency.** Running `/memex-link` twice in a row, with no source edits between runs, must produce identical output (or zero output if everything was accepted). This is enforced by the `source_related_already` filter in the script — once a target is in source's `related:`, the pair is never re-emitted.
- **Plan/tasks intra-pair excluded.** Wikilinks between `spec-X` and its sibling `plan-X` / `tasks-X` are structural, not knowledge cross-links. They do not count toward island detection thresholds and are filtered out of `/memex-link` candidates.

## User Stories / Scenarios

1. **Spec author finishing a feature.** Marks `tasks-foo.md` all checked, sets `spec-foo.md` to `status: shipped`. The "After completing a spec" reflection step runs `/memex-link spec-foo` automatically. Three suggestions surface, two with `high` confidence. Author types `y / y / n` and the spec's `related:` is populated.
2. **Maintainer running periodic vault hygiene.** Runs `/memex-link` with no args. Whole-vault scan produces a table of 8 candidates. Maintainer accepts 5, skips 3. Frontmatter changes are committed in a follow-up commit.
3. **Sweep flagging an island.** `/memex-sweep` reports: "Spec `2026-04-30-opensource-readiness` has no vault cross-links beyond its own plan/tasks. Run `/memex-link spec-opensource-readiness`." Maintainer follows the suggestion.
4. **New spec author reading the template.** Copies `_template/spec.md`, sees the `related: []` field plus the inline note explaining when to populate it. Adds two wikilinks while writing the spec, before any reflection step.
5. **External contributor running memex on their own repo.** `/memex` scaffolds memex-link alongside the existing skills. Contributor learns the `related:` discipline from the AGENTS.md text installed by the scaffolder.
6. **Frontmatter shape edge case.** A spec author manually wrote `related: ["[[X]]", "[[Y]]"]` as inline list. `/memex-link` accepts a suggestion; the skill normalizes the field to multiline block form before appending the new entry. No data loss, uniformity preserved.

## Acceptance Criteria

- [x] `context/specs/_template/spec.md` frontmatter contains `related: []` (empty list, not absent), and the body has the explanatory note about populating it before the `## Context` section. Verified by both `grep -F 'related: []' context/specs/_template/spec.md` (frontmatter check) and `grep -F 'Note on \`related:\` frontmatter' context/specs/_template/spec.md` (body note check) returning matches.
- [x] `AGENTS.md` `## After completing a spec` section contains the wording that bidirectional backlinks are mandatory, not optional. Verified by `grep -F "MUST include a wikilink back to the spec" AGENTS.md` returning a non-empty match.
- [x] `.claude/commands/memex-sweep.md` and `skills/memex/scaffold/commands/memex-sweep.md` both contain a section titled `### Isolated specs` with the detector logic. Verified by `grep -lF "### Isolated specs" .claude/commands/memex-sweep.md skills/memex/scaffold/commands/memex-sweep.md` returning both files.
- [x] `context/specs/2026-04-30-opensource-readiness/spec-opensource-readiness.md` frontmatter contains a `related:` list with at least one wikilink to a learning. Verified by `awk '/^---$/{n++} n==2{exit} {print}' <file> | grep -c '^\s*-\s*"\[\['` ≥ 1.
- [x] Canonical skill `.agents/skills/memex-link/SKILL.md` exists with `name: memex-link` frontmatter and a description that includes both "what" and "when". Verified by `grep '^name: memex-link$' .agents/skills/memex-link/SKILL.md` and a visual check that the description names both the command's purpose and its trigger.
- [x] Detector script `.agents/skills/memex-link/scripts/find-candidates.sh` is present and executable. Verified by `[ -x .agents/skills/memex-link/scripts/find-candidates.sh ]`.
- [x] Slash command `.claude/commands/memex-link.md` exists and references the `memex-link` skill. Verified by `grep -F "memex-link" .claude/commands/memex-link.md`.
- [x] Scaffold copies `skills/memex/scaffold/skills/memex-link/SKILL.md` and `skills/memex/scaffold/commands/memex-link.md` exist and are byte-identical to the canonical copies (within the `SKILL.md` body — installed scripts may differ in execute bit which is reapplied by the installer). Verified by `diff -r .agents/skills/memex-link/ skills/memex/scaffold/skills/memex-link/` and `diff .claude/commands/memex-link.md skills/memex/scaffold/commands/memex-link.md` both producing zero output.
- [x] `skills/memex/SKILL.md` `SKILL_NAMES` array contains `memex-link` and the slash-command loop iterates `memex-link`. Verified by `grep -F "memex-link" skills/memex/SKILL.md` returning at least 2 matches (one in each list).
- [x] `skills/memex/references/audit-checklist.md` lists `.agents/skills/memex-link/` and `.claude/commands/memex-link.md` in the inventory.
- [x] `skills/memex/references/validation.md` check #9 hardcoded array contains `memex-link` (not just SKILL.md's `SKILL_NAMES`). Verified by `grep -F 'memex-recall memex-brainstorming memex-writing-plans memex-link' skills/memex/references/validation.md`.
- [x] `skills/memex/references/validation.md` check #11 hardcoded command list contains `memex-link`. Verified by `grep -F 'memex-link' skills/memex/references/validation.md` returning at least one match in the check #11 region.
- [x] The 15 checks in `skills/memex/references/validation.md` still pass after this work — checks #9 and #11 now also cover `memex-link`. Run all 15 manually; result is `15/15 PASS`.
- [x] `.agents/skills/memex-link/tests/run.sh` exits 0 on the bundled fixtures (PASS). Verified by `bash .agents/skills/memex-link/tests/run.sh; echo $?` returning `0`.
- [x] After running `/memex-link` against the live vault on this branch, the report contains at least one suggestion (the retroactive backfill candidate is one such — verifies end-to-end). Captured in PR description as the smoke-test output.
- [x] After running `/memex-link` *post*-retroactive-backfill against the same vault, the previously-emitted retroactive candidate is no longer surfaced (idempotency filter works). Verified by manual second run.
- [x] `/memex-sweep` flags the test island fixture (a constructed spec folder with zero outgoing wikilinks dropped under `tests/fixtures/`) and does NOT flag the live `rename-harness-to-memex` spec (which has `related:` populated). Verified by manual run, output captured in PR description.
- [x] Branch is `feat/strengthen-vault-cross-links`, not `main`. Verified by `git branch --show-current`.
- [x] Spec frontmatter has `status: shipped` and a non-null `shipped:` date when the work is merged.

## Risks and Mitigations

| Risk | Mitigation |
|---|---|
| `find-candidates.sh` produces false positives on shared headings (two notes share generic terms like "context" or "how it works") | Hardcoded `STOPWORDS` list in the script (the/a/of/in/on/by/and/or/for/to/with/is/this/that/repo/skill/vault/agent/agents/context/note/learning); ≥2-shared-term threshold; only `medium` confidence (never `high`) for this evidence type so user always reviews. |
| `find-candidates.sh` produces false negatives by missing valid connections | `medium` confidence intentionally biased toward over-emission (filepath/title mention is enough). The interactive loop's `n` is cheap. Better to surface and reject than miss. |
| Frontmatter editing corrupts YAML | The skill never uses raw `sed` on frontmatter; uses a documented helper procedure: locate the `---` fences, parse the YAML between them as YAML (not regex), rewrite. If the helper detects a malformed `related:` (string instead of list, mapping, etc.), it aborts that single edit and surfaces to the user. |
| Race between `find-candidates.sh` JSON snapshot and the user's interactive accept (user edits source manually mid-loop) | Skill re-stats source mtime before each edit; if changed, skip with a warning. Loop continues. |
| `jq` missing on a target machine | Skill checks `command -v jq` before Phase 2 and aborts with `Install with: brew install jq` (or platform-appropriate hint). Documented in `SKILL.md`. |
| Scaffold copies drift from canonical (someone edits `.agents/skills/memex-link/` without mirroring to `skills/memex/scaffold/`) | Acceptance criterion uses `diff -r` to assert byte-equivalence; PR cannot ship if the diff is non-empty. Pattern already established for the other bundled skills. |
| Sweep `### Isolated specs` check produces noise on intentional standalone specs (rare but possible) | The detector only flags; it never auto-edits or blocks. The user can ignore the flag, or run `/memex-link spec-X` and accept zero suggestions to bless the standalone status. No persistent annotation needed — re-running sweep will re-flag, which is a feature, not a bug, until the user explicitly populates `related:`. |
| `_template/spec.md` adds `related: []` but new specs forget to populate it | Inline body note + `/memex-sweep` island detector + `/memex-link` interactive prompt at spec-ship time form three reinforcing layers. If all three fail, that's a process problem, not a tooling problem. |
| `find-candidates.sh` is slow on a large vault | Vault is currently ~15 notes; the script's complexity is O(n²) over notes for the H2-overlap step. At 100 notes that's still fast (<1s). At 1000 notes — revisit and consider memoizing tokenization. Not premature; the test fixtures + the smoke test on the live vault will surface this if it becomes real. |
| Shipped-spec retroactive edit (Component 4) is a precedent for "rewriting history" | Frontmatter-only edit on a shipped spec (no body changes) is consistent with the constitution rule "specs never get deleted". Adding a metadata field to a shipped spec is bookkeeping, not rewriting content. The body stays untouched and the diff in the PR makes the change auditable. |

## Open Questions

None. All open decisions raised during brainstorming were resolved (criteria/confidence: B; scope: B; output mode: B; workflow integration: B; sweep threshold: B; tags-on-specs: C/no).
