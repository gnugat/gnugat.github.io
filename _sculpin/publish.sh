#!/bin/bash

./vendor/bin/sculpin generate --env=prod
cp -r output_prod/* ../

_BLOG_LATEST_ARTICLE=$(ls -1 -t source/_posts/*.md | head -n 1)
_BLOG_LATEST_ARTICLE_TITLE=$(grep '^title:' "${_BLOG_LATEST_ARTICLE}" | sed 's/^title: *"*//' | sed 's/"*$//')
git add -A
git commit -m "Published \"${_BLOG_LATEST_ARTICLE_TITLE}\""
git push
