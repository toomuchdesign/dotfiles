#!/usr/bin/env python3
"""PreToolUse gate: block destructive git pushes to the default branch.

Blocks, on master/main only:
  - force pushes (--force, -f, --force-with-lease, or a +refspec)
  - remote branch deletes (--delete / -d, or a :refspec)

Feature-branch pushes and non-force pushes are untouched. When no refspec is
given, the target is the checked-out branch, resolved via git in the call's cwd.

Contract: reads the PreToolUse JSON on stdin. Exit 0 allows; exit 2 blocks and
feeds stderr back to the agent.
"""
import json
import os
import re
import shlex
import subprocess
import sys

PROTECTED = {"master", "main"}


def subcommands(command):
    for part in re.split(r"&&|\|\||;|\||\n", command):
        part = part.strip()
        if not part:
            continue
        try:
            yield shlex.split(part)
        except ValueError:
            continue


def is_git_push(tokens):
    if "git" not in tokens or "push" not in tokens:
        return False
    return tokens.index("push") > tokens.index("git")


def refspec_target(refspec):
    dst = refspec.split(":", 1)[1] if ":" in refspec else refspec
    dst = dst.lstrip("+")
    return dst.rsplit("/", 1)[-1] if dst else ""


def current_branch(cwd):
    try:
        out = subprocess.run(
            ["git", "-C", cwd or ".", "symbolic-ref", "--short", "HEAD"],
            capture_output=True, text=True, timeout=2,
        )
        if out.returncode == 0:
            return out.stdout.strip()
    except Exception:
        pass
    return None


def analyze(tokens, cwd):
    """Return a block reason string, or None to allow."""
    after_push = tokens[tokens.index("push") + 1:]
    force = delete = False
    positionals = []
    for tok in after_push:
        if tok in ("--force", "-f") or tok.startswith("--force-with-lease"):
            force = True
        elif tok in ("--delete", "-d"):
            delete = True
        elif tok.startswith("-"):
            continue
        else:
            positionals.append(tok)

    # First positional is the remote (origin, a URL, …); the rest are refspecs.
    refspecs = positionals[1:] if len(positionals) > 1 else []
    force = force or any(r.startswith("+") for r in refspecs)
    delete = delete or any(r.startswith(":") for r in refspecs)

    if not force and not delete:
        return None

    if refspecs:
        targets = {refspec_target(r) for r in refspecs}
    else:
        branch = current_branch(cwd)
        targets = {branch} if branch else set()

    if not targets & PROTECTED:
        return None

    kind = "force-push" if force else "remote branch delete"
    hit = ", ".join(sorted(targets & PROTECTED))
    return (
        f"Blocked: {kind} targeting the default branch ({hit}).\n"
        "Destructive operations on master/main are never permitted. "
        "If a human truly wants this, they must run it themselves."
    )


def main():
    try:
        data = json.load(sys.stdin)
    except Exception:
        sys.exit(0)
    if data.get("tool_name") != "Bash":
        sys.exit(0)
    command = data.get("tool_input", {}).get("command", "")
    cwd = data.get("cwd") or os.getcwd()

    for tokens in subcommands(command):
        if not is_git_push(tokens):
            continue
        reason = analyze(tokens, cwd)
        if reason:
            print(reason, file=sys.stderr)
            sys.exit(2)
    sys.exit(0)


if __name__ == "__main__":
    main()
