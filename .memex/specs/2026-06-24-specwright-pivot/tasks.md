# specwright Pivot — Tasks

> **For agentic workers:** implement task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. Each task names the `AC:` it satisfies and a `Delegable:` note. This is a markdown+shell repo with no test runner — the verification analog to a unit test is the grep/script that proves the change. Run each task's verification before committing.

**For this spec:** `spec.md` (sibling file; specs are self-contained, no wikilinks).

---

## Phase 1 — Rename the trees

### Task 1: git mv the skill, plugin, and companion directories

**AC:** AC-1, AC-2
**Delegable:** no (foundational; everything else builds on the new paths)
**Files:**
- Move: `skills/memex/` → `skills/sw/`
- Move: `plugins/memex/` → `plugins/sw/`
- Move: `.agents/skills/memex-{brainstorming,writing-plans,new-pr,code-review,update}/` → `.agents/skills/sw-{...}/`
- Move: `skills/sw/scaffold/skills/memex-{brainstorming,writing-plans,new-pr,code-review,update}/` → `skills/sw/scaffold/skills/sw-{...}/`

- [ ] **Step 1: Rename top-level trees**

```bash
git mv skills/memex skills/sw
git mv plugins/memex plugins/sw
```

- [ ] **Step 2: Rename kept companion dirs (canonical + scaffold)**

```bash
for n in brainstorming writing-plans new-pr code-review update; do
  git mv ".agents/skills/memex-$n" ".agents/skills/sw-$n"
  git mv "skills/sw/scaffold/skills/memex-$n" "skills/sw/scaffold/skills/sw-$n"
done
```

- [ ] **Step 3: Verify no memex-named dirs remain**

Run: `find skills/sw plugins/sw .agents/skills -depth -name '*memex*'`
Expected: no output.

- [ ] **Step 4: Commit**

```bash
git add -A && git commit -m "refactor: rename skill/plugin/companion trees to sw"
```

### Task 2: Update plugin, marketplace, and settings manifests

**AC:** AC-5, AC-13
**Delegable:** yes — "set plugin name sw, marketplace name specwright, plugin source ./plugins/sw, settings enabledPlugins sw@specwright; no other content."
**Files:**
- Modify: `plugins/sw/.claude-plugin/plugin.json`
- Modify: `.claude-plugin/marketplace.json`
- Modify: `.claude/settings.json`

- [ ] **Step 1: plugin.json**

Set `"name": "sw"` and rewrite the description to specwright branding (commands `/sw:spec`, `/sw:review-spec`; companion skills brainstorming, writing-plans, new-pr, code-review, update). No `learn`, `sweep`, `recall`, `link`.

- [ ] **Step 2: marketplace.json**

Set top-level `"name": "specwright"`; the single plugin entry `"name": "sw"`, `"source": "./plugins/sw"`, description in specwright branding.

- [ ] **Step 3: settings.json**

Replace `"memex@memex": true` with `"sw@specwright": true`; rename the `extraKnownMarketplaces` key `memex` → `specwright`.

- [ ] **Step 4: Verify**

Run: `grep -RIl 'memex' plugins/sw/.claude-plugin/plugin.json .claude-plugin/marketplace.json .claude/settings.json`
Expected: no output. Then confirm `jq -r .name .claude-plugin/marketplace.json` prints `specwright`.

- [ ] **Step 5: Commit**

```bash
git add plugins/sw/.claude-plugin/plugin.json .claude-plugin/marketplace.json .claude/settings.json
git commit -m "refactor: point manifests and settings at sw/specwright"
```

### Task 3: Update install.sh

**AC:** AC-1, AC-13
**Delegable:** yes — "rewrite install.sh: REPO=ribeirogab/specwright, SKILL=sw, symlink/paths .agents/skills/sw and .claude/skills/sw, marketplace key specwright, enabledPlugins sw@specwright, command list spec review-spec only."
**Files:**
- Modify: `install.sh`

- [ ] **Step 1: Rewrite identifiers**

Set `REPO="ribeirogab/specwright"`, `SKILL="sw"`, the install paths (`.agents/skills/sw/`, `.claude/skills/sw`), the marketplace key (`specwright`), `enabledPlugins` (`sw@specwright`), and the verified command loop to `sw-spec sw-review-spec` (drop `learn`/`sweep`). Update header comments and the curl URL to the specwright repo.

- [ ] **Step 2: Verify**

Run: `grep -ni 'memex' install.sh`
Expected: no output.

- [ ] **Step 3: Lint the script**

Run: `bash -n install.sh`
Expected: no output (parses clean).

- [ ] **Step 4: Commit**

```bash
git add install.sh && git commit -m "refactor: rebrand installer to specwright/sw"
```

---

## Phase 2 — Remove the memory half

### Task 4: Delete the memory skills and commands

**AC:** AC-2
**Delegable:** yes — "delete these paths in all three copies; no edits elsewhere."
**Files:**
- Delete: `plugins/sw/commands/learn.md`, `plugins/sw/commands/sweep.md`
- Delete: `plugins/sw/skills/recall/`, `plugins/sw/skills/link/`
- Delete: `.agents/skills/sw-recall/`, `.agents/skills/sw-link/` (if the git mv carried them — otherwise the `memex-` originals)
- Delete: `skills/sw/scaffold/skills/sw-recall/`, `skills/sw/scaffold/skills/sw-link/`

- [ ] **Step 1: Remove**

```bash
git rm -r plugins/sw/commands/learn.md plugins/sw/commands/sweep.md \
  plugins/sw/skills/recall plugins/sw/skills/link \
  .agents/skills/memex-recall .agents/skills/memex-link \
  skills/sw/scaffold/skills/memex-recall skills/sw/scaffold/skills/memex-link 2>/dev/null || true
# also catch any sw-renamed variants
git rm -r .agents/skills/sw-recall .agents/skills/sw-link \
  skills/sw/scaffold/skills/sw-recall skills/sw/scaffold/skills/sw-link 2>/dev/null || true
```

- [ ] **Step 2: Verify**

Run: `ls -d plugins/sw/skills/recall plugins/sw/skills/link plugins/sw/commands/learn.md plugins/sw/commands/sweep.md 2>/dev/null`
Expected: no output.

- [ ] **Step 3: Commit**

```bash
git add -A && git commit -m "refactor: remove recall/link/sweep/learn (memory half)"
```

### Task 5: Delete vault law and guide assets

**AC:** AC-3
**Delegable:** yes — "delete the listed scaffold/reference assets; no edits elsewhere."
**Files:**
- Delete: `skills/sw/references/constitution-template.md`
- Delete: `skills/sw/scaffold/vault-docs/spec-driven-development.md`
- Delete: any scaffold `_index`/MOC assets and note templates under `skills/sw/scaffold/`

- [ ] **Step 1: Find and remove**

```bash
git rm skills/sw/references/constitution-template.md
git rm -r skills/sw/scaffold/vault-docs 2>/dev/null || true
# remove note templates + index assets if present in scaffold
find skills/sw/scaffold -iname '*learning*' -o -iname '*_index*' -o -iname '*moc*' | xargs -r git rm -r
```

- [ ] **Step 2: Verify**

Run: `find skills/sw/scaffold -iname '*spec-driven-development*' -o -iname '*constitution*'`
Expected: no output.

- [ ] **Step 3: Commit**

```bash
git add -A && git commit -m "refactor: drop constitution, SDD guide, note/index scaffold assets"
```

### Task 6: Strip rules/constitution/learnings references from kept skills

**AC:** AC-3, AC-8
**Delegable:** yes — "in the named files, remove sentences/sections that reference rules.md, constitution.md, learnings, or the reflection step; re-point universal-standard reads to the code-review rubric and project-standard reads to conventions/. Keep all three copies identical." Note: `review-spec` lives **only** as `plugins/sw/commands/review-spec.md` (no canonical/scaffold copy) and `spec`/`update`-as-command likewise — "all three copies" applies only to the companion skills that have three copies; commands have one.
**Files:**
- Modify: `code-review`, `new-pr`, `writing-plans`, `review-spec`, `brainstorming`, `update` SKILL.md/command across `.agents/skills/sw-*`, `plugins/sw/skills/*`, `plugins/sw/commands/*`, `skills/sw/scaffold/skills/sw-*`

- [ ] **Step 1: Locate references**

Run: `grep -rIl -e 'constitution' -e 'rules\.md' -e 'learnings' -e 'reflect' .agents/skills/sw-* plugins/sw skills/sw/scaffold/skills`

- [ ] **Step 2: Edit each hit**

For `code-review`: remove "read rules.md / constitution" instructions (the rubric is now embedded — see Task 11). For `writing-plans`/`review-spec`: replace "constitution + vault compliance" with "conventions + design compliance". For `new-pr`: drop the rules.md citation. For `brainstorming`/`update`: drop learnings/reflection/constitution sentences. Apply the same edit to all three copies of each skill.

- [ ] **Step 3: Verify**

Run: `grep -rIl -e 'constitution' -e 'rules\.md' .agents/skills/sw-* plugins/sw skills/sw/scaffold/skills`
Expected: no output.

- [ ] **Step 4: Commit**

```bash
git add -A && git commit -m "refactor: drop rules/constitution/learnings references from kept skills"
```

---

## Phase 3 — Remove Obsidian

### Task 7: Remove Obsidian scaffolding and validation checks

**AC:** AC-4, AC-6
**Delegable:** yes — "remove `.obsidian` JSON scaffolding, the `.memex/.obsidian/` gitignore instruction, and Obsidian/MOC validation checks from the named files."
**Files:**
- Modify: `skills/sw/SKILL.md`, `skills/sw/references/vault-files.md`, `skills/sw/references/audit-checklist.md`, `skills/sw/references/validation.md`

- [ ] **Step 1: vault-files.md**

Delete the "Obsidian config" section, the three `.obsidian/*.json` specs, the MOC section, and the wikilink-naming-convention paragraph. Leave only the surviving vault structure (`conventions/`, `specs/`).

- [ ] **Step 2: SKILL.md**

Delete the `.obsidian` gitignore scaffolding block and its rationale; remove the MOC / `_index` write instructions; point the vault scaffold at `conventions/` + `specs/` only.

- [ ] **Step 3: validation.md + audit-checklist.md (full overhaul, not a 3-check trim)**

`validation.md` currently has ~19 checks and `audit-checklist.md` mirrors them; **many** reference removed infrastructure, not just Obsidian. Walk every check and remove or rewrite any that reference: `.obsidian` JSON (old #6), the `.gitignore` Obsidian line (old #7), MOC/`_index` placeholders, `constitution.md`, the "Vault — read" AGENTS.md header, `rules.md`, note `templates/`, the `spec-driven-development.md` guide, the update engine/manifest under the old vault path (`.memex/scripts/memex-update.sh`, `.memex/.update-manifest.json`), and the old `memex-*` skill names (→ `sw-*`). Re-point the update-engine check at `skills/sw/scripts/sw-update.sh`. Renumber the surviving checks contiguously and update the count in the validation.md intro line. Drop the matching rows from `audit-checklist.md`. The surviving check set should validate only: CLAUDE/AGENTS symlink + headers + size cap, placeholder sweeps, spec frontmatter, spec-folder naming, `sw-*` canonical skills installed, `sw` plugin settings, executable scripts at `skills/sw/scripts/`, and spec-template/validator scaffolded from the skill.

- [ ] **Step 4: Verify**

Run: `grep -rIli -e obsidian -e 'wikilink' -e '\[\[' skills/sw`
Expected: no output.

- [ ] **Step 5: Commit**

```bash
git add -A && git commit -m "refactor: remove Obsidian scaffolding, wikilinks, and related checks"
```

### Task 8: Drop wikilinks and `related:` from spec templates and validator

**AC:** AC-4
**Delegable:** yes — "remove `[[ ]]` links and the `related:` frontmatter key from the spec templates; remove any wikilink/placeholder-link logic from validate-spec.sh."
**Files:**
- Modify: the spec templates (moved in Task 10) and `validate-spec.sh` (moved in Task 9)

- [ ] **Step 1: Templates**

In `spec.md`/`design.md`/`tasks.md` templates, replace `[[design]]`/`[[spec]]` with plain filenames and delete the `related:` frontmatter key and its explanatory note.

- [ ] **Step 2: validate-spec.sh**

Confirm no check references wikilinks; the current checks (frontmatter keys, placeholder, vague verb, AC-task trace) stay. Remove the `related:` mention if any.

- [ ] **Step 3: Verify**

Run: `grep -rn -e '\[\[' -e '^related:' skills/sw/scaffold/spec-templates skills/sw/scripts/validate-spec.sh`
Expected: no output.

- [ ] **Step 4: Commit**

```bash
git add -A && git commit -m "refactor: plain-markdown specs, drop related: frontmatter"
```

---

## Phase 4 — Relocate machinery

### Task 9: Move scripts into the skill and re-wire callers

**AC:** AC-7
**Delegable:** no (touches callers across skills)
**Files:**
- Move: `skills/sw/scaffold/vault-scripts/validate-spec.sh` → `skills/sw/scripts/validate-spec.sh`
- Move: `skills/sw/scaffold/vault-scripts/memex-update.sh` → `skills/sw/scripts/sw-update.sh`
- Delete: `skills/sw/scaffold/vault-scripts/` (incl. fixtures, relocated under `skills/sw/scripts/fixtures/` if still used by tests)
- Modify: `writing-plans`, `review-spec`, `update` skills to invoke `skills/sw/scripts/...`

- [ ] **Step 1: Move scripts**

```bash
mkdir -p skills/sw/scripts
git mv skills/sw/scaffold/vault-scripts/validate-spec.sh skills/sw/scripts/validate-spec.sh
git mv skills/sw/scaffold/vault-scripts/memex-update.sh skills/sw/scripts/sw-update.sh
git mv skills/sw/scaffold/vault-scripts/fixtures skills/sw/scripts/fixtures 2>/dev/null || true
chmod +x skills/sw/scripts/validate-spec.sh skills/sw/scripts/sw-update.sh
git rm -r skills/sw/scaffold/vault-scripts 2>/dev/null || true
```

- [ ] **Step 2: Re-wire callers**

In the writing-plans gate, replace `.memex/scripts/validate-spec.sh` with `skills/sw/scripts/validate-spec.sh` (and the scaffold copy's reference accordingly — in a scaffolded repo the skill path resolves under the plugin/agent skills dir). In `update`, point at `skills/sw/scripts/sw-update.sh`. Remove any instruction that copies scripts into `.specwright/scripts`.

- [ ] **Step 3: Verify**

Run: `test -x skills/sw/scripts/validate-spec.sh && test -x skills/sw/scripts/sw-update.sh && echo OK`; then `grep -rIl '\.specwright/scripts\|\.memex/scripts' skills/sw plugins/sw .agents/skills`
Expected: `OK`, then no output.

- [ ] **Step 4: Commit**

```bash
git add -A && git commit -m "refactor: move validate/update scripts into the skill, re-wire callers"
```

### Task 10: Move spec templates into the skill

**AC:** AC-6, AC-11
**Delegable:** yes — "move the spec/design/tasks templates from the vault scaffold into skills/sw/scaffold/spec-templates/ and point brainstorming/writing-plans at the new path."
**Files:**
- Move: `.memex/specs/_template/{spec,design,tasks}.md` → `skills/sw/scaffold/spec-templates/{spec,design,tasks}.md`
- Modify: `brainstorming`, `writing-plans` skills to read the template from the skill path

- [ ] **Step 1: Move templates**

```bash
mkdir -p skills/sw/scaffold/spec-templates
git mv .memex/specs/_template/spec.md skills/sw/scaffold/spec-templates/spec.md
git mv .memex/specs/_template/design.md skills/sw/scaffold/spec-templates/design.md 2>/dev/null || true
git mv .memex/specs/_template/tasks.md skills/sw/scaffold/spec-templates/tasks.md 2>/dev/null || true
```

- [ ] **Step 2: Re-point generators**

In `writing-plans`, replace `cp .memex/specs/_template/spec.md` with the `skills/sw/scaffold/spec-templates/spec.md` path. Same for `brainstorming`'s design template. Strip the `worktree:` example path of the old vault dir → `.specwright/worktrees/<slug>`.

- [ ] **Step 3: Verify**

Run: `ls skills/sw/scaffold/spec-templates/ && grep -rIl '_template' skills/sw plugins/sw .agents/skills`
Expected: the templates listed, then no `_template` references.

- [ ] **Step 4: Commit**

```bash
git add -A && git commit -m "refactor: ship spec templates inside the skill"
```

### Task 11: Bake the universal coding standard into code-review

**AC:** AC-8
**Delegable:** yes — "add a Universal Standard section to the code-review SKILL.md (Unix philosophy rules, meaningful-comments rule, basic security checklist); keep all three copies identical."
**Files:**
- Modify: `code-review` SKILL.md across `.agents/skills/sw-code-review`, `plugins/sw/skills/code-review`, `skills/sw/scaffold/skills/sw-code-review`

- [ ] **Step 1: Author the rubric**

Add a "Universal coding standard" section containing the Unix/ESR philosophy rules (Modularity, Clarity, Composition, Separation, Simplicity, Parsimony, Transparency, Robustness, Representation, Least Surprise, Silence, Repair, Economy, Generation, Optimization, Diversity, Extensibility), the meaningful-comments rule (no comments by default; comment only a non-obvious *why*; never restate *what*; never reference the task/fix/callers), and a basic-security checklist (no secrets in code; validate/escape external input; never weaken auth/permission boundaries). State that project-specific standards come from `conventions/`.

- [ ] **Step 2: Mirror to all three copies**

Write the identical section into the other two copies.

- [ ] **Step 3: Verify**

Run: `for f in .agents/skills/sw-code-review/SKILL.md plugins/sw/skills/code-review/SKILL.md skills/sw/scaffold/skills/sw-code-review/SKILL.md; do grep -ql Modularity "$f" && grep -ql meaningful "$f" && grep -ql secret "$f" && grep -Lq -e constitution -e 'rules\.md' "$f" && echo "$f OK"; done`
Expected: three `OK` lines.

- [ ] **Step 4: Commit**

```bash
git add -A && git commit -m "feat(code-review): embed the universal coding standard rubric"
```

---

## Phase 5 — Self-contained AGENTS.md

### Task 12: Rewrite the AGENTS.md template and this repo's AGENTS.md

**AC:** AC-9
**Delegable:** no (the canonical workflow contract; keep template and live copy aligned)
**Files:**
- Modify: `skills/sw/references/agents-md-template.md`, root `AGENTS.md`

- [ ] **Step 1: Strip removed references**

Delete the "Vault — read from it, write to it" section, the reflection/learnings step, and every reference to `spec-driven-development.md`, `constitution.md`, `rules.md`, and the `specs.md` tracker. Inline enough of the flow that AGENTS.md stands alone (the 9 steps + mermaid already live here).

- [ ] **Step 2: Fix step 9**

Step 9 ("Ship the spec") sets `status: shipped` + `shipped:` in the spec's own frontmatter — remove the "move the entry to Shipped in specs.md" instruction.

- [ ] **Step 3: Re-brand**

Replace command references (`/memex:*` → `/sw:*`), vault path (`.memex` → `.specwright`), and prose name (→ specwright). Keep the template and the live `AGENTS.md` in step with each other.

- [ ] **Step 4: Verify**

Run: `grep -nE 'spec-driven-development|constitution|rules\.md|specs\.md|Vault — read|memex' AGENTS.md skills/sw/references/agents-md-template.md`
Expected: no output. Then `grep -q '### Spec flow' AGENTS.md && grep -q 'status: shipped' AGENTS.md && echo OK`.

- [ ] **Step 5: Commit**

```bash
git add AGENTS.md skills/sw/references/agents-md-template.md
git commit -m "docs(agents): self-contained spec flow, no removed references"
```

---

## Phase 6 — Re-brand root docs

### Task 13: Rebrand README and remaining root docs

**AC:** AC-1
**Delegable:** yes — "rewrite README.md, NOTICE.md, CONTRIBUTING.md to specwright/sw branding; remove memex name and memory/learnings/Obsidian descriptions; update repository-layout tree and command list."
**Files:**
- Modify: `README.md`, `NOTICE.md`, `CONTRIBUTING.md`

- [ ] **Step 1: README**

Rewrite the intro, install block (specwright repo + `/sw`), "What you get" (drop learnings/recall/link/sweep/learn and Obsidian; keep brainstorming/writing-plans/new-pr/code-review/review-spec/update), the layout tree (`skills/sw/`, `plugins/sw/`, `.specwright/`), and the customizing section (three copies under sw paths).

- [ ] **Step 2: NOTICE + CONTRIBUTING**

Update the vendored-script path (`skills/sw/scripts/`) and any memex name in NOTICE; update CONTRIBUTING's command/skill names and scope.

- [ ] **Step 3: Verify**

Run: `grep -ni 'memex' README.md NOTICE.md CONTRIBUTING.md`
Expected: no output.

- [ ] **Step 4: Commit**

```bash
git add README.md NOTICE.md CONTRIBUTING.md && git commit -m "docs: rebrand root docs to specwright"
```

---

## Phase 7 — Dogfood re-host

### Task 14: Born-fresh `.specwright/` and delete `.memex/`

**AC:** AC-11, AC-13
**Delegable:** no (repo-state surgery)
**Files:**
- Create: `.specwright/conventions/`, `.specwright/specs/2026-06-24-specwright-pivot/`
- Move: this spec's `design.md`/`spec.md`/`tasks.md` into `.specwright/specs/2026-06-24-specwright-pivot/`
- Delete: `.memex/`
- Modify: `.gitignore`

- [ ] **Step 1: Carry the pivot spec out and re-author conventions**

```bash
mkdir -p .specwright/specs/2026-06-24-specwright-pivot .specwright/conventions
git mv .memex/specs/2026-06-24-specwright-pivot/design.md .specwright/specs/2026-06-24-specwright-pivot/design.md
git mv .memex/specs/2026-06-24-specwright-pivot/spec.md  .specwright/specs/2026-06-24-specwright-pivot/spec.md
git mv .memex/specs/2026-06-24-specwright-pivot/tasks.md .specwright/specs/2026-06-24-specwright-pivot/tasks.md
```

Re-author each still-true file under `.memex/conventions/` into `.specwright/conventions/` with no old-name references (read them first, copy forward the genuinely-general ones).

- [ ] **Step 2: Delete the old vault**

```bash
git rm -r .memex
```

- [ ] **Step 3: Fix `.gitignore`**

Remove the `.memex/.obsidian/` line and any `.memex` entries; add `.specwright/worktrees/` (git-ignored worktree location).

- [ ] **Step 4: Verify**

Run: `test ! -e .memex && ls .specwright && grep -n 'memex\|obsidian' .gitignore`
Expected: `.memex` gone, `.specwright` lists `conventions specs`, no gitignore matches.

- [ ] **Step 5: Commit**

```bash
git add -A && git commit -m "chore: re-host repo on .specwright, drop .memex"
```

---

## Phase 8 — Quality gate

### Task 15: Run validators and grep guards

**AC:** AC-1, AC-3, AC-4, AC-9, AC-10, AC-12
**Delegable:** no (final gate; fix anything it surfaces)
**Files:**
- Run-only; fix wherever a check fails.

- [ ] **Step 1: Spec validator**

Run: `skills/sw/scripts/validate-spec.sh .specwright/specs/2026-06-24-specwright-pivot`
Expected: `PASS`.

- [ ] **Step 2: Scaffolder validation**

Run: `python3 skills/sw/scripts/quick_validate.py` (or follow `skills/sw/references/validation.md` checks).
Expected: no failures (or only checks N/A to this repo, noted).

- [ ] **Step 3: Old-name and Obsidian guards**

Run: `grep -rIl -e memex -e '\.obsidian' -e '\[\[' -e constitution -e 'rules\.md' -e spec-driven-development skills/sw plugins/sw .agents/skills AGENTS.md README.md install.sh .claude-plugin .gitignore .claude/settings.json`
Expected: no output.

- [ ] **Step 4: Three-copy sync**

Run, for each kept skill, a diff across canonical / plugin / scaffold SKILL.md:
```bash
for n in brainstorming writing-plans new-pr code-review update; do
  diff -q ".agents/skills/sw-$n/SKILL.md" "plugins/sw/skills/$n/SKILL.md" \
    && diff -q "plugins/sw/skills/$n/SKILL.md" "skills/sw/scaffold/skills/sw-$n/SKILL.md" \
    || echo "DRIFT: $n"
done
```
Expected: no `DRIFT` lines.

- [ ] **Step 5: AGENTS.md self-containment**

Run: `grep -nE 'spec-driven-development|constitution|rules\.md|specs\.md|Vault — read' AGENTS.md`
Expected: no output.

- [ ] **Step 6: Commit any fixes**

```bash
git add -A && git commit -m "test: pass spec validator, scaffolder validation, and old-name guards"
```
