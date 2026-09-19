# AGENTS.md

macOS dotfiles. See `README.md` for install, per-app config, and local-override mechanics — not repeated here. Only non-discoverable landmines below.

## Landmines

- **Never run `make` / `make install` / `make install-minimal` / `make link` to "verify" a change.** These mutate the _real machine_, not a sandbox: `sudo`, `chsh` the default shell, `brew bundle` installs, and `stow` symlinks over `$HOME`. There is no dry-run target here — the only `stow -n` checks are commented at the bottom of the `Makefile`. Reason about correctness by reading, don't execute the install.
- **After `make link`, tracked files under `runcom/` and `config/` are the live config via stow symlinks** (`runcom/` → `$HOME`, `config/` → `~/.config`). Editing a repo file changes the user's active shell/git config immediately — treat edits as live, not as a staging copy.
- **`install/iterm2/com.googlecode.iterm2.plist` is written by iTerm2 itself.** Don't hand-edit it; changes made in the iTerm2 UI show up here as diffs to commit.
- **Never commit configuration changes automatically.** Apps that write back to tracked files (iTerm2, cmux, and any other symlinked `config/` app) constantly produce config diffs. Do not stage or commit them — or any config edit — unless the user explicitly asks. Leave drift in the working tree for the user to review.

## Keep docs in sync

`README.md` is the hand-maintained record of what this repo installs and how to use it — it never regenerates itself. Whenever you add, change, or remove something a `make` target installs, update the matching part of `README.md` in the same change so it stays a usable reference:

- **The `## Shell` section** — for any function (`runcom/.oh-my-zsh/custom/functions.zsh`), alias (`aliases.zsh`, `alias.macos.zsh`), git alias (`config/git/config`), or interactive CLI tool wired up in `runcom/.zshrc` / the `Brewfile`, update the matching table.
- **The `## Claude Code skills & plugins` section** — for any skill, plugin, hook, or global config the `claude-skills` / `claude-config` targets install (`install/claude/`), update the relevant table and note how to invoke it.
- **Any other new tool** — if it's installed by `make` and has a usage worth remembering, document it (which target installs it, how to run it, and post-install steps if any).

## Validation

No CI, tests, or build. Formatting only: prettier reads `config/prettier/.prettierrc` (note `bracketSpacing: false`, `singleQuote`), but nothing runs it automatically — apply it yourself when touching formatted files.
