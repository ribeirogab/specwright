---
feature: bare-spec-filenames
plan: "[[2026-06-14-bare-spec-filenames/plan|plan]]"
spec: "[[2026-06-14-bare-spec-filenames/spec|spec]]"
created: 2026-06-14
---
# Bare Spec Filenames — Tasks

**For this plan:** `[[2026-06-14-bare-spec-filenames/plan|plan]]`

Branch `feat/bare-spec-filenames`. Mode **autonomous**. Conventional Commits, no AI attribution. Only executable test: `bash .agents/skills/memex-link/tests/run.sh` (needs `jq`). Markdown validators: `uv run --quiet --with pyyaml python skills/memex/scripts/quick_validate.py <path>`.

Canonical link-key rule (applied to both a target path and every `related[]` entry): `base` = last path segment minus `.md`; if `base ∈ {spec,plan,tasks}` → key = `<second-to-last-segment>/<base>`, else key = `base`.

---

## Phase 1: GC tooling folder-aware + tests (§C)

### Task 1.1: Extend the link test fixtures with a two-spec no-false-dedup case
**Files:**
- Rename: `.agents/skills/memex-link/tests/fixtures/.vault/specs/2026-01-01-test-spec/{spec,plan,tasks}-test-spec.md` → bare
- Create: `.agents/skills/memex-link/tests/fixtures/.vault/specs/2026-01-02-other-spec/spec.md`
- Create: `.agents/skills/memex-link/tests/fixtures/.vault/learnings/source-links-spec-a.md`

- [ ] **Step 1: Rename the existing slug-named fixture files to bare**

```bash
cd .agents/skills/memex-link/tests/fixtures/.vault/specs/2026-01-01-test-spec
for t in spec plan tasks; do git mv "${t}-test-spec.md" "${t}.md"; done
cd - >/dev/null
```

- [ ] **Step 2: If those files carried intra-pair slug wikilinks, rewrite them to the new form**

```bash
d=.agents/skills/memex-link/tests/fixtures/.vault/specs/2026-01-01-test-spec
grep -nE '\[\[(spec|plan|tasks)-test-spec' "$d"/*.md || echo "no slug wikilinks to fix"
# For any hit, rewrite e.g. [[spec-test-spec]] -> [[2026-01-01-test-spec/spec|spec]] inside that folder's files.
```
Apply with the Edit tool for each hit (plan→`[[2026-01-01-test-spec/plan|plan]]`, spec→`[[2026-01-01-test-spec/spec|spec]]`, tasks→`[[2026-01-01-test-spec/tasks|tasks]]`). If Step 1's `grep` printed "no slug wikilinks to fix", skip.

- [ ] **Step 3: Create the second bare spec fixture** — `2026-01-02-other-spec/spec.md`

```markdown
---
status: draft
feature: other-spec
created: 2026-01-02
---
# Otherspec Qux

Distinct body content for the otherspec qux fixture target.
```

- [ ] **Step 4: Create the source learning that already links spec A and body-links both specs**

`.vault/learnings/source-links-spec-a.md` (relative to the fixtures `.vault`):

```markdown
---
related:
  - "[[2026-01-01-test-spec/spec|test-spec]]"
---
# Sourcelinks Quux

Body references [[2026-01-01-test-spec/spec]] and [[2026-01-02-other-spec/spec]] together.
```

- [ ] **Step 5: Run the test — it MUST fail on the unmodified script (proves the bug)**

Run: `bash .agents/skills/memex-link/tests/run.sh`
Expected: `FAIL`. Under the current basename logic, the `related[]` entry reduces to bare `spec`, which dedups **both** specs, so the source→other-spec candidate is missing **and** the expected-output (Task 1.2) won't match yet. (If it unexpectedly PASSes, stop and inspect — the fixture is not exercising the path.)

- [ ] **Step 6: Commit**

```bash
git add .agents/skills/memex-link/tests/fixtures
git commit -m "test(link): add two-spec no-false-dedup fixture for bare spec filenames"
```

### Task 1.2: Add the expected candidate for the new fixture
**Files:** Modify `.agents/skills/memex-link/tests/expected-output.json`

- [ ] **Step 1: Append the one new candidate object** to the JSON array (keep valid JSON):

```json
{
  "source": ".vault/learnings/source-links-spec-a.md",
  "target": ".vault/specs/2026-01-02-other-spec/spec.md",
  "source_title": "Sourcelinks Quux",
  "target_title": "Otherspec Qux",
  "evidence_type": "wikilink_in_body",
  "evidence_detail": "[[2026-01-02-other-spec/spec]] cited at body line 3"
}
```

- [ ] **Step 2: Validate the JSON parses**

Run: `jq -e '.' .agents/skills/memex-link/tests/expected-output.json >/dev/null && echo OK`
Expected: `OK`

- [ ] **Step 3: Re-run the test — still FAIL** (script not yet fixed)

Run: `bash .agents/skills/memex-link/tests/run.sh`
Expected: `FAIL` with a diff showing the expected `other-spec` candidate is missing from actual.

- [ ] **Step 4: Commit**

```bash
git add .agents/skills/memex-link/tests/expected-output.json
git commit -m "test(link): expected output for the two-spec dedup case"
```

### Task 1.3: Make `find-candidates.sh` key spec-folder files folder-relative (canonical copy)
**Files:** Modify `.agents/skills/memex-link/scripts/find-candidates.sh`

- [ ] **Step 1: Update the `all_notes()` exclusion filters** — bare plan/tasks names

Replace:
```bash
    | grep -Ev '/plan-[^/]+\.md$' \
    | grep -Ev '/tasks-[^/]+\.md$' \
```
with:
```bash
    | grep -Ev '/plan\.md$' \
    | grep -Ev '/tasks\.md$' \
```

- [ ] **Step 2: Replace the `related[]` basename reduction with link-key normalization**

In the precompute awk that writes `$CACHE/$enc.related`, replace:
```awk
        i = index($0, "|")
        if (i) $0 = substr($0, 1, i-1)
        n2 = match($0, /\/[^\/]+$/)
        if (n2) $0 = substr($0, n2+1)
        print
```
with:
```awk
        i = index($0, "|")
        if (i) $0 = substr($0, 1, i-1)
        nseg = split($0, seg, "/")
        base = seg[nseg]
        if (base == "spec" || base == "plan" || base == "tasks") {
          if (nseg >= 2) print seg[nseg-1] "/" base; else print base
        } else {
          print base
        }
```

- [ ] **Step 3: Compute `tgt_key` and use it for dedup + the intra-pair skip**

Replace:
```bash
    tgt_basename="${tgt##*/}"
    tgt_basename="${tgt_basename%.md}"

    # Filter: target already in source's related (bash case, no fork).
    case "$src_related_str" in
      *" $tgt_basename "*) continue ;;
    esac

    # Filter: plan/tasks intra-pair within same spec folder.
    tgt_dir="${tgt%/*}"
    if [ "$src_dir" = "$tgt_dir" ]; then
      tgt_base="${tgt##*/}"
      case "$tgt_base" in
        plan-*|tasks-*) continue ;;
      esac
    fi
```
with:
```bash
    tgt_basename="${tgt##*/}"
    tgt_basename="${tgt_basename%.md}"

    # Link key: folder-qualify spec-folder files so two bare spec.md don't collide.
    case "$tgt_basename" in
      spec|plan|tasks)
        tgt_parent="${tgt%/*}"; tgt_parent="${tgt_parent##*/}"
        tgt_key="$tgt_parent/$tgt_basename" ;;
      *) tgt_key="$tgt_basename" ;;
    esac

    # Filter: target already in source's related (bash case, no fork).
    case "$src_related_str" in
      *" $tgt_key "*) continue ;;
    esac

    # Filter: plan/tasks intra-pair within same spec folder.
    tgt_dir="${tgt%/*}"
    if [ "$src_dir" = "$tgt_dir" ]; then
      case "$tgt_basename" in
        plan|tasks) continue ;;
      esac
    fi
```

- [ ] **Step 4: Use `tgt_key` in the wikilink-in-body evidence match**

Replace:
```bash
    if grep -qE "\[\[([^]|]*/)?$tgt_basename(\||\]\])" "$src_body_f"; then
      line=$(grep -m1 -nE "\[\[([^]|]*/)?$tgt_basename(\||\]\])" "$src_body_f" | cut -d: -f1)
      evidence="wikilink_in_body"; detail="[[$tgt_basename]] cited at body line $line"
```
with:
```bash
    if grep -qE "\[\[([^]|]*/)?$tgt_key(\||\]\])" "$src_body_f"; then
      line=$(grep -m1 -nE "\[\[([^]|]*/)?$tgt_key(\||\]\])" "$src_body_f" | cut -d: -f1)
      evidence="wikilink_in_body"; detail="[[$tgt_key]] cited at body line $line"
```

- [ ] **Step 5: Run the test — now PASS**

Run: `bash .agents/skills/memex-link/tests/run.sh`
Expected: `PASS`. (If FAIL, diff the actual vs expected — most likely the `evidence_detail` line number or a stray shared-heading candidate; fix the fixture text, not the logic, unless the logic diff is wrong.)

- [ ] **Step 6: Commit** (canonical only; copies synced in 1.4)

```bash
git add .agents/skills/memex-link/scripts/find-candidates.sh
git commit -m "feat(link): key spec-folder files by folder-relative identity"
```

### Task 1.4: Sync the plugin + scaffold copies of `find-candidates.sh`
**Files:** Modify `plugins/memex/skills/link/scripts/find-candidates.sh`, `skills/memex/scaffold/skills/memex-link/scripts/find-candidates.sh`

- [ ] **Step 1: Copy canonical → both copies (byte-identical)**

```bash
cp .agents/skills/memex-link/scripts/find-candidates.sh plugins/memex/skills/link/scripts/find-candidates.sh
cp .agents/skills/memex-link/scripts/find-candidates.sh skills/memex/scaffold/skills/memex-link/scripts/find-candidates.sh
```

- [ ] **Step 2: Verify identity**

```bash
diff .agents/skills/memex-link/scripts/find-candidates.sh plugins/memex/skills/link/scripts/find-candidates.sh \
 && diff .agents/skills/memex-link/scripts/find-candidates.sh skills/memex/scaffold/skills/memex-link/scripts/find-candidates.sh \
 && echo "3-copy identical"
```
Expected: `3-copy identical`

- [ ] **Step 3: Commit**

```bash
git add plugins/memex/skills/link/scripts/find-candidates.sh skills/memex/scaffold/skills/memex-link/scripts/find-candidates.sh
git commit -m "chore(link): sync find-candidates.sh plugin + scaffold copies"
```

### Task 1.5: Make `/memex:sweep` broken-link resolution folder-aware
**Files:** Modify `plugins/memex/commands/sweep.md`

- [ ] **Step 1: Read the "### 2. Broken wikilinks" section** and its resolution prose ("strip the path prefix and search the vault for any file or directory whose basename matches"). Add a folder-aware rule so a spec-folder link is verified against its specific folder:

Append to that section's prose (before the bash block, after the existing "Skip files inside `templates/`…" sentence):
> For a path-qualified link to a spec-folder file — `[[…/<YYYY-MM-DD-slug>/spec]]` (or `plan`/`tasks`) — resolve it against that **specific** folder: the target exists only if `.vault/specs/<YYYY-MM-DD-slug>/spec.md` exists. Do **not** fall back to a bare `spec.md`-anywhere match for these, or a link to a deleted spec resolves to an unrelated spec. Bare basename resolution still applies to learnings/conventions/rules links.

- [ ] **Step 2: Update check #5** ("Specs done in `tasks-<slug>.md` but still `status: draft`")

In the check-#5 prose and bash, replace the slugged filenames with bare: `spec-<slug>.md` → `spec.md`, `tasks-<slug>.md` → `tasks.md`. The folder still derives from `basename "$spec_dir"`; the files inside are now bare.

- [ ] **Step 3: Verify no `*-<slug>.md` filename pattern remains in sweep**

Run: `grep -nE '(spec|plan|tasks)-<slug>\.md|(spec|plan|tasks)-\$\{?slug' plugins/memex/commands/sweep.md || echo "clean"`
Expected: `clean`

- [ ] **Step 4: Commit**

```bash
git add plugins/memex/commands/sweep.md
git commit -m "docs(sweep): folder-aware broken-link resolution + bare check #5 filenames"
```

---

## Phase 2: Convention definition (§A)

### Task 2.1: Rewrite the spec-file naming convention + templates in `vault-files.md`
**Files:** Modify `skills/memex/references/vault-files.md`

- [ ] **Step 1: Replace the plan template link forms** (~lines 211, 216)

`spec: "[[spec-{{kebab-slug-of-feature}}]]"` → `spec: "[[spec]]"`
`**For this spec:** `[[spec-{{kebab-slug-of-feature}}]]`` → `**For this spec:** `[[spec]]``

- [ ] **Step 2: Replace the tasks template link forms** (~lines 243–249)

`plan: "[[plan-{{kebab-slug-of-feature}}]]"` → `plan: "[[plan]]"`
`spec: "[[spec-{{kebab-slug-of-feature}}]]"` → `spec: "[[spec]]"`
`**For this plan:** `[[plan-{{kebab-slug-of-feature}}]]`` → `**For this plan:** `[[plan]]``

- [ ] **Step 3: Rewrite the "Spec file naming convention" prose** (~line 264)

Replace the whole paragraph with:
> **Spec file naming convention:** the three files inside a spec folder use **bare** names — `spec.md`, `plan.md`, `tasks.md`. The dated folder (`YYYY-MM-DD-<kebab-slug>/`) is the discriminator, so cross-references are **path-qualified wikilinks** that carry the folder: a sibling link is `[[YYYY-MM-DD-<kebab-slug>/spec|spec]]`, an inbound link from elsewhere in the vault is `[[../specs/YYYY-MM-DD-<kebab-slug>/spec|<slug>]]`. This keeps every `[[ ]]` globally unique (Obsidian and the `/memex:link` resolver key on the path) while keeping filenames clean. Templates inside `_template/` keep bare, **unqualified** placeholders (`[[spec]]`, `[[plan]]`) — the generating skills (`memex-brainstorming`, `memex-writing-plans`) inject the folder prefix when they copy the template into a real dated folder. Trade-off, accepted deliberately: editor tabs and fuzzy-finder entries show `spec.md` for every spec, distinguished only by their parent folder.

- [ ] **Step 4: Verify**

Run: `grep -nE 'spec-\{\{|plan-\{\{|tasks-\{\{|spec-<slug>|<type>-<slug>' skills/memex/references/vault-files.md || echo "clean"`
Expected: `clean`

- [ ] **Step 5: Commit**

```bash
git add skills/memex/references/vault-files.md
git commit -m "docs(vault-files): bare spec filenames + path-qualified link convention"
```

### Task 2.2: Confirm the on-disk `_template/` link placeholders match
**Files:** Read `.vault/specs/_template/plan.md`, `.vault/specs/_template/tasks.md`

- [ ] **Step 1: Confirm they already use bare `[[spec]]`/`[[plan]]` placeholders** (no slug)

Run: `grep -nE '\[\[(spec|plan|tasks)' .vault/specs/_template/plan.md .vault/specs/_template/tasks.md`
Expected: only `[[spec]]` / `[[plan]]` forms. If any slug or path appears, edit it back to the bare placeholder. (No commit if no change.)

---

## Phase 3: Generating skills (§B)

### Task 3.1: `memex-brainstorming` — write the spec to bare `spec.md`
**Files:** Modify `.agents/skills/memex-brainstorming/SKILL.md` (canonical)

- [ ] **Step 1: Replace every `spec-<slug>.md` / `plan-<slug>.md` / `tasks-<slug>.md` reference** in the skill with the bare form. Known anchors: the checklist step 7 (`save to .vault/specs/YYYY-MM-DD-<slug>/spec-<slug>.md`), the "Documentation" section, the dot diagram label if it names the file, and step 9 (`plan-<slug>.md` + `tasks-<slug>.md`).

`.../<slug>/spec-<slug>.md` → `.../<slug>/spec.md`; `plan-<slug>.md` → `plan.md`; `tasks-<slug>.md` → `tasks.md`.

- [ ] **Step 2: Verify**

Run: `grep -nE '(spec|plan|tasks)-<slug>\.md' .agents/skills/memex-brainstorming/SKILL.md || echo clean`
Expected: `clean`

- [ ] **Step 3: Regenerate plugin + scaffold copies**

```bash
cp .agents/skills/memex-brainstorming/SKILL.md skills/memex/scaffold/skills/memex-brainstorming/SKILL.md
sed 's/^name: memex-brainstorming$/name: brainstorming/' .agents/skills/memex-brainstorming/SKILL.md > plugins/memex/skills/brainstorming/SKILL.md
diff <(tail -n +3 .agents/skills/memex-brainstorming/SKILL.md) <(tail -n +3 plugins/memex/skills/brainstorming/SKILL.md) \
 && diff .agents/skills/memex-brainstorming/SKILL.md skills/memex/scaffold/skills/memex-brainstorming/SKILL.md \
 && echo "synced"
```
Expected: `synced`

- [ ] **Step 4: Commit**

```bash
git add .agents/skills/memex-brainstorming/SKILL.md plugins/memex/skills/brainstorming/SKILL.md skills/memex/scaffold/skills/memex-brainstorming/SKILL.md
git commit -m "feat(brainstorming): write spec to bare spec.md"
```

### Task 3.2: `memex-writing-plans` — bare filenames + inject folder-qualified sibling links
**Files:** Modify `.agents/skills/memex-writing-plans/SKILL.md` (canonical)

- [ ] **Step 1: Replace the save-path references** — `plan-<slug>.md` → `plan.md`, `tasks-<slug>.md` → `tasks.md`, `spec-<slug>.md` → `spec.md` (e.g. the "Save plans to" line and any body mention).

- [ ] **Step 2: Add the link-injection instruction.** Where the skill describes materializing `plan.md`/`tasks.md` from the template, add: "When filling the template, replace the bare placeholder links with folder-qualified ones using the spec's dated folder: `[[spec]]` → `[[<YYYY-MM-DD-slug>/spec|spec]]`, `[[plan]]` → `[[<YYYY-MM-DD-slug>/plan|plan]]`."

- [ ] **Step 3: Verify**

Run: `grep -nE '(spec|plan|tasks)-<slug>\.md' .agents/skills/memex-writing-plans/SKILL.md || echo clean`
Expected: `clean`

- [ ] **Step 4: Regenerate plugin + scaffold copies**

```bash
cp .agents/skills/memex-writing-plans/SKILL.md skills/memex/scaffold/skills/memex-writing-plans/SKILL.md
sed 's/^name: memex-writing-plans$/name: writing-plans/' .agents/skills/memex-writing-plans/SKILL.md > plugins/memex/skills/writing-plans/SKILL.md
diff <(tail -n +3 .agents/skills/memex-writing-plans/SKILL.md) <(tail -n +3 plugins/memex/skills/writing-plans/SKILL.md) \
 && diff .agents/skills/memex-writing-plans/SKILL.md skills/memex/scaffold/skills/memex-writing-plans/SKILL.md \
 && echo "synced"
```
Expected: `synced`

- [ ] **Step 5: Commit**

```bash
git add .agents/skills/memex-writing-plans/SKILL.md plugins/memex/skills/writing-plans/SKILL.md skills/memex/scaffold/skills/memex-writing-plans/SKILL.md
git commit -m "feat(writing-plans): bare plan/tasks filenames + folder-qualified sibling links"
```

---

## Phase 4: Validator / audit / recipe (§D)

### Task 4.1: Invert validation check #15
**Files:** Modify `skills/memex/references/validation.md`

- [ ] **Step 1: Rewrite check #15** (currently "### 15. No spec folder contains generic `spec.md` / `plan.md` / `tasks.md`"). The new check FAILS when a **slug-named** file survives. Replace its heading, rationale, bash, and fix pointer:

Heading → `### 15. Spec folders use bare `spec.md` / `plan.md` / `tasks.md``
Rationale → bare names are the convention; a `<type>-<slug>.md` file is drift from before the rename.
Bash (replace the loop):
```bash
bad=$(find .vault/specs -type f \( -name 'spec-*.md' -o -name 'plan-*.md' -o -name 'tasks-*.md' \) 2>/dev/null)
[ -z "$bad" ] && echo PASS || { echo "FAIL:"; echo "$bad"; }
```
Fix pointer → run the (reversed) spec-file rename migration in `SKILL.md`.

- [ ] **Step 2: Update the TOC line** (~line 10) — "spec-file slug naming" → "spec-file bare naming".

- [ ] **Step 3: Verify the new bash PASSes on this repo only after migration** — for now just confirm the file has no leftover "generic ... defeat the convention" wording:

Run: `grep -ni 'generic .*spec\.md' skills/memex/references/validation.md || echo clean`
Expected: `clean`

- [ ] **Step 4: Commit**

```bash
git add skills/memex/references/validation.md
git commit -m "docs(validation): invert check #15 to require bare spec filenames"
```

### Task 4.2: Invert the audit-checklist naming section
**Files:** Modify `skills/memex/references/audit-checklist.md`

- [ ] **Step 1: Rewrite the "### Spec file naming follows `<spec|plan|tasks>-<slug>.md`" section** to "### Spec file naming follows bare `spec.md` / `plan.md` / `tasks.md`" — bare is correct; a `<type>-<slug>.md` file inside a real spec folder is `DRIFT`. Update the rationale to the path-qualified-link reasoning.

- [ ] **Step 2: Verify**

Run: `grep -nE '<spec\|plan\|tasks>-<slug>|slug-included naming' skills/memex/references/audit-checklist.md || echo clean`
Expected: `clean`

- [ ] **Step 3: Commit**

```bash
git add skills/memex/references/audit-checklist.md
git commit -m "docs(audit): bare spec filenames are correct, slug names are drift"
```

### Task 4.3: Reverse the SKILL.md spec-file rename migration recipe
**Files:** Modify `skills/memex/SKILL.md`

- [ ] **Step 1: Rewrite the "### Spec file rename migration" block** so it migrates slug→bare. New recipe body:

```bash
spec_dir="<the folder, e.g. .vault/specs/2026-04-30-opensource-readiness>"
slug=$(basename "$spec_dir" | sed 's/^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]-//')
folder=$(basename "$spec_dir")

# 1. Rename slug-named files to bare, preserving git history
for type in spec plan tasks; do
  src="$spec_dir/${type}-${slug}.md"
  dst="$spec_dir/${type}.md"
  [ -f "$src" ] && [ ! -e "$dst" ] && git mv "$src" "$dst"
done

# 2. Rewrite intra-folder wikilinks: [[<type>-<slug>]] -> [[<folder>/<type>|<type>]]
for f in "$spec_dir"/*.md; do
  sed -i.bak \
    -e "s|\\[\\[spec-${slug}\\]\\]|[[${folder}/spec\\|spec]]|g" \
    -e "s|\\[\\[plan-${slug}\\]\\]|[[${folder}/plan\\|plan]]|g" \
    -e "s|\\[\\[tasks-${slug}\\]\\]|[[${folder}/tasks\\|tasks]]|g" \
    "$f" && rm "$f.bak"
done

# 3. Rewrite path-qualified links anywhere they kept the slugged filename
#    /<folder>/spec-<slug>  ->  /<folder>/spec
grep -rl "/${folder}/spec-${slug}\|/${folder}/plan-${slug}\|/${folder}/tasks-${slug}" .vault 2>/dev/null \
  | while IFS= read -r f; do
      sed -i.bak \
        -e "s|/${folder}/spec-${slug}|/${folder}/spec|g" \
        -e "s|/${folder}/plan-${slug}|/${folder}/plan|g" \
        -e "s|/${folder}/tasks-${slug}|/${folder}/tasks|g" \
        "$f" && rm "$f.bak"
    done

# 4. Rewrite bare-basename inbound links: [[spec-<slug>]] -> [[<folder>/spec|<slug>]]
grep -rl "\\[\\[spec-${slug}\\]\\]\|\\[\\[plan-${slug}\\]\\]\|\\[\\[tasks-${slug}\\]\\]" .vault 2>/dev/null \
  | while IFS= read -r f; do
      sed -i.bak \
        -e "s|\\[\\[spec-${slug}\\]\\]|[[${folder}/spec\\|${slug}]]|g" \
        -e "s|\\[\\[plan-${slug}\\]\\]|[[${folder}/plan\\|${slug}]]|g" \
        -e "s|\\[\\[tasks-${slug}\\]\\]|[[${folder}/tasks\\|${slug}]]|g" \
        "$f" && rm "$f.bak"
    done
```
Update the surrounding prose: trigger is now "the audit detected a `<type>-<slug>.md` file inside a spec folder"; the destructive-confirm note stays. Update the `sed` `[|\\]]` note to reflect step 3's `/<folder>/<type>-<slug>` edge scoping.

- [ ] **Step 2: Verify the recipe no longer renames bare→slug**

Run: `grep -nE 'dst=.*\$\{type\}-\$\{slug\}|\[\[spec\]\] -> \[\[spec-' skills/memex/SKILL.md || echo clean`
Expected: `clean`

- [ ] **Step 3: Commit**

```bash
git add skills/memex/SKILL.md
git commit -m "docs(skill): reverse spec-file rename migration to slug->bare"
```

---

## Phase 5: Project law / docs (§E)

### Task 5.1: Constitution + constitution-template flow line
**Files:** Modify `.vault/constitution.md`, `skills/memex/references/constitution-template.md`

- [ ] **Step 1:** In both files, replace `brainstorm → `spec-<slug>.md` → `plan-<slug>.md` → `tasks-<slug>.md` → implement` with `brainstorm → `spec.md` → `plan.md` → `tasks.md` → implement`.

- [ ] **Step 2: Verify**

Run: `grep -nE '(spec|plan|tasks)-<slug>\.md' .vault/constitution.md skills/memex/references/constitution-template.md || echo clean`
Expected: `clean`

- [ ] **Step 3: Commit**

```bash
git add .vault/constitution.md skills/memex/references/constitution-template.md
git commit -m "docs(constitution): bare spec filenames in the spec-driven flow"
```

### Task 5.2: AGENTS.md + agents-md-template spec-flow step 3
**Files:** Modify `AGENTS.md`, `skills/memex/references/agents-md-template.md`

- [ ] **Step 1:** In both, in spec-flow step 3, replace `spec-<slug>.md` → `spec.md` and `plan-<slug>.md` + `tasks-<slug>.md` → `plan.md` + `tasks.md`.

- [ ] **Step 2: Verify size + headers + cleanliness**

```bash
grep -nE '(spec|plan|tasks)-<slug>\.md' AGENTS.md skills/memex/references/agents-md-template.md || echo clean
[ "$(wc -l < AGENTS.md | tr -d ' ')" -le 80 ] && echo "<=80" || echo "TOO LONG"
[ "$(grep -c '^## ' AGENTS.md)" -eq 4 ] && echo "4 headers" || echo "HEADER COUNT WRONG"
```
Expected: `clean`, `<=80`, `4 headers`

- [ ] **Step 3: Commit**

```bash
git add AGENTS.md skills/memex/references/agents-md-template.md
git commit -m "docs(agents): bare spec filenames in the spec flow step"
```

### Task 5.3: new-pr (×3) + review-spec filename refs
**Files:** Modify `.agents/skills/memex-new-pr/SKILL.md` (canonical), `plugins/memex/commands/review-spec.md`

- [ ] **Step 1: Edit canonical new-pr** — replace `spec-<slug>.md` / `plan-<slug>.md` / `tasks-<slug>.md` with bare forms (the "Find the spec driving this branch" line + the "spec: …, plan: …, tasks: …" line). Keep the by-`branch:`-frontmatter lookup logic; only the filenames change.

- [ ] **Step 2: Regenerate new-pr plugin + scaffold copies**

```bash
cp .agents/skills/memex-new-pr/SKILL.md skills/memex/scaffold/skills/memex-new-pr/SKILL.md
sed 's/^name: memex-new-pr$/name: new-pr/' .agents/skills/memex-new-pr/SKILL.md > plugins/memex/skills/new-pr/SKILL.md
diff <(tail -n +3 .agents/skills/memex-new-pr/SKILL.md) <(tail -n +3 plugins/memex/skills/new-pr/SKILL.md) \
 && diff .agents/skills/memex-new-pr/SKILL.md skills/memex/scaffold/skills/memex-new-pr/SKILL.md && echo synced
```
Expected: `synced`

- [ ] **Step 3: Edit review-spec** — `plugins/memex/commands/review-spec.md`, replace `spec-<slug>.md` → `spec.md` (the "For the target `spec-<slug>.md`" line).

- [ ] **Step 4: Verify**

Run: `grep -rnE '(spec|plan|tasks)-<slug>\.md' .agents/skills/memex-new-pr plugins/memex/skills/new-pr plugins/memex/commands/review-spec.md skills/memex/scaffold/skills/memex-new-pr || echo clean`
Expected: `clean`

- [ ] **Step 5: Commit**

```bash
git add .agents/skills/memex-new-pr/SKILL.md plugins/memex/skills/new-pr/SKILL.md skills/memex/scaffold/skills/memex-new-pr/SKILL.md plugins/memex/commands/review-spec.md
git commit -m "docs(new-pr,review-spec): bare spec filenames in references"
```

---

## Phase 6: Migrate this repo's 10 spec folders (§F)

### Task 6.1: Enumerate inbound links first (grep-first, never from memory)
**Files:** read-only

- [ ] **Step 1: List every spec folder + capture the slugs**

```bash
find .vault/specs -mindepth 1 -maxdepth 1 -type d -name '2026-*' | sort
```

- [ ] **Step 2: Capture every inbound wikilink that names a slugged spec file** (both shapes), excluding fictional examples:

```bash
grep -rnoE '\[\[[^]]*(spec|plan|tasks)-[a-z0-9-]+(\|[^]]*)?\]\]' .vault --include='*.md' \
  | grep -vE 'spec-test-spec|spec-island-test|plan-test-spec|tasks-test-spec|plan-island-test'
```
Keep this list; Task 6.2's migration must zero it out (minus the fictional ones).

### Task 6.2: Run the reversed migration recipe per folder
**Files:** all 10 `.vault/specs/2026-*/` folders + `.vault/_index/specs.md` + inbound learnings

- [ ] **Step 1: Apply the SKILL.md slug→bare recipe to each folder.** Loop:

```bash
for spec_dir in $(find .vault/specs -mindepth 1 -maxdepth 1 -type d -name '2026-*' | sort); do
  slug=$(basename "$spec_dir" | sed 's/^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]-//')
  folder=$(basename "$spec_dir")
  for type in spec plan tasks; do
    src="$spec_dir/${type}-${slug}.md"; dst="$spec_dir/${type}.md"
    [ -f "$src" ] && [ ! -e "$dst" ] && git mv "$src" "$dst"
  done
  for f in "$spec_dir"/*.md; do
    sed -i.bak \
      -e "s|\\[\\[spec-${slug}\\]\\]|[[${folder}/spec\\|spec]]|g" \
      -e "s|\\[\\[plan-${slug}\\]\\]|[[${folder}/plan\\|plan]]|g" \
      -e "s|\\[\\[tasks-${slug}\\]\\]|[[${folder}/tasks\\|tasks]]|g" \
      "$f" && rm "$f.bak"
  done
done
```
Note: the in-flight `2026-06-14-bare-spec-filenames` folder has only `spec-bare-spec-filenames.md` at this point (its `plan`/`tasks` are these very files, still slug-named) — the `[ -f "$src" ]` guard skips the missing ones. **This file (`tasks-bare-spec-filenames.md`) and `plan-…`/`spec-…` are renamed by this loop too** — after the loop, continue reading from `tasks.md`.

- [ ] **Step 2: Rewrite path-qualified + bare-basename inbound links across the whole vault** for every slug:

```bash
for spec_dir in $(find .vault/specs -mindepth 1 -maxdepth 1 -type d -name '2026-*' | sort); do
  slug=$(basename "$spec_dir" | sed 's/^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]-//')
  folder=$(basename "$spec_dir")
  # path-qualified links that kept the slugged filename
  grep -rl "/${folder}/spec-${slug}\|/${folder}/plan-${slug}\|/${folder}/tasks-${slug}" .vault 2>/dev/null \
    | while IFS= read -r f; do
        sed -i.bak \
          -e "s|/${folder}/spec-${slug}|/${folder}/spec|g" \
          -e "s|/${folder}/plan-${slug}|/${folder}/plan|g" \
          -e "s|/${folder}/tasks-${slug}|/${folder}/tasks|g" \
          "$f" && rm "$f.bak"
      done
  # bare-basename inbound links (e.g. learnings -> [[spec-<slug>]])
  grep -rl "\\[\\[spec-${slug}\\]\\]\|\\[\\[plan-${slug}\\]\\]\|\\[\\[tasks-${slug}\\]\\]" .vault 2>/dev/null \
    | while IFS= read -r f; do
        sed -i.bak \
          -e "s|\\[\\[spec-${slug}\\]\\]|[[${folder}/spec\\|${slug}]]|g" \
          -e "s|\\[\\[plan-${slug}\\]\\]|[[${folder}/plan\\|${slug}]]|g" \
          -e "s|\\[\\[tasks-${slug}\\]\\]|[[${folder}/tasks\\|${slug}]]|g" \
          "$f" && rm "$f.bak"
      done
done
```

- [ ] **Step 3: Verify no slugged spec filename survives + no broken inbound link**

```bash
find .vault/specs -type f \( -name 'spec-*.md' -o -name 'plan-*.md' -o -name 'tasks-*.md' \)
# expect: empty
grep -rnoE '\[\[[^]]*(spec|plan|tasks)-[a-z0-9-]+(\|[^]]*)?\]\]' .vault --include='*.md' \
  | grep -vE 'spec-test-spec|spec-island-test|plan-test-spec|tasks-test-spec|plan-island-test'
# expect: empty (only the fictional examples remain, which were filtered out)
```
Expected: both empty. If a real slugged link survives, it is a slug whose folder rename missed it — rewrite by hand.

- [ ] **Step 4: Commit**

```bash
git add -A .vault
git commit -m "refactor(vault): migrate 10 spec folders to bare filenames + path-qualified links"
```

---

## Phase 7: Quality gate (AC)

### Task 7.1: Run every acceptance check
- [ ] **Step 1: Link test green**

Run: `bash .agents/skills/memex-link/tests/run.sh`
Expected: `PASS`

- [ ] **Step 2: 3-copy body-identity**

```bash
diff <(tail -n +3 .agents/skills/memex-brainstorming/SKILL.md) <(tail -n +3 plugins/memex/skills/brainstorming/SKILL.md) \
 && diff <(tail -n +3 .agents/skills/memex-writing-plans/SKILL.md) <(tail -n +3 plugins/memex/skills/writing-plans/SKILL.md) \
 && diff <(tail -n +3 .agents/skills/memex-new-pr/SKILL.md) <(tail -n +3 plugins/memex/skills/new-pr/SKILL.md) \
 && diff .agents/skills/memex-link/scripts/find-candidates.sh plugins/memex/skills/link/scripts/find-candidates.sh \
 && diff .agents/skills/memex-link/scripts/find-candidates.sh skills/memex/scaffold/skills/memex-link/scripts/find-candidates.sh \
 && echo "all synced"
```
Expected: `all synced`

- [ ] **Step 3: No slugged filename or convention statement remains**

```bash
find .vault/specs -type f \( -name 'spec-*.md' -o -name 'plan-*.md' -o -name 'tasks-*.md' \)  # empty
grep -rnE '(spec|plan|tasks)-<slug>\.md' AGENTS.md .vault/constitution.md skills/memex/ plugins/memex/ .agents/skills/ || echo clean
```
Expected: first empty; second `clean`.

- [ ] **Step 4: Inverted validator passes on this vault, fails on a reintroduced slug file**

```bash
find .vault/specs -type f \( -name 'spec-*.md' -o -name 'plan-*.md' -o -name 'tasks-*.md' \) | grep -q . && echo FAIL || echo PASS
# spot-check the inverse in a temp copy:
tmp=$(mktemp -d); cp -r .vault/specs/2026-06-14-bare-spec-filenames "$tmp/"; cp "$tmp"/*/spec.md "$tmp/$(ls "$tmp")/spec-x.md" 2>/dev/null
find "$tmp" -name 'spec-*.md' | grep -q . && echo "inverse FAIL-detection OK"; rm -rf "$tmp"
```
Expected: `PASS`, then `inverse FAIL-detection OK`.

- [ ] **Step 5: Sweep broken-link check reports zero BROKEN.** Run the `/memex:sweep` broken-wikilink bash (section 2) against `.vault/`; confirm no `BROKEN:` lines.

- [ ] **Step 6: Markdown validators on touched vault files**

Run: `uv run --quiet --with pyyaml python skills/memex/scripts/quick_validate.py .vault/specs/2026-06-14-bare-spec-filenames/spec.md`
Expected: passes (no schema errors). Repeat for `plan.md`/`tasks.md` if the validator targets them.

- [ ] **Step 7: AGENTS.md size + headers**

```bash
[ "$(wc -l < AGENTS.md | tr -d ' ')" -le 80 ] && [ "$(grep -c '^## ' AGENTS.md)" -eq 4 ] && echo OK
```
Expected: `OK`

- [ ] **Step 8: If any check failed, fix and re-run before proceeding to reflect/deliver.** No commit needed if Phase 6 already captured the migration; commit any gate fixes with a `fix:`/`docs:` message.
