#!/bin/bash

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

echo "  [OK] Created ${_BLOG_NEXT_ARTICLE_FILENAME}"
