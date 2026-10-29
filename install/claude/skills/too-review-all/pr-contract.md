# PR review contract for too-1-by-1

`too-1-by-1` follows this when a `findings.md` from `too-review-all` names it as `contract:`. Each decision is a review comment; nothing is posted before Finish. The header gives `target` (PR URL), `head` (headRefOid) and `worktree`.

## Start

If `worktree` is gone, recreate it as `too-review-all` step 1 does. If `git -C "$wt" rev-parse HEAD` differs from `head`, run `git -C "$wt" reset -q <head>` and say so. If the PR's head has moved since (`gh pr view <n> --json headRefOid`), say so: comments still post against `head`.

## Each item

- The card shows the draft comment in a quote block under **Draft comment**, between **In plain words** and **Options**, following the "PR comments drafted by an agent" rule in `~/.claude/CLAUDE.md`: the problem, why it matters, a concrete fix. Use a GitHub ```` ```suggestion ```` block when the fix is a few lines inside the diff.
- Picker options: ★ `👍 Agree` · `🤔 Not sure` · `FYI` · `Rephrase`. The choice sets the `🤖 AI-flagged` label line. The question ends with "Which stance for this comment?".
- Typed in the free-text field: `summary only` (goes in the review body, not inline), `skip`, `custom <text>` (the comment becomes the user's own, no label), `custom 🤖 <text>` (keeps the label). Text typed after a stance (`👍 we hit this in prod`) becomes the `**Me:**` line; never prompt for it.
- A location outside the diff hunks can't take an inline comment: say so on the card; the comment goes in the summary body.
- `loop` queues the comment instead of implementing.

## Finish

Show every queued comment and the summary body together, ask for the event (`COMMENT`, or `REQUEST_CHANGES` only when a blocking 👍 comment is queued), and post only after the user approves:

```sh
gh api repos/{owner}/{repo}/pulls/<n>/reviews --input review.json
```

`review.json` holds `commit_id` (`head`), `event`, `body`, and `comments: [{path, line, side: "RIGHT", body}]`. `path` is repo-relative. Print the review URL from the response, then `git worktree remove "$wt"`.

Without `gh` auth, stop at the preview.

Post one review, not comment by comment: one review, one notification.
