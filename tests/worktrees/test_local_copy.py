#!/usr/bin/env python3
"""Verify local dual-host state reaches an issue worktree without becoming tracked."""

from __future__ import annotations

from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


REPOSITORY_ROOT = Path(__file__).resolve().parents[2]
PROFILE_TEMPLATES = REPOSITORY_ROOT / "plugins" / "sw" / "templates" / "codex-agents"


def run_git(project: Path, *arguments: str) -> str:
    return subprocess.run(
        ["git", "-C", str(project), *arguments],
        check=True,
        capture_output=True,
        text=True,
    ).stdout


def is_ignored(project: Path, relative_path: str) -> bool:
    result = subprocess.run(
        ["git", "-C", str(project), "check-ignore", "--quiet", relative_path],
        check=False,
    )
    return result.returncode == 0


class LocalWorktreeCopyTests(unittest.TestCase):
    def test_copy_in_preserves_local_dual_host_contract_and_ignore_scope(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            project = Path(temporary_directory) / "project"
            project.mkdir()
            run_git(project, "init")
            run_git(project, "config", "user.name", "Specwright Test")
            run_git(project, "config", "user.email", "specwright@example.test")
            (project / ".gitignore").write_text(
                ".specwright/worktrees/\n"
                ".specwright/\n"
                "AGENTS.override.md\n"
                "CLAUDE.local.md\n"
                ".codex/agents/sw-*.toml\n"
            )
            (project / "README.md").write_text("fixture\n")
            run_git(project, "add", ".gitignore", "README.md")
            run_git(project, "commit", "-m", "test fixture")

            issue_relative_path = Path(".specwright/milestones/example/issues/issue")
            canonical_instructions = project / "AGENTS.override.md"
            canonical_instructions.write_text("# Local instructions\n")
            canonical_profile_directory = project / ".codex/agents"
            canonical_profile_directory.mkdir(parents=True)
            for profile_template in sorted(PROFILE_TEMPLATES.glob("sw-*.toml")):
                shutil.copyfile(profile_template, canonical_profile_directory / profile_template.name)
            issue_directory = project / issue_relative_path
            issue_directory.mkdir(parents=True)
            (issue_directory / "issue.md").write_text("status: pending\n")

            worktree = project / ".specwright/worktrees/issue"
            run_git(project, "worktree", "add", str(worktree), "-b", "test/issue")

            shutil.copyfile(canonical_instructions, worktree / "AGENTS.override.md")
            (worktree / "CLAUDE.local.md").symlink_to("AGENTS.override.md")
            profile_destination = worktree / ".codex/agents"
            profile_destination.mkdir(parents=True)
            for canonical_profile in sorted(canonical_profile_directory.glob("sw-*.toml")):
                shutil.copyfile(canonical_profile, profile_destination / canonical_profile.name)
            copied_issue_directory = worktree / issue_relative_path
            copied_issue_directory.mkdir(parents=True)
            shutil.copytree(issue_directory, copied_issue_directory, dirs_exist_ok=True)

            self.assertEqual((worktree / "AGENTS.override.md").read_text(), "# Local instructions\n")
            claude_adapter = worktree / "CLAUDE.local.md"
            self.assertTrue(claude_adapter.is_symlink())
            self.assertEqual(claude_adapter.readlink(), Path("AGENTS.override.md"))
            self.assertEqual((copied_issue_directory / "issue.md").read_text(), "status: pending\n")

            copied_profiles = sorted(profile_destination.glob("sw-*.toml"))
            canonical_profiles = sorted(canonical_profile_directory.glob("sw-*.toml"))
            self.assertEqual(len(canonical_profiles), 4)
            self.assertEqual([profile.name for profile in copied_profiles], [profile.name for profile in canonical_profiles])
            for canonical_profile, copied_profile in zip(canonical_profiles, copied_profiles):
                self.assertEqual(copied_profile.read_bytes(), canonical_profile.read_bytes())

            canonical_instruction_bytes = canonical_instructions.read_bytes()
            canonical_profile_bytes = canonical_profiles[0].read_bytes()
            (worktree / "AGENTS.override.md").write_text("# Owner-local edit\n")
            copied_profiles[0].write_text("owner-local profile edit\n")
            (copied_issue_directory / "issue.md").write_text("status: shipped\n")
            shutil.copytree(copied_issue_directory, issue_directory, dirs_exist_ok=True)
            self.assertEqual((issue_directory / "issue.md").read_text(), "status: shipped\n")
            self.assertEqual(canonical_instructions.read_bytes(), canonical_instruction_bytes)
            self.assertEqual(canonical_profiles[0].read_bytes(), canonical_profile_bytes)

            (worktree / ".codex/project.toml").write_text("project = true\n")
            ignored = run_git(worktree, "status", "--porcelain", "--ignored")
            self.assertFalse(is_ignored(worktree, ".codex/project.toml"))
            self.assertIn("?? .codex/", ignored)
            self.assertIn("!! AGENTS.override.md", ignored)
            self.assertIn("!! CLAUDE.local.md", ignored)
            self.assertIn("!! .codex/agents/", ignored)
            self.assertIn("!! .specwright/", ignored)


if __name__ == "__main__":
    suite = unittest.defaultTestLoader.loadTestsFromTestCase(LocalWorktreeCopyTests)
    result = unittest.TextTestRunner(verbosity=2).run(suite)
    if result.wasSuccessful():
        print("local worktree copy: PASS")
    raise SystemExit(not result.wasSuccessful())
