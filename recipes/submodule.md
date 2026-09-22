# Submodules

Honest take: submodules are the most common source of "why is this directory
empty" in my life. They're fine once you understand that a submodule pins an
exact commit, and the superproject only stores that commit's SHA.

## Add one

```bash
git submodule add https://github.com/c991china/some-lib.git vendor/some-lib
git commit -m "add some-lib submodule"
```

This creates `.gitmodules` and a gitlink entry. Commit both. If you forget
`.gitmodules`, nobody else can init it.

## Clone a repo that has submodules

A plain `git clone` gives you empty submodule directories. You need:

```bash
git clone --recurse-submodules https://github.com/c991china/parent.git
```

Already cloned without it?

```bash
git submodule update --init --recursive
```

`--init` registers the submodule (reads `.gitmodules`), `--recursive` handles
nested submodules. Forget `--recursive` and you'll get one level and then
confusing emptiness.

## Update a submodule to a newer commit

```bash
cd vendor/some-lib
git fetch
git checkout v2.3.1          # or a sha
cd ../..
git add vendor/some-lib      # the gitlink changed
git commit -m "bump some-lib to v2.3.1"
```

Pull the latest for all submodules at once:

```bash
git submodule update --remote --merge
```

`--remote` uses the branch in `.gitmodules` (defaults to the remote HEAD), not
the pinned SHA. That's the difference between "stay put" and "move forward".

## The detached HEAD trap

After `git submodule update`, the submodule is in **detached HEAD** state. It's
at the pinned commit, which is correct, but if you `git commit` there your commit
is not on any branch and gets orphaned when someone runs `submodule update`
again.

If you intend to make changes inside the submodule, checkout a branch first:

```bash
cd vendor/some-lib
git checkout main
# make changes, commit, push
```

Then update the gitlink in the parent and commit that.

## Remove one

Newer git (2.17+) does the cleanup for you:

```bash
git submodule deinit -f vendor/some-lib
git rm vendor/some-lib
rm -rf .git/modules/vendor/some-lib    # the cached clone
git commit -m "remove some-lib submodule"
```

Skip the `rm -rf .git/modules/...` and re-adding the submodule later reuses a
stale cached clone. I have hit this and wasted a morning.

## Errors you'll actually hit

**`fatal: remote origin already exists`** when running `submodule add` again
The submodule is half-added. `git submodule deinit -f <path>` then remove the
`.git/modules/<path>` dir and try again.

**`error: Server does not allow request for unadvertised object <sha>`**
The pinned SHA isn't reachable on the remote. Usually means someone committed a
submodule pointer to a commit that only exists in their local clone. They need
to push the submodule branch.

**`fatal: needed a single revision`** on `submodule update`
The `.gitmodules` URL is wrong, or the commit no longer exists upstream (force
push in the submodule repo). Check the URL with `git config -f .gitmodules -l`.

## When to not use submodules

If you just want vendored code, a subtree or a package manager is often less
pain. Submodules are for when you genuinely track an independent project and
want the parent to pin an exact revision. If that's not your case, don't.
