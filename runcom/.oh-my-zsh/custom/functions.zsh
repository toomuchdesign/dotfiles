# Create a new directory and enter it
mk() {
  mkdir -p "$@" && cd "$@"
}

# Find files by name anywhere below the current directory.
# Uses fd (fast, respects .gitignore) when available, else falls back to find.
# Usage: ff <name-fragment>   e.g.  ff auth.controller
ff() {
  if command -v fd >/dev/null 2>&1; then
    fd --hidden --type f "$1"
  else
    find . -type f -iname "*$1*"
  fi
}

# Start an HTTP server from a directory, optionally specifying the port
srv() {
    # Get port (if specified)
    local port="${1:-8000}"

    # Open in the browser
    open "http://localhost:${port}/"

    # Redefining the default content-type to text/plain instead of the default
    # application/octet-stream allows "unknown" files to be viewable in-browser
    # as text instead of being downloaded.
    #
    # Unfortunately, "python -m SimpleHTTPServer" doesn't allow you to redefine
    # the default content-type, but the SimpleHTTPServer module can be executed
    # manually with just a few lines of code.
    python -c $'import SimpleHTTPServer;\nSimpleHTTPServer.SimpleHTTPRequestHandler.extensions_map[""] = "text/plain";\nSimpleHTTPServer.test();' "$port"
}

# Clean up merged/stale Git branches with git-trim (brew install git-trim).
# `git trim` understands squash/rebase merges and detects the default branch,
# so no wrapper is needed. Alias kept only for muscle memory.
alias git-cleanup='git trim'

# Kill the process listening on a given TCP port.
# Usage: killport 3000
killport() {
  if [[ -z "$1" ]]; then
    echo "usage: killport <port>" >&2
    return 1
  fi
  local pids
  pids=$(lsof -t -i ":$1")
  if [[ -z "$pids" ]]; then
    echo "no process listening on port $1" >&2
    return 1
  fi
  command kill -9 $pids
}
