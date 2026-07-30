# Learnings — opencode-host-support

- When the managed block template changes and the version bumps in the same change,
  the static `up-to-date` fixtures (`tests/install/fixtures/update/up-to-date/AGENTS.md`
  and `tests/update/fixtures/up-to-date/AGENTS.md`) must be re-rendered with
  `render_managed_block("<new-version>")` or they reclassify as `legacy-migratable`
  and break their own `up-to-date` assertions. The real outgoing-version profile
  digests must also be registered in `KNOWN_PROFILE_DIGESTS_BY_VERSION` so existing
  projects can migrate instead of classifying as `drifted`.

- The task topology validator (check 6) rejects `Integration: isolated` tasks that
  own `.specwright/` paths — isolated workers are contractually barred from touching
  vault artifacts. Plan convention amendments or any `.specwright/` edit as an
  `Integration: inline` owner task, never as a delegable task.

- OpenCode loads skills via `skills.paths` without namespacing; generic skill names
  (`plan`, `run`, `review`) can collide with a user's other skills. OpenCode command
  templates work around this by naming the plugin-relative `skills/<name>/SKILL.md`
  path in the redirect body, but the collision risk remains for the skill tool's
  name-based lookup.
