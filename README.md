# memex

An externalized, navigable project memory for coding agents — Claude Code, Codex, Cursor, OpenCode, Gemini CLI, Aider, and any other tool that supports the open agent skills standard. `memex` is a single skill that idempotently scaffolds a `.vault/` knowledge vault, an `AGENTS.md` (with a `CLAUDE.md` symlink for back-compat), spec/plan/task templates, and a set of bundled companion skills + slash commands into any repository — then dogfoods that same memory on its own development.

> Personal project, solo maintenance, best-effort, no SLA. Published so anyone can install it.

---

## Install

```bash
npx skills add ribeirogab/memex --skill memex
```

## Use

Point an agent at any repo where you want the memex installed:

> "Audit the memex in this repo and scaffold whatever is missing."

The skill is audit-first, autonomous-fix, and safe to re-run. After the first run the repo has a working `.vault/` vault, the bundled `memex-*` companion skills, the `/memex:*` slash commands, and an `AGENTS.md` — all dogfood-tested by the memex's own Phase-5 validator.

**Source:** [`skills/memex/SKILL.md`](skills/memex/SKILL.md)

## Repository layout

```
memex/
├── skills/memex/            # the skill: SKILL.md, references/, scaffold/, scripts/
├── plugins/memex/           # Claude Code plugin — the /memex:* slash commands
├── .claude-plugin/          # marketplace manifest
├── LICENSE                  # MIT
├── NOTICE.md                # attribution for vendored validator scripts
├── CONTRIBUTING.md
├── CODE_OF_CONDUCT.md
├── SECURITY.md
└── README.md
```

The repository also contains `.agents/`, `.claude/`, and `.vault/` — local dirs used to dogfood memex on its own development (the bundled companion skills, the per-agent symlinks, and the maintainer's knowledge vault). They are not what `npx skills add` installs.

## License

This repository's original work is licensed under the [MIT License](LICENSE). The vendored validator scripts under `skills/memex/scripts/` are Apache-2.0; see [`NOTICE.md`](NOTICE.md) for attribution.

## Contributing

Pull requests welcome — see [`CONTRIBUTING.md`](CONTRIBUTING.md) for scope, the quality bar, and the per-PR checklist. By participating, you agree to the [Code of Conduct](CODE_OF_CONDUCT.md). Security concerns go to [`SECURITY.md`](SECURITY.md).
