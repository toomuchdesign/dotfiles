# PR review contract for too-1-by-1

`too-1-by-1` follows this when a `findings.md` from `too-review-all` names it as `contract:`. Each decision is a review comment; nothing is posted before Finish. The header gives `target` (PR URL), `head` (headRefOid) and `worktree`.

## Start

If `worktree` is gone, recreate it as `too-review-all` step 1 does. If `git -C "$wt" rev-parse HEAD` differs from `head`, run `git -C "$wt" reset -q <head>` and say so. If the PR's head has moved since (`gh pr view <n> --json headRefOid`), say so: comments still post against `head`.

## Each item

- The card shows the draft comment in a quote block under **Draft comment**, between **In plain words** and **Options**, following the "PR comments drafted by an agent" rule in `~/.claude/CLAUDE.md`: the problem, why it matters, a concrete fix. Use a GitHub ```` ```suggestion ```` block when the fix is a few lines inside the diff.
- Options: the stances `👍 Agree`, `🤔 Not sure` and `FYI`, with the ★ one first on both the card and the picker, then `Rephrase`. The choice sets the `🤖 AI-flagged` label line. The question ends with "Which stance for this comment? To add your own line, type the stance and your text in Other, e.g. `👍 we hit this in prod`."
- Typed in the free-text field: `summary only` (goes in the review body, not inline), `skip`, `custom <text>` (the comment becomes the user's own, no label), `custom 🤖 <text>` (keeps the label). A stance can be typed as its emoji or its word, in any case (`👍`, `agree`, `🤔`, `not sure`, `fyi`); the text after it, minus leading punctuation, becomes the user's opening line, above the label. Never prompt for it.
- The log line carries the note: `<n>. <name> → <stance> · Note: <text>`.
- With each logged stance or `custom`, write the comment as it will post to `comments/<n>.md` next to the log: the first line is the repo-relative `path:line` (or `summary` for summary-body comments), then a blank line, then the exact body (the user's line and a blank line if there is one, the label line, a blank line, the card's draft text as last shown). `custom` text goes there too. A redecided item overwrites its file; `skip` removes it; `defer` writes none. Finish posts these files as written, so nothing has to be rebuilt from the conversation.
- Two comments can't both carry a ```` ```suggestion ```` for the same line: put both fixes in one suggestion and leave it out of the other, and say so on the card.
- A location outside the diff hunks can't take an inline comment: say so on the card; the comment goes in the summary body.
- `loop` queues the comment instead of implementing.

## Finish

Build `review.json` from `comments/*.md`. Show every queued comment and the summary body together, ask for the event (`COMMENT`, or `REQUEST_CHANGES` only when a blocking 👍 comment is queued), and post only after the user approves:

```sh
gh api repos/{owner}/{repo}/pulls/<n>/reviews --input review.json
```

`review.json` holds `commit_id` (`head`), `event`, `body`, and `comments: [{path, line, side: "RIGHT", body}]`. `path` is repo-relative. Print the review URL from the response, then `git worktree remove "$wt"`.

Without `gh` auth, stop at the preview.

Post one review, not comment by comment: one review, one notification.
