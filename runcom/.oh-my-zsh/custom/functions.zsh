# Create a new directory and enter it
mk() {
  mkdir -p "$@" && cd "$@"
}

# Fuzzy find file/dir
ff() { find . -type f -iname "*$1*";}
fd() { find . -type d -iname "*$1*";}

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

# A script for cleaning up Git repositories
# it deletes branches that are fully merged into `origin/master`,
# prunes obsolete remote tracking branches,
# and as an added bonus will replicate these changes on the remote.
# https://gist.github.com/robmiller/5133264

git-cleanup() {
  #!/bin/bash
  # git-cleanup-repo
  #
  # Author: Rob Miller <rob@bigfish.co.uk>
  # Adapted from the original by Yorick Sijsling

  git checkout master &> /dev/null

  # Make sure we're working with the most up-to-date version of master.
  git fetch

  # Prune obsolete remote tracking branches. These are branches that we
  # once tracked, but have since been deleted on the remote.
  git remote prune origin

  # List all the branches that have been merged fully into master, and
  # then delete them. We use the remote master here, just in case our
  # local master is out of date.
  git branch --merged origin/master | grep -v 'master$' | xargs git branch -d

  # Now the same, but including remote branches.
  MERGED_ON_REMOTE=`git branch -r --merged origin/master | sed 's/ *origin\///' | grep -v 'master$'`

  if [ "$MERGED_ON_REMOTE" ]; then
    echo "The following remote branches are fully merged and will be removed:"
    echo $MERGED_ON_REMOTE

    read -p "Continue (y/N)? "
    if [ "$REPLY" == "y" ]; then
      git branch -r --merged origin/master | sed 's/ *origin\///' \
        | grep -v 'master$' | xargs -I% git push origin :% 2>&1 \
        | grep --colour=never 'deleted'
      echo "Done!"
    fi
  fi
}

# Kill port
kill() { kill -9 $(lsof -t -i :$1);}
