---
feature: refine-spec-flow
spec: "[[spec-refine-spec-flow]]"
created: 2026-06-14
---
# Refine Spec Flow — Plan

**For this spec:** `[[spec-refine-spec-flow]]`

> **For agentic workers:** implement task-by-task from `tasks-refine-spec-flow.md`. No test runner — verification is grep/`wc`/`uv run --with pyyaml … quick_validate.py`.

**Goal:** Rewrite the spec-driven flow's human-interaction model — design approval is the only human review; the agent self-reviews in both modes; post-design asks a single 3-question batch (branch + mode + compact, no PR question, both modes); a compact run (either mode) emits a `txt` handoff after the artifacts are written; the mode decides only delivery (reviewed asks before opening the PR).

**Architecture:** Markdown-only edits across `AGENTS.md`, the three `memex-brainstorming` copies, the scaffold template, the `/memex:spec` command, and the README. The brainstorming skill is the canonical driver; edit `.agents` then regenerate plugin + scaffold copies. No code, no new frontmatter.

**Tech Stack:** markdown, bash, git, `uv` (PyYAML validators).

---

## Approach

The brainstorming `SKILL.md` is the source of truth for the interactive flow; `AGENTS.md`'s `### Spec flow` is the contract; the template mirrors it. Edit the canonical `.agents/skills/memex-brainstorming/SKILL.md`, regenerate the plugin (`sed` name) and scaffold (`cp`) copies, then align `AGENTS.md`, the template, the `/memex:spec` command, and the README. Verify 3-copy body-identity, the 8-step `### Spec flow`, ≤80 lines, and validators. Each phase ends with a Conventional-Commits commit, no AI attribution.

## File Structure

**Modified:**
- `AGENTS.md` — `### Spec flow` 7→8 steps (§B).
- `.agents/skills/memex-brainstorming/SKILL.md` (canonical) → regenerate `plugins/memex/skills/brainstorming/SKILL.md` + `skills/memex/scaffold/skills/memex-brainstorming/SKILL.md`.
- `skills/memex/references/agents-md-template.md` — Template block `### Spec flow` + the "7 steps" filling-rules sentence.
- `plugins/memex/commands/spec.md` — flow prose (no user-review gate; both-mode self-review; compact handoff).
- `README.md` — "What you get" flow bullet.

**Excluded:** `tmp/` (gitignored E2E sandbox).

## Phases → spec mapping

| Phase | Spec § | Artifact |
|---|---|---|
| 1 brainstorming skill | §A, §C, §D | 3 skill copies |
| 2 AGENTS.md flow | §B | AGENTS.md |
| 3 template + command + README | §E | references + commands/spec.md + README |
| 4 quality gate | AC | validators + grep/wc |
| 5 deliver | flow 6-8 | PR + code-review to lgtm |

## Self-review (plan vs spec)

- Every spec §A–§E maps to a phase. The 8-step flow (§B), both-mode self-review (§C), and compact handoff (§D) all land in Phase 1 (skill) + Phase 2 (AGENTS). Mirror/command/README in Phase 3. ACs verified in Phase 4.
- No new frontmatter; no header changes; ≤80-line cap checked in Phase 2.
