---
description: External evaluator that reviews a spec against the project conventions and its design, flagging vagueness, scope creep, and unresolved questions
argument-hint: <optional: path to spec folder, or current spec if omitted>
---

# Review Spec — External Evaluator Pass

Run an **independent** review of a spec written by the agent. It runs inside `/sw:writing-plans` after the technical `spec.md` is written — the external pass between the author's own self-review and implementation. The point is to catch the things the author rationalized past.

**Announce at start:** "Reviewing spec against conventions and design..."

## Inputs

1. **Target spec folder.** If `$ARGUMENTS` is a path under `.specwright/specs/`, read that folder. Otherwise scan `.specwright/specs/` for the most recent `YYYY-MM-DD-*` folder modified and confirm with the user before proceeding. Read both the technical `spec.md` and its companion `design.md`.
2. **Project conventions.** Skim `.specwright/conventions/` — the project-specific standards this spec must respect and must not duplicate or contradict.

## Step 0 — mechanical pre-check (run first)

Before the prose review, run the mechanical validator over the spec folder. It ships with the `sw` skill:

```bash
.agents/skills/sw/scripts/validate-spec.sh <spec-folder>
# (in the specwright dev repo the script is at skills/sw/scripts/validate-spec.sh)
```

It deterministically checks required frontmatter keys + the `scope` enum, surviving `{{placeholder}}`s, vague-verb acceptance criteria, and `AC-N` task coverage. A **non-zero exit is a blocking FAIL** — record it as the `0. Mechanical validator` row, and the verdict is `Block` regardless of the prose findings. Still complete the prose review below so the author fixes everything in one pass. If the script is absent (older install), note `validator missing` and proceed with the prose review only.

## What to evaluate

For the target `spec.md`, return a finding for each of the categories below. Each finding is one of `PASS`, `WARN`, or `FAIL`. Reserve `FAIL` for issues that should block handoff.

### 1. Conventions compliance

Read the project conventions under `.specwright/conventions/`. For each, ask: does this spec violate, weaken, or sidestep it? Quote the convention line and the spec line when reporting.

`FAIL` if a convention is violated. `WARN` if one is sidestepped without acknowledgement. `PASS` otherwise (including when there are no conventions that apply).

### 2. Acceptance Criteria — concrete and testable

Locate the `## Acceptance Criteria` section. Evaluate every bullet:

- Is it **binary** (yes/no, not "good enough")?
- Is it **observable** by someone other than the implementer?
- Could it be verified in **under a minute** with a fixture or a curl?
- Does it avoid **vague verbs**: "works", "handles gracefully", "is robust", "is fast" (without a number), "is simple"?
- Is each criterion **numbered** `AC-1`, `AC-2`, … (the traceability handle tasks and code-review reference)?

`FAIL` if the section is missing, empty, contains only `{{placeholder}}` text, or every bullet is vague. `WARN` if some bullets are vague, unnumbered, but at least one is testable. `PASS` if all bullets are concrete and numbered.

### 3. Required sections present and non-empty

The technical `spec.md` defines: Architecture, File Structure, Phase Ordering, Constraints, User Stories / Scenarios, Acceptance Criteria, Risks and Mitigations, Open Questions. Its companion `design.md` defines: Purpose, Motivation, Definitions, Non-Goals. Check **both** files. For each heading:

- `FAIL` if the heading is missing (or `design.md` itself is absent).
- `WARN` if the section exists but is empty or only `{{placeholder}}`.
- `PASS` if there is real content, or the author wrote `N/A — <reason>`.

`Open Questions` is allowed to be empty if and only if the author wrote `None.`; silence is not the same as resolution.

### 4. Scope discipline

Compare `design.md`'s **Purpose** and **Non-Goals** with the spec's **Acceptance Criteria**. Look for:

- Acceptance criteria that go beyond the stated purpose (scope creep).
- Non-goals (in `design.md`) that are actually implied by the acceptance criteria (lying to ourselves).
- A purpose so broad that no spec could close it (rewrite needed).

`FAIL` only on the third case. `WARN` on the first two.

### 5. Open Questions left unresolved

Every `[NEEDS CLARIFICATION: ...]` marker is a blocker. Same for any acceptance criterion that references an open question.

`FAIL` if any clarification marker survived. `PASS` if `Open Questions` lists `None.` or every question has a documented resolution.

## Output format

```
## Spec Review — <feature-slug>

| # | Category                                | Status | Note |
|---|-----------------------------------------|--------|------|
| 0 | Mechanical validator                    | PASS   | validate-spec.sh exit 0 |
| 1 | Conventions compliance                  | PASS   |      |
| 2 | Acceptance Criteria — concrete/testable | FAIL   | Bullet 3: "handles errors gracefully" — no observable check |
| 3 | Required sections present               | WARN   | Non-Goals is empty |
| 4 | Scope discipline                        | PASS   |      |
| 5 | Open Questions resolved                 | FAIL   | Line 47: [NEEDS CLARIFICATION: which auth provider?] |

### Verdict

**Block** — 2 FAILs must be addressed before implementation.

### Suggested edits

1. Rewrite Acceptance Criteria bullet 3:
   - Was: "Handles errors gracefully"
   - Suggested: "On a 5xx upstream response, the endpoint returns 502 with body `{\"code\":\"UPSTREAM_ERROR\"}` and emits a `upstream_error` log line"
2. Resolve [NEEDS CLARIFICATION: which auth provider?] before continuing — propose a concrete default consistent with the project conventions.
```

## Verdict rules

- **A non-zero validator exit (Step 0)** → `Block`, always — the spec is structurally invalid.
- **Any FAIL** → `Block`. Do not proceed to implementation; fix the spec first.
- **Only WARNs** → `Approve with notes`. May proceed but should address WARNs in the next pass.
- **All PASS** → `Approved`. Proceed to implementation.

## Key rule

This command is a **second opinion**, not a rubber stamp. If the spec author already self-reviewed and approved, that is exactly when the external pass is most valuable — the failure mode is the author rationalizing past their own gaps. Be specific, quote line numbers, and never say "looks good" without checking against the conventions and the design.
