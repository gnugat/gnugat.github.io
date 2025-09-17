#!/usr/bin/env bash
# File: /_sculpin/publish.sh
# ──────────────────────────────────────────────────────────────────────────────
# Publishes an article:
# * generates HTML from md files
# * adds unstaged changes
# * commits with a `Published "<title>"` message
# * pushes the changes
#
# Usage:
#
# ```shell
# pubish.sh
# ```
# ──────────────────────────────────────────────────────────────────────────────

echo "  // Publishing last article"

./vendor/bin/sculpin generate --env=prod
cp -r output_prod/* ../

_BLOG_LATEST_ARTICLE=$(ls source/_posts/*.md | sort | tail -n 1)
_BLOG_LATEST_ARTICLE_TITLE=$(grep '^title:' "${_BLOG_LATEST_ARTICLE}" | sed 's/^title: *"*//' | sed 's/"*$//')
git add -A
git commit -m "Published \"${_BLOG_LATEST_ARTICLE_TITLE}\""
git push

echo ''
echo "  [OK] Published ${_BLOG_LATEST_ARTICLE_TITLE}"
echo ''
