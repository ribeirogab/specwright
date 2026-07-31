# Security Policy

## Reporting a vulnerability

Report security issues privately to **gblosr@gmail.com**. Do not publish a
vulnerability in an issue or pull request before a coordinated fix is available.

Include the affected component, concrete reproduction, host and version, operating
system, impact, and any suggested mitigation.

This repository is maintained by one person on a best-effort basis with no SLA.
High-impact reports are prioritized. A polite follow-up after two weeks is
welcome.

## Scope

In scope:

- both plugin manifests and marketplace catalogs;
- shared skills and Claude command adapters;
- project templates, role manifests and profiles, validators, and the scaffolder;
- `sw:init` behavior affecting `AGENTS*.md`, `CLAUDE*.md`,
  `.codex/agents/sw-*.toml`, `.gitignore`, or `.specwright/`;
- change-owner branch and worktree isolation during a delivery; and
- release tests that claim a host recognizes the package.

Out of scope:

- vulnerabilities in Claude Code, Codex, Git, the operating system, model APIs,
  or unrelated third-party services;
- personal host configuration not written by specwright; and
- upstream vendored-code vulnerabilities unrelated to this repository's wrapper
  or distribution.

## Threat model

specwright is an instruction-driven plugin. Its scaffolder uses only the Python
standard library; skill authoring validation and packaging use PyYAML in an
ephemeral `uv` environment. Shell helpers connect those checks. The plugin can
guide agents that have repository write, Git, and external-service capabilities,
so the main trust boundaries are host permissions, project state written by the
scaffolder, filesystem paths, and delivery dispatch.

### Host authority

Ticket approval and an autonomous `sw:ship` run do not bypass host sandbox,
command, Git, network, credential, or external-action approval policy. A skill
that implies broader authority than the host granted is a security defect.

### Project scaffolding

`sw_init.py` performs no network access. It creates only what is missing and
never overwrites, repairs, or deletes existing content: a path that exists in an
unusable shape is reported as a conflict **before** any write, and the run writes
nothing at all.

Text the project owns must survive byte-for-byte — the `## specwright` section is
appended at most once and never rewritten. Unexpected file kinds, unsafe parent
paths, invalid template sources, or an unsupported symlink operation must fail
before any write. There is no regular-file fallback for Claude adapters, because
a copy would silently diverge from its canonical file.

Profile files are project configuration and may grant write capability to an
agent. Their names, models, reasoning effort, and sandbox mode are therefore part
of the reviewed security surface. `sw-reviewer` must remain read-only;
`sw-change-owner` remains constrained by its protocol and host policy.

### Delivery dispatch isolation

Each change owner works in its own branch and worktree and may edit only its own
change's artifacts, branch, and pull request. An owner that writes another
change's folder, edits the delivery's *why* sections, approves its own review, or
merges a pull request is a security defect.

The orchestrator is a pure conductor: it never edits code, and it pastes a
blocked report unmodified rather than composing one. In local mode it copies
conductor state into a worktree and copies only the change folder back; a sync
that carried instructions or profiles back from a worktree would let dispatched
work rewrite the conductor's own authority, and is a defect.

### Package recognition

Structural checks alone do not prove that a host can ingest the package. Release
CI uses the native Claude strict validator and a disposable Codex marketplace and
plugin home; a green local run of the release suite skips Codex ingestion and is
not evidence of it. It also rejects role profiles whose model is absent from the native
Codex model catalog. Positive installation and negative manifest/skill fixtures
must fail the release if either host no longer recognizes the expected package.

### Credentials and destructive actions

Skills and scripts must not print credentials, copy personal host settings, or
silently perform destructive actions. Temporary test state must be isolated from
maintainer configuration. Reports about command injection, path traversal,
credential disclosure, unsafe overwrite, or permission escalation are welcome.
