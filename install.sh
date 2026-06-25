#!/bin/sh
# specwright per-project installer.
#
# Installs the specwright scaffolder skill into the current project, enables the
# Claude Code plugin, and guarantees this layout:
#
#   .agents/skills/sw/               <- real skill files (open agent-skills standard)
#   .claude/skills/sw                -> ../../.agents/skills/sw  (symlink)
#   skills-lock.json                 <- skills CLI lockfile
#   .claude/settings.json            <- specwright marketplace + plugin enabled
#
# Usage (from your project root):
#   curl -fsSL https://raw.githubusercontent.com/ribeirogab/specwright/main/install.sh | sh
#   # or, from a clone:  sh install.sh
#
# Safe to re-run: the skills CLI is idempotent and the symlink + settings merge
# reconcile in place. Tests source this file with SW_INSTALL_LIB=1 to call the
# functions below without running the network install.

set -eu

REPO="ribeirogab/specwright"
SKILL="sw"
# The skills CLI installs the canonical copy under .agents/skills/ when targeting
# the agent-agnostic "universal" agent; we add the .claude symlink ourselves.
CANONICAL=".agents/skills/${SKILL}"
LINK=".claude/skills/${SKILL}"

say()  { printf '%s\n' "$*"; }
fail() { printf 'error: %s\n' "$*" >&2; exit 1; }

# --- plugin configuration helpers --------------------------------------------

# Marketplace source JSON. Dogfood: inside ribeirogab/specwright itself
# (.claude-plugin/marketplace.json declares name = specwright) use the local path,
# else the github source. grep keeps this dependency-free (no jq just to pick).
marketplace_source() {
  if [ -f .claude-plugin/marketplace.json ] && \
     grep -Eq '"name"[[:space:]]*:[[:space:]]*"specwright"' .claude-plugin/marketplace.json; then
    printf '{"source":"directory","path":"."}'
  else
    printf '{"source":"github","repo":"%s"}' "$REPO"
  fi
}

# Which JSON tool merges settings: jq > python3 > none (the soft-fail signal).
plugin_merge_engine() {
  if command -v jq >/dev/null 2>&1; then printf 'jq'
  elif command -v python3 >/dev/null 2>&1; then printf 'python3'
  else printf 'none'; fi
}

# Human-pasteable settings.json object for the soft-fail path.
plugin_snippet() {
  src="$1"
  printf '%s\n' '{'
  printf '  "extraKnownMarketplaces": { "specwright": { "source": %s } },\n' "$src"
  printf '%s\n' '  "enabledPlugins": { "sw@specwright": true }'
  printf '%s\n' '}'
}

# Merge the two keys into $1, preserving every other top-level key. The mktemp
# copy avoids reading and truncating the same file in one redirect; writing to a
# second temp and mv-ing only on jq success preserves a pre-existing (possibly
# malformed) settings.json instead of emptying it when jq exits non-zero.
merge_with_jq() {
  settings="$1"; src="$2"; tmp="$(mktemp)"; out="$(mktemp)"
  if [ -s "$settings" ]; then cp "$settings" "$tmp"; else printf '{}' > "$tmp"; fi
  if jq --argjson src "$src" '
    .extraKnownMarketplaces["specwright"] = { "source": $src }
    | .enabledPlugins["sw@specwright"] = true
  ' "$tmp" > "$out"; then
    mv "$out" "$settings"
  else
    rm -f "$tmp" "$out"
    return 1
  fi
  rm -f "$tmp" "$out"
}

merge_with_python() {
  SW_SETTINGS="$1" SW_SRC="$2" python3 - <<'PY'
import json, os, pathlib
p = pathlib.Path(os.environ["SW_SETTINGS"])
src = json.loads(os.environ["SW_SRC"])
txt = p.read_text() if p.exists() else ""
data = json.loads(txt) if txt.strip() else {}
data.setdefault("extraKnownMarketplaces", {})["specwright"] = {"source": src}
data.setdefault("enabledPlugins", {})["sw@specwright"] = True
p.write_text(json.dumps(data, indent=2) + "\n")
PY
}

# Enable the Claude Code plugin by merging marketplace + enabledPlugins into
# .claude/settings.json. Soft-fail (no abort) when no JSON tool is available.
configure_plugin() {
  settings=".claude/settings.json"
  src="$(marketplace_source)"
  mkdir -p .claude
  case "$(plugin_merge_engine)" in
    jq)      merge_with_jq "$settings" "$src" ;;
    python3) merge_with_python "$settings" "$src" ;;
    *)
      say "warning: neither jq nor python3 found — plugin not auto-configured."
      say "Add this to ${settings} manually:"
      plugin_snippet "$src"
      return 0
      ;;
  esac
  say "Enabled specwright plugin in ${settings}"
}

# Remove pre-plugin leftover command files (missing files are not an error).
remove_legacy_commands() {
  for cmd in sw-spec sw-review-spec; do
    rm -f ".claude/commands/${cmd}.md"
  done
}

print_next_steps() {
  say ""
  say "specwright installed:"
  say "  ${CANONICAL}/"
  say "  ${LINK} -> ../../.agents/skills/${SKILL}"
  say "  skills-lock.json"
  say "  .claude/settings.json (specwright marketplace + plugin enabled)"
  say ""
  say "Next: open this repo in your coding agent and run  /sw"
  say "  (audits the specwright setup and scaffolds whatever is missing)"
  say ""
  say "The specwright plugin (/sw:spec, /sw:new-pr, ...) installs when Claude Code"
  say "trusts this workspace — reopen the repo or accept the trust prompt."
}

# --- install flow ------------------------------------------------------------

run_install() {
  command -v npx >/dev/null 2>&1 || fail "npx not found. Install Node.js (https://nodejs.org) and retry."

  say "Installing ${SKILL} skill from ${REPO} ..."
  # </dev/null: under `curl ... | sh` stdin IS the script source; npx/skills would
  # otherwise drain it, swallowing every line below.
  npx -y skills add "${REPO}" --skill "${SKILL}" -a universal -y </dev/null

  [ -f "${CANONICAL}/SKILL.md" ] || fail "skills CLI did not produce ${CANONICAL}/SKILL.md"

  mkdir -p ".claude/skills"
  if [ -L "${LINK}" ]; then
    rm -f "${LINK}"
  elif [ -e "${LINK}" ]; then
    fail "${LINK} exists and is not a symlink. Remove it and re-run."
  fi
  ln -s "../../.agents/skills/${SKILL}" "${LINK}"

  [ -L "${LINK}" ]          || fail "${LINK} is not a symlink"
  [ -f "${LINK}/SKILL.md" ] || fail "${LINK} does not resolve to the skill"
  [ -f "skills-lock.json" ] || fail "skills-lock.json was not created"

  remove_legacy_commands
  configure_plugin
  print_next_steps
}

# Run only when executed, not when sourced (tests source with SW_INSTALL_LIB=1).
[ "${SW_INSTALL_LIB:-0}" = "1" ] || run_install
