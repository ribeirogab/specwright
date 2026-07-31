#!/usr/bin/env bash
# Package-surface and project-scaffolding checks. The fixtures are ephemeral Git
# repositories, so this suite never reads or changes host state.
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
INIT="$ROOT/plugins/sw/scripts/sw_init.py"
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
assert_yes() { assert_eq "$1" yes "$2"; }
assert_file() { assert_eq "$1" yes "$([ -f "$2" ] && echo yes || echo no)"; }
assert_absent() { assert_eq "$1" no "$([ -e "$2" ] && echo yes || echo no)"; }
assert_symlink() {
  assert_eq "$1 is a symlink" yes "$([ -L "$2" ] && echo yes || echo no)"
  assert_eq "$1 target" "$3" "$([ -L "$2" ] && readlink "$2" || true)"
}
ensure_temporary_root() {
  if [ -z "$temporary_root" ]; then
    temporary_root="$(mktemp -d "${TMPDIR:-/tmp}/specwright-install.XXXXXX")"
  fi
}
trap '[ -z "$temporary_root" ] || rm -rf "$temporary_root"' EXIT

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
assert_json_file() {
  local label="$1" file="$2"
  assert_file "$label exists" "$file"
  assert_eq "$label is valid JSON" 0 "$(python3 -c 'import json, sys; json.load(open(sys.argv[1], encoding="utf-8"))' "$file" >/dev/null 2>&1; echo $?)"
}
new_project() {
  local name="$1" project
  ensure_temporary_root
  project="$temporary_root/$name"
  mkdir -p "$project"
  cp -R "$ROOT/tests/install/fixtures/projects/${2:-$name}/." "$project" 2>/dev/null || true
  git -C "$project" init -q
  printf '%s\n' "$project"
}
run_init() {
  python3 "$INIT" --project "$1" --mode "$2" >"${3:-/dev/null}" 2>&1
}
ignore_line_count() {
  grep -cxF "$2" "$1/.gitignore" 2>/dev/null || echo 0
}

run_package() {
  local claude_marketplace="$ROOT/.claude-plugin/marketplace.json"
  local codex_marketplace="$ROOT/.agents/plugins/marketplace.json"
  local claude_manifest="$ROOT/plugins/sw/.claude-plugin/plugin.json"
  local codex_manifest="$ROOT/plugins/sw/.codex-plugin/plugin.json"
  local skill role
  local -a skills=(change delivery implement init plan pr review ship)
  local -a roles=(change-owner reviewer)

  assert_json_file "Claude marketplace" "$claude_marketplace"
  assert_eq "Claude marketplace plugin source" ./plugins/sw "$(json_value plugins.0.source "$claude_marketplace")"
  assert_eq "Claude marketplace plugin name" sw "$(json_value plugins.0.name "$claude_marketplace")"
  assert_json_file "Codex marketplace" "$codex_marketplace"
  assert_eq "Codex marketplace plugin source" ./plugins/sw "$(json_value plugins.0.source.path "$codex_marketplace")"
  assert_eq "Codex marketplace source type" local "$(json_value plugins.0.source.source "$codex_marketplace")"
  assert_eq "Codex marketplace installation policy" AVAILABLE "$(json_value plugins.0.policy.installation "$codex_marketplace")"

  assert_json_file "Claude manifest" "$claude_manifest"
  assert_json_file "Codex manifest" "$codex_manifest"
  assert_eq "manifests share plugin name" "$(json_value name "$claude_manifest")" "$(json_value name "$codex_manifest")"
  assert_eq "manifests share calendar version" "$(json_value version "$claude_manifest")" "$(json_value version "$codex_manifest")"
  assert_eq "manifest version is an unpadded real calendar date" yes "$(calendar_version "$(json_value version "$codex_manifest")")"
  assert_eq "Codex manifest skills path" ./skills/ "$(json_value skills "$codex_manifest")"

  assert_eq "canonical skill inventory has eight entries" 8 "${#skills[@]}"
  for skill in "${skills[@]}"; do
    assert_file "skill $skill exists" "$ROOT/plugins/sw/skills/$skill/SKILL.md"
    assert_file "Claude redirect $skill exists" "$ROOT/plugins/sw/commands/$skill.md"
    assert_yes "Claude redirect $skill points to its skill" \
      "$(grep -Fq "skills/$skill/SKILL.md" "$ROOT/plugins/sw/commands/$skill.md" && echo yes || echo no)"
    assert_eq "skill $skill frontmatter name matches its directory" "$skill" \
      "$(grep -E '^name:' "$ROOT/plugins/sw/skills/$skill/SKILL.md" | head -n1 | sed -E 's/^name:[[:space:]]*//')"
  done
  assert_eq "skill directory inventory is canonical" "$(printf '%s\n' "${skills[@]}")" \
    "$(find "$ROOT/plugins/sw/skills" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort)"
  assert_eq "Claude redirect inventory is canonical" "$(printf '%s\n' "${skills[@]}" | sed 's/$/.md/' | sort)" \
    "$(find "$ROOT/plugins/sw/commands" -maxdepth 1 -type f -name '*.md' -exec basename {} \; | sort)"

  # Nothing may self-dispatch: a description states when the skill is invoked.
  for skill in "${skills[@]}"; do
    assert_eq "skill $skill description does not mandate itself" no \
      "$(grep -q 'You MUST' "$ROOT/plugins/sw/skills/$skill/SKILL.md" && echo yes || echo no)"
  done

  # The ladder is only navigable if each step names the next one.
  assert_yes "init names /sw:change" "$(grep -Fq '/sw:change' "$ROOT/plugins/sw/skills/init/SKILL.md" && echo yes || echo no)"
  assert_yes "change names /sw:plan" "$(grep -Fq '/sw:plan' "$ROOT/plugins/sw/skills/change/SKILL.md" && echo yes || echo no)"
  assert_yes "plan names /sw:implement" "$(grep -Fq '/sw:implement' "$ROOT/plugins/sw/skills/plan/SKILL.md" && echo yes || echo no)"
  assert_yes "implement names /sw:pr" "$(grep -Fq '/sw:pr' "$ROOT/plugins/sw/skills/implement/SKILL.md" && echo yes || echo no)"
  assert_yes "pr names /sw:review" "$(grep -Fq '/sw:review' "$ROOT/plugins/sw/skills/pr/SKILL.md" && echo yes || echo no)"

  for skill in change plan delivery; do
    assert_yes "$skill resolves bundled resources from SW_PLUGIN_ROOT" \
      "$(grep -q 'SW_PLUGIN_ROOT' "$ROOT/plugins/sw/skills/$skill/SKILL.md" && echo yes || echo no)"
    assert_eq "$skill has no consumer-relative bundled path" no \
      "$(grep -Eq 'plugins/sw/(templates|scripts)/' "$ROOT/plugins/sw/skills/$skill/SKILL.md" && echo yes || echo no)"
  done

  assert_eq "template inventory is canonical" "$(printf 'change.md\ndelivery.md\nplan.md\n')" \
    "$(find "$ROOT/plugins/sw/templates" -maxdepth 1 -type f -name '*.md' -exec basename {} \; | sort)"
  assert_absent "retired spec template" "$ROOT/plugins/sw/templates/spec.md"
  assert_absent "retired tasks template" "$ROOT/plugins/sw/templates/tasks.md"
  assert_absent "retired board template" "$ROOT/plugins/sw/templates/board.md"
  assert_absent "retired updater" "$ROOT/plugins/sw/scripts/sw_update.py"
  assert_absent "retired spec validator" "$ROOT/plugins/sw/scripts/validate-spec.sh"
  assert_absent "retired topology validator" "$ROOT/plugins/sw/scripts/validate_task_topology.py"
  assert_absent "OpenCode agent templates" "$ROOT/plugins/sw/templates/opencode-agents"
  assert_absent "OpenCode command templates" "$ROOT/plugins/sw/templates/opencode-commands"
  assert_absent "OpenCode project directory" "$ROOT/.opencode"

  run_role_agents
}

run_role_agents() {
  local agents_dir="$ROOT/plugins/sw/agents" profiles_dir="$ROOT/plugins/sw/templates/codex-agents"
  local agent key
  agent_field() { grep -E "^$2:" "$agents_dir/$1.md" 2>/dev/null | head -n 1 | sed -E "s/^$2:[[:space:]]*//; s/[[:space:]]*$//"; }

  assert_eq "Claude role inventory is canonical" "$(printf 'change-owner.md\nreviewer.md\n')" \
    "$(find "$agents_dir" -maxdepth 1 -type f -name '*.md' -exec basename {} \; | sort)"
  assert_eq "Codex profile inventory is canonical" "$(printf 'sw-change-owner.toml\nsw-reviewer.toml\n')" \
    "$(find "$profiles_dir" -maxdepth 1 -type f -name '*.toml' -exec basename {} \; | sort)"

  for agent in change-owner reviewer; do
    for key in name description model effort; do
      assert_yes "agent $agent.md frontmatter has $key" \
        "$(grep -Eq "^$key:" "$agents_dir/$agent.md" 2>/dev/null && echo yes || echo no)"
    done
  done
  assert_eq "agent change-owner model and effort" opus/xhigh "$(agent_field change-owner model)/$(agent_field change-owner effort)"
  assert_eq "agent reviewer model and effort" opus/xhigh "$(agent_field reviewer model)/$(agent_field reviewer effort)"
  assert_yes "agent change-owner preloads ship" \
    "$(grep -Eq '^[[:space:]]*-[[:space:]]*ship$' "$agents_dir/change-owner.md" && echo yes || echo no)"
  assert_yes "agent reviewer preloads review" \
    "$(grep -Eq '^[[:space:]]*-[[:space:]]*review$' "$agents_dir/reviewer.md" && echo yes || echo no)"
  assert_yes "delivery dispatches the stable sw-change-owner role" \
    "$(grep -Fq 'sw-change-owner' "$ROOT/plugins/sw/skills/delivery/SKILL.md" && echo yes || echo no)"
  assert_yes "review dispatches the stable sw-reviewer role" \
    "$(grep -Fq 'sw-reviewer' "$ROOT/plugins/sw/skills/review/SKILL.md" && echo yes || echo no)"

  assert_eq "profile sw-change-owner model" gpt-5.6-sol "$(toml_value "$profiles_dir/sw-change-owner.toml" model)"
  assert_eq "profile sw-change-owner sandbox" workspace-write "$(toml_value "$profiles_dir/sw-change-owner.toml" sandbox_mode)"
  assert_eq "profile sw-reviewer model" gpt-5.6-sol "$(toml_value "$profiles_dir/sw-reviewer.toml" model)"
  assert_eq "profile sw-reviewer sandbox" read-only "$(toml_value "$profiles_dir/sw-reviewer.toml" sandbox_mode)"
  assert_yes "profile sw-change-owner routes into the ship workflow" \
    "$(grep -Fq '$sw:ship' "$profiles_dir/sw-change-owner.toml" && echo yes || echo no)"
  assert_yes "profile sw-reviewer routes into the review workflow" \
    "$(grep -Fq '$sw:review' "$profiles_dir/sw-reviewer.toml" && echo yes || echo no)"
}

assert_vault() {
  local label="$1" project="$2" directory
  assert_eq "$label vault conventions exists" yes "$([ -d "$project/.specwright/conventions" ] && echo yes || echo no)"
  assert_file "$label vault conventions signpost" "$project/.specwright/conventions/README.md"
  for directory in changes deliveries; do
    assert_file "$label vault marker $directory" "$project/.specwright/$directory/.gitkeep"
  done
}

run_init_shared() {
  local project before after output
  ensure_temporary_root
  project="$(new_project shared)"
  output="$temporary_root/shared-init.out"

  run_init "$project" shared "$output"
  assert_eq "shared init exits 0" 0 $?
  assert_vault shared "$project"
  assert_file "shared canonical AGENTS.md exists" "$project/AGENTS.md"
  assert_symlink "shared Claude adapter" "$project/CLAUDE.md" AGENTS.md
  assert_eq "shared AGENTS.md carries one specwright section" 1 \
    "$(grep -cx '## specwright' "$project/AGENTS.md")"
  assert_file "shared profile sw-change-owner installed" "$project/.codex/agents/sw-change-owner.toml"
  assert_file "shared profile sw-reviewer installed" "$project/.codex/agents/sw-reviewer.toml"
  assert_eq "shared ignore line present once" 1 "$(ignore_line_count "$project" '.specwright/worktrees/')"
  assert_eq "shared mode does not ignore the vault" 1 \
    "$(git -C "$project" check-ignore -q -- .specwright/changes/.gitkeep; echo $?)"
  assert_eq "shared mode does not ignore the profiles" 1 \
    "$(git -C "$project" check-ignore -q -- .codex/agents/sw-reviewer.toml; echo $?)"

  before="$(tree_digest "$project")"
  run_init "$project" shared "$temporary_root/shared-second.out"
  after="$(tree_digest "$project")"
  assert_eq "second shared run writes nothing" "$before" "$after"
  assert_eq "second shared run creates nothing" 0 \
    "$(grep -c '^  created' "$temporary_root/shared-second.out" || true)"
  assert_eq "second shared run reports every path present" 8 \
    "$(grep -c '^  present' "$temporary_root/shared-second.out" || true)"
}

run_init_local() {
  local project line agents_digest codex_digest
  ensure_temporary_root
  project="$(new_project local)"
  mkdir -p "$project/.codex"
  printf '# Project instructions\n\nOwned by the project.\n' >"$project/AGENTS.md"
  printf 'project-owned\n' >"$project/.codex/project.toml"
  printf 'node_modules/\n' >"$project/.gitignore"
  agents_digest="$(cksum <"$project/AGENTS.md")"
  codex_digest="$(cksum <"$project/.codex/project.toml")"

  run_init "$project" local
  assert_vault local "$project"
  assert_file "local canonical AGENTS.override.md exists" "$project/AGENTS.override.md"
  assert_symlink "local Claude adapter" "$project/CLAUDE.local.md" AGENTS.override.md
  assert_eq "pre-existing AGENTS.md is untouched" "$agents_digest" "$(cksum <"$project/AGENTS.md")"
  assert_eq "unrelated .codex/project.toml is untouched" "$codex_digest" "$(cksum <"$project/.codex/project.toml")"
  assert_eq "pre-existing ignore rule is preserved" 1 "$(ignore_line_count "$project" 'node_modules/')"

  for line in \
    '.specwright/worktrees/' \
    '.specwright/' \
    'AGENTS.override.md' \
    'CLAUDE.local.md' \
    '.codex/agents/sw-*.toml'
  do
    assert_eq "local ignore rule [$line] present once" 1 "$(ignore_line_count "$project" "$line")"
  done

  assert_eq "local vault is ignored" 0 "$(git -C "$project" check-ignore -q -- .specwright/changes/.gitkeep; echo $?)"
  assert_eq "local instructions are ignored" 0 "$(git -C "$project" check-ignore -q -- AGENTS.override.md; echo $?)"
  assert_eq "local profile is ignored" 0 "$(git -C "$project" check-ignore -q -- .codex/agents/sw-reviewer.toml; echo $?)"
  assert_eq "unrelated .codex/project.toml stays unignored" 1 "$(git -C "$project" check-ignore -q -- .codex/project.toml; echo $?)"
}

run_init_conflict() {
  local project status=0 output before after
  ensure_temporary_root
  project="$(new_project conflict shared)"
  printf '# project-owned claude file\n' >"$project/CLAUDE.md"
  output="$temporary_root/conflict.out"
  before="$(tree_digest "$project")"
  python3 "$INIT" --project "$project" --mode shared >"$output" 2>&1 || status=$?
  after="$(tree_digest "$project")"
  assert_yes "conflicting adapter exits non-zero" "$([ "$status" -ne 0 ] && echo yes || echo no)"
  assert_yes "conflicting adapter is reported" "$(grep -q '^CONFLICT: ' "$output" && echo yes || echo no)"
  assert_eq "conflicting adapter writes nothing" "$before" "$after"
}

run_init_existing_section() {
  local project
  ensure_temporary_root
  project="$(new_project existing-section shared)"
  printf '# House rules\n\nProject-owned prose.\n' >"$project/AGENTS.md"
  run_init "$project" shared
  run_init "$project" shared
  assert_eq "existing AGENTS.md keeps its prose" 1 "$(grep -cx '# House rules' "$project/AGENTS.md")"
  assert_eq "the section is appended exactly once" 1 "$(grep -cx '## specwright' "$project/AGENTS.md")"
}

if [ "$#" -eq 0 ]; then
  set -- package init
fi
for group in "$@"; do
  case "$group" in
    package) run_package ;;
    init) run_init_shared; run_init_local; run_init_conflict; run_init_existing_section ;;
    *) die "unknown test group: $group" ;;
  esac
done

if [ "$fails" -eq 0 ]; then
  echo "ALL PASS"
  exit 0
fi
echo "$fails FAILED"
exit 1
