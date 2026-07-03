#!/usr/bin/env bash
# Smoke tests for the plugin-only install/setup surface. There is no
# install.sh anymore: the plugin is added via `claude plugin marketplace add`
# + `claude plugin install`, and per-repo content comes from /sw:init. These
# checks assert the repo's own plugin manifests and skill files are in the
# shape those two entry points depend on.
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
fails=0
pass() { printf 'PASS: %s\n' "$1"; }
die()  { printf 'FAIL: %s\n' "$1"; fails=$((fails + 1)); }
assert_eq() { if [ "$2" = "$3" ]; then pass "$1"; else die "$1 — expected [$2] got [$3]"; fi; }

# --- install.sh is retired (AC-1) -------------------------------------------
assert_eq "install.sh absent at repo root" 'no' \
  "$([ -f "$ROOT/install.sh" ] && echo yes || echo no)"

# --- marketplace.json is valid and points at the plugin (AC-2, AC-5) --------
mp="$ROOT/.claude-plugin/marketplace.json"
assert_eq "marketplace.json exists" 'yes' "$([ -f "$mp" ] && echo yes || echo no)"
if command -v jq >/dev/null 2>&1; then
  assert_eq "marketplace.json: valid JSON" '0' "$(jq empty "$mp" >/dev/null 2>&1; echo $?)"
  assert_eq "marketplace.json: plugin source" './plugins/sw' "$(jq -r '.plugins[0].source' "$mp")"
  assert_eq "marketplace.json: description lists sw:init" 'yes' \
    "$(jq -r '.plugins[0].description' "$mp" | grep -q '/sw:init' && echo yes || echo no)"
  assert_eq "marketplace.json: description drops sw:update" 'no' \
    "$(jq -r '.plugins[0].description' "$mp" | grep -q 'sw:update' && echo yes || echo no)"
else
  assert_eq "marketplace.json: valid JSON" '0' \
    "$(python3 -c "import json; json.load(open('$mp'))" >/dev/null 2>&1; echo $?)"
fi

# --- plugin.json is valid and lists the current companion set (AC-3, AC-4) -
pj="$ROOT/plugins/sw/.claude-plugin/plugin.json"
assert_eq "plugin.json exists" 'yes' "$([ -f "$pj" ] && echo yes || echo no)"
if command -v jq >/dev/null 2>&1; then
  assert_eq "plugin.json: valid JSON" '0' "$(jq empty "$pj" >/dev/null 2>&1; echo $?)"
  assert_eq "plugin.json: description mentions init" 'yes' \
    "$(jq -r '.description' "$pj" | grep -q 'init' && echo yes || echo no)"
  assert_eq "plugin.json: description drops update" 'no' \
    "$(jq -r '.description' "$pj" | grep -qw 'update' && echo yes || echo no)"
else
  assert_eq "plugin.json: valid JSON" '0' \
    "$(python3 -c "import json; json.load(open('$pj'))" >/dev/null 2>&1; echo $?)"
fi

# --- /sw:init exists and is the per-repo setup skill (AC-2) -----------------
init_skill="$ROOT/plugins/sw/skills/init/SKILL.md"
assert_eq "init skill exists" 'yes' "$([ -f "$init_skill" ] && echo yes || echo no)"
assert_eq "init skill: frontmatter name is init" 'yes' \
  "$(grep -q '^name: init$' "$init_skill" && echo yes || echo no)"

# --- sw:update is fully retired (AC-4) ---------------------------------------
assert_eq "update skill directory absent" 'no' \
  "$([ -d "$ROOT/plugins/sw/skills/update" ] && echo yes || echo no)"
assert_eq "sw-update.sh absent" 'no' \
  "$([ -f "$ROOT/plugins/sw/scripts/sw-update.sh" ] && echo yes || echo no)"

# --- no dangling install.sh reference in live docs (AC-5) -------------------
# .specwright/ holds historical issue records that legitimately discuss the
# deletion or predate it, and this test script legitimately names the file it
# checks for absence; only live docs outside both must be clean.
live_hits=$(grep -rl "install\.sh" "$ROOT" \
  --exclude-dir=.specwright --exclude-dir=.git --exclude-dir=node_modules 2>/dev/null \
  | grep -v "tests/install/run\.sh$" || true)
assert_eq "no live doc references install.sh" '' "$live_hits"

# --- role subagents are bundled with model + effort (role-subagents AC-1/2/3) -
# Labels name the agent file (not a bare AC-N) so this issue's checks are not
# conflated with the install-surface AC numbering above in the shared output.
agents_dir="$ROOT/plugins/sw/agents"
agent_field() { grep -E "^$2:" "$agents_dir/$1.md" 2>/dev/null | head -n1 | sed -E "s/^$2:[[:space:]]*//; s/[[:space:]]*$//"; }
has_skills()  { grep -Eq '^skills:' "$agents_dir/$1.md"; }

for a in issue-owner task-worker spec-document-reviewer reviewer; do
  assert_eq "agent $a.md exists" 'yes' "$([ -f "$agents_dir/$a.md" ] && echo yes || echo no)"
  for key in name description model effort; do
    assert_eq "agent $a.md: frontmatter has $key" 'yes' \
      "$(grep -Eq "^$key:" "$agents_dir/$a.md" 2>/dev/null && echo yes || echo no)"
  done
done

assert_eq "agent issue-owner model/effort" 'opus/xhigh'   "$(agent_field issue-owner model)/$(agent_field issue-owner effort)"
assert_eq "agent task-worker model/effort" 'sonnet/medium' "$(agent_field task-worker model)/$(agent_field task-worker effort)"
assert_eq "agent spec-document-reviewer model/effort" 'opus/high' "$(agent_field spec-document-reviewer model)/$(agent_field spec-document-reviewer effort)"
assert_eq "agent reviewer model/effort" 'opus/xhigh'      "$(agent_field reviewer model)/$(agent_field reviewer effort)"

# skills: preload only on the two roles that reuse an existing skill
assert_eq "agent issue-owner preloads plan" 'yes' \
  "$(has_skills issue-owner && grep -Eq '^[[:space:]]*-[[:space:]]*plan$' "$agents_dir/issue-owner.md" && echo yes || echo no)"
assert_eq "agent reviewer preloads review" 'yes' \
  "$(has_skills reviewer && grep -Eq '^[[:space:]]*-[[:space:]]*review$' "$agents_dir/reviewer.md" && echo yes || echo no)"
assert_eq "agent task-worker has no skills: key" 'no' \
  "$(has_skills task-worker && echo yes || echo no)"
assert_eq "agent spec-document-reviewer has no skills: key" 'no' \
  "$(has_skills spec-document-reviewer && echo yes || echo no)"

# the migrated spec-reviewer prompt file is gone (role-subagents AC-4)
assert_eq "spec-document-reviewer-prompt.md removed" 'no' \
  "$([ -f "$ROOT/plugins/sw/skills/plan/spec-document-reviewer-prompt.md" ] && echo yes || echo no)"

if [ "$fails" -eq 0 ]; then echo "ALL PASS"; exit 0; else echo "$fails FAILED"; exit 1; fi
