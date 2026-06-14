---
status: draft
feature: bare-spec-filenames
created: 2026-06-14
shipped: null
branch: feat/bare-spec-filenames
mode: autonomous
related:
  - "[[mechanical-enforcement-over-prose]]"
  - "[[companion-skill-distribution-topology]]"
  - "[[rename-spec-grep-first]]"
  - "[[sed-rename-pattern-completeness]]"
---
# Bare Spec Filenames — Spec

**Status:** Draft
**Scope:** Reverse memex's shipped spec-file naming convention from `<type>-<slug>.md` to bare `spec.md` / `plan.md` / `tasks.md`, keeping every wikilink resolvable by making the dated spec folder the link discriminator (path-qualified wikilinks) and re-keying the GC tooling on folder-relative identity.

## Context

Today every spec folder `.vault/specs/YYYY-MM-DD-<slug>/` holds `spec-<slug>.md`, `plan-<slug>.md`, `tasks-<slug>.md`. The slug is baked into the filename on purpose, for **two** documented reasons (`skills/memex/references/validation.md` check #15, `audit-checklist.md`, `vault-files.md:264`):

- **(a) wikilink uniqueness** — Obsidian resolves `[[ ]]` by basename, ignoring the folder; the `/memex:link` resolver and `/memex:sweep` broken-link checks are likewise basename-keyed. Two bare `spec.md` files would make `[[spec]]` ambiguous and collide in the tooling.
- **(b) editor/picker/search disambiguation** — many UIs show only the basename; a vault full of `spec.md` tabs is a wall of indistinguishable entries.

The maintainer wants bare filenames. Reason (a) is **fully solved** by path-qualified wikilinks: the dated folder (`YYYY-MM-DD-<slug>`) is already globally unique, so `[[YYYY-MM-DD-<slug>/spec|spec]]` resolves uniquely, and the GC tooling can key on folder-relative identity instead of basename. Reason (b) is **knowingly traded away** — this was confirmed with the maintainer (bare tabs/fuzzy-finder entries are accepted; modern editors show the parent folder on collision, partially mitigating it).

Because the skills that *generate* specs are the same files that *ship* to every repo memex installs into, this cannot be a vault-only cleanup: the convention must be reversed **ship-wide** (skills, templates, validators, references, project law) and then the dogfood vault migrated. Confirmed ship-wide with the maintainer.

## Problem Statement

Make bare `spec.md` / `plan.md` / `tasks.md` the memex convention everywhere — taught by the generating skills, enforced by the validator/audit, documented in the project law — without breaking wikilink resolution, the `/memex:link` cross-link detector, or the `/memex:sweep` broken-link check, and migrate this repo's existing specs to the new form.

## Non-Goals

- Not changing how learnings, conventions, or rules are named or linked. Their basenames are already globally unique; only spec-folder files (`spec`/`plan`/`tasks`) collide under bare naming, so only their identity handling changes.
- Not introducing relative-path or absolute-path Obsidian *vault settings* — the repo cannot depend on a per-user GUI setting; links carry the folder explicitly in their text.
- Not rewriting fictional/illustrative wikilinks embedded in historical spec prose (e.g. `[[spec-test-spec]]`, `[[spec-island-test]]` inside a shipped tasks doc) — only links that resolve to actually-renamed files are migrated.
- Not changing the spec-folder naming convention (`YYYY-MM-DD-<slug>/`) — only the files inside it.
- Not adding new artifacts (no `design.md`, no extra frontmatter fields).

## Constraints

- **Markdown + bash only** (constitution: no JS/TS/Python tooling at repo root; no build pipeline).
- **3-copy sync invariant** — each of these exists in three kept-in-sync copies; edit the canonical (`.agents`) copy, regenerate the others; bodies must stay identical (`plugins` SKILL.md copies differ only in the `name:` frontmatter line). Exact paths (note the plugin skill folders are **un-prefixed** — `brainstorming`, `writing-plans`, `link` — not `memex-*`):
  - `memex-brainstorming`: `.agents/skills/memex-brainstorming/SKILL.md`, `plugins/memex/skills/brainstorming/SKILL.md`, `skills/memex/scaffold/skills/memex-brainstorming/SKILL.md`.
  - `memex-writing-plans`: `.agents/skills/memex-writing-plans/SKILL.md`, `plugins/memex/skills/writing-plans/SKILL.md`, `skills/memex/scaffold/skills/memex-writing-plans/SKILL.md`.
  - `find-candidates.sh`: `.agents/skills/memex-link/scripts/find-candidates.sh`, `plugins/memex/skills/link/scripts/find-candidates.sh`, `skills/memex/scaffold/skills/memex-link/scripts/find-candidates.sh`.
- **AGENTS.md size cap** — ≤80 lines, 4 `## ` section headers (validation checks #4, #14).
- **English** for all committed artifacts; **Conventional Commits**, no agent attribution.
- **Recorded consent** — `mode: autonomous` authorizes committing + pushing `feat/bare-spec-filenames` and opening its PR.
- The link test harness (`.agents/skills/memex-link/tests/run.sh`) must stay green; the validator (`references/validation.md`) and `/memex:sweep` must pass on the migrated vault.

## Design — change groups

The link resolver regex already accepts an optional path prefix (`\[\[([^]|]*/)?<base>(\||\]\])`), so path-qualified links are *detected* today; the work is to (1) make the tooling's *identity* folder-aware so bare basenames don't collide across specs, and (2) flip every place that teaches, enforces, or documents the old convention.

**Canonical link forms after this change:**
- Intra-spec sibling links (in a real spec's `plan`/`tasks` frontmatter + body): `[[YYYY-MM-DD-<slug>/spec|spec]]`, `[[YYYY-MM-DD-<slug>/plan|plan]]` — the dated folder is the discriminator.
- Cross-vault inbound links (e.g. a learning → a spec): preserve the existing path prefix, drop the slug from the filename — `[[../specs/YYYY-MM-DD-<slug>/spec|<slug>]]`. The folder remains in the path, so `<folder>/spec` stays unique.
- **Templates** (`_template/` and the template blocks in `vault-files.md`) keep **bare, unqualified placeholders** `[[spec]]`/`[[plan]]` — a static template cannot know the instantiation folder, and `/memex:sweep` already skips `_template/`. The folder qualification is **injected by the generating skills at instantiation time** (§B), not stored in the template. The reconcile direction in §A is therefore: bring `vault-files.md` (which currently bakes `[[spec-{{kebab-slug-of-feature}}]]`) **down to** the bare `[[spec]]`/`[[plan]]` placeholders already used by the on-disk `_template/` files.

### §A — Convention definition (the canonical statement)
- `skills/memex/references/vault-files.md`: rewrite the "Spec file naming convention" prose (~line 264) to mandate bare names + path-qualified links, stating reason (a) solved and reason (b) accepted; update the `_template/plan.md` and `_template/tasks.md` template blocks (~lines 207–249) to the new link form.
- `.vault/specs/_template/plan.md`, `.vault/specs/_template/tasks.md`: reconcile the placeholder link form with §A so the dogfood template matches the shipped reference.

### §B — Generating skills (inject bare name + folder-qualified link)
- `memex-brainstorming` (×3): write the spec to `…/<folder>/spec.md` (not `spec-<slug>.md`).
- `memex-writing-plans` (×3): write `plan.md` / `tasks.md` and inject the folder-qualified sibling links `[[<folder>/spec|spec]]` / `[[<folder>/plan|plan]]`.

### §C — GC tooling identity (the "Clean")
- `find-candidates.sh` (×3, paths in Constraints): make the matching unit folder-relative for spec-folder files. This is a **three-part** change to the script, all of which must move together:
  1. **`related[]` extraction** (the `.related` cache builder): stop reducing every wikilink to its bare basename — **preserve the path as written** (strip `[[`, `]]`, and any `|alias`, but keep a `folder/` prefix when present). A learning linked bare as `[[foo]]` still stores `foo`; a spec linked as `[[<folder>/spec|spec]]` stores `<folder>/spec`.
  2. **Target comparison key**: compute each target's key as `<parent-folder>/<basename>` when the target is a `spec`/`plan`/`tasks` file inside a spec folder, and as the bare `<basename>` otherwise. The dedup (`src_related_str` membership) and the wikilink-in-body evidence grep both compare against this key — so a `[[A/spec]]` link is **not** counted as evidence for, or a dedup against, `B/spec`.
  3. **Filters**: update the `all_notes` exclusions (`plan-[^/]+\.md` → `plan\.md`, `tasks-[^/]+\.md` → `tasks\.md`) and the intra-pair skip (`plan-*|tasks-*` → `plan.md|tasks.md`).
  Non-spec notes (learnings/conventions/rules) keep bare-basename keying unchanged.
- `.agents/skills/memex-link/tests/`: update `fixtures/.vault` and `expected-output.json` so `run.sh` exercises and passes the folder-relative identity (including a two-spec case proving no cross-spec basename false-dedup).
- `plugins/memex/commands/sweep.md`: make the broken-link resolution folder-aware for spec-folder links (verify the specific `…/<folder>/spec.md` exists, not just any `spec.md`); update check #5 to look for `spec.md` / `tasks.md`.

### §D — Validator / audit (invert enforcement)
- `skills/memex/references/validation.md`: invert check #15 — require bare names, flag surviving `<type>-<slug>.md` as FAIL; update the TOC line (#10) and the fix pointer.
- `skills/memex/references/audit-checklist.md`: invert the "Spec file naming" section — bare is correct, slug-named is DRIFT.
- `skills/memex/SKILL.md`: reverse the Phase-4 "spec file rename migration" recipe — `git mv` `<type>-<slug>.md` → `<type>.md` and rewrite `[[<type>-<slug>]]` → `[[<folder>/<type>|<type>]]` (and the `/<folder>/<type>-<slug>` filepath-form links).

### §E — Project law / docs
- `.vault/constitution.md` and `skills/memex/references/constitution-template.md`: flow line `spec-<slug>.md → plan-<slug>.md → tasks-<slug>.md` → bare.
- `skills/memex/references/agents-md-template.md` and `AGENTS.md`: the spec-flow step that names `spec-<slug>.md` / `plan-<slug>.md` / `tasks-<slug>.md` → bare.
- `plugins/memex/skills/new-pr/SKILL.md` (+ `.agents`/`scaffold` copies) and `plugins/memex/commands/review-spec.md`: filename references → bare.

### §F — Migration (this repo)
- `git mv` each present `<type>-<slug>.md` → `<type>.md` across the **10** spec folders (the 9 existing + this in-flight `bare-spec-filenames` spec). The 9 existing folders have all three files; the in-flight folder has **only** `spec-bare-spec-filenames.md` at mv time (its `plan.md`/`tasks.md` are written bare by §B during this same flow) — `git mv` only the files that exist, do not assume three per folder.
- Rewrite every wikilink that resolves to a renamed file — intra-pair (frontmatter + body) and cross-vault — to the §A canonical forms. Cross-vault inbound links exist in **two shapes** and both must be caught (grep-first, per `[[rename-spec-grep-first]]`): bare-basename links such as `[[2026-06-13-spec-driven-workflow/spec|spec-driven-workflow]]` inside learnings (e.g. `companion-skill-distribution-topology.md`, `quick-validate-needs-pyyaml-via-uv.md`), and path-prefixed links such as `[[../specs/<folder>/spec-<slug>|alias]]` in `.vault/_index/specs.md` and other MOCs. Leave fictional/example links (`[[spec-test-spec]]`, `[[spec-island-test]]` embedded in historical tasks prose, resolving to no real file) untouched.

### §G — Sync invariant
- After editing canonical copies, regenerate plugin + scaffold copies; verify body-identity for all multi-copy skills/scripts.

## User Stories / Scenarios

1. A maintainer opens a spec folder and sees `spec.md`, `plan.md`, `tasks.md` — no slug noise.
2. An agent runs `/memex:link` on the vault; two different specs both named `spec.md` do **not** suppress each other's cross-link suggestions (no basename false-dedup).
3. An agent runs `/memex:sweep`; no broken wikilink is reported for the migrated vault, and a link pointing at a deleted spec's `spec.md` is **not** falsely resolved to a different spec's `spec.md`.
4. A fresh `memex` install into another repo produces bare-named spec files and the validator's check #15 passes (now meaning "bare names present").
5. `memex-brainstorming` + `memex-writing-plans` create a new spec whose sibling links are folder-qualified and resolve in Obsidian and in the tooling.

## Acceptance Criteria

- [ ] No file matches `.vault/specs/[0-9]*-*/`(`spec`|`plan`|`tasks`)`-*.md`: `find .vault/specs -type f \( -name 'spec-*.md' -o -name 'plan-*.md' -o -name 'tasks-*.md' \)` returns empty.
- [ ] Each of the 10 spec folders contains `spec.md`; folders that had a plan/tasks contain `plan.md`/`tasks.md`.
- [ ] `bash .agents/skills/memex-link/tests/run.sh` prints `PASS`, and the fixtures include a two-spec case where linking spec A does not suppress a suggestion toward spec B's `spec.md`.
- [ ] `/memex:sweep` broken-wikilink check reports zero `BROKEN` against the migrated `.vault/`.
- [ ] The (inverted) validation check #15 bash, run against this repo's `.vault/`, prints `PASS`; the same bash prints `FAIL` when a `spec-<slug>.md` file is reintroduced (spot-checked in a temp copy).
- [ ] `grep -rnE '(spec|plan|tasks)-<slug>\.md' AGENTS.md .vault/constitution.md skills/memex/ plugins/memex/ .agents/skills/` returns no hit inside an active convention statement (only historical/illustrative mentions, if any, remain — and those are explicitly called out).
- [ ] 3-copy body-identity holds: `diff <(tail -n+3 .agents/skills/memex-brainstorming/SKILL.md) <(tail -n+3 plugins/memex/skills/brainstorming/SKILL.md)` is empty (same for `memex-writing-plans`); and `find-candidates.sh` is byte-identical across its three copies — `diff .agents/skills/memex-link/scripts/find-candidates.sh plugins/memex/skills/link/scripts/find-candidates.sh` and `diff .agents/skills/memex-link/scripts/find-candidates.sh skills/memex/scaffold/skills/memex-link/scripts/find-candidates.sh` both empty.
- [ ] Every inbound wikilink to a renamed file resolves (a vault-wide basename/path resolution scan finds a matching file for each).
- [ ] `AGENTS.md` is ≤80 lines and still has exactly 4 `## ` section headers.
- [ ] `git grep -n 'spec\.md\|plan\.md\|tasks\.md'` in `skills/memex/references/vault-files.md` shows the convention prose describes bare names as the rule.

## Risks and Mitigations

| Risk | Mitigation |
|---|---|
| `find-candidates.sh` is dense bash; folder-keying changes could regress detection. | Drive the change with the `tests/run.sh` fixtures + expected-output; add the two-spec no-false-dedup case before editing logic (TDD). |
| `sed`-based link rewrite over-matches (e.g. `spec-tweaks` when rewriting `spec-<slug>`) — see `[[sed-rename-pattern-completeness]]`. | Scope rewrites to wikilink edges (`[|\]]` char-class) and to the exact known slugs of the 10 folders; verify with a before/after broken-link sweep. |
| Migrating only some inbound links leaves dangling references — see `[[rename-spec-grep-first]]`. | Grep-first: enumerate every `[[…spec-<slug>…]]` / `[[…plan-<slug>…]]` / `[[…tasks-<slug>…]]` occurrence per folder, rewrite all, then sweep. |
| Editor/fuzzy-finder disambiguation (reason b) is lost. | Accepted by the maintainer; recorded here so the decision is not silently re-litigated. |
| 3-copy drift if only the canonical copy is edited. | Regenerate plugin/scaffold copies in the same task; assert body-identity in the quality gate. |

## Open Questions

(none — the two crux decisions, bare-names tradeoff and ship-wide scope, were resolved with the maintainer before writing this spec.)
