#!/usr/bin/env bash
# validate-change.sh — handoff-readiness gate for a specwright change folder.
#
# One question: can an agent with no memory of the conversation implement this
# from the change folder alone? Every check below is a way that handoff breaks.
#
# Usage: validate-change.sh <change-folder>
#
# Exit codes:
#   0     every check passed (prints "PASS: <dir>").
#   1-7   the number of DISTINCT checks that failed (prints one
#         "FAIL (check N): <reason>" line per failing condition — a single
#         check may emit several lines but counts once).
#   2     ALSO used for operational errors (bad invocation, path not a
#         directory). Those print "usage:" or "FAIL: not a directory" to stderr
#         and carry no "(check N)", so they are distinguishable by message.
#         Callers treat any non-zero exit as "not ready".
#
# Checks (fixed set — never counted more than once each):
#   1. proposal.md frontmatter has feature/created/status; status is one of
#      pending|in-progress|shipped|blocked. status: is load-bearing, so an empty
#      or missing value fails.
#   2. tasks.md frontmatter has feature/created/scope/branch; scope is one of
#      low|medium|high|complex, or empty. branch: is what tells a fresh session
#      where to work, so it must be present and non-empty.
#   3. no surviving {{placeholder}} in proposal.md or tasks.md.
#   4. no banned vague verb in an acceptance-criteria bullet of proposal.md.
#   5. AC traceability both ways: every AC-N in proposal.md is named by a task,
#      and no task names an AC-N that proposal.md does not define.
#   6. every task block declares **AC:**, **Files:** with at least one path, and
#      a non-empty **Validation:** command.
#   7. scope: implies the design document — any value other than low requires a
#      sibling design.md, which is what makes the field load-bearing rather than
#      recorded-only.
set -euo pipefail

usage() { echo "usage: validate-change.sh <change-folder>" >&2; exit 2; }

[ "$#" -eq 1 ] || usage
dir="${1%/}"
[ -d "$dir" ] || { echo "FAIL: not a directory: $dir" >&2; exit 2; }

proposal="$dir/proposal.md"
tasks="$dir/tasks.md"
design="$dir/design.md"

# fail() prints every diagnostic line (Rule of Transparency) but counts each
# check at most once, so the exit code is the number of distinct failed checks
# — not the number of FAIL lines.
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
frontmatter_value() {
  printf '%s\n' "$1" \
    | { grep -E "^$2:" || true; } \
    | head -n1 \
    | sed -E "s/^$2:[[:space:]]*//; s/[[:space:]]*$//"
}

# --- Check 1: proposal.md frontmatter keys + status enum --------------------
if [ ! -f "$proposal" ]; then
  fail 1 "proposal.md not found in $dir"
else
  fm=$(frontmatter "$proposal")
  status_present=1
  for key in feature created status; do
    if ! printf '%s\n' "$fm" | grep -Eq "^${key}:"; then
      fail 1 "proposal.md frontmatter missing required key: ${key}"
      [ "$key" = status ] && status_present=0
    fi
  done
  # Only run the enum test when the key is present; a missing key already
  # reported the same root defect, so it is not double-counted.
  if [ "$status_present" -eq 1 ]; then
    status_val=$(frontmatter_value "$fm" status)
    case "$status_val" in
      pending|in-progress|shipped|blocked) : ;;
      *) fail 1 "proposal.md status must be one of pending|in-progress|shipped|blocked (got: '${status_val}')" ;;
    esac
  fi
fi

# --- Check 2: tasks.md frontmatter keys + scope enum + branch --------------
if [ ! -f "$tasks" ]; then
  fail 2 "tasks.md not found in $dir"
else
  fm=$(frontmatter "$tasks")
  for key in feature created scope branch; do
    if ! printf '%s\n' "$fm" | grep -Eq "^${key}:"; then
      fail 2 "tasks.md frontmatter missing required key: ${key}"
    fi
  done
  scope_val=$(frontmatter_value "$fm" scope)
  case "$scope_val" in
    low|medium|high|complex|"") : ;;
    *) fail 2 "tasks.md scope must be one of low|medium|high|complex (got: '${scope_val}')" ;;
  esac
  # A fresh session reads branch: to know where to work; blank defeats handoff.
  if printf '%s\n' "$fm" | grep -Eq '^branch:'; then
    [ -n "$(frontmatter_value "$fm" branch)" ] \
      || fail 2 "tasks.md branch must name the change's branch"
  fi
fi

# --- Check 3: no surviving {{placeholder}} --------------------------------
for f in "$proposal" "$tasks"; do
  [ -f "$f" ] || continue
  hit=$({ grep -nF '{{' "$f" || true; } | head -n1)
  if [ -n "$hit" ]; then
    fail 3 "surviving {{placeholder}} in $(basename "$f"): ${hit}"
  fi
done

# --- Check 4: no banned vague verb in an acceptance-criteria bullet -------
if [ -f "$proposal" ]; then
  ac=$(awk '
    /^## Acceptance Criteria[[:space:]]*$/ {cap=1; next}
    cap && /^## / {cap=0}
    cap {print}
  ' "$proposal")
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

# --- Check 5: AC traceability, both directions ----------------------------
if [ -f "$proposal" ] && [ -f "$tasks" ]; then
  ac_ids=$(awk '
    /^## Acceptance Criteria[[:space:]]*$/ {cap=1; next}
    cap && /^## / {cap=0}
    cap && /^[[:space:]]*- \[[ xX]\][[:space:]]+\*\*AC-[0-9]+\*\*/ {print}
  ' "$proposal" | { grep -Eoh 'AC-[0-9]+' || true; } | sort -u)
  task_ac_ids=$({ grep -E '^\*\*AC:\*\*' "$tasks" || true; } \
    | { grep -Eoh 'AC-[0-9]+' || true; } \
    | sort -u)

  uncovered=""
  while IFS= read -r id; do
    [ -n "$id" ] || continue
    printf '%s\n' "$task_ac_ids" | grep -qxF "$id" \
      || uncovered="${uncovered:+$uncovered, }$id"
  done <<EOF
$ac_ids
EOF
  [ -z "$uncovered" ] \
    || fail 5 "AC defined in proposal.md but referenced by no task: ${uncovered}"

  undefined=""
  while IFS= read -r id; do
    [ -n "$id" ] || continue
    printf '%s\n' "$ac_ids" | grep -qxF "$id" \
      || undefined="${undefined:+$undefined, }$id"
  done <<EOF
$task_ac_ids
EOF
  [ -z "$undefined" ] \
    || fail 5 "task references an AC that proposal.md does not define: ${undefined}"
fi

# --- Check 6: every task declares AC, Files with a path, and Validation ----
if [ -f "$tasks" ]; then
  task_defects=$(awk '
    function flush() {
      if (id == "") return
      if (!ac) print id ": missing **AC:**"
      if (!files) print id ": **Files:** lists no path"
      if (!validation) print id ": missing or empty **Validation:**"
    }
    /^### T[0-9]+:/ {
      flush()
      id = $2
      sub(/:$/, "", id)
      ac = files = validation = in_files = 0
      next
    }
    id == "" { next }
    /^\*\*AC:\*\*[[:space:]]*AC-[0-9]+/ { ac = 1; in_files = 0; next }
    /^\*\*Files:\*\*/ { in_files = 1; next }
    /^\*\*Validation:\*\*[[:space:]]*[^[:space:]]/ { validation = 1; in_files = 0; next }
    /^\*\*/ { in_files = 0; next }
    in_files && /^-[[:space:]]+[^[:space:]]/ { files = 1; next }
    END { flush() }
  ' "$tasks")
  if [ -n "$task_defects" ]; then
    while IFS= read -r defect; do
      [ -n "$defect" ] || continue
      fail 6 "$defect"
    done <<EOF
$task_defects
EOF
  fi
  if ! grep -Eq '^### T[0-9]+:' "$tasks"; then
    fail 6 "tasks.md defines no task (expected at least one '### Tn:' heading)"
  fi
fi

# --- Check 7: scope implies the design document ---------------------------
# scope: is the switch that decides whether this change needs an architecture
# document. Only `low` may go without one; every other value promises a
# design.md the implementer can read, so a missing file is a broken promise.
if [ -f "$tasks" ]; then
  scope_val=$(frontmatter_value "$(frontmatter "$tasks")" scope)
  case "$scope_val" in
    low|"") : ;;
    medium|high|complex)
      [ -f "$design" ] \
        || fail 7 "tasks.md declares scope: ${scope_val}, which requires a sibling design.md" ;;
    *) : ;;
  esac
fi

# --- Verdict --------------------------------------------------------------
if [ "$fails" -eq 0 ]; then
  echo "PASS: $dir"
  exit 0
fi
echo "FAILED: $fails check(s) in $dir" >&2
exit "$fails"
