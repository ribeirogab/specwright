# Model routing

Route each **spawned** pipeline role to a model, without editing any skill. Two
layers keep this agent-agnostic:

1. **Roles → tier** — policy: how much capability each role needs, named by a
   vendor-neutral **tier**. No model names here.
2. **Bindings** — mechanism: per agent, which concrete model (and effort)
   realizes each tier. One subsection per agent; only `claude` ships filled.

## How a skill resolves a model

When a skill is about to spawn a role (issue owner, task worker, spec reviewer,
code reviewer), it resolves in three steps:

1. **role → tier** — look up the role in the *Roles → tier* table below (use the
   `default` row if the role is absent).
2. **tier → model** — look up that tier under the *Bindings* subsection for the
   agent you are (`### claude`, `### codex`, …).
3. **spawn with that model.**

**Live vs advisory.** The `model` column is applied on the spawn today. The
`effort` column is **advisory** — recorded intent, not yet injected, because the
current dispatch path has no per-spawn effort knob. It goes live automatically
when the runtime supports it; nothing here needs to change then.

**No binding = inherit.** If your agent has no subsection here, or a tier has no
row, or this file is absent, the role runs on the **inherited session model** —
routing is opt-in and additive, and a repo without this file behaves exactly as
before.

**The top-level session is never routed here.** The orchestrator (`/sw:run`) and
a standalone issue owner *are* the session you launched; nothing spawns them, so
no config can change their model — set it with your agent's model selector at
launch. Only spawned roles appear below.

## Roles → tier

| role          | tier     |
|---------------|----------|
| issue-owner   | deep     |
| worker        | fast     |
| spec-reviewer | deep     |
| code-review   | deep     |
| default       | balanced |

## Bindings

Model values may be an alias (`opus`, `sonnet`, `haiku`) or a full model ID where
your agent accepts one. Effort is one of `low | medium | high | xhigh | max`
(advisory today — see above).

### claude

| tier     | model  | effort |
|----------|--------|--------|
| deep     | opus   | xhigh  |
| balanced | sonnet | high   |
| fast     | sonnet | medium |
