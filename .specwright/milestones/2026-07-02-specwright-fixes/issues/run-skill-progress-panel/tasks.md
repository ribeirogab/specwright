---
feature: run-skill-progress-panel
created: 2026-07-02
---
# Run Skill Progress Panel — Tasks

**For this issue:** see the sibling `issue.md` (acceptance criteria) and `spec.md` (technical plan).

> Each task names the `AC:` (acceptance criteria from `issue.md` it satisfies — every `AC-N` must be referenced by at least one task) and `Delegable:` (whether it suits an isolated task worker, and the one-line context that worker would receive). Workers report findings back to the issue owner; only the owner writes `learnings.md`.

## Phase 1: Author the section on the canonical copy

### Task 1: Write the "Progress reporting" section (panel structure) on canonical `sw-run`

**AC:** AC-1, AC-2, AC-3, AC-4
**Delegable:** no — single authored section that must match the approved standard verbatim in structure; the owner holds that reference and the copy-parity invariant.
**Files:**
- Modify: `.agents/skills/sw-run/SKILL.md` — insert `## Progress reporting` after the `## The loop` section and before `## Circuit breakers`.

- [ ] **Step 1: Read the two anchor headings to locate the insertion point**

Run: `grep -n '^## ' .agents/skills/sw-run/SKILL.md`
Expected: lines listing `## The loop`, `## Circuit breakers`, `## Closeout (all shipped)`, `## Degradation — no sub-agent support`, `## Boundaries`. The new section goes between `## The loop` and `## Circuit breakers`.

- [ ] **Step 2: Insert the section** (via Edit, anchoring on the `## Circuit breakers` heading so the new block precedes it)

The section, in order, must state:
  - **The panel, top to bottom (AC-1):** a KPI row of four cards — overall weighted % (shipped issues + in-flight fraction), shipped count `N / total` with the PR range, in-progress count with which issue, findings-in-dossier count; an overall stacked progress bar with three segments (shipped / running / queued) and the caption `X shipped · Y rodando · Z na fila`; a per-issue row list in board order, each row an 88px status-chip pill (`shipped` / `rodando` / `na fila`) + the issue name + a muted one-liner; a sub-milestone section below a hairline with the same bar shape.
  - **The reference palette (AC-1 support):** green `#1D9E75` shipped, amber `#EF9F27` in-flight, track queued — recorded as the reference look, with a note that the *structure* is the contract and the palette reproduces the approved rendering.
  - **The two triggers (AC-2):** render on any progress question from the maintainer, and at round transitions (the loop's re-evaluate step).
  - **The compact line (AC-3):** every text status update during conduction ends with a one-line summary carrying overall %, shipped `X of N`, the currently running issue(s), and the queued count; reference format `Progresso: ~NN% — X/N shipped · <current> rodando (~NN%) · Y na fila`; state the field format and that the line's language follows the conversation.
  - **The degradation rule (AC-4):** a session with no visual rendering capability emits the panel content as a text table plus the compact line — never skipping the update.
  - **Tool-agnostic framing (spec Non-Goal):** describe what to render and when; name a renderer only as a reference example.

- [ ] **Step 3: Verify the section landed with all four content anchors**

Run: `grep -nE 'Progress reporting|stacked progress bar|Progresso:|text table|progress question|round transition' .agents/skills/sw-run/SKILL.md`
Expected: matches for the heading, the bar, the compact-line format, the degradation text-table rule, and both triggers — proving AC-1..AC-4 content is present in the canonical copy.

- [ ] **Step 4: Confirm no literal double-brace was introduced** (validate-spec.sh check 3 guard)

Run: `grep -nE '[{][{]' .agents/skills/sw-run/SKILL.md; echo "exit: $?"`
Expected: no output, `exit: 1` (grep found nothing) — the section uses word-placeholders, never the delimiter. (The pattern uses a bracket class so this task file itself carries no literal double-brace and does not trip check 3.)

- [ ] **Step 5: Commit the canonical edit**

Run: `git add .agents/skills/sw-run/SKILL.md && git commit -m "feat: add progress-reporting section to run skill"`

## Phase 2: Propagate to the two sibling copies and verify parity

### Task 2: Rebuild the plugin and scaffold copies from canonical, byte-parity except `name:`

**AC:** AC-5
**Delegable:** no — mechanical byte-copy that must preserve each copy's line-2 `name:`; the owner verifies parity.
**Files:**
- Modify: `plugins/sw/skills/run/SKILL.md` — rebuilt `head -2` (keeps `name: run`) + `tail -n +3` of canonical.
- Modify: `skills/sw/scaffold/skills/sw-run/SKILL.md` — rebuilt `head -2` (keeps `name: sw-run`) + `tail -n +3` of canonical.

- [ ] **Step 1: Rebuild the plugin copy from canonical**

Run:
```bash
{ head -2 plugins/sw/skills/run/SKILL.md; tail -n +3 .agents/skills/sw-run/SKILL.md; } > /tmp/run-skill-plugin.md && mv /tmp/run-skill-plugin.md plugins/sw/skills/run/SKILL.md
```

- [ ] **Step 2: Rebuild the scaffold copy from canonical**

Run:
```bash
{ head -2 skills/sw/scaffold/skills/sw-run/SKILL.md; tail -n +3 .agents/skills/sw-run/SKILL.md; } > /tmp/run-skill-scaffold.md && mv /tmp/run-skill-scaffold.md skills/sw/scaffold/skills/sw-run/SKILL.md
```

- [ ] **Step 3: Verify canonical vs scaffold are byte-identical from line 3, and differ only on line 2**

Run: `diff <(tail -n +3 .agents/skills/sw-run/SKILL.md) <(tail -n +3 skills/sw/scaffold/skills/sw-run/SKILL.md) && echo IDENTICAL; diff .agents/skills/sw-run/SKILL.md skills/sw/scaffold/skills/sw-run/SKILL.md`
Expected: `IDENTICAL` printed; the full `diff` shows **no** hunks (canonical and scaffold share `name: sw-run`, so they are fully identical).

- [ ] **Step 4: Verify canonical vs plugin differ only in the `name:` line**

Run: `diff <(tail -n +3 .agents/skills/sw-run/SKILL.md) <(tail -n +3 plugins/sw/skills/run/SKILL.md) && echo IDENTICAL; diff .agents/skills/sw-run/SKILL.md plugins/sw/skills/run/SKILL.md`
Expected: `IDENTICAL` printed (from line 3); the full `diff` shows exactly one hunk changing `name: sw-run` → `name: run` on line 2 — this is AC-5.

- [ ] **Step 5: Commit the two propagated copies**

Run: `git add plugins/sw/skills/run/SKILL.md skills/sw/scaffold/skills/sw-run/SKILL.md && git commit -m "feat: propagate progress-reporting section to plugin and scaffold copies"`

## Phase 3: Gates and runtime verification

### Task 3: Validate the plan folder and the touched skills, then runtime-verify every AC

**AC:** AC-1, AC-2, AC-3, AC-4, AC-5
**Delegable:** no — the owner runs the gates and records verification for the PR body.
**Files:**
- Test: `skills/sw/scripts/validate-spec.sh` (plan folder), `skills/sw/scripts/quick_validate.py` (each touched skill).

- [ ] **Step 1: Mechanical spec gate to exit 0**

Run: `bash skills/sw/scripts/validate-spec.sh .specwright/milestones/2026-07-02-specwright-fixes/issues/run-skill-progress-panel; echo "exit: $?"`
Expected: `PASS`, `exit: 0`.

- [ ] **Step 2: Skill validator on the canonical run skill** (quality gate — repo PR template requires it for a modified skill)

Run: `uv run --with pyyaml python skills/sw/scripts/quick_validate.py .agents/skills/sw-run 2>&1 || /usr/bin/python3 skills/sw/scripts/quick_validate.py .agents/skills/sw-run`
Expected: validator passes (no frontmatter/structure error).

- [ ] **Step 3: Runtime-verify AC-1** — the panel structure is present top to bottom

Run: `grep -nE 'KPI|overall weighted|stacked progress bar|status.chip|88px|sub-milestone|hairline' .agents/skills/sw-run/SKILL.md`
Expected: matches proving KPI row, weighted %, stacked bar, per-issue chip list (88px), and sub-milestone/hairline are all named. Record in the PR body.

- [ ] **Step 4: Runtime-verify AC-2** — both triggers stated

Run: `grep -nE 'progress question|round transition' .agents/skills/sw-run/SKILL.md`
Expected: both trigger phrases present.

- [ ] **Step 5: Runtime-verify AC-3** — compact line mandated with field format

Run: `grep -nF 'Progresso: ~NN% — X/N shipped' .agents/skills/sw-run/SKILL.md; grep -niE 'every text (status )?update|language follows' .agents/skills/sw-run/SKILL.md`
Expected: the reference format line and the "every text update ends" + "language follows the conversation" wording are present.

- [ ] **Step 6: Runtime-verify AC-4** — degradation to text table

Run: `grep -niE 'text table|never skip' .agents/skills/sw-run/SKILL.md`
Expected: the degradation rule (text table + never skip) present.

- [ ] **Step 7: Runtime-verify AC-5** — three copies differ only in `name:`

Run:
```bash
diff <(tail -n +3 .agents/skills/sw-run/SKILL.md) <(tail -n +3 plugins/sw/skills/run/SKILL.md) && echo PLUGIN-BODY-IDENTICAL
diff <(tail -n +3 .agents/skills/sw-run/SKILL.md) <(tail -n +3 skills/sw/scaffold/skills/sw-run/SKILL.md) && echo SCAFFOLD-BODY-IDENTICAL
```
Expected: both `*-BODY-IDENTICAL` printed; the only whole-file difference is the plugin's `name: run` line. Record in the PR body.

- [ ] **Step 8: Tick verified AC checkboxes in issue.md and commit the verification state**

After all ACs verified, tick `AC-1`..`AC-5` in `issue.md` and commit with the plan artifacts.
Run: `git add .specwright/milestones/2026-07-02-specwright-fixes/issues/run-skill-progress-panel && git commit -m "chore: verify run-skill-progress-panel acceptance criteria"`
