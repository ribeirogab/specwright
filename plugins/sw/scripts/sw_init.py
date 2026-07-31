#!/usr/bin/env python3
"""Idempotent specwright project scaffolder.

Creates what a repository needs to run the specwright workflow and touches
nothing that already exists. Re-running it is the upgrade path: every path is
reported as ``created`` or ``present``, and a second run writes nothing.

A conflict — a path that exists in a shape the scaffolder cannot use, such as a
Claude adapter that is a regular file instead of the required symlink — is
reported before any write happens, and nothing is written at all. The scaffolder
never overwrites, never repairs, and never decides on the maintainer's behalf.

Usage:
    sw_init.py --project PATH --mode {shared,local} [--format {text,json}]
"""

from __future__ import annotations

import argparse
import json
import os
import shutil
import sys
from dataclasses import dataclass, field
from pathlib import Path

PLUGIN_ROOT = Path(__file__).resolve().parent.parent
PROFILE_NAMES = ("sw-change-owner.toml", "sw-reviewer.toml")

SHARED_IGNORE_LINES = (".specwright/worktrees/",)
LOCAL_IGNORE_LINES = (
    ".specwright/worktrees/",
    ".specwright/",
    "AGENTS.override.md",
    "CLAUDE.local.md",
    ".codex/agents/sw-*.toml",
)

CANONICAL_BY_MODE = {"shared": "AGENTS.md", "local": "AGENTS.override.md"}
ADAPTER_BY_MODE = {"shared": "CLAUDE.md", "local": "CLAUDE.local.md"}

SECTION_HEADING = "## specwright"
SECTION = """## specwright

This repository uses specwright for change-driven work. The vault is
`.specwright/`: changes in `changes/`, deliveries in `deliveries/`, project
conventions in `conventions/`.

- For feature work, suggest `/sw:change` to the user instead of starting the
  workflow yourself. Do not implement a feature without offering it first.
- While a change is in progress, read its `change.md` and `plan.md` before
  touching the code it covers.
- A trivial change needs no artifacts. Edit the code directly.
- Verification — tests, lint, typecheck, build — runs at the `implement` or
  `ship` step, or when the user asks for it. After a direct edit outside the
  workflow, stop and report what changed and what was left unverified; do not
  run gates on your own initiative.

Host surfaces: `/sw:*` in Claude Code, `$sw:*` in Codex. Host permissions and
sandbox policy remain authoritative; nothing here grants permission to write
files, run commands, create branches, commit, push, or reach a network service.
"""

CONVENTIONS_SIGNPOST = """# About this folder — signpost, not a convention

`sw:review` reads every other file in `.specwright/conventions/` as a project
standard it must enforce. This file states no rule. Delete it when the project
adds its first convention.

Keep one project-specific convention per file: code style, naming, architecture,
testing, domain rules, review preferences, or any other durable standard.
"""


class InitError(Exception):
    """A condition the scaffolder refuses to resolve on its own."""


@dataclass
class Report:
    mode: str
    project: str
    actions: list[dict[str, str]] = field(default_factory=list)
    conflicts: list[str] = field(default_factory=list)

    def record(self, path: str, result: str) -> None:
        self.actions.append({"path": path, "result": result})

    @property
    def created(self) -> int:
        return sum(1 for action in self.actions if action["result"] in ("created", "updated"))

    @property
    def present(self) -> int:
        return sum(1 for action in self.actions if action["result"].startswith("present"))

    def as_dict(self) -> dict[str, object]:
        return {
            "mode": self.mode,
            "project": self.project,
            "actions": self.actions,
            "conflicts": self.conflicts,
            "created": self.created,
            "present": self.present,
        }


def ignore_lines(mode: str) -> tuple[str, ...]:
    return LOCAL_IGNORE_LINES if mode == "local" else SHARED_IGNORE_LINES


def find_conflicts(project: Path, mode: str) -> list[str]:
    """Every reason the scaffolder must not write, collected in one pass."""
    conflicts: list[str] = []
    canonical = project / CANONICAL_BY_MODE[mode]
    adapter = project / ADAPTER_BY_MODE[mode]

    if canonical.is_symlink() or (canonical.exists() and not canonical.is_file()):
        conflicts.append(
            f"{CANONICAL_BY_MODE[mode]} must be a regular file; found "
            f"{'a symlink' if canonical.is_symlink() else 'a directory'}"
        )
    if adapter.is_symlink():
        target = os.readlink(adapter)
        if target != CANONICAL_BY_MODE[mode]:
            conflicts.append(
                f"{ADAPTER_BY_MODE[mode]} points at {target!r}; expected "
                f"{CANONICAL_BY_MODE[mode]!r}"
            )
    elif adapter.exists():
        conflicts.append(
            f"{ADAPTER_BY_MODE[mode]} exists as a regular file; specwright needs it to be "
            f"a relative symlink to {CANONICAL_BY_MODE[mode]}. Move or delete it, then re-run."
        )

    for name in PROFILE_NAMES:
        if not (PLUGIN_ROOT / "templates" / "codex-agents" / name).is_file():
            conflicts.append(f"bundled template missing: templates/codex-agents/{name}")

    gitignore = project / ".gitignore"
    if gitignore.exists() and not gitignore.is_file():
        conflicts.append(".gitignore exists but is not a regular file")

    return conflicts


def scaffold_vault(project: Path, report: Report) -> None:
    conventions = project / ".specwright" / "conventions"
    conventions.mkdir(parents=True, exist_ok=True)
    # An existing conventions directory keeps its own files; the signpost is
    # only for a directory that would otherwise be empty and unexplained.
    if any(conventions.iterdir()):
        report.record(".specwright/conventions/", "present")
    else:
        (conventions / "README.md").write_text(CONVENTIONS_SIGNPOST, encoding="utf-8")
        report.record(".specwright/conventions/README.md", "created")

    for name in ("changes", "deliveries"):
        directory = project / ".specwright" / name
        directory.mkdir(parents=True, exist_ok=True)
        keep = directory / ".gitkeep"
        if keep.exists():
            report.record(f".specwright/{name}/.gitkeep", "present")
        else:
            keep.write_text("", encoding="utf-8")
            report.record(f".specwright/{name}/.gitkeep", "created")


def write_section(project: Path, mode: str, report: Report) -> None:
    canonical = project / CANONICAL_BY_MODE[mode]
    relative = CANONICAL_BY_MODE[mode]

    if not canonical.exists():
        canonical.write_text(SECTION, encoding="utf-8")
        report.record(relative, "created")
    else:
        existing = canonical.read_text(encoding="utf-8")
        if any(line.strip() == SECTION_HEADING for line in existing.splitlines()):
            report.record(relative, "present")
        else:
            separator = "" if existing.endswith("\n\n") else ("\n" if existing.endswith("\n") else "\n\n")
            canonical.write_text(existing + separator + SECTION, encoding="utf-8")
            report.record(relative, "created")


def write_adapter(project: Path, mode: str, report: Report) -> None:
    adapter = project / ADAPTER_BY_MODE[mode]
    if adapter.is_symlink():
        report.record(ADAPTER_BY_MODE[mode], "present")
        return
    try:
        os.symlink(CANONICAL_BY_MODE[mode], adapter)
    except OSError as error:
        raise InitError(
            f"cannot create the {ADAPTER_BY_MODE[mode]} symlink: {error}. specwright has no "
            "regular-file fallback — the adapter must be a relative symlink to "
            f"{CANONICAL_BY_MODE[mode]}."
        ) from error
    report.record(ADAPTER_BY_MODE[mode], "created")


def write_profiles(project: Path, report: Report) -> None:
    destination = project / ".codex" / "agents"
    destination.mkdir(parents=True, exist_ok=True)
    for name in PROFILE_NAMES:
        template = PLUGIN_ROOT / "templates" / "codex-agents" / name
        installed = destination / name
        relative = f".codex/agents/{name}"
        if not installed.exists():
            shutil.copyfile(template, installed)
            report.record(relative, "created")
            continue
        # A profile the maintainer edited stays theirs; say so instead of
        # overwriting it or calling it drift.
        same = installed.read_bytes() == template.read_bytes()
        report.record(relative, "present" if same else "present (differs from template)")


def write_ignore_rules(project: Path, mode: str, report: Report) -> None:
    gitignore = project / ".gitignore"
    existing = gitignore.read_text(encoding="utf-8") if gitignore.exists() else ""
    present = {line.strip() for line in existing.splitlines()}
    missing = [line for line in ignore_lines(mode) if line not in present]

    if not missing:
        report.record(".gitignore", "present")
        return

    prefix = "" if not existing or existing.endswith("\n") else "\n"
    gitignore.write_text(existing + prefix + "\n".join(missing) + "\n", encoding="utf-8")
    report.record(".gitignore", "created" if not existing else "updated")


def initialize(project: Path, mode: str) -> Report:
    if not project.is_dir():
        raise InitError(f"not a directory: {project}")

    report = Report(mode=mode, project=str(project))
    conflicts = find_conflicts(project, mode)
    if conflicts:
        report.conflicts = conflicts
        return report

    scaffold_vault(project, report)
    write_section(project, mode, report)
    write_adapter(project, mode, report)
    write_profiles(project, report)
    write_ignore_rules(project, mode, report)
    return report


def render_text(report: Report) -> str:
    lines = [f"specwright init — mode: {report.mode}"]
    if report.conflicts:
        lines.append("")
        lines.extend(f"CONFLICT: {conflict}" for conflict in report.conflicts)
        lines.append("")
        lines.append("Nothing was written. Resolve the conflicts above and re-run.")
        return "\n".join(lines)
    lines.extend(f"  {action['result']:<28} {action['path']}" for action in report.actions)
    lines.append("")
    lines.append(f"{report.created} created, {report.present} already present.")
    return "\n".join(lines)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Scaffold specwright project state.")
    parser.add_argument("--project", required=True, type=Path)
    parser.add_argument("--mode", required=True, choices=("shared", "local"))
    parser.add_argument("--format", default="text", choices=("text", "json"))
    arguments = parser.parse_args(argv)

    try:
        report = initialize(arguments.project.resolve(), arguments.mode)
    except InitError as error:
        print(f"FAIL: {error}", file=sys.stderr)
        return 1

    if arguments.format == "json":
        print(json.dumps(report.as_dict(), indent=2))
    else:
        print(render_text(report))
    return 1 if report.conflicts else 0


if __name__ == "__main__":
    raise SystemExit(main())
