#!/usr/bin/env bash
# Host-native package and project initialization checks. The fixtures are
# ephemeral Git repositories so this suite never reads or changes host state.
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
UPDATE="$ROOT/plugins/sw/scripts/sw_update.py"
fails=0
temporary_root=""

pass() { printf 'PASS: %s\n' "$1"; }
die() { printf 'FAIL: %s\n' "$1"; fails=$((fails + 1)); }
assert_eq() {
  if [ "$2" = "$3" ]; then
    pass "$1"
  else
    die "$1 — expected [$2] got [$3]"
  fi
}
assert_file() { assert_eq "$1" yes "$([ -f "$2" ] && echo yes || echo no)"; }
assert_symlink() {
  assert_eq "$1 is a symlink" yes "$([ -L "$2" ] && echo yes || echo no)"
  assert_eq "$1 target" "$3" "$([ -L "$2" ] && readlink "$2" || true)"
}
json_value() {
  python3 - "$1" "$2" <<'PY'
import json
import sys

value = json.load(open(sys.argv[2], encoding="utf-8"))
for component in sys.argv[1].split("."):
    value = value[int(component)] if component.isdigit() else value[component]
print(value)
PY
}
toml_value() {
  sed -n -E "s/^$2[[:space:]]*=[[:space:]]*\"([^\"]*)\"$/\1/p" "$1" | head -n 1
}
new_project() {
  local name="$1"
  local project="$temporary_root/$name"
  mkdir -p "$project"
  cp -R "$ROOT/tests/install/fixtures/projects/$name/." "$project"
  git -C "$project" init -q
  printf '%s\n' "$project"
}
scaffold_vault() {
  local project="$1" directory
  mkdir -p "$project/.specwright/conventions"
  : >"$project/.specwright/conventions/README.md"
  for directory in changes deliveries; do
    mkdir -p "$project/.specwright/$directory"
    : >"$project/.specwright/$directory/.gitkeep"
  done
}
assert_vault() {
  local label="$1" project="$2" directory
  assert_eq "$label vault directory conventions exists" yes "$([ -d "$project/.specwright/conventions" ] && echo yes || echo no)"
  assert_file "$label vault conventions README exists" "$project/.specwright/conventions/README.md"
  for directory in changes deliveries; do
    assert_eq "$label vault directory $directory exists" yes "$([ -d "$project/.specwright/$directory" ] && echo yes || echo no)"
    assert_file "$label vault marker $directory exists" "$project/.specwright/$directory/.gitkeep"
  done
}
calendar_version() {
  python3 - "$1" <<'PY'
import datetime
import sys

parts = sys.argv[1].split(".")
try:
    year, month, day = (int(part) for part in parts)
    valid = len(parts) == 3 and all(str(value) == part for value, part in zip((year, month, day), parts))
    datetime.date(year, month, day)
except ValueError:
    valid = False
print("yes" if valid else "no")
PY
}
ensure_temporary_root() {
  if [ -z "$temporary_root" ]; then
    temporary_root="$(mktemp -d "${TMPDIR:-/tmp}/specwright-install.XXXXXX")"
  fi
}
tree_digest() {
  python3 - "$1" <<'PY'
from pathlib import Path
import hashlib
import os
import sys

root = Path(sys.argv[1])
digest = hashlib.sha256()
for path in sorted(root.rglob("*"), key=lambda item: item.relative_to(root).as_posix()):
    relative = path.relative_to(root).as_posix().encode()
    digest.update(relative + b"\0")
    if path.is_symlink():
        digest.update(b"symlink\0" + os.readlink(path).encode())
    elif path.is_file():
        digest.update(b"file\0" + path.read_bytes())
    elif path.is_dir():
        digest.update(b"directory\0")
print(digest.hexdigest())
PY
}
json_length() {
  python3 - "$1" "$2" <<'PY'
import json
import sys

value = json.load(open(sys.argv[2], encoding="utf-8"))
for component in sys.argv[1].split("."):
    value = value[int(component)] if component.isdigit() else value[component]
print(len(value))
PY
}
run_plan() {
  local project="$1" mode="$2" output="$3"
  python3 "$UPDATE" --plan --project "$project" --mode "$mode" --format json >"$output"
}
apply_plan() {
  local project="$1" mode="$2" plan="$3"
  python3 "$UPDATE" --apply --project "$project" --mode "$mode" --expect-plan "$(json_value plan_id "$plan")" --format json >/dev/null
}
trap '[ -z "$temporary_root" ] || rm -rf "$temporary_root"' EXIT

assert_json_file() {
  local label="$1" file="$2"
  assert_file "$label exists" "$file"
  assert_eq "$label is valid JSON" 0 "$(python3 -c 'import json, sys; json.load(open(sys.argv[1], encoding="utf-8"))' "$file" >/dev/null 2>&1; echo $?)"
}

run_role_agents() {
  local agents_dir="$ROOT/plugins/sw/agents" agent key
  agent_field() { grep -E "^$2:" "$agents_dir/$1.md" 2>/dev/null | head -n 1 | sed -E "s/^$2:[[:space:]]*//; s/[[:space:]]*$//"; }
  has_skills() { grep -Eq '^skills:' "$agents_dir/$1.md"; }

  for agent in change-owner task-worker spec-document-reviewer reviewer; do
    assert_file "agent $agent.md exists" "$agents_dir/$agent.md"
    for key in name description model effort; do
      assert_eq "agent $agent.md frontmatter has $key" yes "$(grep -Eq "^$key:" "$agents_dir/$agent.md" 2>/dev/null && echo yes || echo no)"
    done
  done
  assert_eq "agent change-owner model and effort" opus/xhigh "$(agent_field change-owner model)/$(agent_field change-owner effort)"
  assert_eq "agent task-worker model and effort" sonnet/medium "$(agent_field task-worker model)/$(agent_field task-worker effort)"
  assert_eq "agent spec-document-reviewer model and effort" opus/high "$(agent_field spec-document-reviewer model)/$(agent_field spec-document-reviewer effort)"
  assert_eq "agent reviewer model and effort" opus/xhigh "$(agent_field reviewer model)/$(agent_field reviewer effort)"
  assert_eq "agent change-owner preloads plan" yes "$(has_skills change-owner && grep -Eq '^[[:space:]]*-[[:space:]]*plan$' "$agents_dir/change-owner.md" && echo yes || echo no)"
  assert_eq "agent reviewer preloads review" yes "$(has_skills reviewer && grep -Eq '^[[:space:]]*-[[:space:]]*review$' "$agents_dir/reviewer.md" && echo yes || echo no)"
  assert_eq "run dispatches stable sw-change-owner role" yes "$(grep -Fq "Dispatch the \`sw-change-owner\` subagent" "$ROOT/plugins/sw/skills/run/SKILL.md" && echo yes || echo no)"
  assert_eq "review dispatches stable sw-reviewer role" yes "$(grep -Fq "\`sw-reviewer\` subagent" "$ROOT/plugins/sw/skills/review/SKILL.md" && echo yes || echo no)"
  assert_eq "agent task-worker has no skills key" no "$(has_skills task-worker && echo yes || echo no)"
  assert_eq "agent spec-document-reviewer has no skills key" no "$(has_skills spec-document-reviewer && echo yes || echo no)"
  assert_eq "legacy spec-document reviewer prompt is removed" no "$([ -f "$ROOT/plugins/sw/skills/plan/spec-document-reviewer-prompt.md" ] && echo yes || echo no)"
}

run_package() {
  local claude_marketplace="$ROOT/.claude-plugin/marketplace.json"
  local codex_marketplace="$ROOT/.agents/plugins/marketplace.json"
  local claude_manifest="$ROOT/plugins/sw/.claude-plugin/plugin.json"
  local codex_manifest="$ROOT/plugins/sw/.codex-plugin/plugin.json"
  local skill
  local -a skills=(brainstorm init plan pr review review-spec run spec update)

  assert_eq "install.sh absent at repo root" no "$([ -f "$ROOT/install.sh" ] && echo yes || echo no)"

  assert_json_file "Claude marketplace" "$claude_marketplace"
  assert_eq "Claude marketplace plugin source" ./plugins/sw "$(json_value plugins.0.source "$claude_marketplace")"
  assert_eq "Claude marketplace plugin name" sw "$(json_value plugins.0.name "$claude_marketplace")"
  assert_json_file "Codex marketplace" "$codex_marketplace"
  assert_eq "Codex marketplace plugin source" ./plugins/sw "$(json_value plugins.0.source.path "$codex_marketplace")"
  assert_eq "Codex marketplace plugin name" sw "$(json_value plugins.0.name "$codex_marketplace")"
  assert_eq "Codex marketplace source type" local "$(json_value plugins.0.source.source "$codex_marketplace")"
  assert_eq "Codex marketplace installation policy" AVAILABLE "$(json_value plugins.0.policy.installation "$codex_marketplace")"
  assert_eq "Codex marketplace authentication policy" ON_INSTALL "$(json_value plugins.0.policy.authentication "$codex_marketplace")"
  assert_eq "Codex marketplace category" Productivity "$(json_value plugins.0.category "$codex_marketplace")"

  assert_json_file "Claude manifest" "$claude_manifest"
  assert_json_file "Codex manifest" "$codex_manifest"
  assert_eq "manifests share plugin name" "$(json_value name "$claude_manifest")" "$(json_value name "$codex_manifest")"
  assert_eq "manifests share calendar version" "$(json_value version "$claude_manifest")" "$(json_value version "$codex_manifest")"
  assert_eq "manifest version is an unpadded real calendar date" yes "$(calendar_version "$(json_value version "$codex_manifest")")"
  assert_eq "Codex manifest skills path" ./skills/ "$(json_value skills "$codex_manifest")"
  assert_eq "Codex manifest category" Productivity "$(json_value interface.category "$codex_manifest")"

  assert_eq "canonical skill inventory has nine entries" 9 "${#skills[@]}"
  for skill in "${skills[@]}"; do
    assert_file "skill $skill exists" "$ROOT/plugins/sw/skills/$skill/SKILL.md"
    assert_file "Claude redirect $skill exists" "$ROOT/plugins/sw/commands/$skill.md"
    assert_eq "Claude redirect $skill points to its skill" yes "$(grep -Fq "skills/$skill/SKILL.md" "$ROOT/plugins/sw/commands/$skill.md" && echo yes || echo no)"
  done
  assert_eq "skill directory inventory is canonical" "$(printf '%s\n' "${skills[@]}")" "$(find "$ROOT/plugins/sw/skills" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort)"
  assert_eq "Claude redirect inventory is canonical" "$(printf '%s\n' "${skills[@]}" | sed 's/$/.md/' | sort)" "$(find "$ROOT/plugins/sw/commands" -maxdepth 1 -type f -name '*.md' -exec basename {} \; | sort)"
  for skill in brainstorm plan review-spec; do
    assert_eq "$skill resolves bundled resources from SW_PLUGIN_ROOT" yes "$(grep -q 'SW_PLUGIN_ROOT' "$ROOT/plugins/sw/skills/$skill/SKILL.md" && echo yes || echo no)"
    assert_eq "$skill has no consumer-relative bundled path" no "$(grep -Eq 'plugins/sw/(templates|scripts)/' "$ROOT/plugins/sw/skills/$skill/SKILL.md" && echo yes || echo no)"
  done
  run_role_agents
}

assert_profiles() {
  local project="$1" name expected_name model effort sandbox template installed required_fragment
  while IFS='|' read -r name expected_name model effort sandbox; do
    template="$ROOT/plugins/sw/templates/codex-agents/$name.toml"
    installed="$project/.codex/agents/$name.toml"
    assert_file "profile template $name exists" "$template"
    assert_eq "profile $name name" "$expected_name" "$(toml_value "$template" name)"
    assert_eq "profile $name model" "$model" "$(toml_value "$template" model)"
    assert_eq "profile $name reasoning effort" "$effort" "$(toml_value "$template" model_reasoning_effort)"
    assert_eq "profile $name sandbox" "$sandbox" "$(toml_value "$template" sandbox_mode)"
    assert_eq "installed profile $name matches template" 0 "$(cmp -s "$template" "$installed"; echo $?)"
    case "$name" in
      sw-change-owner) required_fragment='sole editor and integrator' ;;
      sw-spec-document-reviewer) required_fragment='schema-2 decomposition and ownership' ;;
      sw-reviewer) required_fragment="\$sw:review workflow" ;;
      sw-task-worker) required_fragment='original base SHA' ;;
    esac
    assert_eq "profile $name carries its authority protocol" yes "$(grep -Fq "$required_fragment" "$template" && echo yes || echo no)"
  done <<'EOF'
sw-change-owner|sw-change-owner|gpt-5.6-sol|high|workspace-write
sw-spec-document-reviewer|sw-spec-document-reviewer|gpt-5.6-sol|high|read-only
sw-reviewer|sw-reviewer|gpt-5.6-sol|high|read-only
sw-task-worker|sw-task-worker|gpt-5.6-terra|medium|workspace-write
EOF
}

run_init() {
  local shared local_project shared_plan local_plan
  ensure_temporary_root
  shared="$(new_project shared)"
  assert_file "shared fixture marker is copied" "$shared/.gitkeep"
  scaffold_vault "$shared"
  shared_plan="$temporary_root/shared-plan.json"
  run_plan "$shared" shared "$shared_plan"
  assert_eq "shared init plan is new" new "$(json_value state "$shared_plan")"
  apply_plan "$shared" shared "$shared_plan"
  assert_file "shared canonical AGENTS.md exists" "$shared/AGENTS.md"
  assert_symlink "shared Claude adapter" "$shared/CLAUDE.md" AGENTS.md
  git -C "$shared" add AGENTS.md
  assert_eq "shared AGENTS.md is trackable" 0 "$(git -C "$shared" ls-files --error-unmatch AGENTS.md >/dev/null 2>&1; echo $?)"
  assert_vault shared "$shared"
  git -C "$shared" add .specwright
  assert_eq "shared vault conventions README is trackable" 0 "$(git -C "$shared" ls-files --error-unmatch .specwright/conventions/README.md >/dev/null 2>&1; echo $?)"
  assert_profiles "$shared"
  assert_eq "shared ignore rules are exact" '.specwright/worktrees/' "$(cat "$shared/.gitignore")"
  assert_eq "shared mode does not ignore profiles" 1 "$(git -C "$shared" check-ignore -q -- .codex/agents/sw-task-worker.toml; echo $?)"

  local_project="$(new_project local)"
  assert_file "local fixture marker is copied" "$local_project/.gitkeep"
  mkdir -p "$local_project/.codex"
  scaffold_vault "$local_project"
  printf 'project-owned\n' >"$local_project/.codex/project.toml"
  local_plan="$temporary_root/local-plan.json"
  run_plan "$local_project" local "$local_plan"
  assert_eq "local init plan is new" new "$(json_value state "$local_plan")"
  apply_plan "$local_project" local "$local_plan"
  assert_file "local canonical AGENTS.override.md exists" "$local_project/AGENTS.override.md"
  assert_symlink "local Claude adapter" "$local_project/CLAUDE.local.md" AGENTS.override.md
  assert_vault local "$local_project"
  assert_profiles "$local_project"
  assert_eq "local ignore rules are exact and ordered" $'.specwright/worktrees/\n.specwright/\nAGENTS.override.md\nCLAUDE.local.md\n.codex/agents/sw-*.toml' "$(cat "$local_project/.gitignore")"
  assert_eq "local vault conventions README is ignored" 0 "$(git -C "$local_project" check-ignore -q -- .specwright/conventions/README.md; echo $?)"
  assert_eq "local profile is ignored" 0 "$(git -C "$local_project" check-ignore -q -- .codex/agents/sw-task-worker.toml; echo $?)"
  assert_eq "unrelated .codex/project.toml is preserved" project-owned "$(tr -d '\n' <"$local_project/.codex/project.toml")"
  assert_eq "unrelated .codex/project.toml remains unignored" 1 "$(git -C "$local_project" check-ignore -q -- .codex/project.toml; echo $?)"
}

new_update_project() {
  local name="$1" fixture="$2"
  local project
  ensure_temporary_root
  project="$temporary_root/update-$name"
  mkdir -p "$project"
  cp -R "$ROOT/tests/install/fixtures/update/$fixture/." "$project"
  case "$fixture" in
    up-to-date)
      ln -s AGENTS.md "$project/CLAUDE.md"
      mkdir -p "$project/.codex/agents"
      cp "$ROOT"/plugins/sw/templates/codex-agents/sw-*.toml "$project/.codex/agents/"
      printf '.specwright/worktrees/\n' >"$project/.gitignore"
      ;;
    unrecognized-shared)
      printf '# Project Claude instructions\n\nUnrecognized pre-managed content.\n' >"$project/CLAUDE.md"
      ;;
    unrecognized-local)
      printf '# Project Claude instructions\n\nUnrecognized pre-managed content.\n' >"$project/CLAUDE.local.md"
      ;;
  esac
  git -C "$project" init -q
  printf '%s\n' "$project"
}
assert_plan_pure() {
  local label="$1" project="$2" mode="$3"
  local first="$temporary_root/$label-first.json"
  local second="$temporary_root/$label-second.json"
  local before after
  before="$(tree_digest "$project")"
  run_plan "$project" "$mode" "$first"
  run_plan "$project" "$mode" "$second"
  after="$(tree_digest "$project")"
  assert_eq "$label plan JSON is stable" 0 "$(cmp -s "$first" "$second"; echo $?)"
  assert_eq "$label plan is read-only" "$before" "$after"
}
expect_apply_failure() {
  local label="$1" project="$2" mode="$3" plan="$4" diagnostic="$5"
  local before after status=0
  local standard_output="$temporary_root/$label.out"
  local standard_error="$temporary_root/$label.err"
  before="$(tree_digest "$project")"
  python3 "$UPDATE" \
    --apply \
    --project "$project" \
    --mode "$mode" \
    --expect-plan "$(json_value plan_id "$plan")" \
    --format json >"$standard_output" 2>"$standard_error" || status=$?
  after="$(tree_digest "$project")"
  assert_eq "$label exits non-zero" yes "$([ "$status" -ne 0 ] && echo yes || echo no)"
  assert_eq "$label diagnostic" yes "$(grep -Fq "$diagnostic" "$standard_error" && echo yes || echo no)"
  assert_eq "$label writes nothing" "$before" "$after"
}
run_update() {
  local new_project_path current_project unrecognized_shared unrecognized_local drifted
  local plan new_plan current_plan unrecognized_shared_plan unrecognized_local_plan drifted_plan
  local identity_project identity_plan profile_drift profile_drift_plan ignore_negation ignore_negation_plan unsupported
  local unsupported_plan unsupported_before unsupported_after unsupported_status=0
  local managed_update managed_plan post_plan second_post_plan initial_plan_id

  ensure_temporary_root

  new_project_path="$(new_update_project new new)"
  new_plan="$temporary_root/new-plan.json"
  run_plan "$new_project_path" shared "$new_plan"
  assert_eq "new fixture state" new "$(json_value state "$new_plan")"
  assert_eq "new fixture operation count" 7 "$(json_length operations "$new_plan")"
  assert_eq "new fixture first operation" AGENTS.md "$(json_value operations.0.relative_path "$new_plan")"
  assert_eq "new fixture second operation" CLAUDE.md "$(json_value operations.1.relative_path "$new_plan")"
  assert_eq "new fixture final operation" .gitignore "$(json_value operations.6.relative_path "$new_plan")"
  assert_plan_pure new "$new_project_path" shared

  current_project="$(new_update_project current up-to-date)"
  current_plan="$temporary_root/current-plan.json"
  run_plan "$current_project" shared "$current_plan"
  assert_eq "up-to-date fixture state" up-to-date "$(json_value state "$current_plan")"
  assert_eq "up-to-date fixture has zero operations" 0 "$(json_length operations "$current_plan")"
  assert_plan_pure current "$current_project" shared

  unrecognized_shared="$(new_update_project unrecognized-shared unrecognized-shared)"
  unrecognized_shared_plan="$temporary_root/unrecognized-shared-plan.json"
  run_plan "$unrecognized_shared" shared "$unrecognized_shared_plan"
  assert_eq "unrecognized shared fixture state" drifted "$(json_value state "$unrecognized_shared_plan")"
  assert_eq "unrecognized shared fixture has zero operations" 0 "$(json_length operations "$unrecognized_shared_plan")"
  assert_plan_pure unrecognized-shared "$unrecognized_shared" shared
  expect_apply_failure unrecognized-shared-apply "$unrecognized_shared" shared "$unrecognized_shared_plan" "refusing to apply drifted project"

  unrecognized_local="$(new_update_project unrecognized-local unrecognized-local)"
  unrecognized_local_plan="$temporary_root/unrecognized-local-plan.json"
  run_plan "$unrecognized_local" local "$unrecognized_local_plan"
  assert_eq "unrecognized local fixture state" drifted "$(json_value state "$unrecognized_local_plan")"
  assert_eq "unrecognized local fixture has zero operations" 0 "$(json_length operations "$unrecognized_local_plan")"
  assert_plan_pure unrecognized-local "$unrecognized_local" local
  expect_apply_failure unrecognized-local-apply "$unrecognized_local" local "$unrecognized_local_plan" "refusing to apply drifted project"

  drifted="$(new_update_project drifted drifted)"
  drifted_plan="$temporary_root/drifted-plan.json"
  run_plan "$drifted" shared "$drifted_plan"
  assert_eq "drifted fixture state" drifted "$(json_value state "$drifted_plan")"
  assert_eq "drifted fixture has zero operations" 0 "$(json_length operations "$drifted_plan")"
  assert_eq "drifted fixture has diagnostics" yes "$([ "$(json_length diagnostics "$drifted_plan")" -gt 0 ] && echo yes || echo no)"
  assert_plan_pure drifted "$drifted" shared
  expect_apply_failure drifted-apply "$drifted" shared "$drifted_plan" "refusing to apply drifted project"

  identity_project="$(new_update_project identity new)"
  identity_plan="$temporary_root/identity-plan.json"
  run_plan "$identity_project" shared "$identity_plan"
  printf 'changed-after-confirmation\n' >"$identity_project/.gitignore"
  expect_apply_failure identity-mismatch "$identity_project" shared "$identity_plan" "identity does not match"

  profile_drift="$(new_update_project profile-drift up-to-date)"
  printf 'edited profile\n' >"$profile_drift/.codex/agents/sw-reviewer.toml"
  profile_drift_plan="$temporary_root/profile-drift-plan.json"
  run_plan "$profile_drift" shared "$profile_drift_plan"
  assert_eq "profile drift fixture state" drifted "$(json_value state "$profile_drift_plan")"
  expect_apply_failure profile-drift "$profile_drift" shared "$profile_drift_plan" "refusing to apply drifted project"

  ignore_negation="$(new_update_project ignore-negation new)"
  ignore_negation_plan="$temporary_root/ignore-negation-initial-plan.json"
  run_plan "$ignore_negation" local "$ignore_negation_plan"
  apply_plan "$ignore_negation" local "$ignore_negation_plan"
  printf '!.codex/agents/sw-reviewer.toml\n' >>"$ignore_negation/.gitignore"
  ignore_negation_plan="$temporary_root/ignore-negation-drift-plan.json"
  run_plan "$ignore_negation" local "$ignore_negation_plan"
  assert_eq "ignore negation fixture state" drifted "$(json_value state "$ignore_negation_plan")"
  assert_eq "ignore negation makes managed profile trackable" 1 "$(git -C "$ignore_negation" check-ignore -q -- .codex/agents/sw-reviewer.toml; echo $?)"

  unsupported="$(new_update_project symlink-unsupported symlink-unsupported)"
  unsupported_plan="$temporary_root/symlink-unsupported-plan.json"
  run_plan "$unsupported" shared "$unsupported_plan"
  unsupported_before="$(tree_digest "$unsupported")"
  python3 - \
    "$ROOT/plugins/sw/scripts" \
    "$unsupported" \
    "$(json_value plan_id "$unsupported_plan")" \
    >"$temporary_root/symlink-unsupported.out" \
    2>"$temporary_root/symlink-unsupported.err" <<'PY' || unsupported_status=$?
from pathlib import Path
import sys
from unittest import mock

sys.path.insert(0, sys.argv[1])
import sw_update

try:
    with mock.patch.object(sw_update.os, "symlink", side_effect=OSError("symlinks disabled")):
        sw_update.apply_update(Path(sys.argv[2]), "shared", sys.argv[3])
except sw_update.UpdateError as error:
    print(error, file=sys.stderr)
    raise SystemExit(1)
raise SystemExit("unsupported symlink apply unexpectedly succeeded")
PY
  unsupported_after="$(tree_digest "$unsupported")"
  assert_eq "unsupported symlink exits non-zero" yes "$([ "$unsupported_status" -ne 0 ] && echo yes || echo no)"
  assert_eq "unsupported symlink diagnostic" yes "$(grep -Fq 'no regular-file fallback' "$temporary_root/symlink-unsupported.err" && echo yes || echo no)"
  assert_eq "unsupported symlink writes nothing" "$unsupported_before" "$unsupported_after"

  managed_update="$(new_update_project managed-update up-to-date)"
  if python3 - "$ROOT/plugins/sw/scripts" "$managed_update" >"$temporary_root/managed-update.out" 2>&1 <<'PY'
from pathlib import Path
import sys
from unittest import mock

sys.path.insert(0, sys.argv[1])
import sw_update

project = Path(sys.argv[2])
installed = sw_update.load_installed_version()
agents = project / "AGENTS.md"
agents.write_bytes(
    b"# Project-owned prefix\n\n"
    + sw_update.render_managed_block("2026.7.27").encode()
    + b"\nProject-owned suffix without final newline"
)
digests = {
    name: sw_update._digest_bytes((project / ".codex" / "agents" / name).read_bytes())
    for name in sw_update.PROFILE_NAMES
}
with mock.patch.dict(
    sw_update.KNOWN_PROFILE_DIGESTS_BY_VERSION,
    {"2026.7.27": digests},
    clear=True,
):
    plan = sw_update.plan_update(project, "shared")
    assert plan.state == "legacy-migratable", plan.state
    initial_plan_id = plan.plan_id
    sw_update.apply_update(project, "shared", initial_plan_id)
contents = agents.read_bytes()
assert contents.startswith(b"# Project-owned prefix\n\n")
assert contents.endswith(b"\nProject-owned suffix without final newline")
assert sw_update.render_managed_block(installed).encode() in contents
post = sw_update.plan_update(project, "shared")
second_post = sw_update.plan_update(project, "shared")
assert post.state == "up-to-date", post.state
assert post.operations == (), post.operations
assert post.plan_id == second_post.plan_id
assert post.plan_id != initial_plan_id
PY
  then
    pass "managed update migrates a known-version project byte-exactly"
  else
    die "managed update migrates a known-version project byte-exactly — $(cat "$temporary_root/managed-update.out")"
  fi
}
run_worktree() {
  if python3 "$ROOT/tests/worktrees/test_local_copy.py"; then
    pass "local dual-host worktree copy"
  else
    die "local dual-host worktree copy"
  fi
}
run_topology() {
  local fixture output status expected preplan
  ensure_temporary_root
  if python3 "$ROOT/tests/task-topology/test_parser.py"; then
    pass "schema-2 parser and topology unit tests"
  else
    die "schema-2 parser and topology unit tests"
  fi

  for fixture in good legacy-shipped; do
    if "$ROOT/plugins/sw/scripts/validate-spec.sh" \
      "$ROOT/plugins/sw/scripts/fixtures/$fixture" >/dev/null 2>&1; then
      pass "validator accepts $fixture topology fixture"
    else
      die "validator accepts $fixture topology fixture"
    fi
  done

  for fixture in bad-task-dependency bad-task-cycle bad-task-collision legacy-active; do
    case "$fixture" in
      bad-task-dependency) expected="depends on missing task" ;;
      bad-task-cycle) expected="dependency cycle" ;;
      bad-task-collision) expected="same-wave ownership collision" ;;
      legacy-active) expected="requires explicit schema-2 replanning" ;;
    esac
    output="$temporary_root/$fixture.out"
    status=0
    "$ROOT/plugins/sw/scripts/validate-spec.sh" \
      "$ROOT/plugins/sw/scripts/fixtures/$fixture" >"$output" 2>&1 || status=$?
    if [ "$status" -ne 0 ] && grep -qF "$expected" "$output"; then
      pass "validator rejects $fixture topology fixture"
    else
      die "validator rejects $fixture topology fixture"
    fi
  done

  preplan="$temporary_root/preplan"
  mkdir -p "$preplan"
  cp "$ROOT/plugins/sw/scripts/fixtures/good/change.md" "$preplan/change.md"
  output="$temporary_root/preplan.out"
  status=0
  "$ROOT/plugins/sw/scripts/validate-spec.sh" "$preplan" >"$output" 2>&1 || status=$?
  if [ "$status" -eq 1 ] \
    && grep -qF "FAIL (check 2): spec.md not found" "$output" \
    && ! grep -qF "FAIL (check 6)" "$output"; then
    pass "validator preserves the pre-plan single-check baseline"
  else
    die "validator preserves the pre-plan single-check baseline"
  fi
}

if [ "$#" -eq 0 ]; then
  set -- package init update worktree topology
fi
for group in "$@"; do
  case "$group" in
    package) run_package ;;
    init) run_init ;;
    update) run_update ;;
    worktree) run_worktree ;;
    topology) run_topology ;;
    *) die "unknown test group: $group" ;;
  esac
done

if [ "$fails" -eq 0 ]; then
  echo "ALL PASS"
  exit 0
fi
echo "$fails FAILED"
exit 1
