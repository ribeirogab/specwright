---
feature: rewrite-sw-init
created: 2026-07-03
scope: medium
branch: feat/rewrite-sw-init
worktree: .specwright/worktrees/rewrite-sw-init
milestone: .specwright/milestones/2026-07-03-claude-only-plugin
---
# Rewrite /sw as /sw:init — Spec

**Issue:** see the sibling `issue.md` (the *why*, the acceptance criteria, and the issue `status:`)
**Scope:** create one new content-only `/sw:init` plugin skill and rewrite the three stale reference docs it depends on; no settings.json, self-copy, or per-agent symlink logic anywhere.

> **Note on `scope:` frontmatter** — recorded only.
>
> **Note on `worktree:` frontmatter** — recorded only.
>
> **Note on `milestone:` frontmatter** — recorded only.

This is the **technical** spec — the *how*. The non-technical *why*, the acceptance criteria, and the status live in `issue.md`.

## Architecture

The old `/sw` scaffolder skill (deleted by `plugin-only-restructure`) conflated two concerns: installing specwright's tooling (now the plugin's job — done once, globally, by `claude plugin install`) and preparing a single repository to use it (the vault + entry-point doc + gitignore line). `/sw:init` keeps only the second concern.

`/sw:init` is a new Claude Code plugin skill at `plugins/sw/skills/init/SKILL.md`, invoked as `/sw:init`. It performs three idempotent, additive filesystem operations against the **current working directory** (the repo `/sw:init` is run in — never anything else):

1. **Vault scaffold** — ensure `.specwright/conventions/` (seeded with a signpost `README.md` only when the directory doesn't already exist or is empty — never overwrite user content), `.specwright/issues/.gitkeep`, `.specwright/milestones/.gitkeep`.
2. **Entry-point document** — ensure a root `CLAUDE.md` exists, generated from the bundled `claude-md-template.md` reference (filling its double-brace project-name and project-slug placeholders from the repo — package.json name, directory name fallback, or asking the user). Never overwrites an existing `CLAUDE.md` outright; if one exists, only ensures it declares the `sw` plugin requirement (append a short block if missing) rather than clobbering project-authored content.
3. **`.gitignore` line** — append `.specwright/worktrees/` when the file lacks that exact line; a `.gitignore` that already contains it is left untouched (idempotent, no duplicate).

No other filesystem writes happen. Specifically the skill never touches `.claude/settings.json`, never writes to `.agents/`, `.codex/`, `.cursor/`, `.opencode/`, or `.aider/`, and creates no symlinks. The plugin itself is the only thing that ships the companion skills globally — content-only means content-only.

The three reference docs the skill leans on are rewritten from scratch for this minimal scope (see File Structure): `claude-md-template.md` (renamed from `agents-md-template.md`), `audit-checklist.md`, and `validation.md`. `vault-files.md` already describes only the three vault directories with no settings/self-copy content, so it needs no rewrite — `/sw:init` points to it as-is for the vault file specifications. `claude-plugin-settings.md` described the old settings.json merge recipe that no longer applies to any live skill (the sibling `remove-sw-update` issue owns deleting the `sw-update.sh` engine that also referenced it) — this issue deletes `claude-plugin-settings.md` outright since nothing in the new model reads or writes `.claude/settings.json`.

## File Structure

- **Create** `plugins/sw/skills/init/SKILL.md` — the `/sw:init` skill body: frontmatter (`name: init`, description), steps for the three operations above, idempotency notes, and pointers to the rewritten reference docs.
- **Rename** `plugins/sw/references/agents-md-template.md` → `plugins/sw/references/claude-md-template.md` — rewritten: template targets `CLAUDE.md` (not `AGENTS.md`), keeps the three required section headers (`## Workflow Spec Driven`, `## Coding standard`, `## Skills and slash commands`) with content mirroring this repo's own `CLAUDE.md`, but the "Skills and slash commands" section drops the `.agents/skills/sw-<name>/` canonical-copy line and the Codex/Cursor invocation-syntax callout (no non-Claude agents in this model) and instead states the `sw` plugin is required, naming both install commands. Fills its two double-brace project-name/project-slug placeholders only — no other placeholder token survives a generated file.
- **Modify** `plugins/sw/references/audit-checklist.md` — rewritten: drop `AGENTS.md`/`CLAUDE.md`-symlink section, drop `.agents/skills/sw*` inventory, drop per-agent symlink section, drop the "Claude plugin settings present" section, drop the legacy command/skill-directory migration sections (those describe a pre-plugin repo state that cannot exist under the new model — the plugin is the only source of skills). Keep only what a content-only init/audit still checks: the three vault directories, the `CLAUDE.md` entry point (required section headers + mandatory-plugin line + size cap), and the `.gitignore` line.
- **Modify** `plugins/sw/references/validation.md` — rewritten: same trims as the checklist (drop symlink/settings.json/legacy-migration checks), keep only the checks that still apply: `CLAUDE.md` has no surviving placeholders, `CLAUDE.md` has the three required headers, `CLAUDE.md` is ≤ 80 lines, `CLAUDE.md` declares the plugin requirement with both install commands, the three vault directories exist, `.gitignore` contains the worktrees line. Renumber checks after removals.
- **Delete** `plugins/sw/references/claude-plugin-settings.md` — describes machinery `/sw:init` deliberately does not have; no live skill will reference it after this issue.
- **No change** `plugins/sw/references/vault-files.md` — already correct for the content-only model; `/sw:init` references it as-is.

## Phase Ordering

Single phase — the reference-doc rewrites and the new skill are co-designed (the skill's prose points at the exact section names in the rewritten docs), so they land together in one coherent commit sequence: reference docs first (they have no dependency on the skill), then the skill body (which cites them), then tests/verification.

## Constraints

- **File ownership boundary** — only `plugins/sw/references/*` and the new `plugins/sw/skills/init/` are in scope. Do not touch `plugins/sw/skills/update/` or `plugins/sw/scripts/sw-update.sh` (owned by the sibling `remove-sw-update` issue) or the root `README.md` / repo entry-point doc (owned by `docs-and-install-flow`).
- **No settings.json, no self-copy, no per-agent symlinks anywhere in the new skill or rewritten docs** (AC-5) — this is a hard grep-verified constraint, not a style preference.
- The generated entry-point file is `CLAUDE.md` directly (not a symlink from `AGENTS.md` as the old model had) — Claude-only means `CLAUDE.md` is the one and only entry point; no `AGENTS.md` is created or referenced.
- Must remain idempotent — re-running `/sw:init` in an already-initialized repo makes no destructive change and adds no duplicate content (AC-3 explicitly tests this for `.gitignore`; the same principle extends to the vault dirs and `CLAUDE.md` block).

## User Stories / Scenarios

1. A developer clones a brand-new repo with no `.specwright/` and no `CLAUDE.md`, has the `sw` plugin installed globally, and runs `/sw:init`. The repo gains `.specwright/{conventions,issues,milestones}/`, a root `CLAUDE.md` naming the plugin requirement and the two install commands, and a `.gitignore` with the worktrees line appended.
2. That same developer runs `/sw:init` again by mistake. Nothing breaks: no duplicate `.gitignore` line, the vault directories are untouched (existing conventions files preserved), `CLAUDE.md` is not clobbered.
3. A teammate who has never installed the `sw` plugin opens the repo in Claude Code. The agent reads `CLAUDE.md` (loaded into context automatically) and sees the plugin requirement plus the two install commands, so it can self-serve fixing the gap instead of silently failing to find `/sw:*` commands.

## Acceptance Criteria

The acceptance criteria live in the sibling `issue.md` — the `AC-N` IDs defined there are the contract `tasks.md` references and `/sw:review` walks. Do not duplicate them here; if writing this spec exposed a missing or wrong criterion, fix `issue.md`.

## Risks and Mitigations

| Risk | Mitigation |
|---|---|
| Rewritten reference docs accidentally retain a stale mention of `.agents/`, settings.json, or per-agent symlinks (easy to miss when trimming a large existing file) | Grep the three rewritten/renamed files plus the new skill file for the exact banned strings from AC-5 as an explicit task step before considering the docs done. |
| `CLAUDE.md` template drifts from what `audit-checklist.md`/`validation.md` say to check, causing false DRIFT reports | Write the template first, then derive the checklist/validation required-section list directly from the template's actual headers — not from memory of the old AGENTS.md template. |
| Generated `CLAUDE.md` leaves a double-brace placeholder when project name can't be inferred | Skill falls back to asking the user for project name/stack if not inferable from `package.json`/directory name; template has exactly two placeholder tokens, both filled before the file is written. |
| Runtime verification runs inside this repo, which already has `.specwright/` and `CLAUDE.md`, silently passing trivial checks | Verify in a fresh scratch git repo created specifically for this purpose (a temp dir), per the issue owner instructions. |

## Open Questions

None.
