---
status: draft
feature: rename-vault-to-memex
created: 2026-06-14
related:
  - "[[2026-06-14-rename-vault-to-memex/spec|spec]]"
  - "[[2026-06-14-rename-vault-to-memex/plan|plan]]"
---
# Rename `.vault/` to `.memex/` — Tasks

All paths relative to repo root. Commands assume macOS/bash. `perl -pi -e 's/\.vault/.memex/g'` is the replace primitive everywhere.

---

## Task 0: Capture baseline

- [ ] **Step 1: Save cross-copy diff baselines + confirm green tests**

```bash
diff -rq .agents/skills/memex-link/ plugins/memex/skills/link/ > /tmp/baseline-A-vs-plugin.txt 2>&1
diff -rq .agents/skills/memex-link/ skills/memex/scaffold/skills/memex-link/ > /tmp/baseline-A-vs-scaffold.txt 2>&1
bash .agents/skills/memex-link/tests/run.sh >/dev/null 2>&1 && echo "A: PASS" || echo "A: FAIL"
bash plugins/memex/skills/link/tests/run.sh >/dev/null 2>&1 && echo "plugin: PASS" || echo "plugin: FAIL"
```

Expected: `A: PASS`, `plugin: PASS`. (Scaffold copy intentionally not asserted — pre-broken.)

---

## Task 1: Rename the directory + ignore + leftover

**Files:** `.vault/` → `.memex/`, `.gitignore`

- [ ] **Step 1: Rename the tracked directory with history**

```bash
git mv .vault .memex
```

- [ ] **Step 2: Remove the orphaned leftover holding the gitignored `.obsidian/`**

`git mv` moves only tracked files; the untracked `.vault/.obsidian/` is left behind.

```bash
rm -rf .vault
test ! -e .vault && echo "OK: .vault gone on disk"
```

- [ ] **Step 3: Flip the `.gitignore` Obsidian path**

```bash
perl -pi -e 's/\.vault/.memex/g' .gitignore
grep -F '.memex/.obsidian/' .gitignore && ! grep -qF '.vault' .gitignore && echo "OK gitignore"
```

- [ ] **Step 4: Verify history followed the rename**

```bash
git log --follow --oneline .memex/constitution.md | tail -3
```
Expected: commits from before this branch appear (history preserved).

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "refactor(vault): rename .vault directory to .memex"
```

---

## Task 2: Flip vault canon + current-state notes

**Files:** `.memex/constitution.md`, `.memex/rules.md`, `.memex/_index/specs.md`, `.memex/_index/learnings.md`, `.memex/templates/*`, `.memex/conventions/*`, `.memex/learnings/*` **except** `sed-rename-pattern-completeness.md`

- [ ] **Step 1: Flip canon + indices + templates + conventions**

```bash
perl -pi -e 's/\.vault/.memex/g' \
  .memex/constitution.md .memex/rules.md \
  .memex/_index/specs.md .memex/_index/learnings.md \
  .memex/templates/*.md .memex/conventions/*.md
```

- [ ] **Step 2: Flip learnings, excluding the historical-narrative survivor**

```bash
for f in .memex/learnings/*.md; do
  [ "$(basename "$f")" = "sed-rename-pattern-completeness.md" ] && continue
  perl -pi -e 's/\.vault/.memex/g' "$f"
done
```

- [ ] **Step 3: Verify — only the survivor retains `.vault` in learnings; canon clean**

```bash
git grep -l '\.vault' -- .memex/learnings/    # expect: only sed-rename-pattern-completeness.md
git grep -F '.vault' -- .memex/constitution.md .memex/rules.md .memex/_index/ .memex/templates/ .memex/conventions/   # expect: empty
```

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "refactor(vault): flip .vault paths to .memex in canon and notes"
```

---

## Task 3: Flip root docs

**Files:** `AGENTS.md`, `README.md`, `SECURITY.md`, `CONTRIBUTING.md`, `.github/PULL_REQUEST_TEMPLATE.md`

- [ ] **Step 1: Flip**

```bash
perl -pi -e 's/\.vault/.memex/g' \
  AGENTS.md README.md SECURITY.md CONTRIBUTING.md .github/PULL_REQUEST_TEMPLATE.md
```

- [ ] **Step 2: Verify empty**

```bash
git grep -F '.vault' -- AGENTS.md README.md SECURITY.md CONTRIBUTING.md .github/PULL_REQUEST_TEMPLATE.md   # expect: empty
```
(CLAUDE.md is a symlink to AGENTS.md — propagates automatically.)

- [ ] **Step 3: Commit**

```bash
git add -A
git commit -m "docs: flip .vault paths to .memex in root docs"
```

---

## Task 4: Flip skill source (the scaffolder + its references)

**Files:** `skills/memex/SKILL.md`, `skills/memex/references/*.md`

- [ ] **Step 1: Flip**

```bash
perl -pi -e 's/\.vault/.memex/g' skills/memex/SKILL.md skills/memex/references/*.md
```

- [ ] **Step 2: Verify empty (incl. that `vault-files.md` kept its name, only contents flipped)**

```bash
git grep -F '.vault' -- skills/memex/SKILL.md skills/memex/references/   # expect: empty
test -f skills/memex/references/vault-files.md && echo "OK: vault-files.md name preserved"
```

- [ ] **Step 3: Commit**

```bash
git add -A
git commit -m "refactor(skill): flip .vault paths to .memex in skill source"
```

---

## Task 5: Flip companion skills (non-link) + commands

**Files:** the five non-link companion `SKILL.md` in all three locations + `plugins/memex/commands/*.md`

- [ ] **Step 1: Flip the three companion-skill copies (brainstorming, code-review, new-pr, recall, writing-plans)**

```bash
perl -pi -e 's/\.vault/.memex/g' \
  .agents/skills/memex-brainstorming/SKILL.md \
  .agents/skills/memex-code-review/SKILL.md \
  .agents/skills/memex-new-pr/SKILL.md \
  .agents/skills/memex-recall/SKILL.md \
  .agents/skills/memex-writing-plans/SKILL.md \
  plugins/memex/skills/brainstorming/SKILL.md \
  plugins/memex/skills/code-review/SKILL.md \
  plugins/memex/skills/new-pr/SKILL.md \
  plugins/memex/skills/recall/SKILL.md \
  plugins/memex/skills/writing-plans/SKILL.md \
  skills/memex/scaffold/skills/memex-brainstorming/SKILL.md \
  skills/memex/scaffold/skills/memex-code-review/SKILL.md \
  skills/memex/scaffold/skills/memex-new-pr/SKILL.md \
  skills/memex/scaffold/skills/memex-recall/SKILL.md \
  skills/memex/scaffold/skills/memex-writing-plans/SKILL.md
```

- [ ] **Step 2: Flip the plugin commands**

```bash
perl -pi -e 's/\.vault/.memex/g' plugins/memex/commands/*.md
```

- [ ] **Step 3: Verify empty across companions + commands (link handled in Task 6)**

```bash
git grep -F '.vault' -- '.agents/skills/memex-brainstorming' '.agents/skills/memex-code-review' '.agents/skills/memex-new-pr' '.agents/skills/memex-recall' '.agents/skills/memex-writing-plans' 'plugins/memex/skills/brainstorming' 'plugins/memex/skills/code-review' 'plugins/memex/skills/new-pr' 'plugins/memex/skills/recall' 'plugins/memex/skills/writing-plans' 'skills/memex/scaffold/skills/memex-brainstorming' 'skills/memex/scaffold/skills/memex-code-review' 'skills/memex/scaffold/skills/memex-new-pr' 'skills/memex/scaffold/skills/memex-recall' 'skills/memex/scaffold/skills/memex-writing-plans' plugins/memex/commands/   # expect: empty
```

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "refactor(skills): flip .vault paths to .memex in companion skills and commands"
```

---

## Task 6: Flip memex-link (scripts + fixtures + expected), keep tests green

**Files (×3 copies):** `scripts/find-candidates.sh`, `tests/fixtures/{.vault|vault}/`, `tests/expected-output.json`, the fixture `source-with-filepath.md`. Canonical = `.agents/skills/memex-link`, plugin = `plugins/memex/skills/link`, scaffold = `skills/memex/scaffold/skills/memex-link`.

- [ ] **Step 1: Rename the fixture directories with history (preserve dot/no-dot convention per copy)**

```bash
git mv .agents/skills/memex-link/tests/fixtures/.vault .agents/skills/memex-link/tests/fixtures/.memex
git mv plugins/memex/skills/link/tests/fixtures/.vault plugins/memex/skills/link/tests/fixtures/.memex
git mv skills/memex/scaffold/skills/memex-link/tests/fixtures/vault skills/memex/scaffold/skills/memex-link/tests/fixtures/memex
```

- [ ] **Step 2: Flip script + expected + fixture contents in all three copies**

```bash
perl -pi -e 's/\.vault/.memex/g' \
  .agents/skills/memex-link/scripts/find-candidates.sh \
  plugins/memex/skills/link/scripts/find-candidates.sh \
  skills/memex/scaffold/skills/memex-link/scripts/find-candidates.sh \
  .agents/skills/memex-link/tests/expected-output.json \
  plugins/memex/skills/link/tests/expected-output.json \
  skills/memex/scaffold/skills/memex-link/tests/expected-output.json \
  .agents/skills/memex-link/tests/fixtures/.memex/learnings/source-with-filepath.md \
  plugins/memex/skills/link/tests/fixtures/.memex/learnings/source-with-filepath.md \
  skills/memex/scaffold/skills/memex-link/tests/fixtures/memex/learnings/source-with-filepath.md
```

- [ ] **Step 3: Verify the two working test copies stay green**

```bash
bash .agents/skills/memex-link/tests/run.sh 2>&1 | tail -1     # expect: PASS
bash plugins/memex/skills/link/tests/run.sh 2>&1 | tail -1     # expect: PASS
```

- [ ] **Step 4: Verify scaffold copy behavior unchanged (still pre-broken FATAL, not a new failure mode)**

```bash
bash skills/memex/scaffold/skills/memex-link/tests/run.sh 2>&1 | head -1   # expect: FATAL: .memex/ not found ...
```

- [ ] **Step 5: Verify no new cross-copy divergence vs baseline**

Normalize **only the fixture-dir token** (anchored on `fixtures/`), so the skill path component `memex-link` is never touched:

```bash
perl -pe 's{fixtures/\.?vault}{fixtures/DIR}g' /tmp/baseline-A-vs-plugin.txt | sort > /tmp/base-norm.txt
diff -rq .agents/skills/memex-link/ plugins/memex/skills/link/ 2>&1 | perl -pe 's{fixtures/\.?memex}{fixtures/DIR}g' | sort > /tmp/post-norm.txt
diff /tmp/base-norm.txt /tmp/post-norm.txt && echo "OK: no new A-vs-plugin divergence"
```
Expected: normalized lists match (the fixture-dir token is the only intended difference). If `diff` shows additions, a copy diverged — investigate before committing.

- [ ] **Step 6: Verify no stray `.vault` left in link copies**

```bash
git grep -F '.vault' -- .agents/skills/memex-link/ plugins/memex/skills/link/ skills/memex/scaffold/skills/memex-link/   # expect: empty
```

- [ ] **Step 7: Commit**

```bash
git add -A
git commit -m "test(link): flip .vault fixtures and scripts to .memex, keep tests green"
```

---

## Task 7: Final verification sweep + spec ticks

- [ ] **Step 1: Global anchored sweep — every `.vault` survivor must be justified**

```bash
git grep -l '\.vault' | grep -v '^\.memex/specs/'   # expect: ONLY .memex/learnings/sed-rename-pattern-completeness.md
```
Any other file here is a miss — flip it (or, if a frozen spec, confirm it is under `.memex/specs/`).

- [ ] **Step 2: Phrase-artifact check (redundant "the `.memex/` vault")**

```bash
git grep -n '\.memex/ vault'   # expect: only the historical learning sed-rename-pattern-completeness.md (which still says .vault/ vault, untouched) → so expect EMPTY for .memex/ vault
```
If any active file shows `.memex/ vault`, reword to "the `.memex/` knowledge vault" or "the memex vault" per readability.

- [ ] **Step 3: Confirm directory inventory**

```bash
find . -type d -name '.vault' -not -path './.git/*'    # expect: empty
find . -type d -name '.memex' -not -path './.git/*'    # expect: ./.memex + 2 fixture .memex
test -d skills/memex/scaffold/skills/memex-link/tests/fixtures/memex && echo "OK scaffold no-dot fixture"
```

- [ ] **Step 4: Run the memex validation checks**

```bash
uv run --quiet --with pyyaml python skills/memex/scripts/quick_validate.py skills/memex 2>&1 | tail -5 || echo "(if validator path differs, run per references/validation.md)"
```
Expected: PASS (checks now look at `.memex/`). If the validator is not the right entry point, run the checks documented in `skills/memex/references/validation.md`.

- [ ] **Step 5: Tick the spec acceptance criteria**

Open `.memex/specs/2026-06-14-rename-vault-to-memex/spec.md`, mark each `[ ]` → `[x]` for every criterion verified above. Leave the self-referential `status: shipped` / `shipped:` tick for merge time.

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "docs(specs): tick rename-vault-to-memex acceptance criteria"
```
