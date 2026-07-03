---
feature: model-routing
created: 2026-07-03
scope: high
branch: claude/relaxed-euclid-5d5db2
worktree: null
milestone: null
---
# Per-Role Model Routing — Spec

**Issue:** see the sibling `issue.md` (the *why*, the acceptance criteria, and the issue `status:`)
**Scope:** Add an agent-agnostic `.specwright/models.md` config that routes each spawned pipeline role to a model, teach the three dispatching skills to honor it, wire the scaffolder to seed+audit+validate it, and document the roles + config in the README.

This is the **technical** spec — the *how*. The non-technical *why*, the acceptance criteria, and the status live in `issue.md`.

## Architecture

**Two layers, one file, no parser.** The config is a single markdown file, `.specwright/models.md`, read directly by the conducting agent — never parsed by a script (consistent with `board.md`, the templates, and the rest of the vault). It carries:

1. **Policy — `Roles → tier`** — a table mapping each *routable role* (`issue-owner`, `worker`, `spec-reviewer`, `code-review`, plus a `default` fallback row) to a **tier**: a vendor-neutral capability label. Default tier set: `deep | balanced | fast`. This layer names no model, so it is portable across agents.
2. **Mechanism — `Bindings`** — one subsection per agent (`### claude`, `### codex`, …), each a table mapping `tier → model + effort`. Only the `claude` subsection ships populated; others are absent until an adopter adds them.

**The resolution procedure lives in the file's own header**, so the skills stay DRY: each dispatching skill reads `.specwright/models.md` anyway (step 1 of resolution), and the header states the full `role → tier → binding(this agent) → spawn` procedure plus the two invariants below. A skill's routing note therefore only names its role and points at the file — it never restates the procedure and never names a concrete model. This is what keeps `grep -iE 'opus|sonnet|haiku|fable'` over the skills empty (AC-4).

**Two invariants, stated in the header and echoed one-line per skill:**

- **Live vs advisory.** `model` is applied on the spawn today (the dispatching agent passes it to the Task/Agent spawn). `effort` is **advisory**: recorded as intent, not injected, because the interactive dispatch path has no per-spawn effort knob yet (confirmed against current Claude Code docs). It becomes live when the runtime honors per-spawn effort — no config change needed then.
- **Degradation = inherit.** A routable role whose tier has no binding for the current agent — or a repo with no `.specwright/models.md` at all — runs on the inherited session model. The feature is opt-in and purely additive: absent config reproduces today's behavior exactly. This is what lets a non-Claude agent read the same file and simply inherit.

**The top-level session is out of scope by construction.** The orchestrator (`/sw:run`) and a standalone issue owner *are* the top-level session; nothing spawns them, so no config can route them. `models.md` documents this in its header; the routing lives only where a sub-agent is actually spawned.

## File Structure

**New file:**
- `skills/sw/scaffold/templates/models.md` — the default routing config template. Ships with the `sw` skill (like the other `scaffold/templates/*.md`); the scaffolder seeds a copy into the target vault. Carries the header procedure + both invariants, the `Roles → tier` table with sensible defaults, and a populated `### claude` binding (`deep→opus/xhigh`, `balanced→sonnet/high`, `fast→sonnet/medium`).

**Scaffolder — the `sw` skill (single-copy, under `skills/sw/`):**
- `skills/sw/SKILL.md` — in Phase 4 "Vault directories", add a guarded, idempotent seed of `.specwright/models.md` from the template (mirrors the existing `conventions/README.md` seed: copy only when absent, never overwrite an edited file).
- `skills/sw/references/audit-checklist.md` — add `.specwright/models.md` to the vault inventory (seeded config; `MISSING` when absent, auto-created in Phase 4) and note its integrity is Phase 5's job.
- `skills/sw/references/validation.md` — add check #12: `.specwright/models.md` has no surviving double-brace placeholder and no dangling tier (every tier named in the `Roles → tier` table has a binding row under `### claude`). Update the contents summary (`11` → `12` checks) and the total in the pass line.

**Dispatching skills — three copies each** (canonical `.agents/skills/sw-<name>/`, scaffold `skills/sw/scaffold/skills/sw-<name>/`, plugin `plugins/sw/skills/<name>/`; plugin differs only in the line-2 `name:`):
- `sw-run/SKILL.md` — in the loop's dispatch step, a one-line **Model routing** note: route the issue owner's model via `.specwright/models.md` (role `issue-owner`); inherit if absent; `effort` advisory.
- `sw-plan/SKILL.md` — a compact **Model routing** note covering role `worker` (at the Implement fan-out) and role `spec-reviewer` (at self-review gate 2), same shape.
- `sw-review/SKILL.md` — a one-line **Model routing** note in the three-subagent section: all three lanes route via role `code-review`.

**Docs:**
- `README.md` — a new **Roles** section (the five pipeline roles, each with one line of *what it does* + *who spawns it*, and the top-level-is-`inherit`/spawned-is-routable rule); a **Model routing** subsection documenting `.specwright/models.md` (two layers, `model`-live/`effort`-advisory, the "add a binding subsection" extension path); and add `models.md` to the vault contents list under "What you get".

## Phase Ordering

- **Phase 1 — Config artifact + scaffolder.** Write the template; wire seed (SKILL.md Phase 4), audit (audit-checklist), and validation (validation.md #12). After this, `/sw` manages the file end-to-end.
- **Phase 2 — Skill routing.** Add the routing notes to `sw-run`, `sw-plan`, `sw-review` (canonical copy), then propagate to the scaffold + plugin copies and `diff`-verify.
- **Phase 3 — Docs.** README Roles section + Model routing subsection + vault list.

Phases are logically independent but ordered so the file shape (Phase 1) exists before skills (Phase 2) and docs (Phase 3) reference it. No hard build dependency.

## Constraints

- **Three-copy sync is a review blocker.** Every edit to a companion skill (`sw-run`, `sw-plan`, `sw-review`, plus `sw-plan`'s `spec-document-reviewer-prompt.md` if touched) must land in all three copies: canonical == scaffold byte-for-byte, canonical == plugin except the line-2 `name:` (`run`/`plan`/`review` vs `sw-run`/…). Verify with `diff` (AC-9).
- **No vendor model name in any skill.** The concrete models live only in `models.md`'s `### claude` binding and in the README's documentation of that binding. Skills reference tiers/roles only (AC-4).
- **`validate-spec.sh` is untouched.** It validates an *issue folder*; `models.md` is vault config, validated by the `sw` scaffolder's Phase 5 (`validation.md`), not the per-issue mechanical gate.
- **`AGENTS.md` is intentionally not modified.** `models.md` is optional additive config, documented in the README (the ACs' documentation home). AGENTS.md is the ≤80-line entry-point contract for the *workflow*, not a config reference; leaving it out is deliberate, not an oversight — noted here so the documentation-consistency review does not read it as drift.
- **Model values are spawn-compatible aliases.** The `### claude` binding uses `opus`/`sonnet` (the aliases the Task/Agent spawn accepts), with a one-line note in the template that full model IDs are also accepted where the agent supports them.

## User Stories / Scenarios

1. **Adopter routes workers cheaper.** User edits `.specwright/models.md`: `worker` → `fast`, and `### claude` maps `fast → sonnet`. Next milestone run, every `Delegable: yes` task worker the issue owner spawns runs on sonnet; owner/review still on opus. No skill was edited.
2. **Fresh install.** User runs `/sw` in a new repo → `.specwright/models.md` is created from the template with defaults. Runs `/sw` again → the file is untouched (idempotent).
3. **Non-Claude agent.** A Codex user's repo has `models.md` with only the `### claude` binding. Codex, dispatching an owner, finds no `### codex` binding → inherits the session model. Nothing breaks. Later the user adds a `### codex` subsection and routing goes live for Codex too — zero skill edits.
4. **Effort today.** User sets `deep → opus / xhigh`. The owner spawns review sub-agents on opus (live); the `xhigh` is recorded but not injected — the README and the file header both say so, so the user is not misled.

## Risks and Mitigations

| Risk | Mitigation |
|---|---|
| Skills drift out of sync across the three copies | `diff`-verify every touched skill in the quality gate; AC-9 makes it a hard check. |
| A concrete model name leaks into a skill, re-coupling it to Claude | Resolution procedure lives in `models.md`, not the skills; skills name only roles/tiers; grep check in runtime verification (AC-4). |
| Users read `effort` as live and expect behavior that isn't wired | Both the file header and the README label `effort` advisory; each skill note restates it (AC-5). |
| Existing installs suddenly report `models.md` MISSING | Intended: the audit auto-seeds it in Phase 4; behavior is unchanged because absent==inherit. |
| Making `models.md` a required vault item breaks the "opt-in" promise | The file *existing* with defaults still reproduces inherit-like behavior only where bindings match; the routing itself is what the user opts into by editing. Defaults are documented as such. |

## Open Questions

None.
