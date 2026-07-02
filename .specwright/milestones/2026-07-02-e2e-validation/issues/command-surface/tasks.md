---
feature: command-surface
created: 2026-07-02
---
# Command Surface (T10) — Tasks

**For this issue:** see the sibling `issue.md` (acceptance criteria) and `spec.md` (technical plan).

> Each task names the `AC:` (acceptance criteria from `issue.md` it satisfies — every `AC-N` must be referenced by at least one task) and `Delegable:` (whether it suits an isolated task worker, and the one-line context that worker would receive). Workers report findings back to the issue owner; only the owner writes `learnings.md`.

Paths below: `REPO` = this issue’s worktree root (the repo checkout), `SANDBOX` = `/Users/gabriel/www/ribeirogab/specwright-sandbox/taskr`, `ISSUE` = `REPO/.specwright/milestones/2026-07-02-e2e-validation/issues/command-surface`. The 8 verbs: `brainstorm spec plan run review review-spec pr update`. Retired names: `sw-brainstorming sw-writing-plans sw-new-pr sw-code-review`.

## Phase 1: Inventory

### Task 1: Repo plugin layer inventory (commands + skills)

**AC:** AC-1, AC-2
**Delegable:** no — evidence must land in the owner's findings draft verbatim.

- [x] Step 1: Enumerate the plugin surface and capture output:

Run: `ls -la REPO/plugins/sw/commands/ REPO/plugins/sw/skills/ && cat REPO/plugins/sw/.claude-plugin/plugin.json 2>/dev/null; ls REPO/plugins/sw/`
Expected: command stubs (`spec.md`, `review-spec.md`) + 6 skill dirs (`brainstorm plan pr review run update`); plugin manifest present.

- [x] Step 2: For each of the 6 plugin skills, capture frontmatter `name:`:

Run: `for v in brainstorm plan pr review run update; do echo "== $v"; sed -n '1,10p' REPO/plugins/sw/skills/$v/SKILL.md | grep -E '^name:'; done`
Expected: `name: <bare verb>` per AC-2 (any mismatch → finding).

- [x] Step 3: Check the 2 command stubs are well-formed commands (frontmatter/description) and note whether `spec`/`review-spec` also exist as plugin skills:

Run: `sed -n '1,12p' REPO/plugins/sw/commands/spec.md REPO/plugins/sw/commands/review-spec.md; ls REPO/plugins/sw/skills/ | grep -E 'spec' || echo "no spec/review-spec plugin skill"`
Expected: documented answer for the `/sw:spec` and `/sw:review-spec` cells of the verdict table.

### Task 2: Repo canonical layer inventory (`.agents/skills/sw-*`)

**AC:** AC-1, AC-2
**Delegable:** no — same findings draft.

- [x] Step 1: Enumerate canonical copies and their `name:` frontmatter:

Run: `ls -la REPO/.agents/skills/ && for d in REPO/.agents/skills/sw-*/; do echo "== $d"; grep -m1 -E '^name:' "$d/SKILL.md" 2>/dev/null || echo "NO SKILL.md"; done`
Expected: which of the 8 verbs have `sw-<verb>` canonical copies; `name: sw-<verb>` per AC-2. Independently confirm (or refute) the docs-coherence relay that `sw-spec` and `sw-review-spec` are absent.

- [x] Step 2: Record whether any canonical entries are symlinks and where they point:

Run: `find REPO/.agents -type l -exec ls -l {} +; echo "exit=$?"`
Expected: inventory of symlinks (empty is fine).

### Task 3: Sandbox install inventory (all layers it has)

**AC:** AC-1, AC-2
**Delegable:** no — same findings draft. **Read-only on the sandbox.**

- [x] Step 1: Enumerate the sandbox surface:

Run: `ls -la SANDBOX SANDBOX/.agents/skills/ SANDBOX/.claude/ && cat SANDBOX/.claude/settings.json`
Expected: `sw` + `sw-*` skill dirs; settings referencing the specwright marketplace/plugin; `CLAUDE.md` symlink noted.

- [x] Step 2: Capture frontmatter `name:` of every sandbox skill:

Run: `for d in SANDBOX/.agents/skills/*/; do echo "== $d"; grep -m1 -E '^name:' "$d/SKILL.md" 2>/dev/null || echo "NO SKILL.md"; done`
Expected: `sw-<verb>` names per AC-2; note which verbs are missing entirely.

- [x] Step 3: Check what plugin the sandbox's Claude Code side would load (marketplace wiring, and the local plugin cache if present):

Run: `ls SANDBOX/.claude/plugins 2>/dev/null; ls ~/.claude/plugins/cache/specwright/sw/ 2>/dev/null && ls ~/.claude/plugins/cache/specwright/sw/*/commands ~/.claude/plugins/cache/specwright/sw/*/skills 2>/dev/null`
Expected: evidence for the sandbox plugin-layer cells (or an explicit "delivered via marketplace cache, contents: ..." note).

- [x] Step 4: Inventory per-agent discovery dirs and symlinks in the sandbox:

Run: `find SANDBOX -maxdepth 2 -name 'CLAUDE.md' -o -maxdepth 2 -type d \( -name '.codex' -o -name '.cursor' -o -name '.opencode' -o -name '.claude' \) | sort; find SANDBOX -type l -exec ls -l {} +`
Expected: every symlink listed with target; targets feed Task 4's dangling check.

## Phase 2: Cross-check

### Task 4: Retired-name and dangling-symlink sweep (repo + sandbox)

**AC:** AC-3
**Delegable:** no.

- [x] Step 1: Sweep both surfaces for retired names (excluding this milestone's own vault text, which legitimately mentions them):

Run: `grep -rn -E 'sw-brainstorming|sw-writing-plans|sw-new-pr|sw-code-review' REPO --include='*' -l | grep -v '.specwright/milestones' ; find REPO SANDBOX \( -name 'sw-brainstorming*' -o -name 'sw-writing-plans*' -o -name 'sw-new-pr*' -o -name 'sw-code-review*' \) ; echo "sweep done"`
Expected: zero paths (any hit → finding with path).

- [x] Step 2: Legacy command files:

Run: `ls REPO/.claude/commands/ SANDBOX/.claude/commands/ 2>&1`
Expected: both absent (`No such file or directory`) or empty of `sw-*.md`.

- [x] Step 3: Dangling symlinks anywhere under both surfaces:

Run: `find -L REPO SANDBOX -type l -exec ls -l {} + 2>/dev/null; echo "dangling-check exit=$?"`
Expected: no output before the marker (a `find -L ... -type l` hit = dangling link = finding).

### Task 5: Doc-coherence map (documented invocation → artifact)

**AC:** AC-4
**Delegable:** no.

- [x] Step 1: Extract every documented invocation from both surfaces' docs with line numbers:

Run: `grep -rnoE '(/sw:[a-z-]+|\$sw-[a-z-]+|@sw-[a-z-]+)' REPO/README.md REPO/AGENTS.md REPO/CLAUDE.md REPO/CONTRIBUTING.md SANDBOX/AGENTS.md SANDBOX/CLAUDE.md 2>/dev/null | sort -u -t: -k3`
Expected: the full invocation inventory (file:line:token).

- [x] Step 2: For each distinct token, resolve it against the layer that surface actually produces (plugin skill/command for `/sw:*`; `.agents/skills/sw-*` for `$sw-*` and `@sw-*`), using Task 1–3 inventories. Every unresolved token → finding with doc file:line and the missing path; every artifact with no documented invocation → finding too.
- [x] Step 3: Commit the planning + evidence state so far: `git add .specwright/milestones/2026-07-02-e2e-validation/issues/command-surface && git commit -m "chore(vault): plan the command-surface audit — spec and tasks"` (planning artifacts committed before/with the audit work; findings assembly continues in Task 6).

## Phase 3: Report and ship

### Task 6: Assemble `findings.md`

**AC:** AC-1, AC-2, AC-3, AC-4, AC-5
**Delegable:** no — curation is the owner's.

- [x] Step 1: Write `ISSUE/findings.md`: (a) verdict table — rows = 8 verbs, columns = repo plugin command, repo plugin skill, repo canonical `.agents/skills`, sandbox canonical, each cell `present`/`absent` + path; (b) skill-name identity table (AC-2); (c) retired-names verdict list (AC-3); (d) doc-coherence map with per-token resolution (AC-4); (e) one `Expected / Observed / Proposed fix` block per divergence (AC-5); (f) evidence blocks (verbatim command outputs) with the date.
- [x] Step 2: Re-read `issue.md` AC by AC against the finished `findings.md`; tick every `AC-N` that is satisfied by observed evidence.
- [x] Step 3: Run the repo quality gate available in this worktree: `ls REPO/tests/ && bash REPO/tests/run.sh 2>/dev/null || (cd REPO && for t in tests/*.sh; do bash "$t" || exit 1; done)` — adapt to what `tests/` actually contains; nothing may fail. Also run `REPO/skills/sw/scripts/validate-spec.sh ISSUE` → exit 0.
- [x] Step 4: Commit: `git add .specwright/milestones/2026-07-02-e2e-validation/issues/command-surface && git commit -m "chore(vault): record command-surface audit findings"`

### Task 7: Deliver

**AC:** AC-5
**Delegable:** no.

- [x] Step 1: `/sw:pr` — base `chore/e2e-sandbox-setup`, note the stacking in the body, include the runtime-verification record (which ACs verified how).
- [x] Step 2: `/sw:review` to `lgtm`; apply fixes on this branch until clean.
- [x] Step 3: Write `ISSUE/learnings.md` (only non-obvious facts future issues need — e.g. the actual shape of the spec/review-spec surface, plugin-cache vs repo divergences discovered).
- [x] Step 4: Set `issue.md` `status: shipped` + `shipped: 2026-07-02`; final commit on the branch.
