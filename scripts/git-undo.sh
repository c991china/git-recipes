#!/usr/bin/env bash
#
# git-undo.sh -- undo recent git mistakes, interactively.
#
# Nothing here touches commits you haven't made yet. The one destructive option
# (discard working changes) makes you type the word "yes".
#
# Usage: ./git-undo.sh

set -euo pipefail

die() { printf 'error: %s\n' "$*" >&2; exit 1; }

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || die "not inside a git repo"

# git restore landed in 2.23. Refuse to guess on older versions.
if ! git restore -h >/dev/null 2>&1; then
    die "git too old for 'git restore' (need 2.23+). Try 'git checkout -- <file>'."
fi

cat <<'MENU'
What do you want to undo?

  1) Undo last commit, KEEP changes staged        (reset --soft HEAD~1)
  2) Undo last commit, KEEP changes unstaged      (reset --mixed HEAD~1)
  3) Unstage everything, keep edits               (restore --staged .)
  4) Discard ALL working changes (DESTRUCTIVE)    (restore .)
  5) Amend last commit message only               (commit --amend)
  6) Show reflog so I can pick a commit myself
  q) quit
MENU

read -r -p "> " choice

case "$choice" in
    1)
        git reset --soft HEAD~1
        echo "Last commit undone. Changes are staged."
        ;;
    2)
        git reset --mixed HEAD~1
        echo "Last commit undone. Changes are in the working tree."
        ;;
    3)
        git restore --staged .
        echo "Unstaged everything. Working tree untouched."
        ;;
    4)
        echo "This discards ALL uncommitted changes in tracked files."
        echo "Untracked files are NOT touched (use 'git clean -fd' for those)."
        read -r -p "Type 'yes' to confirm: " confirm
        [[ "$confirm" == "yes" ]] || die "aborted"
        git restore .
        echo "Working tree reset to HEAD."
        ;;
    5)
        git commit --amend
        ;;
    6)
        git reflog --date=relative -20
        echo
        echo "Then, e.g.:  git reset --soft <sha>   or   git cherry-pick <sha>"
        ;;
    q|Q)
        exit 0
        ;;
    *)
        die "unknown choice: $choice"
        ;;
esac
