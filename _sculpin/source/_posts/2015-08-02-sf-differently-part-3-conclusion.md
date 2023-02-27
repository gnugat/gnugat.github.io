---
layout: post
title: "Symfony Differently - part 3: Conclusion"
tags:
    - symfony
    - symfony differently
    - deprecated
---

This series isn't really working for me, so I've decided to conclude it prematurely.
Have a look at the first ones:

1. [Introduction](/2015/06/03/sf-differently-part-1-introduction.html)
2. [Bootstrap](/2015/06/10/sf-differently-part-2-bootstrap.html)

In this article we'll see a series of optimizations with their impact. Then we'll
conclude that Caching is actually better, let's see those figures!

## Tools

The application is built with the Symfony Standard Edition and Doctrine ORM's QueryBuilder.
Composer's configuration has been tweaked to use PSR-4 and to not autoload tests.
Also Composer has been run with the `--optimize-autoloader` option.

Tests are done using [ab](https://httpd.apache.org/docs/2.2/programs/ab.html)
(with 10 concurrent clients for 10 seconds), on a different server than the application's
one.

Also, we're using PHP 5.5 and Symfony 2.7.

## Optimizations

The application would initially serve: **22 requests / seconds**.

By removing unused dependencies, we get **23 requests / seconds**.

> Note
>
> Removed:
>
> * AsseticBundle
> * SensioDistributionBundle (only from `AppKernel`, the dependency is kept to generate `app/bootstrap.php.cache`)
> * SensioGeneratorBundle
> * SwiftmailerBundle
> * TwigBundle
> * WebProfilerBundle
>
> Also, the following components have been disabled:
>
> * Form
> * Validation

By switching from Doctrine ORM's Query Builder to Doctrine DBAL's one: **28 requests / seconds**.

By [adding classes to compile](http://labs.octivi.com/mastering-symfony2-performance-internals/):
**29 requests / seconds**.

By defining controllers as services: **30 requests / seconds**.

This sums up to an increase of 36%.

## How about using HTTP cache?

By setting a 10 seconds HTTP cache (using [FOSCacheBundle](http://foshttpcachebundle.readthedocs.org/en/latest/)),
on top of the previous optimizations , we get **160 requests / seconds** (an increase of 430%).

And that's by using Symfony's built in reverse proxy, imagine what we could get with varnish!

## Conclusion

While optimizations are fun, they don't bring much value. The main bottlenecks
are usually the autoloading, database/network transactions and the number of functions
called.

On the other hand, using a reverse proxy is quite simple and does pay off!
