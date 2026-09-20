---
name: toomuchdesign-relink
description: Use when consuming a locally-built sibling package (e.g. a local @scope/* clone) inside another project as if it were published — links by pack+install, not symlink, so shared singletons (react, redux, a shared core package) stay deduped. Works with npm, yarn, and pnpm. Also handles unlinking (restore).
---

# relink

Make a consumer project use your **local** build of a package as if it were published from the registry.

## Why not `npm/yarn/pnpm link`?

Those symlink the consumer to the source dir. A symlinked package resolves its own
dependencies from its **own** `node_modules`, so shared singletons load twice —
duplicate `react` ("Invalid hook call"), a duplicate shared `@scope/core` (broken
`instanceof`/identity), duplicate redux context. `relink` instead **packs** the source
(exactly what `publish` ships) and **installs the tarball flat**, so there is one copy
of each shared dep. It also survives `rm -rf node_modules && install`, because the
dependency is recorded declaratively.

## Usage

```bash
# link ../my-lib into the current project (tarball mode, auto-detected PM)
bash relink.sh ../my-lib

# link into an explicit consumer, force pnpm, skip the source build
bash relink.sh ../ui-kit --into ~/dev/app --pm pnpm --no-build

# ephemeral: copy into node_modules only, never touch package.json
bash relink.sh ../core --mode copy

# undo: restore the published version (or remove the override)
bash relink.sh restore ../my-lib
bash relink.sh restore @scope/my-lib   # by name also works
```

Run it from the consumer project, or pass `--into <consumer>`.

## Options

| Flag | Default | Meaning |
|---|---|---|
| `--into DIR` | cwd | Consumer project to link into |
| `--mode tarball\|copy` | `tarball` | `tarball` survives node_modules nukes but writes a `file:` line into package.json; `copy` leaves package.json clean but must be re-run after every reinstall |
| `--pm npm\|yarn\|pnpm` | auto | Override package-manager detection for the consumer |
| `--no-build` | build on | Skip running the source's `build` script |

## What it does (tarball mode)

1. Detects the package manager (from `packageManager` field, then lockfile, then availability).
2. Builds the source (if it has a `build` script) so `dist` is fresh.
3. `pack`s it into a stable tarball at `~/.relink-store/tarballs/<name>.tgz` (stable name → package.json doesn't churn on rebuild; just re-run to refresh).
4. Installs that tarball into the consumer.
5. Guards the no-lockfile case: if the repo had no lockfile, any lockfile the install generates is removed.
6. Warns if more than one `react` version ends up resolved.

## Caveats

- **Tarball mode dirties `package.json`** (`"<name>": "file:~/.relink-store/…tgz"`). Don't commit that line. `restore` puts the original spec back.
- Package managers reformat `package.json` on `add`/`remove` — expect that churn regardless of this skill.
- Re-run `relink` after changing the source to rebuild+repack; in `tarball` mode a plain reinstall also refreshes from the (re-packed) tarball.
- `restore` needs a reinstall to fully drop the local copy from `node_modules`.

## Notes for the agent

- This is deterministic — always run `relink.sh`; do not hand-roll linking with symlinks.
- Prefer `tarball` mode unless the user is worried about an accidental package.json commit.
- After linking, verify the consumer actually resolves the local build (e.g. a quick typecheck or import) before reporting success.
