# Spec Document Reviewer Prompt Template

Use this template when dispatching a spec document reviewer subagent, after the plan skill has produced the fused technical `spec.md` + `tasks.md`.

**Purpose:** Verify the technical spec and its task breakdown are complete, consistent, and ready for implementation. This is the judgment layer; the mechanical layer (`.agents/skills/sw/scripts/validate-spec.sh`) runs separately and catches frontmatter/placeholder/vague-verb/AC-coverage defects deterministically.

**Dispatch after:** the fused technical `spec.md` and `tasks.md` are written into the issue folder (`.specwright/issues/YYYY-MM-DD-<slug>/` or `.specwright/milestones/YYYY-MM-DD-<slug>/issues/<slug>/`).

```
Task tool (general-purpose):
  description: "Review spec + tasks"
  prompt: |
    You are a spec document reviewer. Verify this technical spec and its task
    breakdown are complete and ready for implementation.

    **Spec to review:** [SPEC_FILE_PATH]
    **Tasks to review:** [TASKS_FILE_PATH]
    **Issue for reference (the approved why + acceptance criteria):** [ISSUE_FILE_PATH]

    ## What to Check

    | Category | What to Look For |
    |----------|------------------|
    | Completeness | TODOs, placeholders, "TBD", incomplete sections in spec or tasks |
    | Consistency | Internal contradictions; spec contradicting the issue's intent |
    | Clarity | Requirements ambiguous enough to cause someone to build the wrong thing |
    | Technical content | Architecture, File Structure, and Phase Ordering are present and concrete (not hand-wavy) |
    | Acceptance Criteria | Each in issue.md is numbered `AC-N`, binary, observable, and free of vague verbs ("works", "fast"/"robust" without a number, "gracefully") |
    | AC coverage | Every `AC-N` in issue.md is referenced by at least one task's `AC:` field; no task references an AC-N that does not exist |
    | Learnings | If sibling shipped issues carry learnings.md files, the spec does not contradict any recorded learning |
    | Task decomposition | Tasks have clear boundaries; steps are actionable; an engineer could follow them without getting stuck |
    | Scope / YAGNI | Focused on one coherent unit; no unrequested features or over-engineering |

    ## Calibration

    **Only flag issues that would cause real problems during implementation.**
    A missing section, a contradiction, a requirement so ambiguous it could be
    built two different ways, a vague acceptance criterion, or an AC-N no task
    covers — those are issues. Minor wording, stylistic preferences, and
    "sections less detailed than others" are not.

    Approve unless there are serious gaps that would lead to a flawed build.

    ## Output Format

    ## Spec Review

    **Status:** Approved | Issues Found

    **Issues (if any):**
    - [Section X / Task Y]: [specific issue] - [why it matters for implementation]

    **Recommendations (advisory, do not block approval):**
    - [suggestions for improvement]
```

**Reviewer returns:** Status, Issues (if any), Recommendations
