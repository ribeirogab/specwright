# Learnings — role-subagents

Durable, non-obvious facts a future specwright issue would want. Not narration.

## Plugin subagents

- Plugin-shipped subagents live in `plugins/sw/agents/*.md` and are **auto-discovered** on install (no `plugin.json` entry — the optional `agents` manifest key only *overrides* the default `agents/` location).
- They support `name`, `description`, `model`, `effort`, `maxTurns`, `tools`, `disallowedTools`, `skills`, `memory`, `background`, `isolation`. They do **not** support `hooks`, `mcpServers`, or `permissionMode` (a plugin-agent security restriction).
- The `skills:` frontmatter field **preloads the listed skill's full content** into the subagent at startup — used here so a role definition references the skill it runs (`issue-owner` → `plan`, `reviewer` → `review`) instead of duplicating the procedure.
- Per-role reasoning `effort` is set in the agent frontmatter. The Task/Agent dispatch tool exposes a per-invocation `model` but **not** `effort`, so pinning effort per role requires an agent definition — it can't come from a runtime config file. This is why the `config.json` design was dropped: model + effort co-locate natively in the frontmatter.

## YAML frontmatter gotcha (cross-cutting)

- An **unquoted** scalar value containing `: ` (colon-space) breaks the entire frontmatter block, and Claude Code then loads the file with **all fields silently dropped**. Quote any `description`/`argument-hint` value that contains a colon. The bundled skills already quote their descriptions; the `commands/*.md` `argument-hint` values did not (pre-existing breakage, flagged separately).
- `claude plugin validate ./plugins/sw` is a usable mechanical gate for the manifest + skill/agent/command frontmatter. It prints **only problems** — a clean file produces no line — so "no line mentions your file" means it validated clean.
