---
feature: model-routing
created: 2026-07-03
---
# Per-Role Model Routing — Tasks

**For this issue:** see the sibling `issue.md` (acceptance criteria) and `spec.md` (technical plan).

> Each task names the `AC:` (acceptance criteria from `issue.md` it satisfies — every `AC-N` must be referenced by at least one task) and `Delegable:` (whether it suits an isolated task worker, and the one-line context that worker would receive). Workers report findings back to the issue owner; only the owner writes `learnings.md`.

## Phase 1: Config artifact + scaffolder

### Task 1: Default routing template

**AC:** AC-1, AC-5, AC-6
**Delegable:** no — sets the vocabulary (roles, tiers, resolution procedure, invariants) every later task references; one hand must fix it.
**Files:**
- Create: `skills/sw/scaffold/templates/models.md`

- [x] Step 1: Write the file header: a one-paragraph purpose, the full resolution procedure (`role → tier` in the Roles table → `tier → model` in the current agent's binding → spawn with that model), the **live vs advisory** invariant (`model` applied on spawn today; `effort` advisory/recorded-only), the **degradation = inherit** invariant (no binding for this agent, or no file → inherit the session model), and the note that the top-level session (orchestrator / standalone owner) is never routed here.
- [x] Step 2: Write the `## Roles → tier` table: rows `issue-owner→deep`, `worker→fast`, `spec-reviewer→deep`, `code-review→deep`, `default→balanced`.
- [x] Step 3: Write `## Bindings` with a `### claude` table: `deep→opus/xhigh`, `balanced→sonnet/high`, `fast→sonnet/medium`; add a one-line note that model values may be aliases (`opus`/`sonnet`) or full IDs where the agent supports them.
- [x] Step 4: Verify no double-brace placeholder survives and every tier used in the Roles table has a `### claude` row (`grep -c` the three tiers).
- [x] Step 5: Commit.

### Task 2: Scaffolder seeds models.md (idempotent)

**AC:** AC-2
**Delegable:** yes — "In `skills/sw/SKILL.md` Phase 4 'Vault directories', add a guarded seed of `.specwright/models.md` from `scaffold/templates/models.md`, copying only when the target is absent (mirror the existing conventions/README.md emptiness-guarded seed just above)."
**Files:**
- Modify: `skills/sw/SKILL.md` (Phase 4 — Vault directories)

- [x] Step 1: Add a shell block that copies the template to `.specwright/models.md` only when that file does not exist (`[ -e ... ] || cp ...`), so a re-run never overwrites an edited file.
- [x] Step 2: Add one sentence to the surrounding prose describing the seed and its idempotence.
- [x] Step 3: Verify by dry-reading: absent → created; present → untouched.
- [x] Step 4: Commit.

### Task 3: Audit + validation cover models.md

**AC:** AC-3
**Delegable:** yes — "Add `.specwright/models.md` to `references/audit-checklist.md`'s vault inventory, and add validation check #12 (no unsubstituted double-brace placeholder; no dangling tier — every Roles-table tier has a `### claude` binding row) to `references/validation.md`, updating the check count 11→12."
**Files:**
- Modify: `skills/sw/references/audit-checklist.md`
- Modify: `skills/sw/references/validation.md`

- [x] Step 1: In `audit-checklist.md` "Files and directories to check", add `.specwright/models.md` with a one-line description (seeded routing config; `MISSING` when absent → auto-created in Phase 4).
- [x] Step 2: In `validation.md`, add check #12 with a bash recipe: `grep -E '[{][{]' .specwright/models.md` → FAIL; and for each tier in the Roles table, confirm a matching row exists under `### claude` → FAIL naming the dangling tier.
- [x] Step 3: Update `validation.md` contents summary (`11 numbered checks` → `12`) and the "everything passes" line (`11/11` → `12/12`).
- [x] Step 4: Run the new check recipe against the seeded file → expect PASS.
- [x] Step 5: Commit.

## Phase 2: Skill routing

### Task 4: sw-run routes the issue owner

**AC:** AC-4, AC-5, AC-6
**Delegable:** no — wording must match the other two skills' routing notes and the models.md header.
**Files:**
- Modify: `.agents/skills/sw-run/SKILL.md` (the loop's dispatch step)

- [x] Step 1: In the "Dispatch one issue owner per ready issue" step, add a **Model routing** bullet: resolve the owner's model via `.specwright/models.md` (role `issue-owner`) and spawn with it; no binding for this agent / no file → inherit; `effort` there is advisory today.
- [x] Step 2: Confirm the note names only the role/tier vocabulary — no `opus`/`sonnet`/`haiku`/`fable`.
- [x] Step 3: Commit (canonical only; sync in Task 7).

### Task 5: sw-plan routes worker + spec-reviewer

**AC:** AC-4, AC-5, AC-6
**Delegable:** no — same wording-consistency constraint as Task 4.
**Files:**
- Modify: `.agents/skills/sw-plan/SKILL.md` (Implement fan-out; self-review gate 2)

- [x] Step 1: Add a compact **Model routing** note covering role `worker` (Implement fan-out) and role `spec-reviewer` (self-review gate 2): resolve via `.specwright/models.md`, spawn with the model, inherit if absent, `effort` advisory.
- [x] Step 2: Confirm no concrete model name appears.
- [x] Step 3: Commit (canonical only; sync in Task 7).

### Task 6: sw-review routes the review lanes

**AC:** AC-4, AC-5, AC-6
**Delegable:** no — same wording-consistency constraint.
**Files:**
- Modify: `.agents/skills/sw-review/SKILL.md` (three-subagent section)

- [x] Step 1: In the three-subagent review section, add a **Model routing** note: all three lanes route via role `code-review` in `.specwright/models.md`; inherit if absent; `effort` advisory.
- [x] Step 2: Confirm no concrete model name appears.
- [x] Step 3: Commit (canonical only; sync in Task 7).

### Task 7: Propagate to all three copies + diff-verify

**AC:** AC-9
**Delegable:** no — mechanical but must follow Tasks 4-6 and preserve each plugin copy's line-2 `name:`.
**Files:**
- Modify: `skills/sw/scaffold/skills/sw-{run,plan,review}/SKILL.md`
- Modify: `plugins/sw/skills/{run,plan,review}/SKILL.md`

- [x] Step 1: Copy each edited canonical `SKILL.md` over its scaffold twin.
- [x] Step 2: Copy each edited canonical `SKILL.md` over its plugin twin, then restore the plugin line-2 `name:` to the bare form (`run`/`plan`/`review`).
- [x] Step 3: `diff` canonical vs scaffold (expect empty) and canonical vs plugin (expect only line 2) for all three skills.
- [x] Step 4: Commit.

## Phase 3: Docs

### Task 8: README Roles section

**AC:** AC-7
**Delegable:** no — same authorial voice as the rest of the README.
**Files:**
- Modify: `README.md`

- [x] Step 1: Add a `## Roles` section: a table of the five pipeline roles (`orchestrator`, `issue-owner`, `worker`, `spec-reviewer`, `code-reviewer`) with one line each of *what it does* + *who spawns it*, and a sentence stating the top-level session (orchestrator / standalone owner) is `inherit` while spawned roles are routable.
- [x] Step 2: Verify all five roles and the inherit-vs-routable rule are present.
- [x] Step 3: Commit.

### Task 9: README Model routing doc + vault list

**AC:** AC-8
**Delegable:** no — continues Task 8's section.
**Files:**
- Modify: `README.md`

- [x] Step 1: Add a **Model routing** subsection documenting `.specwright/models.md`: the two layers (role→tier, tier→binding), `model`-live / `effort`-advisory, and the "add a `### <agent>` binding subsection" extension path.
- [x] Step 2: Add `models.md` to the vault contents list under "What you get".
- [x] Step 3: Verify the two-layer model, the live/advisory distinction, and the extension path all read clearly.
- [x] Step 4: Commit.
