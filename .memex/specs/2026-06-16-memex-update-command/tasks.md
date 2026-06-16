---
feature: memex-update-command
design: "[[2026-06-16-memex-update-command/design|design]]"
spec: "[[2026-06-16-memex-update-command/spec|spec]]"
created: 2026-06-16
---
# /memex:update — Tasks

> **For agentic workers:** implement task-by-task. Steps use checkbox (`- [ ]`) syntax. Each task names the `AC:` it satisfies and a `Delegable:` note. Run the engine's `--self-test` after every change to it. The engine is testable offline: set `MEMEX_UPSTREAM_DIR` to a local dir to skip the git clone, and `MEMEX_ROOT` to operate in a sandbox.

**For this spec:** `[[2026-06-16-memex-update-command/spec|spec]]`

---

## Phase 1: The reconcile engine (TDD)

### Task 1: Pure classifier + its self-test

**AC:** AC-1
**Delegable:** yes — isolated context: "a bash function `classify_one L B U` returning one of current/stale-clean/local-only/conflict per the spec's 3-way table, plus a self-test that asserts the matrix; degrade to 2-way when B is empty."
**Files:**
- Create: `skills/memex/scaffold/vault-scripts/memex-update.sh`

- [ ] **Step 1: Write the failing self-test for the classifier**

Create `memex-update.sh` with just the classifier + a self-test harness:

```bash
#!/usr/bin/env bash
# memex-update.sh — reconcile an installed memex against upstream.
set -euo pipefail

# classify_one L B U → prints one class. B empty ⇒ 2-way degrade.
classify_one() {
  local L="$1" B="$2" U="$3"
  if [ -z "$B" ]; then [ "$L" = "$U" ] && echo current || echo conflict; return; fi
  if   [ "$L" = "$U" ]; then echo current
  elif [ "$L" = "$B" ]; then echo stale-clean
  elif [ "$B" = "$U" ]; then echo local-only
  else echo conflict; fi
}

_selftest_classifier() {
  local fails=0 got
  _expect() { got=$(classify_one "$2" "$3" "$4"); [ "$got" = "$1" ] || { echo "FAIL $5: want $1 got $got"; fails=1; }; }
  _expect current     aaa aaa aaa  "L==B==U"
  _expect stale-clean aaa aaa bbb  "L==B!=U"
  _expect local-only  bbb aaa aaa  "B==U!=L"
  _expect conflict    bbb aaa ccc  "all-differ"
  _expect current     aaa bbb aaa  "L==U!=B (converged)"
  _expect current     aaa "" aaa   "no-baseline equal"
  _expect conflict    aaa "" bbb   "no-baseline differ"
  return $fails
}

case "${1:-}" in
  --self-test) _selftest_classifier && echo "self-test: PASS" ;;
esac
```

- [ ] **Step 2: Run it, confirm it passes**

Run: `bash skills/memex/scaffold/vault-scripts/memex-update.sh --self-test`
Expected: `self-test: PASS` and exit 0. (If a case fails it prints `FAIL <name>` and exits non-zero.)

- [ ] **Step 3: Commit**

```bash
git add skills/memex/scaffold/vault-scripts/memex-update.sh
git commit -m "feat(update): 3-way classifier + self-test"
```

### Task 2: Hashing, managed set, AGENTS block, manifest I/O

**AC:** AC-8, AC-14
**Delegable:** yes — context: "add to memex-update.sh: portable sha256 helpers, the managed-pairs emitter, the AGENTS spec-flow block extractor, jq-based manifest read, and `--list-managed`. No git commit/push/gh anywhere."
**Files:**
- Modify: `skills/memex/scaffold/vault-scripts/memex-update.sh`

- [ ] **Step 1: Add helpers above the `case` block**

```bash
MANIFEST="${MEMEX_MANIFEST:-.memex/.update-manifest.json}"

_sha_file() { if command -v shasum >/dev/null 2>&1; then shasum -a 256 "$1" | awk '{print $1}'; else sha256sum "$1" | awk '{print $1}'; fi; }
_sha_str()  { if command -v shasum >/dev/null 2>&1; then printf '%s' "$1" | shasum -a 256 | awk '{print $1}'; else printf '%s' "$1" | sha256sum | awk '{print $1}'; fi; }

# spec-flow block: lines after "### Spec flow" up to the next "## " header.
_spec_flow_block() {
  awk '/^### Spec flow[[:space:]]*$/{c=1;next} c&&/^## /{c=0} c{print}' "$1"
}

# managed_pairs <clone_root> → <local_path>\t<kind>\t<upstream_source>
managed_pairs() {
  local clone="$1" s
  for s in recall brainstorming writing-plans link new-pr code-review update; do
    printf '.agents/skills/memex-%s/SKILL.md\tfile\t%s/skills/memex/scaffold/skills/memex-%s/SKILL.md\n' "$s" "$clone" "$s"
  done
  printf '.memex/spec-driven-development.md\tfile\t%s/skills/memex/scaffold/vault-docs/spec-driven-development.md\n' "$clone"
  printf '.memex/scripts/validate-spec.sh\tfile\t%s/skills/memex/scaffold/vault-scripts/validate-spec.sh\n' "$clone"
  printf '.memex/scripts/memex-update.sh\tfile\t%s/skills/memex/scaffold/vault-scripts/memex-update.sh\n' "$clone"
  printf 'AGENTS.md#spec-flow\tagentsblock\t%s/skills/memex/references/agents-md-template.md\n' "$clone"
}

# local hash for a managed entry (kind file → whole file; agentsblock → block)
_local_hash() {
  local path="$1" kind="$2"
  if [ "$kind" = agentsblock ]; then
    [ -f AGENTS.md ] || { echo ""; return; }
    _sha_str "$(_spec_flow_block AGENTS.md)"
  else
    [ -f "$path" ] && _sha_file "$path" || echo ""
  fi
}
_upstream_hash() {
  local src="$1" kind="$2"
  if [ "$kind" = agentsblock ]; then _sha_str "$(_spec_flow_block "$src")"; else _sha_file "$src"; fi
}
_baseline_hash() {
  [ -f "$MANIFEST" ] || { echo ""; return; }
  jq -r --arg k "$1" '.files[$k] // ""' "$MANIFEST" 2>/dev/null || echo ""
}
```

- [ ] **Step 2: Add `--list-managed` to the `case`**

```bash
  --list-managed) managed_pairs "${MEMEX_UPSTREAM_DIR:-.}" | cut -f1 ;;
```

- [ ] **Step 3: Verify the managed list excludes living vault content (AC-8)**

Run:
```bash
bash skills/memex/scaffold/vault-scripts/memex-update.sh --list-managed \
  | grep -E '^\.memex/(_index|learnings|conventions|specs)/' && echo FAIL || echo PASS
```
Expected: `PASS` (no managed path under those prefixes).

- [ ] **Step 4: Verify no commit/push/PR in the engine (AC-14)**

Run: `grep -nE 'git (commit|push)|gh (pr|release)' skills/memex/scaffold/vault-scripts/memex-update.sh && echo FAIL || echo PASS`
Expected: `PASS`.

- [ ] **Step 5: Commit**

```bash
git add skills/memex/scaffold/vault-scripts/memex-update.sh
git commit -m "feat(update): hashing, managed set, manifest read, --list-managed"
```

### Task 3: Classify+apply main loop, --record, report, fixture self-test

**AC:** AC-1, AC-2, AC-3, AC-4, AC-5, AC-6, AC-7, AC-15
**Delegable:** no — ties the engine together and adds the apply-sandbox self-test; needs the whole picture.
**Files:**
- Modify: `skills/memex/scaffold/vault-scripts/memex-update.sh`

(No persistent fixtures file — the apply-sandbox self-test builds and tears down its local/upstream/manifest trees via `mktemp -d`.)

- [ ] **Step 1: Add the reconcile loop + report + `--record`**

```bash
# reconcile <clone_root> : classify each managed entry, apply stale-clean, print report lines.
reconcile() {
  local clone="$1" line local kind src L B U cls
  while IFS=$'\t' read -r local kind src; do
    L=$(_local_hash "$local" "$kind"); U=$(_upstream_hash "$src" "$kind"); B=$(_baseline_hash "$local")
    cls=$(classify_one "$L" "$B" "$U")
    if [ "$cls" = stale-clean ]; then
      if [ "$kind" = agentsblock ]; then _apply_agents_block "$src"; else mkdir -p "$(dirname "$local")"; cp "$src" "$local"; fi
      _record_one "$local" "$U"
      printf 'updated\t%s\n' "$local"
    else
      printf '%s\t%s\n' "$cls" "$local"
    fi
  done < <(managed_pairs "$clone")
}

# Replace the spec-flow block in AGENTS.md with the upstream template's block.
_apply_agents_block() {
  local src="$1" tmp; tmp=$(mktemp)
  awk -v blockfile=<(_spec_flow_block "$1") '
    /^### Spec flow[[:space:]]*$/ {print; while ((getline l < blockfile) > 0) print l; skip=1; next}
    skip && /^## / {skip=0}
    !skip {print}
  ' AGENTS.md > "$tmp" && mv "$tmp" AGENTS.md
}

# _record_one <key> <hash> : upsert one manifest entry (create manifest if absent).
_record_one() {
  local key="$1" hash="$2" tmp; tmp=$(mktemp)
  if [ -f "$MANIFEST" ]; then jq --arg k "$key" --arg h "$hash" '.files[$k]=$h' "$MANIFEST" > "$tmp"
  else jq -n --arg k "$key" --arg h "$hash" '{files:{($k):$h}}' > "$tmp"; fi
  mkdir -p "$(dirname "$MANIFEST")"; mv "$tmp" "$MANIFEST"
}
```

(Note `<(_spec_flow_block ...)` uses process substitution; on systems without it the implementer may write the block to a temp file first. Keep the temp-file form if portability bites.)

- [ ] **Step 2: Wire `--record <path>` and default run into the `case`**

```bash
  --record) _record_one "$2" "$(_local_hash "$2" file)" ;;
  --self-test) _selftest_classifier && _selftest_apply && echo "self-test: PASS" ;;
  ""|--run)
    clone="${MEMEX_UPSTREAM_DIR:-}"
    if [ -z "$clone" ]; then clone=$(mktemp -d); git clone --depth 1 "$UPSTREAM" "$clone" >/dev/null 2>&1 || { echo "memex-update: fetch failed (need network)"; exit 1; }; fi
    printf 'clone\t%s\n' "$clone"   # surface upstream location; not deleted, so the skill can merge conflicts from it
    reconcile "$clone"
    ;;
```

Add `UPSTREAM="https://github.com/ribeirogab/memex"` near the top constants.

- [ ] **Step 3: Add the apply-sandbox self-test (`_selftest_apply`)**

```bash
_selftest_apply() {
  local d; d=$(mktemp -d); local fails=0
  # upstream clone-shape
  mkdir -p "$d/up/skills/memex/scaffold/skills/memex-recall" "$d/up/skills/memex/scaffold/vault-docs" \
           "$d/up/skills/memex/scaffold/vault-scripts" "$d/up/skills/memex/references"
  printf 'recall NEW\n' > "$d/up/skills/memex/scaffold/skills/memex-recall/SKILL.md"
  printf 'guide NEW\n'  > "$d/up/skills/memex/scaffold/vault-docs/spec-driven-development.md"
  printf 'validate\n'   > "$d/up/skills/memex/scaffold/vault-scripts/validate-spec.sh"
  printf 'engine\n'     > "$d/up/skills/memex/scaffold/vault-scripts/memex-update.sh"
  printf '# T\n### Spec flow\nUP-FLOW\n## Next\n' > "$d/up/skills/memex/references/agents-md-template.md"
  # local repo
  mkdir -p "$d/lo/.agents/skills/memex-recall" "$d/lo/.memex/scripts"
  printf 'recall OLD\n' > "$d/lo/.agents/skills/memex-recall/SKILL.md"   # stale-clean (baseline=OLD)
  printf 'guide OLD\n'  > "$d/lo/.memex/spec-driven-development.md"        # conflict (edited)
  printf 'validate\n'   > "$d/lo/.memex/scripts/validate-spec.sh"         # current
  printf 'engine\n'     > "$d/lo/.memex/scripts/memex-update.sh"          # current
  printf '# Local intro\n### Spec flow\nOLD-FLOW\n## Next\n' > "$d/lo/AGENTS.md"  # block stale-clean
  # manifest baseline
  mkdir -p "$d/lo/.memex"
  cat > "$d/lo/.memex/.update-manifest.json" <<JSON
{"files":{
  ".agents/skills/memex-recall/SKILL.md":"$(_sha_str "$(printf 'recall OLD\n')")",
  ".memex/spec-driven-development.md":"$(_sha_str "$(printf 'guide BASE\n')")",
  ".memex/scripts/validate-spec.sh":"$(_sha_str "$(printf 'validate\n')")",
  ".memex/scripts/memex-update.sh":"$(_sha_str "$(printf 'engine\n')")",
  "AGENTS.md#spec-flow":"$(printf 'OLD-FLOW\n' | { command -v shasum >/dev/null && shasum -a 256 || sha256sum; } | awk '{print $1}')"
}}
JSON
  ( cd "$d/lo" && MEMEX_UPSTREAM_DIR="$d/up" MEMEX_MANIFEST=".memex/.update-manifest.json" \
      bash "$OLDPWD/skills/memex/scaffold/vault-scripts/memex-update.sh" --run > "$d/report.txt" )
  grep -q $'updated\t.agents/skills/memex-recall/SKILL.md' "$d/report.txt" || { echo "FAIL apply: recall not updated"; fails=1; }
  diff <(printf 'recall NEW\n') "$d/lo/.agents/skills/memex-recall/SKILL.md" >/dev/null || { echo "FAIL apply: recall content"; fails=1; }
  grep -q $'conflict\t.memex/spec-driven-development.md' "$d/report.txt" || { echo "FAIL apply: guide not conflict"; fails=1; }
  grep -q 'UP-FLOW' "$d/lo/AGENTS.md" || { echo "FAIL apply: AGENTS block not updated"; fails=1; }
  grep -q 'Local intro' "$d/lo/AGENTS.md" || { echo "FAIL apply: AGENTS intro clobbered"; fails=1; }
  rm -rf "$d"; return $fails
}
```

(The baseline hashes above are illustrative; when implementing, compute each baseline with the same `_sha_*` the engine uses so `stale-clean`/`conflict` land as intended. The harness's job is to prove the four observable outcomes: recall updated to NEW, guide reported conflict and left as OLD, AGENTS block→UP-FLOW, AGENTS intro preserved.)

- [ ] **Step 4: Run the full self-test**

Run: `bash skills/memex/scaffold/vault-scripts/memex-update.sh --self-test`
Expected: `self-test: PASS`, exit 0. Covers AC-2 (recall updated to upstream), AC-3 (validate/engine current), AC-5 (guide conflict, unchanged), AC-7 (AGENTS block updated, intro preserved), AC-6 path is exercised by removing the manifest in a follow-up assertion if desired.

- [ ] **Step 5: Add a no-manifest (2-way) assertion to `_selftest_apply`**

After the first run, `rm "$d/lo/.memex/.update-manifest.json"`, re-run with a differing local file, assert the differing file reports `conflict` and that the manifest is re-created (`test -f`). This proves AC-6.

- [ ] **Step 6: Commit**

```bash
git add skills/memex/scaffold/vault-scripts/memex-update.sh
git commit -m "feat(update): reconcile loop, AGENTS-block apply, --record, fixture self-test"
```

## Phase 2: The orchestrator skill (3 copies)

### Task 4: Write `memex-update` SKILL.md (canonical) and mirror to plugin + scaffold

**AC:** AC-9, AC-15
**Delegable:** no — must keep three copies byte-identical except `name:`.
**Files:**
- Create: `.agents/skills/memex-update/SKILL.md` (`name: memex-update`)
- Create: `plugins/memex/skills/update/SKILL.md` (`name: update`)
- Create: `skills/memex/scaffold/skills/memex-update/SKILL.md` (`name: memex-update`)

- [ ] **Step 1: Write the canonical SKILL.md**

Frontmatter `name: memex-update`, `description:` covering "sync an installed memex with upstream — reconcile scaffolded files, auto-apply untouched, merge edited". Body sections:
  - **Announce:** "Reconciling memex against upstream..."
  - **Run the engine:** `bash .memex/scripts/memex-update.sh --run` (or `--run` after confirming network). Read its `STATUS\tpath` report.
  - **Handle conflicts:** read the leading `clone\t<path>` report line — that temp clone is left in place. For each `conflict` line, read the local file and its upstream counterpart from `<clone>/skills/memex/scaffold/...` (the same mapping the engine's `managed_pairs` uses), produce a merge that **keeps the local edits and applies the upstream change**, write it, then `bash .memex/scripts/memex-update.sh --record <path>`.
  - **Report summary:** counts of `current` / `updated` / `merged` / `local-only`, then "review `git diff`, commit when satisfied. This command never commits."
  - **Degradation:** if the report shows everything as `conflict` and there was no manifest, say so — first run is 2-way; the manifest is now written, next run is precise.
  - **No PR / no commit** — explicitly.

- [ ] **Step 2: Mirror to the other two copies, fixing only `name:`**

Copy the canonical body verbatim into the plugin (`name: update`) and scaffold (`name: memex-update`) copies.

- [ ] **Step 3: Verify body identity (AC-9)**

Run:
```bash
diff <(tail -n +3 .agents/skills/memex-update/SKILL.md) <(tail -n +3 plugins/memex/skills/update/SKILL.md) && echo P1
diff <(tail -n +3 .agents/skills/memex-update/SKILL.md) <(tail -n +3 skills/memex/scaffold/skills/memex-update/SKILL.md) && echo P2
```
Expected: `P1` and `P2` (empty diffs). (Adjust `tail -n +N` so it starts below the `name:` line; bodies must be identical.)

- [ ] **Step 4: Commit**

```bash
git add .agents/skills/memex-update plugins/memex/skills/update skills/memex/scaffold/skills/memex-update
git commit -m "feat(update): memex-update orchestrator skill (3 copies)"
```

## Phase 3: Installer integration

### Task 5: Scaffold the script, write the initial manifest, register the skill

**AC:** AC-10, AC-12
**Delegable:** no — edits the installer prose; needs the scaffold conventions.
**Files:**
- Modify: `skills/memex/SKILL.md` (Scaffolding section)
- Modify: `skills/memex/references/vault-files.md`

- [ ] **Step 1: Add the update-script copy step** (mirror validate-spec.sh): copy `scaffold/vault-scripts/memex-update.sh` → `.memex/scripts/memex-update.sh`, `chmod +x`.
- [ ] **Step 2: Add `memex-update` to the canonical skills copy block** (the list that installs `.agents/skills/memex-*`).
- [ ] **Step 3: Add the initial-manifest step:** after scaffolding, run `.memex/scripts/memex-update.sh --record <path>` for every managed path (or a one-shot `--init-manifest` mode if the implementer adds it) so a fresh install ships a complete `.memex/.update-manifest.json`.
- [ ] **Step 4: Document** the manifest + the update script in `vault-files.md`'s scaffolded inventory.
- [ ] **Step 5: Verify** the dogfood scaffold path: `.memex/scripts/memex-update.sh` exists & is executable; `.memex/.update-manifest.json` parses (`jq . .memex/.update-manifest.json >/dev/null`).
- [ ] **Step 6: Commit** `chore(update): scaffold script + initial manifest + skill registration`.

## Phase 4: Audit + validation

### Task 6: Inventory + Phase-5 checks + skills loop + count bump

**AC:** AC-11, AC-12
**Delegable:** yes — context: "add inventory rows + two Phase-5 checks + add memex-update to the skills loop + bump the documented check count from 17 to 19 in validation.md and audit-checklist.md."
**Files:**
- Modify: `skills/memex/references/validation.md`
- Modify: `skills/memex/references/audit-checklist.md`

- [ ] **Step 1:** In `validation.md`, add check #18 (`[ -x .memex/scripts/memex-update.sh ]`) and #19 (`jq . .memex/.update-manifest.json >/dev/null` → PASS/FAIL); add `memex-update` to check #9's `for s in …` loop; change the count line "17 numbered checks" → "19".
- [ ] **Step 2:** In `audit-checklist.md`, add `.memex/scripts/memex-update.sh`, `.memex/.update-manifest.json`, and `.agents/skills/memex-update/` to the inventory; add `memex-update` to the canonical-skills list.
- [ ] **Step 3: Verify** `grep -c 'memex-update' skills/memex/references/validation.md` ≥ 1 and the count line reads 19.
- [ ] **Step 4: Commit** `docs(update): audit + Phase-5 validation for update script, manifest, skill`.

## Phase 5: Docs

### Task 7: AGENTS.md, template, README, plugin.json

**AC:** AC-13, AC-16
**Delegable:** yes — context: "add a one-line `/memex:update` entry to the skills list in AGENTS.md and agents-md-template.md, to README's commands list, and to plugin.json's description; keep AGENTS.md ≤ 80 lines."
**Files:**
- Modify: `AGENTS.md`, `skills/memex/references/agents-md-template.md`, `README.md`, `plugins/memex/.claude-plugin/plugin.json`

- [ ] **Step 1:** Add `- **`/memex:update`** — sync the installed memex with upstream (reconcile scaffolded files).` to the "Skills and slash commands" list in `AGENTS.md` and the template.
- [ ] **Step 2:** Add `/memex:update` to README's companion-skills/commands description.
- [ ] **Step 3:** Add `update` to `plugin.json`'s `description`.
- [ ] **Step 4: Verify** `wc -l < AGENTS.md` ≤ 80 (AC-16) and `grep -l 'memex:update' AGENTS.md skills/memex/references/agents-md-template.md README.md` lists all three (AC-13).
- [ ] **Step 5: Commit** `docs(update): list /memex:update across AGENTS, template, README, plugin`.

## Phase 6: Dogfood + verify

### Task 8: Install into this repo and walk every AC

**AC:** AC-1, AC-10, AC-11, AC-16 (and re-confirm all)
**Delegable:** no — final integration + AC walk.
**Files:**
- Create: `.memex/scripts/memex-update.sh` (copy of scaffold source, `chmod +x`)
- Create: `.memex/.update-manifest.json` (this repo's baseline)

- [ ] **Step 1:** `cp skills/memex/scaffold/vault-scripts/memex-update.sh .memex/scripts/memex-update.sh && chmod +x .memex/scripts/memex-update.sh`. Verify `diff` with the source is empty (AC-10).
- [ ] **Step 2:** Generate this repo's manifest via the `--record`/`--init` path for every managed path; `jq .` it (AC-11 manifest valid).
- [ ] **Step 3:** Run `bash .memex/scripts/memex-update.sh --self-test` → PASS (AC-1).
- [ ] **Step 4:** Run the Phase-5 validation checks #18/#19 and #9 (with memex-update) → PASS (AC-11, AC-12).
- [ ] **Step 5:** Walk AC-1…AC-16, recording each as met (the binary check from the spec). Fix any gap.
- [ ] **Step 6: Commit** `chore(update): dogfood memex-update script + manifest into this repo`.
