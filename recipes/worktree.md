# Worktrees

A worktree lets you have more than one branch checked out at the same time, in
separate directories, sharing one `.git`. No stashing, no "let me finish this
first". This replaced `git stash` for me about 80% of the time.

## The problem it solves

You're mid-feature on `feature/upload`. A hotfix lands on `main`. Without
worktrees you either stash (and lose your build state) or clone the repo again
(and re-download everything). With worktrees:

```bash
git worktree add ../hotfix main
cd ../hotfix
# fix, commit, push, PR
cd ../myrepo
git worktree remove ../hotfix
```

Your `feature/upload` working tree is untouched the whole time.

## Basic commands

```bash
# list worktrees
git worktree list

# add one for an existing branch
git worktree add ../myrepo-release release/1.2

# add one for a brand-new branch based on main
git worktree add -b fix/login-timeout ../myrepo-fix main

# remove it (refuses if there are uncommitted changes)
git worktree remove ../myrepo-release

# force removal (discards uncommitted changes)
git worktree remove --force ../myrepo-release

# clean up bookkeeping for dirs you deleted with rm -rf
git worktree prune
```

`git worktree list` output:

```
/home/me/myrepo              a1b2c3d [feature/upload]
/home/me/myrepo-release      9f8e7d6 [release/1.2]
/home/me/hotfix              3d4e5f6 [main]
```

## When I use it

- Reviewing a PR while my own work is in progress: `git worktree add ../pr-42 origin/pr-42`.
- Running tests on `main` while a feature branch builds.
- Comparing behavior between two branches side by side.
- Keeping a long-lived `gh-pages` checkout without switching away from my code.

## Errors you'll actually hit

**`fatal: 'main' is already checked out at '/home/me/myrepo'`**
You can't check out the same branch in two worktrees. That's a feature, not a
bug: two worktrees writing the same branch would corrupt your index. Use a new
branch (`-b`) or a different existing branch.

**`fatal: '../hotfix' is a missing but already registered worktree`**
You `rm -rf`'d the directory instead of `git worktree remove`. Git still has the
bookkeeping entry. Fix: `git worktree prune`.

**`fatal: validation failed, cannot remove working tree: contains modified or untracked files`**
There are uncommitted changes in the worktree. Either commit/stash them or pass
`--force` if you truly don't want them.

**Worktree in a parent directory of the repo confuses tools.**
Some editors and `git`-aware shells get confused when a worktree sits *inside*
the main repo directory. Keep worktrees as siblings (`../name`), not children.

## Things to know

- Worktrees share `.git`, so they share refs, config, and the object store.
  A commit in one is immediately visible in the others. No syncing needed.
- They do NOT share the working directory or the index. Each has its own.
- `git status` in one worktree does not see uncommitted changes in another.
  That's the whole point.
- Deleting the directory manually leaves a stale entry; `git worktree prune`
  cleans it. I have a shell alias for this (see shell-helpers).
- You can't `git worktree add` to a path that already exists and isn't empty.

## Why not just `git stash`

Stash is fine for a 30-second context switch. Worktrees win when the switch is
longer than that, or when you need both states to actually build and run. A
stashed working tree can't run tests while it's stashed. A worktree can.
