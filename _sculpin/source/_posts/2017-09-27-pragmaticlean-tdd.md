---
layout: post
title: PragmatiClean - TDD
tags:
    - pragmaticlean
    - symfony
    - tdd
---

> **TL;DR**: Write tests first, then code, then refactor.
> Only unit test Commands and Command Handlers.
> Only functional test Controllers and Commands.

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

## Clean Code

## Pragmatic Code

## Symfony Example

## Conclusion

Command Bus allows us to decouple our application logic from the framework,
protecting us from Backward Compability Breaking changes.

However since the Bus can be replaced by Event Listeners, we can simply drop it
and inject the Command Handlers directly in Controllers. If our application
isn't asynchronous, then Command Handlers should be able to return values.

So our PragmatiClean Command Bus is simply a Command and Command Handler pair
for each Use Case in our application (so one pair per Controller action).

> For more resources on TDD, check these links:
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
>
> Also here are some usage examples, with code and everything:
>
> * [Mars Rover](https://gnugat.github.io/2016/06/15/mars-rover-introduction.html):
>   an application coded chapter after chapter, using TDD
> * [The Ultimate Developer Guide to Symfony](https://gnugat.github.io/2016/03/24/ultimate-symfony-api-example.html)
>   Examples on how to create an API endpoint, a full stack web page and a console command
>   with Symfony and TDD
