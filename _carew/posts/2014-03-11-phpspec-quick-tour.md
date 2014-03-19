---
layout: post
title: phpspec: a quick tour
tags:
    - technical
    - Tests series
---

[TL;DR: jump to the conclusion](#conclusion).

This article is part of a series on Tests in general and on how to practice
them:

1. {{ link('posts/2014-02-05-tests-introduction.md', 'Introduction') }}
2. {{ link('posts/2014-02-12-tests-tools-overview.md', 'Tools overview') }}
3. {{ link('posts/2014-02-19-test-driven-development.md', 'Test Driven Development') }}
4. {{ link('posts/2014-02-26-tdd-just-do-it.md', 'TDD: just do it!') }}
5. {{ link('posts/2014-03-05-spec-bdd.md', 'spec BDD') }}
6. {{ link('posts/2014-03-11-phpspec-quick-tour.md', 'phpspec: a quick tour') }}
7. {{ link('posts/2014-03-19-behavior-driven-development-story-bdd.md', 'Behavior Driven Development: story BDD') }}

The {{ link('posts/2014-03-05-spec-bdd.md', 'last article') }} might have seemed
too abstract. Fortunately, this one will be much more concrete! We'll present
[phpspec](http://www.phpspec.net/), a spec BDD tool for PHP.

## Introduction

phpspec automates the Test Driven Development (TDD) and spec BDD process by:

* allowing you to generate the specification
* then allowing you to generate the code from it

It also forces you to follow good practices:

* you can only test non-static public methods
* you cannot generate a code coverage report

It also tries to be less verbose, as you'll see in the next sections.

## Installation

Simply install phpspec using [Composer](https://getcomposer.org/):

    composer require --dev 'phpspec/phpspec:~2.0@RC'

At the time I write this article, phpspec is in Release Candidate, but don't
worry: I've been using it since the beta version and I've never had any trouble.

## Process

First, bootstrap and complete the specification:

    phpspec describe 'Fully\Qualified\Classname'
    $EDITOR spec/Fully/Qualified/ClassnameSpec.php

Then bootstrap and complete the code to make the tests pass:

    phpspec run
    $EDITOR src/Fully/Qualified/Classname.php
    phpspec run

Finally refactor, but keep the tests passing:

    $EDITOR src/Fully/Qualified/Classname.php
    phpspec run

I've found that Marcello Duarte, the creator of phpspec, talks really well about
it in his presentation [Test, transform, refactor](http://www.slideshare.net/marcello.duarte/test-transform-refactor).

I advise you to have a look at his slides, as they explain everything you should
now about the red, green, refactor cycle.

## A tour of the documentation

Surprisingly, the documentation is complete and small:

* [here's the complete list of assertions](http://www.phpspec.net/cookbook/matchers.html)
* [here's how to customize the specification and code tempaltes](http://www.phpspec.net/cookbook/templates.html)
* [here's how to configure phpspec](http://www.phpspec.net/cookbook/configuration.html)

There's nothing missing in these docs!

## Prophecy, the test double framework

Unlike PHPUnit, phpspec uses an external library for its test doubles:
[prophecy](https://github.com/phpspec/prophecy) (but you can still find how to
use it in the [documentation](http://www.phpspec.net/cookbook/configuration.html)).

## Conclusion

phpspec generates specification and code boilerplates for you. It forces you to
concentrate on the class behavior rather than on the implementation and it
provides a non verbose API. Even its documentations is complete and small!

I hope you enjoyed this article, be sure to
[tweet me what you think about it](https://twitter.com/epiloic) ;) .
