# NOTICE — Vendored content attribution

specwright is licensed under the MIT License, the same as the repository as a whole — see [`LICENSE`](LICENSE).

It includes third-party content vendored or adapted from public open-source repositories, preserved with their original licenses and copyright notices; modifications are documented below.

## Vendored under `skills/sw/scripts/`

specwright bundles two scripts vendored from `anthropics/skills` so the skill is self-contained and does not depend on the upstream project being installed alongside it:

| Field | Value |
|---|---|
| Files | `skills/sw/scripts/quick_validate.py`, `skills/sw/scripts/package_skill.py` |
| Original source | [https://github.com/anthropics/skills/tree/main/skill-creator/scripts](https://github.com/anthropics/skills/tree/main/skill-creator/scripts) |
| Original license | Apache-2.0 |
| Copyright holder | Anthropic |
| Modifications | `quick_validate.py` is verbatim. `package_skill.py` has one change vs upstream: the `from scripts.quick_validate import validate_skill` line is replaced with `sys.path.insert(0, str(Path(__file__).parent))` followed by `from quick_validate import validate_skill`, so the file works whether invoked as `python -m scripts.package_skill`, `python scripts/package_skill.py`, or by absolute path. The change is documented inline in the file's module docstring. |

## Adapted under the `sw` skills (`brainstorming`, `writing-plans`)

The `brainstorming` and `writing-plans` skills are adapted from the **superpowers** project by Jesse Vincent (obra). The brainstorming visual companion (its HTML/CSS/scripts) and the plan-writing flow originate there; specwright has rebranded the user-facing surfaces, removed the dependencies on superpowers-only sub-skills, and rewired runtime paths to `.specwright/`.

| Field | Value |
|---|---|
| Source | [https://github.com/obra/superpowers](https://github.com/obra/superpowers) |
| Original license | MIT |
| Modifications | Rebranded the brainstorm UI ("Superpowers Brainstorming" → "specwright Brainstorming"); moved the runtime mockup path `.superpowers/brainstorm/` → `.specwright/brainstorm/`; removed the `superpowers:*` sub-skill dependencies by inlining the execution-approach guidance; integrated both skills into the specwright spec-driven flow. |

## License compatibility

The repository as a whole is licensed under MIT (see [`LICENSE`](LICENSE)). MIT is compatible with the Apache-2.0 vendored scripts: Apache-2.0 content is permitted inside an MIT-licensed project as long as the original license and notices are retained, which they are above. The superpowers-derived skills are MIT-licensed — the same license as this repository — and are retained under MIT with the attribution above. The repository's `LICENSE` covers the original work — the `sw` skill, its bundled companions, the project documentation, and the scaffold payloads — and does not retroactively re-license the vendored scripts.

## How to update this file

When the vendored scripts are refreshed to a newer upstream version, update the row with the new source URL (specific commit or tag) and refresh the modifications cell.
