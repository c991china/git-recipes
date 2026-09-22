#!/usr/bin/env bash
#
# git-find-lost.sh -- find commits and stashes that are not reachable from any
# branch. Run this right after a bad reset/rebase, before git gc cleans them up.
#
# Usage: ./git-find-lost.sh

set -euo pipefail

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
    printf 'error: not inside a git repo\n' >&2; exit 1;
}

echo "== Dangling commits (unreachable, newest first) =="
# fsck lists dangling commits; we pretty-print each. `|| true` because fsck
# exits non-zero when it finds problems, which is the normal case here.
dangling="$(git fsck --no-reflogs --lost-found 2>/dev/null \
    | awk '/dangling commit/ {print $3}' || true)"

if [[ -z "$dangling" ]]; then
    echo "  (none)"
else
    while read -r sha; do
        [[ -z "$sha" ]] && continue
        git --no-pager log -1 --date=relative \
            --pretty=format:'  %h  %s  (%cd, %an)' "$sha" 2>/dev/null && echo
    done <<< "$dangling"
fi

echo
echo "== Reflog (HEAD movements) =="
git reflog --date=relative -15 || true

echo
echo "== Stashes =="
if git stash list | grep -q .; then
    git stash list --date=relative
else
    echo "  (none)"
fi

echo
cat <<'HINT'
To recover one of the above:
  git cherry-pick <sha>                 # replay it onto the current branch
  git branch rescue/<short-sha> <sha>   # keep a handle on it first (safer)
  git stash apply stash@{N}             # for stashes

Tip: do this BEFORE `git gc`. After gc, unreachable objects are gone for good.
HINT
