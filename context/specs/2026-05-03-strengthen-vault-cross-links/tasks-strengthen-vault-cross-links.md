---
feature: strengthen-vault-cross-links
plan: "[[plan-strengthen-vault-cross-links]]"
spec: "[[spec-strengthen-vault-cross-links]]"
created: 2026-05-03
---
# Strengthen Vault Cross-Links — Tasks

**For this plan:** `[[plan-strengthen-vault-cross-links]]`

> **Execution mode:** Inline. The implementer reads each task in order, executes the steps, and commits at the end of each phase. Branch `feat/strengthen-vault-cross-links` is already checked out.
>
> **Bash compatibility:** the `find-candidates.sh` script must run on bash 3.2+ (macOS default). No `declare -A`, no `mapfile`, no bash 4 features. The script is verified by `bash --version` documenting 3.2 as the minimum.

---

## Phase 1 — Static edits (Components 1, 2, 4)

### Task 1: Three small edits + commit

**Files:**
- Modify: `context/specs/_template/spec.md`
- Modify: `AGENTS.md`
- Modify: `context/specs/2026-04-30-opensource-readiness/spec-opensource-readiness.md`

- [ ] **Step 1.1**: Add `related: []` to `context/specs/_template/spec.md` frontmatter, after `shipped: null`.

  Use `Edit`:
  - old:
    ```
    ---
    status: draft
    feature: {{kebab-slug-of-feature}}
    created: {{YYYY-MM-DD}}
    shipped: null
    ---
    ```
  - new:
    ```
    ---
    status: draft
    feature: {{kebab-slug-of-feature}}
    created: {{YYYY-MM-DD}}
    shipped: null
    related: []
    ---
    ```

- [ ] **Step 1.2**: Insert the body note in `_template/spec.md` between **Status:** and **Scope:** lines.

  Use `Edit`:
  - old:
    ```
    **Status:** Draft
    **Scope:** {{one-sentence scope statement}}

    ## Context
    ```
  - new:
    ```
    **Status:** Draft
    **Scope:** {{one-sentence scope statement}}

    > **Note on `related:` frontmatter** — populate the `related:` list with wikilinks to learnings, conventions, or rules this spec touches, reads, or modifies. Empty `related:` is allowed only if the spec genuinely has no vault dependencies; `/memex-sweep` will flag isolated specs.

    ## Context
    ```

- [ ] **Step 1.3**: Harden the `## After completing a spec` rule in `AGENTS.md`.

  Use `Edit`:
  - old:
    ```
    2. If there is at least one useful learning, create an atomic note in `context/learnings/` per learning (one concept per note) using `context/templates/learning.md`, and link it back to the spec folder with a wikilink. Add each new note to `context/_index/learnings.md` under the appropriate category.
    ```
  - new:
    ```
    2. If there is at least one useful learning, create an atomic note in `context/learnings/` per learning (one concept per note) using `context/templates/learning.md`. The new learning's `related:` field MUST include a wikilink back to the spec — bidirectional backlink is not optional. Symmetrically, if the spec gained a `related:` entry pointing at the new learning, add it. Add each new note to `context/_index/learnings.md` under the appropriate category.
    ```

- [ ] **Step 1.4**: Backfill `related:` on the shipped opensource-readiness spec.

  Use `Edit` on `context/specs/2026-04-30-opensource-readiness/spec-opensource-readiness.md`:
  - old:
    ```
    ---
    status: shipped
    feature: opensource-readiness
    created: 2026-04-30
    shipped: 2026-04-30
    ---
    ```
  - new:
    ```
    ---
    status: shipped
    feature: opensource-readiness
    created: 2026-04-30
    shipped: 2026-04-30
    related:
      - "[[../../learnings/vendoring-a-single-skill-loses-upstream-license]]"
    ---
    ```

- [ ] **Step 1.5**: Verify CLAUDE.md symlink intact (it propagates AGENTS.md changes).

  ```bash
  test -L CLAUDE.md && readlink CLAUDE.md
  ```

  Expected: `AGENTS.md`.

- [ ] **Step 1.6**: Commit.

  ```bash
  git add context/specs/_template/spec.md AGENTS.md context/specs/2026-04-30-opensource-readiness/spec-opensource-readiness.md
  git commit -m "feat(vault): add related: to spec template, harden post-spec backlink rule, backfill opensource-readiness"
  ```

---

## Phase 2 — Sweep `### Isolated specs` check

### Task 2: Add detector section + commit

**Files:**
- Modify: `.claude/commands/memex-sweep.md`
- Modify: `skills/memex/scaffold/commands/memex-sweep.md`

- [ ] **Step 2.1**: Read `.claude/commands/memex-sweep.md` to find the appropriate insertion point (after the existing checks list, before any closing summary).

- [ ] **Step 2.2**: Append the `### Isolated specs` section to `.claude/commands/memex-sweep.md`. Use `Edit`. The section to add:

  ```markdown
  ### Isolated specs

  For each `spec-*.md` under `context/specs/<date>-*/`, count outgoing wikilinks in body+frontmatter. Exclude wikilinks pointing to `plan-*` or `tasks-*` of the same folder (those are structural pairs, not knowledge cross-links).

  ```bash
  for spec in context/specs/[0-9]*-*/spec-*.md; do
    [ -f "$spec" ] || continue
    spec_dir=$(dirname "$spec")
    folder=$(basename "$spec_dir")
    # Count outgoing wikilinks excluding the plan/tasks intra-pair
    count=$(grep -oE '\[\[[^]]+\]\]' "$spec" \
            | grep -vE "(plan|tasks)-" \
            | sort -u | wc -l | tr -d ' ')
    if [ "$count" = "0" ]; then
      echo "ISLAND: $spec — zero outgoing wikilinks beyond plan/tasks pair."
      echo "  Suggest: /memex-link $folder"
    fi
  done
  ```

  An empty result is healthy. Any line beginning with `ISLAND:` is a finding to surface to the user under the sweep report's "Specs" section. The sweep does not auto-fix; it only reports.
  ```

  Insert this section in a logical position with other sweep checks (after the existing checks for orphan learnings / broken wikilinks, before any closing summary). If unsure, append at the end of the checks block.

- [ ] **Step 2.3**: Mirror the exact same section into `skills/memex/scaffold/commands/memex-sweep.md`.

  After editing both, verify they remain in sync:

  ```bash
  diff .claude/commands/memex-sweep.md skills/memex/scaffold/commands/memex-sweep.md
  ```

  Expected: empty (no diff).

- [ ] **Step 2.4**: Verify both files have the new section.

  ```bash
  grep -F "### Isolated specs" .claude/commands/memex-sweep.md skills/memex/scaffold/commands/memex-sweep.md
  ```

  Expected: 2 matches (one per file).

- [ ] **Step 2.5**: Commit.

  ```bash
  git add .claude/commands/memex-sweep.md skills/memex/scaffold/commands/memex-sweep.md
  git commit -m "feat(memex-sweep): add isolated-specs detector"
  ```

---

## Phase 3 — `memex-link` canonical skill (TDD)

### Task 3: Skeleton skill + first evidence type (`wikilink_in_body`)

**Files:**
- Create: `.agents/skills/memex-link/SKILL.md`
- Create: `.agents/skills/memex-link/scripts/find-candidates.sh`
- Create: `.agents/skills/memex-link/tests/run.sh`
- Create: `.agents/skills/memex-link/tests/expected-output.json`
- Create: `.agents/skills/memex-link/tests/fixtures/context/learnings/source-with-wikilink.md`
- Create: `.agents/skills/memex-link/tests/fixtures/context/learnings/target-of-wikilink.md`

- [ ] **Step 3.1**: Create the directory structure.

  ```bash
  mkdir -p .agents/skills/memex-link/scripts
  mkdir -p .agents/skills/memex-link/tests/fixtures/context/learnings
  mkdir -p .agents/skills/memex-link/tests/fixtures/context/specs/2026-01-01-test-spec
  ```

- [ ] **Step 3.2**: Write a stub `SKILL.md` (the full body comes in Task 9 — for now just frontmatter so Anthropic skill-loader doesn't choke).

  Create `.agents/skills/memex-link/SKILL.md`:

  ```markdown
  ---
  name: memex-link
  description: "Analyze the context/ vault for missing `related:` frontmatter cross-links and present suggestions interactively. Conservative: only surfaces high-evidence (wikilink already in body) and medium-evidence (filepath/title in body, or ≥2 shared title/H2 terms) candidates. Never edits without explicit per-item user confirmation. Use when the user runs /memex-link, when /memex-sweep flags an isolated spec, or as part of the After-completing-a-spec reflection."
  ---

  # Memex Link — Vault Cross-Link Suggestions

  *(Body authored in Task 9.)*
  ```

- [ ] **Step 3.3**: Create the first fixture pair: source with wikilink to target.

  `.agents/skills/memex-link/tests/fixtures/context/learnings/source-with-wikilink.md`:

  ```markdown
  ---
  tags:
    - learning
  related: []
  created: 2026-01-01
  ---
  # Source With Wikilink

  This note cites [[target-of-wikilink]] in its body.

  ## How It Works

  Just an example fixture.
  ```

  `.agents/skills/memex-link/tests/fixtures/context/learnings/target-of-wikilink.md`:

  ```markdown
  ---
  tags:
    - learning
  related: []
  created: 2026-01-01
  ---
  # Target Of Wikilink

  Plain target note. No outgoing wikilinks.

  ## Some Heading

  Body.
  ```

- [ ] **Step 3.4**: Write the expected JSON for this single fixture pair.

  `.agents/skills/memex-link/tests/expected-output.json`:

  ```json
  [
    {
      "source": "context/learnings/source-with-wikilink.md",
      "target": "context/learnings/target-of-wikilink.md",
      "source_title": "Source With Wikilink",
      "target_title": "Target Of Wikilink",
      "evidence_type": "wikilink_in_body",
      "evidence_detail": "[[target-of-wikilink]] cited at body line 3"
    }
  ]
  ```

- [ ] **Step 3.5**: Write the test runner.

  `.agents/skills/memex-link/tests/run.sh`:

  ```bash
  #!/usr/bin/env bash
  # Run find-candidates.sh against the bundled fixtures and diff vs expected JSON.
  set -euo pipefail

  cd "$(dirname "$0")/fixtures"

  actual=$(bash ../../scripts/find-candidates.sh)
  expected=$(cat ../expected-output.json)

  norm() { jq -S 'sort_by(.source, .target)' <<< "$1"; }

  if diff <(norm "$actual") <(norm "$expected") > /dev/null; then
    echo "PASS"
    exit 0
  else
    echo "FAIL"
    echo "--- expected ---"
    norm "$expected"
    echo "--- actual ---"
    norm "$actual"
    exit 1
  fi
  ```

  Make it executable:

  ```bash
  chmod +x .agents/skills/memex-link/tests/run.sh
  ```

- [ ] **Step 3.6**: Write the initial `find-candidates.sh` — handles `wikilink_in_body` only.

  `.agents/skills/memex-link/scripts/find-candidates.sh`:

  ```bash
  #!/usr/bin/env bash
  # find-candidates.sh — Detect missing related: cross-links in the memex vault.
  # Output: JSON array on stdout (or "[]" if no candidates).
  # Errors/warnings on stderr. Exit codes: 0 success, 2 fatal.
  # Usage: find-candidates.sh [scope]
  #   scope (optional): path, folder name, or empty (whole vault).
  # Requires: bash >= 3.2, jq, find, awk, grep, sort, comm, tr.
  set -euo pipefail

  SCOPE="${1:-}"

  if [ ! -d context ]; then
    echo "FATAL: context/ vault not found. Run from a directory containing context/." >&2
    exit 2
  fi

  # all_notes — emit one tracked note path per line; exclude templates and plan/tasks.
  all_notes() {
    find context/learnings context/conventions context/rules context/specs \
      -type f -name '*.md' 2>/dev/null \
      | grep -v '^context/specs/_template/' \
      | grep -Ev '/plan-[^/]+\.md$' \
      | grep -Ev '/tasks-[^/]+\.md$' \
      | sort
  }

  notes_in_scope() {
    if [ -z "$SCOPE" ]; then all_notes; return; fi
    if [ -f "$SCOPE" ]; then echo "$SCOPE"
    elif [ -d "$SCOPE" ]; then all_notes | grep "^${SCOPE%/}/"
    else all_notes | awk -v p="$SCOPE" 'index($0, p)' || true
    fi
  }

  extract_body() {
    awk 'BEGIN{n=0} /^---$/{n++; next} n>=2{print}' "$1"
  }

  extract_title() {
    extract_body "$1" | awk '/^# /{sub(/^# /,""); print; exit}'
  }

  emit_json() {
    jq -nc \
      --arg source "$1" --arg target "$2" \
      --arg source_title "$3" --arg target_title "$4" \
      --arg evidence_type "$5" --arg evidence_detail "$6" \
      '{source: $source, target: $target, source_title: $source_title, target_title: $target_title, evidence_type: $evidence_type, evidence_detail: $evidence_detail}'
  }

  emitted=$(mktemp)
  trap 'rm -f "$emitted"' EXIT

  sources=$(notes_in_scope)
  targets=$(all_notes)

  while IFS= read -r src; do
    [ -z "$src" ] && continue
    src_basename=$(basename "$src" .md)
    src_title=$(extract_title "$src"); [ -z "$src_title" ] && src_title="$src_basename"
    src_body=$(extract_body "$src")

    while IFS= read -r tgt; do
      [ -z "$tgt" ] && continue
      [ "$src" = "$tgt" ] && continue

      tgt_basename=$(basename "$tgt" .md)
      tgt_title=$(extract_title "$tgt"); [ -z "$tgt_title" ] && tgt_title="$tgt_basename"

      # Evidence: wikilink in body
      if printf '%s\n' "$src_body" | grep -qE "\[\[([^]|]*/)?$tgt_basename(\||\]\])"; then
        line=$(printf '%s\n' "$src_body" | grep -nE "\[\[([^]|]*/)?$tgt_basename(\||\]\])" | head -1 | cut -d: -f1)
        emit_json "$src" "$tgt" "$src_title" "$tgt_title" \
          "wikilink_in_body" "[[$tgt_basename]] cited at body line $line" >> "$emitted"
      fi
    done <<< "$targets"
  done <<< "$sources"

  if [ ! -s "$emitted" ]; then
    echo "[]"
  else
    jq -s '.' "$emitted"
  fi
  ```

  Make it executable:

  ```bash
  chmod +x .agents/skills/memex-link/scripts/find-candidates.sh
  ```

- [ ] **Step 3.7**: Run the test.

  ```bash
  bash .agents/skills/memex-link/tests/run.sh
  ```

  Expected: `PASS`. If `FAIL`, inspect the printed diff and fix until green. Common issues: line number off-by-one (verify the wikilink is actually on body line 3 of the fixture), missing chmod on script, jq not installed.

### Task 4: Add `filepath_in_body`, `title_in_body`, `shared_heading_terms`

**Files:**
- Modify: `.agents/skills/memex-link/scripts/find-candidates.sh`
- Modify: `.agents/skills/memex-link/tests/expected-output.json`
- Create: 6 fixture files (3 source/target pairs)

- [ ] **Step 4.1**: Create three new fixture pairs.

  `.agents/skills/memex-link/tests/fixtures/context/learnings/source-with-filepath.md`:

  ```markdown
  ---
  tags:
    - learning
  related: []
  created: 2026-01-01
  ---
  # Source With Filepath

  This note mentions context/learnings/target-with-filepath.md as a path reference.

  ## Body

  Some content.
  ```

  `.agents/skills/memex-link/tests/fixtures/context/learnings/target-with-filepath.md`:

  ```markdown
  ---
  tags:
    - learning
  related: []
  created: 2026-01-01
  ---
  # Target With Filepath

  Plain target.
  ```

  `.agents/skills/memex-link/tests/fixtures/context/learnings/source-with-title-mention.md`:

  ```markdown
  ---
  tags:
    - learning
  related: []
  created: 2026-01-01
  ---
  # Source With Title Mention

  This note mentions Distinctive Phrase Title in its body, exactly like the target's H1.

  ## Body

  Just so the script's title-search heuristic finds it.
  ```

  `.agents/skills/memex-link/tests/fixtures/context/learnings/target-distinctive-phrase-title.md`:

  ```markdown
  ---
  tags:
    - learning
  related: []
  created: 2026-01-01
  ---
  # Distinctive Phrase Title

  Plain target. The H1 is the matchable phrase.
  ```

  `.agents/skills/memex-link/tests/fixtures/context/learnings/source-shared-headings-A.md`:

  ```markdown
  ---
  tags:
    - learning
  related: []
  created: 2026-01-01
  ---
  # Source Shared Headings A

  ## Migration Strategy

  ## Rollback Procedure

  Body.
  ```

  `.agents/skills/memex-link/tests/fixtures/context/learnings/source-shared-headings-B.md`:

  ```markdown
  ---
  tags:
    - learning
  related: []
  created: 2026-01-01
  ---
  # Source Shared Headings B

  ## Migration Strategy

  ## Rollback Procedure

  Body.
  ```

  Note: the two shared-heading sources will produce *bidirectional* emissions (A→B and B→A) because each one is a source with the other as candidate target. That's correct behavior.

- [ ] **Step 4.2**: Update `expected-output.json` to include the new candidates.

  Replace the entire file with:

  ```json
  [
    {
      "source": "context/learnings/source-shared-headings-A.md",
      "target": "context/learnings/source-shared-headings-B.md",
      "source_title": "Source Shared Headings A",
      "target_title": "Source Shared Headings B",
      "evidence_type": "shared_heading_terms",
      "evidence_detail": "shared title/H2 terms: headings,migration,procedure,rollback,shared,source,strategy"
    },
    {
      "source": "context/learnings/source-shared-headings-B.md",
      "target": "context/learnings/source-shared-headings-A.md",
      "source_title": "Source Shared Headings B",
      "target_title": "Source Shared Headings A",
      "evidence_type": "shared_heading_terms",
      "evidence_detail": "shared title/H2 terms: headings,migration,procedure,rollback,shared,source,strategy"
    },
    {
      "source": "context/learnings/source-with-filepath.md",
      "target": "context/learnings/target-with-filepath.md",
      "source_title": "Source With Filepath",
      "target_title": "Target With Filepath",
      "evidence_type": "filepath_in_body",
      "evidence_detail": "filepath 'context/learnings/target-with-filepath.md' at body line 3"
    },
    {
      "source": "context/learnings/source-with-title-mention.md",
      "target": "context/learnings/target-distinctive-phrase-title.md",
      "source_title": "Source With Title Mention",
      "target_title": "Distinctive Phrase Title",
      "evidence_type": "title_in_body",
      "evidence_detail": "title 'Distinctive Phrase Title' at body line 3"
    },
    {
      "source": "context/learnings/source-with-wikilink.md",
      "target": "context/learnings/target-of-wikilink.md",
      "source_title": "Source With Wikilink",
      "target_title": "Target Of Wikilink",
      "evidence_type": "wikilink_in_body",
      "evidence_detail": "[[target-of-wikilink]] cited at body line 3"
    }
  ]
  ```

  (The runner sorts by source+target before diffing, so order in the file is irrelevant — but kept alphabetical for readability.)

- [ ] **Step 4.3**: Run the test before extending the script — it should FAIL (expected JSON now has 5 entries; script produces only 1).

  ```bash
  bash .agents/skills/memex-link/tests/run.sh
  ```

  Expected: `FAIL` with diff showing 4 missing entries.

- [ ] **Step 4.4**: Replace `find-candidates.sh` with the extended version. Full content:

  ```bash
  #!/usr/bin/env bash
  # find-candidates.sh — Detect missing related: cross-links in the memex vault.
  # Output: JSON array on stdout (or "[]" if no candidates).
  # Errors/warnings on stderr. Exit codes: 0 success, 2 fatal.
  # Usage: find-candidates.sh [scope]
  set -euo pipefail

  SCOPE="${1:-}"

  if [ ! -d context ]; then
    echo "FATAL: context/ vault not found. Run from a directory containing context/." >&2
    exit 2
  fi

  STOPWORDS_RE='^(the|a|an|of|in|on|by|and|or|for|to|with|is|this|that|repo|skill|skills|vault|agent|agents|context|note|notes|learning|learnings|spec|specs|how|what|why|when|where|works|use|using|over)$'

  all_notes() {
    find context/learnings context/conventions context/rules context/specs \
      -type f -name '*.md' 2>/dev/null \
      | grep -v '^context/specs/_template/' \
      | grep -Ev '/plan-[^/]+\.md$' \
      | grep -Ev '/tasks-[^/]+\.md$' \
      | sort
  }

  notes_in_scope() {
    if [ -z "$SCOPE" ]; then all_notes; return; fi
    if [ -f "$SCOPE" ]; then echo "$SCOPE"
    elif [ -d "$SCOPE" ]; then all_notes | grep "^${SCOPE%/}/"
    else all_notes | awk -v p="$SCOPE" 'index($0, p)' || true
    fi
  }

  extract_body() {
    awk 'BEGIN{n=0} /^---$/{n++; next} n>=2{print}' "$1"
  }

  extract_title() {
    extract_body "$1" | awk '/^# /{sub(/^# /,""); print; exit}'
  }

  extract_h2s() {
    extract_body "$1" | awk '/^## /{sub(/^## /,""); print}'
  }

  tokenize() {
    tr '[:upper:]' '[:lower:]' \
      | tr -cs '[:alnum:]' '\n' \
      | awk 'length($0) >= 3' \
      | grep -Ev "$STOPWORDS_RE" \
      | sort -u
  }

  emit_json() {
    jq -nc \
      --arg source "$1" --arg target "$2" \
      --arg source_title "$3" --arg target_title "$4" \
      --arg evidence_type "$5" --arg evidence_detail "$6" \
      '{source: $source, target: $target, source_title: $source_title, target_title: $target_title, evidence_type: $evidence_type, evidence_detail: $evidence_detail}'
  }

  emitted=$(mktemp)
  trap 'rm -f "$emitted"' EXIT

  sources=$(notes_in_scope)
  targets=$(all_notes)

  while IFS= read -r src; do
    [ -z "$src" ] && continue
    src_basename=$(basename "$src" .md)
    src_title=$(extract_title "$src"); [ -z "$src_title" ] && src_title="$src_basename"
    src_body=$(extract_body "$src")
    src_title_tokens=$(printf '%s\n' "$src_title" | tokenize)
    src_h2_tokens=$(extract_h2s "$src" | tokenize)

    while IFS= read -r tgt; do
      [ -z "$tgt" ] && continue
      [ "$src" = "$tgt" ] && continue

      tgt_basename=$(basename "$tgt" .md)
      tgt_title=$(extract_title "$tgt"); [ -z "$tgt_title" ] && tgt_title="$tgt_basename"

      evidence=""; detail=""

      # Evidence 1: wikilink in body
      if printf '%s\n' "$src_body" | grep -qE "\[\[([^]|]*/)?$tgt_basename(\||\]\])"; then
        line=$(printf '%s\n' "$src_body" | grep -nE "\[\[([^]|]*/)?$tgt_basename(\||\]\])" | head -1 | cut -d: -f1)
        evidence="wikilink_in_body"; detail="[[$tgt_basename]] cited at body line $line"

      # Evidence 2: filepath in body
      elif printf '%s\n' "$src_body" | grep -qF "$tgt"; then
        line=$(printf '%s\n' "$src_body" | grep -nF "$tgt" | head -1 | cut -d: -f1)
        evidence="filepath_in_body"; detail="filepath '$tgt' at body line $line"

      # Evidence 3: title in body (only for titles >= 10 chars to reduce false positives)
      elif [ -n "$tgt_title" ] && [ "${#tgt_title}" -ge 10 ] \
           && printf '%s\n' "$src_body" | grep -qiF "$tgt_title"; then
        line=$(printf '%s\n' "$src_body" | grep -niF "$tgt_title" | head -1 | cut -d: -f1)
        evidence="title_in_body"; detail="title '$tgt_title' at body line $line"

      # Evidence 4: shared title+H2 tokens >= 2
      else
        tgt_title_tokens=$(printf '%s\n' "$tgt_title" | tokenize)
        tgt_h2_tokens=$(extract_h2s "$tgt" | tokenize)
        src_combined=$(printf '%s\n%s\n' "$src_title_tokens" "$src_h2_tokens" | sort -u | grep -v '^$' || true)
        tgt_combined=$(printf '%s\n%s\n' "$tgt_title_tokens" "$tgt_h2_tokens" | sort -u | grep -v '^$' || true)
        shared=$(comm -12 <(printf '%s\n' "$src_combined") <(printf '%s\n' "$tgt_combined") | grep -v '^$' || true)
        shared_count=$(printf '%s\n' "$shared" | grep -c . 2>/dev/null || echo 0)
        if [ "$shared_count" -ge 2 ]; then
          evidence="shared_heading_terms"
          detail="shared title/H2 terms: $(printf '%s\n' "$shared" | tr '\n' ',' | sed 's/,$//')"
        fi
      fi

      if [ -n "$evidence" ]; then
        emit_json "$src" "$tgt" "$src_title" "$tgt_title" "$evidence" "$detail" >> "$emitted"
      fi

    done <<< "$targets"
  done <<< "$sources"

  if [ ! -s "$emitted" ]; then
    echo "[]"
  else
    jq -s '.' "$emitted"
  fi
  ```

- [ ] **Step 4.5**: Run the test again.

  ```bash
  bash .agents/skills/memex-link/tests/run.sh
  ```

  Expected: `PASS`. Common pitfall: token-overlap detail string differs from expected because comm output ordering matches sort order — verify that `migration,procedure,rollback,strategy` is the alphabetical order produced by `tokenize` + `comm`. If not, update either the script or the expected JSON to match.

### Task 5: Filters — already-in-related, plan/tasks intra-pair, self-reference

**Files:**
- Modify: `.agents/skills/memex-link/scripts/find-candidates.sh`
- Modify: `.agents/skills/memex-link/tests/expected-output.json`
- Create: 4 new fixture files (one filter case + a spec folder with plan/tasks)

- [ ] **Step 5.1**: Create the "already in related" fixture pair. The titles are intentionally chosen so that title-token overlap between the two is below threshold — otherwise `shared_heading_terms` would trigger a reverse emission and mask whether the filter is doing its job.

  `.agents/skills/memex-link/tests/fixtures/context/learnings/already-citing-source.md`:

  ```markdown
  ---
  tags:
    - learning
  related:
    - "[[already-cited-target]]"
  created: 2026-01-01
  ---
  # Citing Source

  This note also cites [[already-cited-target]] in its body, but should NOT be emitted because target is already in `related:`.

  ## Body

  Filter test.
  ```

  `.agents/skills/memex-link/tests/fixtures/context/learnings/already-cited-target.md`:

  ```markdown
  ---
  tags:
    - learning
  related: []
  created: 2026-01-01
  ---
  # Cited Target

  Plain target. Should never be a suggested addition because the source already lists it.

  ## Body

  Filter test.
  ```

- [ ] **Step 5.2**: Create the spec folder fixture with plan/tasks pair.

  `.agents/skills/memex-link/tests/fixtures/context/specs/2026-01-01-test-spec/spec-test-spec.md`:

  ```markdown
  ---
  status: draft
  feature: test-spec
  created: 2026-01-01
  shipped: null
  related: []
  ---
  # Test Spec

  Body has no wikilinks. Pair with plan-test-spec and tasks-test-spec must NOT emit (intra-pair filter).

  ## Context

  Filter fixture.
  ```

  `.agents/skills/memex-link/tests/fixtures/context/specs/2026-01-01-test-spec/plan-test-spec.md`:

  ```markdown
  ---
  feature: test-spec
  spec: "[[spec-test-spec]]"
  created: 2026-01-01
  ---
  # Test Spec — Plan

  Plan body. Should be excluded from sources by the plan-* filter, and from targets when source is the spec.
  ```

  `.agents/skills/memex-link/tests/fixtures/context/specs/2026-01-01-test-spec/tasks-test-spec.md`:

  ```markdown
  ---
  feature: test-spec
  plan: "[[plan-test-spec]]"
  spec: "[[spec-test-spec]]"
  created: 2026-01-01
  ---
  # Test Spec — Tasks

  Tasks body. Excluded from sources; excluded from targets when source is the spec.
  ```

- [ ] **Step 5.3**: Update `expected-output.json` — same as Task 4's, plus no new entries (filters should suppress all the new fixtures).

  Confirm: the filter cases should produce ZERO additional emissions. The expected JSON from Task 4.2 stays valid as-is. **Do not modify it.**

- [ ] **Step 5.4**: Run the test before extending the script — it should FAIL because the current script doesn't apply the filters and will emit pairs for the new fixtures.

  ```bash
  bash .agents/skills/memex-link/tests/run.sh
  ```

  Expected: `FAIL` with diff showing extra entries (intra-pair pairs for the spec, plus a wikilink emission for source-already-related → target-already-related).

- [ ] **Step 5.5**: Replace `find-candidates.sh` with the filter-extended version. The diff from Task 4's version is: an `extract_related_basenames` function, an `is_plan_tasks_intra_pair` helper, and two new filter clauses inside the main loop.

  Replace the script's entire content with:

  ```bash
  #!/usr/bin/env bash
  # find-candidates.sh — Detect missing related: cross-links in the memex vault.
  # Output: JSON array on stdout (or "[]" if no candidates).
  # Errors/warnings on stderr. Exit codes: 0 success, 2 fatal.
  # Usage: find-candidates.sh [scope]
  set -euo pipefail

  SCOPE="${1:-}"

  if [ ! -d context ]; then
    echo "FATAL: context/ vault not found. Run from a directory containing context/." >&2
    exit 2
  fi

  STOPWORDS_RE='^(the|a|an|of|in|on|by|and|or|for|to|with|is|this|that|repo|skill|skills|vault|agent|agents|context|note|notes|learning|learnings|spec|specs|how|what|why|when|where|works|use|using|over)$'

  all_notes() {
    find context/learnings context/conventions context/rules context/specs \
      -type f -name '*.md' 2>/dev/null \
      | grep -v '^context/specs/_template/' \
      | grep -Ev '/plan-[^/]+\.md$' \
      | grep -Ev '/tasks-[^/]+\.md$' \
      | sort
  }

  notes_in_scope() {
    if [ -z "$SCOPE" ]; then all_notes; return; fi
    if [ -f "$SCOPE" ]; then echo "$SCOPE"
    elif [ -d "$SCOPE" ]; then all_notes | grep "^${SCOPE%/}/"
    else all_notes | awk -v p="$SCOPE" 'index($0, p)' || true
    fi
  }

  extract_body() {
    awk 'BEGIN{n=0} /^---$/{n++; next} n>=2{print}' "$1"
  }

  extract_title() {
    extract_body "$1" | awk '/^# /{sub(/^# /,""); print; exit}'
  }

  extract_h2s() {
    extract_body "$1" | awk '/^## /{sub(/^## /,""); print}'
  }

  # extract_related_basenames — frontmatter related[] slugs, one per line.
  extract_related_basenames() {
    awk '
      BEGIN{n=0; in_rel=0}
      /^---$/{n++; if(n>=2)exit; next}
      n==1 && /^related:/{in_rel=1; next}
      n==1 && in_rel && /^[a-zA-Z][a-zA-Z_-]*:/{in_rel=0}
      n==1 && in_rel && /^[[:space:]]*-[[:space:]]/{
        sub(/^[[:space:]]*-[[:space:]]*/, "")
        sub(/^"?\[\[/, "")
        sub(/\]\]"?[[:space:]]*$/, "")
        i = index($0, "|")
        if (i) $0 = substr($0, 1, i-1)
        n2 = match($0, /\/[^\/]+$/)
        if (n2) $0 = substr($0, n2+1)
        print
      }
    ' "$1"
  }

  tokenize() {
    tr '[:upper:]' '[:lower:]' \
      | tr -cs '[:alnum:]' '\n' \
      | awk 'length($0) >= 3' \
      | grep -Ev "$STOPWORDS_RE" \
      | sort -u
  }

  is_plan_tasks_intra_pair() {
    local src="$1" tgt="$2"
    local src_dir tgt_dir tgt_base
    src_dir=$(dirname "$src")
    tgt_dir=$(dirname "$tgt")
    tgt_base=$(basename "$tgt")
    if [ "$src_dir" = "$tgt_dir" ]; then
      case "$tgt_base" in
        plan-*|tasks-*) return 0 ;;
      esac
    fi
    return 1
  }

  emit_json() {
    jq -nc \
      --arg source "$1" --arg target "$2" \
      --arg source_title "$3" --arg target_title "$4" \
      --arg evidence_type "$5" --arg evidence_detail "$6" \
      '{source: $source, target: $target, source_title: $source_title, target_title: $target_title, evidence_type: $evidence_type, evidence_detail: $evidence_detail}'
  }

  emitted=$(mktemp)
  trap 'rm -f "$emitted"' EXIT

  sources=$(notes_in_scope)
  targets=$(all_notes)

  while IFS= read -r src; do
    [ -z "$src" ] && continue
    src_basename=$(basename "$src" .md)
    src_title=$(extract_title "$src"); [ -z "$src_title" ] && src_title="$src_basename"
    src_body=$(extract_body "$src")
    src_related=$(extract_related_basenames "$src")
    src_title_tokens=$(printf '%s\n' "$src_title" | tokenize)
    src_h2_tokens=$(extract_h2s "$src" | tokenize)

    while IFS= read -r tgt; do
      [ -z "$tgt" ] && continue
      [ "$src" = "$tgt" ] && continue

      tgt_basename=$(basename "$tgt" .md)

      # Filter: target already in source's related
      if printf '%s\n' "$src_related" | grep -qxF "$tgt_basename"; then
        continue
      fi

      # Filter: plan/tasks intra-pair within same spec folder
      if is_plan_tasks_intra_pair "$src" "$tgt"; then
        continue
      fi

      tgt_title=$(extract_title "$tgt"); [ -z "$tgt_title" ] && tgt_title="$tgt_basename"

      evidence=""; detail=""

      if printf '%s\n' "$src_body" | grep -qE "\[\[([^]|]*/)?$tgt_basename(\||\]\])"; then
        line=$(printf '%s\n' "$src_body" | grep -nE "\[\[([^]|]*/)?$tgt_basename(\||\]\])" | head -1 | cut -d: -f1)
        evidence="wikilink_in_body"; detail="[[$tgt_basename]] cited at body line $line"
      elif printf '%s\n' "$src_body" | grep -qF "$tgt"; then
        line=$(printf '%s\n' "$src_body" | grep -nF "$tgt" | head -1 | cut -d: -f1)
        evidence="filepath_in_body"; detail="filepath '$tgt' at body line $line"
      elif [ -n "$tgt_title" ] && [ "${#tgt_title}" -ge 10 ] \
           && printf '%s\n' "$src_body" | grep -qiF "$tgt_title"; then
        line=$(printf '%s\n' "$src_body" | grep -niF "$tgt_title" | head -1 | cut -d: -f1)
        evidence="title_in_body"; detail="title '$tgt_title' at body line $line"
      else
        tgt_title_tokens=$(printf '%s\n' "$tgt_title" | tokenize)
        tgt_h2_tokens=$(extract_h2s "$tgt" | tokenize)
        src_combined=$(printf '%s\n%s\n' "$src_title_tokens" "$src_h2_tokens" | sort -u | grep -v '^$' || true)
        tgt_combined=$(printf '%s\n%s\n' "$tgt_title_tokens" "$tgt_h2_tokens" | sort -u | grep -v '^$' || true)
        shared=$(comm -12 <(printf '%s\n' "$src_combined") <(printf '%s\n' "$tgt_combined") | grep -v '^$' || true)
        shared_count=$(printf '%s\n' "$shared" | grep -c . 2>/dev/null || echo 0)
        if [ "$shared_count" -ge 2 ]; then
          evidence="shared_heading_terms"
          detail="shared title/H2 terms: $(printf '%s\n' "$shared" | tr '\n' ',' | sed 's/,$//')"
        fi
      fi

      if [ -n "$evidence" ]; then
        emit_json "$src" "$tgt" "$src_title" "$tgt_title" "$evidence" "$detail" >> "$emitted"
      fi

    done <<< "$targets"
  done <<< "$sources"

  if [ ! -s "$emitted" ]; then
    echo "[]"
  else
    jq -s '.' "$emitted"
  fi
  ```

- [ ] **Step 5.6**: Run the test.

  ```bash
  bash .agents/skills/memex-link/tests/run.sh
  ```

  Expected: `PASS`. The fixtures from Task 4 still produce 5 emissions; the new filter fixtures from Task 5 produce zero (covered by filters).

### Task 6: Write the SKILL.md body + commit Phase 3

**Files:**
- Modify: `.agents/skills/memex-link/SKILL.md`

- [ ] **Step 6.1**: Replace the stub body in `SKILL.md` with the full procedure. Keep the existing frontmatter.

  Use `Edit`:
  - old:
    ```
    # Memex Link — Vault Cross-Link Suggestions

    *(Body authored in Task 9.)*
    ```
  - new:
    ```
    # Memex Link — Vault Cross-Link Suggestions

    Analyze the `context/` vault and surface candidate `related:` frontmatter additions where genuinely necessary.

    **Announce at start:** "Analyzing vault for missing cross-links..."

    ## Mode of Operation

    Four phases. Detection is deterministic (Bash). Presentation and editing are interactive (agent + user).

    1. **Detect** — invoke `scripts/find-candidates.sh "$SCOPE"` (where `$SCOPE` is the optional argument from the slash command).
    2. **Classify** — read JSON from stdout; map `evidence_type` to confidence (high/medium).
    3. **Present** — render markdown table grouped by confidence, with one-line rationale.
    4. **Loop** — interactive y/n/skip-rest per item; on `y`, edit source's `related:` frontmatter to add the wikilink.

    If no candidates surface, say `No cross-link suggestions. Vault is well-connected.` and stop.

    ## Phase 1 — Detect

    Sanity-check `command -v jq` first — if absent, abort with `memex-link requires jq. Install with: brew install jq` (or platform-appropriate hint).

    Then run the deterministic detector:

    ```bash
    SCOPE="$1"   # optional argument from slash command
    SKILL_DIR="$(dirname "$(readlink -f "$0" 2>/dev/null || realpath "$0")")"
    bash "$SKILL_DIR/scripts/find-candidates.sh" "$SCOPE" > /tmp/memex-link-candidates.json
    ```

    If the script exits with code 2, surface its stderr and stop. If exit 0 and stdout is `[]`, report "Vault is well-connected" and stop.

    ## Phase 2 — Classify

    For each candidate, map `evidence_type` to confidence:

    | `evidence_type` | Confidence |
    |---|---|
    | `wikilink_in_body` | high |
    | `filepath_in_body` | medium |
    | `title_in_body` | medium |
    | `shared_heading_terms` | medium |

    No "low" bucket; the script does not emit anything that would qualify.

    ## Phase 3 — Present

    Render a markdown table grouped by confidence:

    ```markdown
    ## Cross-Link Suggestions — N candidates (H high, M medium)

    | # | conf | source → target | rationale |
    |---|---|---|---|
    | 1 | high | spec-rename… → memex | wikilink in body line 14 |
    | 2 | medium | sweep → mechanical-enforcement-over-prose | shared H2 terms: feedforward, feedback |
    ```

    ## Phase 4 — Interactive loop

    For each candidate, in order, prompt the user:

    ```
    [1/3] HIGH — context/specs/.../spec-X.md → context/learnings/Y.md
           Reason: wikilink in body line 14

           Add to source's `related:`? (y/n/skip-rest)
    ```

    Receive user input (single character):

    - **`y`** — edit the source's frontmatter:
        - Read source file
        - Locate the YAML frontmatter (between the first two `---` fences)
        - Find or insert the `related:` field
        - Add a wikilink to the target using the canonical relative path: from source's directory to target's path. Compute with `realpath --relative-to=$(dirname source) target` (or equivalent for macOS).
            - For specs/&lt;date&gt;/spec-X.md → learnings/Y.md, the wikilink is `[[../../learnings/Y]]`.
            - For learnings/X.md → learnings/Y.md, the wikilink is `[[Y]]`.
        - Write the file back. Use multi-line block list form for `related:` (uniformity with existing notes).
        - **Edit safety**: re-stat the source file's mtime before writing. If mtime > the time at which Phase 1 ran, abort that single edit with `Source modified externally — skipping.` Continue loop.
        - **Edit safety**: if the existing `related:` value is not a list (e.g., a string or mapping), abort that single edit with `Cannot edit <path>: related field has unexpected shape. Skipping. Open the file and fix manually.` Continue loop.

    - **`n`** — skip; record locally as rejected (not persisted across runs); continue.

    - **`skip-rest`** or `s` — terminate the loop.

    After the loop, print summary:

    ```
    Done. N accepted, M rejected, K skipped.
    Edits applied to: <list of files>
    ```

    Do not auto-commit. The user decides when.

    ## Self-test

    The skill ships a fixture-based test for the deterministic detector. To run:

    ```bash
    bash .agents/skills/memex-link/tests/run.sh
    ```

    Expected output: `PASS`. Run before committing any change to the script.
    ```

- [ ] **Step 6.2**: Verify scripts and tests are executable.

  ```bash
  chmod +x .agents/skills/memex-link/scripts/find-candidates.sh
  chmod +x .agents/skills/memex-link/tests/run.sh
  ls -l .agents/skills/memex-link/scripts/find-candidates.sh .agents/skills/memex-link/tests/run.sh
  ```

  Both should show executable bits (`-rwxr-xr-x` or similar).

- [ ] **Step 6.3**: Final test run.

  ```bash
  bash .agents/skills/memex-link/tests/run.sh
  ```

  Expected: `PASS`.

- [ ] **Step 6.4**: Commit Phase 3.

  ```bash
  git add .agents/skills/memex-link/
  git status --short
  git commit -m "feat(memex-link): canonical skill with TDD-tested deterministic detector"
  ```

---

## Phase 4 — Wiring (symlink + slash command + scaffold mirror)

### Task 7: Per-agent symlink + slash command + scaffold mirrors

**Files:**
- Create: `.claude/skills/memex-link` (symlink)
- Create: `.claude/commands/memex-link.md`
- Create: `skills/memex/scaffold/skills/memex-link/` (mirror of canonical)
- Create: `skills/memex/scaffold/commands/memex-link.md` (mirror of slash command)

- [ ] **Step 7.1**: Create the per-agent symlink.

  ```bash
  ln -s ../../.agents/skills/memex-link .claude/skills/memex-link
  [ -e .claude/skills/memex-link ] && echo OK || echo BROKEN
  ```

  Expected: `OK`.

- [ ] **Step 7.2**: Create the slash command file.

  `.claude/commands/memex-link.md`:

  ```markdown
  ---
  description: "Analyze vault for missing related: cross-links and present suggestions interactively"
  argument-hint: "<optional: path or folder to scope analysis>"
  ---

  Use the `memex-link` skill. Argument scope: $ARGUMENTS
  ```

- [ ] **Step 7.3**: Create the scaffold mirror — copy canonical skill to scaffold.

  ```bash
  mkdir -p skills/memex/scaffold/skills
  cp -r .agents/skills/memex-link skills/memex/scaffold/skills/memex-link
  diff -r .agents/skills/memex-link/ skills/memex/scaffold/skills/memex-link/ | head
  ```

  Expected: empty output (no diff). If there are file-mode differences, recopy with preserve flags.

- [ ] **Step 7.4**: Create the scaffold mirror of the slash command.

  ```bash
  cp .claude/commands/memex-link.md skills/memex/scaffold/commands/memex-link.md
  diff .claude/commands/memex-link.md skills/memex/scaffold/commands/memex-link.md
  ```

  Expected: empty (no diff).

- [ ] **Step 7.5**: Commit Phase 4.

  ```bash
  git add .claude/skills/memex-link .claude/commands/memex-link.md skills/memex/scaffold/skills/memex-link skills/memex/scaffold/commands/memex-link.md
  git status --short
  git commit -m "feat(memex-link): per-agent symlink, slash command, and scaffold mirrors"
  ```

---

## Phase 5 — Memex scaffolder integration

### Task 8: Update memex SKILL.md SKILL_NAMES + cmd loop

**Files:**
- Modify: `skills/memex/SKILL.md`

- [ ] **Step 8.1**: Add `memex-link` to the `SKILL_NAMES` array.

  Use `Edit`:
  - old: `SKILL_NAMES=(memex-recall memex-brainstorming memex-writing-plans)`
  - new: `SKILL_NAMES=(memex-recall memex-brainstorming memex-writing-plans memex-link)`

- [ ] **Step 8.2**: Add `memex-link` to the slash-command loop.

  Use `Edit`:
  - old: `for cmd in memex-open-pr memex-learn memex-spec memex-review-spec memex-sweep; do`
  - new: `for cmd in memex-open-pr memex-learn memex-spec memex-review-spec memex-sweep memex-link; do`

- [ ] **Step 8.3**: Verify both edits.

  ```bash
  grep -F "memex-link" skills/memex/SKILL.md
  ```

  Expected: at least 2 matches (one in each list).

### Task 9: Update audit-checklist.md inventory

**Files:**
- Modify: `skills/memex/references/audit-checklist.md`

- [ ] **Step 9.1**: Read the file to find the bundled-skills inventory list.

  ```bash
  grep -n "memex-recall\|memex-brainstorming\|memex-writing-plans" skills/memex/references/audit-checklist.md
  ```

- [ ] **Step 9.2**: Add `.agents/skills/memex-link/` to the inventory after the existing bundled-skills entries. Use `Edit` with the appropriate surrounding context for uniqueness.

  Locate the line containing `.agents/skills/memex-writing-plans/` and add a sibling line for `memex-link`. Example:

  - old:
    ```
    .agents/skills/memex-writing-plans/             (full directory)
    ```
  - new:
    ```
    .agents/skills/memex-writing-plans/             (full directory)
    .agents/skills/memex-link/                      (full directory — vault cross-link analyzer)
    ```

- [ ] **Step 9.3**: Add `.claude/commands/memex-link.md` to the slash-commands inventory. Use `Edit`:

  - old:
    ```
    .claude/commands/memex-sweep.md
    ```
  - new:
    ```
    .claude/commands/memex-sweep.md
    .claude/commands/memex-link.md
    ```

- [ ] **Step 9.4**: Verify.

  ```bash
  grep -F "memex-link" skills/memex/references/audit-checklist.md
  ```

  Expected: 2 matches (skill dir + command file).

### Task 10: Update validation.md checks #9 and #11

**Files:**
- Modify: `skills/memex/references/validation.md`

- [ ] **Step 10.1**: Update check #9's hardcoded skill list.

  Use `Edit`:
  - old: `for s in memex-recall memex-brainstorming memex-writing-plans; do`
  - new: `for s in memex-recall memex-brainstorming memex-writing-plans memex-link; do`

- [ ] **Step 10.2**: Update check #11's hardcoded command list.

  Use `Edit`:
  - old: `for c in memex-open-pr memex-learn memex-spec memex-review-spec memex-sweep; do`
  - new: `for c in memex-open-pr memex-learn memex-spec memex-review-spec memex-sweep memex-link; do`

- [ ] **Step 10.3**: Verify both edits.

  ```bash
  grep -F "memex-link" skills/memex/references/validation.md
  ```

  Expected: 2 matches.

- [ ] **Step 10.4**: Commit Phase 5.

  ```bash
  git add skills/memex/SKILL.md skills/memex/references/audit-checklist.md skills/memex/references/validation.md
  git status --short
  git commit -m "feat(memex): register memex-link in scaffolder, audit-checklist, validation"
  ```

---

## Phase 6 — Validation

### Task 11: Run all 19 acceptance criteria from the spec

**Files:** none modified — read-only verification.

- [ ] **Step 11.1**: AC #1 — template `related: []` + body note.

  ```bash
  grep -F 'related: []' context/specs/_template/spec.md
  grep -F 'Note on `related:` frontmatter' context/specs/_template/spec.md
  ```

  Both must return matches.

- [ ] **Step 11.2**: AC #2 — AGENTS.md hardening.

  ```bash
  grep -F "MUST include a wikilink back to the spec" AGENTS.md
  ```

  Must return a non-empty match.

- [ ] **Step 11.3**: AC #3 — sweep `### Isolated specs` section in both copies.

  ```bash
  grep -lF "### Isolated specs" .claude/commands/memex-sweep.md skills/memex/scaffold/commands/memex-sweep.md
  ```

  Expected: both file paths printed.

- [ ] **Step 11.4**: AC #4 — opensource-readiness `related:` populated.

  ```bash
  awk '/^---$/{n++} n==2{exit} {print}' context/specs/2026-04-30-opensource-readiness/spec-opensource-readiness.md \
    | grep -c '^[[:space:]]*-[[:space:]]*"\[\['
  ```

  Expected: ≥ 1.

- [ ] **Step 11.5**: AC #5 — canonical SKILL.md frontmatter.

  ```bash
  grep '^name: memex-link$' .agents/skills/memex-link/SKILL.md
  grep -F 'analyze' .agents/skills/memex-link/SKILL.md | head -1
  ```

  Both must return matches.

- [ ] **Step 11.6**: AC #6 — detector script exists and is executable.

  ```bash
  test -x .agents/skills/memex-link/scripts/find-candidates.sh && echo OK
  ```

  Expected: `OK`.

- [ ] **Step 11.7**: AC #7 — slash command exists.

  ```bash
  grep -F "memex-link" .claude/commands/memex-link.md
  ```

  Expected: at least one match.

- [ ] **Step 11.8**: AC #8 — scaffold byte-equivalence.

  ```bash
  diff -r .agents/skills/memex-link/ skills/memex/scaffold/skills/memex-link/
  diff .claude/commands/memex-link.md skills/memex/scaffold/commands/memex-link.md
  ```

  Both must produce zero output.

- [ ] **Step 11.9**: AC #9 — memex SKILL.md SKILL_NAMES + cmd loop.

  ```bash
  grep -cF "memex-link" skills/memex/SKILL.md
  ```

  Expected: ≥ 2.

- [ ] **Step 11.10**: AC #10 — audit-checklist inventory.

  ```bash
  grep -F '.agents/skills/memex-link/' skills/memex/references/audit-checklist.md
  grep -F '.claude/commands/memex-link.md' skills/memex/references/audit-checklist.md
  ```

  Both must return matches.

- [ ] **Step 11.11**: AC #11 — validation.md check #9 hardcoded array.

  ```bash
  grep -F 'memex-recall memex-brainstorming memex-writing-plans memex-link' skills/memex/references/validation.md
  ```

  Expected: match found.

- [ ] **Step 11.12**: AC #12 — validation.md check #11 hardcoded list.

  ```bash
  grep -F 'memex-link' skills/memex/references/validation.md | wc -l
  ```

  Expected: ≥ 2 (one for check #9, one for check #11).

- [ ] **Step 11.13**: AC #13 — full Phase 5 validation.

  Read `skills/memex/references/validation.md`. Execute every check listed there. Record `PASS`/`FAIL` per check. Result must be `15/15 PASS`.

- [ ] **Step 11.14**: AC #14 — tests/run.sh.

  ```bash
  bash .agents/skills/memex-link/tests/run.sh
  echo "Exit: $?"
  ```

  Expected: `PASS` then `Exit: 0`.

- [ ] **Step 11.15**: AC #15 — `/memex-link` against the live vault produces ≥ 1 suggestion.

  Run `/memex-link` (the slash command) without args. Capture the table. Confirm at least one row. Save the captured output for the PR description.

  *Manual check; the loop will prompt — answer `n` to all so nothing gets edited during validation.*

- [ ] **Step 11.16**: AC #16 — idempotency post-backfill.

  Re-run `/memex-link` (the same scope as step 11.15) immediately after. Confirm that the previously-emitted retroactive candidate (the one from Phase 1's backfill) is **not** re-surfaced.

  *Manual check.*

- [ ] **Step 11.17**: AC #17 — sweep flags an island fixture, doesn't flag a populated spec.

  Construct a transient fixture in `/tmp` (do NOT commit it):

  ```bash
  mkdir -p /tmp/island-fixture/context/specs/2026-01-01-island-test
  cat > /tmp/island-fixture/context/specs/2026-01-01-island-test/spec-island-test.md <<'EOF'
  ---
  status: draft
  feature: island-test
  created: 2026-01-01
  shipped: null
  related: []
  ---
  # Island Test

  No outgoing wikilinks. Should be flagged by sweep.

  ## Body

  Pure island.
  EOF
  cat > /tmp/island-fixture/context/specs/2026-01-01-island-test/plan-island-test.md <<'EOF'
  ---
  feature: island-test
  spec: "[[spec-island-test]]"
  created: 2026-01-01
  ---
  # Plan
  EOF
  cat > /tmp/island-fixture/context/specs/2026-01-01-island-test/tasks-island-test.md <<'EOF'
  ---
  feature: island-test
  plan: "[[plan-island-test]]"
  spec: "[[spec-island-test]]"
  created: 2026-01-01
  ---
  # Tasks
  EOF

  # Run the sweep's island detector against the fixture vault:
  cd /tmp/island-fixture
  for spec in context/specs/[0-9]*-*/spec-*.md; do
    [ -f "$spec" ] || continue
    spec_dir=$(dirname "$spec")
    folder=$(basename "$spec_dir")
    count=$(grep -oE '\[\[[^]]+\]\]' "$spec" | grep -vE "(plan|tasks)-" | sort -u | wc -l | tr -d ' ')
    if [ "$count" = "0" ]; then
      echo "ISLAND: $spec"
    fi
  done
  cd - > /dev/null
  rm -rf /tmp/island-fixture
  ```

  Expected: one `ISLAND:` line for the fixture spec.

  Then verify the live `rename-harness-to-memex` spec (which has populated `related:`) is NOT flagged when sweep runs against the live vault.

- [ ] **Step 11.18**: AC #18 — branch.

  ```bash
  git branch --show-current
  ```

  Expected: `feat/strengthen-vault-cross-links`.

- [ ] **Step 11.19**: AC #19 — spec frontmatter status. (Will be done in Phase 7.)

### Task 12: Fix any failing checks

**Files:** any file flagged by Task 11.

- [ ] **Step 12.1**: For each FAIL recorded in Task 11, identify the cause and apply a targeted fix. Re-run the specific check until PASS.

- [ ] **Step 12.2**: If any fixes were committed, do so as a separate "fix(...)" commit so the validation-driven changes are auditable.

  ```bash
  git add -A
  git diff --cached --stat
  git commit -m "fix: validation-driven cleanup for strengthen-vault-cross-links"
  ```

  If no fixes were needed, skip this step entirely.

---

## Phase 7 — Ship

### Task 13: Mark spec status `shipped` + index + reflection

**Files:**
- Modify: `context/specs/2026-05-03-strengthen-vault-cross-links/spec-strengthen-vault-cross-links.md`
- Modify: `context/_index/specs.md`
- Maybe-create: a reflection learning note.

- [ ] **Step 13.1**: Mark spec frontmatter shipped.

  Use `Edit` on `context/specs/2026-05-03-strengthen-vault-cross-links/spec-strengthen-vault-cross-links.md`:
  - old:
    ```
    status: draft
    feature: strengthen-vault-cross-links
    created: 2026-05-03
    shipped: null
    ```
  - new:
    ```
    status: shipped
    feature: strengthen-vault-cross-links
    created: 2026-05-03
    shipped: 2026-05-03
    ```

  And update the body header line:
  - old: `**Status:** Draft`
  - new: `**Status:** Shipped (2026-05-03)`

- [ ] **Step 13.2**: Tick all `[ ]` checkboxes in the spec's Acceptance Criteria section to `[x]`.

  ```bash
  sed -i.bak 's/^- \[ \]/- [x]/g' context/specs/2026-05-03-strengthen-vault-cross-links/spec-strengthen-vault-cross-links.md \
    && rm context/specs/2026-05-03-strengthen-vault-cross-links/spec-strengthen-vault-cross-links.md.bak
  ```

- [ ] **Step 13.3**: Index the spec under "Shipped" in `context/_index/specs.md`.

  Use `Edit` to add a new entry above the `opensource-readiness` line:

  - old:
    ```
    ## Shipped

    - [[../specs/2026-05-03-rename-harness-to-memex/spec-rename-harness-to-memex|rename-harness-to-memex]]
    ```
  - new:
    ```
    ## Shipped

    - [[../specs/2026-05-03-strengthen-vault-cross-links/spec-strengthen-vault-cross-links|strengthen-vault-cross-links]] — added `related:` to spec template, hardened post-spec backlink rule, extended `/memex-sweep` with isolated-specs detector, backfilled `opensource-readiness`, and shipped new `/memex-link` skill+command for interactive cross-link suggestions. Shipped 2026-05-03.
    - [[../specs/2026-05-03-rename-harness-to-memex/spec-rename-harness-to-memex|rename-harness-to-memex]]
    ```

  (Adjust the surrounding context to match the actual line layout — only the new bullet is being added.)

- [ ] **Step 13.4**: Reflection — explicitly ask: "what did I learn implementing this that wasn't obvious from the spec?"

  Common candidates:
  - Bash 3.2 quirks during `find-candidates.sh` development (heredoc syntax, no associative arrays).
  - Token-overlap stopword tuning surprises (e.g., generic terms not initially listed).
  - Edge cases in frontmatter parsing.
  - Edit-safety races during the interactive loop.

  If at least one non-obvious learning surfaced: create a new note under `context/learnings/<slug>.md` using the template `context/templates/learning.md`, populate it (including `related: [[../specs/2026-05-03-strengthen-vault-cross-links/spec-strengthen-vault-cross-links]]`), and add an entry to `context/_index/learnings.md` under the appropriate `#concept`/`#gotcha`/`#reference` heading.

  If nothing non-obvious came up: state "**Reflection:** No new learnings from this spec." in the PR description body. (Per CLAUDE.md — silence is not the same as reflection.)

- [ ] **Step 13.5**: Commit Phase 7.

  ```bash
  git add context/specs/2026-05-03-strengthen-vault-cross-links/spec-strengthen-vault-cross-links.md context/_index/specs.md
  # plus any reflection learning, if created
  git status --short
  git commit -m "ship: strengthen-vault-cross-links — spec marked shipped, indexed, reflection captured"
  ```

### Task 14: Push branch + open PR

**Files:** none modified — git operation.

- [ ] **Step 14.1**: Push the branch.

  ```bash
  git push -u origin feat/strengthen-vault-cross-links
  ```

- [ ] **Step 14.2**: Open the PR via `/memex-open-pr`. Pass enough context (spec link, AC summary, reflection note location).

  If the slash command fails for any reason, fall back to:

  ```bash
  gh pr create --title "feat: strengthen vault cross-links (related: + memex-link + sweep island detector)" --body "$(cat <<'EOF'
  ## Summary
  - Adds `related:` to spec template (Component 1)
  - Hardens AGENTS.md post-spec backlink rule to bidirectional-mandatory (Component 2)
  - Extends `/memex-sweep` with `### Isolated specs` detector (Component 3)
  - Backfills `opensource-readiness` spec `related:` (Component 4)
  - Ships new `/memex-link` skill with bash detector + interactive accept loop (Component 5)

  ## Test plan
  - [x] All 19 acceptance criteria from spec PASS (see `context/specs/2026-05-03-strengthen-vault-cross-links/spec-...md`)
  - [x] `bash .agents/skills/memex-link/tests/run.sh` → PASS
  - [x] Phase 5 validation 15/15 PASS
  - [x] Live vault smoke test of `/memex-link` produces suggestions
  - [x] Sweep test fixture flagged correctly; live populated specs not flagged

  Spec: `context/specs/2026-05-03-strengthen-vault-cross-links/spec-strengthen-vault-cross-links.md`
  EOF
  )"
  ```

  (No Claude attribution per Rule 19.)

---

## Done

After Task 14 the PR is open and the spec is shipped.
