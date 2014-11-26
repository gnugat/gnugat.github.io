---
title: Hi, I'm Loïc
---

This is my blog, where I speak about [Symfony2](http://symfony.com), PHP, tests,
design patterns and other developer stuff.

## Useful links

* {{ link('tags', 'tags') }}
* [RSS Feed](http://gnugat.github.io/feed/atom.xml)
* [Sources on Github](https://github.com/gnugat/gnugat.github.io)

## Posts

{{ render_documents(carew.posts|reverse) }}
