# Claude Plugin Settings — Reference

The specwright skill writes (or merges into) the target repo's `.claude/settings.json` so that Claude Code installs the upstream marketplace `specwright` plus the `sw` plugin at trust time. This reference is the **single source of truth** for the marketplace coordinates, the JSON shapes, and the merge recipe.

## Canonical coordinates

| Key             | Value                       |
| --------------- | --------------------------- |
| Marketplace name | `specwright`             |
| Marketplace source (target repos) | `{ "source": "github", "repo": "ribeirogab/specwright" }` |
| Marketplace source (this repo dogfood only) | `{ "source": "directory", "path": "." }` |
| Plugin name     | `sw`                     |
| Enabled-plugins key | `sw@specwright`    |

## JSON shapes

The two keys to write under the top-level object are `extraKnownMarketplaces` and `enabledPlugins`.

`extraKnownMarketplaces["specwright"]` (target repos):

```json
{
  "source": {
    "source": "github",
    "repo": "ribeirogab/specwright"
  }
}
```

`enabledPlugins["sw@specwright"]`:

```json
true
```

## Merge recipe — jq (preferred)

`jq` is the preferred tool because it preserves existing top-level keys and avoids parse-rewrite-write round-trip bugs.

```bash
SETTINGS=".claude/settings.json"
TMP="$(mktemp)"

# Read existing settings (or start from {} if file is absent or empty)
if [ -s "$SETTINGS" ]; then
  cp "$SETTINGS" "$TMP"
else
  echo '{}' > "$TMP"
fi

jq '
  .extraKnownMarketplaces["specwright"] = {
    "source": { "source": "github", "repo": "ribeirogab/specwright" }
  } |
  .enabledPlugins["sw@specwright"] = true
' "$TMP" > "$SETTINGS"

rm "$TMP"
```

The recipe:

- Creates `.claude/settings.json` if absent (`mktemp` + `echo '{}'`).
- Preserves every other top-level key — `jq` only sets the two target paths.
- Overwrites the two target paths if they already exist (idempotent — re-running the recipe converges to the same final state).

## Merge recipe — Python fallback

If `jq` is not installed, use this inline Python snippet. Behaviour matches the jq recipe.

```bash
python3 - <<'PY'
import json, pathlib
p = pathlib.Path(".claude/settings.json")
data = json.loads(p.read_text()) if p.exists() and p.read_text().strip() else {}
data.setdefault("extraKnownMarketplaces", {})["specwright"] = {
    "source": {"source": "github", "repo": "ribeirogab/specwright"}
}
data.setdefault("enabledPlugins", {})["sw@specwright"] = True
p.write_text(json.dumps(data, indent=2) + "\n")
PY
```

If neither `jq` nor `python3` is available, the skill must report a clear error and emit the snippet the user should paste manually. The skill **must not** overwrite the file with a templated full-file write — that would clobber unrelated keys.

## Dogfood note (this repo only)

When the specwright skill runs **inside `ribeirogab/specwright` itself** (the marketplace repo), the dogfood `.claude/settings.json` declares the marketplace source as `{ "source": "directory", "path": "." }` instead of the GitHub source above. This keeps the maintainer's inner dev loop fast — local edits to `plugins/sw/` are picked up on `/plugin marketplace update` without commit-push-fetch. The github source is for **target repos** (every other repo). The skill detects this case by checking whether the current repo's `.claude-plugin/marketplace.json` declares `name = "specwright"`; if it does, use the local source.

## Trade-off-rejected alternatives (from Architecture Decision 3)

For the historical record so this question is not re-litigated:

1. **Documented manual `/plugin marketplace add` + `/plugin install`** — rejected because every team member would re-run two commands per fresh clone, and the `.claude/settings.json` route gives identical UX with one trust-prompt acceptance.
2. **Skill running `/plugin` commands via bash** — rejected because the `/plugin` slash command is a Claude Code TUI primitive, not a shell command; the skill cannot invoke it from a bash block.
