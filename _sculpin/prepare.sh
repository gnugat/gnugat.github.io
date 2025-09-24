#!/usr/bin/env bash
# File: /_sculpin/prepare.sh
# ──────────────────────────────────────────────────────────────────────────────
# Prepares last article for publication:
# * adds unstaged changes
# * commits with a `Prepared "<title>"` message
# * merges the branch in main
# * pushes the changes
#
# Usage:
#
# ```shell
# prepare.sh
# ```
# ──────────────────────────────────────────────────────────────────────────────

echo "  // Preparing last article for publication"

_BLOG_LATEST_ARTICLE=$(ls source/_posts/*.md | sort | tail -n 1)
_BLOG_LATEST_ARTICLE_TITLE=$(grep '^title:' "${_BLOG_LATEST_ARTICLE}" | sed 's/^title: *"*//' | sed 's/"*$//')
git add -A
git commit -m "Prepared \"${_BLOG_LATEST_ARTICLE_TITLE}\""
_BLOG_BRANCH=$(git branch --show-current) && \
    git checkout main && \
    git merge --no-ff $_GIT_BRANCH && \
    git branch -D $_GIT_BRANCH && \
    git push

echo ''
echo "  [OK] Prepared ${_BLOG_LATEST_ARTICLE_TITLE}"
echo ''
