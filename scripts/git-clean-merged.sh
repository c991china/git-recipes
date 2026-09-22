#!/usr/bin/env bash
#
# git-clean-merged.sh -- delete local branches already merged into main.
#
# Skips: the main branch, the current branch, and anything matching a protect
# list. Defaults to --dry-run; you must pass --apply to actually delete.
#
# Usage:
#   ./git-clean-merged.sh            # dry run, shows what would go
#   ./git-clean-merged.sh --apply    # actually delete (uses -d, not -D)

set -euo pipefail

MAIN_BRANCH="${MAIN_BRANCH:-main}"
PROTECT_RE='^(main|master|develop|release/.*)$'
APPLY=0

for arg in "$@"; do
    case "$arg" in
        --apply) APPLY=1 ;;
        --dry-run) APPLY=0 ;;
        -h|--help)
            sed -n '2,12p' "$0"; exit 0 ;;
        *) printf 'unknown arg: %s\n' "$arg" >&2; exit 2 ;;
    esac
done

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
    printf 'error: not inside a git repo\n' >&2; exit 1;
}

current="$(git symbolic-ref --short HEAD 2>/dev/null || echo '')"

if ! git show-ref --verify --quiet "refs/heads/${MAIN_BRANCH}"; then
    printf 'error: no local branch %s (set MAIN_BRANCH=... to override)\n' "$MAIN_BRANCH" >&2
    exit 1
fi

# Branches merged into MAIN_BRANCH, minus HEAD and the protect list.
mapfile -t candidates < <(
    git branch --merged "$MAIN_BRANCH" --format='%(refname:short)' \
        | grep -Ev "$PROTECT_RE" \
        | grep -Fvx "$current" \
        || true
)

if [[ "${#candidates[@]}" -eq 0 ]]; then
    echo "Nothing to clean. No merged branches (other than protected ones)."
    exit 0
fi

echo "Branches merged into ${MAIN_BRANCH}:"
for b in "${candidates[@]}"; do
    printf '  %s  (last commit %s)\n' "$b" \
        "$(git log -1 --date=short --format='%cd %s' "$b")"
done
echo

if [[ "$APPLY" -ne 1 ]]; then
    echo "Dry run. Re-run with --apply to delete these with 'git branch -d'."
    exit 0
fi

read -r -p "Delete the above branches? [y/N] " ans
case "$ans" in
    y|Y) ;;
    *) echo "aborted"; exit 0 ;;
esac

for b in "${candidates[@]}"; do
    # -d refuses to delete unmerged branches, which is a safety net. Do NOT
    # switch this to -D unless you know the branch is already in a PR.
    if git branch -d "$b"; then
        echo "deleted $b"
    else
        echo "SKIPPED $b (not fully merged? -d refused)" >&2
    fi
done
