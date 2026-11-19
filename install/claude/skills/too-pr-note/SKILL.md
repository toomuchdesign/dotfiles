---
name: too-pr-note
description: Reviewer notes on the user's own PR, kept out of the code. Use when the user wants to leave a note for reviewers on specific lines (often mid-review in plannotator or too-1-by-1), opens or creates the PR or marks it ready (posts queued notes), or asks to list the notes.
---

# Reviewer notes

Line comments the author leaves on their own PR for reviewers. Notes are
queued locally while the branch is still being rewritten and posted once,
as one review, when the PR is opened.

## Queue

One file per branch, inside the git dir so it is never committed. Branch
names can contain `/`, so create the parent folder first:

```sh
q="$(git rev-parse --path-format=absolute --git-common-dir)/too-pr-notes/$(git branch --show-current).md"
mkdir -p "$(dirname "$q")"
```

On a detached HEAD there is no branch to queue for: ask the user which
branch the note belongs to.

Each note is one block:

````markdown
## src/foo.ts:40-48

Captured at: <snapshot sha>

Before:

```ts
<3 lines above the range>
```

Lines:

```ts
<the commented lines, 40 to 48>
```

After:

```ts
<3 lines below the range>
```

Note:

<note text, verbatim>

Status: queued
````

A single line is `path:42`, with one line under `Lines:`. `Before:` and
`After:` are shorter at the top or bottom of a file. If the code contains
a ```` ``` ```` line, fence that block with four backticks.

`Status` is one of:

- `queued`: not posted yet.
- `skipped: <reason>`: a post attempt couldn't place it. Retried on the
  next post.
- `posted: <comment URL>`: on the PR.

## Anchoring

Line numbers and SHAs change on every rebase or amend; the code a note is
about usually doesn't. So the anchor is the text of `Lines:`. `Before:`
and `After:` break ties when that text appears more than once. The header
line number and `Captured at:` are hints for when the text itself changed.

## Arguments

- `/too-pr-note [path:line | path:start-end] <text>`: add a note.
- `/too-pr-note list`: list the notes and their status.
- `/too-pr-note post`: post the `queued` and `skipped` notes.

## Add a note

1. Binding: take `path:line` or `path:start-end` from the argument. If
   missing, use the file and lines under discussion in the current
   plannotator or too-1-by-1 session. If there are none, ask.
2. Read the lines from the working tree. For `Captured at:`, take
   `git stash create || git rev-parse HEAD`: a commit of the working tree,
   uncommitted lines included, that leaves the tree and stash list as they
   are. Append the block with `Status: queued`. Keep the note text as the user wrote it; offer
   `too-voice` only if asked.
3. Reply with one line echoing the binding, so a wrong guess shows now:
   `queued: src/foo.ts:40-48 "<note start>…" (3 queued)`. Then go back to
   the session the user was in.

Always queue, even when the PR exists: posting early leaves comments
outdated after the next amend.

## List the notes

Print each note numbered, as `path:line`, its status and its text, then
the count per status. If the queue is empty or missing, say so in one line.

On GitHub, check `posted` notes live with
`gh api repos/{owner}/{repo}/pulls/comments/<id>`, where `<id>` is the
number after `#discussion_r` in the URL. A `null` `line` means GitHub
marks it outdated: show `posted (outdated)`. A 404 means it was deleted:
show `posted (deleted)`.

The user can then drop or edit a note by number, or rebind it to new
lines. Editing a `posted` note only changes the queue; say so.

## Post the notes

Run when the user opens the PR, asks to create it, marks it ready for
review, or asks to post the notes.

1. Find the PR/MR, its head and its base as the `too-pr-draft-review`
   provider file says (`github.md`, `gitlab.md`). If none exists, say so
   and stop; the queue stays. Fetch the head if it isn't local
   (`git fetch origin <head>`). If the local branch is
   ahead of it, say the notes are placed against the pushed code, which
   lacks the unpushed commits, and offer to push first.
2. Place each `queued` or `skipped` note in `git show <head>:<path>`:
   - **Path gone:** look for a rename in
     `git diff -M --name-status <Captured at> <head>` and use the new
     path. The base branch won't show it when the branch added the file. If
     the snapshot is gone, skip: `file not found`.
   - **Exact:** find `Lines:` as consecutive lines, comparing each line
     with surrounding whitespace trimmed. One match is the new range. Several
     matches: keep the one with the most `Before:`/`After:` lines matching
     (either side may have changed).
   - **Changed:** no match, or a tie the context can't break. If the
     `Captured at:` commit still exists locally (`git cat-file -e <sha>`),
     follow the header lines through
     `git diff -M <sha> <head> -- <old path> <new path>` and offer the
     result as a candidate. Otherwise skip: `code changed`.
   - **Outside the diff:** inline comments take only lines inside one hunk of
     `git diff <base>...<head> -- <path>`, and a range must
     sit within a single hunk. Skip the rest: `outside the PR diff`.
3. Show the user every note with its new `path:line`, marking candidates
   from **Changed** and listing the skipped ones with reasons. Post only
   after they confirm; they can rebind or drop any note first.
4. Write each placed note to a review directory as `too-pr-draft-review`
   reads it (`path:line` or `path:start-end`, a blank line, the note text)
   and hand it over with the PR/MR URL, recommending `Comment`, and say
   the user confirmed step 3's preview. It posts the draft review and
   reports.
5. From its report, set each posted note to `posted: <comment URL>` (the
   PR/MR URL when the provider gives none) and the rest to
   `skipped: <reason>`.

Post the note text as written: notes are the user's own words, so the
`🤖 AI-flagged` label doesn't apply.
