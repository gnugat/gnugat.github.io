---
layout: post
title: Mars Rover, Introduction
tags:
    - mars rover series
    - mono repo
    - cqrs
    - event sourcing
    - tdd
---

Welcome to this Mars Rover series where we're going to practice the followings:

* Monolithic Repositories (MonoRepo)
* Command / Query Responsibility Segregation (CQRS)
* Event Sourcing (ES)
* Test Driven Development (TDD)

In this introductory article, we're simply going to describe our Mars Rover
specifications.

> **Note**: This programming exercise originally comes from
> [Dallas Hack Club](http://dallashackclub.com/rover), which is now
> unfortunately down.
>
> This Mars Rover [kata](https://en.wikipedia.org/wiki/Kata_(programming))
> has been adapted for the needs of this series.

But first, let's have a quick reminder on what the practices mentioned above
are.

## Monolithic Repositories

A MonoRepo is a single versioning repository containing many packages that
would otherwise be versioned in their own repositories.

With it, everything can be found in one place, which makes it easy to:

* navigate
* manage dependencies
* set up
* run tests

However it also brings the following disadvantages:

* no hard separation between packages (thigh coupling is possible)
* limited regarding scaling (disk space, bandwidth)
* no finely grain permission management (a user has access to everything
  or nothing)

MonoRepos make sense for projects that would be packaged / released together
(although it makes it possible to package / release them independently).

> **Note**: Here are some references about MonoRepos:
>
> * [Advantages of a monolithic version control](http://danluu.com/monorepo/)
> * [On Monolithic Repositories](http://gregoryszorc.com/blog/2014/09/09/on-monolithic-repositories/)

## Command / Query Responsibility Segregation

CQRS is about separating "write" logic from "read" logic, and it can be applied
on many levels, for example:

* have a read-only microservice and a separate write microservice
* have endpoints / tasks that are either write or read only
* separate your models in two (again, read-only and write-only)

It's important to note that CQRS can also be applied *partially* in the same
project: use it only when it makes sense.

> **Note**: Here are some references about CQRS:
>
> * [Command / Query Responsibility Segregation](/2015/08/25/cqrs.html)
> * [CQRS](http://martinfowler.com/bliki/CQRS.html)
> * [Adding the R to CQS: some storage options](http://www.jefclaes.be/2013/02/adding-r-to-cqs-some-storage-options.html)
> * [Clarified CQRS](http://udidahan.com/2009/12/09/clarified-cqrs/)
> * [Functional foundation for CQRS / ES](http://verraes.net/2014/05/functional-foundation-for-cqrs-event-sourcing/)
> * [Messaging Flavours](http://verraes.net/2015/01/messaging-flavours/)
> * [Avoiding the Mud](https://speakerdeck.com/richardmiller/avoiding-the-mud)
> * [Do not mistake DDD for CQRS. Yeah but where to start?](https://medium.com/@benjamindulau/do-not-mistake-ddd-for-cqrs-yeah-but-where-to-start-5595b8e68a4d#.vnh8i8rhb)
> * [CQRS/ES](https://moquet.net/talks/phptour-2015/)
> * [Fighting Bottlenecks with CQRS](http://verraes.net/2013/12/fighting-bottlenecks-with-cqrs/)

## Event Sourcing

With ES, every significant action is recorded as an "event". Keeping track of
those events provides the following advantages:

* replay them to recreate the state of an application at a given time
  (undo, redo, synchronization)
* analyse how the latest state came to be (compare two versions or find who did
  what and when)

Just like with CQRS, it's important to note that ES can also be applied
*partially* inside a project : use it only when it makes sense.

ES is often associated to CQRS, but they can be used separately.

> **Note**: Here are some references about ES:
>
> * [Using logs to build a solid data infrastructure or: why dual writes are a bad idea](https://martin.kleppmann.com/2015/05/27/logs-for-data-infrastructure.html)
> * [Event Sourcing](http://martinfowler.com/eaaDev/EventSourcing.html)
> * [Practical Event Sourcing](http://verraes.net/2014/03/practical-event-sourcing.markdown/)
> * [CQRS/ES](https://moquet.net/talks/phptour-2015/)
> * [Fighting Bottlenecks with CQRS](http://verraes.net/2013/12/fighting-bottlenecks-with-cqrs/)
> * [Functional foundation for CQRS / ES](http://verraes.net/2014/05/functional-foundation-for-cqrs-event-sourcing/)
> * [Meeting the Broadway team - talking DDD, CQRS and event sourcing](http://php-and-symfony.matthiasnoback.nl/2015/07/meeting-the-broadway-team/)

## Test Driven Development

TDD can be summed up in the following steps when developing:

1. create a test
2. then write just enough code to make the test pass (quick and dirty, or
   "make it work")
3. then refactor the code (clean, or "make it right")

Writing the test before the code forces us to think about how we'd like the
future code to be *used*. It's like writing specifications, but with 3
purposes: design, documentation and automated regression checking.

This discipline makes it easy to have a high code coverage (although rigour
still needs to be applied: we need to test all the happy paths and all the
unhappy ones).

> **Note**: Here are some references about TDD:
>
> * [Straw man TDD](http://codemanship.co.uk/parlezuml/blog/?postid=1170)
> * [Coverage!!!](http://codemanship.co.uk/parlezuml/blog/?postid=1202)
> * [The Failures of "Intro to TDD"](http://blog.testdouble.com/posts/2014-01-25-the-failures-of-intro-to-tdd.html)
> * [TDD, avoid testing implementation details](http://tech.mybuilder.com/coupling-tests/)
> * [Monogamous TDD](http://blog.8thlight.com/uncle-bob/2014/04/25/MonogamousTDD.html)
> * [When TDD doesn't work](http://blog.8thlight.com/uncle-bob/2014/04/30/When-tdd-does-not-work.html)
> * [Does TDD really lead to good design?](http://codurance.com/2015/05/12/does-tdd-lead-to-good-design/)
> * [TDD is dead, long live testing](http://david.heinemeierhansson.com/2014/tdd-is-dead-long-live-testing.html)
> * [What TDD is and is not](http://www.daedtech.com/what-tdd-is-and-is-not/)
> * [TDD, where it all went wrong](https://vimeo.com/68375232)
> * [TDD and Complexity](https://medium.com/@davidihunt/tdd-and-complexity-1bbd5ca51ee7#.4mzrdro57)
> * [Giving up on TDD](http://blog.cleancoder.com/uncle-bob/2016/03/19/GivingUpOnTDD.html)

## Specifications

The purpose of this series is to create the software of a Mars Rover, according
to the following specifications.

Mars Rovers need first to be landed at a given position. A position is composed
of coordinates (`x` and `y`, which are both integers) and an orientation
(a string being one of `north`, `east`, `west` or `south`).

It is then possible to drive them, using instructions such as `move_forward`
(keeps orientation, but moves along the `x` or `y` axis) or
`turn_left` / `turn_right` (keeps the same coordinates, but changes the
orientation).

From time to time, they'll be requested to give their current location
(again, `x` and `y` coordinates and the orientation).

For example, a rover can be landed at `23`, `42`, `north` and then can be
instructed to move forward twice, then to turn left, then to move forward once.
When requested to, it should provide this location: `22`, `44`, `west`.

## Identifying use cases

From the above specifications, we can identify at least three use cases:

1. Landing a Rover on Mars
2. Driving the rover
3. Requesting its location

## What's next

In the next article, we'll start developing for the first use case:
"Landing a Rover on Mars".

> **Note** We'll be using:
>
> * PHP 7:
> * [Composer](https://getcomposer.org)
> * git
> * [phpspec](http://phpspec.net/)
>   and its [SpecGen extension](http://memio.github.io/spec-gen)
