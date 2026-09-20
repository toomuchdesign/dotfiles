---
name: toomuchdesign-pr-description
description: Use when asked to write or generate a PR description, PR body, or human-friendly markdown summary of a branch diff (usually the current branch) to paste into GitHub. Triggers include "PR description for this branch", "describe this diff", "write the PR body".
---

# PR description

Write the PR body that walks a reviewer through the change: professional,
friendly, example-driven. Not a changelog or a commit dump.

## Gather the diff

1. Detect the base branch — don't assume `origin/main`:

   ```sh
   base=$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null \
     || (git remote show origin 2>/dev/null | sed -n 's/.*HEAD branch: //p')) ; \
     base=${base#origin/} ; base="origin/${base:-main}"
   ```

   If that yields nothing usable, fall back to `origin/main`, then
   `origin/master`. Confirm the base has commits the branch builds on.

2. Read the change:
   - `git log --oneline <base>..HEAD` — the story in commits
   - `git diff <base>...HEAD --stat` — scope
   - `git diff <base>...HEAD` — the detail

3. Understand the *why* before writing.

4. Note the branch's issue/story id if there is one — many repos want it in the
   title or as a `Closes #123` line. Get a hint from the branch name instead of
   asking outright, then confirm rather than trusting it:

   ```sh
   git rev-parse --abbrev-ref HEAD | grep -oE '[0-9]{3,6}' | head -1
   ```

5. Check whether a PR already exists for this branch — it decides update-vs-create
   and warns against clobbering an in-progress review:

   ```sh
   gh pr view --json number,title,url,state,reviewDecision 2>/dev/null || echo "no PR yet"
   ```

### Clarify first

Before writing, resolve real uncertainties by asking the user — batch a few
short, specific questions rather than guessing. Ask when:

- the intent or motivation isn't clear from the diff and commits
- there's an issue or ticket to link but the id is unknown
- the scope mixes themes and it's unclear whether to split the PR
- you can't tell how it was tested, or whether something breaks
- the emphasis is ambiguous — what matters most to this reviewer

Skip questions the diff and commits already answer. Don't stall on trivia.

### Multi-theme branches

If the branch mixes unrelated themes (e.g. a shell tweak plus a feature):
lead with the dominant theme in the Summary, group the rest under Changes,
and add a Notes line naming the mix. If the themes are large and genuinely
independent, say so and suggest splitting into separate PRs.

## Title

Propose a one-line title above the body. Match the repo's convention (check
`git log --oneline`): if it uses Conventional Commits, use
`type(scope): summary`; otherwise a short imperative sentence. If the repo
requires an issue/story id in the title, include the one from Gather step 4.
The title is the GitHub PR title — keep it separate from the body.

## Body — always this shape

```markdown
## Summary

<1-3 sentences: what this PR introduces and the problem it solves.>

## Motivation & context

<why this change, now. Link the issue: "Closes #123" if one exists.>

## Changes

- <notable changes in the reader's domain language — not file-by-file>

## How to review

<the commits in the order a reviewer should read them, one plain line each on
what to look at. Use when the branch keeps a clean, independently-revertable
history — it's the fastest path through the PR.>

## Example / Screenshots

<the smallest concrete thing that makes it click: a before/after diff, a
call tree, a mermaid diagram, or UI screenshots.>

## Testing

<how it was verified: the test that now passes, command + output, or a
screenshot.>

## Breaking changes

<what breaks and how to migrate — or "None".>

## Notes

<risks, follow-ups, anything a reviewer should watch. Say so if the PR is
intentionally a POC or minimal-by-design.>

## Open points

<questions or decisions where you want the reviewer's input before merge.>
```

### Which sections to include

Include a section only when it earns its place for the reviewer. Drop
anything empty, boilerplate, or already obvious — a tiny PR can be just a
**Summary**. Never pad to fill the template.

- **Summary** — always; every reviewer reads it.
- **Motivation & context** — when the *why* isn't obvious, or an issue links.
- **Changes** — when several notable changes are worth listing.
- **How to review** — when the branch has a clean multi-commit history worth walking in order.
- **Example / Screenshots** — when behaviour or UI changes.
- **Testing** — when there's something to verify.
- **Breaking changes** — when something actually breaks.
- **Notes** — when there's a real risk or follow-up.
- **Open points** — when the PR needs the reviewer's input.

## Markup

- Don't hard-wrap prose. Write each paragraph as a single line and let it
  flow — GitHub wraps it. Reserve line breaks for real paragraph splits.
- Split a block into short paragraphs when it covers more than one idea.
- Use markdown to aid reading: **bold** for the key point, `code` for
  identifiers, paths, and commands, and fenced code blocks for diffs, trees,
  and multi-line snippets.

## Explain the hard parts plainly

The body keeps the professional voice throughout (see **Voice**). The one
exception: for a single step or concept that's genuinely hard to grasp from
the diff, drop a short inline callout right where it's needed:

> **In plain words:** <one or two jargon-free sentences>

Write just the callout the way the `bro` skill does — one human explaining
to another, no jargon. Never apply this casual register to the whole
description; use it sparingly, only where a reviewer would otherwise get
lost.

## Voice

Professional but friendly. Write impersonally by default — the PR is the
subject: "This PR introduces…", "It moves…", "The decision was…". Avoid a
default "I did / we did".

Switch to the first person only to own a personal call the author wants to
underline: "I chose X over Y because…". Reserve it for those moments.

## Finish

- Run the `unslop` skill on the whole thing: cut AI tells, plain words.
- Keep it minimal — trim every sentence that doesn't help the reader.

## Deliver it

Do both — show it and stage it for pasting:

1. **Show** the full body in the reply so the user can read and critique it.
2. Write the body to a scratch file (e.g. `"$TMPDIR/pr-body.md"`).
3. **Copy** it to the clipboard — `pbcopy < "$TMPDIR/pr-body.md"` (macOS) —
   and confirm it's ready to paste into GitHub.
4. Print the proposed title separately so they can paste it into the title
   field.

If the user works with `gh`, offer to open or update the PR directly. When
Gather found an existing PR, prefer `gh pr edit --body-file "$TMPDIR/pr-body.md"`
and keep that PR — don't recreate it, and if it's already under review don't
rewrite history as part of this, just update the body. Otherwise
`gh pr create --title "<title>" --body-file "$TMPDIR/pr-body.md"`. No "here's
the description" preamble.

## Iterate

The first output is a draft. After delivering, invite feedback and expect
changes. When the user asks for edits, apply them and re-run **Deliver it**
(show + clipboard + title) so the clipboard always holds the latest version.
Repeat until they're happy.
