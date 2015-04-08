---
layout: post
title: Introducting Memio, code generator
tags:
    - technical
    - memio
---

> **TL;DR**: Work in Progress: Memio, a library for PHP code generation.

Code generators write code for you, so you don't have to! There's many kinds out there:

* the ones that bootstrap code but can't add anything to it later
* the ones that create code but you can't add anything to it later
* the ones that can add new things to existing files
* the ones that will completly change the style of existing file if they add anything to it

Many frameworks provide code generators, because they can be a real time saver by
automating repetitive boring tasks (e.g. bootstraping a CRUD controller). The only
issue is that usually we can't customize them.

For example with [GeneratorBundle](https://github.com/sensiolabs/SensioGeneratorBundle),
it's impossible to create REST controllers.

Some of them provide templates but don't template engines, like [phpspec](http://phpspec.net/)
for example: this is a step forward but that's not enough.

Now let's have a look at code generator libraries: the main ones don't allow an easy
way to customize the coding style of generated code:

* [Zend Code Generator](http://framework.zend.com/manual/current/en/modules/zend.code.generator.examples.html)
* [PHP Parser](https://github.com/nikic/PHP-Parser)

Some of them do use a template engine, but you need to write a lot of code in order to use
them:

* [TwigGenerator](https://github.com/cedriclombardot/TwigGenerator)

Don't panic! Memio is a code generator library that uses a template engine and provide
out of the box templates, generators and even validation!

Started in september 2014 under the name "Medio", it has now matured enough to be soon
released in stable version (1.0.0).

Let's have a look at what's going to be achieved with it.

## Improving phpspec

The [phpspec typehint extension](https://github.com/ciaranmcnulty/phpspec-typehintedmethods) was
a good playground for Memio: it allowed to test generation of a method argument by:

* adding typehints when needed
* naming object arguments after their types

Once Memio is stable, it will provide its own phpspec extension that aims at:

* generating argument's PHPdoc
* generating use statements for object arguments (no more fully qualified classnames)
* generating dependency injection

Curious about this last bullet point? Then read on.

## Automating Dependency Injection

There are many ways to use constructors, and one of them is dependency injection:
each argument is stored in a property and the class can then use them.

> **Note**: Remember, Dependency Injection is a fancy word for passing arguments.

When doing so, we need to write a lot of boilerplate code:

* add argument to constructor (with PHPdoc, typehint, name after the type)
* add property initialization in constructor body
* add property (with PHPdoc)
* add use statement, if necessary

Memio will automate this in its phpspec extension.

## Possibly more?

We talked about GeneratorBundle: the issue is that we can't define our own templates.
Well Memio could solve this issue in a reusable way!

Usually each applications have its own style, its own requirements, etc. In short:
we can't use the same code generator between projects. But if we focus on a single
project, then we can start using the same code generator to boostrap many classes:
endpoint/page controllers, entities, etc. The possibilities are endless!

## Conclusion

Memio, once stable, will provide a powerful and reusable way of generating code.

What's left to do before the release of v1.0? Mainly splitting the main package
(`memio/memio`) into small ones (`model`, `template-engine`, `validator`, etc).
The main package would become a "standard edition", allowing developers to select
the features they want, for example the template engine (as [requested](https://github.com/memio/memio/issues/51)
by [webmozart](https://github.com/webmozart)).

Stay tuned!

### Thanks

I'd like to thank the following early contributors:

* [funivan](https://github.com/funivan)
* [pyrech](https://github.com/pyrech)
* [tigitz](https://github.com/tigitz)
* [TomasVotruba](https://github.com/TomasVotruba)

Keep up the good work!
