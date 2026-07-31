---
name: pr
user-invocable: false
description: "Use when explicitly invoked to open the current change's pull request following specwright conventions — branch and base resolution, the repository's PR template, an English Conventional-Commit title, the runtime-verification record, and no AI attribution. Trigger on '/sw:pr', '$sw:pr', or a direct request to open the PR."
---

# pr — open the change's pull request

The sanctioned way to open a PR in a specwright repository.

**Announce at start:** "Opening the pull request."

## Inputs

`$ARGUMENTS` (optional): a target base branch and/or extra instructions — "to
main", "label bug", "draft". Empty → the base defaults to `main`.

## Safety gate — never from the default branch

```bash
git branch --show-current
```

If it is `main` or `master`, **stop** and tell the maintainer to create a feature
branch first. Do not proceed.

## Find the change

Locate the change driving this branch: the `plan.md` under `.specwright/changes/*/`
whose `branch:` matches the current branch, else the most recently modified change
folder there.

- **Found** — the approved ticket authorizes this step. Continue within the
  host's Git, network, credential, and external-action policy; ask when that
  policy requires explicit consent.
- **Not found** — an ad-hoc PR. Proceed only if the maintainer invoked this skill
  explicitly.

## Push the branch if needed

```bash
git ls-remote --heads origin "$(git branch --show-current)"
```

If the branch is not on origin, push it — only when host policy permits the
Git/network action, and never `main` or `master`:

```bash
git push -u origin "$(git branch --show-current)"
```

## Resolve the PR template

```bash
cat .github/PULL_REQUEST_TEMPLATE.md 2>/dev/null || cat .github/pull_request_template.md 2>/dev/null
```

Fill its sections and do not drop required checklist items — answer them
honestly. For a maintainer dogfood PR that edits `.specwright/`, annotate rather
than silently tick. If no template exists, print one line — `PR template not
found; using embedded fallback` — and use the fallback at the bottom of this file.

## Title and body

- **Title** — English, Conventional Commits: `<type>(<scope>): <concise summary>`.
  Types: `feat`, `fix`, `docs`, `refactor`, `chore`, `test`, `ci`. Derive the
  scope from the area the diff touches.
- **Body** — English; committed artifacts are English even when the conversation
  is not. Open with ONE product-level sentence — what this PR does, no filenames,
  no pipeline mechanics — then two to five concrete bullets (resource + action).
  Link the change artifacts as absolute GitHub URLs on the branch: `change.md`
  and `plan.md`.

  **Exception — local mode** (`git check-ignore -q .specwright/changes` succeeds):
  those files are git-ignored and never pushed, so a GitHub URL would 404. Omit
  the links and write one line instead: the artifacts live only in the local,
  un-pushed `.specwright/` vault.

  The template's test-plan section carries two things: the **quality-gate
  results** (what ran, what passed) and the **runtime-verification record** —
  each `AC-N` with how it was verified by observed behavior, or
  `needs-human-verification` with its reason. A repository-only auditor must be
  able to tell what was actually executed.
- **No AI attribution** anywhere — no "Co-Authored-By: Claude", no "Generated
  by …", in the body or in any commit.

## Degradation — ordered preflight

Run these **before** `gh pr create`, which is never invoked as a probe and never
with a placeholder title or body. It runs once, with the real content.

1. **Remote** — inspect `git remote -v`. Empty, or no GitHub remote → **stop**:
   explain, and do not fabricate a PR.
2. **`gh`** — not on PATH, or `gh auth status` fails → **stop**: print the exact
   `git push` and manual PR-creation steps for the maintainer to finish.

**On either stop, write the fully-filled body — including the quality-gate
results and the per-criterion verification record — to `<change-folder>/pr.md`**
and say so. The delivery record must survive the session.

## Create the PR

```bash
gh pr create --base <BASE> --title "<TITLE>" --body "<BODY>" --assignee @me
```

Keep `--assignee @me` unless `$ARGUMENTS` says otherwise. Add `--draft` only if
asked. Print the PR URL afterwards.

## Stacked base (delivery changes)

When this change's delivery dependency is not yet merged, the branch was cut from
the dependency's branch: pass that branch as `--base` and say so in the body
("stacked on #<PR>"). Re-target to `main` after the dependency merges.

## Then

Print the PR URL and stop.

Say what comes next: **`/sw:review`** (`$sw:review` in Codex) reviews the branch
to `lgtm`. Merging is the maintainer's call, never this skill's.

## Embedded fallback (repository has no PR template)

In local mode, replace the `## Change` block's URLs with the single line
described above.

```markdown
<one product-level sentence — what this PR does>
- <concrete change 1>
- <concrete change 2>

## Summary
<context, motivation, key decisions, non-goals, trade-offs>

## Change
- change: <github-url>
- plan: <github-url>

## Quality gate
<tests, validators, and checks run, with their results>

## Runtime verification
<AC-N: verified how — or needs-human-verification + reason>
```
