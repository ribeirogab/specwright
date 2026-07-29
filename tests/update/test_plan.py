#!/usr/bin/env python3
"""Focused coverage for the pure specwright update planner."""

from __future__ import annotations

from contextlib import redirect_stdout
import io
import json
from pathlib import Path
import shutil
import sys
import tempfile
import unittest


REPOSITORY_ROOT = Path(__file__).resolve().parents[2]
SCRIPT_DIRECTORY = REPOSITORY_ROOT / "plugins" / "sw" / "scripts"
sys.path.insert(0, str(SCRIPT_DIRECTORY))

from sw_update import LEGACY_GENERIC_TEMPLATE, is_calendar_version, main, plan_as_dict, plan_update, render_managed_block


FIXTURES = Path(__file__).parent / "fixtures"


class UpdatePlanTests(unittest.TestCase):
    def test_calendar_versions_require_unpadded_real_dates(self) -> None:
        self.assertTrue(is_calendar_version("2026.7.28"))
        self.assertFalse(is_calendar_version("2026.07.28"))
        self.assertFalse(is_calendar_version("2026-07-28"))
        self.assertFalse(is_calendar_version("2026.2.30"))

    def test_new_project_has_a_deterministic_plan_without_writes(self) -> None:
        with self._fixture_copy("new") as project:
            before = self._tree_snapshot(project)
            first = plan_update(project, "shared")
            second = plan_update(project, "shared")
            self.assertEqual(first.state, "new")
            self.assertEqual(first.plan_id, second.plan_id)
            self.assertEqual(plan_as_dict(first), plan_as_dict(second))
            self.assertEqual([item.relative_path for item in first.observed], sorted(item.relative_path for item in first.observed))
            self.assertEqual(before, self._tree_snapshot(project))
            self.assertEqual([item.relative_path for item in first.operations], [
                "AGENTS.md",
                "CLAUDE.md",
                ".codex/agents/sw-issue-owner.toml",
                ".codex/agents/sw-spec-document-reviewer.toml",
                ".codex/agents/sw-reviewer.toml",
                ".codex/agents/sw-task-worker.toml",
                ".gitignore",
            ])

    def test_matching_managed_state_is_up_to_date(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            project = Path(directory)
            agents = project / "AGENTS.md"
            agents.write_text("before\n" + render_managed_block("2026.7.28") + "\nafter\n")
            (project / "CLAUDE.md").symlink_to("AGENTS.md")
            destination = project / ".codex" / "agents"
            destination.mkdir(parents=True)
            for source in sorted((REPOSITORY_ROOT / "plugins/sw/templates/codex-agents").glob("sw-*.toml")):
                shutil.copyfile(source, destination / source.name)
            (project / ".gitignore").write_text(".specwright/worktrees/\n")
            plan = plan_update(project, "shared")
            self.assertEqual(plan.state, "up-to-date")
            self.assertEqual(plan.operations, ())

    def test_bad_managed_digest_is_drifted(self) -> None:
        with self._fixture_copy("drifted") as project:
            plan = plan_update(project, "shared")
            self.assertEqual(plan.state, "drifted")
            self.assertEqual(plan.operations, ())

    def test_current_claude_only_repository_shape_is_legacy_migratable(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            project = Path(directory)
            source = REPOSITORY_ROOT / "CLAUDE.md"
            legacy = project / "CLAUDE.md"
            legacy.write_bytes(source.read_bytes())
            before = legacy.read_bytes()
            plan = plan_update(project, "shared")
            self.assertEqual(plan.state, "legacy-migratable")
            self.assertEqual(legacy.read_bytes(), before)
            desired = plan.operations[0].desired_after
            self.assertTrue(desired.startswith("# specwright — Agent Instructions\n\nInstructions for AI coding assistants"))
            self.assertIn("<!-- sw:managed version=2026.7.28", desired)
            self.assertIn("### Editing the bundled skills", desired)
            self.assertNotIn("## Workflow Spec Driven", desired)

    def test_exact_generic_shared_and_local_legacy_shapes_are_migratable(self) -> None:
        legacy = LEGACY_GENERIC_TEMPLATE.replace("{{Project Name}}", "Example").replace("{{project}}", "example")
        with tempfile.TemporaryDirectory() as directory:
            project = Path(directory)
            (project / "CLAUDE.md").write_text(legacy)
            shared = plan_update(project, "shared")
            self.assertEqual(shared.state, "legacy-migratable")
            self.assertEqual(shared.operations[0].desired_after, render_managed_block("2026.7.28"))
        with tempfile.TemporaryDirectory() as directory:
            project = Path(directory)
            (project / "CLAUDE.local.md").write_text(legacy)
            local = plan_update(project, "local")
            self.assertEqual(local.state, "legacy-migratable")
            self.assertEqual(local.operations[0].relative_path, "AGENTS.override.md")
            self.assertEqual(local.operations[-1].desired_after.splitlines(), [
                ".specwright/worktrees/",
                ".specwright/",
                "AGENTS.override.md",
                "CLAUDE.local.md",
                ".codex/agents/sw-*.toml",
            ])

    def test_edited_legacy_like_file_is_drifted(self) -> None:
        legacy = LEGACY_GENERIC_TEMPLATE.replace("{{Project Name}}", "Example").replace("{{project}}", "example")
        edited = legacy.replace("## Coding standard", "## Coding standard\n\nProject-owned edit.")
        with tempfile.TemporaryDirectory() as directory:
            project = Path(directory)
            (project / "CLAUDE.md").write_text(edited)
            self.assertEqual(plan_update(project, "shared").state, "drifted")

    def test_legacy_with_a_conflicting_managed_profile_is_drifted(self) -> None:
        legacy = LEGACY_GENERIC_TEMPLATE.replace("{{Project Name}}", "Example").replace("{{project}}", "example")
        with tempfile.TemporaryDirectory() as directory:
            project = Path(directory)
            (project / "CLAUDE.md").write_text(legacy)
            destination = project / ".codex" / "agents"
            destination.mkdir(parents=True)
            shutil.copyfile(REPOSITORY_ROOT / "plugins/sw/templates/codex-agents/sw-reviewer.toml", destination / "sw-reviewer.toml")
            self.assertEqual(plan_update(project, "shared").state, "drifted")

    def test_unexpected_adapter_kind_is_drifted(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            project = Path(directory)
            (project / "AGENTS.md").write_text(render_managed_block("2026.7.28"))
            (project / "CLAUDE.md").write_text("not a symlink")
            self.assertEqual(plan_update(project, "shared").state, "drifted")

    def test_legacy_adapter_symlink_is_drifted_without_following_it(self) -> None:
        legacy = LEGACY_GENERIC_TEMPLATE.replace("{{Project Name}}", "Example").replace("{{project}}", "example")
        with tempfile.TemporaryDirectory() as directory:
            project = Path(directory)
            target = project / "legacy-source.md"
            target.write_text(legacy)
            (project / "CLAUDE.md").symlink_to(target.name)
            self.assertEqual(plan_update(project, "shared").state, "drifted")

    def test_unexpected_canonical_kind_and_partial_profiles_are_drifted(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            project = Path(directory)
            (project / "AGENTS.md").mkdir()
            self.assertEqual(plan_update(project, "shared").state, "drifted")

    def test_duplicate_or_malformed_managed_markers_are_drifted(self) -> None:
        block = render_managed_block("2026.7.28")
        with tempfile.TemporaryDirectory() as directory:
            project = Path(directory)
            (project / "AGENTS.md").write_text(block + "\n" + block)
            self.assertEqual(plan_update(project, "shared").state, "drifted")
        with tempfile.TemporaryDirectory() as directory:
            project = Path(directory)
            malformed = block.replace("<!-- /sw:managed -->", "<!-- /sw:managed extra -->")
            (project / "AGENTS.md").write_text(malformed)
            self.assertEqual(plan_update(project, "shared").state, "drifted")
        with tempfile.TemporaryDirectory() as directory:
            project = Path(directory)
            (project / "AGENTS.md").write_text(render_managed_block("2026.7.28"))
            (project / "CLAUDE.md").symlink_to("AGENTS.md")
            destination = project / ".codex" / "agents"
            destination.mkdir(parents=True)
            source = REPOSITORY_ROOT / "plugins/sw/templates/codex-agents/sw-issue-owner.toml"
            shutil.copyfile(source, destination / source.name)
            (project / ".gitignore").write_text(".specwright/worktrees/\n")
            self.assertEqual(plan_update(project, "shared").state, "drifted")

    def test_json_output_is_canonical_and_pure(self) -> None:
        with self._fixture_copy("new") as project:
            before = self._tree_snapshot(project)
            output = io.StringIO()
            with redirect_stdout(output):
                result = main(["--plan", "--project", str(project), "--mode", "local", "--format", "json"])
            self.assertEqual(result, 0)
            self.assertEqual(json.loads(output.getvalue())["state"], "new")
            self.assertEqual(before, self._tree_snapshot(project))
            plan = plan_update(project, "local")
            encoded = json.dumps(plan_as_dict(plan), sort_keys=True, separators=(",", ":"), ensure_ascii=True)
            self.assertEqual(encoded, json.dumps(json.loads(encoded), sort_keys=True, separators=(",", ":"), ensure_ascii=True))
            self.assertEqual(plan.operations[-1].desired_after.splitlines(), [
                ".specwright/worktrees/",
                ".specwright/",
                "AGENTS.override.md",
                "CLAUDE.local.md",
                ".codex/agents/sw-*.toml",
            ])

    def _fixture_copy(self, name: str):
        directory = tempfile.TemporaryDirectory()
        project = Path(directory.name) / "project"
        shutil.copytree(FIXTURES / name, project)
        return _TemporaryProject(directory, project)

    @staticmethod
    def _tree_snapshot(project: Path) -> tuple[tuple[str, bytes], ...]:
        return tuple(sorted(
            (path.relative_to(project).as_posix(), path.read_bytes())
            for path in project.rglob("*")
            if path.is_file() and not path.is_symlink()
        ))


class _TemporaryProject:
    def __init__(self, directory: tempfile.TemporaryDirectory[str], project: Path) -> None:
        self.directory = directory
        self.project = project

    def __enter__(self) -> Path:
        return self.project

    def __exit__(self, exception_type: object, exception: object, traceback: object) -> None:
        self.directory.cleanup()


if __name__ == "__main__":
    result = unittest.main(exit=False)
    if result.result.wasSuccessful():
        print("update planner: PASS")
    raise SystemExit(0 if result.result.wasSuccessful() else 1)
