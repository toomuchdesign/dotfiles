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

# Path to your oh-my-zsh installation.
export ZSH=$HOME/.oh-my-zsh

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME=skaro

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "skaro" "af-magic" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Auto-update behavior. `disabled` kills both the "Would you like to update?"
# reminder prompt AND the periodic `git fetch` against the omz repo that runs on
# shell startup when a check is due — that network call is a prime suspect for
# the first-tab-after-a-while hang. Run `omz update` by hand when you want it.
zstyle ':omz:update' mode disabled
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git zsh-autosuggestions)

# De-duplicate fpath before oh-my-zsh runs compinit. Because `brew shellenv`
# runs in more than one startup file and fpath (unlike PATH) is not auto-unique,
# Homebrew's site-functions dir was landing in fpath ~5x, making compinit/compaudit
# stat the same directories over and over.
typeset -U fpath FPATH

# Skip oh-my-zsh's completion-security audit (compaudit). Homebrew's
# group-writable share/zsh dirs make that audit stat a pile of directories on
# every launch — slow on a cold filesystem and the usual cause of multi-second
# startup hangs. We trust these dirs, so skip the check.
ZSH_DISABLE_COMPFIX=true

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

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
