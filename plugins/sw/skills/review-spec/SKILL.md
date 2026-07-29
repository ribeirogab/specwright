---
name: review-spec
user-invocable: false
description: "Review an issue plan against project conventions and the approved issue, flagging vagueness, scope creep, and unresolved questions."
---

# Review Spec — External Evaluator Pass

Run an **independent** review of an issue's technical plan written by the agent. It runs inside the `sw:plan` workflow after `spec.md` + `tasks.md` are written — the external pass between the author's own self-review and implementation. The point is to catch the things the author rationalized past.

**Announce at start:** "Reviewing the plan against conventions and the issue..."

## Resolve the validator

Resolve `SW_PLUGIN_ROOT` before the mechanical pre-check:

1. use `PLUGIN_ROOT` when it contains `.codex-plugin/plugin.json`;
2. otherwise use `CLAUDE_PLUGIN_ROOT` when it contains
   `.claude-plugin/plugin.json`;
3. otherwise derive the root from this loaded `skills/review-spec/SKILL.md` real
   path (two parents above the `skills/review-spec/` directory).

Require `scripts/validate-spec.sh` beneath that root. A missing resource is
`validator missing`; never fall back to a target-repository-relative
`plugins/sw/` path.

## Inputs

1. **Target issue folder.** If `$ARGUMENTS` is a path under `.specwright/issues/` or `.specwright/milestones/*/issues/`, read that folder. Otherwise scan both trees for the most recently modified issue folder and confirm with the user before proceeding. Read `issue.md` (the approved why + acceptance criteria), `spec.md`, and `tasks.md`.
2. **Project conventions.** Skim `.specwright/conventions/` — the project-specific standards this plan must respect and must not duplicate or contradict.

## Step 0 — mechanical pre-check (run first)

Before the prose review, run the mechanical validator over the issue folder. It ships with the `sw` skill:

```bash
"$SW_PLUGIN_ROOT/scripts/validate-spec.sh" <issue-folder>
```

It deterministically checks `issue.md` frontmatter (`feature`/`created`/`status` + the status enum), `spec.md` frontmatter (`feature`/`created`/`scope` + the scope enum), surviving double-brace placeholders, vague-verb acceptance criteria, and `AC-N` task coverage. A **non-zero exit is a blocking FAIL** — record it as the `0. Mechanical validator` row, and the verdict is `Block` regardless of the prose findings. Still complete the prose review below so the author fixes everything in one pass. If the script is absent (older install), note `validator missing` and proceed with the prose review only.

## What to evaluate

Return a finding for each category below — `PASS`, `WARN`, or `FAIL`. Reserve `FAIL` for issues that should block implementation.

### 1. Conventions compliance

Read the project conventions under `.specwright/conventions/`. For each, ask: does this plan violate, weaken, or sidestep it? Quote the convention line and the plan line when reporting.

`FAIL` if a convention is violated. `WARN` if one is sidestepped without acknowledgement. `PASS` otherwise (including when there are no conventions that apply).

### 2. Acceptance Criteria — concrete and testable

Locate the `## Acceptance Criteria` section **in `issue.md`**. Evaluate every bullet:

- Is it **binary** (yes/no, not "good enough")?
- Is it **observable** by someone other than the implementer?
- Could it be verified in **under a minute** with a fixture or a curl?
- Does it avoid **vague verbs**: "works", "handles gracefully", "is robust", "is fast" (without a number), "is simple"?
- Is each criterion **numbered** `AC-1`, `AC-2`, … (the traceability handle tasks and `sw:review` reference)?

`FAIL` if the section is missing, empty, contains only placeholder text, or every bullet is vague. `WARN` if some bullets are vague or unnumbered but at least one is testable. `PASS` if all bullets are concrete and numbered.

### 3. Required sections present and non-empty

`issue.md` defines: Purpose, Motivation, Non-Goals, Acceptance Criteria. `spec.md` defines: Architecture, File Structure, Phase Ordering, Constraints, User Stories / Scenarios, Acceptance Criteria (a pointer to `issue.md`, never a duplicate), Risks and Mitigations, Open Questions. Check **both** files. For each heading:

- `FAIL` if the heading is missing (or `issue.md` itself is absent).
- `WARN` if the section exists but is empty or only placeholder text.
- `PASS` if there is real content, or the author wrote `N/A — <reason>`.

`Open Questions` is allowed to be empty if and only if the author wrote `None.`; silence is not the same as resolution.

### 4. Scope discipline

Compare `issue.md`'s **Purpose** and **Non-Goals** with its **Acceptance Criteria** and the spec's plan. Look for:

- Acceptance criteria or tasks that go beyond the stated purpose (scope creep).
- Non-goals that are actually implied by the acceptance criteria (lying to ourselves).
- A purpose so broad that no single issue could close it (it should have been a milestone).

`FAIL` only on the third case. `WARN` on the first two.

### 5. Open Questions left unresolved

Every `[NEEDS CLARIFICATION: ...]` marker is a blocker. Same for any acceptance criterion that references an open question.

`FAIL` if any clarification marker survived. `PASS` if `Open Questions` lists `None.` or every question has a documented resolution.

### 6. Learnings respected (milestone issues)

When the issue belongs to a milestone and sibling shipped issues carry `learnings.md` files, check the spec against each recorded learning.

`FAIL` if the plan contradicts a recorded learning. `PASS` otherwise (including standalone issues and milestones with no learnings yet).

## Output format

```
## Spec Review — <issue-slug>

| # | Category                                | Status | Note |
|---|-----------------------------------------|--------|------|
| 0 | Mechanical validator                    | PASS   | validate-spec.sh exit 0 |
| 1 | Conventions compliance                  | PASS   |      |
| 2 | Acceptance Criteria — concrete/testable | FAIL   | AC-3: "handles errors gracefully" — no observable check |
| 3 | Required sections present               | WARN   | Non-Goals is empty |
| 4 | Scope discipline                        | PASS   |      |
| 5 | Open Questions resolved                 | FAIL   | Line 47: [NEEDS CLARIFICATION: which auth provider?] |
| 6 | Learnings respected                     | PASS   |      |

### Verdict

**Block** — 2 FAILs must be addressed before implementation.

### Suggested edits

1. Rewrite acceptance criterion AC-3 in issue.md:
   - Was: "Handles errors gracefully"
   - Suggested: "On a 5xx upstream response, the endpoint returns 502 with body `{\"code\":\"UPSTREAM_ERROR\"}` and emits a `upstream_error` log line"
2. Resolve [NEEDS CLARIFICATION: which auth provider?] before continuing — propose a concrete default consistent with the project conventions.
```

## Verdict rules

- **A non-zero validator exit (Step 0)** → `Block`, always — the folder is structurally invalid.
- **Any FAIL** → `Block`. Do not proceed to implementation; fix first.
- **Only WARNs** → `Approve with notes`. May proceed but should address WARNs in the next pass.
- **All PASS** → `Approved`. Proceed to implementation.

## Key rule

This command is a **second opinion**, not a rubber stamp. If the author already self-reviewed and approved, that is exactly when the external pass is most valuable — the failure mode is the author rationalizing past their own gaps. Be specific, quote line numbers, and never say "looks good" without checking against the conventions and the issue.
