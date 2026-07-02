#!/usr/bin/env bash
# validate-spec.sh — mechanical structural check for a specwright issue folder.
#
# Usage: validate-spec.sh <issue-folder>
#
# Exit codes:
#   0     every check passed (prints "PASS: <dir>").
#   1-5   the number of DISTINCT checks that failed (prints one
#         "FAIL (check N): <reason>" line per failing condition — a single
#         check may emit several lines but counts once). This is a feedforward
#         gate for /sw:review-spec — a structurally invalid issue fails noisily
#         here before any prose review (Rule of Repair).
#   2     ALSO used for operational errors (bad invocation, path not a
#         directory). These print a "usage:" or "FAIL: not a directory" line to
#         stderr and carry no "(check N)" — so an exit 2 from a usage error is
#         distinguishable from "two checks failed" by the message, not the code.
#         Callers should treat any non-zero exit as "not clean" (all in-repo
#         callers loop until exit 0), which sidesteps the overlap entirely.
#
# Checks (fixed set — never counted more than once each):
#   1. issue.md frontmatter has feature/created/status; status is one of
#      pending|in-progress|shipped|blocked. status: is load-bearing (the
#      pipeline and audit read it), so an empty or missing value FAILS by
#      deliberate choice — unlike scope: (check 2), which is recorded-only and
#      is allowed to be blank. A missing status: key fails check 1 exactly once
#      (the enum test is skipped when the key is absent).
#   2. spec.md frontmatter has feature/created/scope; scope is one of
#      low|medium|high|complex, or empty (recorded-only; blank is tolerated).
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

# fail() prints every diagnostic line (Rule of Transparency) but counts each
# check at most once, so the exit code is the number of distinct failed checks
# — not the number of FAIL lines. failed_checks tracks which have already fired.
fails=0
failed_checks=" "
fail() {
  echo "FAIL (check $1): $2"
  case "$failed_checks" in
    *" $1 "*) : ;;
    *) failed_checks="${failed_checks}$1 "; fails=$((fails + 1)) ;;
  esac
}

frontmatter() { awk 'NR==1 && $0=="---"{f=1; next} f && $0=="---"{exit} f{print}' "$1"; }

# --- Check 1: issue.md frontmatter keys + status enum ----------------------
if [ ! -f "$issue" ]; then
  fail 1 "issue.md not found in $dir"
else
  fm=$(frontmatter "$issue")
  status_present=1
  for key in feature created status; do
    if ! printf '%s\n' "$fm" | grep -Eq "^${key}:"; then
      fail 1 "issue.md frontmatter missing required key: ${key}"
      [ "$key" = status ] && status_present=0
    fi
  done
  # status: is load-bearing (the pipeline/audit read it) — an empty or invalid
  # value is a real defect and must fail, unlike recorded-only scope: (check 2)
  # which is allowed to be blank. Only run the enum check when the key is
  # present; a missing key already reported the same root defect above, so we do
  # not double-count it against check 1.
  if [ "$status_present" -eq 1 ]; then
    status_val=$(printf '%s\n' "$fm" \
      | { grep -E '^status:' || true; } \
      | head -n1 \
      | sed -E 's/^status:[[:space:]]*//; s/[[:space:]]*$//')
    case "$status_val" in
      pending|in-progress|shipped|blocked) : ;;
      *) fail 1 "issue.md status must be one of pending|in-progress|shipped|blocked (got: '${status_val}')" ;;
    esac
  fi
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
