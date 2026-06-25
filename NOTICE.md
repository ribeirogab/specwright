# NOTICE — Vendored content attribution

specwright is licensed under the MIT License, the same as the repository as a whole — see [`LICENSE`](LICENSE).

It includes a small amount of third-party content vendored from a public open-source repository, preserved with its original license and copyright notice; modifications are documented below.

## Vendored under `skills/sw/scripts/`

specwright bundles two scripts vendored from `anthropics/skills` so the skill is self-contained and does not depend on the upstream project being installed alongside it:

| Field | Value |
|---|---|
| Files | `skills/sw/scripts/quick_validate.py`, `skills/sw/scripts/package_skill.py` |
| Original source | [https://github.com/anthropics/skills/tree/main/skill-creator/scripts](https://github.com/anthropics/skills/tree/main/skill-creator/scripts) |
| Original license | Apache-2.0 |
| Copyright holder | Anthropic |
| Modifications | `quick_validate.py` is verbatim. `package_skill.py` has one change vs upstream: the `from scripts.quick_validate import validate_skill` line is replaced with `sys.path.insert(0, str(Path(__file__).parent))` followed by `from quick_validate import validate_skill`, so the file works whether invoked as `python -m scripts.package_skill`, `python scripts/package_skill.py`, or by absolute path. The change is documented inline in the file's module docstring. |

## License compatibility

The repository as a whole is licensed under MIT (see [`LICENSE`](LICENSE)). MIT is compatible with the Apache-2.0 vendored scripts: Apache-2.0 content is permitted inside an MIT-licensed project as long as the original license and notices are retained, which they are above. The repository's `LICENSE` covers the original work — the `sw` skill, its bundled companions, the project documentation, and the scaffold payloads — and does not retroactively re-license the vendored scripts.

## How to update this file

When the vendored scripts are refreshed to a newer upstream version, update the row with the new source URL (specific commit or tag) and refresh the modifications cell.
