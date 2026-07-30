---
feature: opencode-host-support
created: 2026-07-29
tasks_schema: 2
---
# OpenCode Host Support — Tasks

**For this change:** see the sibling `change.md` (acceptance criteria) and `spec.md` (technical plan).

> Every task has a stable `Tn` identifier and names the `AC:` criteria it satisfies. `Delegable:` begins with `yes` or `no` and may add a concise context after ` — `. `Delegable: yes` tasks use `Integration: isolated` and own explicit repository-relative files. `Delegable: no` tasks use `Integration: inline` and list exactly `- None` when they have no owned files. `Depends on:` plus the `Files:` ownership set are the graph `sw:run` derives **waves** from — a wave is a dependency-ready, file-disjoint set of isolated tasks that may run in parallel; waves are computed at dispatch time and never persisted. Workers report findings back to the change-owner; only the owner writes `learnings.md`.

## Phase 1: Templates

### T1: OpenCode agent templates

**AC:** AC-2
**Delegable:** yes — four self-contained template files with full contents specified below
**Depends on:** none
**Files:**
- Create: `plugins/sw/templates/opencode-agents/sw-change-owner.md`
- Create: `plugins/sw/templates/opencode-agents/sw-reviewer.md`
- Create: `plugins/sw/templates/opencode-agents/sw-spec-document-reviewer.md`
- Create: `plugins/sw/templates/opencode-agents/sw-task-worker.md`
**Integration:** isolated
**Validation:** `python3 - <<'PY'
from pathlib import Path
root = Path("plugins/sw/templates/opencode-agents")
files = sorted(p.name for p in root.glob("*.md"))
assert files == ["sw-change-owner.md", "sw-reviewer.md", "sw-spec-document-reviewer.md", "sw-task-worker.md"], files
for path in root.glob("*.md"):
    text = path.read_text(encoding="utf-8")
    assert text.startswith("---\n"), path
    frontmatter = text.split("---\n")[1]
    assert "mode: subagent" in frontmatter, path
    assert "model:" not in frontmatter, path
    if "reviewer" in path.name:
        assert "edit: deny" in frontmatter, path
print("opencode agent templates OK")
PY`

- [ ] **Step 1: Write `plugins/sw/templates/opencode-agents/sw-change-owner.md` with this exact content**

````markdown
---
description: "The sole owner and integrator for one specwright change: writes its plan and artifacts, schedules schema-2 task waves, creates isolated worker branches/worktrees, reviews and cherry-picks accepted commits, runs integrated validation, owns the PR and learnings, and reports delivery to the delivery orchestrator."
mode: subagent
---

You own exactly one change. Load the specwright `plan` skill and run it end to end
for the change folder in the dispatch prompt.

## Exclusive authority

Only you may edit:

- the change branch;
- `change.md`, `spec.md`, `tasks.md`, and `learnings.md`;
- the change pull request and delivery state.

A task worker never receives or writes those resources. The delivery orchestrator
may track your result on its board, but it does not implement the change or integrate
your workers.

## Plan before implementation

Write schema-2 `tasks.md` with stable task IDs, dependencies, exact file ownership,
`inline` or `isolated` integration, and validation commands. Pass all plan gates,
including validator check 6, then commit the plan before implementation.

Build dependency waves from the validated graph — a wave is a dependency-ready,
file-disjoint set of isolated tasks that may run in parallel. Execute inline tasks
yourself on the change branch. For each wave of ready, pairwise non-overlapping
isolated tasks:

1. require a clean change worktree and record its exact `base SHA`;
2. create every task branch from that same SHA;
3. create one sibling worktree under
   `.specwright/worktrees/<change-slug>-<task-id>/`;
4. reject a declared path when `lstat`/resolved containment finds a symlink or
   existing ancestor outside the worker worktree, except an explicit operation on
   the symlink leaf itself;
5. dispatch `sw-task-worker` with the task block, allowed paths, validation command,
   branch, worktree, base SHA, and authority prohibitions.

Never dispatch a dependent task before integrated validation of all prerequisites.
Never remove a worker worktree automatically.

## Sole integration protocol

Require every worker to return:

- status;
- the original base SHA;
- ordered commit SHAs;
- touched paths;
- validation commands and results;
- raw discoveries or a blocker report.

Before integration, repeat the symlink/resolved-containment check, then verify base
equality, commit ancestry and exact order, absence of merge commits, clean worker
state, final branch HEAD, diff scope, returned touched paths, declared ownership,
and credible validation evidence. Read the full diff. Reject any `.specwright/`
change, undeclared path, scope expansion, escape from the worktree, or unverifiable
result.

Cherry-pick only accepted ordered commit SHAs onto the change branch. You may resolve
a mechanical conflict only when formatting, import order, lockfile reconciliation,
or adjacent-line placement makes the intended result behaviorally predetermined.
A semantic conflict, ownership overlap, behavioral choice, or scope change requires
you to abort that integration attempt and replan or redelegate.

After each wave, run every task validation and the combined touched area's
integrated validation. Release dependents only after all pass. Curate useful raw
discoveries into `learnings.md` yourself; workers never do this.

## Delivery

Complete the quality gate and runtime verification, open and maintain the change PR,
drive review to `lgtm`, curate durable learnings, and update the change status.

Return one result to the delivery orchestrator:

- `shipped` — PR URL and one line per curated learning;
- `blocked` — a paste-ready **Why / Tried / Needs** block.

Honor the circuit breaker: three identical failures of the same gate or criterion
means stop, set the change to `blocked`, and return the blocker report.
````

- [ ] **Step 2: Write `plugins/sw/templates/opencode-agents/sw-task-worker.md` with this exact content**

````markdown
---
description: "An isolated specwright task implementer: works only in the task branch/worktree and declared files supplied by the change owner, validates and commits that task, and returns ordered SHAs, paths, evidence, and raw discoveries without integrating or editing change artifacts."
mode: subagent
---

Implement exactly one `Integration: isolated` task from the change owner's dispatch.
You do not own the change.

## Required dispatch inputs

Require all of these before writing:

- task ID and complete task block;
- task branch and absolute worktree path;
- base SHA;
- normalized allowed file paths;
- exact validation command.

Work only in the supplied task worktree and branch. Confirm its initial `HEAD`
equals the base SHA. If an input is missing, the branch provenance is wrong, or the
declared ownership cannot complete the task, return `blocked`; never widen scope.

Before any read or write, inspect every allowed path and existing ancestor with
`lstat`, resolve existing entries, and require containment inside the supplied
worktree. Do not follow a symlink in an allowed path. A task may delete or replace
the symlink leaf itself only when that exact operation is declared; otherwise a
symlink is a blocker. Repeat this check before returning.

## Authority boundary

You may edit only the declared allowed paths in your task worktree. You must not:

- edit any `.specwright/` artifact, including change files or `learnings.md`;
- edit the change branch or another worker's branch/worktree;
- create, update, or comment on a pull request;
- cherry-pick, merge, rebase, or integrate another branch;
- change task ownership, dependencies, acceptance criteria, or scope;
- remove any worktree.

Follow the task steps, project conventions, and surrounding code. Use TDD where the
task calls for it. Commit only to your task branch. Before returning, require a clean
worktree and compare the complete touched-path set from `base SHA..HEAD` with the
allowed list. An undeclared path or an out-of-worktree mutation is a blocker, not
something to hide or hand-wave.

Run the exact validation command from the dispatch and record its exit status plus
material output. Additional focused checks are welcome, but they do not replace the
required command.

## Return contract

Return this structure to the change owner:

```text
status: completed | blocked
base SHA: <sha>
ordered commit SHAs:
- <sha in base-to-head order>
touched paths:
- <repository-relative path>
validation:
- command: <exact command>
  result: <exit status and material output>
raw discoveries:
- <unfiltered fact, surprise, constraint, or workaround>
blocker:
  why: <reason>
  tried: <safe attempts>
  needs: <ownership, decision, or external change>
```

For `completed`, ordered commit SHAs must be the exact non-merge sequence after the
base, touched paths must match the Git diff, and `blocker` is omitted. For
`blocked`, make no out-of-scope fix; include **why / tried / needs**.

Report raw discoveries without curating them into durable knowledge. The change
owner alone decides what belongs in `learnings.md` and whether your commits are
accepted and cherry-picked.
````

- [ ] **Step 3: Write `plugins/sw/templates/opencode-agents/sw-reviewer.md` with this exact content**

````markdown
---
description: "The specwright review lane — dispatched by the shared sw:review workflow once per lane as a find-only reviewer of a branch diff. Not for ad-hoc use; the review skill spawns it three times, one lane each."
mode: subagent
permission:
  edit: deny
---

You are ONE find-only review lane. Your lane is named in the dispatch prompt — one of:
- **A — rubric + conventions:** does the diff obey the universal coding standard and the project's conventions?
- **B — change-conformance:** does the diff deliver this change's `AC-N`, with runtime-verification evidence?
- **C — documentation-consistency:** after this diff, does the project's live documentation still match the code?

Stay strictly in your lane — do not duplicate another lane's findings or wander into its scope. The lanes are deliberately non-overlapping so the main agent's merge is clean.

Load the specwright `review` skill before reviewing. Apply its standard, its blocker calibration, and its reply templates. Never edit code — findings only. Return your lane's findings for the main agent to merge into the single verdict; the branch reaches `lgtm` only when every lane is clean.
````

- [ ] **Step 4: Write `plugins/sw/templates/opencode-agents/sw-spec-document-reviewer.md` with this exact content**

````markdown
---
description: "The specwright spec-document reviewer — dispatched by the shared sw:plan workflow at Gate 2 to verify a change's fused spec.md + tasks.md against its change.md before implementation. Not for ad-hoc use."
mode: subagent
permission:
  edit: deny
---

You are a spec document reviewer. Verify the technical spec and its task breakdown are complete and ready for implementation.

The dispatch prompt gives you the paths to review: the change's `spec.md`, its
`tasks.md`, and its `change.md` (the approved *why* plus the acceptance criteria).
This is the judgment layer; the mechanical validator resolved from the installed
plugin root runs separately and catches frontmatter, placeholders, vague criteria,
AC coverage, and schema-2 topology deterministically.

## What to Check

| Category | What to Look For |
|----------|------------------|
| Completeness | TODOs, placeholders, "TBD", incomplete sections in spec or tasks |
| Consistency | Internal contradictions; spec contradicting the change's intent |
| Clarity | Requirements ambiguous enough to cause someone to build the wrong thing |
| Technical content | Architecture, File Structure, and Phase Ordering are present and concrete (not hand-wavy) |
| Acceptance Criteria | Each in change.md is numbered `AC-N`, binary, observable, and free of vague verbs ("works", "fast"/"robust" without a number, "gracefully") |
| AC coverage | Every `AC-N` in change.md is referenced by at least one task's `AC:` field; no task references an AC-N that does not exist |
| Learnings | If sibling shipped changes carry learnings.md files, the spec does not contradict any recorded learning |
| Task decomposition | Tasks have clear boundaries; steps are actionable; an engineer could follow them without getting stuck |
| Scope / YAGNI | Focused on one coherent unit; no unrequested features or over-engineering |

## Calibration

**Only flag issues that would cause real problems during implementation.** A missing section, a contradiction, a requirement so ambiguous it could be built two different ways, a vague acceptance criterion, or an AC-N no task covers — those are issues. Minor wording, stylistic preferences, and "sections less detailed than others" are not.

Approve unless there are serious gaps that would lead to a flawed build.

## Output Format

Return exactly this shape as your final message:

**Status:** Approved | Issues Found

**Issues (if any):**
- [Section X / Task Y]: [specific issue] - [why it matters for implementation]

**Recommendations (advisory, do not block approval):**
- [suggestions for improvement]
````

- [ ] **Step 5: Run the task `Validation:` command; expected output `opencode agent templates OK`**
- [ ] **Step 6: Commit** — `feat(templates): add opencode agent role templates`

### T2: OpenCode command templates

**AC:** AC-1
**Delegable:** yes — nine mechanical redirect files fully specified below
**Depends on:** none
**Files:**
- Create: `plugins/sw/templates/opencode-commands/sw-brainstorm.md`
- Create: `plugins/sw/templates/opencode-commands/sw-init.md`
- Create: `plugins/sw/templates/opencode-commands/sw-plan.md`
- Create: `plugins/sw/templates/opencode-commands/sw-pr.md`
- Create: `plugins/sw/templates/opencode-commands/sw-review-spec.md`
- Create: `plugins/sw/templates/opencode-commands/sw-review.md`
- Create: `plugins/sw/templates/opencode-commands/sw-run.md`
- Create: `plugins/sw/templates/opencode-commands/sw-spec.md`
- Create: `plugins/sw/templates/opencode-commands/sw-update.md`
**Integration:** isolated
**Validation:** `python3 - <<'PY'
from pathlib import Path
root = Path("plugins/sw/templates/opencode-commands")
expected = ["sw-brainstorm.md", "sw-init.md", "sw-plan.md", "sw-pr.md", "sw-review-spec.md", "sw-review.md", "sw-run.md", "sw-spec.md", "sw-update.md"]
files = sorted(p.name for p in root.glob("*.md"))
assert files == expected, files
for path in root.glob("*.md"):
    skill = path.stem.removeprefix("sw-")
    text = path.read_text(encoding="utf-8")
    assert f"skills/{skill}/SKILL.md" in text, path
    assert "$ARGUMENTS" in text, path
    assert text.startswith("---\n"), path
print("opencode command templates OK")
PY`

- [ ] **Step 1: Write the nine command templates.** Each file has the uniform shape below; only `<name>` and `<description>` vary. `<name>` is the skill name (`init`, `brainstorm`, `spec`, `plan`, `run`, `review`, `review-spec`, `pr`, `update`); the filename is `sw-<name>.md`:

````markdown
---
description: <description>
---

Run the specwright **<name>** skill. Load the skill named `<name>` from the
specwright plugin (`skills/<name>/SKILL.md`) and follow its instructions exactly,
treating `$ARGUMENTS` as the skill's input.
````

Descriptions per file (quote them verbatim, unquoted YAML scalar):

| File | `<description>` |
|---|---|
| `sw-init.md` | `Set up specwright's project state — the .specwright/ vault, canonical AGENTS instructions, host adapter files, role profiles, and exact ignore rules` |
| `sw-brainstorm.md` | `Design exploration that concludes single change vs delivery and writes the specwright artifacts — the required first step before any creative work` |
| `sw-spec.md` | `Turn the current conversation into a change (or delivery) using the specwright brainstorm flow` |
| `sw-plan.md` | `Produce an approved change's fused spec.md + tasks.md, self-review them, then drive the change pipeline — implement, quality gate, runtime verification, PR, review to lgtm` |
| `sw-run.md` | `Conduct a specwright delivery — dispatch every ready change to the sw-change-owner role in parallel, track the board, apply circuit breakers, and close out. Resumable from a fresh session` |
| `sw-review.md` | `Review a branch diff (or pointed-at files) with find-only subagents across rubric+conventions, change-conformance, and documentation-consistency, merged into one verdict that reaches lgtm only when every lane is clean` |
| `sw-review-spec.md` | `External evaluator that reviews a change's plan against the project conventions and the approved change, flagging vagueness, scope creep, and unresolved questions` |
| `sw-pr.md` | `Open the current change's pull request following specwright conventions — branch/base resolution, repo PR template, Conventional-Commit title, runtime-verification results, no AI attribution` |
| `sw-update.md` | `Plan and apply a confirmed versioned specwright project migration across every supported host without overwriting drift` |

- [ ] **Step 2: Run the task `Validation:` command; expected output `opencode command templates OK`**
- [ ] **Step 3: Commit** — `feat(templates): add opencode command redirects`

## Phase 2: Engine + tests

### T3: Tri-host updater, version bump, block template, and suites

**AC:** AC-3, AC-4, AC-5, AC-7, AC-8
**Delegable:** yes — mechanical generalization of one Python module plus fixture/test updates; every hunk specified below
**Depends on:** T1, T2
**Files:**
- Modify: `plugins/sw/scripts/sw_update.py`
- Modify: `plugins/sw/.codex-plugin/plugin.json`
- Modify: `plugins/sw/.claude-plugin/plugin.json`
- Modify: `plugins/sw/references/agents-md-template.md`
- Modify: `tests/install/run.sh`
- Modify: `tests/install/fixtures/update/up-to-date/AGENTS.md`
- Modify: `tests/update/test_plan.py`
- Modify: `tests/update/fixtures/up-to-date/AGENTS.md`
**Integration:** isolated
**Validation:** `python3 tests/update/test_plan.py && bash tests/install/run.sh update && bash tests/install/run.sh package init && bash tests/install/run.sh worktree topology`

- [ ] **Step 1: Verify the recorded 2026.7.29 profile digests**

Run: `shasum -a 256 plugins/sw/templates/codex-agents/sw-*.toml`. Confirm the four digests match the values hardcoded in Step 3 exactly; if any differs, stop and report — the Codex templates drifted from the 2026.7.29 release.

- [ ] **Step 2: Bump both manifests to `2026.7.30`**

In `plugins/sw/.codex-plugin/plugin.json` and `plugins/sw/.claude-plugin/plugin.json`, set `"version": "2026.7.30"`.

- [ ] **Step 3: Extend the constants block in `plugins/sw/scripts/sw_update.py`**

Replace the block from `LOCAL_IGNORE_RULES = (` through `KNOWN_PROFILE_DIGESTS_BY_VERSION: dict[str, dict[str, str]] = {}` with:

```python
LOCAL_IGNORE_RULES = (
    ".specwright/worktrees/",
    ".specwright/",
    "AGENTS.override.md",
    "CLAUDE.local.md",
    ".codex/agents/sw-*.toml",
    ".opencode/agent/sw-*.md",
    ".opencode/command/sw-*.md",
)
SHARED_IGNORE_RULES = (".specwright/worktrees/",)
ALL_MANAGED_IGNORE_RULES = tuple(dict.fromkeys((*SHARED_IGNORE_RULES, *LOCAL_IGNORE_RULES)))
OPENCODE_AGENT_DIRECTORY = Path(".opencode/agent")
OPENCODE_AGENT_NAMES = (
    "sw-change-owner.md",
    "sw-reviewer.md",
    "sw-spec-document-reviewer.md",
    "sw-task-worker.md",
)
OPENCODE_COMMAND_DIRECTORY = Path(".opencode/command")
OPENCODE_COMMAND_NAMES = (
    "sw-brainstorm.md",
    "sw-init.md",
    "sw-plan.md",
    "sw-pr.md",
    "sw-review-spec.md",
    "sw-review.md",
    "sw-run.md",
    "sw-spec.md",
    "sw-update.md",
)
MANAGED_TEMPLATE_SETS = (
    (PROFILE_DIRECTORY, "codex-agents", PROFILE_NAMES),
    (OPENCODE_AGENT_DIRECTORY, "opencode-agents", OPENCODE_AGENT_NAMES),
    (OPENCODE_COMMAND_DIRECTORY, "opencode-commands", OPENCODE_COMMAND_NAMES),
)
# Immutable predecessor digests distinguish a legitimate version upgrade from an
# edited managed profile. Add the outgoing release here before changing a profile.
KNOWN_PROFILE_DIGESTS_BY_VERSION: dict[str, dict[str, str]] = {
    "2026.7.29": {
        "sw-change-owner.toml": "e284400ad6ae02350b1978e2dbd5242c5d3c782fd7dd0d4e327a0c47089135c5",
        "sw-spec-document-reviewer.toml": "289862b98d25197db8afd074de3613bd45e3360c7df930f4aaadc3da368954df",
        "sw-reviewer.toml": "c3178c120cba83622d2346f8b92e5c2f53a435fdea0e34c0aec1572490690274",
        "sw-task-worker.toml": "bd43f3856048b804d49326eae461dcea49c19382121272a57f54f58218f0b516",
    },
}
```

- [ ] **Step 4: Add the `_template_source` helper**

Insert after the `_observe_path` function:

```python
def _template_source(relative_path: str) -> Path | None:
    """Return the installed template for a managed destination path, or None."""
    path = Path(relative_path)
    for directory, template_directory, names in MANAGED_TEMPLATE_SETS:
        if path.parent == directory and path.name in names:
            return (
                Path(__file__).resolve().parents[1]
                / "templates"
                / template_directory
                / path.name
            )
    return None
```

- [ ] **Step 5: Generalize `_observe_paths`**

Replace the two `paths.extend(...)`/list lines with:

```python
    paths = [Path(canonical), Path(adapter), Path(".gitignore")]
    paths.extend(
        directory / name
        for directory, _, names in MANAGED_TEMPLATE_SETS
        for name in names
    )
```

- [ ] **Step 6: Generalize `_classify`'s `managed_paths`**

Replace the `managed_paths = [...]` line with:

```python
    managed_paths = [
        canonical_path,
        adapter_path,
        *(
            project / directory / name
            for directory, _, names in MANAGED_TEMPLATE_SETS
            for name in names
        ),
    ]
```

- [ ] **Step 7: Generalize `_is_up_to_date`'s profile loop**

Replace the `for name in PROFILE_NAMES:` loop with:

```python
    for directory, _, names in MANAGED_TEMPLATE_SETS:
        for name in names:
            destination = project / directory / name
            source = _template_source((directory / name).as_posix())
            assert source is not None
            if destination.is_symlink() or not destination.is_file() or destination.read_bytes() != source.read_bytes():
                return False
```

- [ ] **Step 8: Guard OpenCode drift in `_managed_update_desired`**

Keep the existing `for name in PROFILE_NAMES:` known-digests loop, then append after it (before the `_ignore_rules_match` check):

```python
    for directory, _, names in MANAGED_TEMPLATE_SETS[1:]:
        for name in names:
            destination = project / directory / name
            if destination.is_symlink():
                return None
            if not destination.exists():
                continue
            source = _template_source((directory / name).as_posix())
            assert source is not None
            if not destination.is_file() or destination.read_bytes() != source.read_bytes():
                return None
```

- [ ] **Step 9: Generalize `_operations`'s profile loop**

Replace the entire `for name in PROFILE_NAMES:` block with:

```python
    for directory, _, names in MANAGED_TEMPLATE_SETS:
        for name in names:
            source = _template_source((directory / name).as_posix())
            assert source is not None
            destination = project / directory / name
            relative = (directory / name).as_posix()
            if not (destination.is_symlink() or destination.exists()):
                operations.append(
                    Operation("create", relative, None, _digest_bytes(source.read_bytes()))
                )
            elif (
                state == "legacy-migratable"
                and not destination.is_symlink()
                and destination.is_file()
                and destination.read_bytes() != source.read_bytes()
            ):
                operations.append(
                    Operation(
                        "replace-profile",
                        relative,
                        _digest_bytes(destination.read_bytes()),
                        _digest_bytes(source.read_bytes()),
                    )
                )
```

- [ ] **Step 10: Generalize `_validate_profile_source`**

Replace the function body with (keep the two original error-message strings verbatim):

```python
def _validate_profile_source(operation: Operation) -> None:
    if operation.action not in {"create", "replace-profile"}:
        return
    source = _template_source(operation.relative_path)
    if source is None:
        return
    if source.is_symlink() or not source.is_file():
        raise UpdateError(f"installed profile template is invalid: {source}")
    if _digest_bytes(source.read_bytes()) != operation.desired_after:
        raise UpdateError(f"installed profile template changed after planning: {source}")
```

- [ ] **Step 11: Generalize `_apply_operation`'s content resolution**

In the `if operation.action in {"create", "replace-managed-block", "replace-profile"}:` branch, replace the `if operation.relative_path.startswith(...PROFILE_DIRECTORY...)` source lookup with:

```python
        source = _template_source(operation.relative_path)
        if source is not None:
            contents = source.read_bytes()
            mode = stat.S_IMODE(source.stat().st_mode)
        else:
```

(the `else:` keeps the existing `contents = operation.desired_after.encode("utf-8")` and mode fallback unchanged.)

- [ ] **Step 12: Add the OpenCode surface to `plugins/sw/references/agents-md-template.md`**

In the managed block's `## Command surfaces` paragraph, insert one sentence so it reads:

```markdown
Claude Code exposes the workflow as `/sw:*` commands. Codex exposes the same shared
workflow as `$sw:*` skills. OpenCode exposes the same workflow as `/sw-*` commands.
These are host adapters for the same workflow; use the surface available in the
current host.
```

- [ ] **Step 13: Re-render the two static up-to-date fixtures**

Both `tests/install/fixtures/update/up-to-date/AGENTS.md` and `tests/update/fixtures/up-to-date/AGENTS.md` contain only the rendered 2026.7.29 managed block; after Steps 2 and 12 they would classify `legacy-migratable` instead of `up-to-date`. Regenerate both byte-identically with the new template and version:

```bash
python3 - <<'PY'
from pathlib import Path
import sys
sys.path.insert(0, "plugins/sw/scripts")
import sw_update
block = sw_update.render_managed_block("2026.7.30") + "\n"
for fixture in (
    Path("tests/install/fixtures/update/up-to-date/AGENTS.md"),
    Path("tests/update/fixtures/up-to-date/AGENTS.md"),
):
    fixture.write_text(block, encoding="utf-8")
print("fixtures re-rendered")
PY
```

Expected output: `fixtures re-rendered`. (The real 2026.7.29 block's legacy migration stays covered by `tests/update/test_plan.py`'s managed-update case and by Step 15's new real-`KNOWN_PROFILE_DIGESTS_BY_VERSION` case, which renders `render_managed_block("2026.7.29")` — the same self-consistent-fixture technique the suite already uses for 2026.7.27.)

- [ ] **Step 14: Update `tests/install/run.sh`**

1. Add an `assert_opencode_files()` helper (place it after `assert_profiles`):

```bash
assert_opencode_files() {
  local project="$1" name template installed
  for name in sw-change-owner sw-reviewer sw-spec-document-reviewer sw-task-worker; do
    template="$ROOT/plugins/sw/templates/opencode-agents/$name.md"
    installed="$project/.opencode/agent/$name.md"
    assert_file "opencode agent template $name exists" "$template"
    assert_eq "installed opencode agent $name matches template" 0 "$(cmp -s "$template" "$installed"; echo $?)"
    assert_eq "opencode agent $name is a subagent" yes "$(grep -Fq 'mode: subagent' "$template" && echo yes || echo no)"
    assert_eq "opencode agent $name pins no model" no "$(grep -q '^model:' "$template" && echo yes || echo no)"
  done
  for name in sw-brainstorm sw-init sw-plan sw-pr sw-review-spec sw-review sw-run sw-spec sw-update; do
    template="$ROOT/plugins/sw/templates/opencode-commands/$name.md"
    installed="$project/.opencode/command/$name.md"
    assert_file "opencode command template $name exists" "$template"
    assert_eq "installed opencode command $name matches template" 0 "$(cmp -s "$template" "$installed"; echo $?)"
    assert_eq "opencode command $name passes arguments through" yes "$(grep -Fq 'ARGUMENTS' "$template" && echo yes || echo no)"
  done
}
```

2. In `run_init`, after each `assert_profiles` call (shared and local projects), add `assert_opencode_files "$shared"` / `assert_opencode_files "$local_project"` respectively.
3. Extend the shared assertion block with: `assert_eq "shared mode does not ignore opencode agents" 1 "$(git -C "$shared" check-ignore -q -- .opencode/agent/sw-task-worker.md; echo $?)"`.
4. Replace the local exact-ignore assertion's expected value with `$'.specwright/worktrees/\n.specwright/\nAGENTS.override.md\nCLAUDE.local.md\n.codex/agents/sw-*.toml\n.opencode/agent/sw-*.md\n.opencode/command/sw-*.md'`, and add: `assert_eq "local opencode command is ignored" 0 "$(git -C "$local_project" check-ignore -q -- .opencode/command/sw-plan.md; echo $?)"`.
5. In `new_update_project`'s `up-to-date)` case, after the Codex profile copy, add:

```bash
      mkdir -p "$project/.opencode/agent" "$project/.opencode/command"
      cp "$ROOT"/plugins/sw/templates/opencode-agents/sw-*.md "$project/.opencode/agent/"
      cp "$ROOT"/plugins/sw/templates/opencode-commands/sw-*.md "$project/.opencode/command/"
```

6. Find the update-flow case that exercises the `drifted` fixture (asserts state `drifted` and no writes). Immediately after it, add an OpenCode drift case following the same pattern: build a project from the `up-to-date` fixture setup, `printf '# hand edit\n' >>"$project/.opencode/command/sw-plan.md"`, snapshot `tree_digest`, run plan, assert state `drifted`, and assert the tree digest is unchanged.
7. Update the operation-count assertions the tri-host managed set legitimately changes — for a `new` fixture the plan grows from 7 to 20 operations (2 instruction paths + 17 template-set creates + 1 `ensure-ignore-rules`), so the `.gitignore` operation index moves from `operations.6` to `operations.19`; verify the real indices from a live plan instead of guessing. The assertion semantics stay — only counts and indices move.
8. Read the whole file first; keep every existing assertion semantics intact — extend, never delete or weaken.

- [ ] **Step 15: Update `tests/update/test_plan.py`**

Read the file fully first. Update every expectation the tri-host change legitimately alters (observed-path counts, operation counts/names for `new` projects, ignore-rule lists). Known-affected existing tests: `test_matching_managed_state_is_up_to_date` and `test_static_up_to_date_fixture_is_recognized` (setup must install the 13 `.opencode/` files), the two mocked `legacy-migratable` tests with exact operation-list assertions (`test_managed_block_update_preserves_exact_project_bytes`, `test_known_version_upgrade_replaces_unchanged_managed_profiles` — each gains 13 `create` operations), and any `lines[-5:]`-style ignore-rule slice (now `lines[-7:]`); confirm each name and expectation against the live file rather than trusting this list. Add cases proving: (a) a `new` shared project's apply installs all 13 OpenCode files byte-matching templates and a follow-up plan is `up-to-date`; (b) editing any one installed `.opencode/agent/sw-*.md` or `.opencode/command/sw-*.md` classifies the project `drifted` with zero writes on apply attempts; (c) a `legacy-migratable` 2026.7.29 project (real `KNOWN_PROFILE_DIGESTS_BY_VERSION` entry, no mock; seed `AGENTS.md` with `render_managed_block("2026.7.29")`, matching Codex profiles, no `.opencode/` files) reaches `up-to-date` with the 13 creates applied; (d) local-mode apply writes exactly the seven ignore rules. Extend — never delete or weaken — existing cases.

- [ ] **Step 16: Run the task `Validation:` command — all four suites pass**
- [ ] **Step 17: Commit** — `feat(scripts,tests): tri-host managed template sets with 2026.7.29 migration`

## Phase 3: Documentation

### T4: Tri-host docs sweep

**AC:** AC-6, AC-7, AC-8
**Delegable:** yes — mechanical text updates across enumerated files; behavior is final after T3
**Depends on:** T3
**Files:**
- Modify: `plugins/sw/skills/init/SKILL.md`
- Modify: `plugins/sw/skills/update/SKILL.md`
- Modify: `plugins/sw/skills/brainstorm/SKILL.md`
- Modify: `plugins/sw/skills/brainstorm/visual-companion.md`
- Modify: `plugins/sw/skills/plan/SKILL.md`
- Modify: `plugins/sw/skills/run/SKILL.md`
- Modify: `plugins/sw/commands/init.md`
- Modify: `plugins/sw/commands/update.md`
- Modify: `plugins/sw/references/validation.md`
- Modify: `plugins/sw/references/vault-files.md`
- Modify: `plugins/sw/references/audit-checklist.md`
- Modify: `README.md`
- Modify: `CONTRIBUTING.md`
**Integration:** isolated
**Validation:** `UV_CACHE_DIR=/tmp/specwright-uv-cache uv run --offline --with PyYAML python3 plugins/sw/scripts/quick_validate.py plugins/sw/skills/init && UV_CACHE_DIR=/tmp/specwright-uv-cache uv run --offline --with PyYAML python3 plugins/sw/scripts/quick_validate.py plugins/sw/skills/update && UV_CACHE_DIR=/tmp/specwright-uv-cache uv run --offline --with PyYAML python3 plugins/sw/scripts/quick_validate.py plugins/sw/skills/brainstorm && UV_CACHE_DIR=/tmp/specwright-uv-cache uv run --offline --with PyYAML python3 plugins/sw/scripts/quick_validate.py plugins/sw/skills/plan && UV_CACHE_DIR=/tmp/specwright-uv-cache uv run --offline --with PyYAML python3 plugins/sw/scripts/quick_validate.py plugins/sw/skills/run && bash tests/validate-spec/run.sh`

- [ ] **Step 1: `plugins/sw/skills/init/SKILL.md`** — description: replace "dual-host project state" with "project state", list the OpenCode agents/commands installation, and add `'/sw-init'` to the trigger list. Announce line (~21): "Setting up specwright's dual-host project state..." → "Setting up specwright's project state...". Intro (lines 9-16): replace "in Claude Code\nand Codex" framing with host-neutral "across every supported host" and add "four `.opencode/agent/sw-*.md` role profiles and nine `.opencode/command/sw-*.md` redirects" to the bullet list. Required-files list (section 1): append the four paths `templates/opencode-agents/sw-change-owner.md`, `templates/opencode-agents/sw-spec-document-reviewer.md`, `templates/opencode-agents/sw-reviewer.md`, `templates/opencode-agents/sw-task-worker.md` and the nine `templates/opencode-commands/sw-*.md` paths, written out one per line. Section 2 mode bullets: shared tracks also "the four `.opencode/agent/sw-*.md` profiles and nine `.opencode/command/sw-*.md` redirects"; local ignores exactly the two additional patterns. Verify section: add a check that all 13 `.opencode/` files byte-match the installed templates, and update the local ignore-rule check from "all five exact local patterns" to "all seven exact local patterns".
- [ ] **Step 2: `plugins/sw/skills/update/SKILL.md`** — description: replace "for Claude Code and Codex" with "across every supported host" and add `'/sw-update'` trigger. The sentence listing what the updater owns (line ~10): add "the four `.opencode/agent/sw-*.md` profiles and the nine `.opencode/command/sw-*.md` redirects". Sweep the whole file for "four project-scoped Codex profiles"-style enumerations (including the verify guidance near the end) and extend each to cover the 13 OpenCode files.
- [ ] **Step 3: `plugins/sw/skills/brainstorm/SKILL.md`** — description: add `'/sw-brainstorm'` trigger. Handoff block (lines ~140-143): add a third line `OpenCode: /sw-run <slug>`, and update the preceding "both valid resume surfaces" phrasing (line ~138) to cover all three surfaces.
- [ ] **Step 4: `plugins/sw/skills/brainstorm/visual-companion.md`** — after the Codex launch note, add: `**OpenCode:** the visual companion has not been verified under OpenCode; treat background-process behavior as unknown.`
- [ ] **Step 5: `plugins/sw/skills/plan/SKILL.md`** — gate 3 (lines ~137-138): replace "invoke `/sw:review-spec` in Claude Code or\n`$sw:review-spec` in Codex" with "invoke the host's `sw:review-spec` surface (`/sw:review-spec` in Claude Code, `$sw:review-spec` in Codex, `/sw-review-spec` in OpenCode)". Deliver section (lines ~305-306): same treatment for `sw:pr` and `sw:review` surfaces.
- [ ] **Step 6: `plugins/sw/skills/run/SKILL.md`** — description: add `'/sw-run'` trigger. Local-mode paragraphs (lines ~27, ~49, ~65): the copy-in set becomes "canonical local instructions, their Claude symlink, the project-installed `sw-*` Codex profiles, the `.opencode/agent/sw-*.md` and `.opencode/command/sw-*.md` files, and the change folder"; copy-back remains the change folder only (instructions and host profiles stay conductor-owned). Line ~128 host-surface mention: add `/sw-run` in OpenCode.
- [ ] **Step 7: `plugins/sw/commands/init.md` and `plugins/sw/commands/update.md`** — descriptions: replace with the neutral wording from T2's table (`Set up specwright's project state — ...` / `... across every supported host without overwriting drift`).
- [ ] **Step 8: `plugins/sw/references/validation.md`** — section 4 heading/body: cover "Codex role profiles **and OpenCode managed files** match installed templates" — all four `.opencode/agent/sw-*.md` and nine `.opencode/command/sw-*.md` byte-match. The inventory check near line 125: add that nine `.opencode/command/sw-*.md` files remain pure redirects (no host-specific behavior).
- [ ] **Step 9: `plugins/sw/references/vault-files.md`** — shared spec: the 13 `.opencode/` files are tracked; local spec: the two new ignore patterns appear exactly. Keep every existing line's meaning.
- [ ] **Step 10: `plugins/sw/references/audit-checklist.md`** — add the two template directories and the 13 installed files to the inventory sections they belong to.
- [ ] **Step 11: `README.md`** — (a) Install: add `### OpenCode` — clone the repository, then add `{"skills": {"paths": ["<checkout>/plugins/sw/skills"]}}` to `opencode.json` (project or `~/.config/opencode/opencode.json`), restart OpenCode; update the "Both hosts install the same package and the same nine skills." line to cover all three hosts. (b) Parity table: add an `OpenCode` column with `/sw-init` … `/sw-update`, and neutralize the init row's "Plan and create dual-host project state." purpose cell. (c) "The updater owns only" list: add the OpenCode agents and commands bullets. (d) "Project state after initialization" tree: add `.opencode/agent/` (4 files) and `.opencode/command/` (9 files). (e) "Repository layout": add two child lines under the `templates/` entry naming `templates/opencode-agents/` and `templates/opencode-commands/` with one-line responsibilities. (f) Role table: add an OpenCode column — model "inherits session model (no pin)", sandbox "default" for owner/worker and `edit: deny` for the two reviewers. (g) One caveat sentence: OpenCode does not namespace skills loaded via `skills.paths`; specwright's skill names (`plan`, `run`, …) may shadow same-named user skills. (h) The local-mode paragraph in "Change flow and worker integration" (the `sw:run` copy-in set): add the `.opencode/agent/sw-*.md` and `.opencode/command/sw-*.md` files to the copied set, keeping copy-back as the change folder only. (i) The opening tagline (line 3, "`specwright` (`sw`) is a dual-host plugin for Claude Code and Codex") and any other "dual-host" mention become tri-host ("for Claude Code, Codex, and OpenCode").
- [ ] **Step 12: `CONTRIBUTING.md`** — rule 5: extend to "Treat `.codex/agents/sw-*.toml` and `.opencode/{agent,command}/sw-*.md` as generated project files. Change their source templates and migration tests together." Scope list: after "thin Claude redirects" add "and OpenCode command/agent adapters". Release smoke section: add one sentence that OpenCode has no package ingestion to smoke-test; its coverage is the install/update matrix. PR checklist item "The dual-host release smoke test passes when package surfaces change." → "The host release smoke test passes when package surfaces change."
- [ ] **Step 13: No-op sweep of the remaining skills** — read `plugins/sw/skills/spec/SKILL.md`, `review/SKILL.md`, `review-spec/SKILL.md`, and `pr/SKILL.md` and grep them for dual-host-only phrasing (`dual-host`, `/sw:` and `$sw:` surface lists without an OpenCode entry). Verified clean at planning time; edit only if the grep finds a stale spot, and report either outcome.

- [ ] **Step 14: Run the task `Validation:` command — quick_validate passes for all five modified skills and the validate-spec suite passes**
- [ ] **Step 15: Commit** — `docs(skills,references): tri-host surfaces and opencode install path`
## Phase 4: Dogfood + gates

### T5: Dogfood this repository and run every gate

**AC:** AC-9
**Delegable:** no — owner-only: migrates the canonical repo, asks the user to confirm the exact plan_id, and records runtime verification
**Depends on:** T4
**Files:**
- Create: `.opencode/agent/sw-change-owner.md`
- Create: `.opencode/agent/sw-reviewer.md`
- Create: `.opencode/agent/sw-spec-document-reviewer.md`
- Create: `.opencode/agent/sw-task-worker.md`
- Create: `.opencode/command/sw-brainstorm.md`
- Create: `.opencode/command/sw-init.md`
- Create: `.opencode/command/sw-plan.md`
- Create: `.opencode/command/sw-pr.md`
- Create: `.opencode/command/sw-review-spec.md`
- Create: `.opencode/command/sw-review.md`
- Create: `.opencode/command/sw-run.md`
- Create: `.opencode/command/sw-spec.md`
- Create: `.opencode/command/sw-update.md`
- Modify: `AGENTS.md`
- Modify: `.specwright/conventions/skill-validation-requirements.md`
**Integration:** inline
**Validation:** `python3 plugins/sw/scripts/sw_update.py --plan --project "$PWD" --mode shared --format json` reports `up-to-date` with zero operations

- [ ] **Step 1: Amend the skill-validation convention** — `.specwright/conventions/skill-validation-requirements.md` must enforce the tri-host reality against future diffs (without this amendment, review lane A would apply stale "both valid surfaces" wording against T4's tri-host skill text): "A shared skill must be discoverable from the same `plugins/sw/skills/` source by both host adapters" → "by every host adapter". "Workflow behavior lives only in `SKILL.md`. The homonymous Claude command is a pure redirect, and the Codex manifest points at the shared skills root." — append "OpenCode commands in `templates/opencode-commands/` are equally pure redirects." Heading "Dual-host behavior" → "Host-surface behavior"; its first bullet → "User-facing syntax in a shared skill is host-neutral or names every valid surface: `/sw:*` for Claude Code, `$sw:*` for Codex, `/sw-*` for OpenCode." Required checks: "the dual-host release smoke test" → "the host release smoke test" (matching T4's CONTRIBUTING rename). Commit as `docs(conventions): tri-host skill surface requirements`.
- [ ] **Step 2: Plan this repo's migration** — run `python3 plugins/sw/scripts/sw_update.py --plan --project "$PWD" --mode shared --format json`; expect state `legacy-migratable`, 13 `create` operations for `.opencode/`, one `replace-managed-block` on `AGENTS.md`, and no `ensure-ignore-rules` (shared rules unchanged). Display the full `plan_id`.
- [ ] **Step 3: Ask the user to confirm the exact displayed `plan_id`** — the update skill's explicit-confirmation rule applies to the owner too; only an affirmative authorizes the apply.
- [ ] **Step 4: Apply** — `python3 plugins/sw/scripts/sw_update.py --apply --expect-plan "<confirmed-plan-id>" --project "$PWD" --mode shared --format json`.
- [ ] **Step 5: Re-plan** — expect `up-to-date` with zero operations (the task `Validation:` command).
- [ ] **Step 6: Commit the dogfood** — `git add .opencode AGENTS.md` then `chore: migrate dogfooded project state to 2026.7.30 tri-host`.
- [ ] **Step 7: Full validation matrix** — `claude plugin validate --strict plugins/sw`; `bash tests/install/run.sh package init`; `bash tests/install/run.sh update worktree topology`; `python3 tests/update/test_plan.py`; `python3 tests/worktrees/test_local_copy.py`; `python3 tests/task-topology/test_parser.py`; `bash tests/release/run.sh`; the skill authoring checks from CONTRIBUTING for every modified skill.
- [ ] **Step 8: OpenCode discovery check** — attempt `opencode run` with a prompt asking to enumerate custom commands matching `sw-*` and subagents matching `sw-*` in this checkout. If the CLI output credibly lists the nine commands and four agents, record it for AC-9; if it cannot be obtained headlessly, mark AC-9's discovery clause `needs-human-verification` in `change.md` with the one-line reason.
- [ ] **Step 9: Runtime-verify every AC-N** against `change.md` (each check takes < 1 minute; record the evidence for the PR body), then tick the verified checkboxes in `change.md`.
