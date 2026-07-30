# Issue Pipeline Contract — Learnings

- Shipped-copy propagation that cannot drift: edit only `.agents/skills/sw-<name>/SKILL.md`, then byte-copy to `skills/sw/scaffold/skills/sw-<name>/SKILL.md` and to `plugins/sw/skills/<name>/SKILL.md` with a line-2 `name:` rewrite; verify with `diff` — the plugin copy must differ in exactly the frontmatter `name:` line, the scaffold copy in nothing.
- `skills/sw/scripts/quick_validate.py` and `package_skill.py` require PyYAML; on this machine the default `python3` (Homebrew) lacks it — use `/usr/bin/python3` (system Python ships `yaml`).
- Follow-up candidate, out of this issue's approved ACs: the pr skill's `## Push the branch if needed` still runs `git push` before the new ordered pre-flight inspects `git remote -v`; moving the pre-flight above the push step would stop a non-GitHub remote before any network write.
- The session scratchpad is shared across parallel issue owners — prefix temp filenames with the issue slug (a generic `pr-body.md` already belonged to a sibling owner).
- Subagent completion notifications do not reliably wake a stopped issue-owner session (dossier 7.1 recurrence at this nesting level too): run review/gate passes inline or poll observable state from a live turn; never end the turn to wait on a notification.
