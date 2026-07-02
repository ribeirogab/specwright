# Command Surface (T10) — Findings

Audit date: 2026-07-02. Surfaces: the specwright repo (worktree of branch `chore/e2e-command-surface`, referred to as `REPO`) and the sandbox install (`/Users/gabriel/www/ribeirogab/specwright-sandbox/taskr`, referred to as `SANDBOX`, read-only). Every verdict below was produced by a shell command whose output is reproduced in the Evidence section.

## 1. Verdict table — 8 verbs × layers (AC-1)

Layers: **plugin cmd** = `REPO/plugins/sw/commands/<verb>.md`; **plugin skill** = `REPO/plugins/sw/skills/<verb>/SKILL.md`; **repo canonical** = `REPO/.agents/skills/sw-<verb>/SKILL.md`; **scaffold src** = `REPO/skills/sw/scaffold/skills/sw-<verb>/` (what new installs receive); **sandbox canonical** = `SANDBOX/.agents/skills/sw-<verb>/SKILL.md`.

| Verb | plugin cmd | plugin skill | repo canonical | scaffold src | sandbox canonical | `/sw:<verb>` reachable |
|---|---|---|---|---|---|---|
| brainstorm | absent (by design) | **present** `plugins/sw/skills/brainstorm/` | **present** `.agents/skills/sw-brainstorm/` | **present** | **present** | yes (plugin skill) |
| spec | **present** `plugins/sw/commands/spec.md` | absent | **absent** | **absent** | **absent** | yes (plugin command) |
| plan | absent (by design) | **present** `plugins/sw/skills/plan/` | **present** `.agents/skills/sw-plan/` | **present** | **present** | yes (plugin skill) |
| run | absent (by design) | **present** `plugins/sw/skills/run/` | **present** `.agents/skills/sw-run/` | **present** | **present** | yes (plugin skill) |
| review | absent (by design) | **present** `plugins/sw/skills/review/` | **present** `.agents/skills/sw-review/` | **present** | **present** | yes (plugin skill) |
| review-spec | **present** `plugins/sw/commands/review-spec.md` | absent | **absent** | **absent** | **absent** | yes (plugin command) |
| pr | absent (by design) | **present** `plugins/sw/skills/pr/` | **present** `.agents/skills/sw-pr/` | **present** | **present** | yes (plugin skill) |
| update | absent (by design) | **present** `plugins/sw/skills/update/` | **present** `.agents/skills/sw-update/` | **present** | **present** | yes (plugin skill) |

"absent (by design)" = the plugin manifest itself declares the split — commands `/sw:spec` + `/sw:review-spec`, companion skills for the other six — so those cells are the intended shape, not drift. The two **bold absent** columns for `spec`/`review-spec` at the canonical/scaffold/sandbox layers are drift against the docs: see F1.

Sandbox Claude Code plugin layer: `SANDBOX/.claude/settings.json` declares marketplace `specwright` (github `ribeirogab/specwright`) and enables `sw@specwright`; no revision is pinned for the sandbox project in `~/.claude/plugins/installed_plugins.json` yet (materializes on first trusted session — documented behavior, README.md:20). The marketplace HEAD cache revision `3b34bf4899a2` carries 2 commands + 6 skills = all 8 `/sw:` verbs. Verdict: **wired, coherent**.

Scaffolder entry `/sw` (not one of the 8, audited for symlink coherence): repo `present` (`.claude/skills/sw -> ../../skills/sw`, resolves); sandbox `.agents/skills/sw/` present but **no `.claude/skills/sw` symlink** — see F2.

## 2. Skill-name identity (AC-2)

Rule: plugin skill `name:` = bare verb; canonical `name:` = `sw-<verb>`.

| Artifact | `name:` frontmatter | Verdict |
|---|---|---|
| `plugins/sw/skills/{brainstorm,plan,pr,review,run,update}/SKILL.md` | `brainstorm`, `plan`, `pr`, `review`, `run`, `update` | **match** (6/6) |
| `REPO/.agents/skills/sw-{brainstorm,plan,pr,review,run,update}/SKILL.md` | `sw-brainstorm` … `sw-update` | **match** (6/6) |
| `SANDBOX/.agents/skills/sw-{brainstorm,plan,pr,review,run,update}/SKILL.md` | `sw-brainstorm` … `sw-update` | **match** (6/6) |
| `SANDBOX/.agents/skills/sw/SKILL.md` | `sw` | **match** |

Both command stubs (`spec.md`, `review-spec.md`) have well-formed command frontmatter (`description:` + `argument-hint:`). Zero identity mismatches.

## 3. Retired names (AC-3)

Retired: `sw-brainstorming`, `sw-writing-plans`, `sw-new-pr`, `sw-code-review`, legacy `.claude/commands/sw-*.md`.

| Check | Command | Verdict |
|---|---|---|
| File/dir/symlink named after a retired name, REPO + SANDBOX | `find … -name 'sw-brainstorming*' -o …` | **zero hits** |
| Legacy `.claude/commands/` | `ls` both surfaces | **absent on both** (`No such file or directory`) |
| Dangling symlinks anywhere under REPO + SANDBOX | `find -L … -type l` | **zero hits** (repo `.claude/skills/sw` and sandbox `CLAUDE.md -> AGENTS.md` both resolve) |
| Content mentions (context only, not an AC-3 failure) | `grep -rn` excluding `.git` and this milestone's vault | `skills/sw/SKILL.md:139` + sandbox copy — the migration instruction telling `/sw` to flag pre-rename dirs as DRIFT; `.specwright/issues/2026-06-24-specwright-pivot/tasks.md:337,349` — historical vault record. All legitimate; none resolvable as a command/skill. |

Out-of-scope observation (recorded for context, not an AC-3 failure — neither audited surface is affected): the global plugin cache still holds pre-rename revision `~/.claude/plugins/cache/specwright/sw/2245ec42a933/` whose `skills/` are the retired names (`brainstorming`, `code-review`, `new-pr`, `writing-plans`); `installed_plugins.json` pins it to four unrelated local projects. Those projects get the retired surface until they update. Nothing in the sandbox or the repo resolves to it.

**AC-3 verdict: PASS on both audited surfaces.**

## 4. Doc-coherence map (AC-4)

Documented invocations extracted with `grep -rnoE '(/sw:[a-z-]+|\$sw-[a-z-]+|@sw-[a-z-]+)'` plus a literal `\$sw-|@sw-` pass (the docs write Codex/Cursor forms generically as `$sw-<verb>`).

| Documented invocation | Doc lines | Resolves to | Verdict |
|---|---|---|---|
| `/sw:brainstorm` `/sw:plan` `/sw:run` `/sw:review` `/sw:pr` `/sw:update` | REPO README.md:43–50, AGENTS.md:47–54, SANDBOX AGENTS.md:45–52 (+ inline uses) | plugin skills `plugins/sw/skills/<verb>/` | **resolved** |
| `/sw:spec` `/sw:review-spec` | REPO README.md:20,44,48,72; AGENTS.md:23,48,52; SANDBOX AGENTS.md:21,46,50 | plugin commands `plugins/sw/commands/{spec,review-spec}.md` | **resolved** |
| `$sw-<verb>` / `@sw-<verb>` for **"All entries"** (8 verbs) | REPO AGENTS.md:44 = CLAUDE.md:44 (symlink), SANDBOX AGENTS.md:42 | `.agents/skills/sw-<verb>/` — exists for 6 verbs only; `sw-spec` and `sw-review-spec` exist **nowhere** (repo canonical, scaffold source, sandbox) | **unresolved for 2×2 forms → F1** |
| `/sw` (scaffolder) + `.claude/skills/sw` symlink | REPO README.md:17,20,42 | repo: symlink present and resolves; sandbox: `.agents/skills/sw/` present, symlink **absent** | **partially unresolved → F2** |

No artifact exists without a documented invocation (every skill/command in the inventories maps to a doc row above).

## 5. Divergences — Expected / Observed / Proposed fix (AC-5)

### F1 — `$sw-spec`, `$sw-review-spec`, `@sw-spec`, `@sw-review-spec` are documented but unreachable

- **Expected:** REPO `AGENTS.md:44` (and its `CLAUDE.md` symlink) and SANDBOX `AGENTS.md:42` state "All entries shown in Claude Code syntax (plugin namespace `sw:`). Codex users invoke as `$sw-<verb>`; Cursor users as `@sw-<verb>`." — the 8-entry lists that follow include `spec` (AGENTS.md:48 / sandbox :46) and `review-spec` (AGENTS.md:52 / sandbox :50), so a Codex/Cursor user is promised `$sw-spec`, `$sw-review-spec`, `@sw-spec`, `@sw-review-spec` backed by `.agents/skills/sw-<verb>/` (AGENTS.md:46 / sandbox :44).
- **Observed:** no `sw-spec/` or `sw-review-spec/` under `REPO/.agents/skills/` (6 dirs), `REPO/skills/sw/scaffold/skills/` (6 dirs), or `SANDBOX/.agents/skills/` (6 `sw-*` dirs + `sw`). The two verbs exist only as Claude Code plugin command stubs. Independently reconfirms the docs-coherence (T11) relay with fresh evidence.
- **Proposed fix:** either (a) ship canonical `sw-spec` and `sw-review-spec` skills (add to `skills/sw/scaffold/skills/`, `REPO/.agents/skills/`, and the plugin as needed, keeping the three copies in sync per README.md:83–87), or (b) correct the docs: scope the "All entries" note to the six companion skills and state that `spec`/`review-spec` are Claude Code-only commands. (b) is the one-line fix; (a) is the parity fix.

### F2 — README promises a `.claude/skills/sw` symlink the sandbox install does not have

- **Expected:** REPO `README.md:17` — install "installs the scaffolder skill — `.agents/skills/sw/`, plus the `.claude/skills/sw` symlink"; `install.sh:8,147–153` creates `.claude/skills/sw -> ../../.agents/skills/sw`. That symlink is what makes `/sw` (README.md:20,42) discoverable by Claude Code in an installed repo.
- **Observed:** `SANDBOX/.claude/` contains only `settings.json` — no `skills/` dir, no symlink (evidence E7). `SANDBOX/.agents/skills/sw/` exists, so the skill body is there but Claude Code has no documented discovery path to it in the sandbox. (The specwright repo itself has the symlink — `.claude/skills/sw -> ../../skills/sw` — so this is sandbox-install drift, not repo drift.)
- **Proposed fix:** determine how the sandbox was installed (sandbox-setup used the `sw` scaffolder rather than `install.sh`, per its learnings); if the scaffolder path is meant to be equivalent to `install.sh`, add the `.claude/skills/sw` symlink step to the `sw` skill's scaffold procedure; otherwise document that only `install.sh` wires Claude Code discovery for `/sw`. Then create the missing symlink in the sandbox.

No other divergences: verbs, names, retired-name sweep, and the `/sw:` command surface are coherent everywhere else.

## 6. Evidence

All commands run 2026-07-02 from this worktree. `REPO` and `SANDBOX` as defined above.

**E1 — repo plugin layer** (`ls plugins/sw/commands plugins/sw/skills`; `cat plugins/sw/.claude-plugin/plugin.json`): commands = `review-spec.md`, `spec.md`; skills = `brainstorm plan pr review run update`; manifest: `"specwright slash commands (/sw:spec, /sw:review-spec) and companion skills (brainstorm, plan, run, review, pr, update)…"`.

**E2 — plugin skill names** (`grep '^name:' plugins/sw/skills/*/SKILL.md`): `brainstorm plan pr review run update` — all bare-verb, all match.

**E3 — repo canonical** (`ls .agents/skills/`; `grep '^name:'`): `sw-brainstorm sw-plan sw-pr sw-review sw-run sw-update`; names `sw-<verb>` all match; `find .agents -type l` → empty.

**E4 — scaffold source** (`ls skills/sw/scaffold/skills/`): `sw-brainstorm sw-plan sw-pr sw-review sw-run sw-update` — no `sw-spec`, no `sw-review-spec`.

**E5 — sandbox canonical** (`ls SANDBOX/.agents/skills/`; `grep '^name:'`): `sw sw-brainstorm sw-plan sw-pr sw-review sw-run sw-update`; all names match dir names.

**E6 — sandbox plugin wiring** (`cat SANDBOX/.claude/settings.json`): marketplace `specwright` → `{"source":"github","repo":"ribeirogab/specwright"}`, `enabledPlugins: {"sw@specwright": true}`. `installed_plugins.json` has no entry for the sandbox project path; cache revisions present: `2245ec42a933` (pre-rename skills: `brainstorming code-review new-pr update writing-plans`), `3b34bf4899a2` (current: commands `spec review-spec` + skills `brainstorm plan pr review run update`).

**E7 — sandbox `.claude` tree** (`find SANDBOX/.claude -maxdepth 3`): exactly one file, `settings.json`. Sandbox symlinks (`find SANDBOX -type l`): only `CLAUDE.md -> AGENTS.md` (resolves).

**E8 — retired-name sweep**: filename `find` over REPO+SANDBOX → zero hits (exit 0); `ls REPO/.claude/commands SANDBOX/.claude/commands` → both `No such file or directory`; `find -L REPO SANDBOX -type l` → zero dangling; content grep hits limited to `skills/sw/SKILL.md:139` (+ sandbox copy) and `.specwright/issues/2026-06-24-specwright-pivot/tasks.md:337,349` — instructional/historical text.

**E9 — doc invocation extraction**: distinct `/sw:` tokens across REPO README/AGENTS/CLAUDE/CONTRIBUTING + SANDBOX AGENTS/CLAUDE = exactly the 8 verbs; `$sw-`/`@sw-` appear only in the generic "All entries" lines (REPO AGENTS.md:44, SANDBOX AGENTS.md:42); CONTRIBUTING.md has no invocations.

**E10 — repo `.claude`**: `settings.json` (directory marketplace `.`, plugin enabled) + `skills/sw -> ../../skills/sw` (resolves).
