# Contributing

Thanks for considering a contribution to `specwright`. The repository accepts pull requests for the `sw` skill (and its bundled companions) and the documentation that supports them, with a small quality bar that this document explains.

The maintenance model is **solo, best-effort, no SLA**. Pull requests are reviewed when the maintainer is available; complex changes may take time to land. Please do not interpret silence as rejection — a polite ping after a couple of weeks is welcome.

## Scope

### What is in scope

- **Bug fixes and improvements to `sw`** — including bundled payloads (the scaffold content it copies into target repos, the bundled companion skills under `.agents/skills/sw-*/`, and the vendored validator scripts under `skills/sw/scripts/`).
- **Documentation fixes** to `README.md`, `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`, `SECURITY.md`, `NOTICE.md`.
- **Vendored-content updates** when a skill bundles upstream code that was refreshed; update `NOTICE.md` accordingly.

### What is out of scope

- **Skills unrelated to specwright.** This repository is dedicated to specwright. The [skills CLI](https://github.com/vercel-labs/skills) makes any public GitHub repo installable, so publish unrelated skills from your own repo.
- **`.specwright/`, `.agents/`, `.claude/`, `evals/`** — these are the maintainer's local-only dirs (dogfooded specwright output, eval workspaces). They are not part of the published skill surface and PRs touching them will be closed without merge.
- **Governance proposals**, maintainer hierarchies, decision-making frameworks, funding models, sponsorship, and similar process documents. The project is intentionally solo and lightweight.

## How to fix a bug or improve a skill

1. **File an issue first** for non-trivial changes so we can confirm scope before you spend time. Trivial fixes (typos, broken links, obvious bugs) can go straight to PR.
2. **Make the change** under `skills/<the-skill>/`. If the skill ships a scaffold or other payload that gets copied into target repos at runtime, remember those files run elsewhere — keep them generic and re-runnable.
3. **Run the quality bar checks** (next section) on the modified skill.
4. **Open the PR** with the template's checklist filled in.

## Quality bar

Mechanical checks must pass on the modified skill before the PR is opened. Both scripts are vendored copies of the canonical authoring validators (Apache-2.0, see [`NOTICE.md`](NOTICE.md)) and ship under `skills/sw/scripts/`:

```bash
python skills/sw/scripts/quick_validate.py skills/<the-skill-you-changed>
# expected output: "Skill is valid!"

python skills/sw/scripts/package_skill.py skills/<the-skill-you-changed> /tmp
# expected output: ends with "Successfully packaged skill to: /tmp/<skill-name>.skill"
```

`quick_validate.py` enforces the frontmatter contract (kebab-case `name`, `description` ≤ 1024 chars, no XML angle brackets, no reserved words, only canonical top-level keys). `package_skill.py` re-runs that validation and additionally confirms the skill packages cleanly into a `.skill` artifact (no broken file references, no excluded patterns left behind).

## Pull request checklist

The PR template carries this checklist; the items below explain each entry.

- [ ] **Branch name** is descriptive and not `main`. Suggested prefixes: `feat/`, `fix/`, `docs/`.
- [ ] **`quick_validate.py` and `package_skill.py` pass** on every modified skill (or N/A — your PR doesn't touch a skill).
- [ ] **`NOTICE.md` updated** when vendored content is refreshed or modified.
- [ ] **No edits under `.specwright/`, `.agents/`, `.claude/`, or `evals/`** (maintainer-local dirs, out of scope).
- [ ] **Commit messages** follow Conventional Commits style (`feat(<scope>): ...`, `fix(<scope>): ...`, `docs: ...`, `chore: ...`).
- [ ] **No AI-attribution footers** in commits or PR description (e.g. `Co-Authored-By: Claude`, `Generated with Cursor`, `Co-authored-by: Codex`, etc.).

## Reporting bugs

Open an issue using the bug-report template. Please include the skill name, the agent and version (Claude Code, Codex, Cursor, etc.), exact reproduction steps, and what you expected to happen vs. what did happen. The smaller and more specific the report, the faster it can be addressed.

## Code of conduct

Participation in this project is governed by the [Contributor Covenant 2.1](CODE_OF_CONDUCT.md). By contributing — whether via issues, PRs, or discussion — you agree to those standards.

## Security

Security concerns go to [`SECURITY.md`](SECURITY.md), not the public issue tracker.
