---
tags:
  - learning
  - reference
related:
  - "[[memex-improvement-insights]]"
  - "[[mechanical-enforcement-over-prose]]"
created: 2026-06-14
---
# Validate vault mermaid diagrams with mermaid-cli (no-build, one-off)

Vault learnings can carry mermaid diagrams, and a malformed block fails *silently* in the reader. To parse-check every diagram without violating the "no build pipeline" constitution rule, extract the fenced ```` ```mermaid ```` blocks and run them through **`@mermaid-js/mermaid-cli` via a one-off `npx`** — never installed to the repo root. On macOS the headless-chromium step needs a puppeteer config with the sandbox disabled:

```bash
printf '{"args":["--no-sandbox","--disable-setuid-sandbox"]}' > /tmp/pptr.json
npx -y @mermaid-js/mermaid-cli@latest -p /tmp/pptr.json -i diagram.mmd -o /tmp/out.svg
# exit 0 = parses; non-zero prints the syntax error
```

A small Python extractor (`re.findall(r"```mermaid\n(.*?)```", text, re.S)`) splits each `.md` into per-diagram `.mmd` files; loop `mmdc` over them and count exit codes.

## Context

Discovered while shipping the `2026-06-14-benchmark-spec-driven-tools` learnings (3 notes, 7 mermaid diagrams). Without `-p pptr.json` the default chromium launch can fail in a sandboxed shell; with it, all 7 diagrams validated 7/7. `mmdc` *renders* (real parse) rather than just lints, so it catches errors a regex never would — the same feedforward-gate idea as [[mechanical-enforcement-over-prose]], applied to docs. Relevant to recommendation #4 in [[memex-improvement-insights]] (a mechanical validator for spec artifacts).

## How to Apply

Before committing any vault note (or spec/plan) that contains mermaid, run the extract-then-`mmdc` loop and require 7/7-style clean exit. Keep it a one-off `npx` invocation and write outputs to `/tmp` — nothing about it touches the repo, so the no-build-pipeline rule holds. If a future `skills/memex/scripts/` validator grows a docs check, fold this command into it.
