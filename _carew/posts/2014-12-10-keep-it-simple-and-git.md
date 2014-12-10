---
layout: post
title: Keep It Simple and Git
tags:
    - practices
    - git
---

> **TL;DR**: Branch only from master, merge back when done and immediately deploy.

Git proposes a branch system with the possibility to merge them together,
allowing you to separate released code from work in progress one.

Git flows have been created to help you keep the same process in your team.
In this article, we'll have a look at [@jbenet](https://github.com/jbenet)'s
[simple git branching model](https://gist.github.com/jbenet/ee6c9ac48068889b0912):

> 1. `master` must always be deployable.
> 2. **all changes** are made through feature branches (pull-request + merge)
> 3. rebase to avoid/resolve conflicts; merge in to `master`

## Working on a change

Changes can be new features, bug fixes, enhancements. They're all coming from
master:

```bash
git checkout master
git checkout -b my-changes
```

## Making the change ready

Once you're happy with your branch, you need to update it with the last changes
from master:

```bash
git checkout master
git pull --rebase
git checkout my-changes
git rebase master
git push -fu origin my-changes
```

> **Note**: `rebase` will rewrite your commits, their dates will be changed
> (therefore their hash will be changed).

Check your tests, the coding standards and ask for a code review.

### Managing conflicts

You can list conflicts (if any):

```bash
git status
```

Edit your files and then mark them as solved:

```bash
git add <file>
```

When all conflicted files have been resolved, you can continue:

```bash
git rebase --continue
```

### When to merge

Here's a to do list you can use to know if a branch is ready to be merged:

* is it compliant with the coding standards?
* has the code been reviewed?
* do the tests pass?
* has the Quality Assurance team checked the feature?
* will someone be available in the next hour in case of emergency?
* does the product owner want this feature now?

## Deploying the new change

If everything is ok with your change, then you can merge it into master:

```bash
git checkout master
git merge --no-ff my-change
git push
git push origin :my-changes
git branch -D my-changes
```

It's now time to deploy! You can make a tag:

```bash
git tag -a <version>
git push --tags
```

## Conclusion

Make small changes, release often.
