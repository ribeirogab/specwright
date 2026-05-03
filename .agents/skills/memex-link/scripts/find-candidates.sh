#!/usr/bin/env bash
# find-candidates.sh — Detect missing related: cross-links in the memex vault.
# Output: JSON array on stdout (or "[]" if no candidates).
# Errors/warnings on stderr. Exit codes: 0 success, 2 fatal.
# Usage: find-candidates.sh [scope]
#   scope (optional): path, folder name, or empty (whole vault).
# Requires: bash >= 3.2, jq, find, awk, grep, sort, comm, tr.
set -euo pipefail

SCOPE="${1:-}"

if [ ! -d vault ]; then
  echo "FATAL: vault/ not found. Run from a directory containing vault/." >&2
  exit 2
fi

STOPWORDS_RE='^(the|a|an|of|in|on|by|and|or|for|to|with|is|this|that|repo|skill|skills|vault|agent|agents|context|note|notes|learning|learnings|spec|specs|how|what|why|when|where|works|use|using|over)$'

all_notes() {
  find vault/learnings vault/conventions vault/rules vault/specs \
    -type f -name '*.md' 2>/dev/null \
    | grep -v '^vault/specs/_template/' \
    | grep -Ev '/plan-[^/]+\.md$' \
    | grep -Ev '/tasks-[^/]+\.md$' \
    | sort
}

notes_in_scope() {
  if [ -z "$SCOPE" ]; then all_notes; return; fi
  if [ -f "$SCOPE" ]; then echo "$SCOPE"
  elif [ -d "$SCOPE" ]; then all_notes | grep "^${SCOPE%/}/"
  else all_notes | awk -v p="$SCOPE" 'index($0, p)' || true
  fi
}

extract_body() {
  awk 'BEGIN{n=0} /^---$/{n++; next} n>=2{print}' "$1"
}

extract_title() {
  extract_body "$1" | awk '/^# /{sub(/^# /,""); print; exit}'
}

extract_h2s() {
  extract_body "$1" | awk '/^## /{sub(/^## /,""); print}'
}

# extract_related_basenames — frontmatter related[] slugs, one per line.
extract_related_basenames() {
  awk '
    BEGIN{n=0; in_rel=0}
    /^---$/{n++; if(n>=2)exit; next}
    n==1 && /^related:/{in_rel=1; next}
    n==1 && in_rel && /^[a-zA-Z][a-zA-Z_-]*:/{in_rel=0}
    n==1 && in_rel && /^[[:space:]]*-[[:space:]]/{
      sub(/^[[:space:]]*-[[:space:]]*/, "")
      sub(/^"?\[\[/, "")
      sub(/\]\]"?[[:space:]]*$/, "")
      i = index($0, "|")
      if (i) $0 = substr($0, 1, i-1)
      n2 = match($0, /\/[^\/]+$/)
      if (n2) $0 = substr($0, n2+1)
      print
    }
  ' "$1"
}

tokenize() {
  tr '[:upper:]' '[:lower:]' \
    | tr -cs '[:alnum:]' '\n' \
    | awk 'length($0) >= 3' \
    | { grep -Ev "$STOPWORDS_RE" || true; } \
    | sort -u
}

is_plan_tasks_intra_pair() {
  local src="$1" tgt="$2"
  local src_dir tgt_dir tgt_base
  src_dir=$(dirname "$src")
  tgt_dir=$(dirname "$tgt")
  tgt_base=$(basename "$tgt")
  if [ "$src_dir" = "$tgt_dir" ]; then
    case "$tgt_base" in
      plan-*|tasks-*) return 0 ;;
    esac
  fi
  return 1
}

emit_json() {
  jq -nc \
    --arg source "$1" --arg target "$2" \
    --arg source_title "$3" --arg target_title "$4" \
    --arg evidence_type "$5" --arg evidence_detail "$6" \
    '{source: $source, target: $target, source_title: $source_title, target_title: $target_title, evidence_type: $evidence_type, evidence_detail: $evidence_detail}'
}

emitted=$(mktemp)
trap 'rm -f "$emitted"' EXIT

sources=$(notes_in_scope)
targets=$(all_notes)

while IFS= read -r src; do
  [ -z "$src" ] && continue
  src_basename=$(basename "$src" .md)
  src_title=$(extract_title "$src"); [ -z "$src_title" ] && src_title="$src_basename"
  src_body=$(extract_body "$src")
  src_related=$(extract_related_basenames "$src")
  src_title_tokens=$(printf '%s\n' "$src_title" | tokenize)
  src_h2_tokens=$(extract_h2s "$src" | tokenize)

  while IFS= read -r tgt; do
    [ -z "$tgt" ] && continue
    [ "$src" = "$tgt" ] && continue

    tgt_basename=$(basename "$tgt" .md)

    # Filter: target already in source's related
    if printf '%s\n' "$src_related" | grep -qxF "$tgt_basename"; then
      continue
    fi

    # Filter: plan/tasks intra-pair within same spec folder
    if is_plan_tasks_intra_pair "$src" "$tgt"; then
      continue
    fi

    tgt_title=$(extract_title "$tgt"); [ -z "$tgt_title" ] && tgt_title="$tgt_basename"

    evidence=""; detail=""

    # Evidence 1: wikilink in body
    if printf '%s\n' "$src_body" | grep -qE "\[\[([^]|]*/)?$tgt_basename(\||\]\])"; then
      line=$(printf '%s\n' "$src_body" | grep -m1 -nE "\[\[([^]|]*/)?$tgt_basename(\||\]\])" | cut -d: -f1)
      evidence="wikilink_in_body"; detail="[[$tgt_basename]] cited at body line $line"

    # Evidence 2: filepath in body
    elif printf '%s\n' "$src_body" | grep -qF "$tgt"; then
      line=$(printf '%s\n' "$src_body" | grep -m1 -nF "$tgt" | cut -d: -f1)
      evidence="filepath_in_body"; detail="filepath '$tgt' at body line $line"

    # Evidence 3: title in body (only for titles >= 10 chars to reduce false positives)
    elif [ -n "$tgt_title" ] && [ "${#tgt_title}" -ge 10 ] \
         && printf '%s\n' "$src_body" | grep -qiF "$tgt_title"; then
      line=$(printf '%s\n' "$src_body" | grep -m1 -niF "$tgt_title" | cut -d: -f1)
      evidence="title_in_body"; detail="title '$tgt_title' at body line $line"

    # Evidence 4: shared title+H2 tokens >= 2
    else
      tgt_title_tokens=$(printf '%s\n' "$tgt_title" | tokenize)
      tgt_h2_tokens=$(extract_h2s "$tgt" | tokenize)
      src_combined=$(printf '%s\n%s\n' "$src_title_tokens" "$src_h2_tokens" | sort -u | grep -v '^$' || true)
      tgt_combined=$(printf '%s\n%s\n' "$tgt_title_tokens" "$tgt_h2_tokens" | sort -u | grep -v '^$' || true)
      shared=$(comm -12 <(printf '%s\n' "$src_combined") <(printf '%s\n' "$tgt_combined") | grep -v '^$' || true)
      shared_count=$(printf '%s\n' "$shared" | grep -c . || true)
      if [ "$shared_count" -ge 2 ]; then
        evidence="shared_heading_terms"
        detail="shared title/H2 terms: $(printf '%s\n' "$shared" | tr '\n' ',' | sed 's/,$//')"
      fi
    fi

    if [ -n "$evidence" ]; then
      emit_json "$src" "$tgt" "$src_title" "$tgt_title" "$evidence" "$detail" >> "$emitted"
    fi

  done <<< "$targets"
done <<< "$sources"

if [ ! -s "$emitted" ]; then
  echo "[]"
else
  jq -s '.' "$emitted"
fi
