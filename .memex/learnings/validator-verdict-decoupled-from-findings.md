---
tags:
  - learning
related:
  - "[[../specs/2026-06-14-bare-spec-filenames/spec|bare-spec-filenames]]"
  - "[[mechanical-enforcement-over-prose]]"
  - "[[bash-strict-mode-grep-filter]]"
created: 2026-06-14
---
# A validator's verdict can silently decouple from its findings (pipe subshell)

The old validation check #15 set `fail=0`, then ran `find … | while read; do …; fail=1; done`, then concluded `[ $fail -eq 0 ] && echo PASS`. Because the `while` loop is the right side of a pipe, it runs in a **subshell** — `fail=1` never escapes, so the check always concluded `PASS` even while printing `FAIL:` lines. A check that always passes is worse than no check: it advertises enforcement it does not provide. The fix is to capture findings with command substitution in the parent shell — `bad=$(find …); [ -z "$bad" ] && echo PASS || { echo FAIL; echo "$bad"; }` — so the verdict is computed from the same data the reader sees.

## Context

Found while inverting check #15 (slug-named → bare spec filenames) in `skills/memex/references/validation.md`. The bug had been latent because the FAIL lines still printed, so casual reads looked plausible; only the summary line lied.

## How to Apply

Never set a pass/fail flag inside a `cmd | while …` loop and read it afterward — the assignment dies with the subshell. Derive the verdict from a value captured in the parent shell (command substitution, a temp file, or process substitution `while …; done < <(cmd)`). When writing or reviewing a memex validator/sweep check, confirm the summary verdict is computed from the same captured output it prints, not from a variable mutated inside a pipeline.
