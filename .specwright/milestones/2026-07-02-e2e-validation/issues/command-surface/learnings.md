# Command Surface — Learnings

Curated facts downstream issues inherit via their specs.

- `spec` and `review-spec` exist **only** as Claude Code plugin commands (`plugins/sw/commands/{spec,review-spec}.md`); they have no canonical `.agents/skills` copy anywhere — not in the repo, not in `skills/sw/scaffold/skills/`, not in the sandbox. Documented `$sw-spec`/`@sw-spec`/`$sw-review-spec`/`@sw-review-spec` invocations are therefore unbacked (F1 in this issue's `findings.md`); any issue touching the Codex/Cursor surface must account for the 6-skill (not 8) canonical layout.
- The scaffolder (`sw` skill) install path does **not** create the `.claude/skills/sw` symlink that `install.sh` creates and README documents — the sandbox has `.agents/skills/sw/` but no Claude Code discovery path to it (F2). Installs made by the two paths are not equivalent.
- A project's Claude Code plugin materializes only on the first trusted session: the sandbox's `.claude/settings.json` wiring is complete, yet `~/.claude/plugins/installed_plugins.json` has no entry for it — absence of a pin there is not install drift.
- The user-global plugin cache (`~/.claude/plugins/cache/specwright/sw/`) retains pre-rename revisions whose skills carry the retired names; greps or audits that stray outside the repo/sandbox surfaces will hit them without it meaning drift in the audited install.
