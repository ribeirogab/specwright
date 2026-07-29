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
- project templates, role manifests/profiles, validators, and updater;
- init/update behavior affecting `AGENTS*.md`, `CLAUDE*.md`,
  `.codex/agents/sw-*.toml`, `.gitignore`, or `.specwright/`;
- issue-owner/task-worker branch and worktree isolation; and
- release tests that claim a host recognizes the package.

Out of scope:

- vulnerabilities in Claude Code, Codex, Git, the operating system, model APIs,
  or unrelated third-party services;
- personal host configuration not written by specwright; and
- upstream vendored-code vulnerabilities unrelated to this repository's wrapper
  or distribution.

## Threat model

specwright is an instruction-driven plugin with standard-library Python and shell
helpers. It can guide agents that have repository write, Git, and external-service
capabilities, so the main trust boundaries are host permissions, managed project
state, filesystem paths, and worker integration.

### Host authority

Design approval and specwright plan confirmation do not bypass host sandbox,
command, Git, network, credential, or external-action approval policy. A skill
that implies broader authority than the host granted is a security defect.

### Project migration

The updater treats the installed Codex manifest as the target version and performs
no network access or remote-branch lookup. A read-only plan includes observed
state, ordered operations, and a deterministic `plan_id`; apply requires that
exact identity.

The managed AGENTS block carries a SHA-256 digest. Text outside it belongs to the
project and must be preserved. Unexpected file kinds, modified digests, stale
plan identity, invalid template sources, unsafe parent paths, or an unsupported
symlink operation must fail before managed writes. There is no regular-file
fallback for Claude adapters.

Profile files are project configuration and may grant write capability to an
agent. Their names, models, reasoning effort, and sandbox mode are therefore part
of the reviewed security surface. The two reviewer roles must remain read-only;
owner and worker write roles remain constrained by their protocol and host policy.

### Worker isolation

The issue owner records the exact base SHA, declared paths, and validation command
before dispatch. A returned worker branch is untrusted integration input until the
owner verifies ancestry, commit order, touched paths, and the full diff. Workers
must never write issue artifacts, integrate branches, create PRs, or alter files
outside their assignment.

Mechanical conflicts may be resolved and revalidated by the owner. Semantic
conflicts, scope changes, or ownership overlap require rejection and replanning.
Path traversal, symlink escape, common-Git-root confusion, or accepting commits
outside the recorded base are security defects.

### Package recognition

Structural checks alone do not prove that a host can ingest the package. Release
CI uses the native Claude strict validator and a disposable Codex marketplace and
plugin home. Positive installation and negative manifest/skill fixtures must fail
the release if either host no longer recognizes the expected package.

### Credentials and destructive actions

Skills and scripts must not print credentials, copy personal host settings, or
silently perform destructive actions. Temporary test state must be isolated from
maintainer configuration. Reports about command injection, path traversal,
credential disclosure, unsafe overwrite, or permission escalation are welcome.
