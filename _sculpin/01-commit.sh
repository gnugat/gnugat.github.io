#!/usr/bin/env bash
# File: /_sculpin/01-commit.sh
# ──────────────────────────────────────────────────────────────────────────────
# Creates a commit for the newest article:
# * adds unstaged changes
# * commits with a `Prepared "<title>"` message
#
# Usage:
#
# ```shell
# 01-commit.sh
# ```
# ──────────────────────────────────────────────────────────────────────────────

echo "  // Creating commit for new article"

_BLOG_LATEST_ARTICLE=$(ls source/_posts/*.md | sort | tail -n 1)
_BLOG_LATEST_ARTICLE_TITLE=$(grep '^title:' "${_BLOG_LATEST_ARTICLE}" | sed 's/^title: *"*//' | sed 's/"*$//')
_BLOG_LATEST_ARTICLE_BRANCH=$(git branch --show-current)
git add -A
git commit -m "Prepared \"${_BLOG_LATEST_ARTICLE_TITLE}\""

echo ''
echo "  [OK] Commit created: Prepared ${_BLOG_LATEST_ARTICLE_TITLE}"
echo ''
