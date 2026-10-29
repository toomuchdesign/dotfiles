---
name: too-review-all
description: Use for "/too-review-all", "run all the reviews", "full review", or when the user wants several code reviewers run on the same change and their findings reconciled into one list. Works on the local branch or on a GitHub PR given by number or URL.
---

# Review all

Run several independent reviewers on one diff, reconcile their findings once, and write them to `findings.md`. Deciding on them is `too-1-by-1`'s job: on the local branch the decisions are code changes; on a PR they are review comments, posted by [pr-contract.md](pr-contract.md).

## 1. Target

**Local mode** (no argument, or a branch name): detect the base the way `too-pr-description` does, then `git diff <base>...HEAD`.

**PR mode** (number or URL). The working directory must be a clone of the PR's repo; otherwise stop and say so.

```sh
gh pr view <pr> --json number,url,title,body,author,baseRefName,headRefOid
gh api user --jq .login
```

If the PR author is the current user, suggest local mode from the checked-out branch instead: GitHub won't take `REQUEST_CHANGES` on your own PR, and you'd fix rather than comment. Otherwise check the head out into a temporary worktree, tell the user its path; `too-1-by-1` removes it after posting:

```sh
git fetch origin <baseRefName> "pull/<n>/head"
wt="$(mktemp -d)/pr-<n>" ; git worktree add --detach "$wt" <headRefOid> ; printf '%s\n' "$wt"
git -C "$wt" diff origin/<baseRefName>...HEAD
```

Put the worktree in the session's scratchpad directory when there is one. Fetch existing feedback so it isn't repeated: `gh api repos/{owner}/{repo}/pulls/<n>/comments --paginate` and `gh pr view <n> --comments`.

If `gh` isn't authenticated, read the PR from the public API instead (`curl -s https://api.github.com/repos/{owner}/{repo}/pulls/<n>` and its `/comments`); posting then stops at the preview.

Stop on an empty diff. Then state the intent in one paragraph from the PR body, commits, linked issue or plan; ask if it's unclear.

## 2. Reviewer sources

Read the prompts from the installed plugins, newest version:

```sh
P=~/.claude/plugins/cache
ls -d $P/pstack-claude/pstack/*/skills/interrogate/references | sort -V | tail -1
ls -d $P/superpowers-marketplace/superpowers/*/skills/requesting-code-review | sort -V | tail -1
ls -d $P/mattpocock/mattpocock-skills/*/skills/engineering/code-review | sort -V | tail -1
```

If one is missing, skip its seat and say which. Don't write a substitute prompt.

## 3. Seats

Launch every seat in one message as read-only `general-purpose` agents. In PR mode each works inside `$wt`; a seat that needs to compile or build copies the tree first (`git -C "$wt" archive HEAD | tar -x -C "$(mktemp -d)"`).

| Seat | Prompt | Runs |
|---|---|---|
| interrogate ×N | `reviewer-prompt.md` filled with the intent, diff, `rubric.md` and `code-quality-review.md`. One agent per `interrogate reviewers` model in `~/.claude/pstack-models.md`, else one each of the current Opus, Fable and Sonnet | always |
| plan | `code-reviewer.md` filled with the intent, the plan or spec (or "none given"), base and head SHAs | always |
| correctness | invoke the `code-review` skill on the target, report only: no `--comment`, no `--fix`. It reviews the session's working directory, so in PR mode pass the PR number, or without `gh` have the seat follow its recipe by hand on the diff | always |
| standards | the Standards sub-agent brief and smell baseline from mattpocock's `SKILL.md` steps 3–4, with the repo's standards files | the repo documents coding standards |
| security | invoke the `security-review` skill | diff touches auth, sessions, permissions, secrets, crypto, or user input reaching a query, shell or HTML |
| blast radius | invoke the `pstack:blast-radius` skill | diff changes an exported API, schema, wire format or shared config |

Append to every seat prompt: "Return each finding as `### <critical|warning|nit> <title>` with `Location: <repo-relative path>:<line>`, `Finding`, `Evidence`, optional `Suggestion`. Zero findings is a valid answer."

## 4. Reconcile

In PR mode, first check `git -C "$wt" rev-parse HEAD` still equals headRefOid; a seat that moved it gets `git -C "$wt" reset -q <headRefOid>` and a mention.

Act as the lead reviewer in interrogate's `lead-judgment.md`, over all seats at once:

1. Merge findings that describe the same problem; record every seat that raised it. Two or more seats is consensus.
2. Read the code at each Act on / Consider location and drop what doesn't hold.
3. PR mode: drop findings an existing comment already raises, naming who raised them.
4. Bucket into Act on, Consider, Noted, Dismissed.

## 5. Recap and hand off

Write `findings.md` in a directory of its own, so concurrent runs never share a path, and print it. Create the file only through this; never write to a fixed `findings.md` path:

```sh
f="$(mktemp -d "${SCRATCH:-${TMPDIR:-/tmp}}/review-all.XXXXXX")/findings.md" ; printf '%s\n' "$f"
```

`SCRATCH` is the session's scratchpad directory when there is one. The file looks like:

````markdown
---
source: too-review-all
target: <PR URL, or the branch>
base: <base ref>
head: <headRefOid, or HEAD's SHA>
worktree: <$wt, PR mode only>
contract: <absolute path of this skill's pr-contract.md, PR mode only>
default: <numbers of Act on + Consider>
---

## Act on

### 1 · ▮▮▮ <title>
Location: /absolute/path/file.ts:42
Seats: <seats> · Proven: <yes, how | no>
<finding, evidence, suggestion>

## Consider
## Noted
## Dismissed
````

Number across Act on and Consider. Meters follow `too-1-by-1`: critical `▮▮▮`, warning `▮▮▯`, nit `▮▯▯`.

Then show the recap and stop, even when the user asked to go straight into deciding:

- a seats table: seat, model, finding count, or why it was skipped
- the four buckets with each finding's number, meter, location, seats and proof
- a short agreement map
- the next step: `/too-1-by-1 <path>` decides Act on + Consider; add numbers (`/too-1-by-1 <path> 1,3,5`) to pick others. It can run in a fresh session. In PR mode the worktree stays until that run posts the review.

## Common mistakes

- Running `/pstack:interrogate` whole: its own judge filters before the other seats are seen, so cross-seat consensus is lost. Use its prompt files as seats.
- Adding `simplify`, `pstack:no-comments` or `code-review --fix`: seats must not edit code.
- Starting `too-1-by-1` from here: stop at the recap so the user can read and edit `findings.md` first. If they asked to go straight on, say so, and that a reply of `go` starts `/too-1-by-1 <path>`.
