# Rewriting history

The rule I actually follow: rewrite freely on branches only you have. Once a
branch is pushed and someone else has it, rewriting is a coordination problem,
not a git problem. Ask first.

## Squash the last N commits into one

```bash
git rebase -i HEAD~5
```

Your editor opens with five `pick` lines:

```
pick 1a2b3c4 add upload retry
pick 5d6e7f8 fix typo
pick 9a0b1c2 fix typo again
pick 3d4e5f6 tests for retry
pick 7a8b9c0 review feedback
```

Change all but the first to `squash` (or `s`):

```
pick 1a2b3c4 add upload retry
squash 5d6e7f8 fix typo
squash 9a0b1c2 fix typo again
squash 3d4e5f6 tests for retry
squash 7a8b9c0 review feedback
```

Save, close, and git opens a second editor for the combined message. Write the
one message you'd want in history.

## Edit an old commit (message or contents)

Mark the commit `edit` in the interactive rebase instead of `pick`. Git stops
there. Now you can amend it or change files:

```bash
git commit --amend                 # fix the message or staged content
git add -p                         # or change files, then:
git commit --amend --no-edit
git rebase --continue
```

If you get lost mid-rebase: `git rebase --abort` puts everything back exactly
as it was. Use it without shame.

## Reorder or drop commits

In the rebase todo, move lines to reorder. Delete a line to drop that commit
entirely. Deleting is not "revert" — the change vanishes from the branch.

## The push

After rewriting a pushed branch you must force-push. Use the lease variant:

```bash
git push --force-with-lease
```

`--force-with-lease` refuses if the remote moved since your last fetch. Plain
`--force` overwrites whatever is there. On a shared branch, `--force` is how you
delete a teammate's work.

## Errors you'll actually hit

**`error: cannot 'squash' without a previous commit`**
Your todo starts with `squash`. The first line must be `pick`. Reorder so the
oldest commit is `pick`.

**`CONFLICT (content): Merge conflict in src/uploader.py`** during the rebase
Rebase replays commits one by one, so a conflict is expected if later commits
touched the same lines. Fix the file, `git add` it, `git rebase --continue`.
Do not `git commit` — that makes a new commit instead of continuing.

**`Updates were rejected because the tip of your current branch is behind`**
You forgot `--force-with-lease`. Or someone else pushed. If the latter, stop and
talk to them before forcing.

**`fatal: refusing to merge unrelated histories`**
Not a rebase issue, but you'll see it when squashing across an imported repo.
`git rebase --root` or add `--allow-unrelated-histories` on the merge.

## Keep a safety net

Before any big rewrite:

```bash
git branch backup/pre-rebase
```

If it goes sideways, `git reset --hard backup/pre-rebase`. Costs nothing, saves
evenings. I learned this the hard way.
