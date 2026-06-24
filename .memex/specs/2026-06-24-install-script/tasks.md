---
feature: install-script
design: "[[2026-06-24-install-script/design|design]]"
spec: "[[2026-06-24-install-script/spec|spec]]"
created: 2026-06-24
---
# Per-project install.sh — Tasks

> **For agentic workers:** implement task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. Each task names the `AC:` it satisfies and a `Delegable:` note.

**For this spec:** `[[2026-06-24-install-script/spec|spec]]`

> Each task names the `AC:` (from `[[2026-06-24-install-script/spec|spec]]`) and `Delegable:`. The shipped base `install.sh` (commit `94337c5`) installs the skill + symlink + lockfile; these tasks add plugin-config and make the config testable.

---

## Phase 1: Sourceable refactor + test harness

### Task 1: Wrap install.sh in `run_install` + lib-guard

**AC:** AC-10, AC-11 (enabler — no behavior change)
**Delegable:** no — the implementer needs the whole-file shape.
**Files:**
- Modify: `install.sh`

- [ ] **Step 1: Move the procedural body (current lines 29-61) into a `run_install` function and add the lib-guard.** Keep `set -eu`, the `REPO`/`SKILL`/`CANONICAL`/`LINK` vars, and `say`/`fail` at top level. Replace everything from the `# --- prerequisites` block to the end with:

```sh
run_install() {
  command -v npx >/dev/null 2>&1 || fail "npx not found. Install Node.js (https://nodejs.org) and retry."

  say "Installing ${SKILL} skill from ${REPO} ..."
  # </dev/null: under `curl ... | sh` stdin IS the script source; npx/skills would
  # otherwise drain it, swallowing every line below.
  npx -y skills add "${REPO}" --skill "${SKILL}" -a universal -y </dev/null

  [ -f "${CANONICAL}/SKILL.md" ] || fail "skills CLI did not produce ${CANONICAL}/SKILL.md"

  mkdir -p ".claude/skills"
  if [ -L "${LINK}" ]; then
    rm -f "${LINK}"
  elif [ -e "${LINK}" ]; then
    fail "${LINK} exists and is not a symlink. Remove it and re-run."
  fi
  ln -s "../../.agents/skills/${SKILL}" "${LINK}"

  [ -L "${LINK}" ]          || fail "${LINK} is not a symlink"
  [ -f "${LINK}/SKILL.md" ] || fail "${LINK} does not resolve to the skill"
  [ -f "skills-lock.json" ] || fail "skills-lock.json was not created"

  remove_legacy_commands
  configure_plugin
  print_next_steps
}

# Run only when executed, not when sourced (tests source with MEMEX_INSTALL_LIB=1).
[ "${MEMEX_INSTALL_LIB:-0}" = "1" ] || run_install
```

Also update the header comment block to list `.claude/settings.json   <- marketplace + plugin enabled` in the layout, and add `#   # tests source this file with MEMEX_INSTALL_LIB=1 to call functions without network`. (The `remove_legacy_commands`, `configure_plugin`, `print_next_steps` functions are added in later tasks — the script will not run cleanly until Task 6 wires them; that is expected.)

- [ ] **Step 2: Create the test harness `tests/install/run.sh`.**

```bash
#!/usr/bin/env bash
# Unit tests for install.sh config logic. Sources install.sh in lib mode
# (no npx / no network) and exercises the pure functions against tmpdirs.
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
fails=0
pass() { printf 'PASS: %s\n' "$1"; }
die()  { printf 'FAIL: %s\n' "$1"; fails=$((fails + 1)); }
assert_eq() { if [ "$2" = "$3" ]; then pass "$1"; else die "$1 — expected [$2] got [$3]"; fi; }

# Source install.sh as a library, then relax the strict flags it sets so the
# assertions below can inspect non-zero exits.
MEMEX_INSTALL_LIB=1 . "$ROOT/install.sh"
set +eu

# --- cases appended by later tasks ---

if [ "$fails" -eq 0 ]; then echo "ALL PASS"; exit 0; else echo "$fails FAILED"; exit 1; fi
```

- [ ] **Step 3: Run shellcheck on the harness and confirm it sources cleanly.**

Run: `shellcheck -s sh install.sh; bash tests/install/run.sh`
Expected: shellcheck reports the not-yet-defined functions as referenced-but-undefined is NOT a shellcheck error (they are defined later in the same file once added); the harness prints `ALL PASS` (zero cases yet). If sourcing aborts, the lib-guard is wrong — fix before continuing.

- [ ] **Step 4: Commit**

```bash
git add install.sh tests/install/run.sh
git commit -m "refactor: make install.sh sourceable for testing"
```

---

## Phase 2: Config functions (TDD)

### Task 2: `marketplace_source`

**AC:** AC-1, AC-2
**Delegable:** yes — "Add a POSIX sh function `marketplace_source` to install.sh that echoes a marketplace source JSON; dogfood-detect via grep on .claude-plugin/marketplace.json."
**Files:**
- Modify: `install.sh`, `tests/install/run.sh`

- [ ] **Step 1: Add the failing tests** (before the final `if` in `run.sh`):

```bash
# marketplace_source
(
  d="$(mktemp -d)"; cd "$d"
  assert_eq "source: github default" '{"source":"github","repo":"ribeirogab/memex"}' "$(marketplace_source)"
  mkdir -p .claude-plugin
  printf '{ "name": "memex", "owner": "ribeirogab" }\n' > .claude-plugin/marketplace.json
  assert_eq "source: dogfood directory" '{"source":"directory","path":"."}' "$(marketplace_source)"
  cd /; rm -rf "$d"
)
```

- [ ] **Step 2: Run — expect FAIL** (`marketplace_source: command not found` / not defined).

Run: `bash tests/install/run.sh`
Expected: FAIL lines for both cases.

- [ ] **Step 3: Implement** — add to install.sh (after `fail()`):

```sh
# Marketplace source JSON. Dogfood: inside ribeirogab/memex itself
# (.claude-plugin/marketplace.json declares name = memex) use the local path.
marketplace_source() {
  if [ -f .claude-plugin/marketplace.json ] && \
     grep -Eq '"name"[[:space:]]*:[[:space:]]*"memex"' .claude-plugin/marketplace.json; then
    printf '{"source":"directory","path":"."}'
  else
    printf '{"source":"github","repo":"%s"}' "$REPO"
  fi
}
```

- [ ] **Step 4: Run — expect PASS** for both cases.

Run: `bash tests/install/run.sh`
Expected: `PASS: source: github default` and `PASS: source: dogfood directory`.

- [ ] **Step 5: Commit**

```bash
git add install.sh tests/install/run.sh
git commit -m "feat: marketplace_source with dogfood detection"
```

### Task 3: merge engine, jq/python merge, snippet

**AC:** AC-3 (base), AC-6
**Delegable:** yes — "Add `plugin_merge_engine`, `plugin_snippet`, `merge_with_jq`, `merge_with_python` to install.sh; jq and python paths must produce deep-equal JSON."
**Files:**
- Modify: `install.sh`, `tests/install/run.sh`

- [ ] **Step 1: Add the failing tests:**

```bash
# merge engine + jq/python parity
(
  d="$(mktemp -d)"; cd "$d"
  src='{"source":"github","repo":"ribeirogab/memex"}'

  printf '{}' > a.json
  merge_with_jq a.json "$src"
  assert_eq "jq: plugin enabled" 'true' "$(jq -c '.enabledPlugins["memex@memex"]' a.json)"
  assert_eq "jq: marketplace source" "$src" "$(jq -c '.extraKnownMarketplaces.memex.source' a.json)"

  printf '{}' > b.json
  merge_with_python b.json "$src"
  assert_eq "jq vs python parity" \
    "$(jq -S . a.json)" "$(jq -S . b.json)"

  assert_eq "snippet mentions plugin" 'yes' \
    "$(plugin_snippet "$src" | grep -q 'memex@memex' && echo yes || echo no)"
  cd /; rm -rf "$d"
)
```

- [ ] **Step 2: Run — expect FAIL.**

Run: `bash tests/install/run.sh`
Expected: FAIL (functions undefined).

- [ ] **Step 3: Implement** — add to install.sh:

```sh
# Which JSON tool merges settings: jq > python3 > none (the soft-fail signal).
plugin_merge_engine() {
  if command -v jq >/dev/null 2>&1; then printf 'jq'
  elif command -v python3 >/dev/null 2>&1; then printf 'python3'
  else printf 'none'; fi
}

# Human-pasteable settings.json object for the soft-fail path.
plugin_snippet() {
  src="$1"
  printf '%s\n' '{'
  printf '  "extraKnownMarketplaces": { "memex": { "source": %s } },\n' "$src"
  printf '%s\n' '  "enabledPlugins": { "memex@memex": true }'
  printf '%s\n' '}'
}

# Merge the two keys into $1, preserving every other top-level key. The mktemp
# copy avoids reading and truncating the same file in one redirect.
merge_with_jq() {
  settings="$1"; src="$2"; tmp="$(mktemp)"
  if [ -s "$settings" ]; then cp "$settings" "$tmp"; else printf '{}' > "$tmp"; fi
  jq --argjson src "$src" '
    .extraKnownMarketplaces["memex"] = { "source": $src }
    | .enabledPlugins["memex@memex"] = true
  ' "$tmp" > "$settings"
  rm -f "$tmp"
}

merge_with_python() {
  MEMEX_SETTINGS="$1" MEMEX_SRC="$2" python3 - <<'PY'
import json, os, pathlib
p = pathlib.Path(os.environ["MEMEX_SETTINGS"])
src = json.loads(os.environ["MEMEX_SRC"])
data = json.loads(p.read_text()) if p.exists() and p.read_text().strip() else {}
data.setdefault("extraKnownMarketplaces", {})["memex"] = {"source": src}
data.setdefault("enabledPlugins", {})["memex@memex"] = True
p.write_text(json.dumps(data, indent=2) + "\n")
PY
}
```

- [ ] **Step 4: Run — expect PASS** for all four cases.

Run: `bash tests/install/run.sh`
Expected: PASS for jq enabled / source / parity / snippet.

- [ ] **Step 5: Commit**

```bash
git add install.sh tests/install/run.sh
git commit -m "feat: settings.json merge (jq + python parity) and snippet"
```

### Task 4: `configure_plugin` (orchestration + preserve + idempotent + soft-fail)

**AC:** AC-3, AC-4, AC-5, AC-7
**Delegable:** yes — "Add `configure_plugin` to install.sh orchestrating marketplace_source → plugin_merge_engine → merge, with a soft-fail branch when engine is none."
**Files:**
- Modify: `install.sh`, `tests/install/run.sh`

- [ ] **Step 1: Add the failing tests:**

```bash
# configure_plugin: writes keys, preserves existing, idempotent
(
  d="$(mktemp -d)"; cd "$d"
  mkdir -p .claude; printf '{"theme":"dark"}' > .claude/settings.json
  configure_plugin >/dev/null
  assert_eq "configure: enabled"  'true'   "$(jq -c '.enabledPlugins["memex@memex"]' .claude/settings.json)"
  assert_eq "configure: preserves" '"dark"' "$(jq -c '.theme' .claude/settings.json)"
  one="$(cat .claude/settings.json)"
  configure_plugin >/dev/null
  assert_eq "configure: idempotent" "$one" "$(cat .claude/settings.json)"
  cd /; rm -rf "$d"
)
# configure_plugin soft-fail: engine none → no settings, snippet printed
(
  d="$(mktemp -d)"; cd "$d"
  plugin_merge_engine() { printf 'none'; }   # override after sourcing
  out="$(configure_plugin)"; rc=$?
  assert_eq "softfail: rc 0" '0' "$rc"
  assert_eq "softfail: no settings" 'no' "$([ -f .claude/settings.json ] && echo yes || echo no)"
  assert_eq "softfail: snippet has marketplace" 'yes' \
    "$(printf '%s' "$out" | grep -q 'extraKnownMarketplaces' && echo yes || echo no)"
  assert_eq "softfail: snippet has plugin" 'yes' \
    "$(printf '%s' "$out" | grep -q 'memex@memex' && echo yes || echo no)"
  cd /; rm -rf "$d"
)
```

(The `plugin_merge_engine` override is inside the `( ... )` subshell, so it does not leak to the parent harness — no restore needed.)

- [ ] **Step 2: Run — expect FAIL.**

Run: `bash tests/install/run.sh`
Expected: FAIL (`configure_plugin` undefined).

- [ ] **Step 3: Implement** — add to install.sh:

```sh
# Enable the Claude Code plugin by merging marketplace + enabledPlugins into
# .claude/settings.json. Soft-fail (no abort) when no JSON tool is available.
configure_plugin() {
  settings=".claude/settings.json"
  src="$(marketplace_source)"
  mkdir -p .claude
  case "$(plugin_merge_engine)" in
    jq)      merge_with_jq "$settings" "$src" ;;
    python3) merge_with_python "$settings" "$src" ;;
    *)
      say "warning: neither jq nor python3 found — plugin not auto-configured."
      say "Add this to ${settings} manually:"
      plugin_snippet "$src"
      return 0
      ;;
  esac
  say "Enabled memex plugin in ${settings}"
}
```

- [ ] **Step 4: Run — expect PASS** for all six cases.

Run: `bash tests/install/run.sh`
Expected: PASS for all seven asserts — configure enabled/preserves/idempotent and softfail rc/no-settings/snippet×2.

- [ ] **Step 5: Commit**

```bash
git add install.sh tests/install/run.sh
git commit -m "feat: configure_plugin with idempotent merge and soft-fail"
```

### Task 5: `remove_legacy_commands` + `print_next_steps`

**AC:** AC-8, AC-9
**Delegable:** yes — "Add `remove_legacy_commands` (rm -f the four .claude/commands/memex-*.md) and `print_next_steps` (closing message recommending /memex + trust-time note)."
**Files:**
- Modify: `install.sh`, `tests/install/run.sh`

- [ ] **Step 1: Add the failing tests:**

```bash
# remove_legacy_commands
(
  d="$(mktemp -d)"; cd "$d"
  mkdir -p .claude/commands; : > .claude/commands/memex-spec.md
  remove_legacy_commands
  assert_eq "legacy removed" 'no' "$([ -e .claude/commands/memex-spec.md ] && echo yes || echo no)"
  cd /; rm -rf "$d"
)
# print_next_steps
out="$(print_next_steps)"
assert_eq "next-steps mentions /memex" 'yes' "$(printf '%s' "$out" | grep -q '/memex' && echo yes || echo no)"
assert_eq "next-steps mentions trust" 'yes' \
  "$(printf '%s' "$out" | grep -Eqi 'trust|reopen' && echo yes || echo no)"
```

- [ ] **Step 2: Run — expect FAIL.**

Run: `bash tests/install/run.sh`
Expected: FAIL (functions undefined).

- [ ] **Step 3: Implement** — add to install.sh:

```sh
# Remove pre-plugin leftover command files (missing files are not an error).
remove_legacy_commands() {
  for cmd in memex-spec memex-learn memex-sweep memex-review-spec; do
    rm -f ".claude/commands/${cmd}.md"
  done
}

print_next_steps() {
  say ""
  say "memex installed:"
  say "  ${CANONICAL}/"
  say "  ${LINK} -> ../../.agents/skills/${SKILL}"
  say "  skills-lock.json"
  say "  .claude/settings.json (memex marketplace + plugin enabled)"
  say ""
  say "Next: open this repo in your coding agent and run  /memex"
  say "  (audits the memex and scaffolds whatever is missing)"
  say ""
  say "The memex plugin (/memex:spec, /memex:new-pr, ...) installs when Claude Code"
  say "trusts this workspace — reopen the repo or accept the trust prompt."
}
```

- [ ] **Step 4: Run — expect PASS.**

Run: `bash tests/install/run.sh`
Expected: PASS for legacy removed / next-steps /memex / next-steps trust.

- [ ] **Step 5: Commit**

```bash
git add install.sh tests/install/run.sh
git commit -m "feat: legacy command cleanup and /memex next-steps message"
```

---

## Phase 3: Wire + integration

### Task 6: Confirm wiring + network smoke check

**AC:** AC-11
**Delegable:** no — needs network and judgement on the real install.
**Files:**
- Verify: `install.sh`

- [ ] **Step 1:** Confirm `run_install` (from Task 1) already calls `remove_legacy_commands`, `configure_plugin`, `print_next_steps` in that order, and that the old inline `say` tail was removed (no duplicate output). If the Task 1 body still has the old trailing `say "Next: ..."` lines, delete them — `print_next_steps` owns the closing message now.

- [ ] **Step 2: Run the real install in a clean tmpdir** (network):

```bash
cd "$(mktemp -d)" && git init -q
sh "$OLDPWD/install.sh"   # or: curl-equivalent; OLDPWD points back to the repo
```

- [ ] **Step 3: Assert the full tree + plugin config:**

```bash
test -f .agents/skills/memex/SKILL.md && echo "canonical OK"
test -f .claude/skills/memex/SKILL.md && echo "symlink resolves OK"
test -f skills-lock.json && echo "lock OK"
jq -e '.enabledPlugins["memex@memex"] == true' .claude/settings.json >/dev/null && echo "plugin OK"
jq -e '.extraKnownMarketplaces.memex.source.repo == "ribeirogab/memex"' .claude/settings.json >/dev/null && echo "marketplace OK"
```

Expected: `canonical OK`, `symlink resolves OK`, `lock OK`, `plugin OK`, `marketplace OK`.

- [ ] **Step 4: Pipe-mode regression check** — confirm `curl|sh` stdin-drain stays fixed:

```bash
cd "$(mktemp -d)" && git init -q && cat "$OLDPWD/install.sh" | sh
readlink .claude/skills/memex   # must print ../../.agents/skills/memex
jq -e '.enabledPlugins["memex@memex"]' .claude/settings.json >/dev/null && echo "pipe OK"
```

Expected: symlink target printed + `pipe OK`.

- [ ] **Step 5: Commit** (only if Step 1 required an edit)

```bash
git add install.sh
git commit -m "fix: remove duplicated install tail after wiring next-steps"
```

---

## Phase 4: Docs + gates

### Task 7: README re-narration

**AC:** AC-12
**Delegable:** yes — "Update README.md Install section: install.sh = full Claude Code-side setup (skill + plugin enabled); /memex = audit + scaffold the vault. Keep exactly one fenced install.sh command."
**Files:**
- Modify: `README.md`

- [ ] **Step 1:** In the `## Install` section, add a primary one-line `install.sh` path and describe the split. Keep the existing `npx skills add` line as the underlying mechanism. The current subsection heading is `### Two ways in` with two bullets — adding a third entry means **renaming that heading** (e.g. `### Ways in`) so it does not contradict the bullet count. Example block to add (adapt to surrounding prose):

```markdown
- **`install.sh` (one command)** — `curl -fsSL https://raw.githubusercontent.com/ribeirogab/memex/main/install.sh | sh` installs the scaffolder skill **and** enables the marketplace plugin in `.claude/settings.json`. Then open the repo in your agent and run `/memex` to audit and scaffold the `.memex/` vault. The plugin (`/memex:spec`, `/memex:new-pr`, …) installs when Claude Code trusts the workspace.
```

- [ ] **Step 2: Verify** exactly one fenced `install.sh` invocation and the split is described:

Run: `grep -c 'install.sh | sh' README.md; grep -n '/memex' README.md | head`
Expected: the count is 1; `/memex` is described as the scaffold/audit step.

- [ ] **Step 3: Commit**

```bash
git add README.md
git commit -m "docs(readme): describe install.sh plugin setup vs /memex scaffold"
```

### Task 8: Quality gate

**AC:** AC-10 (and re-confirms AC-1..AC-9)
**Delegable:** no.
**Files:**
- Verify: `install.sh`, `tests/install/run.sh`

- [ ] **Step 1: Lint.**

Run: `shellcheck -s sh install.sh`
Expected: clean (exit 0). Fix any finding.

- [ ] **Step 2: Run the full unit suite.**

Run: `bash tests/install/run.sh`
Expected: `ALL PASS`, exit 0.

- [ ] **Step 3: Mechanical spec gate.**

Run: `bash .memex/scripts/validate-spec.sh .memex/specs/2026-06-24-install-script`
Expected: exit 0.

- [ ] **Step 4: Commit** (if anything changed in Steps 1-2)

```bash
git add install.sh tests/install/run.sh
git commit -m "test: install.sh config unit suite passes shellcheck and run.sh"
```
