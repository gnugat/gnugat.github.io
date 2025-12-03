#!/usr/bin/env bash
# File: /_sculpin/04-merge.sh
# ──────────────────────────────────────────────────────────────────────────────
# Merges the article's branch:
# * checks out the main branch
# * merges the article's branch
# * removes the article's branch
# * pushes the changes
# * generates HTML from md files
# * adds unstaged changes
# * commits with a `Published "<title>"` message
# * pushes the changes
#
# Usage:
#
# ```shell
# 04-merge.sh [merge-to] [merge-from]
# ```
# ──────────────────────────────────────────────────────────────────────────────

echo "  // Merging newest article"

_GIT_MERGE_TO_BRANCH=${1:-main}
_GIT_MERGE_FROM_BRANCH=${2:-$(git branch --show-current)}

if [ "${_GIT_MERGE_TO_BRANCH}" = "${_GIT_MERGE_FROM_BRANCH}" ]; then
    echo "  [ERROR] Cannot merge branch '${_GIT_MERGE_TO_BRANCH}' into itself"
    exit 1
fi

git checkout $_GIT_MERGE_TO_BRANCH && \
    git merge --no-ff $_GIT_MERGE_FROM_BRANCH && \
    git branch -D $_GIT_MERGE_FROM_BRANCH && \
    git push

echo ''
echo "  [OK] Merged ${_GIT_MERGE_FROM_BRANCH}"
echo ''
