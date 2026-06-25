#!/usr/bin/env bash
# sw-update.sh — reconcile an installed specwright against upstream.
#
# Deterministic engine behind /sw:update. It self-fetches upstream specwright,
# classifies each managed scaffolded file against a tracked sha256 baseline
# (the manifest), auto-applies upstream changes to files the user never touched,
# and reports the rest for the agent to merge. It never merges, commits, or pushes.
#
# Modes:
#   (default) | --run     classify + auto-apply stale-clean + print report
#   --self-test           run the built-in fixtures; print "self-test: PASS"
#   --list-managed        print one managed local path per line
#   --init-manifest       record baseline = current local hash for every path
#                         (install time, where local == upstream)
#   --record <path> <clone>
#                         record baseline = upstream hash for one path
#                         (after the agent merges a conflict)
#
# Classify (per managed path), checks in order — first match wins:
#   1. L==U                 current      (incl. independent convergence L!=B)
#   2. L==B (so B!=U)       stale-clean  copy U->local, record U
#   3. B==U (so L!=B)       local-only   report only
#   4. otherwise            conflict     report for agent merge
# With no baseline (B empty) degrade to 2-way: L==U current, else conflict.
#
# Env overrides (for tests/install): SW_UPSTREAM_DIR (skip git clone, read a
# local tree), SW_MANIFEST (manifest path).
set -euo pipefail

UPSTREAM="https://github.com/ribeirogab/specwright"
MANIFEST="${SW_MANIFEST:-.agents/skills/sw/.update-manifest.json}"
SELF="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"

# --- hashing (portable: macOS shasum, else Linux sha256sum) ---
_sha_file() {
  [ -f "$1" ] || { echo ""; return 0; }
  if command -v shasum >/dev/null 2>&1; then shasum -a 256 "$1" | awk '{print $1}'
  else sha256sum "$1" | awk '{print $1}'; fi
}
_sha_str() {
  if command -v shasum >/dev/null 2>&1; then printf '%s' "$1" | shasum -a 256 | awk '{print $1}'
  else printf '%s' "$1" | sha256sum | awk '{print $1}'; fi
}

# --- the pure classifier ---
# classify_one L B U -> prints one class. B empty => 2-way degrade.
classify_one() {
  local L="$1" B="$2" U="$3"
  if [ -z "$B" ]; then [ "$L" = "$U" ] && echo current || echo conflict; return 0; fi
  if   [ "$L" = "$U" ]; then echo current
  elif [ "$L" = "$B" ]; then echo stale-clean
  elif [ "$B" = "$U" ]; then echo local-only
  else echo conflict; fi
}

# spec-flow block: lines after "### Spec flow" up to (not incl.) the next "## " header.
_spec_flow_block() {
  awk '/^### Spec flow[[:space:]]*$/{c=1;next} c&&/^## /{c=0} c{print}' "$1"
}

# managed_pairs <clone_root> -> <local_path>\t<kind>\t<upstream_source>
managed_pairs() {
  local clone="$1" s
  for s in brainstorming writing-plans new-pr code-review update; do
    printf '.agents/skills/sw-%s/SKILL.md\tfile\t%s/skills/sw/scaffold/skills/sw-%s/SKILL.md\n' "$s" "$clone" "$s"
  done
  printf 'AGENTS.md#spec-flow\tagentsblock\t%s/skills/sw/references/agents-md-template.md\n' "$clone"
}

# --- hashes per managed entry (kind file => whole file; agentsblock => the block) ---
_local_hash() {
  local path="$1" kind="$2"
  if [ "$kind" = agentsblock ]; then
    [ -f AGENTS.md ] && _sha_str "$(_spec_flow_block AGENTS.md)" || echo ""
  else _sha_file "$path"; fi
}
_upstream_hash() {
  local src="$1" kind="$2"
  if [ "$kind" = agentsblock ]; then
    [ -f "$src" ] && _sha_str "$(_spec_flow_block "$src")" || echo ""
  else _sha_file "$src"; fi
}
_baseline_hash() {
  [ -f "$MANIFEST" ] || { echo ""; return 0; }
  jq -r --arg k "$1" '.files[$k] // ""' "$MANIFEST" 2>/dev/null || echo ""
}

# --- manifest writers ---
# _record_one <key> <hash> : upsert one entry (create the manifest if absent).
_record_one() {
  local key="$1" hash="$2" tmp; tmp=$(mktemp)
  if [ -f "$MANIFEST" ]; then jq --arg k "$key" --arg h "$hash" '.files[$k]=$h' "$MANIFEST" > "$tmp"
  else jq -n --arg k "$key" --arg h "$hash" '{files:{($k):$h}}' > "$tmp"; fi
  mkdir -p "$(dirname "$MANIFEST")"; mv "$tmp" "$MANIFEST"
}

# Record baseline = current local hash for every managed path (install time).
_init_manifest() {
  local lpath kind _src
  while IFS=$'\t' read -r lpath kind _src; do
    _record_one "$lpath" "$(_local_hash "$lpath" "$kind")"
  done < <(managed_pairs "${SW_UPSTREAM_DIR:-.}")
}

# Record baseline = upstream hash for one path (after the agent merges a conflict).
_record_upstream() {
  local target="$1" clone="$2" lpath kind src
  [ -n "$target" ] && [ -n "$clone" ] || { echo "usage: sw-update.sh --record <path> <clone>" >&2; return 2; }
  while IFS=$'\t' read -r lpath kind src; do
    if [ "$lpath" = "$target" ]; then
      _record_one "$target" "$(_upstream_hash "$src" "$kind")"; return 0
    fi
  done < <(managed_pairs "$clone")
  echo "sw-update: not a managed path: $target" >&2; return 1
}

# Replace the spec-flow block in AGENTS.md with the upstream template's block.
_apply_agents_block() {
  local src="$1" blk tmp
  blk=$(mktemp); tmp=$(mktemp)
  _spec_flow_block "$src" > "$blk"
  awk -v blockfile="$blk" '
    /^### Spec flow[[:space:]]*$/ { print; while ((getline line < blockfile) > 0) print line; close(blockfile); skip=1; next }
    skip && /^## / { skip=0 }
    !skip { print }
  ' AGENTS.md > "$tmp" && mv "$tmp" AGENTS.md
  rm -f "$blk"
}

# --- the reconcile loop: classify each managed entry, apply stale-clean, print the report ---
reconcile() {
  local clone="$1" lpath kind src L B U cls
  while IFS=$'\t' read -r lpath kind src; do
    L=$(_local_hash "$lpath" "$kind"); U=$(_upstream_hash "$src" "$kind"); B=$(_baseline_hash "$lpath")
    cls=$(classify_one "$L" "$B" "$U")
    case "$cls" in
      stale-clean)
        if [ "$kind" = agentsblock ]; then _apply_agents_block "$src"
        else mkdir -p "$(dirname "$lpath")"; cp "$src" "$lpath"; fi
        _record_one "$lpath" "$U"
        printf 'updated\t%s\n' "$lpath" ;;
      conflict)
        printf 'conflict\t%s\n' "$lpath" ;;
      *)  # current | local-only — advance/heal the baseline to U when it differs
        [ "$B" = "$U" ] || _record_one "$lpath" "$U"
        printf '%s\t%s\n' "$cls" "$lpath" ;;
    esac
  done < <(managed_pairs "$clone")
}

# --- self-test: pure classifier matrix + an apply sandbox built with mktemp ---
_selftest_classifier() {
  local fails=0 got
  _expect() { got=$(classify_one "$2" "$3" "$4"); [ "$got" = "$1" ] || { echo "FAIL classify $5: want $1 got $got"; fails=1; }; }
  _expect current     aaa aaa aaa  "L==B==U"
  _expect stale-clean aaa aaa bbb  "L==B!=U"
  _expect local-only  bbb aaa aaa  "B==U!=L"
  _expect conflict    bbb aaa ccc  "all-differ"
  _expect current     aaa bbb aaa  "L==U!=B converged"
  _expect current     aaa ""  aaa  "no-baseline equal"
  _expect conflict    aaa ""  bbb  "no-baseline differ"
  return $fails
}

_selftest_apply() {
  local d fails=0
  d=$(mktemp -d)
  # fake upstream clone shape (only the files the assertions touch)
  mkdir -p "$d/up/skills/sw/scaffold/skills/sw-brainstorming" \
           "$d/up/skills/sw/scaffold/skills/sw-writing-plans" \
           "$d/up/skills/sw/scaffold/skills/sw-new-pr" \
           "$d/up/skills/sw/references"
  printf 'brainstorming NEW\n'  > "$d/up/skills/sw/scaffold/skills/sw-brainstorming/SKILL.md"
  printf 'writing-plans NEW\n'  > "$d/up/skills/sw/scaffold/skills/sw-writing-plans/SKILL.md"
  printf 'new-pr\n'             > "$d/up/skills/sw/scaffold/skills/sw-new-pr/SKILL.md"
  printf '# Template\n### Spec flow\nUP-FLOW\n## Next\n' > "$d/up/skills/sw/references/agents-md-template.md"
  # local install
  mkdir -p "$d/lo/.agents/skills/sw-brainstorming" \
           "$d/lo/.agents/skills/sw-writing-plans" \
           "$d/lo/.agents/skills/sw-new-pr" \
           "$d/lo/.agents/skills/sw"
  printf 'brainstorming OLD\n'  > "$d/lo/.agents/skills/sw-brainstorming/SKILL.md"   # stale-clean
  printf 'writing-plans OLD\n'  > "$d/lo/.agents/skills/sw-writing-plans/SKILL.md"   # conflict
  printf 'new-pr\n'             > "$d/lo/.agents/skills/sw-new-pr/SKILL.md"          # current
  printf '# Local intro\n### Spec flow\nOLD-FLOW\n## Next\n' > "$d/lo/AGENTS.md"  # block stale-clean
  # baseline manifest — hashed with the engine's own helpers so classes land as intended
  local base_writing h_brainstorming h_writing h_newpr h_agents
  base_writing="$d/base_writing"; printf 'writing-plans BASE\n' > "$base_writing"
  h_brainstorming=$(_sha_file "$d/lo/.agents/skills/sw-brainstorming/SKILL.md")
  h_writing=$(_sha_file "$base_writing")
  h_newpr=$(_sha_file "$d/lo/.agents/skills/sw-new-pr/SKILL.md")
  h_agents=$( cd "$d/lo" && _sha_str "$(_spec_flow_block AGENTS.md)" )
  cat > "$d/lo/.agents/skills/sw/.update-manifest.json" <<JSON
{"files":{
  ".agents/skills/sw-brainstorming/SKILL.md":"$h_brainstorming",
  ".agents/skills/sw-writing-plans/SKILL.md":"$h_writing",
  ".agents/skills/sw-new-pr/SKILL.md":"$h_newpr",
  "AGENTS.md#spec-flow":"$h_agents"
}}
JSON
  # run 1 — full 3-way
  ( cd "$d/lo" && SW_UPSTREAM_DIR="$d/up" SW_MANIFEST=".agents/skills/sw/.update-manifest.json" \
      bash "$SELF" --run ) > "$d/report.txt" 2>"$d/err.txt" \
      || { echo "FAIL apply: run crashed"; cat "$d/err.txt"; rm -rf "$d"; return 1; }
  grep -q $'^updated\t\\.agents/skills/sw-brainstorming/SKILL\\.md' "$d/report.txt" || { echo "FAIL apply: brainstorming not updated"; fails=1; }
  diff <(printf 'brainstorming NEW\n') "$d/lo/.agents/skills/sw-brainstorming/SKILL.md" >/dev/null || { echo "FAIL apply: brainstorming content"; fails=1; }
  grep -q $'^conflict\t\\.agents/skills/sw-writing-plans/SKILL\\.md' "$d/report.txt" || { echo "FAIL apply: writing-plans not conflict"; fails=1; }
  diff <(printf 'writing-plans OLD\n') "$d/lo/.agents/skills/sw-writing-plans/SKILL.md" >/dev/null || { echo "FAIL apply: writing-plans changed"; fails=1; }
  grep -q $'^current\t\\.agents/skills/sw-new-pr/SKILL\\.md' "$d/report.txt" || { echo "FAIL apply: new-pr not current"; fails=1; }
  grep -q 'UP-FLOW' "$d/lo/AGENTS.md" || { echo "FAIL apply: AGENTS block not updated"; fails=1; }
  grep -q 'Local intro' "$d/lo/AGENTS.md" || { echo "FAIL apply: AGENTS intro clobbered"; fails=1; }
  # run 2 — no manifest (2-way degrade): differing file must conflict + manifest re-created
  rm -f "$d/lo/.agents/skills/sw/.update-manifest.json"
  printf 'new-pr EDITED\n' > "$d/lo/.agents/skills/sw-new-pr/SKILL.md"
  ( cd "$d/lo" && SW_UPSTREAM_DIR="$d/up" SW_MANIFEST=".agents/skills/sw/.update-manifest.json" \
      bash "$SELF" --run ) > "$d/report2.txt" 2>>"$d/err.txt" \
      || { echo "FAIL 2way: run crashed"; cat "$d/err.txt"; rm -rf "$d"; return 1; }
  grep -q $'^conflict\t\\.agents/skills/sw-new-pr/SKILL\\.md' "$d/report2.txt" || { echo "FAIL 2way: new-pr not conflict"; fails=1; }
  test -f "$d/lo/.agents/skills/sw/.update-manifest.json" || { echo "FAIL 2way: manifest not recreated"; fails=1; }
  rm -rf "$d"
  return $fails
}

case "${1:-}" in
  --self-test)
    _selftest_classifier && _selftest_apply && { echo "self-test: PASS"; exit 0; }
    echo "self-test: FAIL"; exit 1 ;;
  --list-managed) managed_pairs "${SW_UPSTREAM_DIR:-.}" | cut -f1 ;;
  --init-manifest) _init_manifest ;;
  --record) _record_upstream "${2:-}" "${3:-}" ;;
  ""|--run)
    clone="${SW_UPSTREAM_DIR:-}"
    if [ -z "$clone" ]; then
      clone=$(mktemp -d)
      git clone --depth 1 "$UPSTREAM" "$clone" >/dev/null 2>&1 \
        || { echo "sw-update: fetch failed (need network)" >&2; exit 1; }
    fi
    printf 'clone\t%s\n' "$clone"   # surface the upstream clone; left in place for conflict merges
    reconcile "$clone" ;;
  *) echo "usage: sw-update.sh [--run|--self-test|--list-managed|--init-manifest|--record <path> <clone>]" >&2; exit 2 ;;
esac
