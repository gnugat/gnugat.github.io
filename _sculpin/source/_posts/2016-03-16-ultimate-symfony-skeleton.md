---
layout: post
title: The Ultimate Developer Guide to Symfony - Skeleton
tags:
    - symfony
    - ultimate symfony series
    - reference
---

> **Reference**: This article is intended to be as complete as possible and is
> kept up to date.

> **TL;DR**: Start by putting everything in `AppBundle` until we have a better
> idea of what the project looks like and how to organize it.

In this guide we've explored the main standalone libraries (also known as "Components")
provided by [Symfony](http://symfony.com) to help us build applications:

* [HTTP Kernel and HTTP Foundation](/2016/02/03/ultimate-symfony-http-kernel.html)
* [Event Dispatcher](/2016/02/10/ultimate-symfony-event-dispatcher.html)
* [Routing and YAML](/2016/02/17/ultimate-symfony-routing.html)
* [Dependency Injection](/2016/02/24/ultimate-symfony-dependency-injection.html)
* [Console](/2016/03/02/ultimate-symfony-console.html)

We've also seen how HttpKernel enabled reusable code with [Bundles](/2016/03/09/ultimate-symfony-bundle.html).

In this article, we're going to have a closer look at how to organise our applications
directory tree.

## Editions

Deciding how our project directory is organized is up to us, but for consistency
and convenience we usually use "Editions" to bootstrap new projects:

```
composer create-project gnugat/symfony-empty-edition our-project
cd our-project
```

> **Note**: Here we've decided to use the [Symfony Empty Edition](https://github.com/gnugat/symfony-empty-edition)
> which follows the "add what you need" philosophy (it only contains the strict minimum).
>
> If we're rather fond of the "solve 80% of use cases" philosophy we can go for
> [Standard Edition](https://github.com/symfony/symfony-standard)
> which includes many tools commonly used to build full-stack websites.
>
> To find more distributions, [check the official website](http://symfony.com/distributions).

The directory tree looks like this:

```
.
├── app
│   ├── AppKernel.php
│   ├── autoload.php
│   └── config
│       ├── config_dev.yml
│       ├── config_prod.yml
│       ├── config_test.yml
│       ├── config.yml
│       └── parameters.yml.dist
├── bin
│   └── console
├── composer.json
├── src
│   └── AppBundle
│       └── AppBundle.php
├── var
│   ├── cache
│   └── logs
└── web
    ├── app.php
    ├── favicon.ico
    └── robots.txt
```

Each folder in the root directory has a purpose:

* `app`: configuration
* `bin`: scripts, binaries
* `src`: our code
* `var`: temporary files
* `web`: public directory exposed via the web server (`app.php` is the front controller)

> **Note**: Classes that wouldn't be used in production can be put outside of
> `src` (e.g. tests could be put in `tests`, fixtures in `fixtures`, etc). They
> should be configured in `composer.json` as follow:
>
> ```
> {
>     "autoload-dev": {
>         "psr-4": {
>             "Gnugat\\Toasty\\Fixtures\\": "fixtures",
>             "Gnugat\\Toasty\\Tests\\": "tests"
>         }
>     }
> }
> ```
>
> This way, when running Composer's `install` command in development we get our
> tests/fixtures classes autoloaded, and when running the same command with `--no-dev`
> option in production we don't.

## AppBundle

Once we have an empty skeleton, we can start organizing our code by puting all
new classes in `src/AppBundle`, as advised by the [official best practice](http://symfony.com/doc/current/best_practices/business-logic.html).

Symfony specific classes can be put in the following directories:

* `src/AppBundle/Command`, for Console Commands
* `src/AppBundle/Controller` for HttpKernel Controllers
* `src/AppBundle/DependencyInjection`, for `CompilerPassInterface` and `ExtensionInterface` implementations
* `src/AppBundle/EventListener`, for EventDispatcher Listeners

Our project specific classes can be put the `src/AppBundle/Service` directory.

The number of classes in will grow overtime, at some point we'll have an itch to
organize them in a better way: we can group them by entity.

Regarding configuration, we can organize it this way:

* `app/config/routings/`, contains Router configuration
* `app/config/services/`, contains Dependency Injection configuration

The directory tree looks like this:

```
.
├── app
│   ├── AppKernel.php
│   ├── autoload.php
│   └── config
│       ├── config_dev.yml
│       ├── config_prod.yml
│       ├── config_test.yml
│       ├── config.yml
│       ├── parameters.yml.dist
│       ├── routings
│       └── services
├── bin
│   └── console
├── composer.json
├── composer.lock
├── src
│   └── AppBundle
│       ├── AppBundle.php
│       ├── Command
│       ├── Controller
│       ├── DependencyInjection
│       │   └── CompilerPass
│       ├── EventListener
│       └── Service
├── var
│   ├── cache
│   └── logs
└── web
    ├── app.php
    ├── favicon.ico
    └── robots.txt
```

## Decoupling from framework

Starting by putting everything in `AppBundle` is fine until we have a better idea
of what the project looks like and how to organize it.

As suggested in the [official best practice](http://symfony.com/doc/current/best_practices/business-logic.html),
we can move our "business logic" (everything in `src/AppBundle/Service`) to a new
`src/<vendor>/<project>` directory.

> **Note**: Replace `<vendor>` by the organization/author (e.g. `Gnugat`)
> and `<project>` by the project name (e.g. `Toasty`).

The directory tree looks like this:

```
.
├── app
│   ├── AppKernel.php
│   ├── autoload.php
│   └── config
│       ├── config_dev.yml
│       ├── config_prod.yml
│       ├── config_test.yml
│       ├── config.yml
│       ├── parameters.yml.dist
│       ├── routings
│       └── services
├── bin
│   └── console
├── composer.json
├── composer.lock
├── src
│   ├── AppBundle
│   │   ├── AppBundle.php
│   │   ├── Command
│   │   ├── Controller
│   │   ├── DependencyInjection
│   │   │   └── CompilerPass
│   │   └── EventListener
│   └── <vendor>
│       └── <project>
├── var
│   ├── cache
│   └── logs
└── web
    ├── app.php
    ├── favicon.ico
    └── robots.txt
```

By leaving Symfony related classes in `src/AppBundle` and our "business logic"
in `src/<vendor>/<project>`, it becomes easier to [decouple from the framework](/2015/09/30/decouple-from-frameworks.html).

## Decouple from libraries

Building on "decoupling from frameworks", we might also want to [decouple from libraires](http://localhost:8000/2015/10/12/decouple-from-libraries.html).
To do so our "business logic" classes should rely on interfaces, and their implementation
would use libraries.

At this point we can get three different categories of classes:

* `Domain` ones, classes that reflect our business logic
* `Component` ones, classes that don't have a direct link to our project and could be reused as libraries
* `Bridge` ones, classes that map our Domain to Component (or third party libraries)

By organizing our directory tree with those categories, it could looks like this:

```
.
├── app
│   ├── AppKernel.php
│   ├── autoload.php
│   └── config
│       ├── config_dev.yml
│       ├── config_prod.yml
│       ├── config_test.yml
│       ├── config.yml
│       ├── parameters.yml.dist
│       ├── routings
│       └── services
├── bin
│   └── console
├── composer.json
├── composer.lock
├── src
│   ├── AppBundle
│   │   ├── AppBundle.php
│   │   ├── Command
│   │   ├── Controller
│   │   ├── DependencyInjection
│   │   │   └── CompilerPass
│   │   └── EventListener
│   └── <vendor>
│       └── <project>
│           ├── Bridge
│           ├── Component
│           └── Domain
├── var
│   ├── cache
│   └── logs
└── web
    ├── app.php
    ├── favicon.ico
    └── robots.txt
```

The issue with the previous organization is that classes in `Bridge` are now away
from their interface. Wouldn't it better to keep related classes close?

Here's an alternative organization, where we move `Bridge` to be in `Domain`:

```
.
├── app
│   ├── AppKernel.php
│   ├── autoload.php
│   └── config
│       ├── config_dev.yml
│       ├── config_prod.yml
│       ├── config_test.yml
│       ├── config.yml
│       ├── parameters.yml.dist
│       ├── routings
│       └── services
├── bin
│   └── console
├── composer.json
├── composer.lock
├── src
│   ├── AppBundle
│   │   ├── AppBundle.php
│   │   ├── Command
│   │   ├── Controller
│   │   ├── DependencyInjection
│   │   │   └── CompilerPass
│   │   └── EventListener
│   └── <vendor>
│       └── <project>
│           ├── Component
│           └── Domain
│               └── Bridge
├── var
│   ├── cache
│   └── logs
└── web
    ├── app.php
    ├── favicon.ico
    └── robots.txt
```

> **Note**: `Components` could also need their own bridges. Also, a "Bundle" is
> a kind of bridge: it maps a library to Symfony.

## Monolithic Repository

There's a possibility that our application grows out of proportion and we decide
it'd be better to split it into smaller applications.

For example if we have an application that creates resources through a backend
and then provides them through an API for other applications, we could split it
in two: `backend` (note that `backend` could also be split in two:
`backend-api` and `backend-ui`) and `api`.

The problem is that those two applications would share a lot of logic, so splitting
them in different repositories could become cumbersome to maintain. A good indicator
to know if they need to be in the same repository: when we create a new version,
do we need to release them together?

In that case it might be worth keeping those two applications in the same repository,
this practice being called "Monolithic Repository".

For our project, it would mean:

* creating an `apps` directory where we would put small symfony applications,
  similar to the first directory tree we've seen
* creating a `packages` directory where we would put the previous content of `src/<vendor>/<project>`,
  with each component in their own directory (to enable us to use them selectively in each apps)

Here's an overview:

```
.
├── apps
│   └── <app>
│       ├── app
│       │   ├── AppKernel.php
│       │   ├── autoload.php
│       │   └── config
│       │       ├── config_dev.yml
│       │       ├── config_prod.yml
│       │       ├── config_test.yml
│       │       ├── config.yml
│       │       ├── parameters.yml.dist
│       │       ├── routings
│       │       └── services
│       ├── bin
│       │   └── console
│       ├── composer.json
│       ├── composer.lock
│       ├── src
│       │   └── AppBundle
│       │       ├── AppBundle.php
│       │       ├── Command
│       │       ├── Controller
│       │       ├── DependencyInjection
│       │       │   └── CompilerPass
│       │       └── EventListener
│       ├── var
│       │   ├── cache
│       │   └── logs
│       └── web
│           ├── app.php
│           ├── favicon.ico
│           └── robots.txt
└── packages
    └── <package>
        ├── composer.json
        └── src
```

> **Note**: More information about Monolithic Repository:
>
> * [On monolithic repositories](http://gregoryszorc.com/blog/2014/09/09/on-monolithic-repositories/)
> * [Advantages of monolithic version control](http://danluu.com/monorepo/)
> * [Managing monolithic repositories with composer’s path repository](http://sroze.io/2015/09/14/managing-monolith-repositories-with-composers-path-repository/)
> * [Working with a single, big, scary version control repository](https://qafoo.com/talks/15_10_symfony_live_berlin_monorepos.pdf)
> * [Monolithic Repositories with PHP and Composer](http://www.whitewashing.de/2015/04/11/monolithic_repositories_with_php_and_composer.html)
> * [Conductor: A return to monolith](http://tech.mybuilder.com/why-we-created-conductor/)

## Conclusion

There are many ways to organize our application directory tree, and it's difficult
to pick one when we don't have a clear idea on their impact or on what our project
should look like.

The best way to tackle this is to first start small (everything in `src/AppBundle`),
and then move gradually files around. It's also important to make sure that change
is possible.

Here are some alternative ways of organizing the project directory tree:

* [Structuring my application](http://programmingarehard.com/2015/03/04/structing-my-application.html/)
  by [David Adams](http://twitter.com/dadamssg)
* [Code Folder Structure](http://verraes.net/2011/10/code-folder-structure/)
  by [Mathias Verraes](http://twitter.com/mathiasverraes)
* [DDD with Symfony2: Folder Structure And Code First](http://williamdurand.fr/2013/08/07/ddd-with-symfony2-folder-structure-and-code-first/)
  by [William Durand](http://williamdurand.fr/)
