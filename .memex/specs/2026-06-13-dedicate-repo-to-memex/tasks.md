---
feature: dedicate-repo-to-memex
plan: "[[2026-06-13-dedicate-repo-to-memex/plan|plan]]"
spec: "[[2026-06-13-dedicate-repo-to-memex/spec|spec]]"
created: 2026-06-13
---
# Dedicate Repo to Memex — Tasks

**For this plan:** `[[2026-06-13-dedicate-repo-to-memex/plan|plan]]`

Work on branch `feat/dedicate-repo-to-memex` (already created; the spec is committed there). No test runner exists — verification steps are shell/grep assertions and the memex Phase-5 validator. Every task ends with a Conventional-Commits commit, **no AI-attribution footer**.

**`<MKT>` = the marketplace name resolved in Phase 0** (`memex` if not reserved, else `ribeirogab-memex`). Substitute the resolved value everywhere `<MKT>` appears before running Phase 3+.

**Rename ordering rule (avoid string corruption — see `[[../../learnings/sed-rename-pattern-completeness|sed-rename-pattern-completeness]]`):** always replace the compound strings before the bare word, in this order per file:
1. `ribeirogab/agent-skills` → `ribeirogab/memex` (install slug)
2. `ribeirogab-agent-skills` → `<MKT>` (marketplace name)
3. remaining bare `agent-skills` → `memex` (titles/prose)

---

## Phase 0: Marketplace-name gate

### Task 0.1: Resolve `<MKT>` via reservation test

**Files:** `.claude-plugin/marketplace.json` (temporary probe edit, finalized in Task 3.1)

- [x] **Step 1: Set the candidate name to `memex`**

Edit `.claude-plugin/marketplace.json` line 2: `"name": "ribeirogab-agent-skills",` → `"name": "memex",`

- [x] **Step 2: Install-test the name**

Run (the reservation check fires here, not at file-write):
```bash
claude plugin marketplace add . 2>&1 | tee /tmp/mkt-test.txt
```
- **No error** → `memex` is usable. Set `<MKT> = memex`. Then clean up the probe registration:
  ```bash
  claude plugin marketplace remove memex 2>/dev/null || true
  ```
- **Output contains `is reserved for official Anthropic marketplaces`** → `memex` is reserved. Set `<MKT> = ribeirogab-memex` and edit line 2 to `"name": "ribeirogab-memex",`.

If the `claude` CLI requires interactive trust and cannot run head-less here, ask the maintainer to run the command and paste the result (`! claude plugin marketplace add .`).

- [x] **Step 3: Record the decision**

Note the resolved `<MKT>` value and the exact CLI output in the eventual PR description (acceptance criterion #1). Do **not** commit yet — Task 3.1 finalizes `marketplace.json` together with the rest of the cascade. Leave the probe edit in place.

---

## Phase 1: Relocate validation scripts (before deleting skill-improver)

### Task 1.1: `git mv` the validators into memex

**Files:**
- Move: `skills/skill-improver/scripts/quick_validate.py` → `skills/memex/scripts/quick_validate.py`
- Move: `skills/skill-improver/scripts/package_skill.py` → `skills/memex/scripts/package_skill.py`
- Move: `skills/skill-improver/scripts/__init__.py` → `skills/memex/scripts/__init__.py`

- [x] **Step 1: Create the destination and move all three files with history**

```bash
mkdir -p skills/memex/scripts
git mv skills/skill-improver/scripts/quick_validate.py skills/memex/scripts/quick_validate.py
git mv skills/skill-improver/scripts/package_skill.py skills/memex/scripts/package_skill.py
git mv skills/skill-improver/scripts/__init__.py skills/memex/scripts/__init__.py
```

- [x] **Step 2: Verify the scripts run from the new location**

```bash
python skills/memex/scripts/quick_validate.py skills/memex
```
Expected: `Skill is valid!`

```bash
python skills/memex/scripts/package_skill.py skills/memex /tmp
```
Expected: ends with `Successfully packaged skill to: /tmp/memex.skill`

- [x] **Step 3: Verify history followed the move**

```bash
git log --follow --oneline skills/memex/scripts/quick_validate.py | head -3
```
Expected: shows commits predating this move (not a single "add" commit).

- [x] **Step 4: Commit**

```bash
git add skills/memex/scripts/
git commit -m "chore(memex): relocate skill validators into skills/memex/scripts/"
```

---

## Phase 2: Delete non-memex skills

### Task 2.1: Delete skill-improver (skill + symlink)

**Files:**
- Delete: `skills/skill-improver/` (now scriptless)
- Delete: `.claude/skills/skill-improver` (symlink)

- [x] **Step 1: Remove the skill and its symlink**

```bash
git rm -r skills/skill-improver
git rm .claude/skills/skill-improver
```

- [x] **Step 2: Verify no live skill-improver files remain**

```bash
find . -path ./.git -prune -o -name '*skill-improver*' -print
```
Expected: only matches inside `.vault/specs/` (historical) — no `skills/`, `.claude/`, or `evals/` paths yet (evals removed in 2.2).

- [x] **Step 3: Commit**

```bash
git commit -m "feat(repo)!: delete skill-improver (memex-only dedication)"
```

### Task 2.2: Delete the evals directory

**Files:** Delete: `evals/` (only contains `evals/skill-improver/`)

- [x] **Step 1: Remove**

```bash
git rm -r evals
```

- [x] **Step 2: Verify gone**

```bash
test ! -e evals && echo "evals removed"
```
Expected: `evals removed`

- [x] **Step 3: Commit**

```bash
git commit -m "chore(repo): drop evals/ (only held skill-improver harness)"
```

### Task 2.3: Delete vendored maintainer-local skills

**Files:**
- Delete: `.claude/skills/skill-creator/`
- Delete: `.claude/skills/opensource-guide-coach/`

- [x] **Step 1: Remove both vendored dirs**

```bash
git rm -r .claude/skills/skill-creator .claude/skills/opensource-guide-coach
```

- [x] **Step 2: Verify `.claude/skills/` is memex-only and resolves**

```bash
ls .claude/skills/
for f in .claude/skills/*; do [ -e "$f" ] || echo "BROKEN $f"; done
```
Expected: `ls` prints exactly `memex`; the loop prints nothing.

- [x] **Step 3: Commit**

```bash
git commit -m "chore(repo): remove vendored skill-creator and opensource-guide-coach"
```

---

## Phase 3: Rename cascade — marketplace name + install slug

> Run only after Phase 0 resolved `<MKT>`. Apply the 3-step ordering rule per file.

### Task 3.1: Finalize marketplace.json

**Files:** Modify: `.claude-plugin/marketplace.json`

- [x] **Step 1: Confirm the `name` field matches `<MKT>`**

From Phase 0 the probe edit already set line 2 to `"name": "memex",` (or `"ribeirogab-memex"`). Confirm it equals `<MKT>`. No slug appears in this file. The plugin entry `"name": "memex"` (line 8) stays unchanged.

- [x] **Step 2: Verify**

```bash
jq -r '.name' .claude-plugin/marketplace.json
```
Expected: the `<MKT>` value.

- [x] **Step 3: Commit** (deferred — committed with Task 3.2 since both are tiny config files)

### Task 3.2: Rewrite `.claude/settings.json` keys

**Files:** Modify: `.claude/settings.json`

- [x] **Step 1: Replace both keys**

Edit so the file reads (with `<MKT>` substituted):
```json
{
  "enabledPlugins": {
    "memex@<MKT>": true
  },
  "extraKnownMarketplaces": {
    "<MKT>": {
      "source": {
        "source": "directory",
        "path": "."
      }
    }
  }
}
```

- [x] **Step 2: Verify**

```bash
jq -e '.enabledPlugins["memex@<MKT>"] == true and (.extraKnownMarketplaces | has("<MKT>"))' .claude/settings.json
```
Expected: `true`

- [x] **Step 3: Commit**

```bash
git add .claude-plugin/marketplace.json .claude/settings.json
git commit -m "feat(plugin)!: rename marketplace ribeirogab-agent-skills -> <MKT>"
```

### Task 3.3: Cascade through `skills/memex/SKILL.md`

**Files:** Modify: `skills/memex/SKILL.md` (occurrences at lines 114, 139, 165, 167, 170, 182, 183)

- [x] **Step 1: Apply the ordered replacements**

```bash
perl -pi -e 's{ribeirogab/agent-skills}{ribeirogab/memex}g; s{ribeirogab-agent-skills}{<MKT>}g' skills/memex/SKILL.md
```
(There is no bare `agent-skills` in SKILL.md outside the compounds — the two patterns cover all 7 occurrences. Line 170's `MARKETPLACE_SOURCE='{"source":"github","repo":"ribeirogab/agent-skills"}'` becomes `ribeirogab/memex`; the dogfood check on line 167 comparing against the marketplace name becomes `<MKT>`.)

- [x] **Step 2: Verify**

```bash
grep -nE "ribeirogab-agent-skills|ribeirogab/agent-skills" skills/memex/SKILL.md || echo "clean"
```
Expected: `clean`

- [x] **Step 3: Commit** (deferred — committed with Task 3.4)

### Task 3.4: Cascade through the four reference docs

**Files:** Modify:
- `skills/memex/references/claude-plugin-settings.md`
- `skills/memex/references/audit-checklist.md`
- `skills/memex/references/validation.md`
- `skills/memex/references/agents-md-template.md`

- [x] **Step 1: Apply the ordered replacements to all four**

```bash
for f in skills/memex/references/claude-plugin-settings.md \
         skills/memex/references/audit-checklist.md \
         skills/memex/references/validation.md \
         skills/memex/references/agents-md-template.md; do
  perl -pi -e 's{ribeirogab/agent-skills}{ribeirogab/memex}g; s{ribeirogab-agent-skills}{<MKT>}g' "$f"
done
```

- [x] **Step 2: Verify the whole memex skill is clean**

```bash
grep -rnE "ribeirogab-agent-skills|ribeirogab/agent-skills" skills/memex/ || echo "clean"
```
Expected: `clean`

- [x] **Step 3: Verify the dogfood detection is internally consistent**

`claude-plugin-settings.md:88` describes detecting the marketplace repo by checking `name = "<MKT>"`; confirm it now reads `<MKT>` and matches `SKILL.md:167`.

- [x] **Step 4: Commit**

```bash
git add skills/memex/SKILL.md skills/memex/references/
git commit -m "feat(memex)!: cascade marketplace/slug rename through skill source"
```

---

## Phase 5: Docs prose pivot

> Identity titles (`# agent-skills` → `# memex`) live in the prose files and are rewritten in-place by the tasks below (README 5.1, AGENTS 5.2) and in Phase 6 (constitution 6.1, vault indexes 6.2). There is no separate "rename titles" task — the rewrites replace the title in the same edit.

### Task 5.1: Rewrite README.md (memex-only)

**Files:** Modify: `README.md`

- [x] **Step 1: Replace the entire file** with:

```markdown
# memex

An externalized, navigable project memory for coding agents — Claude Code, Codex, Cursor, OpenCode, Gemini CLI, Aider, and any other tool that supports the open agent skills standard. `memex` is a single skill that idempotently scaffolds a `.vault/` knowledge vault, an `AGENTS.md` (with a `CLAUDE.md` symlink for back-compat), spec/plan/task templates, and a set of bundled companion skills + slash commands into any repository — then dogfoods that same memory on its own development.

> Personal project, solo maintenance, best-effort, no SLA. Published so anyone can install it.

---

## Install

```bash
npx skills add ribeirogab/memex --skill memex
```

## Use

Point an agent at any repo where you want the memex installed:

> "Audit the memex in this repo and scaffold whatever is missing."

The skill is audit-first, autonomous-fix, and safe to re-run. After the first run the repo has a working `.vault/` vault, the bundled `memex-*` companion skills, the `/memex:*` slash commands, and an `AGENTS.md` — all dogfood-tested by the memex's own Phase-5 validator.

**Source:** [`skills/memex/SKILL.md`](skills/memex/SKILL.md)

## Repository layout

```
memex/
├── skills/memex/            # the skill: SKILL.md, references/, scaffold/, scripts/
├── plugins/memex/           # Claude Code plugin — the /memex:* slash commands
├── .claude-plugin/          # marketplace manifest
├── LICENSE                  # MIT
├── NOTICE.md                # attribution for vendored validator scripts
├── CONTRIBUTING.md
├── CODE_OF_CONDUCT.md
├── SECURITY.md
└── README.md
```

The repository also contains `.agents/`, `.claude/`, and `.vault/` — local dirs used to dogfood memex on its own development (the bundled companion skills, the per-agent symlinks, and the maintainer's knowledge vault). They are not what `npx skills add` installs.

## License

This repository's original work is licensed under the [MIT License](LICENSE). The vendored validator scripts under `skills/memex/scripts/` are Apache-2.0; see [`NOTICE.md`](NOTICE.md) for attribution.

## Contributing

Pull requests welcome — see [`CONTRIBUTING.md`](CONTRIBUTING.md) for scope, the quality bar, and the per-PR checklist. By participating, you agree to the [Code of Conduct](CODE_OF_CONDUCT.md). Security concerns go to [`SECURITY.md`](SECURITY.md).
```

- [x] **Step 2: Verify**

```bash
grep -c "^## Skills" README.md            # expect 0
grep -c "skill-improver" README.md         # expect 0
grep -cE "ribeirogab-agent-skills|ribeirogab/agent-skills" README.md   # expect 0
grep -c "ribeirogab/memex" README.md       # expect 1
```

- [x] **Step 3: Commit**

```bash
git add README.md
git commit -m "docs(readme)!: reframe as memex-only, drop multi-skill catalog"
```

### Task 5.2: Rewrite AGENTS.md title + opening

**Files:** Modify: `AGENTS.md` (`CLAUDE.md` symlink propagates)

- [x] **Step 1: Replace line 1** `# agent-skills — Agent Instructions` → `# memex — Agent Instructions`

- [x] **Step 2: Replace the opening paragraph (line 3)** with:

```markdown
This repository **is** memex — a single agent skill that idempotently installs an externalized project memory (a "memex") into any repo: a `.vault/` knowledge vault, an `AGENTS.md`, spec/plan/task templates, and bundled companion skills + slash commands. It is written in markdown with occasional shell scripts; there is no build system, no package manager, and no test runner at the repo root. The skill source lives under `skills/memex/`; its bundled companion skills live canonically under `.agents/skills/memex-*/` and are exposed via per-agent symlinks (`.claude/skills/<name>` → `.agents/skills/<name>`); the `/memex:*` slash commands ship as a Claude Code plugin (`plugins/memex/`). The repo dogfoods its own memex.
```

- [x] **Step 3: Fix the marketplace reference in the "Skills and slash commands" section (line 64)**

```bash
perl -pi -e 's{ribeirogab-agent-skills}{<MKT>}g' AGENTS.md
```

- [x] **Step 4: Verify the CLAUDE.md symlink survived and identifiers are clean**

```bash
test -L CLAUDE.md && [ "$(readlink CLAUDE.md)" = "AGENTS.md" ] && echo "symlink ok"
grep -nE "agent-skills" AGENTS.md || echo "clean"
```
Expected: `symlink ok`, then `clean`.

- [x] **Step 5: Commit**

```bash
git add AGENTS.md
git commit -m "docs(agents)!: reframe AGENTS.md as memex-only"
```

### Task 5.3: Narrow CONTRIBUTING.md scope + repoint validators

**Files:** Modify: `CONTRIBUTING.md`

- [x] **Step 1: Line 3** — replace the intro:
`Thanks for considering a contribution to \`agent-skills\`. The repository accepts pull requests for the published skills under [\`skills/\`](skills/) and for the documentation that supports them, with a small quality bar that this document explains.`
→
`Thanks for considering a contribution to \`memex\`. The repository accepts pull requests for the \`memex\` skill (and its bundled companions) and the documentation that supports them, with a small quality bar that this document explains.`

- [x] **Step 2: Lines 10-13 (in-scope)** — replace the first bullet:
`- **Bug fixes and improvements to any skill under \`skills/\`** — including bundled payloads (e.g., scaffold content the skill copies into a target repo, or vendored helper scripts the skill ships).`
→
`- **Bug fixes and improvements to \`memex\`** — including bundled payloads (the scaffold content it copies into target repos, the bundled companion skills under \`.agents/skills/memex-*/\`, and the vendored validator scripts under \`skills/memex/scripts/\`).`

- [x] **Step 3: Line 17 (out-of-scope)** — replace:
`- **New unrelated top-level skills.** This is a curated personal collection. Open an issue first if you think a new skill belongs here; otherwise the [skills CLI](https://github.com/vercel-labs/skills) makes any public GitHub repo installable, so a separate repo is usually the right home.`
→
`- **Skills unrelated to memex.** This repository is dedicated to memex. The [skills CLI](https://github.com/vercel-labs/skills) makes any public GitHub repo installable, so publish unrelated skills from your own repo.`

- [x] **Step 4: Lines 30-42 (quality bar)** — repoint the script paths and drop the "invoke the skill-improver skill" paragraph. Replace the block from line 30 through line 42 with:

```markdown
Mechanical checks must pass on the modified skill before the PR is opened. Both scripts are vendored copies of the canonical authoring validators (Apache-2.0, see [`NOTICE.md`](NOTICE.md)) and ship under `skills/memex/scripts/`:

```bash
python skills/memex/scripts/quick_validate.py skills/<the-skill-you-changed>
# expected output: "Skill is valid!"

python skills/memex/scripts/package_skill.py skills/<the-skill-you-changed> /tmp
# expected output: ends with "Successfully packaged skill to: /tmp/<skill-name>.skill"
```

`quick_validate.py` enforces the frontmatter contract (kebab-case `name`, `description` ≤ 1024 chars, no XML angle brackets, no reserved words, only canonical top-level keys). `package_skill.py` re-runs that validation and additionally confirms the skill packages cleanly into a `.skill` artifact (no broken file references, no excluded patterns left behind).
```

- [x] **Step 5: Line 49 (PR-checklist explainer)** — the wording "on every modified skill" still holds; just confirm it no longer names `skill-improver`. No edit needed unless it does.

- [x] **Step 6: Verify**

```bash
grep -cE "curated personal collection|any skill under" CONTRIBUTING.md   # expect 0
grep -c "skills/skill-improver" CONTRIBUTING.md                          # expect 0
grep -c "skills/memex/scripts" CONTRIBUTING.md                           # expect >=1
grep -nE "agent-skills" CONTRIBUTING.md || echo clean
```

- [x] **Step 7: Commit**

```bash
git add CONTRIBUTING.md
git commit -m "docs(contributing)!: narrow scope to memex, repoint validators"
```

### Task 5.4: Reword SECURITY.md

**Files:** Modify: `SECURITY.md`

- [x] **Step 1: Line 5** — `If you find a security issue in any skill in this repository` → `If you find a security issue in memex or its bundled companions`.
- [x] **Step 2: Line 9** — `- The skill affected (path under \`skills/\`).` → `- The affected component (the \`memex\` skill, a bundled companion, or a script).`
- [x] **Step 3: Line 24** — `- Skills under [\`skills/\`](skills/) — the published surface that \`npx skills add\` installs.` → `- The \`memex\` skill under [\`skills/memex/\`](skills/memex/) — the published surface that \`npx skills add\` installs, plus its bundled companions under \`.agents/skills/memex-*/\`.`
- [x] **Step 4: Line 29** — drop `evals/` from the out-of-scope dir list: `The \`.agents/\`, \`.claude/\`, \`.vault/\`, and \`evals/\` directories` → `The \`.agents/\`, \`.claude/\`, and \`.vault/\` directories`.
- [x] **Step 5: Line 34** — `Skills in this repository are markdown instructions loaded by an agent` → `memex and its bundled companions are markdown instructions loaded by an agent`.

- [x] **Step 6: Verify**

```bash
grep -c "evals/" SECURITY.md   # expect 0
```

- [x] **Step 7: Commit**

```bash
git add SECURITY.md
git commit -m "docs(security): scope policy to memex"
```

### Task 5.5: Prune NOTICE.md

**Files:** Modify: `NOTICE.md`

- [x] **Step 1: Replace the whole file** with (keeps the Apache-2.0 attribution at its new path, drops the maintainer-local section since those dirs are deleted):

```markdown
# NOTICE — Vendored content attribution

memex is licensed under the MIT License, the same as the repository as a whole — see [`LICENSE`](LICENSE).

It includes a small amount of third-party content vendored from a public open-source repository, preserved with its original license and copyright notice; modifications are documented below.

## Vendored under `skills/memex/scripts/`

memex bundles two scripts vendored from `anthropics/skills` so the skill is self-contained and does not depend on the upstream project being installed alongside it:

| Field | Value |
|---|---|
| Files | `skills/memex/scripts/quick_validate.py`, `skills/memex/scripts/package_skill.py` |
| Original source | [https://github.com/anthropics/skills/tree/main/skill-creator/scripts](https://github.com/anthropics/skills/tree/main/skill-creator/scripts) |
| Original license | Apache-2.0 |
| Copyright holder | Anthropic |
| Modifications | `quick_validate.py` is verbatim. `package_skill.py` has one change vs upstream: the `from scripts.quick_validate import validate_skill` line is replaced with `sys.path.insert(0, str(Path(__file__).parent))` followed by `from quick_validate import validate_skill`, so the file works whether invoked as `python -m scripts.package_skill`, `python scripts/package_skill.py`, or by absolute path. The change is documented inline in the file's module docstring. |

## License compatibility

The repository as a whole is licensed under MIT (see [`LICENSE`](LICENSE)). MIT is compatible with the Apache-2.0 vendored scripts: Apache-2.0 permits redistribution under these terms provided the license and notices are retained, which they are above.
```

- [x] **Step 2: Verify**

```bash
grep -c "opensource-guide-coach" NOTICE.md     # expect 0
grep -c "skill-creator" NOTICE.md              # expect 0
grep -c "skills/memex/scripts" NOTICE.md       # expect >=1
```

- [x] **Step 3: Commit**

```bash
git add NOTICE.md
git commit -m "docs(notice): keep Apache-2.0 attribution at new path, drop removed vendored skills"
```

### Task 5.6: Repurpose the issue template + fix the PR template

**Files:**
- Rename + rewrite: `.github/ISSUE_TEMPLATE/skill_request.md` → `.github/ISSUE_TEMPLATE/feature_request.md`
- Modify: `.github/PULL_REQUEST_TEMPLATE.md`

- [x] **Step 1: Move the issue template**

```bash
git mv .github/ISSUE_TEMPLATE/skill_request.md .github/ISSUE_TEMPLATE/feature_request.md
```

- [x] **Step 2: Replace its contents** with:

```markdown
---
name: Feature request
about: Suggest an improvement to memex or a new bundled companion skill
title: "[feature] "
labels: ["enhancement"]
---

## What should memex do?

Describe the improvement to the `memex` skill, a bundled companion (`memex-brainstorming`, `memex-recall`, `memex-writing-plans`, `memex-link`), or a `/memex:*` command. Two or three concrete example prompts beat one abstract description.

## Why does it belong in memex?

Explain how it serves the externalized-project-memory goal. Unrelated skills should be published from their own repo — the [skills CLI](https://github.com/vercel-labs/skills) makes any public GitHub repo installable.

## Sketch of the behavior

Two or three bullets describing what the agent would do. No need to draft the SKILL.md here — the goal is to confirm scope first.

## Are you willing to author it?

Yes / No / Maybe. Either is fine — this issue is useful as a backlog signal even if no one has time today.
```

- [x] **Step 3: Fix `.github/PULL_REQUEST_TEMPLATE.md`** — three edits:
  - Lines 7-8: `skills/skill-improver/scripts/quick_validate.py` → `skills/memex/scripts/quick_validate.py` and `skills/skill-improver/scripts/package_skill.py` → `skills/memex/scripts/package_skill.py`.
  - Line 15: delete the entire line `- [x] \`README.md\`'s \`## Skills\` section was updated if a skill was added or removed.`
  - Line 17: `No edits under \`.vault/\`, \`.agents/\`, \`.claude/\`, or \`evals/\`` → `No edits under \`.vault/\`, \`.agents/\`, or \`.claude/\``.

- [x] **Step 4: Verify**

```bash
test ! -e .github/ISSUE_TEMPLATE/skill_request.md && echo "renamed"
grep -rInE "skill-improver|skills/skill-improver" .github/ || echo "clean"
grep -c "## Skills" .github/PULL_REQUEST_TEMPLATE.md   # expect 0
grep -c "evals/" .github/PULL_REQUEST_TEMPLATE.md      # expect 0
```

- [x] **Step 5: Commit**

```bash
git add .github/
git commit -m "docs(github): repurpose issue template, fix PR template paths"
```

---

## Phase 6: Constitution + vault rewrite

### Task 6.1: Rewrite constitution.md

**Files:** Modify: `.vault/constitution.md`

- [x] **Step 1: Line 5 title** — `# agent-skills — Constitution` → `# memex — Constitution`

- [x] **Step 2: Replace the "Why agent-skills exists" section (heading + body, lines ~11-15)** with:

```markdown
## Why memex exists

`memex` is a single agent skill that idempotently installs a project *memex* — an externalized, navigable project memory — into any repository: a `.vault/` knowledge vault, an `AGENTS.md`, spec/plan/task templates, and a set of bundled companion skills and slash commands. (The name is Vannevar Bush's *memex*, 1945 — an externalized, navigable personal memory.)

This repository **is** memex: the skill's source, its bundled companions, its Claude Code distribution surface (marketplace + plugin), and the `.vault/` that dogfoods the skill on its own development. The repo's purpose is singular — build and ship memex — and it dogfoods memex on itself so the maintainer trusts what is shipped.
```

- [x] **Step 3: Rewrite the "Scope guardrails" section** — replace the in-scope/out-of-scope/symlink bullets with:

```markdown
- **In scope**: the `memex` skill under `skills/memex/` (including `skills/memex/scaffold/`, `skills/memex/references/`, and `skills/memex/scripts/`), the bundled companion skills under `.agents/skills/memex-*/`, and the Claude Code distribution surface (`.claude-plugin/marketplace.json` and `plugins/memex/`).
- **Out of scope**: any skill unrelated to memex, application code, and anything not directly related to authoring or distributing memex.
- **Symlink discipline**: the bundled companions are canonical under `.agents/skills/memex-*/` and exposed via one symlink per skill under each agent discovery dir (`.claude/skills/<name>`, `.codex/skills/<name>`, etc.). The `memex` skill itself is dogfooded onto the maintainer's agent via `.claude/skills/memex` → `skills/memex/`. **Never** map an entire agent dir to `skills/` or `.agents/skills/` with a blanket symlink — only one symlink per skill, named after the skill.
- **No build pipeline**: this repo intentionally has no `package.json`, no transpiler, no test runner. memex is markdown + occasional shell/Python scripts and must stay that way unless a clear need overrides this rule.
```

- [x] **Step 4: Line ~28 (Idempotency principle)** — `the \`memex\` skill (and any future scaffolding skill) must be safe to re-run` → `the \`memex\` skill must be safe to re-run`.

- [x] **Step 5: Line ~26 (Skills are self-contained)** — reword `every skill under \`skills/<name>/\`` → `memex (under \`skills/memex/\`) and each bundled companion ship` to keep the self-containment principle without implying a catalog.

- [x] **Step 6: Line ~48 (Knowledge layering)** — `things unique to agent-skills (e.g. how the memex symlink works, conventions for authoring new skills)` → `things unique to memex (e.g. how the memex symlink works, how the scaffold layer embeds the marketplace coordinates)`.

- [x] **Step 7: Verify**

```bash
grep -c "library of skills" .vault/constitution.md          # expect 0
grep -c "any future scaffolding skill" .vault/constitution.md   # expect 0
grep -c "skill-creator\|opensource-guide-coach" .vault/constitution.md   # expect 0
grep -nE "agent-skills" .vault/constitution.md || echo clean
```

- [x] **Step 8: Commit**

```bash
git add .vault/constitution.md
git commit -m "docs(constitution)!: rewrite as memex-only project charter"
```

### Task 6.2: Reframe home.md + fix vault index titles

**Files:** Modify: `.vault/_index/home.md`, `.vault/_index/learnings.md`, `.vault/_index/conventions.md`, `.vault/_index/rules.md`, `.vault/_index/specs.md`

- [x] **Step 1: home.md** — line 5 `# agent-skills — Project Knowledge Vault` → `# memex — Project Knowledge Vault`; line 7 `all project-specific knowledge for agent-skills` → `all project-specific knowledge for memex`.

- [x] **Step 2: Replace bare `agent-skills` in the other four index headers**

```bash
for f in .vault/_index/learnings.md .vault/_index/conventions.md .vault/_index/rules.md .vault/_index/specs.md; do
  perl -pi -e 's{\bagent-skills\b}{memex}g' "$f"
done
```
(These occurrences are MOC header text like "all specs for agent-skills features" — the substitution to "memex" reads correctly. Review each diff to confirm none sit inside a code block or a path.)

- [x] **Step 3: Verify**

```bash
grep -rnE "\bagent-skills\b" .vault/_index/ || echo clean
```
Expected: `clean`

- [x] **Step 4: Commit** (deferred — committed with Task 6.3 since both touch the indexes)

### Task 6.3: Delete the 6 craft notes + clean the MOCs

**Files:**
- Delete: `.vault/learnings/skill-development-workflow.md`, `.vault/learnings/skill-progressive-disclosure.md`, `.vault/learnings/skill-degrees-of-freedom.md`, `.vault/learnings/generator-evaluator-separation.md`
- Delete: `.vault/conventions/skill-directory-layout.md`, `.vault/conventions/skill-md-style.md`
- Modify: `.vault/_index/learnings.md`, `.vault/_index/conventions.md`, and any surviving note whose `related:` links to a deleted note

- [x] **Step 1: Delete the six notes**

```bash
git rm .vault/learnings/skill-development-workflow.md \
       .vault/learnings/skill-progressive-disclosure.md \
       .vault/learnings/skill-degrees-of-freedom.md \
       .vault/learnings/generator-evaluator-separation.md \
       .vault/conventions/skill-directory-layout.md \
       .vault/conventions/skill-md-style.md
```

- [x] **Step 2: Find every inbound reference to the deleted notes**

```bash
grep -rnE "skill-development-workflow|skill-progressive-disclosure|skill-degrees-of-freedom|generator-evaluator-separation|skill-directory-layout|skill-md-style" .vault --include='*.md' | grep -v ".vault/specs/"
```

- [x] **Step 3: Remove the MOC list-entries** for the deleted notes from `.vault/_index/learnings.md` and `.vault/_index/conventions.md` (delete the bullet lines that link to them).

- [x] **Step 4: Fix dangling `related:` wikilinks** in any surviving note the grep surfaced — remove the wikilink to the deleted note from its `related:` frontmatter list.

- [x] **Step 5: Verify no dangling links outside historical specs**

```bash
grep -rnE "skill-development-workflow|skill-progressive-disclosure|skill-degrees-of-freedom|generator-evaluator-separation|skill-directory-layout|skill-md-style" .vault --include='*.md' | grep -v ".vault/specs/" || echo clean
```
Expected: `clean`

- [x] **Step 6: Commit**

```bash
git add .vault/_index/ .vault/learnings/ .vault/conventions/
git commit -m "docs(vault): drop skill-authoring craft notes, reframe indexes for memex"
```

### Task 6.4: Per-occurrence review of kept learnings

**Files:** Modify (judgment): `.vault/learnings/claude-code-extra-known-marketplaces-source-schema.md`, `.vault/learnings/vendoring-a-single-skill-loses-upstream-license.md`, `.vault/learnings/harness-engineering-foundations.md`

- [x] **Step 1: Inspect each occurrence**

```bash
grep -nE "agent-skills" .vault/learnings/claude-code-extra-known-marketplaces-source-schema.md \
                        .vault/learnings/vendoring-a-single-skill-loses-upstream-license.md \
                        .vault/learnings/harness-engineering-foundations.md
```

- [x] **Step 2: Apply per-occurrence judgment.** For each line: if `agent-skills` / `ribeirogab-agent-skills` / `ribeirogab/agent-skills` names *this project's current identity* (e.g. an example marketplace coordinate that should stay accurate), update it to `memex` / `<MKT>` / `ribeirogab/memex`. If it describes a *past event* ("the marketplace was renamed to `ribeirogab-agent-skills`") leave it as frozen history. Note: `claude-code-reserved-marketplace-names.md` is explicitly out of scope (frozen historical record) and is not in this list.

- [x] **Step 3: Commit**

```bash
git add .vault/learnings/
git commit -m "docs(vault): update kept learnings' live agent-skills references to memex"
```

---

## Phase 7: Validate + handoff

### Task 7.1: Repo-wide cascade verification

- [x] **Step 1: No active `agent-skills` survivors**

```bash
grep -rIn "agent-skills" --exclude-dir=.git . \
  | grep -v ".vault/specs/" \
  | grep -v "claude-code-reserved-marketplace-names" \
  || echo "clean"
```
Expected: `clean` (only the allowed survivors remain — historical specs and the reserved-names learning).

- [x] **Step 2: Marketplace + slug fully cascaded**

```bash
grep -rIn "ribeirogab-agent-skills" --exclude-dir=.git . | grep -vE "\.vault/specs/|claude-code-reserved-marketplace-names" || echo "clean"
grep -rIn "ribeirogab/agent-skills" --exclude-dir=.git . | grep -v "\.vault/specs/" || echo "clean"
```
Expected: both `clean`.

### Task 7.2: memex Phase-5 validation

- [x] **Step 1: Run the validator checklist** in `skills/memex/references/validation.md` against this repo (the `.claude/settings.json` checks now expect `<MKT>` and `memex@<MKT>`).

- [x] **Step 2: Re-run the marketplace add** to confirm the live plugin still loads under `<MKT>`:

```bash
claude plugin marketplace add . 2>&1 | tail -3
```
Expected: no reservation error; the `memex` plugin resolves. (If interactive, hand to the maintainer.)

### Task 7.3: GitHub repo rename (maintainer action)

- [x] **Step 1: Hand the maintainer the command** — they run, in this repo:

```bash
gh repo rename memex
```
This renames `ribeirogab/agent-skills` → `ribeirogab/memex` on GitHub and updates the local `origin` remote. GitHub keeps a redirect for `git clone`.

- [x] **Step 2: Verify the remote**

```bash
git remote get-url origin
```
Expected: `…ribeirogab/memex…`. (If the maintainer hasn't run the rename yet, note it as a pending handoff item in the PR, not a blocker for merge.)

### Task 7.4: Ship — spec status + reflection (same PR)

- [x] **Step 1: Flip the spec frontmatter** in `spec-dedicate-repo-to-memex.md`: `status: draft` → `status: shipped`, `shipped: null` → `shipped: 2026-06-13`, and update the `**Status:**` line in the body. Move the spec from "Active" to "Shipped" in `.vault/_index/specs.md`.

- [x] **Step 2: Reflection** — per the after-completing-a-spec rule, write a learning note for anything non-obvious discovered (e.g. whether `memex` was reserved, any cascade-ordering gotcha), with a `related:` backlink to this spec; or state "No new learnings from this spec" in the PR description if nothing surfaced.

- [x] **Step 3: Commit + open PR**

```bash
git add .vault/specs/2026-06-13-dedicate-repo-to-memex/ .vault/_index/specs.md .vault/learnings/
git commit -m "docs(spec): mark dedicate-repo-to-memex shipped"
```
Open the PR with `/create-pr` (or `gh pr create`); the description records the resolved `<MKT>`, the Phase-0 CLI output, and the reflection outcome. **Do not push to `main`.**
