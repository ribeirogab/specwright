#!/usr/bin/env python3
import sys
import tempfile
from pathlib import Path


REPOSITORY_ROOT = Path(__file__).resolve().parents[2]
SCRIPTS_DIRECTORY = REPOSITORY_ROOT / "plugins" / "sw" / "scripts"
sys.path.insert(0, str(SCRIPTS_DIRECTORY))

from package_skill import package_skill
from quick_validate import validate_skill


def write_skill(directory, frontmatter):
    directory.mkdir()
    (directory / "SKILL.md").write_text(f"---\n{frontmatter}\n---\n\n# Test skill\n")


def assert_validation(directory, expected_valid, expected_message):
    valid, message = validate_skill(directory)
    assert valid is expected_valid, message
    assert expected_message in message, message


def main():
    with tempfile.TemporaryDirectory() as temporary_directory:
        root = Path(temporary_directory)

        valid_skill = root / "valid-skill"
        write_skill(
            valid_skill,
            'name: valid-skill\ndescription: "A valid skill."\nuser-invocable: false',
        )
        assert_validation(valid_skill, True, "Skill is valid!")

        invalid_boolean_skill = root / "invalid-boolean"
        write_skill(
            invalid_boolean_skill,
            'name: invalid-boolean\ndescription: "An invalid skill."\nuser-invocable: falsey',
        )
        assert_validation(invalid_boolean_skill, False, "User-invocable must be a boolean")

        unknown_key_skill = root / "unknown-key"
        write_skill(
            unknown_key_skill,
            'name: unknown-key\ndescription: "A skill with an unknown key."\nunsupported: true',
        )
        assert_validation(unknown_key_skill, False, "Unexpected key(s)")

        packaged_skill = package_skill(valid_skill, root / "packages")
        assert packaged_skill is not None
        assert packaged_skill.exists()

    print("skill validation: PASS")


if __name__ == "__main__":
    main()
