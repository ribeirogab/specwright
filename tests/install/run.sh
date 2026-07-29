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
  for directory in issues milestones; do
    mkdir -p "$project/.specwright/$directory"
    : >"$project/.specwright/$directory/.gitkeep"
  done
}
assert_vault() {
  local label="$1" project="$2" directory
  assert_eq "$label vault directory conventions exists" yes "$([ -d "$project/.specwright/conventions" ] && echo yes || echo no)"
  assert_file "$label vault conventions README exists" "$project/.specwright/conventions/README.md"
  for directory in issues milestones; do
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

  for agent in issue-owner task-worker spec-document-reviewer reviewer; do
    assert_file "agent $agent.md exists" "$agents_dir/$agent.md"
    for key in name description model effort; do
      assert_eq "agent $agent.md frontmatter has $key" yes "$(grep -Eq "^$key:" "$agents_dir/$agent.md" 2>/dev/null && echo yes || echo no)"
    done
  done
  assert_eq "agent issue-owner model and effort" opus/xhigh "$(agent_field issue-owner model)/$(agent_field issue-owner effort)"
  assert_eq "agent task-worker model and effort" sonnet/medium "$(agent_field task-worker model)/$(agent_field task-worker effort)"
  assert_eq "agent spec-document-reviewer model and effort" opus/high "$(agent_field spec-document-reviewer model)/$(agent_field spec-document-reviewer effort)"
  assert_eq "agent reviewer model and effort" opus/xhigh "$(agent_field reviewer model)/$(agent_field reviewer effort)"
  assert_eq "agent issue-owner preloads plan" yes "$(has_skills issue-owner && grep -Eq '^[[:space:]]*-[[:space:]]*plan$' "$agents_dir/issue-owner.md" && echo yes || echo no)"
  assert_eq "agent reviewer preloads review" yes "$(has_skills reviewer && grep -Eq '^[[:space:]]*-[[:space:]]*review$' "$agents_dir/reviewer.md" && echo yes || echo no)"
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
  run_role_agents
}

assert_profiles() {
  local project="$1" name expected_name model effort sandbox template installed
  while IFS='|' read -r name expected_name model effort sandbox; do
    template="$ROOT/plugins/sw/templates/codex-agents/$name.toml"
    installed="$project/.codex/agents/$name.toml"
    assert_file "profile template $name exists" "$template"
    assert_eq "profile $name name" "$expected_name" "$(toml_value "$template" name)"
    assert_eq "profile $name model" "$model" "$(toml_value "$template" model)"
    assert_eq "profile $name reasoning effort" "$effort" "$(toml_value "$template" model_reasoning_effort)"
    assert_eq "profile $name sandbox" "$sandbox" "$(toml_value "$template" sandbox_mode)"
    assert_eq "installed profile $name matches template" 0 "$(cmp -s "$template" "$installed"; echo $?)"
  done <<'EOF'
sw-issue-owner|sw-issue-owner|gpt-5.6|high|workspace-write
sw-spec-document-reviewer|sw-spec-document-reviewer|gpt-5.6|high|read-only
sw-reviewer|sw-reviewer|gpt-5.6|high|read-only
sw-task-worker|sw-task-worker|gpt-5.6-terra|medium|workspace-write
EOF
}

run_init() {
  local shared local_project shared_plan local_plan
  temporary_root="$(mktemp -d "${TMPDIR:-/tmp}/specwright-install.XXXXXX")"
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

if [ "$#" -eq 0 ]; then
  set -- package init
fi
for group in "$@"; do
  case "$group" in
    package) run_package ;;
    init) run_init ;;
    *) die "unknown test group: $group" ;;
  esac
done

if [ "$fails" -eq 0 ]; then
  echo "ALL PASS"
  exit 0
fi
echo "$fails FAILED"
exit 1
