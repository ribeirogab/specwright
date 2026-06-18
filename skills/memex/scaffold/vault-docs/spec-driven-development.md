---
tags:
  - guide
created: 2026-06-14
---
# Spec-Driven Development in memex

The guide to *how* memex turns an idea into a verified, shipped change with durable memory — the mental model, the artifacts, the sizing and delegation tables, the gates.

> **This doc is the map, not the contract.** It explains the *why* and how the pieces fit. The authoritative *mechanics* live elsewhere and win on any conflict: the step contract is `AGENTS.md` (`### Spec flow`), each step's exact behavior is its skill under `.agents/skills/memex-*/`, and the non-negotiables are `.memex/constitution.md` + `.memex/rules.md`. When this guide and one of those disagree, the other is right — fix this guide.

## The mental model

Every non-trivial change runs through one pipeline that converts **intent → a verified, shipped change**, while the **vault** (`.memex/`) accumulates durable memory so the next change starts smarter.

```
brainstorm → design → spec + tasks → implement → quality gate → PR → review-to-lgtm → shipped
```

Two ideas hold it together:

- **Separate the *why* from the *how*.** The non-technical rationale (purpose, motivation, definitions, non-goals) is captured once as `design.md`; the technical plan (architecture, files, phases, acceptance criteria) is `spec.md`. They never duplicate each other.
- **Make "did we deliver?" auditable, not a judgment call.** Acceptance criteria carry stable IDs (`AC-N`) that thread spec → tasks → review, so completion is a checklist a reviewer can verify.

## The entry gate — do I even spec?

Before any work, ask: **"Can I describe the complete solution in one sentence?"**

| Answer | Action |
|---|---|
| **Yes** | Implement directly — no spec. |
| **Almost** (1-2 open decisions) | Ask the user: spec or go direct? |
| **No** | Enter the spec flow. |

If the user is only asking, investigating, or exploring — just answer. The spec flow is for *building*.

## The artifact model

A spec lives in a dated folder `.memex/specs/YYYY-MM-DD-<slug>/` holding three files with **bare** names (the folder is the discriminator; cross-links are path-qualified, e.g. `[[YYYY-MM-DD-<slug>/spec|spec]]`).

| Artifact | Nature | Written by | Holds |
|---|---|---|---|
| `design.md` | non-technical (the *why*) | `memex-brainstorming` | Purpose, Motivation, Definitions, Non-Goals — a durable write-up of the **already-approved** design. Not a second review gate. |
| `spec.md` | technical (the *how*) | `memex-writing-plans` | `scope` frontmatter, Architecture, File Structure, Phase Ordering, **Acceptance Criteria (`AC-N`)**, Risks. The fused spec+plan. |
| `tasks.md` | execution | `memex-writing-plans` | Bite-sized tasks; each names the **`AC:`** it satisfies and a **`Delegable:`** note. |

> There is no `plan.md` — the old plan was fused into `spec.md`. Frozen specs from before this change keep their ship-time shape; only the template and new specs use the model above.

## The 9-step flow

The authoritative step list is `AGENTS.md` → `### Spec flow`. In brief:

| # | Step | Owned by |
|---|---|---|
| 1 | Brainstorm → write `design.md`; post-design batch (branch + mode + worktree + handoff) | `memex-brainstorming` |
| 2 | Create the branch (or a worktree under `.memex/worktrees/<slug>`, default yes unless already inside a linked worktree) — **one branch + one PR per spec** | — |
| 3 | Write the fused `spec.md` + `tasks.md`; self-review the spec | `memex-writing-plans` |
| 4 | Handoff (if chosen) — print a `txt` prompt and stop | — |
| 5 | Implement | (you / subagents) |
| 6 | Quality gate (test/lint/typecheck/build + **test integrity**) | — |
| 7 | Reflect → write learnings to `.memex/learnings/` | — |
| 8 | Deliver — open the PR (`/memex:new-pr`) + run `memex:code-review` to `lgtm` | `memex-new-pr`, `memex-code-review` |
| 9 | **Ship** — `lgtm` ⇒ set `status: shipped` + move to the Shipped index | — |

**Design approval (step 1) is the only human review.** There is no human spec-review gate.

## Scope sizing

`spec.md` frontmatter carries `scope: low | medium | high | complex`.

> **Status today: recorded-only.** `scope` is set honestly by the spec author and documents the size of the work. It does **not** yet gate which artifacts are written or skip any step — it is reserved for a future "quick-mode" that will let small changes take a lighter path. Set it; nothing branches on it yet.

| `scope` | Rough size (author's judgment) |
|---|---|
| `low` | A focused change, one area, few files. |
| `medium` | Several files / a couple of phases; still one coherent unit. |
| `high` | Many files, multiple phases, cross-cutting. |
| `complex` | Touches several subsystems or carries notable risk/unknowns. |

## Subagent delegation

memex delegates work to isolated subagents at three points. The principle: a subagent gets a **bounded task + the isolated context it needs**, finds or does exactly that, and reports back — the main agent stays the integrator.

| Where | What gets delegated | Source of truth |
|---|---|---|
| **Tasks** (`tasks.md`) | Each task's `Delegable:` field marks whether it suits an isolated subagent, plus the one-line context that subagent would receive. | the `tasks.md` template |
| **Implementation** | `memex-writing-plans` decides subagent-driven (a fresh subagent per task, large plans) vs inline (small plans) execution. | `memex-writing-plans/SKILL.md` |
| **Code-review** | Several specialized find-only subagents review the branch in parallel; the main agent merges them and they must **all** reach `lgtm`. | `memex-code-review/SKILL.md` |

The exact roles and lane boundaries of the code-review subagents live in `memex-code-review/SKILL.md` — that skill is the single source of truth for them.

## Reviews and gates

| Gate | When | What it checks | Home |
|---|---|---|---|
| **Design approval** | after brainstorming | the human approves the design — the *only* human review | — |
| **Spec self-review** | after `spec.md` + `tasks.md` exist | spec-document-reviewer subagent + `/memex:review-spec` + the mechanical `validate-spec.sh` | `memex-writing-plans`, `/memex:review-spec` |
| **Mechanical validator** | feedforward, before review | required frontmatter + `scope` enum, surviving `{{placeholder}}`s, vague-verb ACs, `AC-N` → task coverage | `.memex/scripts/validate-spec.sh` |
| **Quality gate** | after implement | the touched area's test/lint/typecheck/build pass; **test integrity** — the test count must not silently drop and assertions must not be weakened/skipped/deleted to go green | `AGENTS.md` step 6 |
| **Code-review** | delivery | several specialized subagents (project law, spec-conformance against `AC-N`, documentation consistency) — all must reach `lgtm` | `memex-code-review` |

## Modes — autonomous vs reviewed

Recorded in `spec.md` frontmatter as `mode:`, chosen in the post-design batch. The recorded `mode:` is standing consent to commit, push the **feature branch**, and open that spec's PR (never `main`).

| `mode` | Delivery behavior |
|---|---|
| `autonomous` | Runs all the way to delivery alone: implement → quality gate → reflect → open the PR → `memex:code-review` to `lgtm`, no further prompts. |
| `reviewed` | Identical up to reflect; then **asks** "open the PR and run code-review?" before delivering. |

Both modes self-review the spec and may use the **handoff** — once `design`/`spec`/`tasks` exist, the agent can print a `txt` summary and stop so you `/compact` (or open a new chat) and resume implementing with a clean context.

## Acceptance-criteria traceability

The spine that makes delivery auditable:

```
spec.md  AC-1, AC-2, …   →   tasks.md  (each task: AC: AC-1)   →   code-review  (walks every AC-N)
```

`validate-spec.sh` fails if any `AC-N` defined in `spec.md` is referenced by no task; the code-review spec-conformance pass flags any `AC-N` with no satisfying change in the diff as a blocker. So "did we do everything?" becomes a checklist, not a guess.

## Shipping a spec

**PR opened + code-review `lgtm` = shipped.** On `lgtm`, the spec's frontmatter is set to `status: shipped` with a `shipped:` date and its entry moves to **Shipped** in `.memex/_index/specs.md` — done on the spec's own branch, as part of its PR, not after merge. Shipped specs are never deleted; they stay in `.memex/specs/` as historical record.

## The vault is the brain

The flow feeds a living knowledge base under `.memex/`:

- `learnings/` — atomic notes on non-obvious discoveries (gotchas, constraints, surprising behavior), wikilinked to their spec. Written at the reflect step.
- `conventions/` — deliberate code-style decisions.
- `constitution.md` / `rules.md` — the non-negotiable law and operational rules.
- Tooling: `/memex:recall` (search the vault), `/memex:link` (find missing cross-links), `/memex:sweep` (garbage-collect orphans, broken links, isolated specs).

Stuck on a change? Search the vault **before** guessing — the answer is often already a learning.

## Where the authority lives

| You want… | Read |
|---|---|
| the non-negotiable scope/architecture/security law | `.memex/constitution.md` |
| philosophy, git & delivery, code rules | `.memex/rules.md` |
| the exact step contract (the 9 steps) | `AGENTS.md` → `### Spec flow` |
| how a single step behaves | that step's `.agents/skills/memex-*/SKILL.md` |
| how PRs are opened | `memex-new-pr` |
| how the branch is reviewed | `memex-code-review` |
| the structural spec checks | `.memex/scripts/validate-spec.sh` |
| the install/audit checks | `skills/memex/references/validation.md` |
