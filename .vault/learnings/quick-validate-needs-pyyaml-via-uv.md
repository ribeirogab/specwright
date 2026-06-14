---
tags:
  - reference
related:
  - "[[2026-06-13-spec-driven-workflow/spec|spec-driven-workflow]]"
created: 2026-06-13
---
# Run the skill validators with `uv run --with pyyaml`

`skills/memex/scripts/quick_validate.py` and `package_skill.py` `import yaml`, but the system `python3` on this machine has no `PyYAML`, so a bare `python3 skills/memex/scripts/quick_validate.py <path>` dies with `ModuleNotFoundError: No module named 'yaml'`. Run them through `uv` instead, which resolves the dependency in an ephemeral environment:

```bash
uv run --quiet --with pyyaml python skills/memex/scripts/quick_validate.py <skill-path>
uv run --quiet --with pyyaml python skills/memex/scripts/package_skill.py <skill-path> /tmp
```

A valid skill prints `Skill is valid!`; packaging prints `Successfully packaged skill to: /tmp/<name>.skill`.

## Context

Hit while running the quality gate for `[[2026-06-13-spec-driven-workflow/spec|spec-driven-workflow]]`. The repo has no `requirements.txt` or virtualenv (constitution: no package manager at the root), so the validator's lone third-party dependency is not installed globally. `uv` is present at `~/.local/bin/uv`.

## How to Apply

When a quality gate or PR checklist says "run `python skills/memex/scripts/quick_validate.py`", use the `uv run --with pyyaml python …` form. Don't `pip install` into the system interpreter — keep the dependency ephemeral.
