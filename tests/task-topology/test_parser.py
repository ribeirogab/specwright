#!/usr/bin/env python3
"""Focused coverage for schema-2 task syntax and metadata parsing."""

from __future__ import annotations

from pathlib import Path
import sys
import unittest


SCRIPT_DIRECTORY = Path(__file__).resolve().parents[2] / "plugins" / "sw" / "scripts"
sys.path.insert(0, str(SCRIPT_DIRECTORY))

from validate_task_topology import (
    parse_task_document,
    validate_issue_task_topology,
    validate_task_topology,
)


FIXTURES = Path(__file__).parent / "fixtures"
REPOSITORY_ROOT = Path(__file__).resolve().parents[2]


class TaskParserTests(unittest.TestCase):
    def test_valid_fixture_returns_normalized_metadata(self) -> None:
        result = parse_task_document((FIXTURES / "valid" / "tasks.md").read_text())

        self.assertEqual(result.diagnostics, ())
        self.assertEqual([task.task_id for task in result.tasks], ["T1", "T2", "T3"])
        self.assertEqual(result.tasks[0].ac_ids, ("AC-1", "AC-2"))
        self.assertTrue(result.tasks[0].delegable)
        self.assertEqual(result.tasks[0].dependencies, ())
        self.assertEqual(
            result.tasks[0].files,
            (
                "plugins/sw/scripts/validate_task_topology.py",
                "tests/task-topology/test_parser.py",
            ),
        )
        self.assertEqual(result.tasks[1].dependencies, ("T1",))
        self.assertEqual(result.tasks[1].files, ())
        self.assertFalse(result.tasks[2].delegable)
        self.assertEqual(result.tasks[2].files, ("CLAUDE.md",))

    def test_malformed_fixture_reports_line_numbered_diagnostics(self) -> None:
        result = parse_task_document((FIXTURES / "malformed" / "tasks.md").read_text())

        messages = {diagnostic.message for diagnostic in result.diagnostics}
        self.assertTrue(all(diagnostic.line > 0 for diagnostic in result.diagnostics))
        self.assertIn("duplicate task ID T1", messages)
        self.assertIn("Depends on must be comma-separated valid identifiers", messages)
        self.assertIn("Files paths must be safe repository-relative paths", messages)
        self.assertIn("Integration: inline requires Delegable: no", messages)
        self.assertIn("Validation must contain a command", messages)
        self.assertIn("Delegable must begin with yes or no", messages)
        self.assertIn("- None is allowed only for Integration: inline", messages)

    def test_schema_and_heading_are_strict(self) -> None:
        result = parse_task_document("---\ntasks_schema: 02\n---\n### Task 1: bad\n")

        messages = {diagnostic.message for diagnostic in result.diagnostics}
        self.assertIn("tasks_schema must be exactly 2", messages)
        self.assertIn("task headings must use the form ### Tn: title", messages)
        self.assertIn("tasks.md must contain at least one ### Tn: title task block", messages)

    def test_file_path_normalization_rejects_unsafe_spellings(self) -> None:
        result = parse_task_document(
            "---\ntasks_schema: 2\n---\n### T1: Normalize\n\n"
            "**AC:** AC-1\n**Delegable:** yes\n**Depends on:** none\n**Files:**\n"
            "- Create: ./plugins//sw/./script.py\n"
            "**Integration:** isolated\n**Validation:** python3 test.py\n"
        )

        self.assertEqual(result.diagnostics, ())
        self.assertEqual(result.tasks[0].files, ("plugins/sw/script.py",))

        unsafe = parse_task_document(
            "---\ntasks_schema: 2\n---\n### T1: Unsafe\n\n"
            "**AC:** AC-1\n**Delegable:** yes\n**Depends on:** none\n**Files:**\n"
            "- Create: /absolute.py\n- Modify: folder\\file.py\n"
            "**Integration:** isolated\n**Validation:** python3 test.py\n"
        )
        self.assertEqual(
            sum("safe repository-relative" in item.message for item in unsafe.diagnostics), 2
        )

    def test_required_fields_and_metadata_duplicates_are_rejected(self) -> None:
        result = parse_task_document(
            "---\ntasks_schema: 2\n---\n### T1: Incomplete\n\n"
            "**AC:** AC-1\n**AC:** AC-2\n**Delegable:** no\n"
            "**Depends on:** none\n**Files:**\n- None\n"
            "**Integration:** inline\n"
        )

        messages = {diagnostic.message for diagnostic in result.diagnostics}
        self.assertIn("duplicate AC field for T1", messages)
        self.assertIn("missing Validation field for T1", messages)

    def test_dependency_cycle_and_wave_collision_fixtures_are_rejected(self) -> None:
        expected = {
            "bad-task-dependency": "depends on missing task",
            "bad-task-cycle": "dependency cycle",
            "bad-task-collision": "same-wave ownership collision",
        }
        fixture_root = REPOSITORY_ROOT / "plugins" / "sw" / "scripts" / "fixtures"
        for name, fragment in expected.items():
            with self.subTest(name=name):
                result = validate_task_topology(
                    (fixture_root / name / "tasks.md").read_text()
                )
                self.assertTrue(
                    any(fragment in item.message for item in result.diagnostics),
                    result.diagnostics,
                )

    def test_legacy_policy_accepts_shipped_and_blocks_active(self) -> None:
        fixture_root = REPOSITORY_ROOT / "plugins" / "sw" / "scripts" / "fixtures"
        shipped = validate_issue_task_topology(
            (fixture_root / "legacy-shipped" / "issue.md").read_text(),
            (fixture_root / "legacy-shipped" / "tasks.md").read_text(),
        )
        active = validate_issue_task_topology(
            (fixture_root / "legacy-active" / "issue.md").read_text(),
            (fixture_root / "legacy-active" / "tasks.md").read_text(),
        )
        self.assertEqual(shipped.diagnostics, ())
        self.assertTrue(
            any("requires explicit schema-2 replanning" in item.message for item in active.diagnostics)
        )

    def test_ac_traceability_uses_only_task_metadata_and_rejects_unknown_ids(self) -> None:
        issue = (
            "---\nstatus: in-progress\n---\n"
            "## Acceptance Criteria\n\n"
            "- [ ] **AC-1** observable behavior\n"
        )
        tasks = (
            "---\ntasks_schema: 2\n---\n"
            "### T1: Wrong AC\n\n"
            "**AC:** AC-2\n"
            "**Delegable:** no\n"
            "**Depends on:** none\n"
            "**Files:**\n"
            "- None\n"
            "**Integration:** inline\n"
            "**Validation:** printf 'AC-1 appears only in prose'\n"
        )
        result = validate_issue_task_topology(issue, tasks)
        messages = {item.message for item in result.diagnostics}
        self.assertIn(
            "acceptance criterion AC-1 is not covered by any task AC field",
            messages,
        )
        self.assertIn("T1 references missing acceptance criterion AC-2", messages)

    def test_isolated_ownership_rejects_globs_and_reserved_state(self) -> None:
        entries = (
            "plugins/sw/**/*.py",
            ".git",
            ".git/config",
            ".GIT/config",
            ".specwright/issues/example/issue.md",
            ".SpecWright/issues/example/issue.md",
        )
        for path in entries:
            with self.subTest(path=path):
                result = parse_task_document(
                    "---\ntasks_schema: 2\n---\n"
                    "### T1: Unsafe ownership\n\n"
                    "**AC:** AC-1\n"
                    "**Delegable:** yes\n"
                    "**Depends on:** none\n"
                    "**Files:**\n"
                    f"- Modify: `{path}`\n"
                    "**Integration:** isolated\n"
                    "**Validation:** true\n"
                )
                self.assertTrue(result.diagnostics)
                self.assertTrue(
                    any(
                        "safe repository-relative" in item.message
                        or "isolated ownership may not include" in item.message
                        for item in result.diagnostics
                    )
                )

    def test_isolated_symlinks_reject_reserved_destinations_and_targets(self) -> None:
        entries = (
            ".GIT/config -> safe-target",
            "safe-link -> .git/config",
            "safe-link -> .SPECWRIGHT/issues/example/issue.md",
        )
        for entry in entries:
            with self.subTest(entry=entry):
                result = parse_task_document(
                    "---\ntasks_schema: 2\n---\n"
                    "### T1: Unsafe symlink\n\n"
                    "**AC:** AC-1\n"
                    "**Delegable:** yes\n"
                    "**Depends on:** none\n"
                    "**Files:**\n"
                    f"- Replace with symlink: `{entry}`\n"
                    "**Integration:** isolated\n"
                    "**Validation:** true\n"
                )
                self.assertTrue(
                    any(
                        "isolated symlinks may not include" in item.message
                        for item in result.diagnostics
                    ),
                    result.diagnostics,
                )

    def test_approved_issue_tasks_have_no_parser_layer_diagnostics(self) -> None:
        issue_tasks = REPOSITORY_ROOT / ".specwright" / "issues" / "2026-07-28-dual-host-safe-worker-orchestration" / "tasks.md"
        result = parse_task_document(issue_tasks.read_text())

        self.assertEqual(result.diagnostics, ())
        self.assertEqual(result.tasks[14].task_id, "T15")
        self.assertEqual(result.tasks[14].files[1], "CLAUDE.md")


if __name__ == "__main__":
    result = unittest.main(exit=False)
    if result.result.wasSuccessful():
        print("task parser: PASS")
    raise SystemExit(0 if result.result.wasSuccessful() else 1)
