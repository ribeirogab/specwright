---
status: draft
feature: memex-update-command
scope: high
created: 2026-06-16
shipped: null
branch: feat/memex-update-command
mode: autonomous
related:
  - "[[mechanical-enforcement-over-prose]]"
  - "[[companion-skill-distribution-topology]]"
  - "[[bash-strict-mode-grep-filter]]"
  - "[[validator-verdict-decoupled-from-findings]]"
---
# /memex:update — Spec

**Status:** Draft
**Design:** [[2026-06-16-memex-update-command/design|design]]
**Scope:** A `/memex:update` companion skill + a `.memex/scripts/memex-update.sh` reconcile engine that self-fetches upstream memex, classifies each managed scaffolded file 3-way against a tracked sha256 manifest, auto-applies upstream changes to untouched files, surfaces conflicts for agent merge, manages only the AGENTS.md `### Spec flow` block (not the whole file), never touches living vault content, and degrades to 2-way when no manifest exists.

> **Note on `scope:`** — `high`: a new shell engine with a self-test, a 3-copy companion skill, installer + Phase-5 validation + audit-checklist integration, and doc updates across five surfaces.
>
> **Note on `related:`** — leans on [[mechanical-enforcement-over-prose]] (the deterministic classify is a runnable check, prose is only the merge), [[companion-skill-distribution-topology]] (the 3-copy skill rule), and two bash-correctness learnings the engine must respect: [[bash-strict-mode-grep-filter]] and [[validator-verdict-decoupled-from-findings]].

This is the **technical** spec — the *how*. The *why* lives in `[[2026-06-16-memex-update-command/design|design]]`.

## Architecture

Two units with a clean seam: a **deterministic shell engine** and a **prose orchestrator skill**.

1. **`memex-update.sh` (the engine).** Pure, testable shell. Responsibilities: fetch upstream into a temp dir; enumerate the managed set; for each managed path compute `L` (local sha256), read `B` (manifest baseline), compute `U` (upstream sha256); classify into one of `current | stale-clean | local-only | conflict`; **apply** stale-clean by copying upstream→local; emit a machine-readable report (one line per file: `STATUS\tpath`); and, on `--record`, rewrite manifest entries to current local hashes. It does the parts a machine must do identically every time. It **never** merges, commits, or pushes.

2. **`memex-update` skill (the orchestrator).** Prose the agent follows: run the engine, read its report, for each `conflict` perform the **semantic merge** (preserve local edits + apply the upstream change), write the merged file, then call `memex-update.sh --record <path>` to fold the merged result into the manifest. Finally print a human summary. The agent is the only non-deterministic actor, and only on conflicts.

**The seam:** the engine's report is the contract between the two. The engine decides *what* changed and auto-handles the safe cases; the skill handles only the cases that need judgment. The engine prints its temp clone location as a leading `clone\t<path>` report line and **does not delete it**, so the orchestrator can read upstream versions from there when merging conflicts (no second fetch, no `MEMEX_LAST_CLONE` convention).

**Three-way classify (per managed path).** Checks run **in order**; the first match wins (this is exactly `classify_one` in the engine):

| # | Condition (given prior checks failed) | Class | Engine action |
|---|---|---|---|
| 1 | `L==U` | `current` | none — already matches upstream, **including independent convergence** (`L==U` but `L!=B`) |
| 2 | `L==B` (so `B!=U`) | `stale-clean` | copy `U`→local, record `U` hash |
| 3 | `B==U` (so `L!=B`) | `local-only` | none (report only) |
| 4 | otherwise (`L!=B`, `B!=U`, `L!=U`) | `conflict` | none; report for agent merge |

The `L==U`-first ordering is why the converged case (`L==U & L!=B`) resolves to `current` and never reaches the `conflict` branch. When `B` is absent (no manifest / no entry), degrade to **2-way**: `L==U` → `current`; else `conflict`. After the run, `--record` writes a manifest for every managed path so the next run is 3-way.

**The AGENTS.md spec-flow block.** AGENTS.md is *partly* managed: only the block between the `### Spec flow` line and the next `## ` header is upstream-owned. The engine extracts that block (local and upstream) and hashes the block, not the file. Applying a `stale-clean` AGENTS block replaces only those lines in the local file; the per-repo intro and other sections are untouched. The manifest stores this under a reserved key `AGENTS.md#spec-flow`.

**The managed set (v1).** Every managed item is backed by a **discrete upstream file** — that is the eligibility rule. v1 manages exactly:

| Local path | Upstream-in-clone source | Manifest key |
|---|---|---|
| `.agents/skills/memex-<name>/SKILL.md` (7: recall, brainstorming, writing-plans, link, new-pr, code-review, update) | `skills/memex/scaffold/skills/memex-<name>/SKILL.md` | the local path |
| `.memex/spec-driven-development.md` | `skills/memex/scaffold/vault-docs/spec-driven-development.md` | the local path |
| `.memex/scripts/validate-spec.sh` | `skills/memex/scaffold/vault-scripts/validate-spec.sh` | the local path |
| `.memex/scripts/memex-update.sh` | `skills/memex/scaffold/vault-scripts/memex-update.sh` | the local path |
| `AGENTS.md` `### Spec flow` block | `### Spec flow` block of `skills/memex/references/agents-md-template.md` | `AGENTS.md#spec-flow` |

Each companion-skill `SKILL.md` is byte-identical to its scaffold source (both carry `name: memex-<name>`), so a direct hash compare is valid. **Prose-embedded scaffold content** (templates, `rules.md`, MOCs, constitution — generated from `vault-files.md`/`constitution-template.md`, with no discrete upstream file) is **out of v1**, per the design Non-Goals.

**Upstream fetch.** `git clone --depth 1 https://github.com/ribeirogab/memex <tmp>` (default branch); read the managed sources from the clone. No network → the engine exits non-zero with a clear message (self-fetch was the chosen model; offline is out of scope).

**Hashing portability.** A `_sha()` helper uses `shasum -a 256` when present, else `sha256sum` (covers macOS + Linux). All grep/pipeline filters that may legitimately match nothing are wrapped `|| true` in brace blocks, and every verdict is computed from data captured in the parent shell — per [[bash-strict-mode-grep-filter]] and [[validator-verdict-decoupled-from-findings]].

## File Structure

**Created — engine + tests:**
- `skills/memex/scaffold/vault-scripts/memex-update.sh` — the reconcile engine (scaffold source-of-truth). Modes: default (classify + apply + report), `--record <path>`, `--self-test`.
- `.memex/scripts/memex-update.sh` — dogfood copy (this repo's own install), kept identical to the scaffold source.

The `--self-test` builds its fixtures **ephemerally** (a `mktemp -d` sandbox with local/upstream/manifest trees, torn down at the end) — there is no persistent `fixtures/` directory deliverable; the self-test is self-contained inside the script.

**Created — orchestrator skill (3 kept-in-sync copies, body byte-identical except `name:`):**
- `.agents/skills/memex-update/SKILL.md` — canonical (`name: memex-update`).
- `plugins/memex/skills/update/SKILL.md` — plugin copy (`name: update`), the `/memex:update` mechanism for Claude Code.
- `skills/memex/scaffold/skills/memex-update/SKILL.md` — scaffold copy (`name: memex-update`).

**Created — baseline manifest (dogfood):**
- `.memex/.update-manifest.json` — this repo's own manifest, one sha256 per managed path + the `AGENTS.md#spec-flow` key + a `memex_ref` field (the upstream ref last reconciled against).

**Modified — installer:**
- `skills/memex/SKILL.md` — Scaffolding section: add the `memex-update.sh` copy+chmod step (mirror validate-spec.sh), add `memex-update` to the canonical skills copy block, and add a step that writes the initial `.memex/.update-manifest.json` by hashing every managed file at scaffold time.
- `skills/memex/references/vault-files.md` — document the manifest file + the update script under the scaffolded inventory.

**Modified — audit + validation:**
- `skills/memex/references/audit-checklist.md` — add `.memex/scripts/memex-update.sh`, `.memex/.update-manifest.json`, and `.agents/skills/memex-update/` to the inventory; add `memex-update` to the canonical-skills list.
- `skills/memex/references/validation.md` — add check #18 (update script scaffolded + executable) and #19 (manifest present + valid JSON); add `memex-update` to check #9's loop; bump the documented count ("17 numbered checks" → "19").

**Modified — docs:**
- `AGENTS.md` + `skills/memex/references/agents-md-template.md` — add `/memex:update` to the "Skills and slash commands" list.
- `README.md` — add `/memex:update` to the "Companion skills" / commands description under "What you get".
- `plugins/memex/.claude-plugin/plugin.json` — add update to the `description`.

**Never touched:** `.memex/_index/*`, `.memex/learnings/*`, `.memex/conventions/*`, `.memex/specs/*` (living vault content); the per-repo intro and non-spec-flow sections of `AGENTS.md`; `constitution.md`.

## Phase Ordering

1. **Engine + self-test** (TDD): fixtures → `--self-test` harness → `memex-update.sh` until self-test is green. No other unit depends on prose.
2. **Orchestrator skill** (3 copies): write canonical, mirror to plugin + scaffold; verify body identity.
3. **Installer integration**: scaffold the script, write the initial manifest, register the skill.
4. **Audit + validation**: inventory + checks + count bump + skills-loop.
5. **Docs**: AGENTS.md, template, README, plugin.json.
6. **Dogfood + verify**: install the script + manifest into this repo, run `--self-test` and the Phase-5 checks, walk every AC.

Phases 2–5 depend only on Phase 1's interface (the report contract), not its internals.

## Constraints

- **Shell + markdown only** (constitution: no build pipeline). The engine is bash; `jq` is permitted (already a dependency of the settings checks). No new language runtime.
- **3-copy skill identity** — the three `memex-update` SKILL.md copies must be body-identical except the `name:` line (Phase-5 + code-review enforce it), per [[companion-skill-distribution-topology]].
- **`AGENTS.md` ≤ 80 lines** — adding one bullet to the skills list must not breach the cap; trim prose if needed.
- **No auto-commit / no PR** from the engine or skill — the engine contains no `git commit`, `git push`, or `gh` invocation.
- **Bash strict-mode safety** — `set -euo pipefail`; zero-match greps wrapped `|| true`; verdicts computed in the parent shell.

## User Stories / Scenarios

1. **Untouched install, upstream renamed a term.** User runs `/memex:update`. Engine fetches upstream, finds the companion skills + spec-driven-development.md `stale-clean`, copies them, records new hashes. Skill reports "5 updated, 0 merged". User reviews `git diff`, commits. (This is the `compact→handoff` case, now one command.)
2. **User customized a companion skill, upstream also changed it.** That file classifies `conflict`. The agent merges (keeps the user's edit, applies the upstream change), records it. Report lists it under "merged — review carefully".
3. **Legacy install with no manifest** (e.g. flavianasser). First run degrades to 2-way: equal files `current`, differing files `conflict` (agent-merged). The run writes a manifest; the next update is fully 3-way.

## Acceptance Criteria

- [ ] **AC-1** `.memex/scripts/memex-update.sh` exists, is executable (`test -x`), and `bash .memex/scripts/memex-update.sh --self-test` exits 0.
- [ ] **AC-2** Given a managed file with `L==B` and `B!=U`, the engine classifies it `stale-clean` and an apply run leaves the local file byte-identical to the upstream version (self-test fixture asserts `diff local upstream` empty post-run).
- [ ] **AC-3** Given `L==U`, the engine classifies it `current` and leaves the local file byte-unchanged (sha256 before == after).
- [ ] **AC-4** Given `L!=B` and `B==U`, the engine classifies it `local-only`, leaves the file byte-unchanged, and prints it under `local-only` in the report.
- [ ] **AC-5** Given `L!=B` and `B!=U`, the engine classifies it `conflict`, leaves the file byte-unchanged, and prints it under `conflict` in the report (the engine performs no merge).
- [ ] **AC-6** With no `.memex/.update-manifest.json` present, a run classifies every managed path 2-way (`L==U`→`current`, else `conflict`) and, after `--record`, a manifest file exists containing one sha256 entry per managed path.
- [ ] **AC-7** For AGENTS.md, the engine hashes only the block between `### Spec flow` and the next `## ` header: a self-test fixture where only that block differs classifies `stale-clean`, and a fixture where only the intro (above `### Spec flow`) differs classifies the block `current` (intro change is invisible to the managed hash).
- [ ] **AC-8** The engine's managed-path list contains none of `.memex/_index/`, `.memex/learnings/`, `.memex/conventions/`, `.memex/specs/` (assert: `memex-update.sh --list-managed` prints no path under those four prefixes).
- [ ] **AC-9** `memex-update` SKILL.md exists at all three copies and `diff <(tail -n +3 A) <(tail -n +3 B)` is empty for both the canonical↔plugin and canonical↔scaffold pairs (bodies identical below the `name:` line).
- [ ] **AC-10** `.memex/scripts/memex-update.sh` is byte-identical to `skills/memex/scaffold/vault-scripts/memex-update.sh` (`diff` empty) — the dogfood copy matches the scaffold source.
- [ ] **AC-11** Phase-5 validation (`skills/memex/references/validation.md`) contains a check asserting `.memex/scripts/memex-update.sh` is executable and a check asserting `.memex/.update-manifest.json` exists and parses as JSON; the file's stated check count reads `19` (not `17`); and `memex-update` appears in check #9's skills loop.
- [ ] **AC-12** `memex-update` is listed in the installer's canonical skills copy block (`skills/memex/SKILL.md`) and in `skills/memex/references/audit-checklist.md`'s skills inventory.
- [ ] **AC-13** `/memex:update` appears in the "Skills and slash commands" list of both `AGENTS.md` and `skills/memex/references/agents-md-template.md`, in `README.md`, and `update` appears in `plugins/memex/.claude-plugin/plugin.json`'s `description` (grep each → ≥1 hit).
- [ ] **AC-14** The engine makes no commit/push/PR: `grep -nE 'git (commit|push)|gh (pr|release)' skills/memex/scaffold/vault-scripts/memex-update.sh` returns nothing.
- [ ] **AC-15** The `memex-update` SKILL.md documents a final summary that categorizes managed files as `current` / `updated` / `merged` / `local-only`, and the engine emits one `STATUS\tpath` line per managed file that the summary is built from.
- [ ] **AC-16** `AGENTS.md` remains ≤ 80 lines after the skills-list addition (`wc -l < AGENTS.md` ≤ 80).

## Risks and Mitigations

| Risk | Mitigation |
|---|---|
| A `stale-clean` auto-copy silently clobbers a local edit the manifest missed. | Auto-copy fires only when `L==B` exactly; any divergence from baseline routes to `conflict` (agent) — never auto-overwritten. AC-2/AC-5. |
| 2-way fallback (no manifest) merges a file the user never touched, wasting an agent merge. | Acceptable for the first run only; `--record` then writes the manifest so subsequent runs are precise. Documented in scenario 3 + AC-6. |
| The AGENTS.md block boundary parse breaks if a project reorders sections. | Boundary is anchored on the literal `### Spec flow` … next `## ` — the same headers Phase-5 check #4 already guarantees exist. AC-7. |
| Bash strict-mode kills the engine on a zero-match grep. | All such greps wrapped `\|\| true`; verdicts computed in the parent shell. [[bash-strict-mode-grep-filter]], [[validator-verdict-decoupled-from-findings]]. |
| The 3 skill copies drift. | AC-9 diffs them; code-review documentation lane re-checks. |

## Open Questions

None.
