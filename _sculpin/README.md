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

## 2. Generating static files

To be able to preview the changes, generate the static files:

```
sh preview.sh
```

Changes can then be seen in the browser [at the following link](http://localhost:8000/).

## 3. Publishing changes

To publish the changes, commit them and push them:

```
sh publish.sh
git add -A
git commit -m 'New content!'
git push
```

The website [gnugat.github.io](https://gnugat.github.io) should take a few
minutes before being updated.

## Bonus

Some scripts are available to ease things:

* `bootstrap.sh`: bootstraps the next article
* `prepare.sh`: prepares last article for publication
* `publish.sh`: publishes an article
