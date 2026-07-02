#!/usr/bin/env bash
# validate-spec.sh — mechanical structural check for a specwright issue folder.
#
# Usage: validate-spec.sh <issue-folder>
#
# Exits 0 when every check passes; otherwise exits with the number of failed
# checks and prints one "FAIL (check N): <reason>" line per failure. It is a
# feedforward gate for /sw:review-spec — a structurally invalid issue should
# fail noisily here before any prose review (Rule of Repair).
#
# Checks:
#   1. issue.md frontmatter has feature/created/status; status is one of
#      pending|in-progress|shipped|blocked.
#   2. spec.md frontmatter has feature/created/scope; scope is one of
#      low|medium|high|complex.
#   3. no surviving {{placeholder}} in issue.md / spec.md / tasks.md /
#      learnings.md.
#   4. no banned vague verb in an acceptance-criteria bullet of issue.md.
#   5. every AC-N defined in issue.md is referenced by at least one task.
set -euo pipefail

usage() { echo "usage: validate-spec.sh <issue-folder>" >&2; exit 2; }

[ "$#" -eq 1 ] || usage
dir="${1%/}"
[ -d "$dir" ] || { echo "FAIL: not a directory: $dir" >&2; exit 2; }

issue="$dir/issue.md"
spec="$dir/spec.md"
tasks="$dir/tasks.md"
learnings="$dir/learnings.md"

fails=0
fail() { echo "FAIL (check $1): $2"; fails=$((fails + 1)); }

frontmatter() { awk 'NR==1 && $0=="---"{f=1; next} f && $0=="---"{exit} f{print}' "$1"; }

# --- Check 1: issue.md frontmatter keys + status enum ----------------------
if [ ! -f "$issue" ]; then
  fail 1 "issue.md not found in $dir"
else
  fm=$(frontmatter "$issue")
  for key in feature created status; do
    if ! printf '%s\n' "$fm" | grep -Eq "^${key}:"; then
      fail 1 "issue.md frontmatter missing required key: ${key}"
    fi
  done
  status_val=$(printf '%s\n' "$fm" \
    | { grep -E '^status:' || true; } \
    | head -n1 \
    | sed -E 's/^status:[[:space:]]*//; s/[[:space:]]*$//')
  case "$status_val" in
    pending|in-progress|shipped|blocked|"") : ;;
    *) fail 1 "issue.md status must be one of pending|in-progress|shipped|blocked (got: '${status_val}')" ;;
  esac
fi

# --- Check 2: spec.md frontmatter keys + scope enum ------------------------
if [ ! -f "$spec" ]; then
  fail 2 "spec.md not found in $dir"
else
  fm=$(frontmatter "$spec")
  for key in feature created scope; do
    if ! printf '%s\n' "$fm" | grep -Eq "^${key}:"; then
      fail 2 "spec.md frontmatter missing required key: ${key}"
    fi
  done
  scope_val=$(printf '%s\n' "$fm" \
    | { grep -E '^scope:' || true; } \
    | head -n1 \
    | sed -E 's/^scope:[[:space:]]*//; s/[[:space:]]*$//')
  case "$scope_val" in
    low|medium|high|complex|"") : ;;
    *) fail 2 "spec.md scope must be one of low|medium|high|complex (got: '${scope_val}')" ;;
  esac
fi

# --- Check 3: no surviving {{placeholder}} --------------------------------
for f in "$issue" "$spec" "$tasks" "$learnings"; do
  [ -f "$f" ] || continue
  hit=$({ grep -nF '{{' "$f" || true; } | head -n1)
  if [ -n "$hit" ]; then
    fail 3 "surviving {{placeholder}} in $(basename "$f"): ${hit}"
  fi
done

# --- Check 4: no banned vague verb in an acceptance-criteria bullet -------
if [ -f "$issue" ]; then
  ac=$(awk '
    /^## Acceptance Criteria[[:space:]]*$/ {cap=1; next}
    cap && /^## / {cap=0}
    cap {print}
  ' "$issue")
  ac_bullets=$(printf '%s\n' "$ac" | { grep -E '^[[:space:]]*- \[[ xX]\]' || true; })
  vague=$(printf '%s\n' "$ac_bullets" | { grep -Ewin 'works|robust|simple|gracefully' || true; } | head -n1)
  if [ -n "$vague" ]; then
    fail 4 "vague verb in acceptance criterion: ${vague}"
  fi
  fast_no_num=$(printf '%s\n' "$ac_bullets" \
    | { grep -Ewi 'fast' || true; } \
    | { grep -Ev '[0-9]' || true; } \
    | head -n1)
  if [ -n "$fast_no_num" ]; then
    fail 4 "vague 'fast' without a number in acceptance criterion: ${fast_no_num}"
  fi
fi

# --- Check 5: every AC-N in issue.md is referenced by a task ---------------
if [ -f "$issue" ] && [ -f "$tasks" ]; then
  ac_ids=$({ grep -Eoh 'AC-[0-9]+' "$issue" || true; } | sort -u)
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
    fail 5 "AC defined in issue.md but referenced by no task: ${missing}"
  fi
fi

# --- Verdict (computed in the parent shell from captured data) ------------
if [ "$fails" -eq 0 ]; then
  echo "PASS: $dir"
  exit 0
fi
echo "FAILED: $fails check(s) in $dir" >&2
exit "$fails"
