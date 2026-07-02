# Docs and Validator — Learnings

- `validate-spec.sh` now exits with the number of **distinct failed checks** (1–5), not the number of FAIL lines. A single defect that used to fire two lines (missing `status:` key) now exits 1. Exit **2** is still reused for operational errors (bad usage / not-a-directory) — distinguished from "two checks failed" only by the message (`usage:` / `FAIL:` with no `(check N)`, on stderr). Any caller must treat non-zero as "not clean"; do not switch on the exact value. `T2`'s recorded "planning-stage baseline = exactly one check-2 FAIL line" still holds and now cleanly means exit 1.

- The deliberate empty-value rule: `status:` (check 1) is load-bearing, so **empty or missing fails**; `scope:` (check 2) is recorded-only, so **empty is tolerated** (`""` is in check 2's enum). This asymmetry is intentional and documented in the script header — do not "fix" it to make them symmetric.

- `validate-spec.sh` is a single-copy artifact: it ships only from `skills/sw/scripts/` and reaches an installed repo via the `.agents/skills/sw/` self-copy (install-parity, PR #51). There is **no** second copy under `scaffold/skills/` or `plugins/`, so a validator edit is one file — unlike companion `SKILL.md`s (three copies) or the two-copy `sw-spec`/`sw-review-spec` pair.

- `agents-md-template.md` intentionally diverges from `AGENTS.md` in exactly one clause: the template's Skills intro says `(marketplace specwright)` and must **not** carry the dogfood-only `in this repo's .claude/settings.json` phrase (the template ships to arbitrary repos). After the AC-2 sync, the two `### Issue flow … Skills-intro` regions are byte-identical except that clause and the double-brace project-name fill — that is the "drift-clean" state any pair-comparison should expect.

- `NOTICE.md` lists exactly two Apache-2.0 vendored files: `quick_validate.py` and `package_skill.py`. `validate-spec.sh` is **original MIT work**, not vendored — any doc that calls the Apache portion "the validator scripts" is wrong.

- Still-open follow-ups this issue could not fix (outside its AC-1..AC-5, recorded per the scope guard):
  - `skills/sw/references/validation.md` Phase-5 check 8 still loops over six skills and checks none of the new install artifacts (self-installed `sw`, `.claude/skills/sw` symlink, vault `.gitkeep`s). install-parity deferred this here, but adding checks is barred by this issue's Non-Goals. Needs its own issue.
  - The README "**three kept-in-sync copies**" claim (line ~83) is accurate for the six companion skills but not for the two-copy `sw-spec`/`sw-review-spec` pair. Not in this issue's ACs; a one-line reword is a follow-up.
  - The degraded-delivery `pr.md` artifact is absent from the `vault-files.md` enumeration (issue-pipeline-contract / PR #50's surface, never actually added there).
  - The "a rename needs no cross-reference rewriting" claim in `skills/sw/SKILL.md` and `audit-checklist.md` now contradicts PR #52's evidence-consuming carve-out (brainstorm-and-templates' surface).
