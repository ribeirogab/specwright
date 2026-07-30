#!/usr/bin/env bash
# Durable checks for plugins/sw/scripts/validate-spec.sh (checks 1-5). Fixtures
# live beside the script; ephemeral cases are built under a temporary root so
# this suite never reads or changes host state.
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
VALIDATOR="$ROOT/plugins/sw/scripts/validate-spec.sh"
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
  local label="$1" dir="$2"
  if "$VALIDATOR" "$dir" >/dev/null 2>&1; then
    pass "$label"
  else
    die "$label — expected exit 0"
  fi
}
expect_fail_with() {
  local label="$1" dir="$2" fragment="$3"
  local output status=0
  ensure_temporary_root
  output="$temporary_root/case.out"
  "$VALIDATOR" "$dir" >"$output" 2>&1 || status=$?
  if [ "$status" -ne 0 ] && grep -qF "$fragment" "$output"; then
    pass "$label"
  else
    die "$label — expected non-zero exit containing [$fragment] (exit=$status)"
  fi
}

expect_pass "validator accepts the good fixture" "$FIXTURES/good"
expect_fail_with "validator requires change.md frontmatter keys" "$FIXTURES/missing-status" \
  "change.md frontmatter missing required key: status"
expect_fail_with "validator enforces the status enum" "$FIXTURES/bad-frontmatter" \
  "change.md status must be one of pending|in-progress|shipped|blocked"
expect_fail_with "validator rejects surviving placeholders" "$FIXTURES/bad-placeholder" \
  "surviving {{placeholder}}"
expect_fail_with "validator rejects vague-verb criteria" "$FIXTURES/bad-vague-verb" \
  "vague verb in acceptance criterion"
expect_fail_with "validator requires AC task coverage" "$FIXTURES/bad-unref-ac" \
  "AC defined in change.md but referenced by no task: AC-3"

ensure_temporary_root
missing_change="$temporary_root/missing-change"
mkdir -p "$missing_change"
cp "$FIXTURES/good/spec.md" "$FIXTURES/good/tasks.md" "$missing_change/"
expect_fail_with "validator fails when change.md is missing" "$missing_change" \
  "change.md not found"

bad_scope="$temporary_root/bad-scope"
mkdir -p "$bad_scope"
cp "$FIXTURES/good/change.md" "$FIXTURES/good/spec.md" "$FIXTURES/good/tasks.md" "$bad_scope/"
sed 's/^scope: low$/scope: enormous/' "$bad_scope/spec.md" >"$bad_scope/spec.md.tmp"
mv "$bad_scope/spec.md.tmp" "$bad_scope/spec.md"
expect_fail_with "validator enforces the scope enum" "$bad_scope" \
  "spec.md scope must be one of low|medium|high|complex"

if [ "$fails" -eq 0 ]; then
  echo "ALL PASS"
  exit 0
fi
echo "$fails FAILED"
exit 1
