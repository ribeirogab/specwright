---
feature: rewrite-sw-init
created: 2026-07-03
---
# Rewrite /sw as /sw:init — Tasks

**For this issue:** see the sibling `issue.md` (acceptance criteria) and `spec.md` (technical plan).

> Each task names the `AC:` (acceptance criteria from `issue.md` it satisfies — every `AC-N` must be referenced by at least one task) and `Delegable:` (whether it suits an isolated task worker, and the one-line context that worker would receive). Workers report findings back to the issue owner; only the owner writes `learnings.md`.

## Phase 1: Rewrite the reference docs

### Task 1: Rename and rewrite the entry-point template

**AC:** AC-2, AC-5, AC-6
**Delegable:** no — feeds directly into Task 3's skill body, needs to be authored with full context of what the skill will say

**Files:**
- Create: `plugins/sw/references/claude-md-template.md`
- Delete: `plugins/sw/references/agents-md-template.md`

- [ ] Step 1: `git mv plugins/sw/references/agents-md-template.md plugins/sw/references/claude-md-template.md`
- [ ] Step 2: Rewrite the file's content — keep the "Filling rules" / "Size constraint" / "Required section headers" prose structure but: (a) target `CLAUDE.md` everywhere `AGENTS.md` appeared, (b) rewrite the template's `## Skills and slash commands` section to state the `sw` plugin is required and name both `claude plugin marketplace add ribeirogab/specwright` and `claude plugin install sw@specwright`, dropping the `.agents/skills/sw-<name>/` canonical-copy line and the Codex/Cursor invocation-syntax callout, (c) keep exactly two double-brace placeholder tokens (project name, project slug) in the template body — no other placeholder token anywhere in the file.
- [ ] Step 3: Search the file for its double-brace marker (open-brace open-brace) — confirm only the two expected placeholders appear (inside the fenced template block, not in prose describing the fill rules).
- [ ] Step 4: `grep -niE '\.claude/settings\.json|extraKnownMarketplaces|enabledPlugins|self-copy|\.codex|\.cursor|\.opencode|\.aider' plugins/sw/references/claude-md-template.md` — confirm zero matches (AC-5).
- [ ] Step 5: Commit.

### Task 2: Rewrite audit-checklist.md and validation.md for the minimal model

**AC:** AC-4, AC-5
**Delegable:** yes — "Rewrite plugins/sw/references/audit-checklist.md and plugins/sw/references/validation.md to describe only a content-only /sw:init: the three .specwright/ vault dirs, the CLAUDE.md entry point (required headers, size cap, plugin-requirement line, no placeholders), and the .gitignore worktrees line. Delete every section about .claude/settings.json, .agents/skills self-copy, per-agent symlinks, and legacy pre-plugin migrations — those describe a repo state that cannot exist in the new model. Read plugins/sw/references/claude-md-template.md first (produced by a sibling task) for the exact section headers to check for. Report back the final section/check list you kept."

- [ ] Step 1: Rewrite `plugins/sw/references/audit-checklist.md` — keep the "Status meanings" and "Report format" sections; keep the "Files and directories to check" list but reduce it to: the three `.specwright/` dirs, `CLAUDE.md` (required section headers, ≤ 80 lines), `.gitignore` (contains the worktrees line). Delete "Per-agent skill symlinks" section, "Legacy command files to remove", "Legacy skill directories to remove", "Claude plugin settings present", and the `CLAUDE.md is a symlink` section entirely (no `AGENTS.md` exists in this model, so no symlink to check). Keep "AGENTS.md drift detection" section but rename it to "CLAUDE.md drift detection" and repoint every mention of `AGENTS.md` at `CLAUDE.md`.
- [ ] Step 2: Rewrite `plugins/sw/references/validation.md` — keep the numbered-checklist shape and "Output format" / "When everything passes" / "When something fails" sections, but reduce the checks to: (1) `CLAUDE.md` has no surviving double-brace placeholders, (2) `CLAUDE.md` contains the required section headers, (3) `CLAUDE.md` is at most 80 lines, (4) `CLAUDE.md` declares the plugin requirement with both install commands, (5) the three vault directories exist (`conventions/` has `README.md`, `issues/` and `milestones/` have `.gitkeep`), (6) `.gitignore` contains the worktrees line exactly once. Delete the `CLAUDE.md`-symlink check, the issue-frontmatter/folder-naming/bare-filename checks (those are `/sw:review-spec`'s and the validator script's job, not init's), the "canonical skills installed" check, the "bundled skill scripts executable" check, the "Claude plugin settings present" check, and the "templates + validator bundled" check (none of that applies once there's no scaffolder copying files into the repo). Renumber the surviving checks 1-6 and update the header count.
- [ ] Step 3: `grep -niE '\.claude/settings\.json|extraKnownMarketplaces|enabledPlugins|self-copy|\.codex|\.cursor|\.opencode|\.aider' plugins/sw/references/audit-checklist.md plugins/sw/references/validation.md` — confirm zero matches (AC-5).
- [ ] Step 4: Commit.

### Task 3: Delete claude-plugin-settings.md

**AC:** AC-5
**Delegable:** no — trivial, faster inline

- [ ] Step 1: `git rm plugins/sw/references/claude-plugin-settings.md`
- [ ] Step 2: `grep -rn 'claude-plugin-settings' plugins/` — confirm no surviving reference to the deleted file from any other skill/command (the `plugin-only-restructure` learnings note nothing else in scope references it, but verify).
- [ ] Step 3: Commit.

## Phase 2: Build the /sw:init skill

### Task 4: Write plugins/sw/skills/init/SKILL.md

**AC:** AC-1, AC-2, AC-3, AC-4, AC-5, AC-6
**Delegable:** no — the core deliverable, needs full context from Tasks 1-3's rewritten docs

**Files:**
- Create: `plugins/sw/skills/init/SKILL.md`

- [ ] Step 1: Write frontmatter — `name: init`, a `description` naming the trigger (`/sw:init`, "initialize specwright in this repo", "set up the vault") and stating it is content-only (vault + CLAUDE.md + gitignore line, no machine configuration).
- [ ] Step 2: Write the vault-scaffold step: create `.specwright/conventions/` (only seed `README.md` when the directory is absent or empty — never overwrite existing content; point at `references/vault-files.md` for the signpost's exact wording/purpose), `.specwright/issues/.gitkeep`, `.specwright/milestones/.gitkeep`. State explicitly this step creates no other file inside `.specwright/`.
- [ ] Step 3: Write the `CLAUDE.md` step: if `CLAUDE.md` does not exist, generate it from `references/claude-md-template.md`, gathering the project-name and project-slug placeholder values from `package.json` `name` (or equivalent manifest) falling back to the repo directory name, asking the user only if neither resolves; if `CLAUDE.md` already exists, check whether it already states the plugin requirement (grep for `claude plugin install sw@specwright`) and only append a short block naming both install commands when absent — never overwrite existing project-authored content.
- [ ] Step 4: Write the `.gitignore` step: append `.specwright/worktrees/` only when a `grep -qxF` check shows the line is not already present; create `.gitignore` if it doesn't exist.
- [ ] Step 5: Write an explicit "Does not do" callout enumerating what the skill never touches: `.claude/settings.json`, `.agents/`, `.codex/`, `.cursor/`, `.opencode/`, `.aider/`, no symlinks of any kind — pointing out these are unnecessary because the plugin serves skills globally.
- [ ] Step 6: Point at `references/vault-files.md` (unchanged) for the vault file specifications, and at `references/audit-checklist.md` + `references/validation.md` (rewritten in Task 2) for what a re-run / audit should verify.
- [ ] Step 7: `grep -niE '\.claude/settings\.json|extraKnownMarketplaces|enabledPlugins|self-copy|\.codex|\.cursor|\.opencode|\.aider' plugins/sw/skills/init/SKILL.md` — confirm zero matches (AC-5).
- [ ] Step 8: Commit.

### Task 5: Register /sw:init in the plugin manifest

**AC:** AC-1
**Delegable:** no — one-line, faster inline

**Files:**
- Modify: `plugins/sw/.claude-plugin/plugin.json`

- [ ] Step 1: Update the `description` field to list `init` among the companion skills (alongside brainstorm, plan, run, review, pr — `update` stays until the sibling issue removes it, per the file-ownership boundary).
- [ ] Step 2: Commit.

## Phase 3: Quality gate and runtime verification

### Task 6: Run the install smoke tests and repo lint

**AC:** (gate, not a specific AC)
**Delegable:** no — needs to see live output to decide on fixes

- [ ] Step 1: `bash tests/install/run.sh` — confirm it still exits 0 (it tests `install.sh`'s bash functions, unrelated to `/sw:init`'s content, so it should be unaffected; if it references any renamed/deleted reference-doc path, fix the reference).
- [ ] Step 2: `grep -rn 'agents-md-template\|claude-plugin-settings' --include='*.md' --include='*.sh' .` — confirm no other file in the repo (skills, commands, README, install.sh) references the renamed/deleted files by their old names; fix any hit found outside this issue's owned files by updating the path if the fix is trivial and in-scope, otherwise note it for the owning issue.
- [ ] Step 3: Commit any fixes.

### Task 7: Runtime-verify AC-1 through AC-4 in a scratch repo

**AC:** AC-1, AC-2, AC-3, AC-4
**Delegable:** no — must observe actual filesystem state, needs to be done by the owner for the PR body

- [ ] Step 1: Create a throwaway scratch repo: `d=$(mktemp -d) && cd "$d" && git init -q`.
- [ ] Step 2: Manually walk through the `/sw:init` skill's steps as written in `plugins/sw/skills/init/SKILL.md` against this scratch repo (since no live plugin install is available in this sandbox, execute the documented bash operations by hand exactly as the skill specifies them) and capture output.
- [ ] Step 3: Inspect the result: `find .specwright -type f`, `cat .specwright/conventions/README.md`, `ls .specwright/issues .specwright/milestones`, `cat CLAUDE.md`, `grep -c '\.specwright/worktrees/' .gitignore`. Confirm AC-1 (conventions/README.md + issues/.gitkeep + milestones/.gitkeep), AC-2 (CLAUDE.md contains both install commands), AC-3 (exactly one worktrees line).
- [ ] Step 4: Re-run the same steps a second time against the same scratch repo; re-check `.gitignore` line count is still exactly 1 (idempotency) and no vault file was clobbered.
- [ ] Step 5: Confirm AC-4 by construction — inspect the scratch repo for `.claude/settings.json`, `.agents/skills/sw`, and any symlink: `[ -e .claude/settings.json ] && echo FOUND || echo absent`; `[ -e .agents/skills/sw ] && echo FOUND || echo absent`; `find . -type l`.
- [ ] Step 6: Clean up the scratch repo (`cd - && rm -rf "$d"`) and record the observed results (paste-ready) for the PR body's runtime-verification section.
- [ ] Step 7: Tick `[x]` on AC-1 through AC-4 in `issue.md` with the observed evidence; if any step could not be executed as a real `/sw:init` invocation (no live plugin harness available), note precisely what was verified (the documented skill steps executed literally) vs. what remains `needs-human-verification` (an actual `/sw:init` slash-command invocation once the plugin is installed) and why.

### Task 8: Verify AC-5 and AC-6 by grep and inspection

**AC:** AC-5, AC-6
**Delegable:** no — quick, feeds directly into the same PR body section as Task 7

- [ ] Step 1: `grep -rniE '\.claude/settings\.json|extraKnownMarketplaces|enabledPlugins|self-copy|\.codex|\.cursor|\.opencode|\.aider' plugins/sw/skills/init/ plugins/sw/references/claude-md-template.md plugins/sw/references/audit-checklist.md plugins/sw/references/validation.md` — confirm zero matches; this is AC-5's literal check.
- [ ] Step 2: Confirm the template file is named `claude-md-template.md` (`ls plugins/sw/references/claude-md-template.md`) and that the scratch-repo `CLAUDE.md` generated in Task 7 has no surviving double-brace token: a literal-string grep for the open-brace-open-brace marker against that generated file returns zero matches.
- [ ] Step 3: Tick `[x]` on AC-5 and AC-6 in `issue.md` with the observed grep/inspection output.

## Phase 4: Deliver

### Task 9: Self-review the plan (mechanical + subagent + review-spec)

**AC:** (gate, not a specific AC)
**Delegable:** no — pipeline step, run by the owner

- [ ] Step 1: `bash plugins/sw/scripts/validate-spec.sh .specwright/milestones/2026-07-03-claude-only-plugin/issues/rewrite-sw-init/` — loop until exit 0.
- [ ] Step 2: Dispatch the spec-document-reviewer subagent per `plugins/sw/skills/plan/spec-document-reviewer-prompt.md`; fix and re-dispatch until Approved.
- [ ] Step 3: Run `/sw:review-spec` over the issue folder; fix any FAIL/WARN worth addressing.
- [ ] Step 4: Commit the plan (spec.md + tasks.md + any gate fixes) before the first implementation commit.

### Task 10: Open the PR and review to lgtm

**AC:** (delivery, not a specific AC)
**Delegable:** no — pipeline step, run by the owner

- [ ] Step 1: Push `feat/rewrite-sw-init`.
- [ ] Step 2: Open the PR via `/sw:pr` against `main`, noting it stacks on `refactor/plugin-only-restructure` (PR #57).
- [ ] Step 3: Run `/sw:review` (three sub-agent lanes on Opus 4.8 at xhigh effort per the board's conduction policy) until `lgtm`; fix blockers.
- [ ] Step 4: Curate `learnings.md`, flip `issue.md` `status: shipped` + `shipped: 2026-07-03`, commit.
