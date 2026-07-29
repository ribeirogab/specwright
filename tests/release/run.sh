#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SKILLS=(brainstorm init plan pr review review-spec run spec update)

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

pass() {
  printf 'PASS: %s\n' "$1"
}

assert_skill_inventory() {
  local plugin_path="$1"
  local skill
  local discovered

  [ -d "$plugin_path" ] || fail "Codex returned an installed plugin directory"
  discovered="$(find "$plugin_path/skills" -mindepth 2 -maxdepth 2 -type f -name SKILL.md | wc -l | tr -d ' ')"
  [ "$discovered" = "${#SKILLS[@]}" ] || fail "Codex installed inventory has ${#SKILLS[@]} skills"
  for skill in "${SKILLS[@]}"; do
    [ -f "$plugin_path/skills/$skill/SKILL.md" ] || fail "Codex installed skill $skill"
  done
}

installed_path_from_json() {
  local output="$1"

  python3 - "$output" <<'PY'
import json
import pathlib
import sys

result = json.loads(pathlib.Path(sys.argv[1]).read_text(encoding="utf-8"))
if result.get("pluginId") != "sw@specwright":
    raise SystemExit("plugin add did not identify sw@specwright")
path = result.get("installedPath")
if not isinstance(path, str) or not path:
    raise SystemExit("plugin add did not return installedPath")
print(path)
PY
}

assert_plugin_json() {
  local output="$1"
  local installed_path

  installed_path="$(installed_path_from_json "$output")"
  [ -f "$installed_path/.codex-plugin/plugin.json" ] || fail "Codex installed package includes its manifest"
  assert_skill_inventory "$installed_path"
}

assert_available_json() {
  local output="$1"

  python3 - "$output" <<'PY'
import json
import pathlib
import sys

result = json.loads(pathlib.Path(sys.argv[1]).read_text(encoding="utf-8"))
entries = result.get("installed", []) + result.get("available", [])
if not any(entry.get("pluginId") == "sw@specwright" for entry in entries):
    raise SystemExit("plugin list did not identify sw@specwright")
PY
}

assert_source_inventory() {
  local skill
  local discovered

  discovered="$(find "$ROOT/plugins/sw/skills" -mindepth 2 -maxdepth 2 -type f -name SKILL.md | wc -l | tr -d ' ')"
  [ "$discovered" = "${#SKILLS[@]}" ] || fail "source inventory has ${#SKILLS[@]} skills"
  for skill in "${SKILLS[@]}"; do
    [ -f "$ROOT/plugins/sw/skills/$skill/SKILL.md" ] || fail "source skill $skill"
  done
}

run_codex_positive() {
  local temporary_home plugin_json available_json

  temporary_home="$(mktemp -d "${TMPDIR:-/tmp}/specwright-codex.XXXXXX")"
  plugin_json="$temporary_home/plugin-add.json"
  available_json="$temporary_home/plugin-list.json"
  mkdir -p "$temporary_home/home"
  (
    CODEX_HOME="$temporary_home/home" codex plugin marketplace add "$ROOT"
    CODEX_HOME="$temporary_home/home" codex plugin add sw@specwright --json >"$plugin_json"
    CODEX_HOME="$temporary_home/home" codex plugin list --marketplace specwright --available --json >"$available_json"
    assert_plugin_json "$plugin_json"
    assert_available_json "$available_json"
  )
  rm -rf "$temporary_home"
  pass "Codex native marketplace ingestion"
}

run_codex_missing_manifest() {
  local fixture_root temporary_home plugin_json installed_path

  fixture_root="$(mktemp -d "${TMPDIR:-/tmp}/specwright-codex-manifest.XXXXXX")"
  temporary_home="$(mktemp -d "${TMPDIR:-/tmp}/specwright-codex-home.XXXXXX")"
  plugin_json="$temporary_home/plugin-add.json"
  cp -R "$ROOT/." "$fixture_root"
  rm "$fixture_root/plugins/sw/.codex-plugin/plugin.json"
  if (
    CODEX_HOME="$temporary_home" codex plugin marketplace add "$fixture_root"
    CODEX_HOME="$temporary_home" codex plugin add sw@specwright --json >"$plugin_json"
    installed_path="$(installed_path_from_json "$plugin_json")"
    [ -f "$installed_path/.codex-plugin/plugin.json" ]
  ); then
    rm -rf "$fixture_root" "$temporary_home"
    fail "Codex rejects a package without .codex-plugin/plugin.json"
  fi
  rm -rf "$fixture_root" "$temporary_home"
  pass "Codex rejects a package without its manifest"
}

run_codex_missing_skill() {
  local fixture_root temporary_home plugin_json

  fixture_root="$(mktemp -d "${TMPDIR:-/tmp}/specwright-codex-skill.XXXXXX")"
  temporary_home="$(mktemp -d "${TMPDIR:-/tmp}/specwright-codex-home.XXXXXX")"
  plugin_json="$temporary_home/plugin-add.json"
  cp -R "$ROOT/." "$fixture_root"
  rm "$fixture_root/plugins/sw/skills/review/SKILL.md"
  if (
    CODEX_HOME="$temporary_home" codex plugin marketplace add "$fixture_root"
    CODEX_HOME="$temporary_home" codex plugin add sw@specwright --json >"$plugin_json"
    assert_plugin_json "$plugin_json"
  ); then
    rm -rf "$fixture_root" "$temporary_home"
    fail "Codex rejects a package without a required skill"
  fi
  rm -rf "$fixture_root" "$temporary_home"
  pass "Codex rejects a package without a required skill"
}

assert_source_inventory
pass "static nine-skill inventory"
claude plugin validate --strict "$ROOT/plugins/sw"
pass "Claude strict validation"

if [ "${CI_EPHEMERAL_RUNNER:-}" != "1" ]; then
  printf 'SKIP: Codex marketplace mutations require CI_EPHEMERAL_RUNNER=1 on an ephemeral runner.\n'
  exit 0
fi

run_codex_positive

temporary_claude_fixture="$(mktemp -d "${TMPDIR:-/tmp}/specwright-claude-manifest.XXXXXX")"
cp -R "$ROOT/." "$temporary_claude_fixture"
rm "$temporary_claude_fixture/plugins/sw/.claude-plugin/plugin.json"
if claude plugin validate --strict "$temporary_claude_fixture/plugins/sw"; then
  rm -rf "$temporary_claude_fixture"
  fail "Claude rejects a package without .claude-plugin/plugin.json"
fi
rm -rf "$temporary_claude_fixture"
pass "Claude rejects a package without its manifest"

run_codex_missing_manifest
run_codex_missing_skill
