---
status: shipped
feature: spec-driven-workflow
created: 2026-06-13
shipped: 2026-06-13
branch: feat/spec-driven-workflow
mode: autonomous
related:
  - "[[constitution]]"
  - "[[companion-skill-distribution-topology]]"
  - "[[quick-validate-needs-pyyaml-via-uv]]"
---
# Spec-Driven Workflow — Spec

**Status:** Shipped
**Scope:** Rework the memex spec-driven delivery flow into an explicit 7-step pipeline with an autonomous/reviewed execution switch, consolidate the non-negotiable rules into a single `.vault/rules.md`, restructure `AGENTS.md`, and add two bundled companion commands — `/memex:new-pr` and `/memex:code-review`. Applied to both the public scaffold/template and this repo's dogfood.

> **Note on `related:`** — this spec amends `constitution.md` (git hygiene line, PR-command name) and replaces the `.vault/rules/` directory. Both backlinks are recorded above; add reciprocal links when the rules note and constitution are edited.

## Context

The current flow lives only as prose in `AGENTS.md` ("Before starting any work") and is loosely mirrored in `references/agents-md-template.md`. It describes brainstorm → spec → self-review → `/memex:review-spec` → writing-plans → implement, but it stops at "implement" — there is no codified path for branching, quality gates, opening the PR, or iterating on review feedback. Three gaps triggered this rework:

1. **No delivery tail.** The flow never says how work reaches a PR or how review findings are resolved. The constitution (line 37) already references a `/memex-open-pr` command that was never built.
2. **No execution-mode switch.** Every task pays the full review tax even when the author wants a hands-off autonomous run.
3. **Rules are scattered.** Philosophy/git/code rules live implicitly in the global `CLAUDE.md` and partly in the constitution; the `.vault/rules/` directory holds a single unrelated project note. There is no single canonical operational rules file.

The repository dogfoods memex, so any flow change must land in both the shipped scaffold and this repo's own `.vault/` + `AGENTS.md`.

**Design references.** The two new commands are informed by their counterparts in the private `gfchaos/gf-embers` repo — `.agents/commands/new-pr.md` and `.agents/skills/code-review/SKILL.md` — adapted to memex, not copied. Adopted: never-PR-from-main + auto-push, PR-template resolution with embedded fallback, the top-section + optional `## Summary`/`## Spec`/quality-gate body shape, the four severity classes, the `lgtm` verdict templates, the read-project-law-first protocol, the anti-formatting pre-reply gate, the re-review loop, and never-approve-under-pressure. Deliberately diverged: PR/review output is **English** (gf-embers uses pt-BR); our review runs as a **sub-agent** with main-agent triage (gf-embers' is chat-based); the blocker calibration is rewritten for memex (scope guardrails, skill validation, the 80-line cap) instead of gf-embers' app tiers/vendor boundary. Notably, gf-embers already uses a single `.vault/rules.md` with the same numbered Philosophy/Git/Code/Security scheme — independent confirmation of Design §D.

## Problem Statement

Codify a complete, enforceable spec-driven delivery pipeline — from brainstorm to an approved PR — with a single autonomous/reviewed switch, a consolidated rules file, and two new companion commands (`/memex:new-pr`, `/memex:code-review`), encoded across every touchpoint (AGENTS.md prose, the brainstorming skill, the spec template, the new commands, and the rules file) rather than documented in prose alone.

## Non-Goals

- **No language switch.** All committed artifacts stay in English (constitution line 36 unchanged). The PT-BR drafts that motivated this spec are translated to English; no constitution amendment for language.
- **No new vault taxonomy.** No `vault-tagging-scheme.md` note is created (that reference was a copy-paste artifact and is dropped).
- **Not a CI/automation feature.** `/memex:new-pr` and `/memex:code-review` are agent-invoked commands, not GitHub Actions or hooks.
- **No rewrite of `memex-writing-plans` or `memex-recall`.** They are referenced by the flow but unchanged.
- **No change to the constitution's role.** The constitution remains the authority for security and architecture; `rules.md` holds operational non-negotiables.

## Constraints

- **Dogfood + template parity.** Every change lands in both `skills/memex/` (scaffold + references) and this repo's live `.vault/`/`AGENTS.md`/`plugins/`/`.agents/`.
- **Agent-agnostic.** New skills must work on Codex/Cursor/OpenCode, which have no native `/code-review` and may not support sub-agent spawning. `memex-code-review` is bespoke and degrades to a fresh-context pass.
- **Colon command namespace.** New commands are `/memex:new-pr` and `/memex:code-review`, matching `/memex:spec` etc. The stale `/memex-open-pr` reference in the constitution is renamed.
- **Explicit-consent compatibility.** The recorded-consent model must be reconciled with the Explicit-Consent rule, not silently contradict it. `main` is never pushed.
- **No Claude attribution** in any generated commit, PR, or artifact.
- **Markdown-only repo.** No build system; "quality gate" for this repo means the Python validators under `skills/memex/scripts/` and per-skill validation, not a test runner.
- **`AGENTS.md` ≤ 80 lines.** A documented, Phase-5-enforced cap (see `.vault/learnings/agents-md-as-map-not-encyclopedia.md`, `references/agents-md-template.md` line 13, `references/audit-checklist.md` line 166). The restructure must stay within it — the cap is honored, not raised. See Design §A for how.

## Design

### A. `AGENTS.md` restructure (dogfood + template)

Sections, in order (5 total): intro (minimal — see below) → `## Workflow Spec Driven` (the gate + `### Spec flow`) → `## Non-negotiable rules` → `## Vault — read from it, write to it` → `## Skills and slash commands`. The old `## Before starting any work`, `## Work ethic — never the lazy path`, `## Commands (most used)`, and `## Knowledge locations` sections are **removed**. Command discovery survives in `## Skills and slash commands`; the work-ethic principle collapses to the intro tagline; deeper principles live in `.vault/rules.md` + `.vault/constitution.md`.

The intro is reduced to two lines (the template uses a `{{project}}` placeholder; the dogfood substitutes `memex`):
> Instructions for AI coding assistants and developers working on the {{project}} codebase.
>
> **Never give up on the right solution.**

`## Workflow Spec Driven` opens with the pre-work reads: **before any work, read `.vault/_index/home.md` (project knowledge), `.vault/constitution.md` (non-negotiables), and `.vault/rules.md` (operational rules).** Then the triage gate, preserved verbatim: *"Can I describe the complete solution in one sentence?"* — Yes → implement directly; Almost (1-2 open decisions) → ask; No → enter the Spec flow. Questions/exploration → just answer.

`## Non-negotiable rules` body: "All in `.vault/rules.md` — philosophy, git, security, code. Security and architecture are detailed in `.vault/constitution.md`."

`## Vault — read from it, write to it` body (translated from the PT-BR draft): `.vault/` is the project brain. Stuck? Search `learnings/`, `conventions/`, `rules.md`, the relevant spec, and the constitution before guessing or asking. A non-obvious discovery → an atomic note in `.vault/learnings/` (template in `.vault/templates/`), indexed in `.vault/_index/learnings.md`, without asking permission.

**Staying under the 80-line cap (Constraint).** The restructure is net-neutral on size because it removes more than it adds. Removed/folded: the old `## Before starting any work` flow (~10 lines, replaced by the more compact `## Workflow Spec Driven`), and the three sections `## When stuck or in doubt`, `## After completing any task`, `## After completing a spec` (~16 lines total) — their substance folds into the single compact `## Vault — read from it, write to it` section (~6 lines, the reflection-on-shipped-spec rule compressed to one line). Rules are pointerized (no inline rule prose). The `## Skills and slash commands` intro paragraph compresses to one line. The cap is a firm acceptance criterion (`wc -l AGENTS.md` ≤ 80); the implementer trims body prose — never a required section header — to hit it.

### B. `### Spec flow` — the 7 steps

1. `memex-brainstorming` → `spec-<slug>.md`. After the design is approved, brainstorming asks the **execution mode: autonomous or reviewed**. The spec records `branch:` and `mode:`. The recorded mode is registered consent for the feature branch (satisfies the Explicit-Consent rule).
2. Create the branch. **One branch + one PR per spec** — spec, plan, tasks, implementation, and learnings all live in it.
3. **reviewed** → `/memex:review-spec` → `memex-writing-plans` → `plan-<slug>.md` + `tasks-<slug>.md` → implement. **autonomous** → skip the review, go straight to `memex-writing-plans` → plan + tasks → implement.
4. Reflect and write learnings to `.vault/learnings/` if genuinely useful — without asking; part of the delivery. Nothing useful → say "No new learnings" explicitly.
5. **Quality gate.** Identify the touched modules' code-quality processes (test, lint, typecheck, build — Makefile, `package.json` scripts, the area's CI workflows) and run them all; nothing you did may break them. Also check what's missing: if the area has tests configured and you created/changed logic without a test, write the missing tests before proceeding.
6. **PR via `/memex:new-pr`.** autonomous → open right after the quality gate; reviewed → wait for the user to validate and ask, same command.
7. **Review cycle.** With the PR open, dispatch a sub-agent running `memex:code-review` over the branch. Triage findings — fix the ones that make sense; contest the rest and align with the sub-agent until consensus. Push the fixes and request a fresh review. Repeat until the sub-agent approves (`lgtm`). Runs in both modes.

### C. Autonomy switch semantics

- The autonomy question is asked **after design approval**, inside `memex-brainstorming` (its terminal handoff is still `memex-writing-plans`).
- **autonomous** ⇔ direct PR. From the moment the design is approved the run is 100% hands-off: skip `/memex:review-spec`, skip the brainstorming internal spec-review loop, skip the spec user-review gate; write spec + plan + tasks, implement, run the quality gate, open the PR (`/memex:new-pr`), and run the `memex:code-review` cycle to `lgtm` — without stopping for the user.
- **reviewed** ⇔ validate-before PR: run the internal spec-review loop + user gate, then `/memex:review-spec`, then writing-plans → implement → quality gate → wait for the user to ask → `/memex:new-pr` → review cycle.
- The design-approval HARD-GATE in `memex-brainstorming` is **never** skipped, in either mode.

### D. `.vault/rules.md` (single file, English)

Replaces the `.vault/rules/` directory. Sections:

- `## Philosophy (Unix, ESR)` — the 17 ESR rules (Modularity … Extensibility), translated to English.
- `## Git & delivery` — 5 rules: (1) Conventional Commits; every change branches from `main` and lands via PR. (2) **Explicit Consent (recorded-consent form)** — never run `git add`/`commit`/`push` without authorization; a spec's recorded `mode:` **is** that authorization for the feature branch (commit + push + open PR); never push to `main`/`master`. (3) Branch Naming — follow the repo convention (`git branch -a`); never inject tool/author identifiers. (4) No Attribution. (5) **PR via Command** — every PR is opened with `/memex:new-pr`; never open a PR any other way (manual `gh pr create`, GitHub UI).
- `## Code` — 2 rules: Meaningful Comments; Currency (latest docs / latest library versions).
- `## Security` — short pointer: "Detailed in `.vault/constitution.md`."

`skill-validation-requirements.md` moves to `.vault/conventions/skill-validation-requirements.md`. Because rules now live in a single file (not a directory of atomic notes), the `.vault/_index/rules.md` MOC is **removed** — a map-of-content over one file adds nothing. `.vault/_index/home.md` is updated to link `[[../rules|Rules]]` directly (replacing the `[[rules|Rules MOC]]` link and the `add to ../rules/` line). `.vault/_index/conventions.md` gains the relocated `skill-validation-requirements.md` entry under `severity: important`. This makes `rules` a deliberate single-file exception to the per-category dir+MOC symmetry (learnings/conventions keep theirs).

### E. Skill `memex-code-review`

Bundled as a cross-agent **plugin skill** in three real copies (same topology as `memex-recall`): `.agents/skills/memex-code-review/SKILL.md` (`name: memex-code-review`, canonical for non-Claude agents), `plugins/memex/skills/code-review/SKILL.md` (`name: code-review`, the plugin copy that surfaces as `/memex:code-review`), and `skills/memex/scaffold/skills/memex-code-review/SKILL.md` (shipped template). No `commands/` file — plugin skills, not commands, are the portable mechanism (commands are Claude-Code-only). Bespoke and portable (no dependency on native `/code-review`). Design is informed by the `gfchaos/gf-embers` `code-review` skill (adapted, not copied — see Context note).

- **Project law first.** Before drafting any finding, read in order: `.vault/rules.md`, `.vault/constitution.md`, the `AGENTS.md` of each area the diff touches, and the relevant `.vault/conventions/`. A finding that maps to a rule or convention cites it by name (e.g. "Meaningful Comments rule", "constitution — scope guardrails").
- **Scope.** Default: current branch vs base — `git log --oneline main..HEAD`, `git diff main...HEAD`, plus uncommitted work. Narrower if the caller points at specific files/commits. Read enough surrounding source to judge correctness, not just the diff.
- **Output contract.** Plain text. No emojis, no markdown headers, no praise, no signature. One-line verdict, then a flat findings list — one line per finding, no grouping. A pre-reply gate scans the draft for emojis/headers/praise and forces a rewrite if any appear.
- **Severity classes:** `blocker`, `suggestion`, `nitpick`, `question`. Verdict templates: clean approve (`lgtm. no blockers.`), approve-with-nits, request-changes, and a wide-scope-blocker shape for structural issues that can't anchor to a line. The approval token is the literal `lgtm`.
- **Blocker calibration (memex-adapted):** a rule/constitution violation; a skill frontmatter/folder validation failure (would fail to load); AI-attribution in branch commits; out-of-scope or speculative work (scope guardrails / Parsimony); an `AGENTS.md` over the 80-line cap; broken vault cross-links; new logic with zero tests where the area has tests. Typos, single whitespace, and naming preferences in docs-only diffs are nits, never blockers.
- **Re-review.** On "review again, fixed" re-run the full pass on the updated diff; if prior blockers are resolved and nothing new → `lgtm. previous blockers resolved.`
- **Never approve under pressure** when blockers exist, regardless of who asks.
- **Orchestration & degradation.** Step 7 dispatches this as a sub-agent over the branch; the **main agent** triages findings (fix the sensible ones, contest the rest until consensus) and re-requests review — the reviewer only finds, it never edits code. On agents without sub-agent spawning, degrade to a delimited fresh-context review pass.
- **Language.** Skill doc and review output are English.

### F. Skill + command `memex-new-pr`

Bundled identically as a cross-agent **plugin skill** in the same three real copies: `.agents/skills/memex-new-pr/SKILL.md` (`name: memex-new-pr`), `plugins/memex/skills/new-pr/SKILL.md` (`name: new-pr`, surfaces as `/memex:new-pr`), and `skills/memex/scaffold/skills/memex-new-pr/SKILL.md`. No `commands/` file. Design is informed by the `gfchaos/gf-embers` `new-pr` command (adapted, not copied — see Context note). SKILL frontmatter is `name:` + `description:` (the plugin-skill format); the `$ARGUMENTS` convention carries the target branch / extra instructions. Reads the spec frontmatter (`branch`, `mode`).

- **Never from main.** If the current branch is `main`/`master`, stop and tell the user to create a feature branch first.
- **Resolve branch + base.** Current branch via `git branch --show-current`; base defaults to `main` (overridable via `$ARGUMENTS`, e.g. "to main").
- **Push if needed.** `git ls-remote --heads origin <branch>`; if absent, `git push -u origin <branch>` (covered by the recorded-consent model — the spec's `mode:` authorizes pushing the feature branch).
- **Resolve PR template.** Use `.github/PULL_REQUEST_TEMPLATE.md` if present (this repo has one: `## Summary` / `## Test plan` / `## Checklist` / `## Notes for the reviewer`) and fill its sections; if missing, print a one-line notice and use an embedded fallback body.
- **Create.** `gh pr create --base <base> --title <title> --body <body> --assignee @me`. Title is Conventional Commits, **English**; body is **English** (constitution line 36 — diverges from the gf-embers pt-BR reference).
- **Body shape.** Top: one product-level sentence (no filenames/mechanics) + 2-5 concrete bullets. When the PR is spec-driven, fill the template's `## Summary` and link the spec artifacts (`spec-<slug>.md`, `plan-<slug>.md`, `tasks-<slug>.md`) as absolute GitHub URLs on the branch, and record the quality-gate results in `## Test plan`. **No AI attribution** anywhere.
- **Mode behavior.** autonomous → the agent invokes it automatically right after the quality gate; reviewed → the user invokes it when ready.
- **Degradation.** Requires `gh` and a GitHub remote; if either is absent it stops and prints manual instructions instead of failing silently.

### G. Spec template

`.vault/specs/_template/spec.md` and the scaffold copy gain two frontmatter keys: `branch:` and `mode:` (`autonomous | reviewed`).

### H. Constitution

`.vault/constitution.md`: rename `/memex-open-pr` → `/memex:new-pr` (line 37); align the git-hygiene bullet with the recorded-consent model; point operational detail at `.vault/rules.md` while keeping the constitution the security/architecture authority.

### J. `memex-brainstorming` skill modification

The autonomy question is added to the brainstorming flow. The skill exists in **three real copies** that must stay in sync: `plugins/memex/skills/brainstorming/SKILL.md` (runs as `/memex:brainstorming`), `.agents/skills/memex-brainstorming/SKILL.md` (canonical for non-Claude agents), and `skills/memex/scaffold/skills/memex-brainstorming/SKILL.md` (shipped template).

Changes to each copy:
- **Checklist:** insert a new step between the current step 5 ("Present design — get user approval") and step 6 ("Write design doc"): *"Ask execution mode — after design approval, ask the user: autonomous or reviewed. Record `branch:` and `mode:` into the spec frontmatter."* Renumber the rest.
- **Conditional steps:** the current step 7 ("Spec review loop") and step 8 ("User reviews written spec") become **conditional on `mode: reviewed`**. When `mode: autonomous`, both are skipped and the flow goes straight from writing the spec to step 9 (invoke `memex-writing-plans`). The design-approval gate (step 5) is never skipped.
- **Flow diagram:** add an "Ask execution mode" node after "User approves design? → yes" with two edges — `reviewed` → "Spec review loop"; `autonomous` → "Invoke writing-plans skill" (bypassing the review loop and user-review gate).
- **"After the Design" prose:** note that in autonomous mode the spec-review loop and user-review gate are skipped and the agent proceeds through writing-plans → implement → quality gate → `/memex:new-pr` → `memex:code-review` cycle without further prompts, per the `AGENTS.md` Spec flow.

### I. Template mirror and cross-references

- `skills/memex/references/agents-md-template.md` — update the section list (lines ~26-33) and the Template block (lines ~37+) to the new section ordering; keep the ≤80-line cap language.
- `skills/memex/references/audit-checklist.md` — replace the **required AGENTS.md headers** list (lines 155-162) with the new 4 headers (`## Workflow Spec Driven`, `## Non-negotiable rules`, `## Vault — read from it, write to it`, `## Skills and slash commands`); the old `## Before starting any work`, `## Work ethic — never the lazy path`, `## When stuck or in doubt`, `## After completing any task`, `## After completing a spec`, `## Commands (most used)`, and `## Knowledge locations` headers are removed from the required list. Change the `.vault/rules/ (directory exists)` check (line 43) to `.vault/rules.md (file exists)`; **remove** the `.vault/_index/rules.md` required-file line (line 33). Keep the ≤80-line cap check.
- `skills/memex/references/vault-files.md` — replace any `.vault/rules/` directory description with the single `.vault/rules.md` file and drop the rules MOC.
- `skills/memex/references/validation.md` — update if it references the rules directory or the old flow.
- `plugins/memex/commands/spec.md` — its prose describes the flow ("spec self-review loop, user review gate, then `/memex:review-spec`… hand off to `memex-writing-plans`"); update it to mention the autonomy switch and the reviewed/autonomous branch.
- Scaffold — the spec template (`skills/memex/scaffold/.../spec.md` wherever the scaffold's vault template lives), and the two new skills under `skills/memex/scaffold/skills/memex-new-pr/` and `.../memex-code-review/`.

## User Stories / Scenarios

1. **Reviewed run.** Author brainstorms a feature; after approving the design, picks **reviewed**. The spec is written (`mode: reviewed`), reviewed internally + by `/memex:review-spec`, the author approves it, writing-plans produces plan + tasks, the author implements, the quality gate runs, the author validates and asks for the PR, `/memex:new-pr` opens it, and the `memex:code-review` cycle iterates to `lgtm`.
2. **Autonomous run.** Author brainstorms; after approving the design, picks **autonomous**. From there the agent writes the spec (`mode: autonomous`), skips all reviews/gates, produces plan + tasks, implements, runs the quality gate, opens the PR directly, and drives the code-review cycle to `lgtm` without further prompts.
3. **Fresh install.** A user runs `npx skills add ribeirogab/memex` in an English repo; the scaffolded `AGENTS.md` has the `## Workflow Spec Driven` section, `.vault/rules.md` exists, and `/memex:new-pr` + `/memex:code-review` are available.

## Acceptance Criteria

- [x] `.vault/rules.md` exists with exactly four H2 sections: `## Philosophy (Unix, ESR)` (17 numbered rules), `## Git & delivery` (5 numbered rules), `## Code` (2 numbered rules), `## Security` (a pointer to the constitution).
- [x] `.vault/rules/` directory no longer exists; `.vault/conventions/skill-validation-requirements.md` exists with the content formerly at `.vault/rules/skill-validation-requirements.md`.
- [x] `.vault/_index/conventions.md` lists the relocated `skill-validation-requirements.md`; no vault file links to a path under `.vault/rules/` (grep for `rules/` returns no live links).
- [x] `AGENTS.md` contains a `## Workflow Spec Driven` section whose `### Spec flow` is a numbered list of exactly 7 steps matching Design §B, and a `## Non-negotiable rules` section pointing to `.vault/rules.md`.
- [x] `AGENTS.md` retains the triage gate ("Can I describe the complete solution in one sentence?") with the Yes/Almost/No branches, and its pre-work reads name `.vault/_index/home.md`, `.vault/constitution.md`, and `.vault/rules.md`.
- [x] `AGENTS.md` no longer contains a `## Commands (most used)`, `## Knowledge locations`, or `## Work ethic — never the lazy path` section; it has exactly 5 sections (intro + 4 H2 headers).
- [x] `AGENTS.md` intro is the two-line form: a "...working on the memex codebase." line and a bold `**Never give up on the right solution.**` line — no repo-structure paragraph.
- [x] `wc -l AGENTS.md` returns ≤ 80.
- [x] `.vault/_index/rules.md` no longer exists; `.vault/_index/home.md` links `.vault/rules.md` directly and contains no `[[rules|Rules MOC]]` link.
- [x] Each of the three `memex-brainstorming` SKILL copies (`plugins/memex/skills/brainstorming/`, `.agents/skills/memex-brainstorming/`, `skills/memex/scaffold/skills/memex-brainstorming/`) has a checklist step that asks the execution mode after design approval, and marks the spec-review loop + user-review gate as conditional on `mode: reviewed`.
- [x] `skills/memex/references/audit-checklist.md` required-AGENTS.md-headers list is exactly the new 4 headers (contains `## Workflow Spec Driven` and `## Non-negotiable rules`; no longer contains `## Before starting any work`, `## Work ethic — never the lazy path`, `## Commands (most used)`, or `## Knowledge locations`); its file checks reference `.vault/rules.md` (not the `.vault/rules/` directory) and no longer require `.vault/_index/rules.md`.
- [x] `.vault/specs/_template/spec.md` frontmatter contains the keys `branch:` and `mode:`; running a grep for both keys in the template returns a match.
- [x] Each new skill exists in all three copies with the correct `name:` field: `.agents/skills/memex-new-pr/SKILL.md` (`name: memex-new-pr`), `plugins/memex/skills/new-pr/SKILL.md` (`name: new-pr`), `skills/memex/scaffold/skills/memex-new-pr/SKILL.md`; and the same trio for `code-review` (`memex-code-review` / `code-review`).
- [x] No `plugins/memex/commands/new-pr.md` or `plugins/memex/commands/code-review.md` is created (the two are plugin skills, not commands).
- [x] `.vault/constitution.md` contains the string `/memex:new-pr` and does not contain `/memex-open-pr`.
- [x] The Explicit-Consent rule text in `.vault/rules.md` explicitly states that a spec's recorded `mode:` authorizes feature-branch commit/push/PR and that `main`/`master` is never pushed.
- [x] `skills/memex/references/agents-md-template.md` section list and Template block reflect the new section ordering (grep for `## Workflow Spec Driven` returns a match; the old `## Before starting any work` heading is gone or folded).
- [x] `python3 skills/memex/scripts/quick_validate.py` (or the documented validator) passes for the two new scaffold skills.
- [x] Both `memex-code-review` and `memex-new-pr` SKILL bodies state their portable-degradation behavior (no native `/code-review` dependency; `gh`/remote absence handling).
- [x] `memex-code-review` SKILL defines the four severity classes (`blocker`/`suggestion`/`nitpick`/`question`), the `lgtm` approval token, the read-project-law-first order, and the never-approve-under-pressure rule.
- [x] `memex-new-pr` SKILL stops when the current branch is `main`/`master`, resolves `.github/PULL_REQUEST_TEMPLATE.md` with an embedded fallback, and produces an English Conventional-Commit title + English body with no AI attribution.

## Risks and Mitigations

| Risk | Mitigation |
|---|---|
| Recorded-consent model read as overriding the global "never commit/push without approval" rule, leading to unwanted pushes | Rule text scopes consent to the feature branch only and reaffirms `main`/`master` is never pushed; the mode is set by an explicit in-brainstorm answer, not inferred. |
| Dogfood and template drift (one updated, the other not) | Acceptance criteria assert both the live files and the `skills/memex/` mirror; the audit checklist is updated so `/memex` re-detects drift. |
| `memex-code-review` unusable on agents without sub-agent spawning | SKILL specifies a fresh-context fallback pass; criterion asserts the degradation is documented. |
| `/memex:new-pr` fails on repos without `gh` or a GitHub remote | Command stops and prints manual instructions instead of erroring; documented in the SKILL. |
| Removing `.vault/rules/` breaks links in existing specs/learnings | Grep gate asserts no live `rules/` links remain; fix references during implementation. |
| This PR edits maintainer-local dirs (`.vault/`, `.agents/`, `.claude/`) that `.github/PULL_REQUEST_TEMPLATE.md`'s checklist says to leave untouched | That checklist item targets external-contributor PRs; the constitution scope guardrails put `.agents/skills/memex-*/` in scope, and the maintainer's own prior specs committed `.vault/` edits. `memex-new-pr` fills the template honestly; the maintainer annotates the checklist item for dogfood PRs. |

## Open Questions

_None — all design decisions resolved during brainstorming (rules layout, command naming, code-review build, scope, artifact language, consent scope, autonomy model and its post-design-approval timing)._
