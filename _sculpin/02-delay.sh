#!/usr/bin/env bash
# File: /_sculpin/02-delay.sh
# ──────────────────────────────────────────────────────────────────────────────
# Delays the newest article (use if the deadline couldn't be met):
# * finds the date of the next wednesday
# * renames the newest article with that date
#
# Usage:
#
# ```shell
# 02-delay.sh
# ```
# ──────────────────────────────────────────────────────────────────────────────

echo "  // Delaying newest article"

_BLOG_LATEST_ARTICLE=$(find ./source/_posts/ -name '*.md' -type f | sort | tail -n 1)
_BLOG_LATEST_ARTICLE_ORIGINAL_DATE=$(basename "${_BLOG_LATEST_ARTICLE}" | cut -d'-' -f1-3)
_BLOG_LATEST_ARTICLE_SLUG=$(basename "${_BLOG_LATEST_ARTICLE}" | cut -d'-' -f4-)

# The following week
_BLOG_LATEST_ARTICLE_NEW_DATE=$(php -r "echo date('Y-m-d', strtotime('${_BLOG_LATEST_ARTICLE_ORIGINAL_DATE} + 7 days'));")

mv "${_BLOG_LATEST_ARTICLE}" "./source/_posts/${_BLOG_LATEST_ARTICLE_NEW_DATE}-${_BLOG_LATEST_ARTICLE_SLUG}"

echo ''
echo "  [OK] Delayed ${_BLOG_LATEST_ARTICLE_SLUG} from ${_BLOG_LATEST_ARTICLE_ORIGINAL_DATE} to ${_BLOG_LATEST_ARTICLE_NEW_DATE}"
echo ''
