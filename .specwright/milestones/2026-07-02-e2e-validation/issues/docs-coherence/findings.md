# Docs Coherence (T11) — Findings

Audit of the specwright repo's own documentation against shipped behavior, at commit `c291025` on branch `chore/e2e-docs-coherence`. Method: every claim in `README.md` / `AGENTS.md` naming a count, command, path, or flow step was mapped to its source of truth in the repo; the five `skills/sw/references/*.md` were swept for retired artifacts and layout accuracy; `validate-spec.sh` was exercised against five fresh fixtures (see `evidence/`). Per the milestone Non-Goals, nothing was fixed — every divergence is a finding (F-N) with Expected / Observed / Proposed fix.

**Verdict summary: 5 findings (F-1..F-5) — 1 behavioral (validator exit-code contract), 2 doc-vs-shipped mismatches, 2 minor wording/omission issues. Everything else checked: match.**

---

## AC-1 — README.md claim-by-claim

| # | Claim (quoted or condensed) | Source of truth | Verdict |
|---|---|---|---|
| R1 | Install "installs the scaffolder skill — `.agents/skills/sw/`, plus the `.claude/skills/sw` symlink, and enables the `sw` plugin in `.claude/settings.json`" | `install.sh` (header comment + `run_install`, `CANONICAL=".agents/skills/sw"`, `LINK=".claude/skills/sw"`, `configure_plugin`) | match |
| R2 | Install command `curl -fsSL https://raw.githubusercontent.com/ribeirogab/specwright/main/install.sh \| sh` | `install.sh` usage comment, line 13 — identical | match |
| R3 | "run `/sw` to audit and scaffold the `.specwright/` vault" | `install.sh` `print_next_steps` ("run /sw"); skill `sw` at `skills/sw/SKILL.md` (audit-first scaffolder), `.claude/skills/sw` symlink present | match |
| R4 | "The plugin commands (`/sw:spec`, `/sw:pr`, …) load once Claude Code trusts the workspace" | `install.sh` `print_next_steps` (same wording); `.claude/settings.json` `enabledPlugins["sw@specwright"]` | match |
| R5 | Vault holds `conventions/` + `issues/` (dated standalone-issue folders) + `milestones/` (dated milestone folders) | `skills/sw/references/vault-files.md` (exactly three directories); actual `.specwright/{conventions,issues,milestones}` in this repo | match |
| R6 | Command table: 9 rows — `/sw` + 8 plugin invocables (`brainstorm`, `spec`, `plan`, `run`, `review`, `review-spec`, `pr`, `update`) | `plugins/sw/commands/{spec,review-spec}.md` (2 commands) + `plugins/sw/skills/{brainstorm,plan,pr,review,run,update}/SKILL.md` (6 skills) + `skills/sw/SKILL.md` (`/sw`) — 9 total | match |
| R7 | Per-command descriptions in the table (brainstorm concludes issue/milestone; plan = pipeline; run = conduct milestone; review = find-only subagents to `lgtm`; review-spec = external evaluator; pr = branch/base/template/Conventional-Commit; update = sync upstream) | Each `SKILL.md` / command frontmatter `description` — sampled all 8 | match |
| R8 | "Design approval is the only human review"; self-review = "spec-document-reviewer subagent + `/sw:review-spec` + the `validate-spec.sh` mechanical gate" | `plugins/sw/skills/plan/SKILL.md` ("Self-review the spec — no human gate", the three gates in order) | match |
| R9 | Issue folder = `issue.md` (ticket + `AC-N` + `status:`), `spec.md`, `tasks.md`, optional `learnings.md` — identical standalone and inside milestones | `vault-files.md` (both trees, same shape); `scaffold/templates/{issue,spec,tasks}.md` | match |
| R10 | Milestone loop: orchestrator "never touches code", dispatches owners, tracks live `board.md`, carries learnings, "three identical failures → `blocked` + a report" | `plugins/sw/skills/run/SKILL.md` (pure conductor, The loop, Circuit breakers) | match |
| R11 | Runtime verification: execute and check each `AC-N` by observed behavior; UI via browser else `needs-human-verification`, "never faked" | `plugins/sw/skills/plan/SKILL.md` (Runtime verification section — same contract) | match |
| R12 | Worktree "default yes; mandatory for parallel milestone dispatch"; path `.specwright/worktrees/` | `plugins/sw/skills/brainstorm/SKILL.md` ("the default is **yes**", worktree guard); `run/SKILL.md` ("Worktree is mandatory for parallel dispatch") | match |
| R13 | Handoff: optional standalone, mandatory after milestone planning; "`/sw:run` resumes from the board in any new session" | `brainstorm/SKILL.md` ("Mandatory handoff — the planning session never conducts"); `run/SKILL.md` ("Resumable from any fresh session") | match |
| R14 | Companion skills live in "three kept-in-sync copies": `.agents/skills/sw-<name>/`, `plugins/sw/skills/<name>/`, `skills/sw/scaffold/skills/sw-<name>/` | `diff -rq` across the three: agents-vs-scaffold byte-identical for all 6; agents-vs-plugin differs **only** in the frontmatter `name:` field (`sw-plan` vs `plan`) — the namespace adaptation the plugin requires | match |
| R15 | "The issue-flow steps — documented in `AGENTS.md` under `### Issue flow` … edit `### Issue flow` in `skills/sw/references/agents-md-template.md` (keep the two consistent)" | `diff` of the two `### Issue flow` blocks | **mismatch — see F-3** (the two blocks have drifted in 7 hunks) |
| R16 | Repository layout tree (9 entries: `skills/sw/`, `plugins/sw/`, `.claude-plugin/`, LICENSE, NOTICE.md, CONTRIBUTING.md, CODE_OF_CONDUCT.md, SECURITY.md, README.md) + "also contains `.agents/`, `.claude/`, and `.specwright/`" | `ls -a` repo root | **mismatch (minor) — see F-5** (`install.sh`, `tests/`, `AGENTS.md`/`CLAUDE.md`, `.github/` exist but appear nowhere in the section) |
| R17 | "The vendored validator scripts under `skills/sw/scripts/` are Apache-2.0; see `NOTICE.md`" | `NOTICE.md` (vendored files are `quick_validate.py` + `package_skill.py`; `validate-spec.sh` and `sw-update.sh` are original MIT work) | **mismatch (wording) — see F-4** |
| R18 | `.claude-plugin/` = "marketplace manifest" declaring marketplace `specwright` | `.claude-plugin/marketplace.json` (`"name": "specwright"`, plugin `sw` at `./plugins/sw`) | match |

## AC-1 — AGENTS.md claim-by-claim

| # | Claim (quoted or condensed) | Source of truth | Verdict |
|---|---|---|---|
| A1 | Issue = one folder (`issue.md` with `AC-N` + `status:`, `spec.md`, `tasks.md`, optional `learnings.md`), one branch, one PR | `vault-files.md`, `scaffold/templates/` | match |
| A2 | Milestone = `goal.md` + live `board.md` + `issues/<slug>/`, conducted by `/sw:run` | `vault-files.md`, `run/SKILL.md`, `scaffold/templates/{goal,board}.md` | match |
| A3 | Step 1: brainstorm converses first, design approval only human review, concludes scope, one batch (single issue = branch + worktree + handoff; milestone = worktree only) | `brainstorm/SKILL.md` (single-issue batch = exactly three things; milestone batch = exactly one thing: worktrees) | match |
| A4 | Step 2 pipeline: `issues/YYYY-MM-DD-<slug>/issue.md` → `/sw:plan` (spec+tasks, three self-review gates, no human gate) → implement → quality gate (test integrity) → runtime verification → `/sw:pr` → `/sw:review` to `lgtm` → `status: shipped` + date; three identical failures → stop | `plan/SKILL.md` — each stage present under the same names and order | match |
| A5 | Step 3: dispatch every **ready** issue (pending + deps shipped), parallel, one worktree each (`.specwright/worktrees/<slug>`, git-ignored; creates, never removes), owners curate `learnings.md`, blocked → board report + loop moves on, closeout promotes learnings with approval, merging stays human | `run/SKILL.md` (ready definition, parallel dispatch, worktree command, closeout); `.gitignore` (`.specwright/worktrees/`); `brainstorm/SKILL.md` ("only ever **creates** worktrees — never removes one") | match |
| A6 | Coding standard: conventions in `.specwright/conventions/`, standalone issues in `.specwright/issues/`, milestones in `.specwright/milestones/` | Actual `.specwright/` tree; `vault-files.md` | match |
| A7 | "Commands + companion skills ship through the `sw` plugin (marketplace `specwright`, in this repo's `.claude/settings.json`)" | `.claude/settings.json` (`extraKnownMarketplaces.specwright` = directory source, `enabledPlugins["sw@specwright"]: true`) | match |
| A8 | 8 command bullets: brainstorm, spec, plan, run, review, review-spec, pr, update — with one-line roles | Plugin surface: 2 commands + 6 skills = the same 8; descriptions match each frontmatter | match |
| A9 | "Codex users invoke as `$sw-<verb>`; Cursor users as `@sw-<verb>`" + "Non-Claude agents read canonical copies under `.agents/skills/sw-<name>/`" — stated for **all** entries | `.agents/skills/` and `skills/sw/scaffold/skills/` contain exactly 6 dirs (`sw-{brainstorm,plan,pr,review,run,update}`); no `sw-spec`, no `sw-review-spec` anywhere | **mismatch — see F-2** |
| A10 | Mermaid flow (brainstorm → approval → scope → single-issue pipeline / milestone handoff → run loop → shipped) | `brainstorm/SKILL.md` decision graph + `run/SKILL.md` loop | match |
| A11 | AGENTS.md structural contract (self-check): required headers `## Workflow Spec Driven`, `## Coding standard`, `## Skills and slash commands` present; 54 lines ≤ 80 cap; `CLAUDE.md` → `AGENTS.md` symlink (`readlink` = `AGENTS.md`) | `references/audit-checklist.md` + `references/validation.md` checks 1/3/4 | match |

## AC-2 — `skills/sw/references/*.md` verdicts

Mechanical sweep first: `grep -n -E 'design\.md|specs/|sw-specify|sw:specify|/sw:design|spec-flow|sw-brainstorming|sw-writing-plans|sw-new-pr|sw-code-review' skills/sw/references/*.md` → **zero hits** (exit 1). The only legacy mentions anywhere in the five files are the explicitly-labeled legacy-cleanup sections (pre-plugin command files `sw-{spec,review-spec}.md`, pre-rename skill dirs listed as "Legacy skill directories to remove") — exactly the historical/cleanup notes AC-2 exempts.

| Reference | Verdict | Notes |
|---|---|---|
| `audit-checklist.md` | clean | Checks the current layout: 3 vault dirs, AGENTS.md ≤ 80 lines + 3 required headers, CLAUDE.md symlink, the 6 canonical `sw-*` skills, `.gitignore` worktrees line, date-prefix + bare-filename rules (milestone-inner slugs exempt), plugin settings. Legacy mentions are inside cleanup instructions only. |
| `vault-files.md` | clean | "Exactly three directories"; dated standalone folders, plain slugs inside milestones; bare-filename rule; frontmatter shapes for `issue.md`/`spec.md`/`tasks.md`/`goal.md`/`board.md` all match `scaffold/templates/` and `validate-spec.sh`'s checks (status enum, scope enum). No retired artifacts. |
| `validation.md` | clean | "11 numbered checks" — counted: exactly 11. Check 8 lists precisely the 6 shipped skills; check 10 matches `claude-plugin-settings.md` coordinates; check 11 names the 5 shipped templates + `validate-spec.sh`. The PyYAML note matches the vendored scripts in NOTICE.md. |
| `agents-md-template.md` | 2 notes | (1) Template's `### Issue flow` block has drifted from the repo's own AGENTS.md — README demands the two be kept consistent → **F-3**. (2) The template embeds the same blanket `$sw-<verb>` / canonical-copies claim over 8 entries incl. `spec`/`review-spec` → same defect as AGENTS.md → **F-2**. No retired artifacts. |
| `claude-plugin-settings.md` | clean | Coordinates (`specwright` marketplace, `sw` plugin, `sw@specwright` key, github source for targets, directory source for dogfood) match `.claude-plugin/marketplace.json`, `plugins/sw/.claude-plugin/plugin.json`, `.claude/settings.json`, and `install.sh`'s `marketplace_source()`. |

## AC-3 — `validate-spec.sh` fixture matrix

Fixtures built fresh on the unified layout (never in the repo tree), run from the worktree root with `bash skills/sw/scripts/validate-spec.sh <fixture>`; full verbatim log in `evidence/validate-spec-runs.txt`, fixtures byte-identical in `evidence/fixtures/`. Environment: GNU bash 5.3.9, macOS, commit `c291025`.

| Fixture | Defect | Exit | Output | Docs promise honored? |
|---|---|---|---|---|
| `valid-standalone` | none (`milestone: null`) | 0 | `PASS: <dir>` | yes |
| `valid-milestone` | none (`milestone:` path set) | 0 | `PASS: <dir>` | yes |
| `bad-frontmatter` | `status:` deleted from issue.md, `scope:` deleted from spec.md | 3 | `FAIL (check 1): … missing required key: status` + `FAIL (check 1): … status must be one of pending\|in-progress\|shipped\|blocked (got: '')` + `FAIL (check 2): … missing required key: scope` | messages: yes (defect-naming). exit code: **divergent — see F-1** |
| `bad-placeholder` | `{{fill-me-in}}` left in spec.md | 1 | `FAIL (check 3): surviving {{placeholder}} in spec.md: 29:{{fill-me-in}}` (file + line) | yes |
| `bad-uncovered-ac` | issue.md defines AC-3, no task references it | 1 | `FAIL (check 5): AC defined in issue.md but referenced by no task: AC-3` | yes |

Every non-zero run also prints the `FAILED: N check(s) in <dir>` trailer to stderr, and both docs promises hold: `/sw:review-spec`'s "a non-zero exit is a blocking FAIL" and the plan skill's "non-zero exit names the structural defect".

## AC-4 — Findings (Expected / Observed / Proposed fix)

### F-1 — `validate-spec.sh` exit code counts FAIL lines, not failed checks (behavioral, header comment wrong)

- **Expected:** the script header (`skills/sw/scripts/validate-spec.sh` lines 6–7) promises: "otherwise exits with the number of failed **checks** and prints one \"FAIL (check N): <reason>\" line per failure." For `bad-frontmatter`, 2 distinct checks fail (1 and 2) → expected exit 2.
- **Observed:** exit **3**. Check 1 invokes `fail()` twice for one defect chain (missing `status:` key, then the now-empty value failing the enum — the check-1 `case` has no empty-string escape, unlike check 2's `scope` which explicitly allows `""`), and `fails` increments per `fail()` invocation. The `FAILED: 3 check(s)` trailer miscounts the same way.
- **Proposed fix:** either (a) reword the header and trailer to "the number of failures reported (one per FAIL line)", or (b) dedupe the counter per check (e.g. track failed check numbers in a set) so exit = distinct failed checks. Note (b) interacts with the reserved exit 2 (usage / not-a-directory): a two-check failure would collide with it either way — worth an explicit note in the header whichever option is taken. Also decide deliberately whether check 1 should skip the enum test when the key is missing (check 2 already tolerates empty `scope`, an asymmetry that looks accidental).

### F-2 — `$sw-<verb>` / canonical-copies claim overreaches for `spec` and `review-spec`

- **Expected:** per `AGENTS.md` lines 44–46 ("Codex users invoke as `$sw-<verb>`; Cursor users as `@sw-<verb>`. … Non-Claude agents read canonical copies under `.agents/skills/sw-<name>/`"), every one of the 8 listed entries — including `/sw:spec` and `/sw:review-spec` — has a canonical copy a non-Claude agent can invoke.
- **Observed:** `.agents/skills/` and `skills/sw/scaffold/skills/` ship exactly 6 skills (`sw-{brainstorm,plan,pr,review,run,update}`). `spec` and `review-spec` exist only as Claude Code plugin commands (`plugins/sw/commands/*.md`); there is no `sw-spec` or `sw-review-spec` anywhere, so `$sw-spec` / `@sw-review-spec` resolve to nothing. Same blanket claim embedded in `skills/sw/references/agents-md-template.md` (lines 75–77), so every new install reproduces it.
- **Proposed fix:** either annotate the two entries as Claude-plugin-only in `AGENTS.md` and the template (e.g. "`/sw:spec` (Claude Code only — non-Claude agents start from `sw-brainstorm`)"), or ship `sw-spec`/`sw-review-spec` canonical skill copies in the scaffold. The first is smaller and matches current shipped intent.

### F-3 — `### Issue flow` drift: `AGENTS.md` vs `agents-md-template.md`

- **Expected:** README §Customizing: "the flow is documented in `AGENTS.md` under `### Issue flow`. … edit `### Issue flow` in `skills/sw/references/agents-md-template.md` (**keep the two consistent**)."
- **Observed:** 7 diff hunks between the repo's `AGENTS.md` and the template's `### Issue flow`/adjacent blocks. The template lags the evolved wording: missing "(converse first, decide at the end)"; step 3 says owners "**write**" `learnings.md` vs AGENTS.md's "**curates**"; missing "git-ignored; specwright creates worktrees, never removes them"; mermaid node text differs ("→ gates →" vs "→ quality gate → runtime verification"); Coding standard says "issues live in" vs "standalone issues in"; the Skills intro lacks "in this repo's `.claude/settings.json`" (this last one is correct to differ — it is repo-specific).
- **Proposed fix:** sync the template's `### Issue flow` (and mermaid + Coding standard line) with the current `AGENTS.md` wording, leaving out the dogfood-only clause; then the audit's DRIFT detection keeps them aligned going forward.

### F-4 — README license sentence mislabels which scripts are vendored

- **Expected:** per `NOTICE.md`, the vendored Apache-2.0 files are `skills/sw/scripts/quick_validate.py` and `skills/sw/scripts/package_skill.py`; `validate-spec.sh` and `sw-update.sh` in the same directory are original MIT-licensed work.
- **Observed:** README §License: "The vendored **validator scripts** under `skills/sw/scripts/` are Apache-2.0". Read plainly, this covers the whole directory and most naturally points at `validate-spec.sh` — the script the docs elsewhere call "the issue validator" — which is neither vendored nor Apache-2.0; and `package_skill.py` is a packager, not a validator.
- **Proposed fix:** "The vendored scripts under `skills/sw/scripts/` (`quick_validate.py`, `package_skill.py`) are Apache-2.0; see `NOTICE.md`."

### F-5 — README §Repository layout omits shipped top-level entries

- **Expected:** a section titled "Repository layout" accounts for the repo's user-facing top level.
- **Observed:** the tree lists 9 entries and the follow-up paragraph adds `.agents/`, `.claude/`, `.specwright/` — but `install.sh` (the entry point the Install section itself pipes to `sh`), `tests/` (the install test suite, `tests/install/run.sh`), `AGENTS.md`/`CLAUDE.md` (the dogfood contract at the root), and `.github/` appear nowhere.
- **Proposed fix:** add `install.sh` and `tests/` rows to the tree and fold `AGENTS.md`/`CLAUDE.md` into the dogfood paragraph; or retitle to "Repository layout (abridged)".
