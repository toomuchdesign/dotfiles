# GitLab: draft notes

Draft notes are visible only to the user until they press Submit review
on the MR. Docs: [draft notes](https://docs.gitlab.com/api/draft_notes/),
[diff positions](https://docs.gitlab.com/api/discussions/#create-a-new-thread-in-the-merge-request-diff).

Needs `glab`, authenticated. Without it, stop: show the items and say
`brew install glab && glab auth login`. Use `glab api` throughout:
`glab mr note` publishes at once, and its `draft` subcommand is
experimental.

## Read

`:id` resolves to the current repo's project. Outside the repo, use the
URL-encoded path (`group%2Fproject`).

```sh
glab api projects/:id/merge_requests/<iid>        # web_url, diff_refs{base_sha,start_sha,head_sha}
glab api projects/:id/merge_requests?source_branch=<branch>&state=opened   # find the MR for a branch
git diff <diff_refs.start_sha>...<diff_refs.head_sha>   # fetch the SHAs first if missing
glab api --paginate projects/:id/merge_requests/<iid>/discussions
glab api projects/:id/merge_requests/<iid>/draft_notes   # the user's existing drafts
```

A `reply` URL ends in `#note_<id>`: its discussion is the one holding that
note.

## Post

One `POST projects/:id/merge_requests/<iid>/draft_notes` per item. New
drafts join any the user already has into the same review.

Inline comment, on the new side of the diff:

```sh
glab api -X POST projects/:id/merge_requests/<iid>/draft_notes \
  -H 'Content-Type: application/json' --input - <<'EOF'
{"note": "...",
 "position": {"position_type": "text", "base_sha": "<base>", "start_sha": "<start>", "head_sha": "<head>",
              "old_path": "src/a.ts", "new_path": "src/a.ts", "new_line": 48}}
EOF
```

- An added line takes `new_line` only. An unchanged context line also
  needs `old_line`, read from the hunk header.
- A range `path:40-48` anchors on its last line (48). A suggestion over
  the range becomes ```` ```suggestion:-8+0 ````; on GitHub it is a plain
  ```` ```suggestion ````. Say so in the preview.
- Summary: a draft note with no `position`. It posts as an overview
  comment when the user submits.
- Reply: `{"note": "...", "in_reply_to_discussion_id": "<discussion id>"}`.

## Notes

- Never call `draft_notes/bulk_publish` or `draft_notes/<id>/publish`:
  that is the user's Submit.
- Link to report: `<web_url>/diffs`.
