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
# Plain zsh — no framework. This replaces oh-my-zsh entirely. The prompt is
# Starship (bottom of file). The sensible defaults omz used to set up
# (completion, history, keybindings, dir aliases) are inlined below; the git
# aliases come from a vendored copy of omz's git plugin
# (runcom/.zsh/vendor/git.plugin.zsh); zsh-autosuggestions and
# zsh-syntax-highlighting come from Homebrew. See docs/shell-framework-options.md.
# ─────────────────────────────────────────────────────────────────────────────

# De-duplicate fpath before compinit. `brew shellenv` runs in both .zprofile and
# this file, so Homebrew's site-functions dir would otherwise land on fpath twice.
typeset -U fpath FPATH

# ── completion ─────────────────────────────────────────────────────────────
# Homebrew's site-functions (git, docker, gh, … completions) are on fpath via
# `brew shellenv`. `-i` silently ignores "insecure directory" warnings
# (single-user Mac); the dump is cached under the XDG cache dir.
_zcompdump="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump-$ZSH_VERSION"
[[ -d ${_zcompdump:h} ]] || mkdir -p "${_zcompdump:h}"
autoload -Uz compinit && compinit -i -d "$_zcompdump"
unset _zcompdump
zmodload -i zsh/complist
zstyle ':completion:*' matcher-list 'm:{[:lower:][:upper:]}={[:upper:][:lower:]}'  # case-insensitive
zstyle ':completion:*' menu select                                                 # arrow-navigable menu
zstyle ':completion:*' list-colors ''                                              # colorize the menu
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompcache"
setopt auto_menu complete_in_word always_to_end
WORDCHARS=''

# ── history ────────────────────────────────────────────────────────────────
HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
setopt share_history hist_ignore_all_dups hist_ignore_space inc_append_history extended_history

# ── directories ──────────────────────────────────────────────────────────────
setopt auto_cd auto_pushd pushd_ignore_dups pushd_minus
alias ll='ls -lh'
alias la='ls -lAh'
alias l='ls -lah'
alias md='mkdir -p'
alias rd='rmdir'
# `1`-`9` jump to that entry in the pushd stack (see it with `dirs -v`).
for i in {1..9}; do alias "$i"="cd +$i"; done; unset i

# ── keybindings ──────────────────────────────────────────────────────────────
bindkey -e   # emacs mode
# Up/Down: search history for entries matching what's already on the line.
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey '^[[A' up-line-or-beginning-search;   bindkey '^[OA' up-line-or-beginning-search
bindkey '^[[B' down-line-or-beginning-search; bindkey '^[OB' down-line-or-beginning-search
# Home / End / Delete — prefer terminfo, fall back to common xterm codes.
bindkey "${terminfo[khome]:-^[[H}"  beginning-of-line
bindkey "${terminfo[kend]:-^[[F}"   end-of-line
bindkey "${terminfo[kdch1]:-^[[3~}" delete-char
# Word-wise movement with ctrl/alt + arrows.
bindkey '^[[1;5C' forward-word;  bindkey '^[[1;5D' backward-word
bindkey '^[[1;3C' forward-word;  bindkey '^[[1;3D' backward-word
# Shift-Tab cycles the completion menu backwards.
bindkey '^[[Z' reverse-menu-complete

# ── misc quality-of-life (what omz's lib/misc + lib/grep gave us) ────────────
setopt interactive_comments long_list_jobs multios
alias grep="grep --color=auto --exclude-dir={.bzr,CVS,.git,.hg,.svn,.idea,.tox,.venv,venv}"

# ── git aliases: vendored copy of oh-my-zsh's git plugin ─────────────────────
# runcom/.zsh/vendor/git.plugin.zsh is a frozen copy of ohmyzsh/ohmyzsh
# plugins/git/git.plugin.zsh (@6574980). Its only external dependency is
# git_current_branch, defined here (lifted from omz lib/git.zsh). Re-sync by
# recopying that one upstream file. git *completion* comes from Homebrew's _git.
function git_current_branch() {
  local ref
  ref=$(command git symbolic-ref --quiet HEAD 2>/dev/null)
  local ret=$?
  if [[ $ret != 0 ]]; then
    [[ $ret == 128 ]] && return  # not in a git repo
    ref=$(command git rev-parse --short HEAD 2>/dev/null) || return
  fi
  echo ${ref#refs/heads/}
}
source "$HOME/.zsh/vendor/git.plugin.zsh"

# ── zsh-autosuggestions (Homebrew formula; brew upgrade keeps it current) ────
# zsh-syntax-highlighting is sourced LAST, at the very bottom of this file.
[[ -r $HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]] \
  && source $HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# ── our aliases / functions / macOS aliases / local overrides ────────────────
# Sourced alphabetically, so local.untracked.zsh (machine overrides) wins.
for _f in "$HOME"/.zsh/*.zsh(N); do source "$_f"; done; unset _f

# ── interactive tools ────────────────────────────────────────────────────────

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
