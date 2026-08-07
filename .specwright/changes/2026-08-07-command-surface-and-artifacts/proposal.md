---
feature: command-surface-and-artifacts
created: 2026-08-07
status: shipped
shipped: 2026-08-07
delivery: null
---
# Command Surface and Artifacts — Proposal

> The ticket: the approved *why*, the acceptance criteria, and the change's status. `status:` lives **only** here. The technical *how* lives in the sibling `design.md`, the task checklist in `tasks.md`.

## Purpose

Narrow specwright to what it is uniquely good at — the change ladder and its
handoff-ready artifacts — by dropping the two responsibilities that belong to the
host repository, renaming the per-change artifacts to the names the wider
spec-driven-development ecosystem already uses, making the recorded-only `scope:`
field load-bearing, and adding the one workflow step that had no owner: what
happens after a branch merges.

## Motivation

Four defects, found by auditing the command surface against real use:

**`sw:pr` legislates a convention it does not own.** It hardcodes an English
Conventional-Commits title and an English body, while `sw:review` defers to the
project's own standards. A repository whose PR convention differs gets two
specwright skills contradicting each other. Opening a pull request is generic Git
plumbing; the only specwright-specific part — the runtime-verification record —
already lives in the ticket.

**`.specwright/conventions/` claims repository territory.** Project standards are
the repository's, not the vault's. The canonical `AGENTS.md` is where the
ecosystem already looks, and `sw:review` already reads it.

**The artifacts are named for this tool alone, and `scope:` does nothing.**
`change.md` and `plan.md` have no counterpart elsewhere, while `proposal.md`,
`design.md`, and `tasks.md` are the names OpenSpec, Kiro, and spec-kit converge
on. Splitting `plan.md` also separates the write-once architecture from the
constantly-mutating checklist, so an unauthorized architecture edit stops hiding
inside checkbox churn. And `scope:` is documented as "recorded only" — a declared
field that changes nothing is dead weight; it is exactly the switch that decides
whether a change needs a design document at all.

**Nothing owns the post-merge moment.** `sw:ship` ends at `lgtm`, before the
merge, because merging is the maintainer's call. Changes therefore accumulate in
`changes/` forever with no step that closes them out.

## Non-Goals

- **No living behavior spec.** A `behavior/` folder accumulating current-state
  prose was considered and rejected: every other vault artifact is historical and
  cannot be wrong, while a present-tense document is invalidated silently by any
  change that bypasses the ladder — which this repo's own instructions explicitly
  permit for trivial work.
- **No third planning artifact.** A per-change spec delta was rejected: the `AC-N`
  already state the behavior, and restating them is the amendment hazard the
  ticket template warns against.
- **No `sw:handoff`.** After the artifacts exist they *are* the handoff; before
  they exist, `sw:propose` harvests the conversation.
- **No backfill.** The 31 existing change folders keep `change.md` and `plan.md`,
  as in the July rename.
- **No merge, and no PR.** This change removes the ability to open one; it does
  not replace it with anything.

## Acceptance Criteria

Number each criterion sequentially as `AC-N` — the IDs are stable handles that
`tasks.md` references and that `sw:review` walks to prove every criterion was
delivered.

- [x] **AC-1** `plugins/sw/skills/pr/` and `plugins/sw/commands/pr.md` are absent, and `grep -rniE 'sw:pr\b|skills/pr/|(^|[^a-z-])pr\.md' plugins tests README.md AGENTS.md CLAUDE.md SECURITY.md CONTRIBUTING.md` exits 1.
- [x] **AC-2** `plugins/sw/skills/implement/SKILL.md` contains a `git branch --show-current` gate that stops the run before the first commit when the branch is `main` or `master`.
- [x] **AC-3** `.specwright/conventions/` is absent; `docs/conventions/` holds `skill-validation-requirements.md` and `verbatim-evidence.md`; `AGENTS.md` contains exactly one `## Conventions` heading that links both files; `grep -rn '\.specwright/conventions' plugins tests README.md AGENTS.md CLAUDE.md` exits 1.
- [x] **AC-4** `python3 plugins/sw/scripts/sw_init.py --project <empty-dir> --mode shared --format json` reports no action path containing `conventions`, and creates no `.specwright/conventions` directory.
- [x] **AC-5** `ls plugins/sw/templates/` prints exactly `codex-agents`, `delivery.md`, `design.md`, `proposal.md`, `tasks.md`.
- [x] **AC-6** `ls plugins/sw/commands/` and the directory names under `plugins/sw/skills/` both list exactly `archive`, `delivery`, `implement`, `init`, `plan`, `propose`, `review`, `ship` (commands with a `.md` suffix), and each command file references its own skill path.
- [x] **AC-7** `bash plugins/sw/scripts/validate-change.sh plugins/sw/scripts/fixtures/ready` prints a `PASS:` line and exits 0, where that fixture holds `proposal.md` and `tasks.md` and no `change.md` or `plan.md`.
- [x] **AC-8** `validate-change.sh` prints a `FAIL (check 7)` line naming `design.md` for a change folder whose `tasks.md` declares `scope: medium` with no sibling `design.md`, and exits 0 for the same folder once `scope:` is `low`.
- [x] **AC-9** `plugins/sw/skills/archive/SKILL.md` detects the merge with git alone: it contains `merge-base --is-ancestor`, and `grep -nE '\bgh ' plugins/sw/skills/archive/SKILL.md` exits 1.
- [x] **AC-10** `bash tests/validate-change/run.sh` prints `ALL PASS`, `bash tests/install/run.sh` prints `ALL PASS`, and `bash tests/release/run.sh` prints `PASS: static eight-skill inventory`.

Tick each `[x]` when verified by observed behavior.

## Decisions and discoveries

- **[decision]** All four changes ship in one pull request instead of four. They
  rewrite the same files — `README.md`, `AGENTS.md`, `references/vault-files.md`,
  `references/validation.md`, and all eight skills — so splitting them would mean
  four rounds of conflicting edits to the same documents for no reviewer benefit.
  Rejected: one PR per change, which specwright's own guidance prefers and which
  is right when the changes touch disjoint files.
- **[decision]** The artifact rename is applied last, after the other three
  changes are in place, so it sweeps their output in one pass. Rejected: renaming
  first, which would force the other three to be written against a schema with no
  real usage behind it yet.
- **[decision]** This change's own folder uses the new `proposal.md` /
  `design.md` / `tasks.md` schema rather than the schema it replaces. Writing it
  in the old names and renaming it mid-run would be theater. Rejected: matching
  the 31 historical folders, which stay untouched by design.
- **[decision]** `scope:` lives in `tasks.md`, and `sw:plan` decides it — not
  `sw:propose`. Judging whether a change needs an architecture document is a
  technical call, and `propose` runs before any technical exploration. Rejected:
  `scope:` in `proposal.md`; and dropping the field entirely, which would leave
  the choice implicit and let every agent default to writing a design document.
- **[decision]** `sw:archive` detects the merge with `git merge-base
  --is-ancestor` rather than `gh pr view`. Reintroducing a GitHub dependency in
  the same change that removes `sw:pr` for imposing GitHub conventions would be
  incoherent, and the git check works on any remote. Rejected: `gh`, more precise
  about *which* PR merged but host-locked.
- **[decision]** `sw:ship` keeps its name although it no longer opens a pull
  request; its description now promises a reviewed branch. Rejected: renaming it,
  which would be the third vocabulary rename since June for a one-word gain.
- **[decision]** The unit stays a "change" — `changes/`, `sw-change-owner`, "the
  change ladder" — while the command becomes `sw:propose`. The proposal is one
  artifact of a change, not a replacement for the concept. Rejected: renaming the
  unit to "proposal" everywhere.
- **[decision]** `AC-1`'s pattern was corrected mid-run from `sw:pr` to
  `sw:pr\b`, and from `pr\.md` to a form that will not match inside a longer
  word. As first written it matched `sw:propose` and `proposal.md` — the very
  command and artifact this same change introduces — so no implementation could
  have satisfied it. The criterion's intent is unchanged: no reference to the
  removed command survives anywhere. Rejected: leaving the pattern and declaring
  the criterion met by inspection, which would have hidden a broken gate.
- **[discovery]** `sw:pr` held the **only** branch-safety gate in the entire
  plugin. No other skill checks the current branch, so removing it would have let
  `/sw:implement` commit straight to `main` with no warning. The gate moves into
  `implement`, where it fires before the first commit rather than after every
  commit is already written.
- **[discovery]** `validate-change.sh` is only ever invoked on one folder at a
  time — by `sw:plan` or by hand — and nothing sweeps the vault. Historical
  folders in the old schema therefore never reach the validator, which is what
  makes a no-backfill rename safe.
