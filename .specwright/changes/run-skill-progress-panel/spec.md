---
feature: run-skill-progress-panel
created: 2026-07-02
scope: low
branch: feat/run-skill-progress-panel
worktree: .specwright/worktrees/run-skill-progress-panel
milestone: .specwright/milestones/2026-07-02-specwright-fixes
---
# Run Skill Progress Panel — Spec

**Issue:** see the sibling `issue.md` (the *why*, the acceptance criteria, and the issue `status:`)
**Scope:** Add one "Progress reporting" section to the run skill (all three shipped copies) transcribing the approved visual-progress-panel standard plus the compact-line and degradation rules.

> **Note on `scope:` frontmatter** — recorded only; nothing branches on it today. `low`: a single documentation section added to one skill, propagated by byte-copy to two sibling copies.
>
> **Note on `worktree:` frontmatter** — this issue's worktree, recorded only.
>
> **Note on `milestone:` frontmatter** — the `specwright-fixes` milestone folder.

This is the **technical** spec — the *how*. The non-technical *why*, the acceptance criteria, and the status live in `issue.md`.

## Architecture

The run skill (`sw-run`) is a markdown SKILL.md with no code. Its behavior is its prose: the orchestrator reads the skill and acts on what it says. This issue **adds one section** — "Progress reporting" — that transcribes the standard Gabriel approved during the e2e-validation conduction (recorded in that milestone board's Conduction notes, dossier entry 8.1, and Gabriel's memory standard). It designs nothing new: the panel structure, colors, chip widths, and the compact-line format are copied from the approved reference, not invented here.

**Where the section goes.** The skill's current section order is: intro → Locate the milestone → The loop → Circuit breakers → Closeout → Degradation → Boundaries. Progress reporting is a **reporting concern that applies across the whole loop** (the conductor reports at round transitions, which happen inside "The loop", and on any maintainer request, which can happen at any time). It reads most naturally as its own top-level section placed **after "The loop" and before "Circuit breakers"** — the conductor has just learned how to dispatch/track/re-evaluate, and now learns how to surface that state. It must precede "Degradation" so the reader meets the panel before the degradation rule that references it.

**Tool-agnostic framing (the issue's Non-Goal).** The section describes *what to render and when*, not *which renderer to call*. It names a visual rendering capability generically and gives the reference structure as the contract; a conductor with a visual widget renders the panel, a conductor without one emits the same content as a text table (AC-4). The memory standard names the visualize `show_widget` as the reference renderer used when Gabriel first approved it — the section may mention it as *the reference/example renderer*, but the binding contract is the structure and the compact line, never a specific tool call. This keeps the skill portable across agents (Claude Code, Codex, Cursor) that have different or no visual capabilities.

**The three copies.** `sw-run` ships in three byte-identical-from-line-3 copies. Per the run-skill-contract learnings the safe edit pattern is: edit the canonical `.agents/skills/sw-run/SKILL.md`, then rebuild each sibling as `head -2 <sibling>` + `tail -n +3 <canonical>`. This propagates the new section to all three and preserves each copy's line-2 `name:` divergence (`sw-run` for canonical + scaffold, `run` for the plugin). AC-5 verifies the result: the three differ only in the frontmatter `name:` line.

**The panel content — transcribed from the approved standard.** Top to bottom:

1. **KPI row** — four metric cards: overall weighted % (shipped issues + in-flight fraction), shipped count `N / total` (with the PR range), in-progress count (with which issue), findings-in-dossier count.
2. **Overall stacked progress bar** — three segments: shipped (green), in-flight (amber), queued (track color); caption `X shipped · Y rodando · Z na fila`.
3. **Per-issue row list, in board order** — each row: an 88px status-chip pill (`shipped` / `rodando` / `na fila`) + the issue name + a muted one-liner (test id, key result, PR#).
4. **Sub-milestone section(s)** below a hairline — same bar shape + a one-line status, when the milestone has sub-milestones.

The exact reference colors from the approved standard (green `#1D9E75` shipped, amber `#EF9F27` in-flight, chip backgrounds/text) are illustrative of the reference rendering; the skill records them as the reference palette so a future renderer reproduces the approved look, but the **contract** the ACs enforce is the *structure* (which elements, in which order, carrying which metrics), not a hex value.

**The two triggers (AC-2).** Render the panel (a) on any progress question from the maintainer, and (b) at round transitions (the loop's re-evaluate step — a round just closed and the next is about to open). This matches "periodically during long conductions and whenever the user asks" from the standard.

**The compact line (AC-3).** *Every* text status update during conduction ends with a one-line summary carrying: overall %, shipped `X of N`, the currently running issue(s), and the queued count. The reference format is `Progresso: ~NN% — X/N shipped · <current> rodando (~NN%) · Y na fila`. The skill spells out the field format and says the line's **language follows the conversation** (the reference is pt-BR because that conduction was pt-BR; an English conduction writes the English equivalent) — the run-skill copies are English documents describing a language-following behavior, so the format is given as a labeled template, not a frozen pt-BR string.

**The degradation rule (AC-4).** A session with no visual rendering capability does not skip the update: it emits the panel content as a **text table** (the KPI numbers + the per-issue rows as table rows) plus the compact line. The existing "Degradation — no sub-agent support" section is about a different axis (serial vs parallel conduction); this rendering-degradation rule lives inside the new Progress reporting section, next to the panel it degrades.

## File Structure

- **Modify** `.agents/skills/sw-run/SKILL.md` — canonical copy; add the "Progress reporting" section after "The loop", before "Circuit breakers". This is the only hand-edited file.
- **Modify** `plugins/sw/skills/run/SKILL.md` — plugin copy; rebuilt as `head -2` (keeps `name: run`) + `tail -n +3` of the canonical.
- **Modify** `skills/sw/scaffold/skills/sw-run/SKILL.md` — scaffold copy; rebuilt as `head -2` (keeps `name: sw-run`) + `tail -n +3` of the canonical.

No other files. The board template, README, AGENTS templates, and other skills are out of scope (owned by siblings `docs-and-validator` and left untouched per the scope guard).

## Phase Ordering

Single phase. One section is authored on the canonical copy, then propagated to the two siblings by the byte-copy recipe, then verified. There are no sub-parts with dependencies.

## Constraints

- **Do not reword the approved ACs.** The `AC-N` in `issue.md` are the frozen contract. If planning had exposed a wrong criterion it would be a blocked report, not an edit — it did not; the ACs are implementable as written.
- **Copy-parity invariant (run-skill-contract learning).** The three copies must stay byte-identical from line 3; only line 2 (`name:`) may differ. Author on canonical, rebuild siblings with `head -2 <sibling>` + `tail -n +3 <canonical>`; verify with `diff`. The review skill's documentation lane (Subagent C) flags any drift beyond the `name:` line.
- **validate-spec.sh check 3 (brainstorm-and-templates learning).** A literal double-brace anywhere in `issue.md`/`spec.md`/`tasks.md`/`learnings.md` — even inside prose that merely *talks about* placeholders — trips check 3. Write "double-brace placeholder" in words; never type the delimiter.
- **Tool-agnostic (issue Non-Goal).** The section prescribes structure and content, not a rendering technology. Name any renderer only as a reference example, never as a required call.
- **AGENTS.md 80-line cap does not apply** — SKILL.md files are not `AGENTS.md`; the review skill's cap is on `AGENTS.md` only. The added section should still be economical (Rule of Economy).
- **English artifact.** The skill copies are English; the compact-line reference and its pt-BR example are documented as a language-following template, with the pt-BR string shown as the reference instance.
- **PyYAML for skill validators.** `quick_validate.py`/`package_skill.py` need pyyaml; run via `uv run --with pyyaml python skills/sw/scripts/quick_validate.py <skill>` or `/usr/bin/python3` (system python ships yaml). The repo PR template requires both for a modified skill.

## User Stories / Scenarios

1. **Long conduction, round closes.** The conductor finishes round 2 (three owners shipped), reaches the loop's re-evaluate step, and renders the progress panel: KPI cards update (overall % climbs, shipped count rises, in-flight drops), the stacked bar shifts green, the per-issue rows flip chips to `shipped`. It then continues to round 3.
2. **Maintainer asks "how's it going?" mid-round.** The conductor renders the panel on demand — same structure — reflecting the current shipped/running/queued split, without waiting for a round boundary.
3. **Every text update ends compact.** Any status line the conductor writes during conduction (a dispatch note, a blocker report, a round summary) ends with `Progresso: ~NN% — X/N shipped · <current> rodando (~NN%) · Y na fila` so the maintainer reads progress at a glance even without the full panel.
4. **Headless / no-visual session.** A conductor running in an agent with no visual widget emits the panel content as a text table plus the compact line — it never silently skips the progress update.

## Acceptance Criteria

The acceptance criteria live in the sibling `issue.md` — the `AC-N` IDs defined there are the contract `tasks.md` references and `/sw:review` walks. Do not duplicate them here; writing this spec exposed no missing or wrong criterion.

## Risks and Mitigations

| Risk | Mitigation |
|---|---|
| The new section drifts across the three copies (a hand-edit to one, not the others). | Author only on canonical; rebuild siblings with the `head -2`/`tail -n +3` recipe; verify with two `diff`s and `validate-spec.sh` AC-5 grep at runtime. |
| A literal double-brace typed while describing the panel/caption template trips `validate-spec.sh` check 3. | Write template placeholders in words ("overall percent", "issue name"); never type the double-brace delimiter in any tracked `.md`. |
| The section over-specifies a renderer, breaking the tool-agnostic Non-Goal. | Frame the renderer as a reference example only; the binding contract is structure + compact line + degradation, all renderer-free. |
| The compact-line reference (pt-BR) reads as a hardcoded string in an English document. | Present it as a labeled template with the "language follows the conversation" rule; show the pt-BR string as the reference instance, not the mandated output. |

## Open Questions

None.
