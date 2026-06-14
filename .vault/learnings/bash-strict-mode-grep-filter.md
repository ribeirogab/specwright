---
tags:
  - learning
  - gotcha
related:
  - "[[../specs/2026-05-03-strengthen-vault-cross-links/spec]]"
  - "[[mechanical-enforcement-over-prose]]"
created: 2026-05-03
---
# Bash strict mode + `grep -v`/`grep -E` filter exits 1 — wrap with `|| true`

When a script uses `set -euo pipefail` and a pipeline includes a `grep` invocation that filters out **all** matching lines (`grep -v`, `grep -Ev`, `grep -F`, etc.), `grep` exits with code 1 ("no matches"). Combined with `pipefail`, the whole pipeline returns 1, and `set -e` kills the script silently — often inside a command substitution where stderr is suppressed. The classic symptom: trace shows the script reached an assignment, then the next line is the EXIT trap, with no error message.

## Context

Hit twice while building `find-candidates.sh` (the `memex-link` deterministic detector):

- `tokenize()` ended in `... | grep -Ev "$STOPWORDS_RE" | sort -u`. When all input tokens were stopwords (e.g. an H2 "How It Works" → `how`/`works`/`it` all filtered), `grep -Ev` exited 1 → pipefail → script aborted at the next `tgt_h2_tokens=$(...)` assignment with no diagnostic.
- `shared_count=$(... | grep -c . 2>/dev/null || echo 0)`. `grep -c .` always *prints* a number, but exits 1 when count is 0. The `|| echo 0` then fired *in addition*, producing `0\n0` literally, which made `[ "$shared_count" -ge 2 ]` fail with `[: 0\n0: integer expected`.

Both are non-obvious because `grep` looks like it succeeded (it printed something or correctly filtered) but the exit code propagation kills the script.

## How to Apply

When writing a bash script with `set -euo pipefail` and any of `grep -v`, `grep -Ev`, `grep -F` (with no match), or `grep -c .` (with zero count) in a pipeline:

1. **Filter pipelines** (`grep -v`/`-Ev`): wrap the failing step in a brace block with `|| true`:
   ```bash
   tokenize() {
     tr '[:upper:]' '[:lower:]' \
       | tr -cs '[:alnum:]' '\n' \
       | { grep -Ev "$STOPWORDS_RE" || true; } \
       | sort -u
   }
   ```
   Don't put `|| true` outside the pipeline (`pipeline || true`) — that hides bugs in upstream stages too. Put it inside the brace block scoped to the one step that's allowed to fail.

2. **Counting with `grep -c`**: never combine `grep -c X || echo N`. Use `grep -c X || true`:
   ```bash
   count=$(printf '%s\n' "$input" | grep -c . || true)
   # count is now "0" or "5" etc., never "0\n0".
   ```

3. **Debugging this class of failure**: if a script under `set -euo pipefail` exits silently mid-execution, run with `bash -x` and look for the last successful assignment — the silently-failing pipeline is on the *next* line. The trace will show no error because the script exits before stderr is flushed.

This is one of the load-bearing reasons that all bash scripts in this repo's skills should ship a `tests/run.sh` with diverse fixtures: at least one input that exercises every filter in every "all matches filtered out" / "zero matches" code path. The first time you run the script in production with no test coverage of these paths, it dies silently.
