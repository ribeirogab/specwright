---
status: draft
feature: install-script
scope: medium
created: 2026-06-24
shipped: null
branch: feat/install-script
mode: autonomous
worktree: null
related:
  - "[[2026-06-24-install-script/design|design]]"
  - "[[claude-code-extra-known-marketplaces-source-schema]]"
  - "[[companion-skill-distribution-topology]]"
  - "[[memex-marketplace-name-not-reserved]]"
  - "[[bash-strict-mode-grep-filter]]"
---
# Per-project install.sh — Spec

**Status:** Draft
**Design:** [[2026-06-24-install-script/design|design]]
**Scope:** Add Claude Code plugin configuration to the per-project `install.sh`, and refactor it into a sourceable shape so the config logic is unit-testable without network.

> **Note on `scope:` frontmatter** — recorded only; nothing branches on it.
> **Note on `worktree:` frontmatter** — `null`; the work runs in place on `feat/install-script`.
> **Note on `related:` frontmatter** — cites the design and the four learnings this spec leans on: the `extraKnownMarketplaces` `directory`-not-`local` schema, the plugin-vs-command distribution topology, the `memex` marketplace-name check, and the bash strict-mode/grep gotcha that shapes the test harness.

This is the **technical** spec — the *how*. The *why* lives in `[[2026-06-24-install-script/design|design]]`.

## Architecture

`install.sh` already installs the canonical skill (`.agents/skills/memex/`), the `.claude/skills/memex` symlink, and `skills-lock.json` (shipped in `94337c5`). This spec adds the **plugin-config** step and the **next-steps message** change, and refactors the script so the new logic can be tested.

**Sourceable shape (the key decision).** The script's behavior depends on `npx skills add`, which hits the network. To unit-test the plugin-config logic without network, the script is restructured so it can be *sourced* without running the installer:

- All logic moves into **pure-ish functions** plus one `run_install` that drives the procedural flow.
- A **lib-guard** at the end runs `run_install` only when the script is executed, not when sourced:
  ```sh
  [ "${MEMEX_INSTALL_LIB:-0}" = "1" ] || run_install
  ```
- A test sources it with `MEMEX_INSTALL_LIB=1 . ./install.sh`, then calls the functions directly against `$TMPDIR` fixtures — no `npx`, no network.

This mirrors the repo's existing tested-shell pattern (`memex-link/tests/run.sh`, `validate-spec.sh`): a script plus a `tests/.../run.sh` that exercises it and prints `PASS`/`FAIL`.

**Plugin-config functions** (single source of truth for shapes/coordinates: `skills/memex/references/claude-plugin-settings.md`):

- `marketplace_source` — echoes the marketplace **source JSON**. Dogfood detection: if `.claude-plugin/marketplace.json` exists and contains a top-level `"name": "memex"`, echo `{"source":"directory","path":"."}`; else `{"source":"github","repo":"ribeirogab/memex"}`. Detection uses `grep` (universal — no `jq`/`python3` dependency just to pick the source).
- `plugin_merge_engine` — echoes `jq` if `jq` is on PATH, else `python3` if available, else `none`. The single decision point for soft-fail; overridable in tests by redefining the function after sourcing.
- `plugin_snippet SRC` — echoes the human-pasteable JSON object for `.claude/settings.json` (used in the soft-fail warning).
- `merge_with_jq SETTINGS SRC` / `merge_with_python SETTINGS SRC` — merge the two keys into `SETTINGS`, preserving all other top-level keys, via a `mktemp` read-copy so the same file is never read-and-truncated in one redirect. Both must yield the same resulting object.
- `configure_plugin` — orchestrates: compute `src`, `mkdir -p .claude`, pick engine; `jq`/`python3` → merge + success line; `none` → print warning + `plugin_snippet` and return without writing `SETTINGS`.
- `remove_legacy_commands` — `rm -f .claude/commands/memex-{spec,learn,sweep,review-spec}.md` (pre-plugin leftovers; missing files are not an error).
- `print_next_steps` — the closing message: recommend running `/memex`, and note the plugin installs at Claude Code workspace-trust time.

**`run_install` order:** prereq check → `npx skills add … -a universal -y </dev/null` → `.claude/skills/memex` symlink reconcile → verify base tree → `remove_legacy_commands` → `configure_plugin` → `print_next_steps`.

**Unchanged:** the `/memex` skill keeps writing `.claude/settings.json` itself (idempotent fallback). `install.sh` and the skill converge to the same JSON.

## File Structure

- **Modify** `install.sh` — refactor to functions + `run_install` + lib-guard; add `marketplace_source`, `plugin_merge_engine`, `plugin_snippet`, `merge_with_jq`, `merge_with_python`, `configure_plugin`, `remove_legacy_commands`, `print_next_steps`; wire them into `run_install`; update header comment to list `.claude/settings.json`.
- **Create** `tests/install/run.sh` — sources `install.sh` in lib mode; exercises the config functions against `$TMPDIR` fixtures; prints `PASS`/`FAIL`, non-zero exit on any failure.
- **Modify** `README.md` — re-narrate the install paths: `install.sh` = full Claude Code-side setup (skill + plugin enabled); `/memex` = audit + scaffold the vault.

## Phase Ordering

1. **Sourceable refactor** — wrap the existing flow in `run_install` + lib-guard, no behavior change. Unblocks testing.
2. **Config functions (TDD)** — `marketplace_source`, engine/merge/snippet, `configure_plugin` soft-fail, `remove_legacy_commands`, `print_next_steps`, each test-first in `tests/install/run.sh`.
3. **Wire + integration** — call the new functions from `run_install`; run the real network smoke check.
4. **Docs + gates** — README re-narration; `shellcheck`, full test run, `validate-spec.sh`.

## Constraints

- POSIX `sh` (`set -eu`); must stay `shellcheck -s sh` clean.
- Curl-pipeable: no command in `run_install` may read the script's stdin (the `</dev/null` on `npx` stays).
- Merge must never overwrite `.claude/settings.json` wholesale — unrelated top-level keys survive (per `claude-plugin-settings.md`).
- `tests/install/run.sh` must not require network (no `npx`); it only sources and calls functions.
- No change to the `/memex` skill or to `skills/memex/references/claude-plugin-settings.md` coordinates.

## User Stories / Scenarios

1. A user runs `curl -fsSL …/install.sh | sh` in a fresh repo → gets the skill, the symlink, the lockfile, **and** `.claude/settings.json` with the marketplace + `memex@memex` enabled; the closing message tells them to run `/memex` and that the plugin installs at trust-time.
2. A user re-runs `install.sh` → settings.json converges, no duplication, existing keys intact.
3. A user without `jq` or `python3` runs it → skill still installs; a warning prints the exact JSON to paste; the script exits 0.

## Acceptance Criteria

- [x] **AC-1** With no `.claude-plugin/marketplace.json` declaring `"name":"memex"`, `marketplace_source` prints exactly `{"source":"github","repo":"ribeirogab/memex"}`.
- [x] **AC-2** In a dir whose `.claude-plugin/marketplace.json` contains a top-level `"name": "memex"`, `marketplace_source` prints exactly `{"source":"directory","path":"."}`.
- [x] **AC-3** After `configure_plugin` runs in a tmpdir with no prior `.claude/settings.json`, `jq '.enabledPlugins["memex@memex"]' .claude/settings.json` is `true` and `jq -c '.extraKnownMarketplaces.memex.source' .claude/settings.json` equals the `marketplace_source` output.
- [x] **AC-4** Given a pre-existing `.claude/settings.json` of `{"theme":"dark"}`, after `configure_plugin` the file still has `.theme == "dark"` plus both new keys.
- [x] **AC-5** Running the merge twice yields a `.claude/settings.json` byte-identical to running it once (idempotent).
- [x] **AC-6** For the same `SETTINGS` input and `SRC`, `merge_with_python` produces a JSON object deep-equal to `merge_with_jq` (verified with `jq -S` normalization).
- [x] **AC-7** With `plugin_merge_engine` forced to `none`, `configure_plugin` creates **no** `.claude/settings.json`, returns 0, and prints a snippet whose text contains both `memex@memex` and `extraKnownMarketplaces`.
- [x] **AC-8** Given `.claude/commands/memex-spec.md` present, after `remove_legacy_commands` that file does not exist.
- [x] **AC-9** `print_next_steps` output contains the literal `/memex` and a trust-time instruction (matches `trust` or `reopen`, case-insensitive).
- [x] **AC-10** `shellcheck -s sh install.sh` exits 0 and `bash tests/install/run.sh` prints `PASS` for every case and exits 0.
- [x] **AC-11** A real `sh install.sh` in a clean tmpdir (network) produces `.agents/skills/memex/SKILL.md`, a `.claude/skills/memex` symlink that resolves to `SKILL.md`, `skills-lock.json`, and a `.claude/settings.json` where `jq '.enabledPlugins["memex@memex"]'` is `true`.
- [x] **AC-12** README contains exactly one fenced `install.sh` invocation and describes `install.sh` as enabling the plugin and `/memex` as scaffolding the vault.

## Risks and Mitigations

| Risk | Mitigation |
|---|---|
| `curl \| sh` stdin-drain regressing (the bug fixed in this branch) | `</dev/null` on `npx` stays; AC-11 runs the real piped path equivalently via `sh install.sh`. |
| `grep`-based dogfood detection matching `"name":"memex"` elsewhere in the JSON | marketplace.json's `name` is a fixed top-level key; the github default is the safe fallback when detection is wrong, and dogfood only ever runs inside this repo. |
| jq and python writing differently-formatted JSON | AC-6 asserts deep-equality of the resulting object (not byte format); both go through a `mktemp` copy, never read-and-truncate. |
| Refactor accidentally changes base-install behavior | Phase 1 is a no-behavior-change wrap; AC-11 re-verifies the full base tree. |

## Open Questions

None.
