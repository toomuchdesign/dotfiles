# .files

These are my dotfiles. Take anything you want, but at your own risk.

It targets macOS systems, but it should work on \*nix as well (with `apt-get`).

## Package overview

- [Homebrew](https://brew.sh) (packages: [Brewfile](./install/Brewfile))
- [homebrew-cask](https://caskroom.github.io) (packages: [Caskfile](./install/Caskfile))
- [Node.js + npm LTS](https://nodejs.org/en/download/) (packages: [npmfile](./install/npmfile))
- Latest Ruby (packages: [Gemfile](./install/Gemfile))
- Latest Git, Bash 4, Python 3, GNU coreutils, curl
- [Hammerspoon](https://www.hammerspoon.org) (config: [keybindings & window management](./config/hammerspoon))
- [Mackup](https://github.com/lra/mackup) (sync application settings)
- `$EDITOR` (and Git editor) is VIM

## Install

On a sparkling fresh installation of macOS:

    sudo softwareupdate -i -a
    xcode-select --install

The Xcode Command Line Tools includes `git` and `make` (not available on stock macOS).
Then, install this repo with `curl` available:

    bash -c "`curl -fsSL https://raw.githubusercontent.com/toomuchdesign/dotfiles/master/remote-install.sh`"

This will clone (using `git`), or download (using `curl` or `wget`), this repo to `~/.dotfiles`. Alternatively, clone manually into the desired location:

    git clone https://github.com/toomuchdesign/dotfiles.git ~/.dotfiles

Use the [Makefile](./Makefile) to install everything [listed above](#package-overview), and symlink [runcom](./runcom) and [config](./config) (using [stow](https://www.gnu.org/software/stow/)):

    cd ~/.dotfiles
    make

> If brew/cask **virtualbox** install fails go to `System Preferences > Security & Privacy > General`, and enable `Oracle` under `Allow apps downloaded from:`.

## Post-install

- `dotfiles dock` (set [Dock items](./macos/dock.sh))
- `dotfiles macos` (set [macOS defaults](./macos/defaults.sh))
- Adjust touchbar with `Preferences/keyboard/Touch bar shows`

### DropBox

Login and sync DropBox.

### Mackup

- `ln -s ~/.config/mackup/.mackup.cfg ~` (until [#632](https://github.com/lra/mackup/pull/632) is fixed)
- `mackup restore`

### Chrome

Install the following extensions:

- [uBlock Origin](https://chrome.google.com/webstore/detail/ublock-origin/cjpalhdlnbpafiamejdnhcphjbkeiagm?hl=en)
- [EverSync](https://chrome.google.com/webstore/detail/eversync-sync-bookmarks-b/iohcojnlgnfbmjfjfkbhahhmppcggdog)
- [React Developer Tools](https://chrome.google.com/webstore/detail/react-developer-tools/fmkadmapgofadopljbjfkapdkoienihi?hl=en)
- [Redux DevTools](https://chrome.google.com/webstore/detail/redux-devtools/lmhkpmbekcpmknklioeibfkpmmfibljd?hl=en)

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
- Fire `Sync: Download Settings`

## The `dotfiles` command

    $ dotfiles help
    Usage: dotfiles <command>

    Commands:
       clean            Clean up caches (brew, npm, gem, rvm)
       dock             Apply macOS Dock settings
       edit             Open dotfiles in IDE (code)
       help             This help message
       macos            Apply macOS system defaults
       test             Run tests
       update           Update packages and pkg managers (OS, brew, npm, gem)

## Customize/extend

You can put your custom settings, such as Git credentials in the `system/.custom` file which will be sourced from `.bash_profile` automatically. This file is in `.gitignore`.

Alternatively, you can have an additional, personal dotfiles repo at `~/.extra`. The runcom `.bash_profile` sources all `~/.extra/runcom/*.sh` files.

## Additional resources

- [Awesome Dotfiles](https://github.com/webpro/awesome-dotfiles)
- [Homebrew](https://brew.sh)
- [Homebrew Cask](http://caskroom.io)
- [Bash prompt](https://wiki.archlinux.org/index.php/Color_Bash_Prompt)
- [Solarized Color Theme for GNU ls](https://github.com/seebi/dircolors-solarized)

## Credits

Many thanks to the [dotfiles community](https://dotfiles.github.io).
