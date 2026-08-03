# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Homebrew shellenv — also in .zprofile, repeated here so non-login
# interactive shells (IDE/agent subshells) pick up /opt/homebrew/bin.
eval "$(/opt/homebrew/bin/brew shellenv)"

# User-local binaries. Most curl|sh installers and Python/Rust user installs
# (pipx, uv, cargo-binstall…) drop executables in ~/.local/bin. Linux distros
# add it to PATH by default, macOS does not. `typeset -U` keeps entries unique
# so re-sourcing this file doesn't grow PATH.
typeset -U path PATH
path=("$HOME/.local/bin" $path)

# ─────────────────────────────────────────────────────────────────────────────
# oh-my-zsh — used as a LIBRARY, not as the full framework.
#
# We deliberately do NOT `source $ZSH/oh-my-zsh.sh`. That entry point mass-loads
# all ~22 lib/*.zsh files, runs an update check, and runs a completion-security
# audit over ~1k Homebrew completion files on every start — the bulk of omz's
# startup cost and the cause of the old cold-start hangs. Instead we init
# completion ourselves and source only the handful of omz pieces we actually use.
#
# The prompt is Starship (below), not an omz theme. To go back to the full
# framework, restore the `ZSH_THEME` / `plugins=()` / `source $ZSH/oh-my-zsh.sh`
# block from git history. See docs/shell-framework-options.md for the rationale.
# ─────────────────────────────────────────────────────────────────────────────
export ZSH=$HOME/.oh-my-zsh
export ZSH_CACHE_DIR=$ZSH/cache

# De-duplicate fpath before compinit. `brew shellenv` runs in both .zprofile and
# this file, so Homebrew's site-functions dir would otherwise land on fpath twice
# and compinit would scan it twice.
typeset -U fpath FPATH

# Completion. `-i` silently ignores "insecure directory" warnings (single-user
# Mac) — this is what `ZSH_DISABLE_COMPFIX=true` used to select under the
# framework, and it skips the slow audit of ~1k Homebrew completion files.
autoload -Uz compinit
compinit -i -d "$ZSH_CACHE_DIR/zcompdump-$ZSH_VERSION"

# omz library pieces we keep (each sources standalone; the rest of lib/ is prompt,
# theming, update and diagnostic machinery we don't use):
source $ZSH/lib/completion.zsh    # menu-select, case-insensitive matching, colors
source $ZSH/lib/history.zsh       # shared history, ignore-dups, HISTSIZE=50000
source $ZSH/lib/directories.zsh   # ll/la/l, md/rd, ..=cd .., 1-9 dir-stack jumps
source $ZSH/lib/key-bindings.zsh  # emacs keys, Up/Down = prefix history search, Home/End
source $ZSH/lib/grep.zsh          # colorized grep with sensible --exclude-dir defaults
source $ZSH/lib/termsupport.zsh   # set the terminal tab/window title to cwd + command

# The one omz plugin we use: git (aliases + helper functions). lib/git.zsh MUST
# come first — it defines git_current_branch, which several git-plugin aliases
# call (ggpull, gpsup, ggsup, gluc…). We use Starship for the prompt, so disable
# omz's async git-prompt handler (it lives in lib/async_prompt.zsh, which we don't
# load; without this it would error trying to register a precmd hook).
zstyle ':omz:alpha:lib:git' async-prompt no
source $ZSH/lib/git.zsh
source $ZSH/plugins/git/git.plugin.zsh
# Add another omz plugin the same way:  source $ZSH/plugins/<name>/<name>.plugin.zsh

# zsh-autosuggestions — installed as a Homebrew formula (brew upgrade keeps it
# current; no manual git pull, no plugin manager). zsh-syntax-highlighting is
# sourced LAST, at the very bottom of this file.
[[ -r $HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]] \
  && source $HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# Our aliases / functions / macOS aliases / local overrides. omz used to
# auto-source custom/*.zsh; we do it explicitly now. Sourced alphabetically, so
# local.untracked.zsh (machine-specific overrides) is loaded last and wins.
for _f in $ZSH/custom/*.zsh(N); do source $_f; done; unset _f

# ── interactive tools ──────────────────────────────────────────────────────

# fzf shell integration — key bindings + completion (fzf >= 0.48).
#   Ctrl-R  fuzzy history search   Ctrl-T  fuzzy file picker   Alt-C  fuzzy cd
command -v fzf >/dev/null && source <(fzf --zsh)

# zoxide setup — smarter `cd` that learns your most-used dirs.
#   z <fragment>   jump to best match      zi <fragment>   interactive (fzf) pick
eval "$(zoxide init zsh)"

# thefuck setup — lazy-loaded so `thefuck --alias`
# only runs the first time `fuck` is invoked, instead of on every shell launch.
fuck() {
  unfunction fuck
  eval "$(thefuck --alias)"
  fuck "$@"
}

# fnm setup
eval "$(fnm env --use-on-cd --shell zsh)"

# Starship prompt.
eval "$(starship init zsh)"

# zsh-syntax-highlighting MUST be sourced last — it wraps the line editor and
# expects every other widget (fzf, zoxide, …) to be defined first.
[[ -r $HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] \
  && source $HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
