---
name: too-sync-master
description: Use for "/too-sync-master [rebase|merge]", "sync with master/main", "rebase on master", "merge master in", "update my branch", "my PR is behind / has conflicts". Brings the current branch up to date with its base, resolves conflicts (lockfiles and generated files included, any package manager), refreshes content derived from the code (generated files, line and commit references, hash-pinned docs), reruns lint and typecheck on the branch's files, then pushes.
---

# Sync with the base branch

Bring the current branch up to date with its base branch and push it. There are two modes:

| Mode     | Does                                   | Push                          | Pick it when                                                                       |
| -------- | -------------------------------------- | ----------------------------- | ---------------------------------------------------------------------------------- |
| `rebase` | Replays the branch on top of the base  | `git push --force-with-lease` | Nobody has reviewed yet, or the user wants linear history                          |
| `merge`  | Adds one merge commit, history is kept | `git push`                    | Reviewers are on the PR: their comments and "changes since last review" stay valid |

The mode comes from the argument. Without one, ask with `AskUserQuestion` (options `rebase` and `merge`, free text allowed) and don't guess.

Invoking the skill is the user's permission to rewrite and push this branch. That permission never covers the default branch.

Do the whole job with git and the repo's own tools. Don't invoke other skills (conflict resolvers, commit folders, CI fixers): each one brings its own rules, and the steps here already cover the job.

## 1. Preflight

```sh
git status --porcelain ; git branch --show-current ; git rev-parse HEAD ; git remote -v
gh pr view --json baseRefName,baseRepository,url 2>/dev/null
```

- Stop if the working tree is dirty. Ask whether to commit or stash first; don't stash on your own.
- Note the starting SHA. It is the way back: `git reset --hard <sha>`.

Never assume the base is called `master`. Find it, first match wins:

1. The PR's `baseRefName`. A PR can target any branch (`main`, `develop`, a release branch).
2. The remote's default branch: `git symbolic-ref --short refs/remotes/<remote>/HEAD`. If unset, `git remote set-head <remote> --auto` sets it.
3. `gh repo view --json defaultBranchRef -q .defaultBranchRef.name`.
4. Whichever of `main` / `master` exists on the remote (`git ls-remote --heads <remote> main master`). If both or neither exist, ask.

`<remote>` is the one hosting the base: `origin` normally, `upstream` in a fork whose PR targets the parent repo (match `baseRepository` against `git remote -v`). `<base>` and `<remote>` below mean the values found here. Stop if the current branch is the repo's default branch or `<base>` itself.

Then fetch and see how far behind the branch is:

```sh
git fetch <remote>
git log --oneline HEAD..<remote>/<base> | wc -l
```

If it is 0 commits behind, say so and stop.

## 2. Sync

Turn on rerere for this run so a conflict resolved once is reused when the same hunk shows up again (a rebase replays every commit):

```sh
git -c rerere.enabled=true rebase --exec '<checks>' <remote>/<base>  # rebase mode
git -c rerere.enabled=true merge --no-edit <remote>/<base>           # merge mode
```

`<checks>` is the lint and typecheck from step 5, joined with `&&`. The rebase stops after the first commit that fails them. Fix it there, `git commit --amend --no-edit`, then continue. Every replayed commit ends up passing, and the fix lands in the commit it belongs to. If a check also fails on the base, the failure isn't the branch's: continue past it and report it.

Any existing merge commits from earlier syncs disappear in a rebase. That is expected.

On a conflict, resolve as below, `git add` the files, then continue without opening an editor:

```sh
GIT_EDITOR=true git -c rerere.enabled=true rebase --continue   # rebase
GIT_EDITOR=true git commit --no-edit                           # merge
```

If a conflict can't be resolved with confidence, `git rebase --abort` / `git merge --abort`, report the file and both intents, and stop.

## 3. Resolve conflicts

Side names flip between modes. In a **rebase**, `ours` is the base and `theirs` is the branch commit being replayed. In a **merge**, `ours` is the branch and `theirs` is the base.

For source files, read why each side changed before editing:

```sh
git log --oneline -3 <remote>/<base> -- <file>   # what landed upstream
git diff <starting-sha>...<remote>/<base> -- <file>
```

Keep both intents: the upstream change and the branch's change. When upstream renamed or moved something the branch uses, follow the rename in the branch's code instead of restoring the old name. Never resolve by taking one whole side unless the other side's change is truly superseded, and say so in the report.

Follow what each commit meant to do, read from its message and diff. When the two intents contradict, so that keeping both is impossible and the result differs from what one side wanted (the branch prints `12.00 €`, upstream prints `$12.00`), pick the closer fit, keep going, and list it under **Check this** in the report.

### Lockfiles

Never hand-merge a lockfile. Resolve its manifest (`package.json`, `Cargo.toml`, …) first, take the base's lockfile, then regenerate it so it matches the resolved manifest:

```sh
git checkout <remote>/<base> -- <lockfile>
```

| Lockfile                  | Regenerate                                |
| ------------------------- | ----------------------------------------- |
| `package-lock.json`       | `npm install --package-lock-only`         |
| `pnpm-lock.yaml`          | `pnpm install --lockfile-only`            |
| `yarn.lock` (Berry, v2+)  | `yarn install --mode=update-lockfile`     |
| `yarn.lock` (Classic, v1) | `yarn install --ignore-scripts`           |
| `bun.lock`, `bun.lockb`   | `bun install --lockfile-only`             |
| `Cargo.lock`              | `cargo update --workspace`                |
| `go.sum`                  | `go mod tidy`                             |
| `poetry.lock`             | `poetry lock` (Poetry < 2: `--no-update`) |
| `uv.lock`                 | `uv lock`                                 |
| `Pipfile.lock`            | `pipenv lock`                             |
| `Gemfile.lock`            | `bundle lock`                             |
| `composer.lock`           | `composer update --lock`                  |

Use the version the repo pins: the `packageManager` field (corepack), `.nvmrc` / `.node-version`, `rust-toolchain.toml`. A lockfile regenerated by another major version rewrites the whole file. For anything not in the table, use that tool's command that updates only the lockfile.

### Generated files

Resolve a file a repo command produces (codegen types, API clients, built docs, snapshots, anything headed `@generated` or `DO NOT EDIT`) like a lockfile: take the base's version, resolve its sources, then rerun the generator. Never hand-merge it.

## 4. Refresh derived content

A sync moves lines, and a rebase gives every branch commit a new SHA. Content derived from the code at one point goes stale even without a conflict. Find the commands where you found the checks, plus the repo's agent instructions (`AGENTS.md`, `CLAUDE.md`), which may name a docs tool and its commands.

- **Generated files**: rerun each generator whose inputs the sync changed, then check `git status`.
- **Line and commit references** the branch adds (`file.ts:42`, `#L42`, `/blob/<sha>/`, `/commit/<sha>`):

  ```sh
  git diff -U0 <remote>/<base>...HEAD | grep -E '\.[a-z]+:[0-9]+|#L[0-9]+|/(blob|tree|commit)/[0-9a-f]{7,40}'
  ```

  Check each line reference still points at the code it describes, and fix the number. After a rebase, the branch's old SHAs vanish from the remote on push: `git range-diff <starting-sha>...HEAD` pairs each old commit with its new SHA.

- **Docs pinned to code by hash**: tools that store a content hash or SHA per doc line or snippet, usually in a config folder or markers next to the text. Never edit the hashes by hand. Run the tool's check command, then its update command where the code moved without changing meaning. Where a snippet's code really changed, update the doc text too, or list it under **Check this** if the right wording isn't clear.

Where fixes land:

- **Rebase**: `git commit --fixup=<commit that introduced the file or reference>`, then `GIT_SEQUENCE_EDITOR=: git rebase --autosquash <remote>/<base>`, and rerun the checks.
- **Merge**: one commit after the merge, e.g. `chore: refresh derived content after syncing with <base>`.

## 5. Static checks

Pick the commands before syncing, since rebase mode runs them during the rebase. Use what the repo already uses: `package.json` scripts (`lint`, `typecheck`, `check-types`, `tsc`), the Makefile, the CI workflow. Run them as CI does, with the package manager the lockfile belongs to.

- **Lint**: the files the branch changes, when the linter takes file arguments (`npx eslint <files>`, `ruff check <files>`). Otherwise run the whole script.

  ```sh
  git diff --name-only --diff-filter=d <remote>/<base>...HEAD
  ```

- **Typecheck**: whole project (`tsc --noEmit`, `cargo check`, `mypy`, `go vet ./...`). Types cross files, so per-file runs miss breakage.

In rebase mode the checks already ran per commit. In merge mode run them once after the merge. When one fails, find out whether the sync caused it: if it isn't clear, run the same check at `<remote>/<base>` in a `git worktree add` on a temp dir, and remove the worktree afterwards.

- **Caused by the sync** (an upstream rename, a changed signature): fix it in a separate commit after the merge, e.g. `fix: adapt <thing> to <base> changes`, so reviewers see it apart from the merge.
- **Already failing on the base**: leave it and report it.

Push only when every check the sync could affect passes.

## 6. Push

```sh
git push --force-with-lease   # rebase
git push                      # merge
```

Add `-u origin HEAD` when the branch has no upstream. If `--force-with-lease` is rejected, someone else pushed to the branch: stop and report, don't retry with `--force`.

## Report

Open with **Check this** when a conflict had contradicting intents, or a hash-pinned doc's code changed meaning: one line each with the file, what each side wanted, what was picked, and how to flip it. Leave the heading out when there were none.

- Mode, base, and the range: `<starting-sha>` → `<new-sha>`, N upstream commits pulled in.
- Each conflict: file, what each side changed, how it was resolved.
- Lockfiles regenerated, with the command used.
- Derived content: each generator run, and each reference or pinned doc updated, with the command used.
- Each check run, with its command and result. List any failure that was already on the base.
- Push result, or why it didn't push.
