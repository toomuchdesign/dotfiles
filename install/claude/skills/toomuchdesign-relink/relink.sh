#!/usr/bin/env bash
# relink — consume a locally-built package as if it were published.
# Works with npm, yarn (v1 + berry) and pnpm. Uses pack+install (a flat copy),
# NOT a symlink, so shared singletons (react, redux, @scope/*) stay deduped.
#
#   relink.sh <source-dir> [--into DIR] [--mode tarball|copy] [--pm PM] [--no-build]
#   relink.sh restore <source-dir|pkg-name> [--into DIR] [--pm PM]
#
# Defaults: consumer = cwd, mode = tarball, pm = auto-detected, build = on.
set -euo pipefail

STORE="${RELINK_STORE:-$HOME/.relink-store}"
mkdir -p "$STORE/tarballs" "$STORE/backups"

die() { echo "relink: $*" >&2; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }

# --- package.json readers (node is assumed available in any JS project) -------
pkg_field() { node -e 'try{const p=require(process.argv[1]+"/package.json");const v=process.argv[2].split(".").reduce((o,k)=>o&&o[k],p);if(v!=null)console.log(typeof v==="string"?v:JSON.stringify(v))}catch(e){}' "$1" "$2" 2>/dev/null || true; }
pkg_name()  { pkg_field "$1" name; }
dep_spec()  { # print current spec of dep $2 in consumer $1, across dep sections
  node -e 'try{const p=require(process.argv[1]+"/package.json");const n=process.argv[2];for(const s of["dependencies","devDependencies","optionalDependencies","peerDependencies"]){if(p[s]&&p[s][n]){console.log(s+"\t"+p[s][n]);process.exit(0)}}}catch(e){}' "$1" "$2" 2>/dev/null || true; }

detect_pm() {
  local dir="$1" pm
  pm="$(pkg_field "$dir" packageManager)"; pm="${pm%%@*}"
  [ -n "$pm" ] && { echo "$pm"; return; }
  [ -f "$dir/pnpm-lock.yaml" ] && { echo pnpm; return; }
  [ -f "$dir/yarn.lock" ]      && { echo yarn; return; }
  [ -f "$dir/package-lock.json" ] && { echo npm; return; }
  for c in pnpm yarn npm; do have "$c" && { echo "$c"; return; }; done
  echo npm
}

yarn_major() { (cd "$1" && yarn --version 2>/dev/null | cut -d. -f1) || echo 1; }

# --- lockfile guard: don't create a lockfile in a repo that has none ----------
lock_snapshot() { local d="$1" f; for f in pnpm-lock.yaml yarn.lock package-lock.json; do [ -f "$d/$f" ] && echo "$f"; done; return 0; }
lock_restore() { # $1 dir, $2 = pre-existing lockfiles (newline list)
  local d="$1" pre="$2" f
  for f in pnpm-lock.yaml yarn.lock package-lock.json; do
    if [ -f "$d/$f" ] && ! grep -qx "$f" <<<"$pre"; then
      rm -f "$d/$f"; echo "relink: removed generated $f (repo had no lockfile)"
    fi
  done
}

slug() { echo "$1" | sed 's#[/ ]#_#g; s#^_*##'; }

# ---------------------------------------------------------------------------
CMD=link
if [ "${1:-}" = restore ]; then CMD=restore; shift; fi
SRC="${1:-}"; [ -n "$SRC" ] || die "source package dir (or name, for restore) required"; shift || true

CONSUMER="$PWD"; MODE=tarball; PM=""; BUILD=1
while [ $# -gt 0 ]; do case "$1" in
  --into) CONSUMER="$2"; shift 2;;
  --mode) MODE="$2"; shift 2;;
  --pm)   PM="$2"; shift 2;;
  --no-build) BUILD=0; shift;;
  *) die "unknown arg: $1";;
esac; done
[ -f "$CONSUMER/package.json" ] || die "no package.json in consumer: $CONSUMER"

# =========================== restore ========================================
if [ "$CMD" = restore ]; then
  # SRC may be a dir or a bare package name
  NAME="$SRC"; [ -d "$SRC" ] && NAME="$(pkg_name "$SRC")"
  [ -n "$NAME" ] || die "could not determine package name to restore"
  [ -z "$PM" ] && PM="$(detect_pm "$CONSUMER")"
  BK="$STORE/backups/$(slug "$CONSUMER")__$(slug "$NAME").spec"
  pre="$(lock_snapshot "$CONSUMER")"
  if [ -f "$BK" ]; then
    sec="$(cut -f1 "$BK")"; spec="$(cut -f2 "$BK")"
    dev=""; [ "$sec" = devDependencies ] && dev="-D"
    echo "relink: restoring $NAME@$spec via $PM ${dev:+(dev)}"
    (cd "$CONSUMER" && "$PM" add $dev "$NAME@$spec")
    rm -f "$BK"
  else
    echo "relink: no genuine original spec on record; removing local override for $NAME"
    (cd "$CONSUMER" && "$PM" remove "$NAME" 2>/dev/null || true)
  fi
  lock_restore "$CONSUMER" "$pre"
  echo "relink: done. Reinstall if needed."
  exit 0
fi

# ============================= link =========================================
[ -d "$SRC" ] || die "source is not a directory: $SRC"
NAME="$(pkg_name "$SRC")"; [ -n "$NAME" ] || die "source has no package name"
SRCPM="$(detect_pm "$SRC")"
[ -z "$PM" ] && PM="$(detect_pm "$CONSUMER")"
echo "relink: $NAME  ($SRC)  →  $CONSUMER   [mode=$MODE, build-pm=$SRCPM, install-pm=$PM]"

# 1. build the source (so dist is fresh) -------------------------------------
if [ "$BUILD" = 1 ] && [ -n "$(pkg_field "$SRC" scripts.build)" ]; then
  echo "relink: building source ($SRCPM run build)…"
  (cd "$SRC" && "$SRCPM" run build)
fi

# 2. pack into a stable tarball (byte-for-byte what publish would ship) -------
TMP="$(mktemp -d)"
case "$SRCPM" in
  pnpm) (cd "$SRC" && pnpm pack --pack-destination "$TMP" >/dev/null);;
  npm)  (cd "$SRC" && npm pack --pack-destination "$TMP" >/dev/null);;
  yarn) if [ "$(yarn_major "$SRC")" = 1 ]; then (cd "$SRC" && yarn pack --filename "$TMP/p.tgz" >/dev/null);
        else (cd "$SRC" && yarn pack --out "$TMP/p.tgz" >/dev/null); fi;;
  *) die "unsupported pm: $SRCPM";;
esac
SRCTGZ="$(ls "$TMP"/*.tgz 2>/dev/null | head -1)"; [ -n "$SRCTGZ" ] || die "pack produced no tarball"
DEST="$STORE/tarballs/$(slug "$NAME").tgz"   # stable name → package.json entry doesn't churn on rebuild
mv "$SRCTGZ" "$DEST"; rm -rf "$TMP"
echo "relink: packed → $DEST"

# 3a. copy mode: extract into node_modules (clean, but dies on reinstall) -----
if [ "$MODE" = copy ]; then
  TARGET="$CONSUMER/node_modules/$NAME"
  rm -rf "$TARGET"; mkdir -p "$TARGET"
  tar -xzf "$DEST" -C "$TARGET" --strip-components=1
  echo "relink: copied into node_modules (ephemeral — re-run after any reinstall)"
else
# 3b. tarball mode: install as file: dep (survives node_modules nukes) --------
  # back up the original spec once, so `restore` can put it back
  BK="$STORE/backups/$(slug "$CONSUMER")__$(slug "$NAME").spec"
  if [ ! -f "$BK" ]; then
    orig="$(dep_spec "$CONSUMER" "$NAME")"            # "section<tab>spec" or ""
    ospec="$(printf '%s' "$orig" | cut -f2)"
    case "$ospec" in
      file:*|link:*|"") : ;;                          # already linked / absent → nothing genuine to back up
      *) printf '%s\n' "$orig" >"$BK" ;;
    esac
  fi
  pre="$(lock_snapshot "$CONSUMER")"
  echo "relink: installing tarball into consumer ($PM)…"
  case "$PM" in
    pnpm) (cd "$CONSUMER" && pnpm add "$DEST" --config.lockfile=false 2>/dev/null || pnpm add "$DEST");;
    npm)  (cd "$CONSUMER" && npm install --no-package-lock "$DEST");;
    yarn) (cd "$CONSUMER" && yarn add "$DEST");;
    *) die "unsupported pm: $PM";;
  esac
  lock_restore "$CONSUMER" "$pre"
  echo "relink: package.json now points at file:$DEST — DO NOT COMMIT that line. Undo with: relink.sh restore $NAME"
fi

# 4. sanity: warn on duplicate react (the classic breakage) ------------------
rv="$(find "$CONSUMER/node_modules" -maxdepth 5 -type f -path '*/react/package.json' 2>/dev/null \
      | while read -r f; do node -e 'try{console.log(require(process.argv[1]).version)}catch(e){}' "$f"; done \
      | sort -u)"
n="$(printf '%s\n' "$rv" | grep -c . || true)"
if [ "${n:-0}" -gt 1 ]; then
  echo "relink: ⚠ multiple react versions resolved ($(printf '%s' "$rv" | tr '\n' ' ')) — dedupe before trusting the run"
fi
echo "relink: done."
