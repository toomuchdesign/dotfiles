---
name: too-pr-draft-review
description: Use for "/too-pr-draft-review", or whenever review feedback, inline comments, thread replies or reviewer notes are about to go on a pull request or merge request (GitHub, GitLab, any provider), from any skill or from the conversation. Triggers include "post the review", "put these on the PR", "leave these comments", "reply to that thread".
---

# Draft PR/MR review

Puts feedback on a PR/MR as a **draft review** the user reads online and
submits themselves. Reviewing and deciding happen elsewhere (`too-1-by-1`,
`pstack:interrogate`, plannotator, the conversation); this skill only posts.

**The user submits. You never publish.** No submit call, no publish call,
no endpoint that posts at once, whatever the reason: "so it all goes out in
one notification", "the user is in a hurry", "the reply endpoint is
simpler", "the summary is just a note". A provider or call with no draft
mode means stop, say so, and let the user decide.

## Input: the review directory

One file per item. First line is the anchor, then a blank line, then the
body exactly as it will post:

| First line                      | Item                                  |
| ------------------------------- | ------------------------------------- |
| `path:42` / `path:40-48`        | inline comment on the head's new side |
| `summary`                       | the review body (at most one file)    |
| `reply <comment or thread URL>` | reply inside an existing thread       |

Callers (`too-1-by-1` via `pr-contract.md`, `too-pr-note`) hand over a
directory and the target URL. Otherwise build one in the scratchpad from
the conversation: the user's words verbatim, AI-raised points following
"PR comments drafted by an agent" in `~/.claude/CLAUDE.md`.

## Steps

1. **Provider.** From the target URL host, else `git remote get-url origin`:
   GitHub (incl. Enterprise) → [github.md](github.md), GitLab →
   [gitlab.md](gitlab.md). Anything else: stop, there is no known draft
   API; show the items and let the user post them by hand. Same when the
   provider CLI isn't authenticated.
2. **Head.** Fetch the PR/MR head SHA and diff. Post against that head.
3. **Place.** An inline comment must sit inside one diff hunk on the new
   side. Outside the diff: move it into the summary with a permalink at the
   head. A ```` ```suggestion ```` replaces every line the comment covers:
   if the body suggests fewer lines than the range, flag it.
4. **Repeats.** List existing threads; flag items that repeat one and
   offer a `reply` instead.
5. **Preview.** Show every item as it will post, with its final anchor, and
   what moved and why. Post only after the user says go. A caller that
   already showed the same items and got a go skips this.
6. **Post** as the provider file says. One draft review per run.
7. **Report.** The PR/MR link, each item's URL where the provider gives
   one, what was moved or skipped, and:
   "The review is a draft waiting for you to submit." Callers that pass
   an event recommendation (e.g. `Request changes`) get it repeated here.

## Red flags: stop

- About to call `/events`, `submitPullRequestReview`, `bulk_publish`,
  `draft_notes/:id/publish`, `glab mr note draft publish`.
- About to use `gh pr review`, `gh pr comment`, `glab mr note -m`, REST
  `/pulls/<n>/comments` or `/replies`, MR `notes`/`discussions`.
- A "pending review already exists" error: report it. Never submit or
  delete the user's existing draft to make room.
