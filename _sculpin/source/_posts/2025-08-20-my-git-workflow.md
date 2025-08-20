---
layout: post
title: My Git Workflow
tags:
    - git
    - introducing-methodology
    - reference
---

> **TL;DR**:
>
> 1. `git checkout -b FEAT-4423-my-feature` from `main`
> 2. `git rebase main` to update
> 3. `git merge --no-ff feature` back in `main` 

Wield the crimson blade of version control,
where every commit carves your legacy into the eternal codex of time.

I wrote about [my git workflow back in 2014](/2014/12/10/keep-it-simple-and-git.html),
which really was just [@jbenet](https://github.com/jbenet)'s
2013 [simple git branching model](https://gist.github.com/jbenet/ee6c9ac48068889b0912).

I very much like this workflow as I still use it, a decade after!

In this article, we'll explore some of the subtleties I've discovered along the way.

* [Branch out of main](#branch-out-of-main)
* [Rebase to update](#rebase-to-update)
* [Merge back in main](#merge-back-in-main)
* [Reflection on Continuous Delivery](#reflection-on-continuous-delivery)

## Branch out of main

Whenever a change (feature, bug fix, etc) needs to be made,
create a new branch from an up-to-date `main`:

```console
# Update main
git checkout main
git pull --rebase

# Create new branch
git checkout -b FEAT-4423-my-feature
```

> **Super Secret Tip 1**: establish a direct relationship between code modifications and project tasks,
> by including the Ticket ID in your branch name. This will allow:
>
> * **Automated Integration**: like linking the branch, its commits, and its Pull Request
>   to the ticket, enabling synchronisation between the ticket and the pull request status,
>   as well as deployment
> * **Traceability and Context**: trace any code change back to its original purpose,
>   which can be helpful when debugging some issues in the future

## Rebase to update

Update your branch often with the changes in `main`:

```console
# Update remote main
git fetch origin

# Get latest main changes
git rebase origin/main

# Update remote feature branch
git push -fu origin FEAT-4423-my-feature
```

> **Super Secret Tip 2**: Enable git's "Reuse Recorded Resolution" (aka "rerere"),
> for automatic conflict resolutions: `git config --global rerere.enabled true`.
>
> This won't solve everything for you, but will save you time when the same
> conflict happens repeatedly.


The rebase command will **move** your commits after the ones in the `main` branch:

* it'll be like starting from the latest changes in `main` as the foundation
* then your commits are replayed one by one, allowing for simpler conflict resolution
* finally this makes your branch history more linear and clear

So for example, instead of having branches look like this:

```
*   a1b2c3d - Merged in feature-x (pull request #123) (Dev A)
|\
| *   e4f5g6h - Merge main into feature-x (Dev A)
| |\
* | | b7c8d9e - Merged in hotfix-y (pull request #124) (Dev B)
|\| |
| * | f1a2b3c - hotfix for critical bug (Dev B)
| |/
|/|
* |   d4e5f6g - Merged in feature-z (pull request #122) (Dev C)
|\ \
| |/
|/|
* | h7i8j9k - refactor database layer (Dev C)
|/
*
```

With rebase it'd look like that:

```
*   a1b2c3d - Merged in feature-x (pull request #123) (Dev A)
|\
| * e4f5g6h - implement feature x functionality (Dev A)
|/
*   b7c8d9e - Merged in hotfix-y (pull request #124) (Dev B)
|\
| * f1a2b3c - hotfix for critical bug (Dev B)
|/
*   d4e5f6g - Merged in feature-z (pull request #122) (Dev C)
|\
| * h7i8j9k - refactor database layer (Dev C)
|/
*
```

As you can see each feature is now a clean line of commits,
making it easy to see what each feature contributed.

The linear, readable history allows us to identify merge commits we might want to
revert, when we want to roll back a feature.

> **Super Secret Tip 3**: To display branches with `git lg`,
> set the following alias in your git config:
>
> ```
> [alias]
>    # Logs history in a graph format with colours:
>    # * abbreviated commit hash in red
>    # * branch and tag names in cyan
>    # * commit title in white
>    # * author name in yellow
>    # * author date in green (format: `Mon, 02 Jan 2006 15:04:05 +0000`)
>    lg  = log --graph --pretty=tformat:'%Cred%h%Creset -%C(cyan)%d %Creset%s (%C(yellow)%an%Creset %Cgreen%aD%Creset)' --abbrev-commit
> ```

## Merge back in main

Once tests pass, code quality checks are green, code review is approved,
and overall the changes in the branch are production ready,
you can finally merge it back to main:

```console
# Update main
git checkout main
git pull --rebase origin/main


# Double check you had the latest changes
git checkout -
git rebase main
## ⚠️ If there are new changes from main, redo all checks (test, code quality, etc)

# Merge your branch in main
git checkout main
git merge --no-fast-forward FEAT-4423-my-feature
```

The `--no-fast-forward` (`--no-ff`) option will force git to create a merge commit,
which then makes it simple to undo a feature, using `git revert -m 1 <merge-commit-hash>`
(this will create a reverse diff of all the changes introduced by the merge).

## Reflection on Continuous Delivery

For the many years I've used this workflow,
I was working in a small team of 4 developers,
and I was curious to see if it would scale well in bigger teams.

A habbit I had taken was to break the feature into small "atomic" steps,
and so my branches would look like that:

```
*   a1b2c3d - Merged in feature-y (pull request #321) (Dev A)
|\
| * e4f5g6h - feature y step 3 (Dev A)
| * f1a2b3c - feature y step 2 (Dev A)
| * h7i8j9k - feature y step 1 (Dev A)
|/
*
```

These feature would take me about a week to implement,
meaning I could deliver the feature to production within the 2-weeks sprint.

But hearing about Continuous Delivery,
and how some teams deploy to prod sometimes multiple times a day,
I realy was wondering how it could at all be possible.

During my time at Bumble in 2025, I finally got some answers on these two questions.



