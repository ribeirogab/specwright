---
tags:
  - learning
  - gotcha
related:
  - "[[../specs/2026-05-15-memex-claude-plugin-namespace/spec-memex-claude-plugin-namespace]]"
created: 2026-05-15
---
# Claude Code `extraKnownMarketplaces` Source Schema

Claude Code's `.claude/settings.json` validates `extraKnownMarketplaces[name].source` against a discriminated union with a fixed list of `source` values: `url`, `hostPattern`, `github`, `git`, `npm`, `file`, `directory`. There is no `local` source type. Using `{ "source": "local", "path": "." }` raises a settings-load error (`source: Invalid input`) and Claude Code skips the entire `.claude/settings.json` file — not just the invalid entry. **For a local-path marketplace, use `directory`:**

```json
{
  "extraKnownMarketplaces": {
    "ribeirogab-agent-skills": {
      "source": { "source": "directory", "path": "." }
    }
  }
}
```

> Note: `agent-skills` was the original marketplace name in the spec, but Claude Code reserves that name for official Anthropic marketplaces (`failed to add marketplace: The name 'agent-skills' is reserved`). Renamed to `ribeirogab-agent-skills` in a follow-up fix — see [[claude-code-reserved-marketplace-names]].

## Context

Discovered in `2026-05-15-memex-claude-plugin-namespace` post-merge: the dogfood `.claude/settings.json` shipped with `{ "source": "local", "path": "." }` per the spec (Architecture Decision 7). Claude Code rejected the file with a `Settings Error` dialog: `extraKnownMarketplaces → agent-skills → source → source: Invalid input`. The error message names the invalid field but does not list the valid alternatives.

The valid source types are not in the prose docs at `https://code.claude.com/docs/en/plugin-marketplaces` — those describe **marketplace-internal** plugin sources (`source: "github"`, relative path, etc.) which is a different schema. The authoritative source-type list lives in the JSON schema at `https://json.schemastore.org/claude-code-settings.json`.

## How to Apply

When writing or templating `.claude/settings.json` entries for `extraKnownMarketplaces`:

- For GitHub-hosted marketplaces: `{ "source": "github", "repo": "owner/repo" }`.
- For local-path marketplaces (dogfood, dev): `{ "source": "directory", "path": "<relative-or-absolute>" }` — directory must contain `.claude-plugin/marketplace.json`.
- For a direct `marketplace.json` URL: `{ "source": "url", "url": "https://..." }`.
- For a direct `marketplace.json` file path: `{ "source": "file", "path": "..." }`.
- Never use `"local"` — it is not a valid discriminant value.

Before introducing a new `extraKnownMarketplaces` shape, cross-check against the JSON schema (`json.schemastore.org/claude-code-settings.json`), not just the prose docs.
