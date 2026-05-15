---
status: shipped
feature: memex-claude-plugin-namespace
created: 2026-05-15
shipped: 2026-05-15
related:
  - "[[../2026-05-05-memex-canonical-commands/spec-memex-canonical-commands]]"
  - "[[../../learnings/claude-code-extra-known-marketplaces-source-schema]]"
---
# Memex Claude Plugin Namespace — Spec

**Status:** Draft
**Scope:** Migrate the memex skill's bundled slash commands from agent-agnostic flat files (`.agents/commands/memex-*.md` + `.claude/commands/memex-*.md` symlinks → invocation `/memex-spec`) to a Claude Code plugin under namespace `memex` (invocation `/memex:spec`). Make `ribeirogab/agent-skills` itself a Claude Code marketplace. Memex skill stops shipping command files in target repos and instead writes `.claude/settings.json` referencing the upstream marketplace so plugin installs automatically when the user trusts the workspace.

## Context

The `memex` skill scaffolds an externalized project memory (vault, AGENTS.md, templates, companion skills, slash commands) into any target repository. Today the bundled slash commands install at two locations per the previously-shipped canonical-commands convention:

- **Canonical (agent-agnostic):** `.agents/commands/memex-<verb>.md` — `memex-spec`, `memex-learn`, `memex-sweep`, `memex-review-spec`
- **Per-agent symlinks (Claude Code only):** `.claude/commands/memex-<verb>.md` → `../../.agents/commands/memex-<verb>.md`

Result on Claude Code: `/memex-spec`, `/memex-learn`, `/memex-sweep`, `/memex-review-spec` invocations. Slash commands are a Claude Code-specific concept — no other current agent (Codex, Cursor, OpenCode, Aider, Augment) has an equivalent, so the `.agents/commands/` canonical exists today only to serve as the symlink source for `.claude/commands/`.

The maintainer wants the colon-namespaced invocation form Claude Code reserves for plugins: `/memex:spec`, `/memex:learn`, `/memex:sweep`, `/memex:review-spec`. The Claude Code docs are explicit (verified from `https://code.claude.com/docs/en/plugins` and `https://code.claude.com/docs/en/slash-commands`):

> "Plugin skills use a `plugin-name:skill-name` namespace, so they cannot conflict with other levels."

Standalone `.claude/commands/<name>.md` files have no namespace syntax — invocation always matches the filename. Subdirectory placement under `.claude/commands/` does not introduce a colon prefix. The colon form exists exclusively for Claude Code plugins.

Claude Code plugins are distributed through marketplaces. A marketplace is a git repository (or local path) containing `.claude-plugin/marketplace.json` and one or more plugin directories. Users add a marketplace with `/plugin marketplace add` or by declaring `extraKnownMarketplaces` in `.claude/settings.json`; trust-prompt then offers installation. Plugins can also be enabled by default via `enabledPlugins` in `.claude/settings.json`.

## Problem Statement

1. **Invocation syntax does not match the wanted form.** Today `/memex-spec`; user wants `/memex:spec`. Only the plugin route gets the colon.

2. **Cross-agent leakage in slash-command storage.** `.agents/commands/` was introduced as a canonical, agent-agnostic location, but slash commands are a Claude Code concept. The directory exists solely to be symlinked into `.claude/commands/`. Moving slash commands to a Claude Code plugin removes that asymmetry — Claude Code-specific surface lives in Claude Code-specific containers, and `.agents/commands/` ceases to exist.

3. **`agent-skills` repo is not yet a marketplace.** To ship the plugin upstream, the repo must declare itself as a Claude Code marketplace (`.claude-plugin/marketplace.json` at root) and host the plugin source under `plugins/memex/`. The constitution's current scope guardrail (`In scope: skills/ and skills/<skill>/scaffold/`) does not permit those paths.

4. **Existing memex installs in target repos carry legacy command files.** Repositories that have run the memex skill already contain `.claude/commands/memex-*.md` symlinks and `.agents/commands/memex-*.md` canonicals. A re-run of the new memex skill must remove those legacy files cleanly so the user does not see duplicate `/memex-spec` and `/memex:spec` entries.

## Non-Goals

- **Not plugin-ifying the companion skills.** `memex-brainstorming`, `memex-recall`, `memex-writing-plans`, `memex-link` stay canonical under `.agents/skills/<name>/` with per-agent symlinks. They are skills, not slash commands, and they must remain accessible to non-Claude agents (Codex, Cursor, OpenCode) via their native skill-discovery mechanisms. On Claude Code they continue to surface as `/memex-brainstorming` etc. via the existing `.claude/skills/<name>` symlinks — the resulting inconsistency (commands use colon namespace, companion skills use hyphen) is accepted.

- **Not deleting the `memex-open-pr` legacy file in target repos.** Out of scope per the previous canonical-commands spec (orphan policy B). The memex skill does not detect or remove orphan files in installed repos.

- **Not supporting plugin distribution via npm or any non-git source.** Marketplace source in **target repos** (any repo where memex skill scaffolds) is `{ "source": "github", "repo": "ribeirogab/agent-skills" }`. The local-path source value is used **only** in this repo's own dogfood `.claude/settings.json` (see Architecture Decision 7), never in scaffolded settings.json of other repos.

- **Not versioning the plugin.** `plugin.json` omits `version`; git commit SHA drives updates per the Claude Code docs ("If you omit `version` and your plugin is distributed via git, the commit SHA is used and every commit counts as a new version"). The memex-installed `enabledPlugins` entry pins to `@agent-skills`, not to a specific version. The plugin-no-versioning decision is captured here in Non-Goals (not under an Architecture Decision number) because it is a defaults-driven choice with no real fork to record.

- **Not migrating slash commands of any other (future) skill** in this PR. Only the four `memex-*` commands move into the plugin. If `skill-improver` or others gain slash commands later, that is a separate spec.

- **Not preserving the `/memex-spec` invocation as a deprecated alias.** Clean break — the new memex skill removes legacy command files on re-run and the plugin is the sole surface. Repos that previously had `/memex-spec` lose that name; only `/memex:spec` remains.

- **Not changing `npx skills add ribeirogab/agent-skills --skill memex`** install command. That entry point continues to install the memex skill itself. The plugin is a separate Claude Code-side artifact, fetched by Claude Code via marketplace mechanism after the memex skill writes `.claude/settings.json`.

- **Not adding any subagent, hook, MCP server, or LSP server to the plugin.** Plugin contains four slash commands and nothing else.

## Constraints

- **Idempotency non-negotiable.** Re-running `/memex` against any target repo (clean, partially installed, fully installed, or pre-plugin-migration) must converge without prompts beyond the destructive-op confirmations the skill already requires (spec-folder rename, spec-file rename). Removing legacy `.claude/commands/memex-*.md` symlinks and `.agents/commands/memex-*.md` canonical files is treated as a non-destructive op per existing policy ("scaffold sempre vence").

- **No build pipeline.** Per `.vault/constitution.md` § "Tooling and workflow principles", changes are markdown plus inline bash. Settings.json mutation in target repos uses `jq` if available, falling back to a small inline Python or shell snippet documented in `references/`. No JS/TS tooling.

- **Skills self-contained.** Per `.vault/constitution.md` § "Architecture principles", the `memex` skill remains usable by copying or symlinking its directory alone. Plugin scaffold lives outside the skill (at repo root under `plugins/memex/` and `.claude-plugin/marketplace.json`) but the memex skill itself only needs to know the upstream marketplace coordinates (`github:ribeirogab/agent-skills`, plugin name `memex`, marketplace name `agent-skills`) — those four constants live in `skills/memex/references/claude-plugin-settings.md`.

- **Constitution amendment required.** `.vault/constitution.md` § "Scope guardrails" currently restricts in-scope paths to `skills/` and `skills/<skill>/scaffold/`. Spec implementation modifies the constitution to add `.claude-plugin/marketplace.json` and `plugins/<name>/` as in-scope (Claude Code marketplace surface). Amendment is part of the same PR as the spec implementation.

- **Reference docs split out.** Long instructions go in `skills/memex/references/*.md`. The orchestrator (`SKILL.md`) carries dispatch logic and a small bash recipe for settings.json mutation.

- **Two repo modes:** upstream (this repo, `ribeirogab/agent-skills`) is the marketplace and dogfoods itself; target repos consume the marketplace via `extraKnownMarketplaces` in their own `.claude/settings.json`. The memex skill's scaffold logic runs in target-repo mode. Upstream-mode setup (marketplace + plugin source files) is one-time, hand-authored in this same PR, and not produced by any scaffold step.

- **Settings.json merge, not overwrite.** `.claude/settings.json` in target repos may already contain unrelated keys (`permissions`, `env`, hooks, etc.). The memex skill must merge `extraKnownMarketplaces` and `enabledPlugins` into the existing JSON, preserving every other top-level key. A jq merge recipe is mandatory; full-file overwrite is forbidden.

- **No regression in the audit-checklist totals.** Phase 5 keeps exactly 15 checks. Check #11 is redefined (canonical-commands check → settings.json marketplace ref check). No checks are added or removed.

## Architecture Decisions

The brainstorming pass settled six forks. They are recorded here as the decision log so the implementation plan does not relitigate them.

1. **Plugin hosting: upstream marketplace at `ribeirogab/agent-skills`.** Target repos do not carry plugin files. Plugin is fetched by Claude Code from `github:ribeirogab/agent-skills` via marketplace mechanism. Rationale: single source of truth for plugin commands, updates propagate via `/plugin marketplace update`, target repos stay clean. Trade-off rejected: shipping plugin files into every target repo (rejected for cruft + sync drift); hybrid local+upstream (rejected for complexity).

2. **Legacy file handling: hard removal on re-run.** Memex skill detects and deletes `.claude/commands/memex-<verb>.md` and `.agents/commands/memex-<verb>.md` for the four affected verbs (`spec`, `learn`, `sweep`, `review-spec`) on every run, regardless of whether they are real files or symlinks. Rationale: clean break, no `/memex-spec` and `/memex:spec` duplication in Claude Code's `/help`, no deprecation period to maintain. Trade-off rejected: coexistence (rejected for duplicate `/help` entries); deprecation with warnings (rejected for lasting complexity).

3. **Plugin install path in target repos: settings.json auto-config.** Memex skill writes (or merges) `extraKnownMarketplaces` and `enabledPlugins` into the target's `.claude/settings.json`. When the user trusts the workspace in Claude Code, the trust prompt offers to install the marketplace plus enabled plugins. Rationale: zero-manual-command experience, team members on the same repo get the same plugin. Trade-off rejected: documented manual `/plugin marketplace add` + `/plugin install` (rejected for friction); skill running CLI plugin commands via bash (rejected for fragility — depends on Claude Code being live).

4. **Marketplace location: same repo (agent-skills root).** `agent-skills` root gains `.claude-plugin/marketplace.json` and `plugins/memex/`. Repo dogfoods and serves as marketplace simultaneously. Rationale: single repo for the entire memex distribution stack (skill + plugin), no synchronization between two repos, simpler maintainer workflow. Trade-off rejected: separate `ribeirogab/claude-plugins` repo (rejected for two-repo sync overhead); subdir under `claude-plugins/` in this repo (rejected as the same constitution amendment is needed and the subdir adds depth with no benefit).

5. **Phase 5 Check #11 redefinition: settings.json marketplace ref.** The check verifies the target repo's `.claude/settings.json` contains `extraKnownMarketplaces["agent-skills"]` with the correct GitHub source AND `enabledPlugins["memex@agent-skills"] === true`. Total Phase 5 check count stays at 15. Rationale: the marketplace settings entry is the proxy for "plugin is reachable" — actual plugin install lives in `~/.claude/plugins/cache/` which is machine-local and not a property of the repo. Trade-off rejected: drop Check #11 (rejected — loses signal); validate plugin cache existence (rejected for machine-local fragility, can't gate in CI or on first clone).

6. **AGENTS.md command wording: hard-code `/memex:spec` form with one-line cross-agent note.** AGENTS.md and `references/agents-md-template.md` substitute every `/memex-<verb>` literal with `/memex:<verb>`, then add a single line near the top of `## Skills and slash commands` clarifying that the colon syntax is Claude Code's plugin form (Codex: `$memex-<verb>` via skill mention; Cursor: `@memex-<verb>` via rule reference). Rationale: Claude Code is the dominant agent the maintainer uses and team members use; non-Claude users do a one-time mental mapping. Trade-off rejected: prefix-less workflow names (rejected — loses the actionable invocation hint); multi-syntax listing per command (rejected — verbose, table noise, three lines per entry).

7. **Dogfood marketplace source: local path `.`.** This repo's own `.claude/settings.json` declares `extraKnownMarketplaces["agent-skills"].source = { "source": "local", "path": "." }`. Rationale: the maintainer iterates on `plugins/memex/commands/*.md` and on `.claude-plugin/marketplace.json` and needs `/plugin marketplace update` (or session restart) to pick up the local edits immediately, without a commit-push-fetch loop. Trade-off rejected: `github:ribeirogab/agent-skills` for the dogfood source (rejected — every plugin tweak would require commit+push+marketplace-update before it could be tested in this repo, slowing the inner dev loop dramatically). Target repos, by contrast, always use the github source (see Non-Goals).

## User Stories / Scenarios

1. **Fresh install in a new target repo.** Maintainer runs `/memex` in a repo that has neither `.claude/` nor `.agents/`. Memex skill creates the vault, AGENTS.md, templates, companion skills under `.agents/skills/`, and writes `.claude/settings.json` with `extraKnownMarketplaces["agent-skills"]` + `enabledPlugins["memex@agent-skills"]`. No `.claude/commands/` or `.agents/commands/` directories are created. Maintainer restarts Claude Code in that repo, accepts the trust prompt, marketplace and plugin install, and `/memex:spec` is available. Phase 5 reports 15/15 PASS.

2. **Re-install on a target repo that ran the pre-plugin memex.** Repo has `.claude/commands/memex-{spec,learn,sweep,review-spec}.md` symlinks and `.agents/commands/memex-*.md` canonical files. Memex skill detects them, removes them (`rm` for files and symlinks), writes (or merges) the marketplace + plugin into `.claude/settings.json`. Companion skills under `.agents/skills/` are untouched. On next Claude Code start the trust prompt installs the plugin. `/memex-spec` is gone; `/memex:spec` is present. Phase 5 reports 15/15 PASS.

3. **Re-install on a target repo that already has the new plugin installed.** Repo has no legacy command files, has `.claude/settings.json` with the marketplace + plugin entries, has companion skills. Memex skill audits, reports all `OK`, applies no filesystem changes, Phase 5 reports 15/15 PASS. `git status` clean. Idempotency holds.

4. **Re-install on a target repo whose `.claude/settings.json` has unrelated keys.** Repo's settings.json already contains `permissions`, `env`, custom hooks. Memex skill reads the JSON, merges `extraKnownMarketplaces` and `enabledPlugins` (deep-merging if keys present, adding if absent), preserving every unrelated top-level key. `jq -s` or equivalent recipe documented in references. Phase 5 reports 15/15 PASS.

5. **Re-install on a target repo without `.claude/` directory.** Repo uses, say, only Codex. Memex skill scaffolds the vault, AGENTS.md, companion skills under `.agents/skills/` and per-agent symlinks under `.codex/skills/`. Memex skill **does not create** `.claude/` — its absence signals the user does not run Claude Code in this repo. Phase 5 Check #11 (settings.json marketplace ref) is `PASS` because the check is only enforced when `.claude/` exists. AGENTS.md still mentions `/memex:spec` etc. with the cross-agent note. Phase 5 reports 15/15 PASS overall.

6. **Dogfood: agent-skills repo itself.** The same PR that ships the new memex skill applies the migration here: creates `.claude-plugin/marketplace.json`, creates `plugins/memex/{.claude-plugin/plugin.json, commands/{spec,learn,sweep,review-spec}.md}`, deletes `.claude/commands/memex-*.md` legacy symlinks, deletes `.agents/commands/memex-*.md` canonical files, updates `.claude/settings.json` with `extraKnownMarketplaces["agent-skills"].source = { "source": "local", "path": "." }` (Architecture Decision 7). Constitution scope guardrails section is amended in the same commit. Re-running `/memex` in this repo after merge produces no filesystem changes.

7. **Marketplace fetch in target repo: trust prompt flow.** User clones a target repo for the first time. Opens Claude Code. Workspace trust prompt appears. Inside that prompt, Claude Code reads `extraKnownMarketplaces` and surfaces "Install marketplace `agent-skills` and plugin `memex`?" The user accepts; Claude Code fetches `github:ribeirogab/agent-skills`, reads `.claude-plugin/marketplace.json`, fetches `plugins/memex/` from the same repo, enables the plugin. `/memex:spec` etc. become available.

## Acceptance Criteria

Each criterion is binary and observable in under a minute by reading the resulting filesystem state and running the audit.

### Upstream marketplace (agent-skills repo)

- [ ] **AC1.** `.claude-plugin/marketplace.json` exists at repo root. Its content is valid JSON with required fields `name = "agent-skills"`, `owner.name = "ribeirogab"`, and `plugins` array containing exactly one entry: `{ "name": "memex", "source": "./plugins/memex" }`. Verified with `jq '.name, .owner.name, .plugins[0].name, .plugins[0].source' .claude-plugin/marketplace.json` returning `"agent-skills"`, `"ribeirogab"`, `"memex"`, `"./plugins/memex"` in that order.

- [ ] **AC2.** `plugins/memex/.claude-plugin/plugin.json` exists. Its content is valid JSON with `name = "memex"` and any non-empty `description`. The `version` field is absent (git SHA drives versioning per the "Not versioning the plugin" Non-Goal).

- [ ] **AC3.** `plugins/memex/commands/` contains exactly four files: `spec.md`, `learn.md`, `sweep.md`, `review-spec.md`. Each file's body is the content from the pre-migration `.agents/commands/memex-<verb>.md` file unchanged except for verb-self-references (the file `spec.md` may say "this command does X" but any internal mention of `/memex-spec` is rewritten to `/memex:spec`).

- [ ] **AC4.** `plugins/memex/commands/*.md` filenames do **not** contain the `memex-` prefix. `ls plugins/memex/commands/` returns exactly `learn.md  review-spec.md  spec.md  sweep.md` (alphabetical).

### Legacy removal (agent-skills repo dogfood)

- [ ] **AC5.** `.agents/commands/` directory does not exist at repo root. `test ! -d .agents/commands` succeeds.

- [ ] **AC6.** `.claude/commands/memex-spec.md`, `.claude/commands/memex-learn.md`, `.claude/commands/memex-sweep.md`, `.claude/commands/memex-review-spec.md` do not exist (whether as files or symlinks). `find .claude/commands -name 'memex-*' 2>/dev/null` returns nothing.

- [ ] **AC7.** This repo's `.claude/settings.json` contains both `extraKnownMarketplaces["agent-skills"]` and `enabledPlugins["memex@agent-skills"] = true`. The marketplace source value is exactly `{ "source": "local", "path": "." }` per Architecture Decision 7 (dogfood local-path). Verified with `jq '.extraKnownMarketplaces["agent-skills"].source' .claude/settings.json` returning `{"source":"local","path":"."}` (key order irrelevant) and `jq '.enabledPlugins["memex@agent-skills"]' .claude/settings.json` returning `true`. The settings.json file is otherwise unchanged from pre-migration except for these two added keys (any pre-existing top-level keys survive intact).

### Memex skill changes

- [ ] **AC8.** `skills/memex/SKILL.md` Phase 4 no longer contains any block that creates `.agents/commands/<cmd>.md` or `.claude/commands/<cmd>.md` (regular files or symlinks). `grep -nE '(\.agents/commands|\.claude/commands)' skills/memex/SKILL.md` returns no match for the four affected verbs.

- [ ] **AC9.** `skills/memex/SKILL.md` Phase 4 contains a new block that: (a) detects existing `.claude/commands/memex-{spec,learn,sweep,review-spec}.md` and `.agents/commands/memex-{spec,learn,sweep,review-spec}.md` and removes them with `rm` (works for both regular files and symlinks); (b) reads or creates `.claude/settings.json` only when the target repo has a `.claude/` directory; (c) merges `extraKnownMarketplaces["agent-skills"]` and `enabledPlugins["memex@agent-skills"] = true` into the JSON using a jq recipe documented in `skills/memex/references/claude-plugin-settings.md`. The merge recipe preserves every other top-level key.

- [ ] **AC10.** `skills/memex/references/claude-plugin-settings.md` exists and contains: (a) the canonical marketplace name (`agent-skills`), plugin name (`memex`), and GitHub source (`ribeirogab/agent-skills`); (b) the exact JSON object shapes for `extraKnownMarketplaces["agent-skills"]` and `enabledPlugins["memex@agent-skills"]`; (c) a jq merge recipe that handles missing-file, missing-key, and present-key cases without overwriting unrelated keys; (d) the two trade-off-rejected alternatives from Architecture Decision 3 (manual `/plugin marketplace add` + `/plugin install`; bash-driven CLI plugin invocation) with one-line rationale each.

- [ ] **AC11.** `skills/memex/references/audit-checklist.md` no longer lists any `.agents/commands/memex-<verb>.md` entry in "Files and directories to check". The "Per-agent command symlinks (Claude Code only)" subsection is deleted in full. A new check "Claude plugin settings present (when `.claude/` exists)" is documented with its detection recipe (jq query against `.claude/settings.json`) and `DRIFT` semantics (missing key or wrong value → auto-fix in Phase 4 by re-running the merge block).

- [ ] **AC12.** `skills/memex/references/audit-checklist.md` lists legacy paths `.claude/commands/memex-{spec,learn,sweep,review-spec}.md` and `.agents/commands/memex-*.md` under a new "Legacy paths to remove" subsection, with `DRIFT` semantics whenever they exist (no prompt; non-destructive per policy) and the fix being `rm` (works for files and symlinks).

- [ ] **AC13.** `skills/memex/references/validation.md` Phase 5 Check #11 is redefined to validate `.claude/settings.json` contains the marketplace and plugin entries when `.claude/` exists, and trivially `PASS`es when `.claude/` is absent (no `N/A`, no fail). The check uses a portable shell + jq recipe. Total Phase 5 check count remains exactly 15. No other check is added or removed.

- [ ] **AC14.** `skills/memex/references/agents-md-template.md` substitutes every `/memex-<verb>` reference with `/memex:<verb>` for the four affected verbs (`spec`, `learn`, `sweep`, `review-spec`). Companion skill names without slash prefix (`memex-brainstorming`, `memex-recall`, `memex-writing-plans`, `memex-link`) are preserved verbatim — they are skills, not slash commands, and remain in the hyphen form. A new one-line note is added near the top of `## Skills and slash commands`: "Slash commands shown in Claude Code syntax. Codex users invoke as `$memex-<verb>`; Cursor users as `@memex-<verb>`."

- [ ] **AC15.** `AGENTS.md` (root of this repo) receives the same substitution treatment as AC14 in the same commit.

- [ ] **AC16.** `skills/memex/scaffold/commands/` directory does not exist on disk. `test ! -d skills/memex/scaffold/commands` succeeds.

### Constitution amendment

- [ ] **AC17.** `.vault/constitution.md` § "Scope guardrails" includes `.claude-plugin/marketplace.json` (repo root) and `plugins/<name>/` (repo root) as in-scope paths, with a one-sentence rationale tying them to the existing project purpose ("distribute Claude Code skills and the Claude Code surface they require").

### Behavioural verification (audit-and-scaffold runs)

- [ ] **AC18.** Running the new memex skill against a clean test repo (no `.claude/`, no `.agents/`) produces the vault scaffold and companion-skill symlinks. `.claude/commands/`, `.agents/commands/`, and `.claude/settings.json` are not created (no `.claude/` triggers no settings.json). Phase 5 reports 15/15 PASS.

- [ ] **AC19.** Running the new memex skill against a test repo with empty `.claude/` (`.claude/` directory present but otherwise empty) creates `.claude/settings.json` with the two required keys. No `.claude/commands/` or `.agents/commands/` directory is created. Phase 5 reports 15/15 PASS.

- [ ] **AC20.** Running the new memex skill against a test repo seeded with legacy `.claude/commands/memex-{spec,learn,sweep,review-spec}.md` symlinks and `.agents/commands/memex-*.md` canonical files removes all eight legacy files and writes `.claude/settings.json` with the two required keys. The legacy `memex-open-pr.md`, if present, is left untouched (orphan policy B from the prior spec). Phase 5 reports 15/15 PASS.

- [ ] **AC21.** Running the new memex skill against a test repo whose `.claude/settings.json` already contains a `permissions` key (or any other top-level key) merges the marketplace and plugin entries without altering the unrelated key. `diff` of the file pre- and post-run shows only additions, no deletions or modifications outside the two target keys.

- [ ] **AC22.** Running the new memex skill twice in a row against the result of any of AC18–AC21 produces zero filesystem changes on the second run (`git status` clean if these were a real git-tracked repo) and Phase 5 reports 15/15 PASS both times.

### Trust-prompt flow

- [ ] **AC23.** In a target repo where the memex skill has written the settings.json, opening Claude Code and accepting the trust prompt installs marketplace `agent-skills` and plugin `memex`. After install (or `/reload-plugins` if necessary), running `/help` lists `/memex:spec`, `/memex:learn`, `/memex:sweep`, `/memex:review-spec` and does **not** list `/memex-spec` or any other hyphen-form memex command. Verified by visual inspection of `/help` output and by invoking each plugin command to confirm it executes the expected workflow.

## Risks and Mitigations

| Risk | Mitigation |
|---|---|
| Trust-prompt UX is not deterministic — Claude Code may not auto-install marketplace plus plugin on first trust if the user has previously declined a similar prompt or if the Claude Code version is older than the version that introduced `enabledPlugins`. | Document the manual fallback (`/plugin marketplace add ribeirogab/agent-skills` + `/plugin install memex@agent-skills`) in `references/claude-plugin-settings.md`. AC23 verifies the happy path; the spec accepts that an older client may require the manual fallback. |
| Settings.json merge corrupts the file when jq is not installed on the user's system. | The merge recipe in `references/claude-plugin-settings.md` documents a Python fallback (`python3 -c 'import json, sys; ...'`) and the memex skill detects the absence of jq before running the merge. The skill reports a clear error and a manual remediation snippet if neither jq nor python3 is available. |
| The plugin's `commands/<verb>.md` bodies drift from the legacy `.agents/commands/memex-<verb>.md` bodies during the migration (typo, copy-paste error). | AC3 explicitly pins the body contents to the pre-migration files. Implementation does the copy with `cp .agents/commands/memex-<verb>.md plugins/memex/commands/<verb>.md` and then runs an explicit substitution pass for self-references. Diff is reviewed in the PR. |
| `extraKnownMarketplaces` source format may change in a future Claude Code release, breaking the recipe. | Source field is documented in the [Claude Code marketplace schema](https://code.claude.com/docs/en/plugin-marketplaces). The memex skill's settings.json recipe is the only place the format is referenced — a future schema change is a one-file fix in `references/claude-plugin-settings.md`. |
| The constitution amendment widens scope and could be used to justify future repo-root additions unrelated to Claude Code skills. | The amendment is precisely worded: it permits exactly `.claude-plugin/marketplace.json` (singular, at repo root) and `plugins/<name>/` (Claude Code marketplace plugin sources). Other repo-root paths remain out of scope and require a separate amendment. |
| Companion skills (`memex-brainstorming` etc.) continue to surface as `/memex-brainstorming` on Claude Code, creating an inconsistency where slash commands use the colon namespace and companion skills use the hyphen form. | Accepted per Non-Goals. The cross-agent note in AGENTS.md (AC14) makes the asymmetry explicit. A future spec can plugin-ify the companion skills if the maintainer decides the inconsistency outweighs the cross-agent-symlink simplicity. |

## Open Questions

None. All forks settled in `Architecture Decisions`.
