# GitHub: draft (pending) review

A review created without `event` stays `PENDING`, visible only to the user
until they submit it under Files changed › Finish your review.
Docs: [create a review](https://docs.github.com/en/rest/pulls/reviews#create-a-review-for-a-pull-request),
[GraphQL mutations](https://docs.github.com/en/graphql/reference/mutations).

## Read

```sh
gh pr view <url|number> --json id,number,headRefOid,baseRefName,url   # no arg: current branch
gh pr diff <n>
```

Existing threads, the user's pending review and their IDs (paginate
`reviewThreads` past 100):

```sh
gh api graphql -F o={owner} -F r={repo} -F n=<n> -f query='
query($o:String!,$r:String!,$n:Int!){repository(owner:$o,name:$r){pullRequest(number:$n){
  reviews(states:PENDING,first:1){nodes{id databaseId body}}
  reviewThreads(first:100){nodes{id path line comments(first:50){nodes{databaseId body}}}}}}}'
```

A `reply` URL ends in `#discussion_r<databaseId>`: its thread is the one
holding that comment.

## Post

**No pending review yet:** create one with the inline comments and the
summary. Never put `event` in it.

```sh
gh api repos/{owner}/{repo}/pulls/<n>/reviews --input - <<'EOF'
{"commit_id": "<head>", "body": "<summary>",
 "comments": [
  {"path": "src/a.ts", "line": 42, "side": "RIGHT", "body": "..."},
  {"path": "src/a.ts", "start_line": 40, "start_side": "RIGHT", "line": 48, "side": "RIGHT", "body": "..."}
 ]}
EOF
```

The response's `node_id` is the review ID for the replies below.

**A pending review already exists:** GitHub allows one per user per PR.
Add to it instead of creating another: each inline comment through
`addPullRequestReviewThread` (`pullRequestReviewId`, `path`, `line`,
`side: RIGHT`, `startLine`/`startSide` for a range, `body`), and append
the summary to its body with `PUT repos/{owner}/{repo}/pulls/<n>/reviews/<databaseId>`
(`{"body": "<existing>\n\n<summary>"}`). Say you joined an existing draft.

**Replies,** always through GraphQL and into the pending review (the REST
`/replies` endpoint publishes at once):

```sh
gh api graphql -F t=<thread id> -F rv=<review node id> -F b=@reply.md -f query='
mutation($t:ID!,$rv:ID!,$b:String!){addPullRequestReviewThreadReply(input:{
  pullRequestReviewThreadId:$t,pullRequestReviewId:$rv,body:$b}){comment{url}}}'
```

With only replies to post, first create an empty pending review:
`addPullRequestReview(input:{pullRequestId:<PR id>, commitOID:<head>})`,
no `event`.

## Notes

- `422` on create rejects the whole review: find the comment GitHub
  couldn't place (usually a line outside the diff), move it to the
  summary, post again.
- Item URLs: `gh api repos/{owner}/{repo}/pulls/<n>/reviews/<databaseId>/comments`,
  field `html_url`.
- Link to report: `<url>/files`.
