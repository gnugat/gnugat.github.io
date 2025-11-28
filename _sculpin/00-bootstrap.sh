#!/usr/bin/env bash
# File: /_sculpin/00-bootstrap.sh
# ──────────────────────────────────────────────────────────────────────────────
# Bootstraps the next article:
# * finds the date of the next wednesday
# * creates an empty article on that date
#
# > _Note_: file will need to be renamed with propre slugged title 
#
# Usage:
#
# ```shell
# 00-bootstrap.sh
# ```
# ──────────────────────────────────────────────────────────────────────────────

echo "  // Bootstraping next article"

_BLOG_LATEST_ARTICLE=$(ls source/_posts/*.md | sort | tail -n 1)
_BLOG_LATEST_ARTICLE_DATE=$(basename "${_BLOG_LATEST_ARTICLE}" | cut -d'-' -f1-3)

# The following Wednesday
_BLOG_NEXT_ARTICLE_DATE=$(php -r "echo date('Y-m-d', strtotime('${_BLOG_LATEST_ARTICLE_DATE} + 7 days'));")

_BLOG_NEXT_ARTICLE_FILENAME="./source/_posts/${_BLOG_NEXT_ARTICLE_DATE}-next.md"
touch "${_BLOG_NEXT_ARTICLE_FILENAME}"

cat > "${_BLOG_NEXT_ARTICLE_FILENAME}" << EOF
---
layout: post
title: Next
tags:
    -
---

EOF

echo ''
echo "  [OK] Bootstrapped ${_BLOG_NEXT_ARTICLE_FILENAME}"
echo ''
