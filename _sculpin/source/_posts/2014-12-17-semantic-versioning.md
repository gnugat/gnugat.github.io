---
layout: post
title: Semantic Versioning
tags:
    - introducing methodology
---

> **TL;DR**: A library's public API can be: fully qualified class names,
> object's types, exceptions, method names and arguments.

When working on a project, every change made to it can possibly break its usage.
Sometimes this is because we introduced a bug, but some other times this is
because the project's usage needed to be changed.

Or did it?

In this article, we will discuss about semantic versioning, and public API.

## Semantic Versioning

In order to make the migration between two versions easier for users, we could
use [Semantic Versioning](http://semver.org/), which can be summed up as follow:

> Given a version number MAJOR.MINOR.PATCH, increment the:
>
> 1. MAJOR version when you make incompatible API changes
> 2. MINOR version when you add functionality in a backwards-compatible manner
> 3. PATCH version when you make backwards-compatible bug fixes

The trick is to define a "public API" (what the user actually use) and promise
that we won't break it as long as we don't increment the MAJOR version.

## Public API

The "public API" will vary between projects:

* for a CLI tool, it will be the command names, their options and arguments
* for a web API, it will be the URLs
* for a library, it will be a set of defined classes

Let's focus on libraries.

## Redaktilo example

When I started the [Redaktilo](https://github.com/gnugat/redaktilo) library I
had a lot of decisions to make:

* what name and responsibility to give to new objects
* what names and arguments to give to methods
* what exception to throw in case of errors

I knew that I could make the wrong choices, which would mean changing names,
types, arguments, etc. Basically, for the developers using the library it would
mean breaking their code.

### Private and public classes

In order to avoid that as much as possible, I've decided to minimize the number
of classes the developers would use: a `Text` model and an `Editor` service.
`Editor` doesn't contain any logic, it relies on several "private" classes to do
the actual job. It's a [Facade](http://en.wikipedia.org/wiki/Facade_pattern).

So my public API was the `Gnugat\Redaktilo\Editor`'s fully qualified classname
(full namespace and the class name), and its methods (name and arguments).

### Private class constructors

Later on in the project we've introduced a version that didn't change the
defined public API, but broke the projects that were using Redaktilo: the issue
was that we added a new arguments in a private class's constructor.

Therefore the public API was extended to **every** constructors.

To fix the backward compatibility break, we made this new argument optional.

### Exceptions

Some time passed and we've decided to re-organize the project's exceptions:
moving them to their own sub-namespace (`Gnugat\Redaktilo\Exception`)
and throwing only exceptions we owned.
But by doing so we could potentially break project's using our library.

Hence we extended the public API to exceptions.

To avoid backward compatible breaks we simply duplicated the exceptions:
the new ones in the sub-namespace contain all the logic and inherit from the old
exceptions to get their types.

## Making changes to the public API

Defining a public API doesn't mean we can't make changes to it:

* we can add new arguments to methods, by making them optional
* we can change a class name and type, by creating a new one and make it extend the old one
* we can change a method name, by creating a new one and use it in the old one
* we can add a method to an interface, by creating a new interface and make it extend the old one

Those changes will introduce deprecations that will be removed only when the
MAJOR version is incremented.

This can be documented directly in the code, using [phpdoc](http://www.phpdoc.org/docs/latest/references/phpdoc/tags/deprecated.html):
use `@deprecated <since-version> <what to use instead>`.

This can also be described in a migration documentation (e.g. `UPGRADE-2.0.md`).

## Avoid complete rewrites

Semantic versioning only applies to versions greater than `1.0.0`: if you tag your project as
being in version `0.MINOR.PATCH` you are allowed to break everything. But
remember that it will make your project very unstable, and people won't trust
it.

In theory you could break everything again when incrementing the MAJOR version
(e.g. from version 1 to version 2), but this won't be appealing at all for
people that already use your project. Try to make as few changes as possible,
document them and give time to your users to stop using deprecated stuff.

## Conclusion

Semantic versioning is a versioning methodology which has its perks and
advantages. It gives high priority to user's experience, so you have to define a
line between what should be used (public API) and what shouldn't (private).

Changes to the public API can be made by keeping the old stuff and document it
as deprecated.

When creating a library, remember that exceptions and all constructors (even of
private classes) are part of the public API.

> **Note**: Many thanks to [Loïck Piera](http://loickpiera.com/) and his help,
> without him I'd still think that declaring a class as being part of the public
> API is sufficient.
