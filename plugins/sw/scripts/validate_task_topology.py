#!/usr/bin/env python3
"""Parse and validate schema-2 task metadata and dependency topology."""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import PurePosixPath
import re
import sys


TASK_HEADING_PATTERN = re.compile(r"^###\s+(T[1-9][0-9]*):\s+(.+?)\s*$")
METADATA_PATTERN = re.compile(
    r"^\*\*(AC|Delegable|Depends on|Files|Integration|Validation):\*\*(?:\s*(.*))$"
)
TASK_LIKE_HEADING_PATTERN = re.compile(r"^###\s+")
AC_ID_PATTERN = re.compile(r"AC-[1-9][0-9]*")
TASK_ID_PATTERN = re.compile(r"T[1-9][0-9]*")
FILE_ENTRY_PATTERN = re.compile(r"^-\s+(?:Create|Modify|Delete):\s+(.+?)\s*$")
SYMLINK_ENTRY_PATTERN = re.compile(r"^-\s+Replace with symlink:\s+(.+?)\s*$")
DELEGABLE_PATTERN = re.compile(r"^(yes|no)(?:\s+—\s+.+)?$")
REQUIRED_FIELDS = ("AC", "Delegable", "Depends on", "Files", "Integration", "Validation")


@dataclass(frozen=True)
class Task:
    task_id: str
    ac_ids: tuple[str, ...]
    delegable: bool
    dependencies: tuple[str, ...]
    files: tuple[str, ...]
    integration: str
    validation: str
    line: int = 0


@dataclass(frozen=True)
class Diagnostic:
    line: int
    message: str


@dataclass(frozen=True)
class ParseResult:
    tasks: tuple[Task, ...]
    diagnostics: tuple[Diagnostic, ...]


@dataclass(frozen=True)
class _TaskBlock:
    task_id: str
    line: int
    body: tuple[tuple[int, str], ...]


def parse_task_document(text: str) -> ParseResult:
    """Return schema-2 tasks and all syntax or metadata diagnostics."""
    lines = text.splitlines()
    diagnostics = _parse_frontmatter(lines)
    blocks, heading_diagnostics = _split_task_blocks(lines)
    diagnostics.extend(heading_diagnostics)

    tasks: list[Task] = []
    seen_ids: set[str] = set()
    for block in blocks:
        if block.task_id in seen_ids:
            diagnostics.append(Diagnostic(block.line, f"duplicate task ID {block.task_id}"))
        seen_ids.add(block.task_id)
        task, block_diagnostics = _parse_task_block(block)
        diagnostics.extend(block_diagnostics)
        if task is not None:
            tasks.append(task)

    return ParseResult(tuple(tasks), tuple(sorted(diagnostics, key=lambda item: item.line)))


def _parse_frontmatter(lines: list[str]) -> list[Diagnostic]:
    if not lines or lines[0] != "---":
        return [Diagnostic(1, "tasks.md must begin with frontmatter containing tasks_schema: 2")]

    try:
        closing_index = lines.index("---", 1)
    except ValueError:
        return [Diagnostic(1, "frontmatter is missing its closing delimiter")]

    schema_lines = [
        index + 1
        for index, line in enumerate(lines[1:closing_index], start=1)
        if line.startswith("tasks_schema:")
    ]
    if len(schema_lines) != 1:
        return [Diagnostic(1, "frontmatter must contain exactly one tasks_schema: 2 field")]
    schema_line = schema_lines[0]
    if lines[schema_line - 1] != "tasks_schema: 2":
        return [Diagnostic(schema_line, "tasks_schema must be exactly 2")]
    return []


def _split_task_blocks(lines: list[str]) -> tuple[list[_TaskBlock], list[Diagnostic]]:
    blocks: list[_TaskBlock] = []
    diagnostics: list[Diagnostic] = []
    current_id: str | None = None
    current_line = 0
    current_body: list[tuple[int, str]] = []

    for line_number, line in enumerate(lines, start=1):
        heading_match = TASK_HEADING_PATTERN.match(line)
        if heading_match:
            if current_id is not None:
                blocks.append(_TaskBlock(current_id, current_line, tuple(current_body)))
            current_id = heading_match.group(1)
            current_line = line_number
            current_body = []
            continue
        if TASK_LIKE_HEADING_PATTERN.match(line):
            diagnostics.append(Diagnostic(line_number, "task headings must use the form ### Tn: title"))
        if current_id is None:
            if METADATA_PATTERN.match(line) or line.startswith("- ["):
                diagnostics.append(Diagnostic(line_number, "task content appears outside a recognized task block"))
            continue
        current_body.append((line_number, line))

    if current_id is not None:
        blocks.append(_TaskBlock(current_id, current_line, tuple(current_body)))
    if not blocks:
        diagnostics.append(Diagnostic(1, "tasks.md must contain at least one ### Tn: title task block"))
    return blocks, diagnostics


def _parse_task_block(block: _TaskBlock) -> tuple[Task | None, list[Diagnostic]]:
    diagnostics: list[Diagnostic] = []
    fields: dict[str, tuple[int, str]] = {}
    files_line = 0
    file_entries: list[tuple[int, str]] = []

    for position, (line_number, line) in enumerate(block.body):
        match = METADATA_PATTERN.match(line)
        if match:
            field_name, value = match.groups()
            if field_name in fields:
                diagnostics.append(Diagnostic(line_number, f"duplicate {field_name} field for {block.task_id}"))
            else:
                fields[field_name] = (line_number, value)
                if field_name == "Files":
                    files_line = line_number
                    following = block.body[position + 1 :]
                    for entry_line, entry in following:
                        if METADATA_PATTERN.match(entry):
                            break
                        if not entry:
                            break
                        if entry.startswith("- "):
                            file_entries.append((entry_line, entry))
                            continue
                        break

    for field_name in REQUIRED_FIELDS:
        if field_name not in fields:
            diagnostics.append(Diagnostic(block.line, f"missing {field_name} field for {block.task_id}"))

    if diagnostics:
        return None, diagnostics

    ac_line, ac_value = fields["AC"]
    ac_ids = _parse_csv(ac_value, AC_ID_PATTERN, "AC IDs", ac_line, diagnostics)
    delegable_line, delegable_value = fields["Delegable"]
    delegable = _parse_delegable(delegable_value, delegable_line, diagnostics)
    dependencies_line, dependencies_value = fields["Depends on"]
    dependencies = _parse_dependencies(dependencies_value, dependencies_line, diagnostics)
    integration_line, integration = fields["Integration"]
    integration = integration.strip()
    if integration not in {"isolated", "inline"}:
        diagnostics.append(Diagnostic(integration_line, "Integration must be isolated or inline"))
    validation_line, validation = fields["Validation"]
    validation = validation.strip()
    if not validation:
        diagnostics.append(Diagnostic(validation_line, "Validation must contain a command"))

    files = _parse_files(file_entries, files_line, integration, diagnostics)
    if delegable is not None and integration in {"isolated", "inline"}:
        if integration == "isolated" and not delegable:
            diagnostics.append(Diagnostic(integration_line, "Integration: isolated requires Delegable: yes"))
        if integration == "inline" and delegable:
            diagnostics.append(Diagnostic(integration_line, "Integration: inline requires Delegable: no"))

    if diagnostics or delegable is None:
        return None, diagnostics
    return Task(
        block.task_id, ac_ids, delegable, dependencies, files, integration, validation, block.line
    ), diagnostics


def validate_task_topology(text: str) -> ParseResult:
    """Return parser and dependency-wave diagnostics for a schema-2 document."""
    parsed = parse_task_document(text)
    diagnostics = list(parsed.diagnostics)
    if diagnostics:
        return parsed

    task_ids = {task.task_id for task in parsed.tasks}
    for task in parsed.tasks:
        for dependency in task.dependencies:
            if dependency == task.task_id:
                diagnostics.append(Diagnostic(task.line, f"{task.task_id} cannot depend on itself"))
            elif dependency not in task_ids:
                diagnostics.append(
                    Diagnostic(task.line, f"{task.task_id} depends on missing task {dependency}")
                )
    if diagnostics:
        return ParseResult(parsed.tasks, tuple(sorted(diagnostics, key=lambda item: item.line)))

    remaining = {task.task_id: task for task in parsed.tasks}
    completed: set[str] = set()
    while remaining:
        wave = [
            task
            for task in parsed.tasks
            if task.task_id in remaining and set(task.dependencies).issubset(completed)
        ]
        if not wave:
            cycle_ids = ", ".join(sorted(remaining))
            diagnostics.append(Diagnostic(1, f"dependency cycle among remaining tasks: {cycle_ids}"))
            break
        _validate_wave_ownership(wave, diagnostics)
        for task in wave:
            completed.add(task.task_id)
            del remaining[task.task_id]

    return ParseResult(parsed.tasks, tuple(sorted(diagnostics, key=lambda item: item.line)))


def _validate_wave_ownership(wave: list[Task], diagnostics: list[Diagnostic]) -> None:
    owners: dict[str, Task] = {}
    for task in wave:
        if task.integration != "isolated":
            continue
        for filename in task.files:
            previous = owners.get(filename)
            if previous is None:
                owners[filename] = task
                continue
            diagnostics.append(
                Diagnostic(
                    task.line,
                    f"independent same-wave ownership collision for {filename}: "
                    f"{previous.task_id}, {task.task_id}",
                )
            )


def validate_change_task_topology(change_text: str, tasks_text: str) -> ParseResult:
    """Apply the schema-1 policy before validating a schema-2 task document."""
    if _has_schema_two(tasks_text):
        result = validate_task_topology(tasks_text)
        if result.diagnostics:
            return result
        diagnostics: list[Diagnostic] = []
        change_ac_ids = set(_change_ac_ids(change_text))
        task_ac_ids = {
            ac_id
            for task in result.tasks
            for ac_id in task.ac_ids
        }
        for ac_id in sorted(change_ac_ids - task_ac_ids):
            diagnostics.append(
                Diagnostic(
                    1,
                    f"acceptance criterion {ac_id} is not covered by any task AC field",
                )
            )
        for task in result.tasks:
            for ac_id in task.ac_ids:
                if ac_id not in change_ac_ids:
                    diagnostics.append(
                        Diagnostic(
                            task.line,
                            f"{task.task_id} references missing acceptance criterion {ac_id}",
                        )
                    )
        return ParseResult(
            result.tasks,
            tuple(sorted(diagnostics, key=lambda item: item.line)),
        )

    status = _change_status(change_text)
    if status == "shipped":
        return ParseResult((), ())
    return ParseResult(
        (),
        (
            Diagnostic(
                1,
                "schema-1 tasks.md requires explicit schema-2 replanning "
                f"(change status: {status or 'missing'})",
            ),
        ),
    )


def _has_schema_two(text: str) -> bool:
    lines = text.splitlines()
    if not lines or lines[0] != "---":
        return False
    try:
        closing_index = lines.index("---", 1)
    except ValueError:
        return False
    return "tasks_schema: 2" in lines[1:closing_index]


def _change_status(text: str) -> str | None:
    lines = text.splitlines()
    if not lines or lines[0] != "---":
        return None
    try:
        closing_index = lines.index("---", 1)
    except ValueError:
        return None
    for line in lines[1:closing_index]:
        if line.startswith("status:"):
            return line.partition(":")[2].strip() or None
    return None


def _change_ac_ids(text: str) -> tuple[str, ...]:
    in_acceptance_criteria = False
    identifiers: list[str] = []
    for line in text.splitlines():
        if line == "## Acceptance Criteria":
            in_acceptance_criteria = True
            continue
        if in_acceptance_criteria and line.startswith("## "):
            break
        if not in_acceptance_criteria:
            continue
        match = re.match(r"^-\s+\[[ xX]\]\s+\*\*(AC-[1-9][0-9]*)\*\*", line)
        if match:
            identifiers.append(match.group(1))
    return tuple(identifiers)


def _parse_csv(value: str, pattern: re.Pattern[str], label: str, line: int, diagnostics: list[Diagnostic]) -> tuple[str, ...]:
    tokens = tuple(token.strip() for token in value.split(","))
    if not tokens or any(not token or not pattern.fullmatch(token) for token in tokens):
        diagnostics.append(Diagnostic(line, f"{label} must be comma-separated valid identifiers"))
        return ()
    return tokens


def _parse_delegable(value: str, line: int, diagnostics: list[Diagnostic]) -> bool | None:
    normalized = value.strip()
    match = DELEGABLE_PATTERN.fullmatch(normalized)
    if match is None:
        diagnostics.append(Diagnostic(line, "Delegable must begin with yes or no"))
        return None
    if match.group(1) == "yes":
        return True
    return False


def _parse_dependencies(value: str, line: int, diagnostics: list[Diagnostic]) -> tuple[str, ...]:
    normalized = value.strip()
    if normalized == "none":
        return ()
    return _parse_csv(normalized, TASK_ID_PATTERN, "Depends on", line, diagnostics)


def _parse_files(
    entries: list[tuple[int, str]], files_line: int, integration: str, diagnostics: list[Diagnostic]
) -> tuple[str, ...]:
    if entries == [(files_line + 1, "- None")]:
        if integration != "inline":
            diagnostics.append(Diagnostic(files_line + 1, "- None is allowed only for Integration: inline"))
        return ()
    if not entries:
        diagnostics.append(Diagnostic(files_line, "Files must list owned paths or exact - None"))
        return ()

    files: list[str] = []
    for line, entry in entries:
        symlink_match = SYMLINK_ENTRY_PATTERN.match(entry)
        if symlink_match:
            replacement, target = _split_symlink_entry(symlink_match.group(1))
            normalized_replacement = _normalize_repository_path(replacement)
            normalized_target = _normalize_repository_path(target)
            if normalized_replacement is None or normalized_target is None:
                diagnostics.append(Diagnostic(line, "Files paths must be safe repository-relative paths"))
                continue
            if integration == "isolated" and (
                _is_reserved_isolated_path(normalized_replacement)
                or _is_reserved_isolated_path(normalized_target)
            ):
                diagnostics.append(
                    Diagnostic(
                        line,
                        "isolated symlinks may not include .git or .specwright paths",
                    )
                )
                continue
            files.append(normalized_replacement)
            continue
        match = FILE_ENTRY_PATTERN.match(entry)
        if not match:
            diagnostics.append(
                Diagnostic(
                    line,
                    "Files entries must use - Create|Modify|Delete: path or - Replace with symlink: destination -> target",
                )
            )
            continue
        normalized = _normalize_repository_path(match.group(1))
        if normalized is None:
            diagnostics.append(Diagnostic(line, "Files paths must be safe repository-relative paths"))
            continue
        if integration == "isolated" and _is_reserved_isolated_path(normalized):
            diagnostics.append(
                Diagnostic(
                    line,
                    "isolated ownership may not include .git or .specwright paths",
                )
            )
            continue
        files.append(normalized)
    if integration == "isolated" and not files:
        diagnostics.append(Diagnostic(files_line, "Integration: isolated requires at least one owned file"))
    return tuple(files)


def _is_reserved_isolated_path(path: str) -> bool:
    return path.split("/", 1)[0].casefold() in {".git", ".specwright"}


def _split_symlink_entry(value: str) -> tuple[str, str]:
    expression = _strip_code_span(value.strip())
    replacement, separator, target = expression.partition(" -> ")
    if not separator:
        return "", ""
    return replacement, target


def _normalize_repository_path(value: str) -> str | None:
    candidate = _strip_code_span(value.strip())
    if (
        not candidate
        or "`" in candidate
        or "\\" in candidate
        or candidate.startswith("/")
        or any(character in candidate for character in "*?[]{}")
    ):
        return None
    path = PurePosixPath(candidate)
    if path.is_absolute() or any(part == ".." for part in path.parts):
        return None
    normalized_parts = tuple(part for part in path.parts if part != ".")
    if not normalized_parts or any(part in {"", "."} for part in normalized_parts):
        return None
    return "/".join(normalized_parts)


def _strip_code_span(value: str) -> str:
    if len(value) >= 2 and value.startswith("`") and value.endswith("`"):
        return value[1:-1]
    return value


def main(arguments: list[str]) -> int:
    if len(arguments) == 1:
        change_filename = None
        filename = arguments[0]
    elif len(arguments) == 3 and arguments[0] == "--change":
        change_filename = arguments[1]
        filename = arguments[2]
    else:
        print("usage: validate_task_topology.py [--change CHANGE_MD] TASKS_MD", file=sys.stderr)
        return 2
    try:
        with open(filename, encoding="utf-8") as task_file:
            tasks_text = task_file.read()
        if change_filename is None:
            result = validate_task_topology(tasks_text)
        else:
            with open(change_filename, encoding="utf-8") as change_file:
                result = validate_change_task_topology(change_file.read(), tasks_text)
    except OSError as error:
        print(f"{filename}: {error}", file=sys.stderr)
        return 2
    for diagnostic in result.diagnostics:
        print(f"{filename}:{diagnostic.line}: {diagnostic.message}", file=sys.stderr)
    return 1 if result.diagnostics else 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
