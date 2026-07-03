---
feature: model-routing
created: 2026-07-03
status: in-progress
shipped: null
---
# Per-Role Model Routing — Issue

> The ticket: the approved *why* plus the acceptance criteria and the issue's status. `status:` lives **only** here — `pending | in-progress | shipped | blocked` — and `shipped:` gets the ship date when the PR is open and `/sw:review` reached `lgtm`. The technical *how* lives in the sibling `spec.md` + `tasks.md`, written just-in-time by `/sw:plan`.

## Purpose

Let a specwright adopter decide **which model (and, later, which reasoning effort) each spawned pipeline role runs on** — issue owner, task worker, spec reviewer, code reviewer — through one declarative, **agent-agnostic** config, without editing any skill. The routing is expressed in two layers so it never gets locked to one vendor: a **policy** layer (`role → tier`) that names no model, and a **binding** layer (`tier → model + effort`) with one subsection per agent. Alongside it, document the pipeline **roles** as a first-class concept in the README — the same vocabulary the config routes.

After this delivery, a user writes `.specwright/models.md` once ("workers = fast, review = deep"), fills the `claude` binding with concrete models, and every spawned role in the pipeline runs on the routed model. Adding a second agent later (Codex, Cursor, …) is one new binding subsection — zero skill edits.

## Motivation

Today every spawned role inherits the conducting session's model. A milestone therefore burns the same heavyweight model on cheap, mechanical `Delegable: yes` task workers as on architectural review, with no knob to say otherwise. The user wants explicit, per-role control (e.g. owner/review on a strong model, workers on a cheaper one) — but expressed in a way that survives specwright's agent-agnostic promise instead of hardcoding Claude model names into the skills.

Separating **policy** (how much capability a role needs) from **mechanism** (which concrete model an agent uses to realize that) is the only way to get both: real routing today on Claude, and a clean extension path for other agents. It is the Rule of Separation applied to model selection.

## Definitions

- **Routable role** — a pipeline role that is **spawned** as a sub-agent and can therefore be routed: `issue-owner`, `worker`, `spec-reviewer`, `code-review`. The **orchestrator** (and a standalone issue owner) is the top-level session and is **never routable** — it runs on whatever model the session was launched with (`inherit`).
- **Tier** — a vendor-neutral capability label used by the policy layer (default set: `deep | balanced | fast`). Skills reference tiers, never concrete models.
- **Binding** — a per-agent mapping `tier → model + effort` under a named subsection (`claude`, `codex`, …). Realizes each tier for one concrete agent.
- **Live vs advisory** — `model` routing is **live** on Claude Code today (passed on the spawn). `effort` is **advisory**: recorded as intent, not yet injected on the dynamic dispatch path; it becomes live when the runtime honors per-spawn effort.
- **Inherit** — the fallback: a routable role whose tier has no binding for the current agent runs on the session model. The whole feature is opt-in and additive — absent config or absent binding = today's behavior.

## Non-Goals

- **No routing of the top-level session.** The orchestrator / standalone owner model is set at launch (`/model`); the config documents the intended launch model at most, never injects it.
- **No effort enforcement today.** The `effort` column is advisory (see Definitions); this issue does not attempt to force per-spawn effort while the dispatch path lacks the knob.
- **No non-Claude bindings shipped populated.** The default template ships only the `claude` binding filled; other agents are left to `inherit` until an adopter adds their subsection. The design must support them; this issue does not author them.
- **No parser or new script.** The config is markdown read by the agent, consistent with the rest of the vault; no runtime parser is introduced. `validate-spec.sh` is unchanged — models.md validation lives in the `sw` scaffolder's audit/validation, not the per-issue validator.
- **No change to the pipeline itself** — same roles, same gates, same order. Only *which model each spawned role uses* becomes configurable, plus documentation.

## Acceptance Criteria

- [x] **AC-1** A bundled template produces `.specwright/models.md` with two sections: a **Roles → tier** table mapping each routable role (`issue-owner`, `worker`, `spec-reviewer`, `code-review`) plus a `default` row to a tier; and a **Bindings** section containing a `claude` subsection mapping tiers `deep`/`balanced`/`fast` to a concrete `model` + `effort`. Every tier named in the Roles table has a matching binding row under `claude` (no dangling tier).
- [x] **AC-2** The `sw` scaffolder creates `.specwright/models.md` from that template when it is absent, and a second run does **not** overwrite an existing file: delete the file and run → it is created; edit a value and run again → the edited value is preserved.
- [x] **AC-3** The `sw` audit checklist lists `.specwright/models.md` with a status of `OK`/`MISSING`/`DRIFT`, and the scaffolder's validation FAILs on a models.md that still contains an unsubstituted double-brace placeholder or references a tier with no binding row under `claude` — the failure line names the specific defect.
- [x] **AC-4** The dispatch instructions in `sw-plan`, `sw-run`, and `sw-review` resolve `role → tier → binding(current agent) → spawn with that model`, and contain **no hardcoded concrete model name**: grepping those three skills for `opus`/`sonnet`/`haiku`/`fable` in their routing instructions returns only tier names, never a vendor model.
- [x] **AC-5** Each routing instruction passes `model` on the spawn and explicitly labels `effort` as advisory/not-yet-injected, so a reader cannot mistake effort for live behavior.
- [x] **AC-6** Each routing instruction states the degradation rule: a routable role whose tier has no binding subsection for the current agent runs on the inherited session model — verifiable by reading any one of the three skills' routing blocks.
- [x] **AC-7** `README.md` gains a **Roles** section enumerating the five pipeline roles (`orchestrator`, `issue-owner`, `worker`, `spec-reviewer`, `code-reviewer`), each with a one-line "what it does" and "who spawns it", and states that the top-level session (orchestrator / standalone owner) is `inherit` while spawned roles are routable.
- [x] **AC-8** `README.md` documents `.specwright/models.md`: the two-layer model, that `model` routes live while `effort` is advisory today, and the "add a binding subsection" path to extend routing to another agent.
- [x] **AC-9** For each touched companion skill (`sw-plan`, `sw-run`, `sw-review`, including `sw-plan`'s sibling prompt files), the three copies stay in sync: canonical `.agents/skills/sw-<name>/` equals the `skills/sw/scaffold/skills/sw-<name>/` copy byte-for-byte, and equals the `plugins/sw/skills/<name>/` copy except the line-2 `name:` — confirmed by `diff`.
