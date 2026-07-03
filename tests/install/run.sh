#!/usr/bin/env bash
# Smoke tests for the plugin-only install/setup surface. There is no
# install.sh anymore: the plugin is added via `claude plugin marketplace add`
# + `claude plugin install`, and per-repo content comes from /sw:init. These
# checks assert the repo's own plugin manifests and skill files are in the
# shape those two entry points depend on.
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
fails=0
pass() { printf 'PASS: %s\n' "$1"; }
die()  { printf 'FAIL: %s\n' "$1"; fails=$((fails + 1)); }
assert_eq() { if [ "$2" = "$3" ]; then pass "$1"; else die "$1 — expected [$2] got [$3]"; fi; }

# --- install.sh is retired (AC-1) -------------------------------------------
assert_eq "install.sh absent at repo root" 'no' \
  "$([ -f "$ROOT/install.sh" ] && echo yes || echo no)"

# --- marketplace.json is valid and points at the plugin (AC-2, AC-5) --------
mp="$ROOT/.claude-plugin/marketplace.json"
assert_eq "marketplace.json exists" 'yes' "$([ -f "$mp" ] && echo yes || echo no)"
if command -v jq >/dev/null 2>&1; then
  assert_eq "marketplace.json: valid JSON" '0' "$(jq empty "$mp" >/dev/null 2>&1; echo $?)"
  assert_eq "marketplace.json: plugin source" './plugins/sw' "$(jq -r '.plugins[0].source' "$mp")"
  assert_eq "marketplace.json: description lists sw:init" 'yes' \
    "$(jq -r '.plugins[0].description' "$mp" | grep -q '/sw:init' && echo yes || echo no)"
  assert_eq "marketplace.json: description drops sw:update" 'no' \
    "$(jq -r '.plugins[0].description' "$mp" | grep -q 'sw:update' && echo yes || echo no)"
else
  assert_eq "marketplace.json: valid JSON" '0' \
    "$(python3 -c "import json; json.load(open('$mp'))" >/dev/null 2>&1; echo $?)"
fi

# --- plugin.json is valid and lists the current companion set (AC-3, AC-4) -
pj="$ROOT/plugins/sw/.claude-plugin/plugin.json"
assert_eq "plugin.json exists" 'yes' "$([ -f "$pj" ] && echo yes || echo no)"
if command -v jq >/dev/null 2>&1; then
  assert_eq "plugin.json: valid JSON" '0' "$(jq empty "$pj" >/dev/null 2>&1; echo $?)"
  assert_eq "plugin.json: description mentions init" 'yes' \
    "$(jq -r '.description' "$pj" | grep -q 'init' && echo yes || echo no)"
  assert_eq "plugin.json: description drops update" 'no' \
    "$(jq -r '.description' "$pj" | grep -qw 'update' && echo yes || echo no)"
else
  assert_eq "plugin.json: valid JSON" '0' \
    "$(python3 -c "import json; json.load(open('$pj'))" >/dev/null 2>&1; echo $?)"
fi

# --- /sw:init exists and is the per-repo setup skill (AC-2) -----------------
init_skill="$ROOT/plugins/sw/skills/init/SKILL.md"
assert_eq "init skill exists" 'yes' "$([ -f "$init_skill" ] && echo yes || echo no)"
assert_eq "init skill: frontmatter name is init" 'yes' \
  "$(grep -q '^name: init$' "$init_skill" && echo yes || echo no)"

# --- sw:update is fully retired (AC-4) ---------------------------------------
assert_eq "update skill directory absent" 'no' \
  "$([ -d "$ROOT/plugins/sw/skills/update" ] && echo yes || echo no)"
assert_eq "sw-update.sh absent" 'no' \
  "$([ -f "$ROOT/plugins/sw/scripts/sw-update.sh" ] && echo yes || echo no)"

# --- no dangling install.sh reference in live docs (AC-5) -------------------
# .specwright/ holds historical issue records that legitimately discuss the
# deletion or predate it, and this test script legitimately names the file it
# checks for absence; only live docs outside both must be clean.
live_hits=$(grep -rl "install\.sh" "$ROOT" \
  --exclude-dir=.specwright --exclude-dir=.git --exclude-dir=node_modules 2>/dev/null \
  | grep -v "tests/install/run\.sh$" || true)
assert_eq "no live doc references install.sh" '' "$live_hits"

if [ "$fails" -eq 0 ]; then echo "ALL PASS"; exit 0; else echo "$fails FAILED"; exit 1; fi
