#!/usr/bin/env bash
# Durable checks for plugins/sw/scripts/validate-change.sh. The committed
# fixtures cover one defect each; ephemeral cases are built under a temporary
# root so this suite never reads or changes host state.
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
VALIDATOR="$ROOT/plugins/sw/scripts/validate-change.sh"
FIXTURES="$ROOT/plugins/sw/scripts/fixtures"
fails=0
temporary_root=""

pass() { printf 'PASS: %s\n' "$1"; }
die() { printf 'FAIL: %s\n' "$1"; fails=$((fails + 1)); }
ensure_temporary_root() {
  if [ -z "$temporary_root" ]; then
    temporary_root="$(mktemp -d "${TMPDIR:-/tmp}/specwright-validate.XXXXXX")"
  fi
}
trap '[ -z "$temporary_root" ] || rm -rf "$temporary_root"' EXIT

expect_pass() {
  local label="$1" dir="$2" output status=0
  ensure_temporary_root
  output="$temporary_root/case.out"
  "$VALIDATOR" "$dir" >"$output" 2>&1 || status=$?
  if [ "$status" -eq 0 ] && grep -q '^PASS: ' "$output"; then
    pass "$label"
  else
    die "$label — expected exit 0 and a PASS line (exit=$status)"
  fi
}
expect_fail_with() {
  local label="$1" dir="$2" fragment="$3" output status=0
  ensure_temporary_root
  output="$temporary_root/case.out"
  "$VALIDATOR" "$dir" >"$output" 2>&1 || status=$?
  if [ "$status" -ne 0 ] && grep -qF "$fragment" "$output"; then
    pass "$label"
  else
    die "$label — expected non-zero exit naming [$fragment] (exit=$status)"
  fi
}
new_case() {
  local name="$1" directory
  ensure_temporary_root
  directory="$temporary_root/$name"
  mkdir -p "$directory"
  cp "$FIXTURES/ready/change.md" "$FIXTURES/ready/plan.md" "$directory/"
  printf '%s\n' "$directory"
}

expect_pass "validator accepts the ready fixture" "$FIXTURES/ready"

expect_fail_with "validator requires change.md status" "$FIXTURES/missing-status" \
  "change.md frontmatter missing required key: status"
expect_fail_with "validator rejects surviving placeholders" "$FIXTURES/bad-placeholder" \
  "surviving {{placeholder}}"
expect_fail_with "validator rejects vague-verb criteria" "$FIXTURES/bad-vague-verb" \
  "vague verb in acceptance criterion"
expect_fail_with "validator requires AC task coverage" "$FIXTURES/bad-unref-ac" \
  "AC defined in change.md but referenced by no task: AC-3"
expect_fail_with "validator requires a task validation command" "$FIXTURES/bad-task-metadata" \
  "T2: missing or empty **Validation:**"

undefined_ac="$(new_case undefined-ac)"
sed 's/^\*\*AC:\*\* AC-2$/**AC:** AC-2, AC-9/' "$undefined_ac/plan.md" >"$undefined_ac/plan.tmp"
mv "$undefined_ac/plan.tmp" "$undefined_ac/plan.md"
expect_fail_with "validator rejects a task naming an undefined AC" "$undefined_ac" \
  "task references an AC that change.md does not define: AC-9"

missing_plan="$temporary_root/missing-plan"
mkdir -p "$missing_plan"
cp "$FIXTURES/ready/change.md" "$missing_plan/"
expect_fail_with "validator fails before the plan exists" "$missing_plan" \
  "plan.md not found"

missing_change="$temporary_root/missing-change"
mkdir -p "$missing_change"
cp "$FIXTURES/ready/plan.md" "$missing_change/"
expect_fail_with "validator fails when change.md is missing" "$missing_change" \
  "change.md not found"

no_tasks="$(new_case no-tasks)"
sed '/^## Tasks/,$d' "$FIXTURES/ready/plan.md" >"$no_tasks/plan.md"
expect_fail_with "validator rejects a plan with no task" "$no_tasks" \
  "plan.md defines no task"

blank_branch="$(new_case blank-branch)"
sed 's|^branch: feat/sample-change$|branch:|' "$blank_branch/plan.md" >"$blank_branch/plan.tmp"
mv "$blank_branch/plan.tmp" "$blank_branch/plan.md"
expect_fail_with "validator requires a named branch" "$blank_branch" \
  "plan.md branch must name the change's branch"

bad_scope="$(new_case bad-scope)"
sed 's/^scope: low$/scope: enormous/' "$bad_scope/plan.md" >"$bad_scope/plan.tmp"
mv "$bad_scope/plan.tmp" "$bad_scope/plan.md"
expect_fail_with "validator enforces the scope enum" "$bad_scope" \
  "plan.md scope must be one of low|medium|high|complex"

bad_status="$(new_case bad-status)"
sed 's/^status: pending$/status: almost/' "$bad_status/change.md" >"$bad_status/change.tmp"
mv "$bad_status/change.tmp" "$bad_status/change.md"
expect_fail_with "validator enforces the status enum" "$bad_status" \
  "change.md status must be one of pending|in-progress|shipped|blocked"

missing_files="$(new_case missing-files)"
python3 - "$missing_files/plan.md" <<'PY'
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
path.write_text(
    path.read_text().replace(
        "**Files:**\n- Modify: `src/sample/cli.py`\n- Modify: `tests/test_cli.py`\n"
        "**Validation:** `pytest tests/test_cli.py::test_version -q`",
        "**Files:**\n**Validation:** `pytest tests/test_cli.py::test_version -q`",
        1,
    )
)
PY
expect_fail_with "validator requires at least one owned path" "$missing_files" \
  "T1: **Files:** lists no path"

ensure_temporary_root
usage_output="$temporary_root/usage.out"
usage_status=0
"$VALIDATOR" >"$usage_output" 2>&1 || usage_status=$?
if [ "$usage_status" -eq 2 ] && grep -qF 'usage: validate-change.sh' "$usage_output"; then
  pass "validator reports usage on a bad invocation"
else
  die "validator reports usage on a bad invocation (exit=$usage_status)"
fi

not_a_directory="$temporary_root/not-a-directory"
: >"$not_a_directory"
expect_fail_with "validator rejects a non-directory argument" "$not_a_directory" \
  "not a directory"

if [ "$fails" -eq 0 ]; then
  echo "ALL PASS"
  exit 0
fi
echo "$fails FAILED"
exit 1
