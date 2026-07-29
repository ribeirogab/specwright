This draft defines the delivery contract for native Claude Code and Codex parity with owner-controlled worker integration.

- Defines one shared nine-skill implementation with native adapters for both hosts.
- Specifies versioned AGENTS migrations, project-scoped Codex roles, and symlink-only Claude compatibility.
- Defines validated task waves and issue-owner cherry-pick integration for isolated workers.

## Summary

This is an artifacts-only draft: implementation has intentionally not started. The approved design requires full first-release parity, an unpadded calendar SemVer from the Codex manifest, deterministic plan identities for project migration, and the issue owner as the sole integrator of worker commits.

- [issue](https://github.com/ribeirogab/specwright/blob/feat/dual-host-safe-worker-orchestration/.specwright/issues/2026-07-28-dual-host-safe-worker-orchestration/issue.md)
- [spec](https://github.com/ribeirogab/specwright/blob/feat/dual-host-safe-worker-orchestration/.specwright/issues/2026-07-28-dual-host-safe-worker-orchestration/spec.md)
- [tasks](https://github.com/ribeirogab/specwright/blob/feat/dual-host-safe-worker-orchestration/.specwright/issues/2026-07-28-dual-host-safe-worker-orchestration/tasks.md)

## Test plan

- [ ] Not applicable yet — no skill implementation is modified in this draft.
- [ ] Not applicable yet — end-to-end host behavior is deferred to the implementation tasks.
- [x] Visually confirmed the rendered issue, spec, tasks, dependency metadata, and PR record.

## Planning gates

- Mechanical validator: PASS.
- Author review: PASS — AC-1 through AC-12 are covered, no placeholders or unresolved questions remain, and the dependency graph is acyclic.
- Spec-document reviewer: three iterations completed. The final iteration identified only a literal inline-ownership marker mismatch; it was corrected to exact `- None`. No fourth dispatch was made because the skill caps independent review at three iterations.
- External issue/conventions review: PASS — required sections, scope discipline, concrete criteria, and project conventions are satisfied.

## Runtime verification

AC-1 through AC-12 are not yet runtime-verified because this draft intentionally contains no implementation. Their exact fixture and host-native verification commands are defined in `tasks.md`.

## Checklist

- [x] Branch name is descriptive and not `main`.
- [x] `NOTICE.md` is unchanged because no vendored content is added or modified.
- [ ] Maintainer dogfood exception — this planning-only draft intentionally adds one issue folder under `.specwright/`.
- [x] Commit messages follow Conventional Commits style.
- [x] No AI-attribution footers appear in commits or this description.

## Notes for the reviewer

Implementation is intentionally pending. Review should focus on the approved scope, acceptance criteria, task ownership/dependencies, updater safety contract, host parity, and worker authority boundaries.
