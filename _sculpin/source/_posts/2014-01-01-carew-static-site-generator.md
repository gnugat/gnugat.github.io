---
layout: post
title: Carew, the static site generator
tags:
    - introducing tool
    - deprecated
---

> **Deprecated**: This article has been re-written - see [Scuplin](/2016/01/15/sculpin.html)

Frameworks are a real help when building web applications which serve business
logic. But what about static websites?

Those only contain pages which could be directly written in HTML. The only
problem with this approach is that HTML isn't writter friendly compared to
Markdown.

Also, we could say that static websites like blogs do have some logic behind the
scenes:

- posts can have a state (is it published yet?)
- posts can be tagged, in order to make them easier to find

But still, a framework might be too much for this task.

Static site generators are a way to solve this problem:

1. simply write your pages in markdown
2. launch a command to generate HTML from it

[Carew](http://carew.github.io/) is one of them (among
  [Jekyll](http://jekyllrb.com/),
  [Hyde](http://hyde.github.io/),
  [Poole](https://github.com/obensonne/poole)
  and [Lanyon](https://github.com/spjwebster/lanyon)):
it is written in PHP, allows you to use the template engine
[Twig](http://twig.sensiolabs.org/) in your markdown and it provides a theme
using [Bootstrap](http://getbootstrap.com/2.3.2/).

This blog post will focus on Carew, as
[this very blog is written with it](https://github.com/gnugat/gnugat.github.io).

## Carew and Github

A common way to quickly publish static sites is to use
[Github Pages](http://pages.github.com/) which works as follow:

1. create a repository, the name should follow this format: `<username>.github.io`
2. add, commit and push the content of the `web` directory directly at the
   root of your repo
3. the site is now available at this address: `http://<username>.github.io`

[Learn more about hosting a website built with Carew on the official website](http://carew.github.io/cookbook/hosting.html).

## Creation

Creating your site using Carew is very simple, just follow these steps:

    $ php composer.phar create-project carew/boilerplate <project> -s dev
    $ cd <project>
    $ bin/carew build

Examples pages (which sources are located in `pages` and `posts`) are converted
from markdown to HTML in the `web` directory.

## Customization

Before writing any page or post, edit the configuration wich is located inside
the `config.yml` file.

Then edit the `pages/index.md` and `pages/about.md` pages with your own content.

Finally, remove the content of the `posts` folder and create your first blog
post using this command:

    $ bin/carew generate:post [--date='YYYY-MM-DD'] title

[See the configuration documentation on the official website](http://carew.github.io/cookbook/configuration.html).

## Front matters

Each markdown file starts with a header:

    ---
    layout: post # no need for this line when writing a regular page
    title: Will be used by `<title></title>` and `<h1></h1>`
    tags:
        - first tag
        - carew
    ---

Carew generates a page listing all existing tags. You can create a link to this
page with the following snippet:

    {{ "{{ link('tags', 'The page with all the tags') }}" }}.

[Learn more about Front matters on the official website](http://carew.github.io/documentation.html#front-matter).

## Conclusion

Carew is really simple to use, in this article we've covered the minimum you
should know to create pages, blog posts and tags.

I hope you enjoyed this article and that it helped you a little.

If you want to learn more, for example to customize its behaviour or its theme,
please refer to [the official documentation](http://carew.github.io/documentation.html).
