## Summary

What this PR does, in 1–3 bullets. Link any related issue.

## Test plan

- [ ] (For modified skills) Ran `UV_CACHE_DIR=/tmp/specwright-uv-cache uv run --offline --with PyYAML python3 plugins/sw/scripts/quick_validate.py <skill-path>` — output was `Skill is valid!`.
- [ ] (For modified skills) Ran `UV_CACHE_DIR=/tmp/specwright-uv-cache uv run --offline --with PyYAML python3 plugins/sw/scripts/package_skill.py <skill-path> /tmp` — output ended with `Successfully packaged skill to: /tmp/<skill-name>.skill`.
- [ ] (For validator changes) Ran `UV_CACHE_DIR=/tmp/specwright-uv-cache uv run --offline --with PyYAML python3 tests/skills/test_validation.py`.
- [ ] (For package changes) Ran `claude plugin validate --strict plugins/sw` and the relevant `tests/install/run.sh` groups.
- [ ] (For dual-host package changes) Ran `bash tests/release/run.sh`; native Codex ingestion ran in a disposable environment.
- [ ] Tried the skill end-to-end in an agent session (Claude Code, Codex, Cursor, OpenCode, or whichever you use) and observed the expected behavior.
- [ ] (For documentation or template-only changes) Visually confirmed the rendered output is correct.

## Checklist

- [ ] Branch name is descriptive and not `main`.
- [ ] `NOTICE.md` was updated if vendored content was refreshed or modified.
- [ ] `.specwright/` edits, if any, are limited to the current dogfooded issue/milestone artifacts; unrelated historical artifacts are unchanged.
- [ ] No personal host state such as `.claude/settings.json` is committed.
- [ ] Commit messages follow Conventional Commits style.
- [ ] No AI-attribution footers in commits or this description (e.g. `Co-Authored-By: Claude`, `Generated with Cursor`, `Co-authored-by: Codex`, etc.).

## Notes for the reviewer

(Optional. Anything that didn't fit above — alternatives considered, follow-ups deferred to a later PR, etc.)
