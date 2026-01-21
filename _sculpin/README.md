# Sculpin - Loïc Faugeron - Technical Blog

The following commands need to be run from the `_sculpin` directory.

## 0. Installing

If you've freshly cloned this repository, then run:

```
composer install -a
```

## 1. Writing content

Content can be edited or created in the following paths:

* about page is in `source/about.md` 
* articles are in `source/_posts/*.md`
* best articles is in `source/best-articles.md`

Article file names should follow this standard:

* date prefix (`YYYY-MM-DD`)
* hyphened short title
* `.md` suffix

> *Note*: you can use `sh 00-bootstrap.sh` to create a new empty article.

Each article file need to start with the following header:

```
---
layout: post
title: <title>
tags:
    - <tag>
    - ...
---
```

The tags can be anything, however the following tags have a special meaning:

* `deprecated`: will be flagged in red, article should be ignored by readers
* `reference`: will be flagged in green, article should be kept up to date by authors

## Helpful scripts

Some scripts are available to ease things:

* `00-bootstrap.sh`: bootstraps the next article
* `01-preview.sh`: provides a way to preview the changes at http://localhost:42999
* `02-delay.sh`: bumps the date of the newest article (when the original deadline couldn't be met)
* `03-commit.sh`: creates commit for newest article
* `04-merge.sh`: merges the newest article branch back in main
* `05-publish.sh`: publishes latest changes

After running the `05-publish.sh` script, the website
[gnugat.github.io](https://gnugat.github.io) should take a few minutes
before being updated.
