---
feature: rename-context-to-vault
plan: "[[2026-05-03-rename-context-to-vault/plan|plan]]"
spec: "[[2026-05-03-rename-context-to-vault/spec|spec]]"
created: 2026-05-03
---
# Rename `context/` to `.vault/` — Tasks

**For this plan:** `[[2026-05-03-rename-context-to-vault/plan|plan]]`

> **Execution mode:** Inline. Branch `feat/rename-context-to-vault` already checked out.

---

## Phase 1 — Directory rename

### Task 1: `git mv` directories + commit

- [ ] **Step 1.1**: Top-level rename.

  ```bash
  git mv context vault
  ```

- [ ] **Step 1.2**: Test fixture directories (canonical + scaffold).

  ```bash
  git mv .agents/skills/memex-link/tests/fixtures/context .agents/skills/memex-link/tests/fixtures/vault
  git mv skills/memex/scaffold/skills/memex-link/tests/fixtures/context skills/memex/scaffold/skills/memex-link/tests/fixtures/vault
  ```

- [ ] **Step 1.3**: Verify no `context/` directory remains.

  ```bash
  find . -type d -name 'context' -not -path './.git/*' -not -path './node_modules/*'
  ```

  Expected: empty.

- [ ] **Step 1.4**: Commit (intermediate state — directories renamed but contents still reference `context/`).

  ```bash
  git commit -m "refactor(vault): git mv context → vault (directories only; content edits in next commit)"
  ```

---

## Phase 2 — Bulk substitute `context/` → `.vault/`

### Task 2: `sed` across active files + commit

- [ ] **Step 2.1**: Build a list of files that need the substitution. Excludes: shipped specs (frozen), in-flight spec for THIS rename (intentional narrative), `.git/`, `.bak` files.

  ```bash
  cd /Users/gabriel/www/ribeirogab/agent-skills

  # Use git ls-files to get tracked-only list, then filter.
  git ls-files | grep -v -E '^.vault/specs/2026-04-30-opensource-readiness/' \
                | grep -v -E '^.vault/specs/2026-05-03-rename-harness-to-memex/' \
                | grep -v -E '^.vault/specs/2026-05-03-strengthen-vault-cross-links/' \
                | grep -v -E '^.vault/specs/2026-05-03-rename-context-to-vault/' \
                | xargs grep -l 'context/' 2>/dev/null > /tmp/files-to-sed.txt
  wc -l /tmp/files-to-sed.txt
  ```

  Expected: a count > 0 of active files referencing `context/`.

- [ ] **Step 2.2**: Run `sed -i.bak 's|context/|.vault/|g'` on each file in the list.

  ```bash
  while IFS= read -r f; do
    [ -f "$f" ] && sed -i.bak 's|context/|.vault/|g' "$f" && rm "$f.bak"
  done < /tmp/files-to-sed.txt
  ```

- [ ] **Step 2.3**: Verify CLAUDE.md symlink intact (it propagates AGENTS.md changes).

  ```bash
  test -L CLAUDE.md && readlink CLAUDE.md
  ```

  Expected: `AGENTS.md`.

- [ ] **Step 2.4**: Commit.

  ```bash
  git add -A
  git status --short | head
  git commit -m "refactor(vault): substitute context/ → .vault/ across active files (excluding shipped + in-flight specs)"
  ```

---

## Phase 3 — Per-occurrence review

### Task 3: Sweep remaining `context/` and decide per-occurrence

- [ ] **Step 3.1**: List remaining survivors.

  ```bash
  git grep -l 'context/'
  ```

  Expected (allowed):
  - `.vault/specs/2026-04-30-opensource-readiness/*.md` (3 files, frozen)
  - `.vault/specs/2026-05-03-rename-harness-to-memex/*.md` (3 files, frozen)
  - `.vault/specs/2026-05-03-strengthen-vault-cross-links/*.md` (3 files, frozen)
  - `.vault/specs/2026-05-03-rename-context-to-vault/*.md` (3 files, in-flight narrative)
  - Possibly `.vault/learnings/rename-spec-grep-first.md` or similar (literature/historical references — review per-occurrence)

  Anything else: investigate, decide if it's a missed substitution (flip) or legitimate historical reference (keep + annotate).

- [ ] **Step 3.2**: For each unexpected survivor, view the line in context.

  ```bash
  git grep -n 'context/' <file>
  ```

  Heuristic:
  - "the context/ directory" / "context/learnings/" referring to the *current* layout → flip to .vault/.
  - "When we had context/, we did X" / quoting the rename narrative → keep.
  - Historical notes about the migration → keep, annotate.

- [ ] **Step 3.3**: Apply edits via `Edit` (not bulk sed — judgment per match).

- [ ] **Step 3.4**: If anything was edited, commit.

  ```bash
  git add -A
  git status --short
  git commit -m "fix(vault): per-occurrence review of remaining context/ mentions"
  ```

  If nothing was edited, skip.

---

## Phase 4 — Validation

### Task 4: Run all 16 ACs + tests + Phase 5

- [ ] **Step 4.1**: AC #1 — no `context` directory.

  ```bash
  find . -type d -name 'context' -not -path './.git/*' -not -path './node_modules/*'
  ```

  Expected: empty.

- [ ] **Step 4.2**: AC #2 — exactly 3 `vault` directories.

  ```bash
  find . -type d -name 'vault' -not -path './.git/*' -not -path './node_modules/*' | sort
  ```

  Expected: 3 paths — `./vault`, `./.agents/skills/memex-link/tests/fixtures/vault`, `./skills/memex/scaffold/skills/memex-link/tests/fixtures/vault`.

- [ ] **Step 4.3**: AC #3 — `git grep -l 'context/'` only returns allowed survivors.

  ```bash
  git grep -l 'context/'
  ```

  Compare against allowed list from Phase 3.

- [ ] **Step 4.4**: AC #4 — root docs zero context/.

  ```bash
  grep -F 'context/' AGENTS.md README.md .vault/constitution.md
  ```

  Expected: empty.

- [ ] **Step 4.5**: AC #5 — vault docs zero context/.

  ```bash
  grep -rF 'context/' .vault/_index/ .vault/templates/ .vault/conventions/ .vault/rules/
  ```

  Expected: empty.

- [ ] **Step 4.6**: AC #6 — tests/run.sh PASS.

  ```bash
  bash .agents/skills/memex-link/tests/run.sh
  ```

  Expected: `PASS`.

- [ ] **Step 4.7**: AC #7 — find-candidates.sh references .vault/ not context/.

  ```bash
  grep -F '.vault/' .agents/skills/memex-link/scripts/find-candidates.sh skills/memex/scaffold/skills/memex-link/scripts/find-candidates.sh | head
  grep -F 'context/' .agents/skills/memex-link/scripts/find-candidates.sh skills/memex/scaffold/skills/memex-link/scripts/find-candidates.sh
  ```

  First grep: matches. Second grep: empty.

- [ ] **Step 4.8**: AC #8-9 — memex SKILL.md + references reference .vault/.

  ```bash
  grep -F '.vault/' skills/memex/SKILL.md | head -2
  grep -rF 'context/' skills/memex/references/
  ```

  First grep: matches. Second grep: empty.

- [ ] **Step 4.9**: AC #10 — slash commands canonical+scaffold reference .vault/.

  ```bash
  grep -F 'context/' .claude/commands/memex-*.md skills/memex/scaffold/commands/memex-*.md
  ```

  Expected: empty.

- [ ] **Step 4.10**: AC #11 — .gitignore.

  ```bash
  grep -E '^.vault/\.obsidian/?$' .gitignore
  ```

  Expected: match.

- [ ] **Step 4.11**: AC #12 — bundled SKILL.md canonical+scaffold.

  ```bash
  grep -rF 'context/' .agents/skills/memex-*/ skills/memex/scaffold/skills/memex-*/
  ```

  Expected: empty.

- [ ] **Step 4.12**: AC #13 — scaffold byte-equivalence.

  ```bash
  diff -r .agents/skills/memex-link/ skills/memex/scaffold/skills/memex-link/
  ```

  Expected: empty.

- [ ] **Step 4.13**: AC #14 — Phase 5 validation 15/15 PASS.

  Read `skills/memex/references/validation.md`. Run all 15 checks. Note: the checks themselves now reference `.vault/` paths (post-substitute). Some may need to be re-validated after the substitute updated the inventory.

- [ ] **Step 4.14**: AC #15 — branch.

  ```bash
  git branch --show-current
  ```

  Expected: `feat/rename-context-to-vault`.

- [ ] **Step 4.15**: Fix any failures from above. Commit if any fixes were applied.

---

## Phase 5 — Ship

### Task 5: Mark spec shipped, index, push, PR

- [ ] **Step 5.1**: Mark spec frontmatter shipped (path: `.vault/specs/2026-05-03-rename-context-to-vault/spec.md`).

  - `status: draft` → `status: shipped`
  - `shipped: null` → `shipped: 2026-05-03`
  - Body `**Status:** Draft` → `**Status:** Shipped (2026-05-03)`

- [ ] **Step 5.2**: Tick all `[ ]` checkboxes in Acceptance Criteria.

  ```bash
  sed -i.bak 's/^- \[ \]/- [x]/g' .vault/specs/2026-05-03-rename-context-to-vault/spec.md \
    && rm .vault/specs/2026-05-03-rename-context-to-vault/spec.md.bak
  ```

- [ ] **Step 5.3**: Add to `.vault/_index/specs.md` under "Shipped".

- [ ] **Step 5.4**: Reflection — capture any non-obvious learning. If yes, write to `.vault/learnings/<slug>.md` per template, link `related: [[../specs/.../spec-rename-context-to-vault]]`, index in `_index/learnings.md`. If no, state explicitly in PR description.

- [ ] **Step 5.5**: Commit + push.

  ```bash
  git add .vault/specs/2026-05-03-rename-context-to-vault/spec.md .vault/_index/specs.md
  # plus any reflection learning
  git commit -m "ship: rename-context-to-vault — spec marked shipped, indexed, reflection captured"
  git push -u origin feat/rename-context-to-vault
  ```

- [ ] **Step 5.6**: Open PR via `/memex-open-pr`.
