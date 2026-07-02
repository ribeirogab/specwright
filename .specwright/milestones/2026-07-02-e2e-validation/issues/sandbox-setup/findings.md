# Sandbox Setup — Findings

Divergences between documented and observed specwright behavior, hit while installing specwright into the sandbox by following `skills/sw/SKILL.md`.

## F-1 — The scaffold never installs the `sw` skill itself into `.agents/skills/sw/`

- **Expected:** following `skills/sw/SKILL.md` Phase 4 produces an install where the issue pipeline can run: the installed `sw-plan` skill (line 92) and the `/sw:review-spec` command both invoke the mechanical validator at `.agents/skills/sw/scripts/validate-spec.sh`, and validation check 11 expects the templates + validator to be present "inside this skill".
- **Observed:** the copy loop in `SKILL.md` (`SKILL_NAMES=(sw-brainstorm sw-plan sw-pr sw-review sw-run sw-update)`) installs only the six companion skills. Nothing in Phase 4 copies the `sw` skill itself into the target repo, and `references/audit-checklist.md`'s inventory does not list `.agents/skills/sw/` either. A by-the-letter install therefore leaves `.agents/skills/sw/scripts/validate-spec.sh` nonexistent and the issue pipeline's mechanical gate broken on first use. The docs implicitly assume the user already placed the `sw` skill at `.agents/skills/sw/` before running it, but no document states that step. For the sandbox, `skills/sw/` was copied to `.agents/skills/sw/` explicitly so AC-4/AC-5 could hold.
- **Proposed fix:** add `sw` to the canonical install in `SKILL.md` Phase 4 (self-copy: when the running skill's own directory is not `<repo>/.agents/skills/sw`, copy it there, including `scaffold/` and `scripts/`, and `chmod +x scripts/*.sh`), and list `.agents/skills/sw/` in `references/audit-checklist.md`'s inventory so the audit catches its absence.

## F-2 — "Empty is fine" vault directories cannot survive a git clone

- **Expected:** `SKILL.md` Phase 4 ("Vault directories"): "Ensure all three directories exist (empty is fine on first install)" — implying a compliant install is durable as-is.
- **Observed:** git does not track empty directories, so a fresh install committed and re-cloned loses `.specwright/{conventions,issues,milestones}/` until something writes into them; any audit run on the clone reports them `MISSING`. The sandbox bootstrap added a `.gitkeep` to each so the single bootstrap commit preserves the vault.
- **Proposed fix:** have the scaffold `touch .specwright/{conventions,issues,milestones}/.gitkeep` (idempotent), or document that the vault dirs are recreated on demand and the audit's `MISSING` on a fresh clone is expected noise.
