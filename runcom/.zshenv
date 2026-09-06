# .zshenv is sourced by every zsh: interactive, login, and non-interactive
# (scripts, `zsh -c`, cron, git hooks). All PATH setup lives here, not in
# .zshrc (interactive-only) or .zprofile (login-only), so every shell gets the
# same PATH. Without it, non-interactive shells can't find ~/.local/bin or
# Homebrew tools.
#
# One exception: Claude Code sets its own PATH in ~/.claude/settings.json,
# which overrides whatever this file computes. That file, not this one,
# controls PATH for Claude Code's shells.

# `typeset -U` keeps path/fpath entries unique, so sourcing this more than once
# (nested shells) never grows PATH.
typeset -U path PATH

# Homebrew: bin dirs on PATH + HOMEBREW_* env, for every shell.
eval "$(/opt/homebrew/bin/brew shellenv)"

# User-local binaries. Most curl|sh installers and Python/Rust user installs
# (pipx, uv, cargo-binstall, plannotator…) drop executables in ~/.local/bin.
# macOS doesn't add it by default.
path=("$HOME/.local/bin" $path)
