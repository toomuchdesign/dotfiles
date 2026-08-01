# .files

These are my dotfiles. Take anything you want, but at your own risk.

Initially forked from https://github.com/webpro/dotfiles. It targets only macOS systems.

## Package overview

- [Homebrew](https://brew.sh) (packages: [Brewfile](./install/Brewfile))
- [homebrew-cask](https://caskroom.github.io) (packages: [Caskfile](./install/Caskfile))
- [Node.js + npm LTS](https://nodejs.org/en/download/)
- Latest Git, ZSH, GNU coreutils, curl

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

## App configurations

Applications that can't be configured through a dotfile keep their exported settings in `install/<app-name>/`:

| App                                                 | Assets                                        | How it's applied                                                                        |
| --------------------------------------------------- | --------------------------------------------- | --------------------------------------------------------------------------------------- |
| [iTerm2](./install/iterm2/)                         | `com.googlecode.iterm2.plist`                 | iTerm2 reads and writes the folder itself, once pointed at it ([post-install](#iterm2)) |
| [Raycast](./install/raycast/)                       | `raycast-configuration.rayconfig`, `scripts/` | Manual import ([post-install](#raycast))                                                |
| [PDF quartz filters](./install/pdf-quartz-filters/) | `*.qfilter` (Preview/Print → `Quartz Filter`) | `make quartz-filters` copies them to `~/Library/Filters`                                |

To add another app: create `install/<app-name>/`, commit its exported configuration there, then either wire the import into the [Makefile](./Makefile) if it can be applied non-interactively, or document the manual steps under [Post-install](#post-install).

## Post-install

### iTerm2

Point iTerm2 at [install/iterm2/](./install/iterm2/) so it loads its preferences from this repo:

`Settings` > `General` > `Preferences` > check `Load preferences from a custom folder or URL` > select `~/.dotfiles/install/iterm2` > set `Save changes` to `Automatically`

Restart iTerm2. Everything else (zsh as custom shell, colors, keybindings) comes from the plist, so there is nothing left to set by hand.

Because iTerm2 also _writes_ to that folder, any preference changed in the UI shows up as a diff in this repo — commit it like any other change.

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

### VSC

- Open `VSC` settings `cmd + ,`
- Connect `Code settings` extension to GitHub
- Run `Sync: Download Settings`

## Local overrides

Machine-specific settings (work email, private hosts, secrets, per-machine tweaks) must **never** be committed. Two untracked files exist for that purpose. Both are [git-ignored](./.gitignore) and created empty by `make link`, so they are safe to edit freely:

| File                                           | Overrides                         |
| ---------------------------------------------- | --------------------------------- |
| `config/git/config.untracked`                  | [git config](./config/git/config) |
| `runcom/.oh-my-zsh/custom/local.untracked.zsh` | zsh setup                         |

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

Many thanks to the [dotfiles community](https://dotfiles.github.io).

## Todos

- Auto configure local `dotfiles` git config with personal user info
