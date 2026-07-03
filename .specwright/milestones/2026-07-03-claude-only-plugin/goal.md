---
milestone: claude-only-plugin
created: 2026-07-03
---
# Claude-only Plugin — Goal

> The stable *why* of the whole delivery — written once during the milestone brainstorm, after the decomposition is approved. Editing this file afterwards is a **scope change**: the orchestrator never does it on its own; a human decides. The live state (order, dependencies, blockers) lives in the sibling `board.md`; each issue's why lives in its own `issue.md`.

## Purpose

Turn specwright into a Claude-only plugin distributed through the marketplace, with a single on-disk source of truth under `plugins/sw/`. The plugin is installed once, globally, and provides every `/sw:*` command to any repository without copying files into it. Per-repository setup shrinks to a single command that creates the `.specwright/` vault and the `CLAUDE.md` entry point — and nothing machine-specific.

## Motivation

The agent-agnostic design forces every bundled skill to exist in three kept-in-sync copies (`.agents/skills/sw-*`, `skills/sw/scaffold/skills/sw-*`, `plugins/sw/skills/*`) because non-Claude agents discover skills from the repo filesystem, so the scaffolder must copy skills into each repo and merge machine configuration. Committing to Claude-only removes that need entirely: a plugin serves its skills globally without copying anything in. Collapsing to one copy kills the synchronization burden, the standalone installer, the self-copy/symlink machinery, and the settings-merge logic — and reduces the ex-scaffolder to per-repo content setup.

## Success Criteria

- The plugin installs once from the marketplace and makes every `/sw:*` command available in any repository, with no specwright tooling files copied into that repository.
- Adopting specwright into a repository requires only running the per-repo setup command, which produces the vault and the entry-point document and no machine configuration.
- Each bundled skill exists on disk exactly once; there is no duplicate copy to keep synchronized.
- The retired surface — the standalone installer, the update command, and the multi-agent scaffolding layer — is absent from the repository with no dangling references left in code or docs.

## Non-Goals

- Supporting non-Claude agents (Codex, Cursor, OpenCode, Aider, and similar).
- Auto-provisioning the plugin on clone. Global install stays a manual one-time step; a repository may separately opt into committed project settings, but building that is out of scope here.
- Changing the issue-driven workflow semantics (brainstorm → plan → quality gate → runtime verification → PR → review to lgtm).
