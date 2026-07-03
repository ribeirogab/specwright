# Learnings — Per-Role Model Routing

Non-obvious facts future issues inherit. Not narration of what was done.

## Claude Code honors per-subagent `model` but not per-subagent `effort` (today)

When a parent spawns a sub-agent, Claude Code applies a per-spawn **`model`** (the Agent/Task-tool `model` param, or an agent-definition `model:` frontmatter — aliases `opus`/`sonnet`/`haiku`/`fable`, full IDs, or `inherit`). It does **not** apply per-spawn **`effort`** on the interactive dispatch path: subagents run at the session's default effort, and extended-thinking on/off is inherited from the parent, not settable per sub-agent. `effort:` frontmatter and the SDK `AgentDefinition.effort` field exist in the docs, but are not wired through the interactive Task-tool spawn used by the specwright skills.

**Consequence for `.specwright/models.md`:** the `model` column routes for real; the `effort` column is **advisory** (recorded intent). A future issue that wants effort to go live must either drive spawns through agent-definition frontmatter / the SDK, or wait for the runtime to expose per-spawn effort — at which point the existing `effort` column becomes live with **no file-format change**.

## `validate-spec.sh` check 3 greps for a literal double-brace — describing placeholders trips it

Check 3 of `skills/sw/scripts/validate-spec.sh` fails on any literal double-brace opener in `issue.md`/`spec.md`/`tasks.md`. An issue artifact that needs to *describe* placeholder behavior (e.g. "validation FAILs on a surviving double-brace placeholder") will false-FAIL the mechanical gate. Write "double-brace placeholder" in prose, and in an embedded shell recipe match the token with a char class — `grep -E '[{][{]'` — so the literal two-brace sequence never appears in the file.

## `validation.md` / scaffolder recipes run in the user's shell (often zsh) — don't rely on `sh` word-splitting

The bash recipes documented in `skills/sw/references/validation.md` and `SKILL.md` may be executed by the agent through the machine's login shell, which on macOS is **zsh**, not bash. zsh does **not** word-split unquoted scalar parameters by default, so `for x in $var` (where `$var` is a newline-separated string) iterates **once** over the whole blob and silently produces wrong results — a validator that reports PASS when it should FAIL. Two independent review lanes caught exactly this in check #12's dangling-tier loop. Iterate portably with a quoted array or `while IFS= read -r x; do …; done <<< "$var"` (here-strings work in both bash and zsh). Every other loop in these files already uses a quoted array (`"${arr[@]}"`) or a glob — match that idiom.
