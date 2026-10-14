#!/bin/sh
# snapshot.sh <repo> <base-ref> <out-dir> [path-to-drop ...]: <repo> at <base-ref> as a fresh one-commit
# git repo in <out-dir>, for tasks whose answers live in later commits. There is no history to mine
# (a worktree would let `git log --all` / `git show <future sha>` reveal the answer), and the listed
# paths (eval files, handoffs, plans: anything that could hold answers) are dropped. `.env*` files
# (except `.env.example`) are always dropped.
# node_modules becomes a farm of absolute symlinks to each entry's realpath, so a bun/pnpm workspace
# (relative links) still resolves while the sandbox denies the real repo.
set -eu
REPO=$(cd "$1" && pwd -P)
BASE=$2
OUT=$3
shift 3
[ ! -e "$OUT" ] || { echo "snapshot: $OUT exists" >&2; exit 1; }
mkdir -p "$OUT"
git -C "$REPO" archive "$BASE" | tar -x -C "$OUT"
for drop in "$@"; do rm -rf "${OUT:?}/$drop"; done
find "$OUT" -maxdepth 1 -name '.env*' ! -name '.env.example' -exec rm -rf {} +
if [ -d "$REPO/node_modules" ]; then
  mkdir "$OUT/node_modules"
  for entry in "$REPO"/node_modules/* "$REPO"/node_modules/.bin; do
    [ -e "$entry" ] || continue
    name=${entry#"$REPO/node_modules/"}
    case "$name" in
      @* | .bin)
        mkdir -p "$OUT/node_modules/$name"
        for inner in "$entry"/*; do ln -s "$(realpath "$inner")" "$OUT/node_modules/$name/$(basename "$inner")"; done
        ;;
      *) ln -s "$(realpath "$entry")" "$OUT/node_modules/$name" ;;
    esac
  done
fi
cd "$OUT"
git init -q
# A fresh throwaway repo: staging everything is the point here.
git add -A
git -c user.name=eval -c user.email=eval@local commit -qm "snapshot" --no-gpg-sign
