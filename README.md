# git-recipes

Git things I have to look up every time, written down once so I stop looking
them up. Scripts are safe-by-default: they print what they're about to do and
most ask before doing anything destructive.

I made this after I `git reset --hard`'d away an afternoon of work and spent an
hour in `git reflog` learning that it was recoverable, but only because I hadn't
garbage-collected yet.

## Scripts

All scripts are bash, take no required args, and refuse to run outside a git
repo. Run `--help`-ish behavior by reading the header comment; they're short.

| script | what it does |
|--------|--------------|
| `scripts/git-undo.sh` | undo the last commit / unstage / discard, with a menu |
| `scripts/git-find-lost.sh` | hunt for dangling commits + stashes in the reflog |
| `scripts/git-clean-merged.sh` | delete local branches already merged into main |

```bash
chmod +x scripts/*.sh
./scripts/git-undo.sh              # interactive menu
./scripts/git-find-lost.sh         # lists recoverable commits
./scripts/git-clean-merged.sh --dry-run   # show what would be deleted
```

## Recipes

| file | covers |
|------|--------|
| `recipes/rewrite-history.md` | interactive rebase, squash, edit old commits, the force-push dance |
| `recipes/submodule.md` | add/update/remove submodules, the detached-HEAD trap |
| `recipes/cherry-pick.md` | copy a commit across branches, ranges, conflict handling |
| `recipes/bisect.md` | find the commit that broke things, incl. `bisect run` |
| `recipes/worktree.md` | two branches checked out at once, no stashing |

## Sample output

`git-find-lost.sh` on a repo where I'd just reset away a commit:

```
$ ./scripts/git-find-lost.sh
Dangling commits (most recent first):
  a1b2c3d  feat: add retry logic to uploader       (2 minutes ago)
  9f8e7d6  wip: half-finished parser rewrite        (1 hour ago)

Stash entries:
  stash@{0}  On main: snap before rebase            (3 hours ago)

Recover a commit with:
  git cherry-pick <sha>
  git branch rescue/<short-sha> <sha>
```

## Gotchas

- **`git reset --hard` does not delete commits immediately.** They become
  dangling and survive until `git gc` runs (default ~2 weeks, or when you run it
  by hand). So there's a window. Don't rely on it, but don't panic either.
- **`--force-with-lease` is not a magic wand.** It still force-pushes if your
  local view of the remote is current. If a teammate pushed since your last
  fetch, it refuses. That's the point. `git push --force` does not refuse.
- **Rebasing shared branches is rude.** If anyone else has the branch, don't
  rewrite it. This is the one rule I actually enforce.
- Scripts assume `main` as the default branch. If yours is `master`, edit the
  `MAIN_BRANCH` variable at the top of `git-clean-merged.sh`.

## Notes

Tested with git 2.43 on Ubuntu 24.04 and git 2.39 on macOS 14. `git-undo.sh`
uses `git restore`, which needs git 2.23+; on anything older it will tell you
and bail rather than do the wrong thing.

Nothing here is clever. It's a notebook with guard rails.
