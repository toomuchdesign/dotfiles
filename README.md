# .files

These are my dotfiles. Take anything you want, but at your own risk.

Initially forked from https://github.com/webpro/dotfiles. It targets only macOS systems.

## Package overview

- [Homebrew](https://brew.sh) (packages: [Brewfile](./install/Brewfile))
- [homebrew-cask](https://caskroom.github.io) (packages: [Caskfile](./install/Caskfile))
- [Node.js + npm LTS](https://nodejs.org/en/download/)
- [Plannotator](https://plannotator.ai) (not on Homebrew — installed via its official script by `make`; see [below](#plannotator))
- Claude Code agent skills & plugins ([superpowers](https://github.com/obra/superpowers), [mcollina/skills](https://github.com/mcollina/skills), [@playwright/cli](https://playwright.dev/docs/getting-started-cli); see [below](#claude-code-skills--plugins))
- Latest Git, ZSH, GNU coreutils, curl
- Modern CLI tooling — [Starship](https://starship.rs) prompt, `fzf`, `zoxide`, `fd`, `ripgrep`, `bat`, `delta` (see [Shell](#shell))

## Install

On a sparkling fresh installation of macOS:

```
sudo softwareupdate -i -a
xcode-select --install
```

The Xcode Command Line Tools includes `git` and `make` (not available on stock macOS).

Then, install this repo with `git` into the desired location:

```
git clone https://github.com/toomuchdesign/dotfiles.git ~/.dotfiles
```

Use the [Makefile](./Makefile) to install everything [listed above](#package-overview), and symlink [runcom](./runcom) and [config](./config) (using [stow](https://www.gnu.org/software/stow/)):

```
cd ~/.dotfiles
make
# or:
make install-minimal
```

`make install-minimal` installs a few less applications.

Most symlinked apps read their config without ever touching the file, but a few _write back_ to it — [cmux](https://github.com/manaflow-ai/cmux) rewrites [config/cmux/cmux.json](./config/cmux/cmux.json) (linked to `~/.config/cmux/cmux.json`) whenever you change a shortcut or layout option in its UI. As with iTerm2, that just shows up as a diff in this repo — commit it like any other change. cmux's session state lives separately under `~/Library/Application Support/cmux/` and is intentionally not tracked.

## Shell

The shell is [oh-my-zsh](https://ohmyz.sh) (for plugins) with the
[Starship](https://starship.rs) prompt and custom aliases and functions under
[`runcom/.oh-my-zsh/custom/`](./runcom/.oh-my-zsh/custom/), plus a set of modern
CLI tools wired up in [`runcom/.zshrc`](./runcom/.zshrc). Run `alias` to dump
every shortcut; the tables below cover the main ones.

### Interactive tools

Installed via the [Brewfile](./install/Brewfile) / oh-my-zsh plugins and activated on shell start:

| Tool                      | Invoke                        | What it does                                                      |
| ------------------------- | ----------------------------- | ----------------------------------------------------------------- |
| `starship`                | the prompt itself             | Prompt showing dir, git branch/status, Node version, cmd duration, exit status ([`starship.toml`](./config/starship.toml)) |
| `fzf`                     | `Ctrl-R` / `Ctrl-T` / `Alt-C` | Fuzzy search history / insert a file path / `cd` into a subdir    |
| `zoxide`                  | `z <frag>` / `zi <frag>`      | Jump to a frecent dir / pick one interactively (fzf)              |
| `fd`                      | `fd <name>`                   | Find files **by name** (fast, respects `.gitignore`)              |
| `rg` (ripgrep)            | `rg <pattern>`                | Search file **contents** (fast, respects `.gitignore`)            |
| `bat`                     | `bat <file>`                  | `cat` with syntax highlighting, line numbers and a git gutter     |
| `delta`                   | any `git diff` / `git show`   | Side-by-side, syntax-highlighted diffs (`n`/`N` to move by file)  |
| `jq` / `yq`               | `… \| jq '.'`                 | Query JSON (`jq`)                                                 |
| `thefuck`                 | `fuck`                        | Correct and rerun the previous command                            |
| `fnm`                     | automatic on `cd`             | Switch Node version per `.nvmrc` / `.node-version`                |
| `zsh-autosuggestions`     | `→` / `End` to accept         | History-based inline suggestions as you type                      |
| `zsh-syntax-highlighting` | automatic                     | Colours commands green/red for validity as you type               |

### Functions

Defined in [`functions.zsh`](./runcom/.oh-my-zsh/custom/functions.zsh):

| Function             | Usage                | Description                                                                     |
| -------------------- | -------------------- | ------------------------------------------------------------------------------- |
| `mk <dir>`           | `mk src/new-feature` | `mkdir -p` the path and `cd` into it                                            |
| `ff <name-fragment>` | `ff auth.controller` | Find files by name below the cwd (uses `fd`, falls back to `find`)              |
| `srv [port]`         | `srv 3000`           | Serve the current dir over HTTP (default `:8000`) and open the browser          |
| `killport <port>`    | `killport 3000`      | Kill whatever process is listening on a TCP port                                |
| `git-cleanup`        | `git-cleanup`        | Delete branches merged into `origin/master`, locally and (opt-in) on the remote |

### Aliases

Defined in [`aliases.zsh`](./runcom/.oh-my-zsh/custom/aliases.zsh) and, for macOS-specific ones, [`alias.macos.zsh`](./runcom/.oh-my-zsh/custom/alias.macos.zsh):

| Group      | Highlights                                                                                                                |
| ---------- | ------------------------------------------------------------------------------------------------------------------------- |
| Navigation | `..` `...` (up 1–2 levels), `-` (previous dir)                                                                            |
| Git        | `gs` status · `gdd` diff cached · `gca`/`gcaa` amend · `gp`/`gpu` pull/push · `gst`/`gsta` stash · `gls`/`gll` pretty log |
| npm        | `npms` start · `npmd` run dev · `npmr` run · `nui` upgrade deps                                                           |
| pnpm       | `pn` · `pns` start · `pnd` dev · `pnr` run · `pni` install · `pnx` exec · `pui` update interactive                        |
| yarn       | `yui` upgrade-interactive                                                                                                 |
| Docker     | `d` · `dps` ps · `dils` images · `dvls` volumes · `dcu`/`dcs`/`dcr` compose up/stop/restart                               |
| Network    | `ip` public IP · `ipl` local IP · `pubkey` copy SSH public key                                                            |
| macOS      | `showdotfiles`/`hidedotfiles` · `desktopshow`/`desktophide` · `emptytrash`                                                |

### Git aliases

Defined in [`config/git/config`](./config/git/config) — invoke as `git <alias>`:

| Alias               | Description                                                |
| ------------------- | ---------------------------------------------------------- |
| `git lg`            | Graph log, one line per commit, relative dates             |
| `git stbr`          | Local branches sorted by last commit date                  |
| `git pending`       | Local branches not yet merged into `origin/master`         |
| `git pruneasorigin` | Delete local branches whose remote tracking branch is gone |

## App configurations

Applications that can't be configured through a dotfile keep their exported settings in `install/<app-name>/`:

| App                                                 | Assets                                        | How it's applied                                                                        |
| --------------------------------------------------- | --------------------------------------------- | --------------------------------------------------------------------------------------- |
| [iTerm2](./install/iterm2/)                         | `com.googlecode.iterm2.plist`                 | iTerm2 reads and writes the folder itself, once pointed at it ([post-install](#iterm2)) |
| [Raycast](./install/raycast/)                       | `raycast-configuration.rayconfig`, `scripts/` | Manual import ([post-install](#raycast))                                                |
| [PDF quartz filters](./install/pdf-quartz-filters/) | `*.qfilter` (Preview/Print → `Quartz Filter`) | `make quartz-filters` copies them to `~/Library/Filters`                                |

To add another app: create `install/<app-name>/`, commit its exported configuration there, then either wire the import into the [Makefile](./Makefile) if it can be applied non-interactively, or document the manual steps under [Post-install](#post-install).

## Plannotator

[Plannotator](https://plannotator.ai) isn't on Homebrew, so the [`plannotator` Makefile target](./Makefile) installs it from its official script instead of a Brewfile/Caskfile. The `--non-interactive` run:

- drops the `plannotator` binary in `~/.local/bin` (already on `PATH` via [`runcom/.zshrc`](./runcom/.zshrc));
- checks out its Claude Code skills (`plannotator-review`, `plannotator-annotate`, `plannotator-last`) into `~/.claude/skills/` and wires the plan hook — **no separate skills step is needed**;
- integrates with coding agents it detects, which is why it runs after `packages` (so the `claude-code` cask already exists).

Both the binary and the skills are generated artifacts (like a `git` checkout), so nothing here is tracked in this repo. To change the extras / model-invocable choices skipped by `--non-interactive`, run `plannotator --reconfigure` by hand.

## Claude Code skills & plugins

`make` installs a few [Claude Code](https://claude.com/claude-code) agent add-ons under `~/.claude` (or `$CLAUDE_CONFIG_DIR`) via the [`claude-skills` Makefile target](./Makefile). Like plannotator's skills, these are generated artifacts installed from source, so nothing is tracked in this repo:

| Add-on                                                             | Kind                                                                 | How it's installed                                                                 |
| ------------------------------------------------------------------ | -------------------------------------------------------------------- | ---------------------------------------------------------------------------------- |
| [superpowers](https://github.com/obra/superpowers)                 | Claude Code **plugin** (hooks, `/brainstorm`, session-start context) | `claude plugin marketplace add` + `claude plugin install @superpowers-marketplace` |
| [mcollina/skills](https://github.com/mcollina/skills)              | Plain skills (no plugin manifest)                                    | shallow `git clone`, copied into `~/.claude/skills/`                               |
| [@playwright/cli](https://playwright.dev/docs/getting-started-cli) | npm CLI + its own skill                                              | `npm i -g @playwright/cli@latest` + `playwright-cli install --skills`              |

Runs after `packages` so the `claude` CLI and Node are available. The superpowers step may prompt once to trust its marketplace — answer it interactively. Re-running the target refreshes each add-on to its latest version.

An alternative to the imperative `superpowers` target would be to declare the marketplace + plugin in a global `~/.claude/settings.json` (`extraKnownMarketplaces` + `enabledPlugins`) and let Claude Code auto-install on startup — but this repo doesn't manage `~/.claude`, so the Makefile route is used instead.

## Post-install

### iTerm2

Point iTerm2 at [install/iterm2/](./install/iterm2/) so it loads its preferences from this repo:

`Settings` > `General` > `Preferences` > check `Load preferences from a custom folder or URL` > select `~/.dotfiles/install/iterm2` > set `Save changes` to `Automatically`

Restart iTerm2. Everything else (zsh as custom shell, colors, keybindings, font) comes from the plist.

To change the colour scheme, pick one of iTerm2's built-in presets: `Settings` > `Profiles` > `Colors` > `Color Presets…`. The [Starship](#shell) prompt uses only plain Unicode glyphs, so no Nerd Font is required.

Because iTerm2 also _writes_ to the preferences folder, any UI change (colors, font, keybindings) is captured back into the tracked plist — so it only needs doing once, then commit the diff like any other change.

### DropBox

Login and sync DropBox.

### Raycast

Import configuration from [install/raycast/raycast-configuration.rayconfig](./install/raycast/raycast-configuration.rayconfig).

Then register the script commands: `Settings` > `Extensions` > `Script Commands` > `Add Directories` > select `~/.dotfiles/install/raycast/scripts`.

### Chrome

Install the following extensions:

- [uBlock Origin Lite](https://chromewebstore.google.com/detail/ublock-origin-lite/ddkjiahejlhfcafbddmgiahcphecmpfh?hl=en)
- [React Developer Tools](https://chrome.google.com/webstore/detail/react-developer-tools/fmkadmapgofadopljbjfkapdkoienihi?hl=en)
- [Floccus](https://chromewebstore.google.com/detail/floccus-bookmarks-sync/fnaicdffflnofjppbagibeoednhnbjhg)
- [Auto Quality for YouTube](https://chromewebstore.google.com/detail/auto-quality-for-youtube/iaddfgegjgjelgkanamleadckkpnjpjc)

Configure search engines (`Manage search engines`):

| name             | Query URL                                                       | key binding |
| ---------------- | --------------------------------------------------------------- | ----------- |
| Duckduckgo       | https://duckduckgo.com/?q=%s                                    | `d`         |
| Google maps      | https://www.google.com/maps/search/%s                           | `gm`        |
| Google translate | https://translate.google.com/?&op=translate&sl=it&tl=en&text=%s | `gt`        |
| npm              | https://www.npmjs.com/search?q=%s                               | `n`         |
| Word Reference   | http://www.wordreference.com/iten/%s                            | `wr`        |
| YouTube          | https://www.youtube.com/results?search_query=%s                 | `yt`        |

### Keyboard layouts

Add the **U.S.** and **U.S. International – PC** input sources:

`Settings` > `Keyboard` > `Text Input` > `Input Sources` > `Edit…` > `+` > `English` > pick `U.S.` and `U.S. International – PC` > `Add`

Switch between them with `Ctrl-Space` (or whatever `Input Sources` shortcut is set under `Keyboard Shortcuts`).

### VSC

- Open `VSC` settings `cmd + ,`
- Connect `Code settings` extension to GitHub
- Run `Sync: Download Settings`

## Local overrides

Machine-specific settings (work email, private hosts, secrets, per-machine tweaks) must **never** be committed. Two untracked files exist for that purpose. Both are [git-ignored](./.gitignore), so they are safe to edit freely:

| File                                           | Overrides                         | Created by `make link`                                                                                       |
| ---------------------------------------------- | --------------------------------- | ------------------------------------------------------------------------------------------------------------ |
| `config/git/config.untracked`                  | [git config](./config/git/config) | Copied from [`config.untracked.example`](./config/git/config.untracked.example) if absent (never overwritten) |
| `runcom/.oh-my-zsh/custom/local.untracked.zsh` | zsh setup                         | Created empty                                                                                                 |

The git template is committed (with commented placeholders only — no real values), so a fresh machine gets a documented starting point without any secret ever being tracked. `make link` seeds the copy only when it's missing, so re-running never clobbers your machine's populated file.

Both are read **after** their tracked counterpart, so any value they define wins. For git this is guaranteed by the position of the `[include]`; for zsh it follows from oh-my-zsh sourcing `custom/*.zsh` alphabetically (`local.*` sorts after `alias*`/`functions*`).

The git one is pulled in by an `[include]` directive at the end of [config/git/config](./config/git/config) and uses standard git config syntax:

```ini
[user]
	email = me@work-company.com
```

Verify an override is being picked up with:

```
git config --show-origin --get user.email
```

Note that `git config --global <key>` won't show included values unless `--includes` is passed — that flag is only off for explicitly scoped queries, not for git's own reads.

## Credits

Many thanks to [webpro](https://github.com/webpro/dotfiles), which provided the initial foundation.

## Todos

- Auto configure local `dotfiles` git config with personal user info
