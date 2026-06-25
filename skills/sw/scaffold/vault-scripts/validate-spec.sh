#!/usr/bin/env bash
# validate-spec.sh — mechanical structural check for a memex spec folder.
#
# Usage: validate-spec.sh <spec-folder>
#
# Exits 0 when every check passes; otherwise exits with the number of failed
# checks and prints one "FAIL (check N): <reason>" line per failure. It is a
# feedforward gate for /memex:review-spec — a structurally invalid spec should
# fail noisily here before any prose review (Rule of Repair).
#
# Checks:
#   1. spec.md frontmatter has status/feature/created/scope; scope is one of
#      low|medium|high|complex.
#   2. no surviving {{placeholder}} in spec.md / design.md / tasks.md.
#   3. no banned vague verb in an acceptance-criteria bullet.
#   4. every AC-N defined in spec.md is referenced by at least one task.
set -euo pipefail

usage() { echo "usage: validate-spec.sh <spec-folder>" >&2; exit 2; }

[ "$#" -eq 1 ] || usage
dir="${1%/}"
[ -d "$dir" ] || { echo "FAIL: not a directory: $dir" >&2; exit 2; }

spec="$dir/spec.md"
design="$dir/design.md"
tasks="$dir/tasks.md"

fails=0
fail() { echo "FAIL (check $1): $2"; fails=$((fails + 1)); }

# --- Check 1: required frontmatter keys + scope enum ----------------------
if [ ! -f "$spec" ]; then
  fail 1 "spec.md not found in $dir"
else
  fm=$(awk 'NR==1 && $0=="---"{f=1; next} f && $0=="---"{exit} f{print}' "$spec")
  for key in status feature created scope; do
    if ! printf '%s\n' "$fm" | grep -Eq "^${key}:"; then
      fail 1 "spec.md frontmatter missing required key: ${key}"
    fi
  done
  scope_val=$(printf '%s\n' "$fm" \
    | { grep -E '^scope:' || true; } \
    | head -n1 \
    | sed -E 's/^scope:[[:space:]]*//; s/[[:space:]]*$//')
  case "$scope_val" in
    low|medium|high|complex|"") : ;;
    *) fail 1 "spec.md scope must be one of low|medium|high|complex (got: '${scope_val}')" ;;
  esac
fi

# --- Check 2: no surviving {{placeholder}} --------------------------------
for f in "$spec" "$design" "$tasks"; do
  [ -f "$f" ] || continue
  hit=$({ grep -nF '{{' "$f" || true; } | head -n1)
  if [ -n "$hit" ]; then
    fail 2 "surviving {{placeholder}} in $(basename "$f"): ${hit}"
  fi
done

# --- Check 3: no banned vague verb in an acceptance-criteria bullet -------
if [ -f "$spec" ]; then
  ac=$(awk '
    /^## Acceptance Criteria[[:space:]]*$/ {cap=1; next}
    cap && /^## / {cap=0}
    cap {print}
  ' "$spec")
  ac_bullets=$(printf '%s\n' "$ac" | { grep -E '^[[:space:]]*- \[[ xX]\]' || true; })
  vague=$(printf '%s\n' "$ac_bullets" | { grep -Ewin 'works|robust|simple|gracefully' || true; } | head -n1)
  if [ -n "$vague" ]; then
    fail 3 "vague verb in acceptance criterion: ${vague}"
  fi
  fast_no_num=$(printf '%s\n' "$ac_bullets" \
    | { grep -Ewi 'fast' || true; } \
    | { grep -Ev '[0-9]' || true; } \
    | head -n1)
  if [ -n "$fast_no_num" ]; then
    fail 3 "vague 'fast' without a number in acceptance criterion: ${fast_no_num}"
  fi
fi

# --- Check 4: every AC-N in spec.md is referenced by a task ---------------
if [ -f "$spec" ] && [ -f "$tasks" ]; then
  ac_ids=$({ grep -Eoh 'AC-[0-9]+' "$spec" || true; } | sort -u)
  missing=""
  while IFS= read -r id; do
    [ -n "$id" ] || continue
    if ! grep -qw "$id" "$tasks"; then
      missing="${missing:+$missing, }$id"
    fi
  done <<EOF
$ac_ids
EOF
  if [ -n "$missing" ]; then
    fail 4 "AC defined in spec.md but referenced by no task: ${missing}"
  fi
fi

# --- Verdict (computed in the parent shell from captured data) ------------
if [ "$fails" -eq 0 ]; then
  echo "PASS: $dir"
  exit 0
fi
echo "FAILED: $fails check(s) in $dir" >&2
exit "$fails"
