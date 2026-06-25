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
# shellcheck source=/dev/null
SW_INSTALL_LIB=1 . "$ROOT/install.sh"
set +eu

# --- marketplace_source (AC-1, AC-2) ----------------------------------------
(
  d="$(mktemp -d)"; cd "$d" || exit 1
  assert_eq "source: github default" '{"source":"github","repo":"ribeirogab/specward"}' "$(marketplace_source)"
  mkdir -p .claude-plugin
  printf '{ "name": "specward", "owner": "ribeirogab" }\n' > .claude-plugin/marketplace.json
  assert_eq "source: dogfood directory" '{"source":"directory","path":"."}' "$(marketplace_source)"
  cd /; rm -rf "$d"
)

# --- merge engine + jq/python parity + snippet (AC-3 base, AC-6) -------------
(
  d="$(mktemp -d)"; cd "$d" || exit 1
  src='{"source":"github","repo":"ribeirogab/specward"}'

  printf '{}' > a.json
  merge_with_jq a.json "$src"
  assert_eq "jq: plugin enabled" 'true' "$(jq -c '.enabledPlugins["sw@specward"]' a.json)"
  assert_eq "jq: marketplace source" "$src" "$(jq -c '.extraKnownMarketplaces.specward.source' a.json)"

  printf '{}' > b.json
  merge_with_python b.json "$src"
  assert_eq "jq vs python parity" "$(jq -S . a.json)" "$(jq -S . b.json)"

  assert_eq "snippet mentions plugin" 'yes' \
    "$(plugin_snippet "$src" | grep -q 'sw@specward' && echo yes || echo no)"
  cd /; rm -rf "$d"
)

# --- both engines preserve a malformed pre-existing settings.json -----------
(
  d="$(mktemp -d)"; cd "$d" || exit 1
  src='{"source":"github","repo":"ribeirogab/specward"}'
  printf 'not json{' > sj.json
  merge_with_jq sj.json "$src" 2>/dev/null; rcj=$?
  assert_eq "jq malformed: returns non-zero" '1' "$rcj"
  assert_eq "jq malformed: preserved" 'not json{' "$(cat sj.json)"
  printf 'not json{' > sp.json
  merge_with_python sp.json "$src" 2>/dev/null; rcp=$?
  assert_eq "python malformed: returns non-zero" '1' "$rcp"
  assert_eq "python malformed: preserved" 'not json{' "$(cat sp.json)"
  cd /; rm -rf "$d"
)

# --- configure_plugin: writes keys, preserves existing, idempotent ----------
(
  d="$(mktemp -d)"; cd "$d" || exit 1
  mkdir -p .claude; printf '{"theme":"dark"}' > .claude/settings.json
  configure_plugin >/dev/null
  assert_eq "configure: enabled"   'true'   "$(jq -c '.enabledPlugins["sw@specward"]' .claude/settings.json)"
  assert_eq "configure: preserves" '"dark"' "$(jq -c '.theme' .claude/settings.json)"
  one="$(cat .claude/settings.json)"
  configure_plugin >/dev/null
  assert_eq "configure: idempotent" "$one" "$(cat .claude/settings.json)"
  cd /; rm -rf "$d"
)

# --- configure_plugin soft-fail: engine none → no settings, snippet printed --
(
  d="$(mktemp -d)"; cd "$d" || exit 1
  # shellcheck disable=SC2329  # invoked indirectly by configure_plugin
  plugin_merge_engine() { printf 'none'; }   # override stays inside this subshell
  out="$(configure_plugin)"; rc=$?
  assert_eq "softfail: rc 0" '0' "$rc"
  assert_eq "softfail: no settings" 'no' "$([ -f .claude/settings.json ] && echo yes || echo no)"
  assert_eq "softfail: snippet has marketplace" 'yes' \
    "$(printf '%s' "$out" | grep -q 'extraKnownMarketplaces' && echo yes || echo no)"
  assert_eq "softfail: snippet has plugin" 'yes' \
    "$(printf '%s' "$out" | grep -q 'sw@specward' && echo yes || echo no)"
  cd /; rm -rf "$d"
)

# --- remove_legacy_commands (AC-8) ------------------------------------------
(
  d="$(mktemp -d)"; cd "$d" || exit 1
  mkdir -p .claude/commands; : > .claude/commands/sw-spec.md
  remove_legacy_commands
  assert_eq "legacy removed" 'no' "$([ -e .claude/commands/sw-spec.md ] && echo yes || echo no)"
  cd /; rm -rf "$d"
)

# --- print_next_steps (AC-9) ------------------------------------------------
out="$(print_next_steps)"
assert_eq "next-steps mentions /sw" 'yes' "$(printf '%s' "$out" | grep -q '/sw' && echo yes || echo no)"
assert_eq "next-steps mentions trust" 'yes' \
  "$(printf '%s' "$out" | grep -Eqi 'trust|reopen' && echo yes || echo no)"

if [ "$fails" -eq 0 ]; then echo "ALL PASS"; exit 0; else echo "$fails FAILED"; exit 1; fi
