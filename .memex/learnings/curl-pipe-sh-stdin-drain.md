---
tags:
  - learning
  - gotcha
related:
  - "[[../specs/2026-06-24-install-script/spec]]"
  - "[[skills-cli-agent-selection-shapes-layout]]"
created: 2026-06-24
---
# `curl | sh`: the script is the shell's stdin — child readers drain it

When a script runs via `curl -fsSL … | sh`, the shell reads the **script itself** from stdin. Any child process that reads stdin (an installer, `npx`, an interactive prompt) consumes the not-yet-read remainder of the script source. The shell then hits EOF, and every line after that command silently never executes — no error, no non-zero exit. The same failure reproduces locally with `cat script.sh | sh` (but **not** with `sh script.sh`, where stdin is the terminal).

Fix: redirect the offending command's stdin away from the script with `</dev/null`.

## Context

The per-project `install.sh` ([[../specs/2026-06-24-install-script/spec]]) worked under `sh install.sh` but failed under `curl … | sh`: it created `.agents/skills/memex/` and `skills-lock.json`, then stopped — the `.claude/skills/memex` symlink and verification never ran, with no error. `npx skills add` was draining the rest of the piped script. Adding `</dev/null` to the `npx` line restored the trailing steps. The bug hid behind GitHub's raw CDN cache during testing: after a force-push, `raw.githubusercontent.com/<branch>/…` served the stale pre-fix script for ~5 min, so testing via the immutable `…/<commit-sha>/…` URL was needed to confirm the fix.

## How to Apply

- In any script meant for `curl | sh`, append `</dev/null` to every command that might read stdin (installers, `npx`, package managers, anything that could prompt).
- Test the piped path, not just the file path: `cat install.sh | sh` reproduces the drain; `sh install.sh` does not.
- When verifying a just-pushed `curl|sh` installer, fetch by commit SHA (`raw.githubusercontent.com/<owner>/<repo>/<sha>/…`), not by branch name — the branch URL is CDN-cached ~5 min and will serve the stale script.
