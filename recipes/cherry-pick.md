# Cherry-pick

Cherry-pick copies the *change* from a commit onto your current branch. It makes
a brand-new commit with a new SHA. Useful for backporting a fix without dragging
along the whole branch.

## Copy one commit

```bash
git switch release/1.2
git cherry-pick 1a2b3c4
```

Git applies the diff and commits it, reusing the original message and author.

## Copy a range

```bash
git cherry-pick A..B
```

That's **exclusive of A**, inclusive of B. If you want A too:

```bash
git cherry-pick A^..B
```

`A^` means "A's parent". This trips me up every time, so I say it out loud: the
range is `(A, B]`.

## Don't commit yet, just stage

```bash
git cherry-pick -n 1a2b3c4 1a2b3c5    # -n == --no-commit
# inspect, maybe combine, then:
git commit
```

`-n` applies several picks into one commit. Handy for backporting a small series.

## Keep a reference to the original

```bash
git cherry-pick -x 1a2b3c4
```

`-x` appends `(cherry picked from commit 1a2b3c4)` to the message. Do this for
backports. Six months later, "why is this line here" has an answer.

## Conflicts

Cherry-pick conflicts are just merge conflicts. Fix the files, then:

```bash
git add <files>
git cherry-pick --continue
```

Or bail out:

```bash
git cherry-pick --abort      # back to before the pick
git cherry-pick --quit       # stop, but keep the partial state
```

## Errors you'll actually hit

**`The previous cherry-pick is now empty, possibly due to conflict resolution.`**
You resolved a conflict down to "no change" — the commit's content is already
present. Git doesn't know what to do. Options:

```bash
git cherry-pick --skip        # if the change is genuinely already there
git cherry-pick --allow-empty # if you want an empty commit (rare)
```

**`error: commit 1a2b3c4 is a merge but no -m option was given.`**
You picked a merge commit. Git can't know which parent's diff you want. Say so:

```bash
git cherry-pick -m 1 1a2b3c4    # -m 1 means "diff against the first parent"
```

**Duplicate commits after a later merge.** If you cherry-pick a commit to
`main` and then later merge the original branch, git sees two different SHAs
with the same change and may or may not detect it. `git cherry` / patch-id helps:

```bash
git cherry -v main feature-branch   # lists which commits are already in main
```

Lines starting with `+` are NOT in main; `-` means already there (by patch-id,
so it catches cherry-picks). Use it before cherry-picking a whole branch.

## When not to cherry-pick

If you're picking five commits, you probably want a real merge or a rebase.
Cherry-picking a long series creates divergent history that bites you at the
next merge. Pick single fixes, not features.
