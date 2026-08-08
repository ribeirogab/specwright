---
feature: command-surface-and-artifacts
---
# Command Surface and Artifacts — Design

**Proposal:** see the sibling `proposal.md` for the *why*, the acceptance criteria, and the change `status:`.

## Architecture

Four independent edits to one plugin, sequenced so the widest one runs last.

**Removal before rename.** `sw:pr` and `.specwright/conventions/` are deletions
with a bounded blast radius; the artifact rename touches every skill, template,
fixture, test, and root document. Running the deletions first means the rename
sweeps their output too, in one pass, instead of the rename being re-applied to
files the deletions later rewrite.

**The safety gate relocates rather than disappears.** `sw:pr` was the sole holder
of the "never from the default branch" check, and it ran *after* every commit was
already written. Moving it into `sw:implement`, immediately before the first
commit, converts a late assertion into an actual gate.

**Conventions become a contract, not a directory.** `sw:review` currently gets its
project-specific standard from a specwright-owned folder. It instead reads a
`## Conventions` section in the canonical AGENTS instructions and follows the
links it lists. specwright stops owning a location and owns a section name —
policy separated from mechanism. `docs/conventions/` is this repository's own
choice of where those files live, not a specwright convention.

**`scope:` becomes load-bearing by validator enforcement.** The field alone
cannot enforce anything; the check that `scope != low` implies a sibling
`design.md` is what turns a recorded value into a decision with a consequence.
That is a new validator check — number 7 — so the existing six keep their
numbers and their test assertions.

**`sw:archive` is post-ladder, not a fifth step.** It runs after the maintainer
merges, which `sw:ship` cannot observe because it stops at `lgtm`. It uses
`git merge-base --is-ancestor` so it stays host-agnostic.

## File Structure

| Path | Responsibility |
|---|---|
| `plugins/sw/skills/pr/` | deleted |
| `plugins/sw/commands/pr.md` | deleted |
| `plugins/sw/skills/archive/SKILL.md` | new — post-merge promotion of a change to archived |
| `plugins/sw/commands/archive.md` | new — thin redirect |
| `plugins/sw/skills/change/` | renamed to `skills/propose/`; body updated for the new artifact names |
| `plugins/sw/commands/change.md` | renamed to `commands/propose.md` |
| `plugins/sw/templates/change.md` | renamed to `templates/proposal.md` |
| `plugins/sw/templates/plan.md` | split into `templates/design.md` and `templates/tasks.md` |
| `plugins/sw/skills/plan/SKILL.md` | writes two files; owns the `scope:` decision |
| `plugins/sw/skills/implement/SKILL.md` | gains the branch gate; reads the three artifacts; points at `sw:review` |
| `plugins/sw/skills/ship/SKILL.md` | four steps; promise changed to a reviewed branch |
| `plugins/sw/skills/review/SKILL.md` | conventions come from the AGENTS `## Conventions` section |
| `plugins/sw/skills/init/SKILL.md` | no conventions directory; next step is `sw:propose` |
| `plugins/sw/skills/delivery/SKILL.md` | artifact names; conventions source |
| `plugins/sw/agents/*.md`, `templates/codex-agents/*.toml` | artifact names; conventions source |
| `plugins/sw/scripts/validate-change.sh` | reads `proposal.md` + `tasks.md`; new check 7 |
| `plugins/sw/scripts/sw_init.py` | stops creating `conventions/`; section text updated |
| `plugins/sw/scripts/fixtures/*/` | `change.md` → `proposal.md`, `plan.md` → `tasks.md` |
| `plugins/sw/references/*.md` | vault shape, validator checks, package surfaces |
| `tests/validate-change/run.sh`, `tests/install/run.sh`, `tests/release/run.sh` | artifact names, skill inventory, vault assertions |
| `docs/conventions/*.md` | new home for the two repository conventions |
| `README.md`, `AGENTS.md` | ladder, command table, artifact list, conventions section |

`CLAUDE.md` is a symlink to `AGENTS.md` and needs no edit.

## Phase Ordering

1. Remove `sw:pr` and relocate the branch gate (T1–T2).
2. Remove `.specwright/conventions/` (T3–T4).
3. Add `sw:archive` (T5).
4. Rename and split the artifacts, activate `scope:` (T6–T10).
5. Documentation sweep and full gate (T11–T12).

## Constraints

- Both hosts must keep exactly **eight** skills: `tests/release/run.sh` asserts
  the count and `tests/install/run.sh` asserts the command/skill pairing. Removing
  `pr` and adding `archive` keeps the count intact — no test constant changes.
- Every `SKILL.md` needs `name:` matching its directory and a `description:` that
  states when the skill is invoked, never instructing autonomous dispatch.
- Committed artifacts stay in English.
- No AI attribution in any commit or PR body.
