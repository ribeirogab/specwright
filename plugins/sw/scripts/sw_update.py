#!/usr/bin/env python3
"""Plan and safely apply deterministic specwright project migrations."""

from __future__ import annotations

import argparse
from dataclasses import asdict, dataclass
import hashlib
import json
import os
from pathlib import Path
import re
import stat
import sys
import tempfile

CALENDAR_VERSION_PATTERN = re.compile(r"^(?P<year>[1-9][0-9]{3})\.(?P<month>[1-9]|1[0-2])\.(?P<day>[1-9]|[12][0-9]|3[01])$")
MANAGED_OPENING_PATTERN = re.compile(
    r"^<!-- sw:managed version=(?P<version>[^ ]+) digest=(?P<digest>[0-9a-f]{64}) -->$"
)
MANAGED_CLOSING_MARKER = "<!-- /sw:managed -->"
PROFILE_DIRECTORY = Path(".codex/agents")
PROFILE_NAMES = (
    "sw-change-owner.toml",
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
    ".opencode/agent/sw-*.md",
    ".opencode/command/sw-*.md",
)
SHARED_IGNORE_RULES = (".specwright/worktrees/",)
ALL_MANAGED_IGNORE_RULES = tuple(dict.fromkeys((*SHARED_IGNORE_RULES, *LOCAL_IGNORE_RULES)))
OPENCODE_AGENT_DIRECTORY = Path(".opencode/agent")
OPENCODE_AGENT_NAMES = (
    "sw-change-owner.md",
    "sw-reviewer.md",
    "sw-spec-document-reviewer.md",
    "sw-task-worker.md",
)
OPENCODE_COMMAND_DIRECTORY = Path(".opencode/command")
OPENCODE_COMMAND_NAMES = (
    "sw-brainstorm.md",
    "sw-init.md",
    "sw-plan.md",
    "sw-pr.md",
    "sw-review-spec.md",
    "sw-review.md",
    "sw-run.md",
    "sw-spec.md",
    "sw-update.md",
)
MANAGED_TEMPLATE_SETS = (
    (PROFILE_DIRECTORY, "codex-agents", PROFILE_NAMES),
    (OPENCODE_AGENT_DIRECTORY, "opencode-agents", OPENCODE_AGENT_NAMES),
    (OPENCODE_COMMAND_DIRECTORY, "opencode-commands", OPENCODE_COMMAND_NAMES),
)
# Immutable predecessor digests distinguish a legitimate version upgrade from an
# edited managed profile. Add the outgoing release here before changing a profile.
KNOWN_PROFILE_DIGESTS_BY_VERSION: dict[str, dict[str, str]] = {
    "2026.7.29": {
        "sw-change-owner.toml": "e284400ad6ae02350b1978e2dbd5242c5d3c782fd7dd0d4e327a0c47089135c5",
        "sw-spec-document-reviewer.toml": "289862b98d25197db8afd074de3613bd45e3360c7df930f4aaadc3da368954df",
        "sw-reviewer.toml": "c3178c120cba83622d2346f8b92e5c2f53a435fdea0e34c0aec1572490690274",
        "sw-task-worker.toml": "bd43f3856048b804d49326eae461dcea49c19382121272a57f54f58218f0b516",
    },
}

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

class UpdateError(RuntimeError):
    """Raised when a confirmed update cannot be applied safely."""

class WriteFailure(UpdateError):
    def __init__(
        self,
        operation: Operation,
        completed: tuple[str, ...],
        pending: tuple[str, ...],
        temporary_path: Path | None,
        cause: Exception,
    ) -> None:
        self.operation = operation
        self.completed = completed
        self.pending = pending
        self.temporary_path = temporary_path
        self.cause = cause
        temporary = f"; recoverable temporary: {temporary_path}" if temporary_path is not None else ""
        super().__init__(
            f"write failed for {operation.relative_path}: {cause}; "
            f"completed: {', '.join(completed) or 'none'}; "
            f"pending: {', '.join(pending) or 'none'}{temporary}"
        )

class OperationWriteError(OSError):
    def __init__(self, cause: OSError, temporary_path: Path | None = None) -> None:
        super().__init__(str(cause))
        self.cause = cause
        self.temporary_path = temporary_path

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
    paths.extend(
        directory / name
        for directory, _, names in MANAGED_TEMPLATE_SETS
        for name in names
    )
    return tuple(sorted((_observe_path(project, path) for path in paths), key=lambda item: item.relative_path))

def _observe_path(project: Path, relative_path: Path) -> ObservedPath:
    absolute_path = project / relative_path
    try:
        stat_result = absolute_path.lstat()
    except FileNotFoundError:
        return ObservedPath(relative_path.as_posix(), "missing", None)
    except NotADirectoryError:
        return ObservedPath(relative_path.as_posix(), "blocked-parent", None)
    if absolute_path.is_symlink():
        return ObservedPath(relative_path.as_posix(), "symlink", str(absolute_path.readlink()))
    if absolute_path.is_file():
        return ObservedPath(relative_path.as_posix(), "file", _digest_bytes(absolute_path.read_bytes()))
    if absolute_path.is_dir():
        return ObservedPath(relative_path.as_posix(), "directory", None)
    return ObservedPath(relative_path.as_posix(), f"other:{stat_result.st_mode:o}", None)

def _template_source(relative_path: str) -> Path | None:
    """Return the installed template for a managed destination path, or None."""
    path = Path(relative_path)
    for directory, template_directory, names in MANAGED_TEMPLATE_SETS:
        if path.parent == directory and path.name in names:
            return (
                Path(__file__).resolve().parents[1]
                / "templates"
                / template_directory
                / path.name
            )
    return None

def _classify(project: Path, mode: str, canonical: str, adapter: str, desired_block: str) -> tuple[str, tuple[str, ...], str]:
    canonical_path = project / canonical
    adapter_path = project / adapter
    managed_paths = [
        canonical_path,
        adapter_path,
        *(
            project / directory / name
            for directory, _, names in MANAGED_TEMPLATE_SETS
            for name in names
        ),
    ]
    existing = [path for path in managed_paths if path.is_symlink() or path.exists()]
    if mode == "shared":
        opposite_canonical = project / "AGENTS.override.md"
        opposite_adapter = project / "CLAUDE.local.md"
        if (
            opposite_canonical.is_symlink()
            or opposite_canonical.exists()
            or opposite_adapter.is_symlink()
            or opposite_adapter.exists()
        ):
            return "drifted", ("the local instruction mode is already present",), desired_block
    if not existing:
        return "new", (), desired_block
    if _is_up_to_date(project, mode, canonical, adapter, desired_block):
        return "up-to-date", (), desired_block
    managed_result = _managed_update_desired(project, mode, canonical, adapter, desired_block)
    if managed_result is not None:
        return "legacy-migratable", (), managed_result
    return "drifted", ("managed paths do not match a recognized specwright state",), desired_block

def _ignore_rules_match(ignore_path: Path, mode: str) -> bool:
    if ignore_path.is_symlink() or not ignore_path.is_file():
        return False
    lines = ignore_path.read_text(encoding="utf-8").splitlines()
    required = LOCAL_IGNORE_RULES if mode == "local" else SHARED_IGNORE_RULES
    forbidden = set(ALL_MANAGED_IGNORE_RULES) - set(required)
    if any(lines.count(rule) != 1 for rule in required):
        return False
    if any(rule in lines for rule in forbidden):
        return False
    first_required_index = min(lines.index(rule) for rule in required)
    return not any(
        line.startswith("!") and not line.startswith(r"\!")
        for line in lines[first_required_index + 1 :]
    )

def _is_up_to_date(project: Path, mode: str, canonical: str, adapter: str, desired_block: str) -> bool:
    canonical_path = project / canonical
    adapter_path = project / adapter
    if canonical_path.is_symlink() or not canonical_path.is_file() or not adapter_path.is_symlink() or adapter_path.readlink() != Path(canonical):
        return False
    if _managed_block(canonical_path.read_text(encoding="utf-8")) != desired_block:
        return False
    for directory, _, names in MANAGED_TEMPLATE_SETS:
        for name in names:
            destination = project / directory / name
            source = _template_source((directory / name).as_posix())
            assert source is not None
            if destination.is_symlink() or not destination.is_file() or destination.read_bytes() != source.read_bytes():
                return False
    if not _ignore_rules_match(project / ".gitignore", mode):
        return False
    return True

def _managed_update_desired(
    project: Path,
    mode: str,
    canonical: str,
    adapter: str,
    desired_block: str,
) -> str | None:
    canonical_path = project / canonical
    adapter_path = project / adapter
    if canonical_path.is_symlink() or not canonical_path.is_file():
        return None
    if not adapter_path.is_symlink() or adapter_path.readlink() != Path(canonical):
        return None
    contents = canonical_path.read_text(encoding="utf-8")
    current_details = _managed_block_details(contents)
    desired_details = _managed_block_details(desired_block)
    if current_details is None or desired_details is None:
        return None
    current_block, current_version = current_details
    _, desired_version = desired_details
    if current_block == desired_block or current_version == desired_version:
        return None
    expected_profiles = KNOWN_PROFILE_DIGESTS_BY_VERSION.get(current_version)
    if expected_profiles is None or set(expected_profiles) != set(PROFILE_NAMES):
        return None
    for name in PROFILE_NAMES:
        destination = project / PROFILE_DIRECTORY / name
        if (
            destination.is_symlink()
            or not destination.is_file()
            or _digest_bytes(destination.read_bytes()) != expected_profiles[name]
        ):
            return None
    for directory, _, names in MANAGED_TEMPLATE_SETS[1:]:
        for name in names:
            destination = project / directory / name
            if destination.is_symlink():
                return None
            if not destination.exists():
                continue
            source = _template_source((directory / name).as_posix())
            assert source is not None
            if not destination.is_file() or destination.read_bytes() != source.read_bytes():
                return None
    if not _ignore_rules_match(project / ".gitignore", mode):
        return None
    return contents.replace(current_block, desired_block, 1)

def _managed_block_details(contents: str) -> tuple[str, str] | None:
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
    version = opening.group("version")
    if not is_calendar_version(version):
        return None
    body = "".join(lines[opening_index + 1 : closing_index]).rstrip("\n")
    if opening.group("digest") != _digest_text(body):
        return None
    return block, version

def _managed_block(contents: str) -> str | None:
    details = _managed_block_details(contents)
    return details[0] if details is not None else None

def _operations(project: Path, mode: str, canonical: str, adapter: str, desired_canonical: str, state: str) -> tuple[Operation, ...]:
    if state in {"up-to-date", "drifted"}:
        return ()
    operations: list[Operation] = []
    canonical_path = project / canonical
    if not (canonical_path.is_symlink() or canonical_path.exists()):
        operations.append(Operation("create", canonical, None, desired_canonical))
    elif canonical_path.is_file() and canonical_path.read_text(encoding="utf-8") != desired_canonical:
        operations.append(
            Operation(
                "replace-managed-block",
                canonical,
                _digest_bytes(canonical_path.read_bytes()),
                desired_canonical,
            )
        )
    adapter_path = project / adapter
    if not (adapter_path.is_symlink() or adapter_path.exists()):
        operations.append(Operation("create-symlink", adapter, None, canonical))
    elif not (adapter_path.is_symlink() and adapter_path.readlink() == Path(canonical)):
        expected = None
        if not adapter_path.is_symlink() and adapter_path.is_file():
            expected = _digest_bytes(adapter_path.read_bytes())
        operations.append(Operation("replace-with-symlink", adapter, expected, canonical))
    for directory, _, names in MANAGED_TEMPLATE_SETS:
        for name in names:
            source = _template_source((directory / name).as_posix())
            assert source is not None
            destination = project / directory / name
            relative = (directory / name).as_posix()
            if not (destination.is_symlink() or destination.exists()):
                operations.append(
                    Operation("create", relative, None, _digest_bytes(source.read_bytes()))
                )
            elif (
                state == "legacy-migratable"
                and not destination.is_symlink()
                and destination.is_file()
                and destination.read_bytes() != source.read_bytes()
            ):
                operations.append(
                    Operation(
                        "replace-profile",
                        relative,
                        _digest_bytes(destination.read_bytes()),
                        _digest_bytes(source.read_bytes()),
                    )
                )
    ignore_path = project / ".gitignore"
    ignore_rules = LOCAL_IGNORE_RULES if mode == "local" else SHARED_IGNORE_RULES
    if not _ignore_rules_match(ignore_path, mode):
        operations.append(
            Operation(
                "ensure-ignore-rules",
                ".gitignore",
                _digest_bytes(ignore_path.read_bytes())
                if not ignore_path.is_symlink() and ignore_path.is_file()
                else None,
                "\n".join(ignore_rules),
            )
        )
    return tuple(operations)

def apply_update(
    project: Path,
    mode: str,
    expect_plan: str,
    version: str | None = None,
) -> tuple[UpdatePlan, tuple[str, ...]]:
    """Replan, verify identity, preflight, and apply exactly the confirmed operations."""
    project = project.resolve()
    plan = plan_update(project, mode, version)
    if not expect_plan or expect_plan != plan.plan_id:
        raise UpdateError(
            f"confirmed plan identity does not match current project state "
            f"(expected {expect_plan or 'missing'}, current {plan.plan_id})"
        )
    if plan.state == "drifted":
        details = "; ".join(plan.diagnostics) or "unrecognized managed state"
        raise UpdateError(f"refusing to apply drifted project: {details}")
    _preflight(project, plan)

    completed: list[str] = []
    for operation_index, operation in enumerate(plan.operations):
        try:
            _apply_operation(project, operation)
        except (OSError, UpdateError) as error:
            pending = tuple(item.relative_path for item in plan.operations[operation_index:])
            temporary_path = getattr(error, "temporary_path", None)
            cause = getattr(error, "cause", error)
            raise WriteFailure(operation, tuple(completed), pending, temporary_path, cause) from error
        completed.append(operation.relative_path)
    return plan, tuple(completed)

def _preflight(project: Path, plan: UpdatePlan) -> None:
    if not project.is_dir():
        raise UpdateError(f"project is not a directory: {project}")
    for operation in plan.operations:
        relative_path = _validated_relative_path(operation.relative_path)
        destination = project / relative_path
        _validate_parent_chain(project, relative_path.parent)
        _validate_operation_precondition(destination, operation)
        _validate_profile_source(operation)
    symlink_operation = next(
        (
            operation
            for operation in plan.operations
            if operation.action in {"create-symlink", "replace-with-symlink"}
        ),
        None,
    )
    if symlink_operation is not None:
        _probe_symlink_support(project, symlink_operation.desired_after)

def _validated_relative_path(value: str) -> Path:
    relative_path = Path(value)
    if relative_path.is_absolute() or not relative_path.parts:
        raise UpdateError(f"managed path must be repository-relative: {value}")
    if any(part in {"", ".", ".."} for part in relative_path.parts):
        raise UpdateError(f"managed path is not normalized: {value}")
    return relative_path

def _validate_parent_chain(project: Path, relative_parent: Path) -> None:
    current = project
    if not os.access(current, os.W_OK | os.X_OK):
        raise UpdateError(f"managed parent is not writable: {current}")
    for component in relative_parent.parts:
        current = current / component
        if current.is_symlink():
            raise UpdateError(f"managed parent may not be a symlink: {current}")
        if current.exists():
            if not current.is_dir():
                raise UpdateError(f"managed parent is not a directory: {current}")
            if not os.access(current, os.W_OK | os.X_OK):
                raise UpdateError(f"managed parent is not writable: {current}")
            continue
        break

def _validate_operation_precondition(destination: Path, operation: Operation) -> None:
    exists = destination.is_symlink() or destination.exists()
    if operation.action in {"create", "create-symlink"}:
        if exists:
            raise UpdateError(f"managed destination is occupied: {operation.relative_path}")
        return
    if operation.action in {"replace-managed-block", "replace-profile", "replace-with-symlink"}:
        if destination.is_symlink() or not destination.is_file():
            raise UpdateError(f"managed destination is not the expected regular file: {operation.relative_path}")
        if operation.expected_before != _digest_bytes(destination.read_bytes()):
            raise UpdateError(f"managed destination changed before apply: {operation.relative_path}")
        return
    if operation.action == "ensure-ignore-rules":
        if destination.is_symlink() or (exists and not destination.is_file()):
            raise UpdateError(".gitignore must be a regular file or missing")
        actual = _digest_bytes(destination.read_bytes()) if destination.is_file() else None
        if actual != operation.expected_before:
            raise UpdateError(".gitignore changed before apply")
        return
    raise UpdateError(f"unknown managed operation: {operation.action}")

def _validate_profile_source(operation: Operation) -> None:
    if operation.action not in {"create", "replace-profile"}:
        return
    source = _template_source(operation.relative_path)
    if source is None:
        return
    if source.is_symlink() or not source.is_file():
        raise UpdateError(f"installed profile template is invalid: {source}")
    if _digest_bytes(source.read_bytes()) != operation.desired_after:
        raise UpdateError(f"installed profile template changed after planning: {source}")

def _probe_symlink_support(project: Path, target: str) -> None:
    temporary_path: Path | None = None
    try:
        descriptor, temporary_name = tempfile.mkstemp(
            prefix=".sw-symlink-probe-",
            dir=project,
        )
        temporary_path = Path(temporary_name)
        os.close(descriptor)
        temporary_path.unlink()
        os.symlink(target, temporary_path)
        if not temporary_path.is_symlink() or temporary_path.readlink() != Path(target):
            raise OSError("symlink probe did not preserve its relative target")
    except OSError as error:
        if temporary_path is not None and (
            temporary_path.is_symlink() or temporary_path.exists()
        ):
            temporary_path.unlink()
        raise UpdateError(
            "symlink support is required; no regular-file fallback is available: "
            f"{error}"
        ) from error
    assert temporary_path is not None
    temporary_path.unlink()

def _apply_operation(project: Path, operation: Operation) -> None:
    relative_path = _validated_relative_path(operation.relative_path)
    _validate_parent_chain(project, relative_path.parent)
    destination = project / relative_path
    _validate_operation_precondition(destination, operation)
    _validate_profile_source(operation)
    if operation.action in {"create", "replace-managed-block", "replace-profile"}:
        source = _template_source(operation.relative_path)
        if source is not None:
            contents = source.read_bytes()
            mode = stat.S_IMODE(source.stat().st_mode)
        else:
            contents = operation.desired_after.encode("utf-8")
            mode = (
                stat.S_IMODE(destination.stat().st_mode)
                if destination.is_file() and not destination.is_symlink()
                else 0o644
            )
        _atomic_write(
            destination,
            contents,
            mode,
            replace=operation.action != "create",
        )
        return
    if operation.action in {"create-symlink", "replace-with-symlink"}:
        _atomic_symlink(
            destination,
            operation.desired_after,
            replace=operation.action == "replace-with-symlink",
        )
        return
    if operation.action == "ensure-ignore-rules":
        contents = _updated_ignore_bytes(destination, operation.desired_after.splitlines())
        mode = (
            stat.S_IMODE(destination.stat().st_mode)
            if destination.is_file() and not destination.is_symlink()
            else 0o644
        )
        _atomic_write(destination, contents, mode, replace=destination.exists())
        return
    raise UpdateError(f"unknown managed operation: {operation.action}")

def _updated_ignore_bytes(destination: Path, rules: list[str]) -> bytes:
    existing = destination.read_bytes() if destination.is_file() and not destination.is_symlink() else b""
    preserved = [
        line
        for line in existing.decode("utf-8").splitlines()
        if line not in ALL_MANAGED_IGNORE_RULES
    ]
    while preserved and not preserved[-1]:
        preserved.pop()
    if preserved:
        preserved.append("")
    preserved.extend(rules)
    return ("\n".join(preserved) + "\n").encode("utf-8")

def _atomic_write(
    destination: Path,
    contents: bytes,
    mode: int,
    *,
    replace: bool,
) -> None:
    destination.parent.mkdir(parents=True, exist_ok=True)
    descriptor, temporary_name = tempfile.mkstemp(
        prefix=f".{destination.name}.sw-",
        dir=destination.parent,
    )
    temporary_path = Path(temporary_name)
    try:
        with os.fdopen(descriptor, "wb") as temporary_file:
            temporary_file.write(contents)
            temporary_file.flush()
            os.fsync(temporary_file.fileno())
        temporary_path.chmod(mode)
        if not replace and (destination.is_symlink() or destination.exists()):
            raise FileExistsError(f"destination appeared during apply: {destination}")
        os.replace(temporary_path, destination)
    except OSError as error:
        raise OperationWriteError(
            error,
            temporary_path if temporary_path.exists() or temporary_path.is_symlink() else None,
        ) from error

def _atomic_symlink(destination: Path, target: str, *, replace: bool) -> None:
    destination.parent.mkdir(parents=True, exist_ok=True)
    descriptor, temporary_name = tempfile.mkstemp(
        prefix=f".{destination.name}.sw-",
        dir=destination.parent,
    )
    temporary_path = Path(temporary_name)
    os.close(descriptor)
    temporary_path.unlink()
    try:
        os.symlink(target, temporary_path)
        if not replace and (destination.is_symlink() or destination.exists()):
            raise FileExistsError(f"destination appeared during apply: {destination}")
        os.replace(temporary_path, destination)
    except OSError as error:
        raise OperationWriteError(
            error,
            temporary_path if temporary_path.exists() or temporary_path.is_symlink() else None,
        ) from error

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
    action = parser.add_mutually_exclusive_group(required=True)
    action.add_argument("--plan", action="store_true")
    action.add_argument("--apply", action="store_true")
    parser.add_argument("--project", type=Path, default=Path.cwd())
    parser.add_argument("--mode", choices=("shared", "local"), required=True)
    parser.add_argument("--format", choices=("text", "json"), default="text")
    parser.add_argument("--expect-plan")
    parsed = parser.parse_args(arguments)
    if parsed.apply and not parsed.expect_plan:
        parser.error("--apply requires --expect-plan")
    if parsed.plan and parsed.expect_plan:
        parser.error("--expect-plan is valid only with --apply")
    try:
        if parsed.apply:
            plan, completed = apply_update(
                parsed.project,
                parsed.mode,
                parsed.expect_plan,
            )
        else:
            plan = plan_update(parsed.project, parsed.mode)
            completed = ()
    except (ValueError, UpdateError) as error:
        print(f"error: {error}", file=sys.stderr)
        return 1
    if parsed.format == "json":
        output = plan_as_dict(plan)
        if parsed.apply:
            output["applied"] = list(completed)
        print(_canonical_json(output))
    else:
        print(f"state: {plan.state}")
        print(f"version: {plan.version}")
        print(f"mode: {plan.mode}")
        print(f"plan_id: {plan.plan_id}")
        for diagnostic in plan.diagnostics:
            print(f"diagnostic: {diagnostic}")
        for operation in plan.operations:
            print(f"operation: {operation.action} {operation.relative_path}")
        if parsed.apply:
            for relative_path in completed:
                print(f"applied: {relative_path}")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
