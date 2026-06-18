# memex worktrees — Tasks

> **For agentic workers:** implement task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. Each task names the `AC:` it satisfies and a `Delegable:` note.

**For this spec:** `[[2026-06-18-memex-worktrees/spec|spec]]`

---

All edits are prose. There is no unit-test framework; the "test" for each task is the grep-based acceptance criterion it names. The repo keeps several **byte-identical mirrors** — apply the same `old → new` string to every copy in a group, then verify mirror identity (AC-9).

## Task 1: Brainstorming skill — fourth question, guard, mechanic (3 copies)

**AC:** AC-1, AC-2, AC-3, AC-4, AC-9
**Delegable:** no (cross-file lockstep edit; a subagent would risk drifting the three copies).
**Files:**
- Modify: `.agents/skills/memex-brainstorming/SKILL.md`
- Modify: `plugins/memex/skills/brainstorming/SKILL.md`
- Modify: `skills/memex/scaffold/skills/memex-brainstorming/SKILL.md`

The three copies are body-identical, so each `old_string` below matches in all three — apply to all three.

- [ ] **Step 1: Checklist step 6 — three → four**

`old_string` (appears once per copy):
```
6. **Post-design batch** — once the design is approved, ask in **one** batch exactly three things: confirm the **branch name**, choose the **mode** (`autonomous` | `reviewed`), and whether to **hand off** before implementing. Record the branch + mode — writing-plans writes them into `spec.md` frontmatter when it creates the technical spec.
```
`new_string`:
```
6. **Post-design batch** — once the design is approved, ask in **one** batch exactly four things: confirm the **branch name**, choose the **mode** (`autonomous` | `reviewed`), choose whether to use a **worktree**, and whether to **hand off** before implementing. Record the branch, mode, and worktree choice — writing-plans writes them into `spec.md` frontmatter when it creates the technical spec.
```

- [ ] **Step 2: Dot-graph node label — add worktree**

Replace **both** occurrences of the node label (lines with `Post-design batch\n(branch + mode + handoff)`) — use `replace_all`:
`old_string` fragment: `Post-design batch\n(branch + mode + handoff)`
`new_string` fragment: `Post-design batch\n(branch + mode + worktree + handoff)`

- [ ] **Step 3: "After the Design" batch paragraph — three → four**

`old_string`:
```
In **one** batch, ask exactly three things: confirm the **branch name**, choose the **mode** (`autonomous` | `reviewed`), and whether to **hand off** before implementing. Record the branch and mode — writing-plans writes them into `spec.md` frontmatter when it creates the technical spec; the recorded `mode:` is registered consent for the feature branch (per `.memex/rules.md`, Git §2). There is no PR question; a PR is always the delivery — the mode only decides whether the agent opens it on its own.
```
`new_string`:
```
In **one** batch, ask exactly four things: confirm the **branch name**, choose the **mode** (`autonomous` | `reviewed`), choose whether to use a **worktree**, and whether to **hand off** before implementing. Record the branch, mode, and worktree choice — writing-plans writes them into `spec.md` frontmatter when it creates the technical spec; the recorded `mode:` is registered consent for the feature branch (per `.memex/rules.md`, Git §2). There is no PR question; a PR is always the delivery — the mode only decides whether the agent opens it on its own.
```

- [ ] **Step 4: Add the Worktree subsection** (insert immediately after the `reviewed` bullet block, before the line `Both modes self-review the spec and may use the handoff.`)

`old_string` (the anchor line):
```
Both modes self-review the spec and may use the handoff. The design-approval gate (step 5) is the **only** human review and is **never** skipped — there is **no** human spec-review gate and no "start implementation" gate.
```
`new_string`:
```
**Worktree (the third question):** before asking, detect whether you are already inside a linked git worktree:

```bash
[ "$(git rev-parse --git-common-dir)" != "$(git rev-parse --git-dir)" ] && echo "already in a linked worktree"
```

- **Already in a worktree** (e.g. a harness checkout under `worktrees/`) → warn the user (name the path) and recommend **no** — work in place. The check keys on git-dir vs git-common-dir, so it is agent-agnostic and never hardcodes one agent's directory.
- **Not in a worktree** → the default is **yes**.

When worktree = **yes**, create the branch as a worktree under the git-ignored `.memex/worktrees/<slug>` (where `<slug>` is the spec's dated-folder slug) and `cd` in before writing `design.md` — the rest of the flow runs there:

```bash
git worktree add .memex/worktrees/<slug> -b <branch>
cd .memex/worktrees/<slug>
```

When worktree = **no**, create the branch in place: `git checkout -b <branch>`. memex only ever **creates** a worktree — it never removes one; cleanup is the maintainer's, done manually after merge. Record the choice as `worktree:` in `spec.md` frontmatter (the path, or `null` when unused).

Both modes self-review the spec and may use the handoff. The design-approval gate (step 5) is the **only** human review and is **never** skipped — there is **no** human spec-review gate and no "start implementation" gate.
```

- [ ] **Step 5: Handoff `cd` note** — in the "Implementation handoff" section, extend the handoff-prompt bullet.

`old_string`:
```
  - **handoff = yes (either mode)** → print a ```` ```txt ```` **handoff prompt** (a one-paragraph summary + the paths to `design`/`spec`/`tasks` + the mode) and stop. The user runs `/compact` (or opens a new chat) and pastes it to resume. **Never hand off before the artifacts exist** — the preference was recorded up front; the handoff is produced only now.
```
`new_string`:
```
  - **handoff = yes (either mode)** → print a ```` ```txt ```` **handoff prompt** (a one-paragraph summary + the paths to `design`/`spec`/`tasks` + the mode; if a worktree was created, its first line is `cd .memex/worktrees/<slug>`) and stop. The user runs `/compact` (or opens a new chat) and pastes it to resume. **Never hand off before the artifacts exist** — the preference was recorded up front; the handoff is produced only now.
```

- [ ] **Step 6: Verify the three copies + identity**

```bash
grep -rc "worktree" .agents/skills/memex-brainstorming/SKILL.md plugins/memex/skills/brainstorming/SKILL.md skills/memex/scaffold/skills/memex-brainstorming/SKILL.md
grep -rn "three things" .agents/skills/memex-brainstorming/SKILL.md plugins/memex/skills/brainstorming/SKILL.md skills/memex/scaffold/skills/memex-brainstorming/SKILL.md
A=.agents/skills/memex-brainstorming/SKILL.md
B=plugins/memex/skills/brainstorming/SKILL.md
C=skills/memex/scaffold/skills/memex-brainstorming/SKILL.md
diff <(sed '1,/^---$/d;1,/^---$/d' "$A") <(sed '1,/^---$/d;1,/^---$/d' "$B") && diff <(sed '1,/^---$/d;1,/^---$/d' "$A") <(sed '1,/^---$/d;1,/^---$/d' "$C") && echo IDENTICAL
```
Expected: each file's `worktree` count ≥ 2; `three things` returns nothing; `IDENTICAL` prints.

- [ ] **Step 7: Commit**

```bash
git add .agents/skills/memex-brainstorming/SKILL.md plugins/memex/skills/brainstorming/SKILL.md skills/memex/scaffold/skills/memex-brainstorming/SKILL.md
git commit -m "feat(brainstorming): add worktree as the post-design batch's fourth question"
```

## Task 2: AGENTS.md + install template — flow steps

**AC:** AC-1, AC-2
**Delegable:** no (two files kept in lockstep).
**Files:**
- Modify: `AGENTS.md`
- Modify: `skills/memex/references/agents-md-template.md`

- [ ] **Step 1: Spec-flow step 1 — batch lists worktree** (same `old → new` in both files)

`old_string`:
```
1. `memex-brainstorming` → design exploration. After the design is approved, the **post-design batch** confirms the **branch name**, the **mode** (`autonomous` / `reviewed`), and whether to **hand off**. Brainstorming writes `design.md` (non-technical: purpose, motivation, definitions, non-goals) — the durable write-up of the approved design, not a second review gate.
```
`new_string`:
```
1. `memex-brainstorming` → design exploration. After the design is approved, the **post-design batch** confirms the **branch name**, the **mode** (`autonomous` / `reviewed`), whether to use a **worktree**, and whether to **hand off**. Brainstorming writes `design.md` (non-technical: purpose, motivation, definitions, non-goals) — the durable write-up of the approved design, not a second review gate.
```

- [ ] **Step 2: Spec-flow step 2 — branch or worktree** (same `old → new` in both files)

`old_string`:
```
2. Create the branch. **One branch + one PR per spec** — design, spec, tasks, implementation, and learnings all live in it.
```
`new_string`:
```
2. Create the branch — or, if a worktree was chosen, `git worktree add .memex/worktrees/<slug>` for it (the guard recommends against a worktree when already inside a linked one; detect with `git rev-parse --git-common-dir` ≠ `--git-dir`). memex only creates the worktree, never removes it. **One branch + one PR per spec** — design, spec, tasks, implementation, and learnings all live in it.
```

- [ ] **Step 3: Mermaid batch-node label** — both files carry the node `C["branch + mode + handoff"]`. Update **both**.

```bash
grep -rn 'branch + mode + handoff' AGENTS.md skills/memex/references/agents-md-template.md
```
For each match, replace `branch + mode + handoff` → `branch + mode + worktree + handoff` (use `replace_all` per file in case the label appears more than once).

- [ ] **Step 4: Verify + commit**

```bash
grep -rn "three things" AGENTS.md skills/memex/references/agents-md-template.md          # expect nothing
grep -rn "mode + handoff" AGENTS.md skills/memex/references/agents-md-template.md        # expect nothing (worktree now sits between)
grep -c "worktree" AGENTS.md skills/memex/references/agents-md-template.md                # expect ≥ 1 each
git add AGENTS.md skills/memex/references/agents-md-template.md
git commit -m "docs(flow): describe the worktree choice in AGENTS.md and its install template"
```

## Task 3: spec-driven-development guide (2 copies)

**AC:** AC-9
**Delegable:** no (two body-identical copies).
**Files:**
- Modify: `.memex/spec-driven-development.md`
- Modify: `skills/memex/scaffold/vault-docs/spec-driven-development.md`

- [ ] **Step 1: Flow-table row 1** (same in both)

`old_string`:
```
| 1 | Brainstorm → write `design.md`; post-design batch (branch + mode + handoff) | `memex-brainstorming` |
```
`new_string`:
```
| 1 | Brainstorm → write `design.md`; post-design batch (branch + mode + worktree + handoff) | `memex-brainstorming` |
```

- [ ] **Step 2: Flow-table row 2** (same in both)

`old_string`:
```
| 2 | Create the branch — **one branch + one PR per spec** | — |
```
`new_string`:
```
| 2 | Create the branch (or a worktree under `.memex/worktrees/<slug>`, default yes unless already inside a linked worktree) — **one branch + one PR per spec** | — |
```

- [ ] **Step 3: Verify identity + commit**

```bash
diff .memex/spec-driven-development.md skills/memex/scaffold/vault-docs/spec-driven-development.md && echo IDENTICAL
git add .memex/spec-driven-development.md skills/memex/scaffold/vault-docs/spec-driven-development.md
git commit -m "docs(guide): note the worktree choice in the spec-driven-development flow table"
```
Expected: `IDENTICAL` prints.

## Task 4: writing-plans skill (3 copies)

**AC:** AC-7, AC-9
**Delegable:** no (three body-identical copies).
**Files:**
- Modify: `.agents/skills/memex-writing-plans/SKILL.md`
- Modify: `plugins/memex/skills/writing-plans/SKILL.md`
- Modify: `skills/memex/scaffold/skills/memex-writing-plans/SKILL.md`

- [ ] **Step 1: Context line — branch or worktree** (same in all three)

`old_string`:
```
**Context:** This runs after brainstorming wrote `design.md` and the branch/mode were recorded. Work in the spec's branch.
```
`new_string`:
```
**Context:** This runs after brainstorming wrote `design.md` and the branch/mode/worktree were recorded. Work in the spec's branch — or its worktree under `.memex/worktrees/<slug>`, if one was created.
```

- [ ] **Step 2: Frontmatter-fill mention** — extend the frontmatter bullet so writing-plans records `worktree:`.

`old_string`:
```
- **Frontmatter** — set `status: draft`, `feature`, `created`, the recorded `branch:`/`mode:`, and `scope:` — your honest sizing of the work, one of `low | medium | high | complex`. `scope` is **recorded only**; nothing branches on it yet (reserved for a future quick-mode).
```
`new_string`:
```
- **Frontmatter** — set `status: draft`, `feature`, `created`, the recorded `branch:`/`mode:`/`worktree:`, and `scope:` — your honest sizing of the work, one of `low | medium | high | complex`. `scope` and `worktree` are **recorded only**; nothing branches on them yet (`scope` is reserved for a future quick-mode; `worktree` records the worktree path or `null`).
```

- [ ] **Step 3: Verify + commit**

```bash
grep -c "worktree" .agents/skills/memex-writing-plans/SKILL.md plugins/memex/skills/writing-plans/SKILL.md skills/memex/scaffold/skills/memex-writing-plans/SKILL.md
A=.agents/skills/memex-writing-plans/SKILL.md
B=plugins/memex/skills/writing-plans/SKILL.md
C=skills/memex/scaffold/skills/memex-writing-plans/SKILL.md
diff <(sed '1,/^---$/d;1,/^---$/d' "$A") <(sed '1,/^---$/d;1,/^---$/d' "$B") && diff <(sed '1,/^---$/d;1,/^---$/d' "$A") <(sed '1,/^---$/d;1,/^---$/d' "$C") && echo IDENTICAL
git add .agents/skills/memex-writing-plans/SKILL.md plugins/memex/skills/writing-plans/SKILL.md skills/memex/scaffold/skills/memex-writing-plans/SKILL.md
git commit -m "docs(writing-plans): record worktree and work inside it when created"
```
Expected: each `worktree` count ≥ 1; `IDENTICAL` prints.

## Task 5: spec template — optional `worktree:` field (live + scaffold source)

**AC:** AC-6
**Delegable:** yes — "Add an optional `worktree:` frontmatter key after `mode:` in two spec-template sources, recorded-only like `scope:`."
**Files:**
- Modify: `.memex/specs/_template/spec.md`
- Modify: `skills/memex/references/vault-files.md`

- [ ] **Step 1: Live template frontmatter** (`.memex/specs/_template/spec.md`)

Insert one new frontmatter line **immediately after the `mode:` line and before `related: []`**. The new line's key is `worktree:` and its value is `.memex/worktrees/<slug> | null` wrapped in the same doubled-curly-brace placeholder style the neighbouring `branch:`/`mode:` lines use. After the edit the frontmatter keys read, in order: `status`, `feature`, `scope`, `created`, `shipped`, `branch`, `mode`, `worktree`, `related`.

(This tasks file does not quote the literal doubled-brace tokens, because `validate-spec.sh` check 2 rejects any `{`-`{` pair in a spec's own `spec.md`/`tasks.md`/`design.md`. Read `.memex/specs/_template/spec.md` directly to copy the exact placeholder style.)

- [ ] **Step 2: Live template note** — add a note next to the `scope:`/`related:` notes.

`old_string`:
```
> **Note on `related:` frontmatter** — populate with wikilinks to learnings, conventions, or rules this spec touches, reads, or modifies. Empty `related:` is allowed only if the spec genuinely has no vault dependencies; `/memex:sweep` will flag isolated specs.
```
`new_string`:
```
> **Note on `worktree:` frontmatter** — the path of this spec's git worktree under `.memex/worktrees/`, or `null` when the work runs in place. **Recorded only**: like `scope:`, nothing branches on it and `validate-spec.sh` does not require it.
>
> **Note on `related:` frontmatter** — populate with wikilinks to learnings, conventions, or rules this spec touches, reads, or modifies. Empty `related:` is allowed only if the spec genuinely has no vault dependencies; `/memex:sweep` will flag isolated specs.
```

- [ ] **Step 3: Scaffold source** (`skills/memex/references/vault-files.md`, the embedded `_template/spec.md` block) — apply the **same two** edits (Steps 1 and 2 `old → new`).

- [ ] **Step 4: Verify + commit**

```bash
grep -n '^worktree:' .memex/specs/_template/spec.md
grep -n 'worktree:' skills/memex/references/vault-files.md
bash .memex/scripts/validate-spec.sh .memex/specs/_template 2>/dev/null; echo "exit:$?"   # template excluded from listings; this is a sanity check, not a gate
git add .memex/specs/_template/spec.md skills/memex/references/vault-files.md
git commit -m "docs(spec-template): add optional recorded-only worktree frontmatter field"
```
Expected: both greps hit; the `worktree:` line is present in both sources.

## Task 6: gitignore — `.memex/worktrees/` (live + scaffold instruction)

**AC:** AC-5
**Delegable:** yes — "Append `.memex/worktrees/` to the repo `.gitignore` and add the same line (with a one-line rationale) to the `.gitignore additions` block in `skills/memex/SKILL.md`."
**Files:**
- Modify: `.gitignore`
- Modify: `skills/memex/SKILL.md`

- [ ] **Step 1: Repo `.gitignore`** — append at end:

```
# memex per-spec worktrees (machine-local checkouts; mirror of .claude/worktrees/)
.memex/worktrees/
```

- [ ] **Step 2: SKILL.md gitignore block** — extend the append-list.

`old_string`:
```
```
# Obsidian vault config (machine-local — Obsidian rewrites these on every open)
.memex/.obsidian/
```
```
`new_string`:
```
```
# Obsidian vault config (machine-local — Obsidian rewrites these on every open)
.memex/.obsidian/

# memex per-spec worktrees (machine-local checkouts)
.memex/worktrees/
```
```

- [ ] **Step 3: Verify + commit**

```bash
grep -qE '^\.memex/worktrees/?$' .gitignore && echo "gitignore OK"
grep -n '.memex/worktrees/' skills/memex/SKILL.md
git add .gitignore skills/memex/SKILL.md
git commit -m "chore(gitignore): ignore .memex/worktrees and scaffold the same for new installs"
```
Expected: `gitignore OK` prints; SKILL.md grep hits.

## Task 7: README + `/memex:spec` command — batch summaries

**AC:** AC-1, AC-2
**Delegable:** yes — "Update two batch summaries from three questions to four, naming the worktree choice; no behavior described, just the count and the new item."
**Files:**
- Modify: `README.md`
- Modify: `plugins/memex/commands/spec.md`

- [ ] **Step 1: README batch sentence**

`old_string`:
```
Right after design approval, one batch asks exactly three things: the **branch name**, the execution **mode** (`autonomous` or `reviewed`), and whether to **hand off** before implementing.
```
`new_string`:
```
Right after design approval, one batch asks exactly four things: the **branch name**, the execution **mode** (`autonomous` or `reviewed`), whether to use a **worktree** (a memex-native checkout under `.memex/worktrees/`, default yes unless already inside a linked worktree), and whether to **hand off** before implementing.
```

- [ ] **Step 2: README mermaid node**

`old_string`: `C["Post-design batch:<br/>branch + mode + handoff?"]`
`new_string`: `C["Post-design batch:<br/>branch + mode + worktree + handoff?"]`

- [ ] **Step 3: `/memex:spec` command sentence**

`old_string`:
```
Then, in one batch, ask exactly three things: confirm the **branch name**, the **mode** (`autonomous`/`reviewed`), and whether to **hand off** before implementing. Record `branch:`/`mode:` in the spec.
```
`new_string`:
```
Then, in one batch, ask exactly four things: confirm the **branch name**, the **mode** (`autonomous`/`reviewed`), whether to use a **worktree** (under `.memex/worktrees/`), and whether to **hand off** before implementing. Record `branch:`/`mode:`/`worktree:` in the spec.
```

- [ ] **Step 4: Verify + commit**

```bash
grep -rn "three things" README.md plugins/memex/commands/spec.md   # expect nothing
grep -c "worktree" README.md plugins/memex/commands/spec.md         # expect ≥ 1 each
git add README.md plugins/memex/commands/spec.md
git commit -m "docs: describe the four-question post-design batch in README and /memex:spec"
```

## Task 8: Dogfood frontmatter, register spec, run gates

**AC:** AC-8, AC-10
**Delegable:** no (final integration + gates).
**Files:**
- Modify: `.memex/specs/2026-06-18-memex-worktrees/spec.md` (already `worktree: null` — confirm)
- Modify: `.memex/_index/specs.md`

- [ ] **Step 1: Confirm this spec's `worktree:` is honest** — the guard fired (work ran in the harness `.claude/worktrees/` checkout, in place), so `worktree: null` is correct. No edit needed unless absent.

```bash
grep -n '^worktree:' .memex/specs/2026-06-18-memex-worktrees/spec.md   # expect: worktree: null
```

- [ ] **Step 2: Register in the specs index** — add an In-Progress entry to `.memex/_index/specs.md` linking `2026-06-18-memex-worktrees` (match the existing row format in that file).

- [ ] **Step 3: Non-goals assertion (AC-8)**

```bash
git diff --name-only main...HEAD | grep -E 'validate-spec\.sh|\.memex/learnings/' && echo "VIOLATION" || echo "non-goals OK"
git diff --name-only main...HEAD | grep '^\.memex/specs/' | grep -v '2026-06-18-memex-worktrees/' | grep -v '_template/' && echo "STRAY SPEC EDIT" || echo "specs scope OK"
```
Expected: `non-goals OK` and `specs scope OK`.

- [ ] **Step 4: Mechanical gate (AC-10)**

```bash
bash .memex/scripts/validate-spec.sh .memex/specs/2026-06-18-memex-worktrees; echo "exit:$?"
grep -n '2026-06-18-memex-worktrees' .memex/_index/specs.md
```
Expected: `exit:0`; the index grep hits.

- [ ] **Step 5: Commit**

```bash
git add .memex/specs/2026-06-18-memex-worktrees/ .memex/_index/specs.md
git commit -m "docs(spec): register memex-worktrees and record worktree:null dogfood"
```
