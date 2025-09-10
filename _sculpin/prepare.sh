#!/bin/bash

_BLOG_LATEST_ARTICLE=$(ls -1 -t source/_posts/*.md | head -n 1)
_BLOG_LATEST_ARTICLE_TITLE=$(grep '^title:' "${_BLOG_LATEST_ARTICLE}" | sed 's/^title: *"*//' | sed 's/"*$//')
git add -A
git commit -m "Prepared \"${_BLOG_LATEST_ARTICLE_TITLE}\""
_BLOG_BRANCH=$(git branch --show-current) && \
    git checkout main && \
    git merge --no-ff $_GIT_BRANCH && \
    git branch -D $_GIT_BRANCH && \
    git push
