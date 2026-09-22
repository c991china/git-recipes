# Bisect

`git bisect` is a binary search for the commit that broke something. You give it
a known-good and a known-bad commit; it checks out the midpoint and asks (or you
tell it) whether that commit is good or bad. log2(N) steps instead of N.

For 1000 commits that's ~10 checks instead of 1000. It's the highest
value-per-keystroke command in git.

## Manual bisect

```bash
git bisect start
git bisect bad                  # current commit is broken
git bisect good v1.4.0          # this tag was fine

# git checks out a midpoint and prints how many steps remain:
#   Bisecting: 47 revisions left to test after this (roughly 6 steps)
```

Now run your test by hand. Then:

```bash
git bisect good                 # if this commit works
git bisect bad                  # if it doesn't
```

Repeat until git prints:

```
1a2b3c4 is the first bad commit
commit 1a2b3c4...
Author: ...
Date: ...
    refactor: switch parser to streaming
```

Then get out of bisect mode:

```bash
git bisect reset                # back to where you started
```

`reset` is important. Forgetting it leaves you on a detached HEAD wondering why
your branch "lost" commits.

## Automatic bisect (the good one)

If you have a command that exits 0 for good and non-zero for bad, let git drive:

```bash
git bisect start HEAD v1.4.0
git bisect run ./run-tests.sh
```

Or inline:

```bash
git bisect start HEAD v1.4.0
git bisect run python -m pytest tests/test_parser.py -q
```

Exit codes git understands:

| exit code | meaning |
|-----------|---------|
| 0         | good |
| 1–127, 128+ | bad |
| 125       | skip this commit (can't test it) |
| 126/127   | abort the bisect (command not executable/found) |

125 is your friend when a commit doesn't even build — you don't want to call it
"bad", you just can't test it. Return 125 and git skips it.

## A real run-tests.sh for bisect

```bash
#!/usr/bin/env bash
# Return 125 if the code won't build at this commit, so bisect skips instead of
# blaming a commit that just doesn't compile.
set -e
if ! make build >/dev/null 2>&1; then
    exit 125
fi
./run-tests.sh >/dev/null 2>&1   # 0 good, non-zero bad
```

## Errors you'll actually hit

**`You need to give me at least one good and one bad revision.`**
You started bisect and gave no endpoints, then ran `bisect run`. Give both:
`git bisect start <bad> <good>`.

**`fatal: 'v1.4.0' is not a valid revision`**
Tag not fetched. `git fetch --tags` first.

**Bisect says a commit is bad that clearly can't be.**
Your test is flaky. A flaky test makes bisect lie confidently. Run the test
several times at the suspect commit before trusting it. `git bisect run` has no
retry logic.

**Submodules/pip installs not present at old commits.**
Bisect checks out old code but not old dependencies. If your test needs a rebuild
each step, make `run-tests.sh` do the install too. Slow, but correct.

## Tips

- Scope the search: pass the narrowest good/bad pair you can. `HEAD` vs a tag
  from last week beats `HEAD` vs the first commit.
- Write down the good/bad SHAs before you start. If you fat-finger one, the
  whole search is wrong and you'll trust a wrong answer.
- `git bisect log` prints the session so far; `git bisect replay <file>` re-runs
  it. Useful for sharing a bisect with a teammate.
