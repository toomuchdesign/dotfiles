#!/usr/bin/env bash
# absorb — reconcile uncommitted changes into the commits that introduced those
# lines, leaving genuinely-new work for its own commit, so branch history reads as
# a clean logical sequence. Deterministic part = git-absorb; judgment = the caller.
#
#   absorb.sh [--base REF]        smart run: stage tracked edits, absorb, and — if
#                                 nothing is left over — fold + verify in one shot.
#                                 If leftover remains, it stops for you to handle it.
#   absorb.sh finish [--base REF] after you've committed the leftover: fold + verify.
#   absorb.sh preview [--base REF] git-absorb --dry-run, no changes made.
#
# Requires: git-absorb (https://github.com/tummychow/git-absorb).
set -euo pipefail

command -v git-absorb >/dev/null 2>&1 || { echo "absorb: git-absorb not installed (brew install git-absorb)" >&2; exit 127; }
git rev-parse --git-dir >/dev/null 2>&1 || { echo "absorb: not a git repo" >&2; exit 1; }
GD="$(git rev-parse --git-dir)"

cmd=run
case "${1:-}" in run|finish|preview) cmd="$1"; shift;; --base) : ;; "") : ;; *) : ;; esac
BASE=""
[ "${1:-}" = "--base" ] && { BASE="$2"; shift 2; }

detect_base() {
  local up
  up="$(git rev-parse --abbrev-ref --symbolic-full-name '@{upstream}' 2>/dev/null || true)"
  [ -z "$up" ] && for b in origin/HEAD origin/master origin/main master main; do
    git rev-parse --verify -q "$b" >/dev/null 2>&1 && { up="$b"; break; }; done
  git merge-base HEAD "$up" 2>/dev/null || git rev-parse HEAD~1
}
[ -z "$BASE" ] && BASE="$(detect_base)"
git rev-parse --verify -q "$BASE" >/dev/null || { echo "absorb: bad base ref: $BASE" >&2; exit 1; }

leftover() { # true if untracked files or unstaged/uncommitted tracked changes remain
  [ -n "$(git status --porcelain)" ]
}
verify() { # HEAD tree must equal the pre-run snapshot; working tree must be clean
  local snap; snap="$(cat "$GD/ABSORB_SNAP" 2>/dev/null || true)"
  [ -n "$snap" ] || { echo "absorb: no snapshot to verify against"; return 0; }
  if git diff --quiet "$snap" HEAD -- && git diff --quiet HEAD --; then
    echo "absorb: ✓ tree verified — content identical, history reorganized only."
  else
    echo "absorb: ⚠ tree differs from pre-run state — recover with: git reset --hard ORIG_HEAD" >&2
    git --no-pager diff --stat "$snap" HEAD -- >&2 || true
    return 1
  fi
}
fold() {
  echo "absorb: folding fixups (non-interactive autosquash rebase onto $(git rev-parse --short "$BASE"))…"
  GIT_SEQUENCE_EDITOR=true git rebase --autosquash "$BASE" >/dev/null
}

# -------- preview --------
if [ "$cmd" = preview ]; then
  tmp_staged=0
  git diff --cached --quiet || tmp_staged=1
  [ "$tmp_staged" = 0 ] && git add -u
  echo "absorb: dry-run against base $(git rev-parse --short "$BASE"):"
  git absorb --dry-run --base "$BASE" 2>&1 | sed 's/^/  /' || true
  [ "$tmp_staged" = 0 ] && git reset -q
  exit 0
fi

# -------- finish (after caller committed leftover) --------
if [ "$cmd" = finish ]; then
  if ! git diff --cached --quiet || ! git diff --quiet; then
    echo "absorb: tracked changes still uncommitted — commit or discard the leftover first." >&2; exit 1
  fi
  fold; verify
  rm -f "$GD/ABSORB_SNAP" "$GD/ABSORB_BASE"
  exit 0
fi

# -------- run (smart) --------
[ -n "$(git status --porcelain)" ] || { echo "absorb: nothing to do — working tree clean."; exit 0; }

# snapshot the full pre-run state (tracked edits + untracked) for the verify gate
git add -A; git write-tree > "$GD/ABSORB_SNAP"; git reset -q
echo "$BASE" > "$GD/ABSORB_BASE"

git add -u                                   # stage tracked edits only; untracked = candidate new concerns
if git diff --cached --quiet; then
  echo "absorb: only new/untracked files present — nothing for git-absorb; treat them as new commits."
  git status --short | sed 's/^/  /'
  echo "absorb: commit them logically, then (optional) run: absorb.sh finish"
  exit 0
fi

echo "absorb: attributing staged edits to their origin commits…"
git absorb --base "$BASE" 2>&1 | grep -E 'fixup:|committed|^No ' | sed 's/^/  /' || true

if leftover; then
  echo ""
  echo "absorb: fixups created, but leftover remains (new concerns or unattributable hunks):"
  git status --short | sed 's/^/  /'
  echo "absorb: decide per item — commit genuinely-new work as its own logical commit —"
  echo "        then run:  absorb.sh finish"
  exit 0
fi

fold; verify
rm -f "$GD/ABSORB_SNAP" "$GD/ABSORB_BASE"
