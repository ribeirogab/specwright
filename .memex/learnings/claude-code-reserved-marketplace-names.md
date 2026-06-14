---
tags:
  - learning
  - gotcha
related:
  - "[[claude-code-extra-known-marketplaces-source-schema]]"
  - "[[../specs/2026-05-15-memex-claude-plugin-namespace/spec]]"
created: 2026-05-15
---
# Claude Code Reserves Certain Marketplace Names

Claude Code's plugin marketplace system reserves a set of names for official Anthropic marketplaces. Attempting to register a marketplace with a reserved `name` via `claude plugin marketplace add` (or the equivalent settings.json `extraKnownMarketplaces` entry) fails with:

```
✘ Failed to add marketplace: The name '<reserved>' is reserved for official Anthropic marketplaces and can only be used with GitHub sources from the 'anthropics' organization.
```

The error fires regardless of source type (`directory`, `github`, `git`, etc.) unless the source is GitHub-hosted under `anthropics/<repo>`.

Confirmed reserved name (observed in practice): `agent-skills`. Anthropic does not publish the full reserved list, so treat anything that sounds like an Anthropic feature/category (`claude-plugins-official`, `agent-skills`, etc.) as potentially reserved.

## Context

Discovered post-merge of `2026-05-15-memex-claude-plugin-namespace`. The spec specified marketplace name `agent-skills` to match the repo name. Settings.json shipped, schema validation passed (after the `local` → `directory` fix in the prior follow-up), but `claude plugin marketplace add` rejected the directory source with the reservation error. Same rejection would happen at workspace trust time for any user installing the marketplace.

Fix: renamed the marketplace to `ribeirogab-agent-skills` (owner-prefixed). All references migrated: `.claude-plugin/marketplace.json` `name` field, this repo's `.claude/settings.json` keys (`extraKnownMarketplaces["ribeirogab-agent-skills"]`, `enabledPlugins["memex@ribeirogab-agent-skills"]`), `skills/memex/SKILL.md` dogfood detection + jq recipe, and the four reference docs that document the coordinates.

## How to Apply

When choosing a marketplace `name` for `.claude-plugin/marketplace.json`:

- **Always prefix with the owner/org name** (e.g., `ribeirogab-agent-skills`, `acme-tools`) unless the marketplace is genuinely an Anthropic-published one served from `github:anthropics/<repo>`.
- Don't reuse short, generic names that overlap with Anthropic product surfaces: `agent-skills`, `agent-sdk`, `claude`, `plugins`, `skills`, `marketplace`, `official`, etc.
- Test marketplace install with `claude plugin marketplace add <source>` before publishing the spec — the reservation check fires at install time, not at file-write time, so the broken state ships unless you actually try to add it.
- The enabled-plugins key follows the marketplace name (`<plugin>@<marketplace-name>`), so every rename cascades into `enabledPlugins`, plugin install commands, `/plugin install plugin@marketplace` literals, and AGENTS.md docs.

The reserved-name list is not documented; rely on the CLI error message to discover collisions during install testing.
