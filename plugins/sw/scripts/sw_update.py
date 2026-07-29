#!/usr/bin/env python3
"""Build deterministic, read-only plans for specwright project migration."""

from __future__ import annotations

import argparse
from dataclasses import asdict, dataclass
import hashlib
import json
from pathlib import Path
import re
import sys


CALENDAR_VERSION_PATTERN = re.compile(r"^(?P<year>[1-9][0-9]{3})\.(?P<month>[1-9]|1[0-2])\.(?P<day>[1-9]|[12][0-9]|3[01])$")
MANAGED_OPENING_PATTERN = re.compile(
    r"^<!-- sw:managed version=(?P<version>[^ ]+) digest=(?P<digest>[0-9a-f]{64}) -->$"
)
MANAGED_CLOSING_MARKER = "<!-- /sw:managed -->"
PROFILE_DIRECTORY = Path(".codex/agents")
PROFILE_NAMES = (
    "sw-issue-owner.toml",
    "sw-spec-document-reviewer.toml",
    "sw-reviewer.toml",
    "sw-task-worker.toml",
)
LOCAL_IGNORE_RULES = (
    ".specwright/worktrees/",
    ".specwright/",
    "AGENTS.override.md",
    "CLAUDE.local.md",
    ".codex/agents/sw-*.toml",
)
SHARED_IGNORE_RULES = (".specwright/worktrees/",)
LEGACY_DOGFOOD_DIGEST = "c32175b40821260004481eb131198c2239851b47b1334e475e962226c190a28b"
LEGACY_GENERIC_TEMPLATE = """# {{Project Name}} — Agent Instructions

Instructions for AI coding assistants and developers working on the {{project}} codebase.

**Never give up on the right solution.**

## Workflow Spec Driven

Implementing, modifying, or creating something? Ask: "Can I describe the complete solution in one sentence?"
- **Yes** → implement directly.
- **Almost** (1-2 open decisions) → ask the user: issue or go direct?
- **No** → enter the Issue flow.

If the user is asking, investigating, or exploring — just answer.

### Issue flow

The **issue** is the unit of work: one folder (`issue.md` ticket with `AC-N` + `status:`, technical `spec.md`, `tasks.md`, optional `learnings.md` + any issue-specific artifacts), one branch, one PR. A large delivery is a **milestone**: `goal.md` + live `board.md` + `issues/<slug>/`, conducted in a loop by `/sw:run`.

1. `/sw:brainstorm` → open design conversation (converse first, decide at the end); design approval is the **only** human review. The agent then concludes the **scope** — single issue or milestone (it suggests, you decide) — and asks one batch: single issue = branch + worktree + handoff; milestone = worktree only.
2. **Single issue** → write `issues/YYYY-MM-DD-<slug>/issue.md`, then `/sw:plan`: just-in-time `spec.md` + `tasks.md`, self-reviewed (spec-document-reviewer subagent + `/sw:review-spec` + `validate-spec.sh` — no human gate) → implement → **quality gate** (run every test/lint/typecheck/build the touched area has; test integrity: no silent count drop, no weakened assertions) → **runtime verification** (execute it; check each `AC-N` by observed behavior; UI via browser or mark `needs-human-verification`) → `/sw:pr` → `/sw:review` to `lgtm` → set `issue.md` `status: shipped` + date. Three identical failures of one gate → stop and report; never thrash.
3. **Milestone** → write `goal.md` + `board.md` + N `issue.md`, print the mandatory handoff and stop (the planning session never conducts). `/sw:run` in a fresh session conducts: dispatch every **ready** issue (pending + deps shipped) to an issue-owner sub-agent in parallel, one worktree each (`.specwright/worktrees/<slug>`, git-ignored; specwright creates worktrees, never removes them); each owner runs step 2's pipeline and curates the issue's `learnings.md` (facts future issues inherit via their specs); blocked issues get a report on the board and the loop moves on; closeout promotes durable learnings to `CLAUDE.md`/conventions with your approval. Merging PRs stays yours.

```mermaid
flowchart TD
    A(["/sw:brainstorm"]) --> B{"design approved?"}
    B -- "no, revise" --> A
    B -- yes --> C{"scope?"}
    C -- "single issue" --> D["issue.md → /sw:plan → implement<br/>→ quality gate → runtime verification<br/>→ /sw:pr → /sw:review lgtm"]
    C -- milestone --> E["goal + board + issues → handoff"]
    E --> F["/sw:run: dispatch ready issues to owners<br/>→ each runs the pipeline → learnings<br/>→ loop until done or blocked"]
    D --> G(["shipped"])
    F --> G
```

## Coding standard

`/sw:review` enforces the coding standard (Unix philosophy, meaningful comments, security). `.specwright/conventions/` holds whatever standards this repo wants kept consistent — code style, architecture, naming, testing, any project preference — which you fill over time and `/sw:review` enforces alongside its universal rubric. Standalone issues live in `.specwright/issues/`; milestones in `.specwright/milestones/`.

## Skills and slash commands

This repository requires the `sw` Claude Code plugin — every `/sw:*` command below comes from it, globally, with nothing copied into this repo. If these commands are unavailable, install the plugin once:

```
claude plugin marketplace add ribeirogab/specwright
claude plugin install sw@specwright
```

- **`/sw:brainstorm`** — design exploration; concludes single issue vs milestone and writes the artifacts.
- **`/sw:spec`** — enter the issue flow from the conversation.
- **`/sw:plan`** — the issue pipeline: just-in-time spec + tasks, gates, delivery.
- **`/sw:run`** — conduct a milestone: dispatch ready issues, track the board, close out.
- **`/sw:review`** — bespoke, portable review cycle to `lgtm`.
- **`/sw:review-spec`** — external evaluator pass over an issue's plan (agent self-review).
- **`/sw:pr`** — open the issue's PR.
"""


@dataclass(frozen=True)
class ObservedPath:
    relative_path: str
    kind: str
    digest_or_target: str | None


@dataclass(frozen=True)
class Operation:
    action: str
    relative_path: str
    expected_before: str | None
    desired_after: str


@dataclass(frozen=True)
class UpdatePlan:
    state: str
    version: str
    mode: str
    observed: tuple[ObservedPath, ...]
    operations: tuple[Operation, ...]
    plan_id: str
    diagnostics: tuple[str, ...] = ()


def load_installed_version() -> str:
    """Return the validated unpadded calendar version from the installed manifest."""
    manifest_path = Path(__file__).resolve().parents[1] / ".codex-plugin" / "plugin.json"
    try:
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise ValueError(f"cannot read Codex manifest: {error}") from error
    version = manifest.get("version")
    if not isinstance(version, str) or not is_calendar_version(version):
        raise ValueError("Codex manifest version must be an unpadded valid calendar SemVer")
    return version


def is_calendar_version(version: str) -> bool:
    match = CALENDAR_VERSION_PATTERN.fullmatch(version)
    if match is None:
        return False
    year, month, day = (int(match.group(name)) for name in ("year", "month", "day"))
    try:
        from datetime import date

        date(year, month, day)
    except ValueError:
        return False
    return True


def render_managed_block(version: str) -> str:
    template_path = Path(__file__).resolve().parents[1] / "references" / "agents-md-template.md"
    template = template_path.read_text(encoding="utf-8")
    marker_start = template.index("<!-- sw:managed")
    marker_end = template.index(MANAGED_CLOSING_MARKER, marker_start) + len(MANAGED_CLOSING_MARKER)
    block = template[marker_start:marker_end]
    body_start = block.index("\n") + 1
    body_end = block.rfind("\n" + MANAGED_CLOSING_MARKER)
    body = block[body_start:body_end]
    rendered_body = body.replace("{{version}}", version)
    digest = _digest_text(rendered_body)
    return block.replace("{{version}}", version).replace("{{digest}}", digest)


def plan_update(project: Path, mode: str, version: str | None = None) -> UpdatePlan:
    """Inspect *project* and return a deterministic plan without changing it."""
    if mode not in {"shared", "local"}:
        raise ValueError("mode must be shared or local")
    project = project.resolve()
    version = load_installed_version() if version is None else version
    if not is_calendar_version(version):
        raise ValueError("version must be an unpadded valid calendar SemVer")

    canonical = "AGENTS.md" if mode == "shared" else "AGENTS.override.md"
    adapter = "CLAUDE.md" if mode == "shared" else "CLAUDE.local.md"
    observed = _observe_paths(project, canonical, adapter)
    desired_block = render_managed_block(version)
    state, diagnostics, desired_canonical = _classify(project, mode, canonical, adapter, desired_block)
    operations = _operations(project, mode, canonical, adapter, desired_canonical, state)
    payload = {
        "version": version,
        "mode": mode,
        "observed": [asdict(item) for item in observed],
        "operations": [asdict(item) for item in operations],
    }
    plan_id = _digest_text(_canonical_json(payload))
    return UpdatePlan(state, version, mode, observed, operations, plan_id, diagnostics)


def _observe_paths(project: Path, canonical: str, adapter: str) -> tuple[ObservedPath, ...]:
    paths = [Path(canonical), Path(adapter), Path(".gitignore")]
    paths.extend(PROFILE_DIRECTORY / name for name in PROFILE_NAMES)
    return tuple(sorted((_observe_path(project, path) for path in paths), key=lambda item: item.relative_path))


def _observe_path(project: Path, relative_path: Path) -> ObservedPath:
    absolute_path = project / relative_path
    try:
        stat_result = absolute_path.lstat()
    except FileNotFoundError:
        return ObservedPath(relative_path.as_posix(), "missing", None)
    if absolute_path.is_symlink():
        return ObservedPath(relative_path.as_posix(), "symlink", str(absolute_path.readlink()))
    if absolute_path.is_file():
        return ObservedPath(relative_path.as_posix(), "file", _digest_bytes(absolute_path.read_bytes()))
    if absolute_path.is_dir():
        return ObservedPath(relative_path.as_posix(), "directory", None)
    return ObservedPath(relative_path.as_posix(), f"other:{stat_result.st_mode:o}", None)


def _classify(project: Path, mode: str, canonical: str, adapter: str, desired_block: str) -> tuple[str, tuple[str, ...], str]:
    canonical_path = project / canonical
    adapter_path = project / adapter
    managed_paths = [canonical_path, adapter_path, *(project / PROFILE_DIRECTORY / name for name in PROFILE_NAMES)]
    existing = [path for path in managed_paths if path.is_symlink() or path.exists()]
    opposite_canonical = project / ("AGENTS.override.md" if mode == "shared" else "AGENTS.md")
    opposite_adapter = project / ("CLAUDE.local.md" if mode == "shared" else "CLAUDE.md")
    if opposite_canonical.is_symlink() or opposite_canonical.exists() or opposite_adapter.is_symlink() or opposite_adapter.exists():
        return "drifted", ("the opposite instruction mode is already present",), desired_block
    if not existing:
        return "new", (), desired_block
    if _is_up_to_date(project, mode, canonical, adapter, desired_block):
        return "up-to-date", (), desired_block
    legacy_result = None if _has_managed_profiles(project) else _legacy_desired(project, canonical, adapter, desired_block)
    if legacy_result is not None:
        return "legacy-migratable", (), legacy_result
    return "drifted", ("managed paths do not match a recognized specwright state",), desired_block


def _is_up_to_date(project: Path, mode: str, canonical: str, adapter: str, desired_block: str) -> bool:
    canonical_path = project / canonical
    adapter_path = project / adapter
    if canonical_path.is_symlink() or not canonical_path.is_file() or not adapter_path.is_symlink() or adapter_path.readlink() != Path(canonical):
        return False
    if _managed_block(canonical_path.read_text(encoding="utf-8")) != desired_block:
        return False
    for name in PROFILE_NAMES:
        destination = project / PROFILE_DIRECTORY / name
        source = Path(__file__).resolve().parents[1] / "templates" / "codex-agents" / name
        if destination.is_symlink() or not destination.is_file() or destination.read_bytes() != source.read_bytes():
            return False
    ignore_path = project / ".gitignore"
    ignore_rules = LOCAL_IGNORE_RULES if mode == "local" else SHARED_IGNORE_RULES
    if not ignore_path.is_file() or not set(ignore_rules).issubset(set(ignore_path.read_text(encoding="utf-8").splitlines())):
        return False
    return True


def _legacy_desired(project: Path, canonical: str, adapter: str, desired_block: str) -> str | None:
    canonical_path = project / canonical
    adapter_path = project / adapter
    if canonical_path.is_symlink() or canonical_path.exists() or adapter_path.is_symlink() or not adapter_path.is_file():
        return None
    contents = adapter_path.read_text(encoding="utf-8")
    if _matches_legacy_generic(contents):
        return desired_block
    if _digest_bytes(contents.encode("utf-8")) == LEGACY_DOGFOOD_DIGEST:
        prefix, suffix = _split_dogfood_legacy(contents)
        return prefix + "\n\n" + desired_block + "\n\n" + suffix
    return None


def _has_managed_profiles(project: Path) -> bool:
    return any((project / PROFILE_DIRECTORY / name).is_symlink() or (project / PROFILE_DIRECTORY / name).exists() for name in PROFILE_NAMES)


def _matches_legacy_generic(contents: str) -> bool:
    expression = re.escape(LEGACY_GENERIC_TEMPLATE)
    expression = expression.replace(re.escape("{{Project Name}}"), r"[^\n]+")
    expression = expression.replace(re.escape("{{project}}"), r"[^\n]+")
    return re.fullmatch(expression, contents) is not None


def _split_dogfood_legacy(contents: str) -> tuple[str, str]:
    workflow_index = contents.index("## Workflow Spec Driven")
    editing_index = contents.index("### Editing the bundled skills")
    prefix = contents[:workflow_index].rstrip()
    suffix = contents[editing_index:].rstrip()
    return prefix, suffix


def _managed_block(contents: str) -> str | None:
    lines = contents.splitlines(keepends=True)
    opening_indices = [index for index, line in enumerate(lines) if line.rstrip("\n").startswith("<!-- sw:managed")]
    closing_indices = [index for index, line in enumerate(lines) if line.rstrip("\n").startswith("<!-- /sw:managed")]
    if len(opening_indices) != 1 or len(closing_indices) != 1:
        return None
    opening_index = opening_indices[0]
    closing_index = closing_indices[0]
    if closing_index <= opening_index or MANAGED_OPENING_PATTERN.match(lines[opening_index].rstrip("\n")) is None or lines[closing_index].rstrip("\n") != MANAGED_CLOSING_MARKER:
        return None
    block = "".join(lines[opening_index : closing_index + 1]).rstrip("\n")
    opening = MANAGED_OPENING_PATTERN.match(lines[opening_index].rstrip("\n"))
    assert opening is not None
    body = "".join(lines[opening_index + 1 : closing_index]).rstrip("\n")
    if opening.group("digest") != _digest_text(body):
        return None
    return block


def _operations(project: Path, mode: str, canonical: str, adapter: str, desired_canonical: str, state: str) -> tuple[Operation, ...]:
    if state in {"up-to-date", "drifted"}:
        return ()
    operations: list[Operation] = []
    canonical_path = project / canonical
    action = "create" if not canonical_path.exists() else "replace-managed-block"
    operations.append(Operation(action, canonical, _digest_bytes(canonical_path.read_bytes()) if canonical_path.is_file() else None, desired_canonical))
    adapter_path = project / adapter
    operations.append(Operation("create-symlink" if not (adapter_path.exists() or adapter_path.is_symlink()) else "replace-with-symlink", adapter, _digest_bytes(adapter_path.read_bytes()) if adapter_path.is_file() else None, canonical))
    for name in PROFILE_NAMES:
        source = Path(__file__).resolve().parents[1] / "templates" / "codex-agents" / name
        operations.append(Operation("create", (PROFILE_DIRECTORY / name).as_posix(), None, _digest_bytes(source.read_bytes())))
    ignore_path = project / ".gitignore"
    ignore_rules = LOCAL_IGNORE_RULES if mode == "local" else SHARED_IGNORE_RULES
    operations.append(Operation("ensure-ignore-rules", ".gitignore", _digest_bytes(ignore_path.read_bytes()) if ignore_path.is_file() else None, "\n".join(ignore_rules)))
    return tuple(operations)


def plan_as_dict(plan: UpdatePlan) -> dict[str, object]:
    return {
        "state": plan.state,
        "version": plan.version,
        "mode": plan.mode,
        "observed": [asdict(item) for item in plan.observed],
        "operations": [asdict(item) for item in plan.operations],
        "plan_id": plan.plan_id,
        "diagnostics": list(plan.diagnostics),
    }


def _canonical_json(value: object) -> str:
    return json.dumps(value, sort_keys=True, separators=(",", ":"), ensure_ascii=True)


def _digest_text(value: str) -> str:
    return _digest_bytes(value.encode("utf-8"))


def _digest_bytes(value: bytes) -> str:
    return hashlib.sha256(value).hexdigest()


def main(arguments: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--plan", action="store_true", required=True)
    parser.add_argument("--project", type=Path, default=Path.cwd())
    parser.add_argument("--mode", choices=("shared", "local"), required=True)
    parser.add_argument("--format", choices=("text", "json"), default="text")
    parsed = parser.parse_args(arguments)
    try:
        plan = plan_update(parsed.project, parsed.mode)
    except ValueError as error:
        parser.error(str(error))
    if parsed.format == "json":
        print(_canonical_json(plan_as_dict(plan)))
    else:
        print(f"state: {plan.state}")
        print(f"version: {plan.version}")
        print(f"mode: {plan.mode}")
        print(f"plan_id: {plan.plan_id}")
        for diagnostic in plan.diagnostics:
            print(f"diagnostic: {diagnostic}")
        for operation in plan.operations:
            print(f"operation: {operation.action} {operation.relative_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
