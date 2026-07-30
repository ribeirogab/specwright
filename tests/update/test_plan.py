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
from unittest import mock


REPOSITORY_ROOT = Path(__file__).resolve().parents[2]
SCRIPT_DIRECTORY = REPOSITORY_ROOT / "plugins" / "sw" / "scripts"
sys.path.insert(0, str(SCRIPT_DIRECTORY))

import sw_update
from sw_update import (
    UpdateError,
    WriteFailure,
    apply_update,
    is_calendar_version,
    main,
    plan_as_dict,
    plan_update,
    render_managed_block,
)


FIXTURES = Path(__file__).parent / "fixtures"
INSTALLED_VERSION = sw_update.load_installed_version()
UNRECOGNIZED_CONTENT = "# Project Claude instructions\n\nUnrecognized pre-managed content.\n"


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
            self.assertEqual(len(first.observed), 20)
            self.assertEqual(before, self._tree_snapshot(project))
            self.assertEqual([item.relative_path for item in first.operations], [
                "AGENTS.md",
                "CLAUDE.md",
                ".codex/agents/sw-change-owner.toml",
                ".codex/agents/sw-spec-document-reviewer.toml",
                ".codex/agents/sw-reviewer.toml",
                ".codex/agents/sw-task-worker.toml",
                ".opencode/agent/sw-change-owner.md",
                ".opencode/agent/sw-reviewer.md",
                ".opencode/agent/sw-spec-document-reviewer.md",
                ".opencode/agent/sw-task-worker.md",
                ".opencode/command/sw-brainstorm.md",
                ".opencode/command/sw-init.md",
                ".opencode/command/sw-plan.md",
                ".opencode/command/sw-pr.md",
                ".opencode/command/sw-review-spec.md",
                ".opencode/command/sw-review.md",
                ".opencode/command/sw-run.md",
                ".opencode/command/sw-spec.md",
                ".opencode/command/sw-update.md",
                ".gitignore",
            ])

    def test_matching_managed_state_is_up_to_date(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            project = Path(directory)
            agents = project / "AGENTS.md"
            agents.write_text("before\n" + render_managed_block(INSTALLED_VERSION) + "\nafter\n")
            (project / "CLAUDE.md").symlink_to("AGENTS.md")
            destination = project / ".codex" / "agents"
            destination.mkdir(parents=True)
            for source in sorted((REPOSITORY_ROOT / "plugins/sw/templates/codex-agents").glob("sw-*.toml")):
                shutil.copyfile(source, destination / source.name)
            self._install_opencode_files(project)
            (project / ".gitignore").write_text(".specwright/worktrees/\n")
            plan = plan_update(project, "shared")
            self.assertEqual(plan.state, "up-to-date")
            self.assertEqual(plan.operations, ())

    def test_bad_managed_digest_is_drifted(self) -> None:
        with self._fixture_copy("drifted") as project:
            plan = plan_update(project, "shared")
            self.assertEqual(plan.state, "drifted")
            self.assertEqual(plan.operations, ())

    def test_unrecognized_shared_and_local_shapes_are_drifted(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            project = Path(directory)
            (project / "CLAUDE.md").write_text(UNRECOGNIZED_CONTENT)
            shared = plan_update(project, "shared")
            self.assertEqual(shared.state, "drifted")
            self.assertEqual(shared.operations, ())
        with tempfile.TemporaryDirectory() as directory:
            project = Path(directory)
            (project / "CLAUDE.local.md").write_text(UNRECOGNIZED_CONTENT)
            local = plan_update(project, "local")
            self.assertEqual(local.state, "drifted")
            self.assertEqual(local.operations, ())

    def test_edited_unrecognized_file_is_drifted(self) -> None:
        edited = UNRECOGNIZED_CONTENT + "\nProject-owned edit.\n"
        with tempfile.TemporaryDirectory() as directory:
            project = Path(directory)
            (project / "CLAUDE.md").write_text(edited)
            self.assertEqual(plan_update(project, "shared").state, "drifted")

    def test_unrecognized_shape_with_a_conflicting_managed_profile_is_drifted(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            project = Path(directory)
            (project / "CLAUDE.md").write_text(UNRECOGNIZED_CONTENT)
            destination = project / ".codex" / "agents"
            destination.mkdir(parents=True)
            shutil.copyfile(REPOSITORY_ROOT / "plugins/sw/templates/codex-agents/sw-reviewer.toml", destination / "sw-reviewer.toml")
            self.assertEqual(plan_update(project, "shared").state, "drifted")

    def test_unexpected_adapter_kind_is_drifted(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            project = Path(directory)
            (project / "AGENTS.md").write_text(render_managed_block(INSTALLED_VERSION))
            (project / "CLAUDE.md").write_text("not a symlink")
            self.assertEqual(plan_update(project, "shared").state, "drifted")

    def test_unrecognized_adapter_symlink_is_drifted_without_following_it(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            project = Path(directory)
            target = project / "unrecognized-source.md"
            target.write_text(UNRECOGNIZED_CONTENT)
            (project / "CLAUDE.md").symlink_to(target.name)
            self.assertEqual(plan_update(project, "shared").state, "drifted")

    def test_unexpected_canonical_kind_and_partial_profiles_are_drifted(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            project = Path(directory)
            (project / "AGENTS.md").mkdir()
            self.assertEqual(plan_update(project, "shared").state, "drifted")

    def test_duplicate_or_malformed_managed_markers_are_drifted(self) -> None:
        block = render_managed_block(INSTALLED_VERSION)
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
            (project / "AGENTS.md").write_text(render_managed_block(INSTALLED_VERSION))
            (project / "CLAUDE.md").symlink_to("AGENTS.md")
            destination = project / ".codex" / "agents"
            destination.mkdir(parents=True)
            source = REPOSITORY_ROOT / "plugins/sw/templates/codex-agents/sw-change-owner.toml"
            shutil.copyfile(source, destination / source.name)
            (project / ".gitignore").write_text(".specwright/worktrees/\n")
            self.assertEqual(plan_update(project, "shared").state, "drifted")

    def test_malformed_or_unknown_managed_versions_are_drifted(self) -> None:
        for version in ("garbage", "2026.7.26"):
            with self.subTest(version=version), tempfile.TemporaryDirectory() as directory:
                project = Path(directory)
                block = render_managed_block(INSTALLED_VERSION).replace(
                    f"version={INSTALLED_VERSION}",
                    f"version={version}",
                    1,
                )
                (project / "AGENTS.md").write_text(block)
                (project / "CLAUDE.md").symlink_to("AGENTS.md")
                self._install_profiles(project)
                (project / ".gitignore").write_text(".specwright/worktrees/\n")
                plan = plan_update(project, "shared")
                self.assertEqual(plan.state, "drifted")
                self.assertEqual(plan.operations, ())

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
                ".opencode/agent/sw-*.md",
                ".opencode/command/sw-*.md",
            ])

    def test_json_apply_cli_forwards_the_confirmed_plan(self) -> None:
        with self._fixture_copy("new") as project:
            plan = plan_update(project, "shared")
            output = io.StringIO()
            with redirect_stdout(output):
                result = main(
                    [
                        "--apply",
                        "--expect-plan",
                        plan.plan_id,
                        "--project",
                        str(project),
                        "--mode",
                        "shared",
                        "--format",
                        "json",
                    ]
                )
            self.assertEqual(result, 0)
            payload = json.loads(output.getvalue())
            self.assertEqual(payload["plan_id"], plan.plan_id)
            self.assertEqual(payload["applied"][0:2], ["AGENTS.md", "CLAUDE.md"])
            self.assertEqual(plan_update(project, "shared").state, "up-to-date")

    def test_apply_rejects_an_identity_mismatch_without_writes(self) -> None:
        with self._fixture_copy("new") as project:
            plan = plan_update(project, "shared")
            (project / ".gitignore").write_text("changed-after-confirmation\n")
            before = self._full_tree_snapshot(project)
            with self.assertRaisesRegex(UpdateError, "identity does not match"):
                apply_update(project, "shared", plan.plan_id)
            self.assertEqual(before, self._full_tree_snapshot(project))

    def test_apply_rejects_drift_and_destination_collision_without_writes(self) -> None:
        with self._fixture_copy("drifted") as project:
            plan = plan_update(project, "shared")
            before = self._full_tree_snapshot(project)
            with self.assertRaisesRegex(UpdateError, "drifted"):
                apply_update(project, "shared", plan.plan_id)
            self.assertEqual(before, self._full_tree_snapshot(project))
        with self._fixture_copy("new") as project:
            plan = plan_update(project, "shared")
            (project / "AGENTS.md").write_text("occupied\n")
            before = self._full_tree_snapshot(project)
            with self.assertRaisesRegex(UpdateError, "identity does not match"):
                apply_update(project, "shared", plan.plan_id)
            self.assertEqual(before, self._full_tree_snapshot(project))
        with self._fixture_copy("new") as project:
            (project / "CLAUDE.md").symlink_to("unexpected-target.md")
            plan = plan_update(project, "shared")
            self.assertEqual(plan.state, "drifted")
            before = self._full_tree_snapshot(project)
            with self.assertRaisesRegex(UpdateError, "drifted"):
                apply_update(project, "shared", plan.plan_id)
            self.assertEqual(before, self._full_tree_snapshot(project))

    def test_preflight_rejects_unwritable_or_invalid_parents_without_writes(self) -> None:
        with self._fixture_copy("new") as project:
            plan = plan_update(project, "shared")
            before = self._full_tree_snapshot(project)
            with mock.patch.object(sw_update.os, "access", return_value=False):
                with self.assertRaisesRegex(UpdateError, "not writable"):
                    apply_update(project, "shared", plan.plan_id)
            self.assertEqual(before, self._full_tree_snapshot(project))
        with self._fixture_copy("new") as project:
            (project / ".codex").write_text("not a directory\n")
            plan = plan_update(project, "shared")
            self.assertIn("blocked-parent", {item.kind for item in plan.observed})
            before = self._full_tree_snapshot(project)
            with self.assertRaisesRegex(UpdateError, "managed parent is not a directory"):
                apply_update(project, "shared", plan.plan_id)
            self.assertEqual(before, self._full_tree_snapshot(project))

    def test_preflight_requires_real_symlink_support_without_fallback(self) -> None:
        with self._fixture_copy("new") as project:
            plan = plan_update(project, "local")
            before = self._full_tree_snapshot(project)
            with mock.patch.object(
                sw_update.os,
                "symlink",
                side_effect=OSError("symlinks disabled"),
            ):
                with self.assertRaisesRegex(UpdateError, "no regular-file fallback"):
                    apply_update(project, "local", plan.plan_id)
            self.assertEqual(before, self._full_tree_snapshot(project))

    def test_unrecognized_shapes_refuse_apply_without_writes(self) -> None:
        cases = (
            ("shared", "CLAUDE.md"),
            ("local", "CLAUDE.local.md"),
        )
        for mode, adapter in cases:
            with self.subTest(mode=mode), tempfile.TemporaryDirectory() as directory:
                project = Path(directory)
                (project / adapter).write_text(UNRECOGNIZED_CONTENT)
                (project / ".gitignore").write_text("custom-rule/\n")
                (project / ".codex").mkdir()
                (project / ".codex" / "custom.toml").write_text("preserve = true\n")
                plan = plan_update(project, mode)
                self.assertEqual(plan.state, "drifted")
                before = self._full_tree_snapshot(project)
                with self.assertRaisesRegex(UpdateError, "drifted"):
                    apply_update(project, mode, plan.plan_id)
                self.assertEqual(before, self._full_tree_snapshot(project))
                self.assertEqual((project / adapter).read_text(), UNRECOGNIZED_CONTENT)
                self.assertEqual(
                    (project / ".codex" / "custom.toml").read_text(),
                    "preserve = true\n",
                )

    def test_local_mode_preserves_existing_shared_project_instructions(self) -> None:
        with self._fixture_copy("new") as project:
            shared_agents = b"# Team AGENTS instructions\n"
            shared_claude = b"# Team Claude instructions\n"
            (project / "AGENTS.md").write_bytes(shared_agents)
            (project / "CLAUDE.md").write_bytes(shared_claude)
            plan = plan_update(project, "local")
            self.assertEqual(plan.state, "new")
            apply_update(project, "local", plan.plan_id)
            self.assertEqual((project / "AGENTS.md").read_bytes(), shared_agents)
            self.assertEqual((project / "CLAUDE.md").read_bytes(), shared_claude)
            self.assertTrue((project / "AGENTS.override.md").is_file())
            self.assertEqual(
                (project / "CLAUDE.local.md").readlink(),
                Path("AGENTS.override.md"),
            )

    def test_managed_block_update_preserves_exact_project_bytes(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            project = Path(directory)
            prefix = "# Project-owned heading\n\nOpaque café bytes.\n"
            suffix = "\nProject-owned suffix without final newline"
            agents = project / "AGENTS.md"
            agents.write_bytes(
                prefix.encode("utf-8")
                + render_managed_block("2026.7.27").encode("utf-8")
                + suffix.encode("utf-8")
            )
            (project / "CLAUDE.md").symlink_to("AGENTS.md")
            self._install_profiles(project)
            (project / ".gitignore").write_text(".specwright/worktrees/\n")
            with mock.patch.dict(
                sw_update.KNOWN_PROFILE_DIGESTS_BY_VERSION,
                {"2026.7.27": self._installed_profile_digests(project)},
                clear=True,
            ):
                plan = plan_update(project, "shared")
                self.assertEqual(plan.state, "legacy-migratable")
                self.assertEqual(
                    [operation.relative_path for operation in plan.operations],
                    [
                        "AGENTS.md",
                        ".opencode/agent/sw-change-owner.md",
                        ".opencode/agent/sw-reviewer.md",
                        ".opencode/agent/sw-spec-document-reviewer.md",
                        ".opencode/agent/sw-task-worker.md",
                        ".opencode/command/sw-brainstorm.md",
                        ".opencode/command/sw-init.md",
                        ".opencode/command/sw-plan.md",
                        ".opencode/command/sw-pr.md",
                        ".opencode/command/sw-review-spec.md",
                        ".opencode/command/sw-review.md",
                        ".opencode/command/sw-run.md",
                        ".opencode/command/sw-spec.md",
                        ".opencode/command/sw-update.md",
                    ],
                )
                apply_update(project, "shared", plan.plan_id)
            updated = agents.read_bytes()
            self.assertTrue(updated.startswith(prefix.encode("utf-8")))
            self.assertTrue(updated.endswith(suffix.encode("utf-8")))
            self.assertIn(render_managed_block(INSTALLED_VERSION).encode("utf-8"), updated)

    def test_known_version_upgrade_replaces_unchanged_managed_profiles(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            project = Path(directory)
            (project / "AGENTS.md").write_text(render_managed_block("2026.7.27"))
            (project / "CLAUDE.md").symlink_to("AGENTS.md")
            destination = project / ".codex" / "agents"
            destination.mkdir(parents=True)
            old_digests: dict[str, str] = {}
            for name in sw_update.PROFILE_NAMES:
                contents = f"managed profile from prior release: {name}\n".encode()
                (destination / name).write_bytes(contents)
                old_digests[name] = sw_update._digest_bytes(contents)
            (project / ".gitignore").write_text(".specwright/worktrees/\n")

            with mock.patch.dict(
                sw_update.KNOWN_PROFILE_DIGESTS_BY_VERSION,
                {"2026.7.27": old_digests},
                clear=True,
            ):
                plan = plan_update(project, "shared")
                self.assertEqual(plan.state, "legacy-migratable")
                self.assertEqual(
                    [operation.action for operation in plan.operations],
                    ["replace-managed-block", *("replace-profile",) * 4, *("create",) * 13],
                )
                apply_update(project, "shared", plan.plan_id)

            self._assert_profiles_match(project)
            self.assertEqual(plan_update(project, "shared").state, "up-to-date")

    def test_ignore_negation_after_managed_rules_is_drift(self) -> None:
        with self._fixture_copy("new") as project:
            initial = plan_update(project, "local")
            apply_update(project, "local", initial.plan_id)
            with (project / ".gitignore").open("a") as ignore_file:
                ignore_file.write("!.codex/agents/sw-reviewer.toml\n")
            plan = plan_update(project, "local")
            self.assertEqual(plan.state, "drifted")
            self.assertEqual(plan.operations, ())

    def test_new_plan_normalizes_managed_ignore_rules_to_the_end(self) -> None:
        with self._fixture_copy("new") as project:
            (project / ".gitignore").write_text(
                ".codex/agents/sw-*.toml\n"
                "!.codex/agents/sw-reviewer.toml\n"
                "project-cache/\n"
            )
            plan = plan_update(project, "local")
            self.assertEqual(plan.state, "new")
            apply_update(project, "local", plan.plan_id)
            lines = (project / ".gitignore").read_text().splitlines()
            self.assertEqual(lines[-7:], list(sw_update.LOCAL_IGNORE_RULES))
            self.assertEqual(lines.count(".codex/agents/sw-*.toml"), 1)
            self.assertEqual(plan_update(project, "local").state, "up-to-date")

    def test_apply_is_idempotent_and_post_apply_identity_is_stable(self) -> None:
        with self._fixture_copy("new") as project:
            initial = plan_update(project, "shared")
            apply_update(project, "shared", initial.plan_id)
            first = plan_update(project, "shared")
            second = plan_update(project, "shared")
            self.assertEqual(first.state, "up-to-date")
            self.assertEqual(first.operations, ())
            self.assertEqual(first.plan_id, second.plan_id)
            self.assertNotEqual(initial.plan_id, first.plan_id)
            before = self._full_tree_snapshot(project)
            _, completed = apply_update(project, "shared", first.plan_id)
            self.assertEqual(completed, ())
            self.assertEqual(before, self._full_tree_snapshot(project))

    def test_write_failure_reports_ledger_and_keeps_recoverable_temporary(self) -> None:
        with self._fixture_copy("new") as project:
            plan = plan_update(project, "shared")
            original_replace = sw_update.os.replace
            replace_count = 0

            def fail_second_replace(source: str | bytes, destination: str | bytes) -> None:
                nonlocal replace_count
                replace_count += 1
                if replace_count == 2:
                    raise OSError("injected adapter failure")
                original_replace(source, destination)

            with mock.patch.object(sw_update.os, "replace", side_effect=fail_second_replace):
                with self.assertRaises(WriteFailure) as raised:
                    apply_update(project, "shared", plan.plan_id)
            failure = raised.exception
            self.assertEqual(failure.completed, ("AGENTS.md",))
            self.assertEqual(failure.pending[0], "CLAUDE.md")
            self.assertIsNotNone(failure.temporary_path)
            assert failure.temporary_path is not None
            self.assertTrue(
                failure.temporary_path.is_symlink()
                or failure.temporary_path.exists()
            )
            self.assertTrue((project / "AGENTS.md").is_file())
            self.assertFalse((project / "CLAUDE.md").exists())

    def test_static_up_to_date_fixture_is_recognized(self) -> None:
        with self._fixture_copy("up-to-date") as project:
            (project / "CLAUDE.md").symlink_to("AGENTS.md")
            self._install_profiles(project)
            self._install_opencode_files(project)
            (project / ".gitignore").write_text(".specwright/worktrees/\n")
            self.assertEqual(plan_update(project, "shared").state, "up-to-date")

    def test_new_shared_apply_installs_opencode_files_and_reaches_up_to_date(self) -> None:
        with self._fixture_copy("new") as project:
            plan = plan_update(project, "shared")
            self.assertEqual(plan.state, "new")
            apply_update(project, "shared", plan.plan_id)
            self._assert_opencode_files_match(project)
            self.assertEqual(plan_update(project, "shared").state, "up-to-date")

    def test_edited_opencode_file_is_drifted_with_zero_writes(self) -> None:
        for directory, _, names in sw_update.MANAGED_TEMPLATE_SETS[1:]:
            for name in names:
                with self.subTest(path=f"{directory}/{name}"), self._fixture_copy("new") as project:
                    plan = plan_update(project, "shared")
                    apply_update(project, "shared", plan.plan_id)
                    (project / directory / name).write_bytes(b"hand edited\n")
                    drift_plan = plan_update(project, "shared")
                    self.assertEqual(drift_plan.state, "drifted")
                    self.assertEqual(drift_plan.operations, ())
                    before = self._full_tree_snapshot(project)
                    with self.assertRaisesRegex(UpdateError, "drifted"):
                        apply_update(project, "shared", drift_plan.plan_id)
                    self.assertEqual(before, self._full_tree_snapshot(project))

    def test_real_2026_7_29_legacy_project_migrates_to_up_to_date(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            project = Path(directory)
            (project / "AGENTS.md").write_text(render_managed_block("2026.7.29"))
            (project / "CLAUDE.md").symlink_to("AGENTS.md")
            self._install_profiles(project)
            (project / ".gitignore").write_text(".specwright/worktrees/\n")
            plan = plan_update(project, "shared")
            self.assertEqual(plan.state, "legacy-migratable")
            self.assertEqual(
                [operation.action for operation in plan.operations],
                ["replace-managed-block", *("create",) * 13],
            )
            apply_update(project, "shared", plan.plan_id)
            self._assert_profiles_match(project)
            self._assert_opencode_files_match(project)
            self.assertEqual(plan_update(project, "shared").state, "up-to-date")

    def test_local_mode_apply_writes_exactly_seven_ignore_rules(self) -> None:
        with self._fixture_copy("new") as project:
            plan = plan_update(project, "local")
            self.assertEqual(plan.state, "new")
            apply_update(project, "local", plan.plan_id)
            self.assertEqual(
                (project / ".gitignore").read_text(),
                "\n".join(sw_update.LOCAL_IGNORE_RULES) + "\n",
            )
            self.assertEqual(plan_update(project, "local").state, "up-to-date")

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

    @staticmethod
    def _full_tree_snapshot(
        project: Path,
    ) -> tuple[tuple[str, str, bytes | str | None], ...]:
        entries: list[tuple[str, str, bytes | str | None]] = []
        for path in project.rglob("*"):
            relative = path.relative_to(project).as_posix()
            if path.is_symlink():
                entries.append((relative, "symlink", str(path.readlink())))
            elif path.is_file():
                entries.append((relative, "file", path.read_bytes()))
            elif path.is_dir():
                entries.append((relative, "directory", None))
        return tuple(sorted(entries))

    @staticmethod
    def _install_profiles(project: Path) -> None:
        destination = project / ".codex" / "agents"
        destination.mkdir(parents=True, exist_ok=True)
        for source in sorted(
            (REPOSITORY_ROOT / "plugins/sw/templates/codex-agents").glob(
                "sw-*.toml"
            )
        ):
            shutil.copyfile(source, destination / source.name)

    @staticmethod
    def _install_opencode_files(project: Path) -> None:
        for directory, template_directory, names in sw_update.MANAGED_TEMPLATE_SETS[1:]:
            destination = project / directory
            destination.mkdir(parents=True, exist_ok=True)
            for name in names:
                source = REPOSITORY_ROOT / "plugins/sw/templates" / template_directory / name
                shutil.copyfile(source, destination / name)

    def _assert_opencode_files_match(self, project: Path) -> None:
        for directory, template_directory, names in sw_update.MANAGED_TEMPLATE_SETS[1:]:
            for name in names:
                source = REPOSITORY_ROOT / "plugins/sw/templates" / template_directory / name
                self.assertEqual(
                    (project / directory / name).read_bytes(),
                    source.read_bytes(),
                )

    def _assert_profiles_match(self, project: Path) -> None:
        destination = project / ".codex" / "agents"
        for source in sorted(
            (REPOSITORY_ROOT / "plugins/sw/templates/codex-agents").glob(
                "sw-*.toml"
            )
        ):
            self.assertEqual((destination / source.name).read_bytes(), source.read_bytes())

    @staticmethod
    def _installed_profile_digests(project: Path) -> dict[str, str]:
        destination = project / ".codex" / "agents"
        return {
            name: sw_update._digest_bytes((destination / name).read_bytes())
            for name in sw_update.PROFILE_NAMES
        }


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
