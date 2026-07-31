#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SKILLS=(change delivery implement init plan pr review ship)

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

pass() {
  printf 'PASS: %s\n' "$1"
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

assert_codex_discovery_json() {
  local output="$1"

  python3 - "$output" "${SKILLS[@]}" <<'PY'
import json
import pathlib
import re
import sys

messages = json.loads(pathlib.Path(sys.argv[1]).read_text(encoding="utf-8"))
expected = sorted(sys.argv[2:])
texts = []
for message in messages:
    for item in message.get("content", []):
        if item.get("type") == "input_text":
            texts.append(item.get("text", ""))
discovered = sorted(
    set(
        re.findall(
            r"(?m)^- sw:([a-z0-9-]+):",
            "\n".join(texts),
        )
    )
)
if discovered != expected:
    raise SystemExit(
        f"Codex native skill discovery mismatch: expected {expected}, got {discovered}"
    )
PY
}

assert_codex_profile_models() {
  local output="$1"

  python3 - "$output" "$ROOT/plugins/sw/templates/codex-agents" <<'PY'
import json
import pathlib
import sys
import tomllib

catalog = json.loads(pathlib.Path(sys.argv[1]).read_text(encoding="utf-8"))
available = {entry["slug"] for entry in catalog.get("models", [])}
profiles = [
    tomllib.loads(path.read_text(encoding="utf-8"))
    for path in pathlib.Path(sys.argv[2]).glob("sw-*.toml")
]
missing = sorted({profile["model"] for profile in profiles} - available)
if missing:
    raise SystemExit(f"Codex profiles select unavailable models: {missing}")
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
  local temporary_home plugin_json available_json discovery_json model_catalog_json

  temporary_home="$(mktemp -d "${TMPDIR:-/tmp}/specwright-codex.XXXXXX")"
  plugin_json="$temporary_home/plugin-add.json"
  available_json="$temporary_home/plugin-list.json"
  discovery_json="$temporary_home/prompt-input.json"
  model_catalog_json="$temporary_home/model-catalog.json"
  mkdir -p "$temporary_home/home"
  (
    CODEX_HOME="$temporary_home/home" codex plugin marketplace add "$ROOT"
    CODEX_HOME="$temporary_home/home" codex plugin add sw@specwright --json >"$plugin_json"
    CODEX_HOME="$temporary_home/home" codex plugin list --marketplace specwright --available --json >"$available_json"
    CODEX_HOME="$temporary_home/home" codex debug prompt-input "\$sw:init" >"$discovery_json"
    CODEX_HOME="$temporary_home/home" codex debug models >"$model_catalog_json"
    assert_plugin_json "$plugin_json"
    assert_available_json "$available_json"
    assert_codex_discovery_json "$discovery_json"
    assert_codex_profile_models "$model_catalog_json"
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
  local fixture_root temporary_home plugin_json discovery_json

  fixture_root="$(mktemp -d "${TMPDIR:-/tmp}/specwright-codex-skill.XXXXXX")"
  temporary_home="$(mktemp -d "${TMPDIR:-/tmp}/specwright-codex-home.XXXXXX")"
  plugin_json="$temporary_home/plugin-add.json"
  discovery_json="$temporary_home/prompt-input.json"
  cp -R "$ROOT/." "$fixture_root"
  rm "$fixture_root/plugins/sw/skills/review/SKILL.md"
  if (
    CODEX_HOME="$temporary_home" codex plugin marketplace add "$fixture_root"
    CODEX_HOME="$temporary_home" codex plugin add sw@specwright --json >"$plugin_json"
    assert_plugin_json "$plugin_json"
    CODEX_HOME="$temporary_home" codex debug prompt-input "\$sw:init" >"$discovery_json"
    assert_codex_discovery_json "$discovery_json"
  ); then
    rm -rf "$fixture_root" "$temporary_home"
    fail "Codex rejects a package without a required skill"
  fi
  rm -rf "$fixture_root" "$temporary_home"
  pass "Codex rejects a package without a required skill"
}

run_codex_malformed_skill() {
  local fixture_root temporary_home plugin_json discovery_json

  fixture_root="$(mktemp -d "${TMPDIR:-/tmp}/specwright-codex-malformed-skill.XXXXXX")"
  temporary_home="$(mktemp -d "${TMPDIR:-/tmp}/specwright-codex-home.XXXXXX")"
  plugin_json="$temporary_home/plugin-add.json"
  discovery_json="$temporary_home/prompt-input.json"
  cp -R "$ROOT/." "$fixture_root"
  printf '%s\n' '# missing frontmatter' >"$fixture_root/plugins/sw/skills/review/SKILL.md"
  if (
    CODEX_HOME="$temporary_home" codex plugin marketplace add "$fixture_root"
    CODEX_HOME="$temporary_home" codex plugin add sw@specwright --json >"$plugin_json"
    assert_plugin_json "$plugin_json"
    CODEX_HOME="$temporary_home" codex debug prompt-input "\$sw:init" >"$discovery_json"
    assert_codex_discovery_json "$discovery_json"
  ); then
    rm -rf "$fixture_root" "$temporary_home"
    fail "Codex rejects a malformed required skill"
  fi
  rm -rf "$fixture_root" "$temporary_home"
  pass "Codex rejects a malformed required skill"
}

assert_source_inventory
pass "static eight-skill inventory"
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
run_codex_malformed_skill
