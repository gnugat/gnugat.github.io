---
layout: post
title: Tests cheat sheet
tags:
    - practices
    - Tests series
---

[TL;DR: jump to the conclusion](#conclusion).

This article concludes the series on Tests:

1. {{ link('posts/2014-02-05-tests-introduction.md', 'Introduction') }}
2. {{ link('posts/2014-02-12-tests-tools-overview.md', 'Tools overview') }}
3. {{ link('posts/2014-02-19-test-driven-development.md', 'Test Driven Development') }}
4. {{ link('posts/2014-02-26-tdd-just-do-it.md', 'TDD: just do it!') }}
5. {{ link('posts/2014-03-05-spec-bdd.md', 'spec BDD') }}
6. {{ link('posts/2014-03-11-phpspec-quick-tour.md', 'phpspec: a quick tour') }}
7. {{ link('posts/2014-03-19-behavior-driven-development-story-bdd.md', 'Behavior Driven Development: story BDD') }}
8. {{ link('posts/2014-03-26-behat-quick-tour.md', 'Behat: a quick tour') }}
9. {{ link('posts/2014-04-02-tests-cheat-sheet.md', 'Conclusion') }}

I've tried to put as much general information and references to blogs which
could help you to go further, in each article. In this final post, I'll regroup
those references and the conclusions.

* [Definitions](#definitions)
* [Tools overview](#tools-overview)
* [TDD](#test-driven-development-tdd)
* [BDD](#behavior-driven-development-bdd)
* [Conclusion](#conclusion)

## Definitions

A test is a way to check if something behaves correctly. This something is
called a System Under Test (SUT) and can be:

* the User Interface (HTML, console output, etc): integration tests
* classes, functions: unit tests
* interractions between those classes and functions: functional tests
* the business value: acceptance tests

Generally, you proceed as follow:

1. have a set of input (parameters, fixtures, etc)
2. put it in the SUT
3. check the output

When doing unit tests, you'll need to isolate your SUT from its collaborators
(the dependencies, the other classes used by it). To do so, you'll need test
doubles and Dependency Injection.

### References

* [Tests doubles explained by Martin Fowler](http://martinfowler.com/articles/mocksArentStubs.html)
* {{ link('posts/2014-01-22-ioc-di-and-service-locator.md', 'Dependency Injection explained') }}
* [Test coverage can be deceptive, by Jason Gorman](http://codemanship.co.uk/parlezuml/blog/?postid=1202)

## Tools overview

Frameworks can help you to automate your tests. You'll generally find these
tools:

* integration tests:
    * [Alexandre Salome's webdriver](https://github.com/alexandresalome/php-webdriver) (PHP)
    * [Facebook's webdriver](https://github.com/facebook/php-webdriver) (PHP)
    * [Goutte](https://github.com/fabpot/goutte) (PHP)
    * [PhantomJS](http://phantomjs.org/)
* xUnit frameworks:
    * [PHPUnit](http://phpunit.de/) (PHP)
    * [Atoum](https://github.com/atoum/) (PHP)
    * [Codeception](http://codeception.com/) (PHP)
    * [Mocha](http://visionmedia.github.io/mocha/) (js)
    * [CasperJs](http://casperjs.org/) (js)
* tests double libraries:
    * [Prophecy](https://github.com/phpspec/prophecy) (PHP)
    * [Mockery](https://github.com/padraic/mockery) (PHP)
    * [Sinon.js](http://sinonjs.org/) (js)
* assertion libraries:
    * [Chai](http://chaijs.com/) (js)
* behavior frameworks:
    * [phpspec](http://www.phpspec.net/) (PHP)
    * [Behat](http://behat.org/) (PHP)
    * [jasmine](http://jasmine.github.io/2.0/introduction.html) (js)

*Note*: xUnit frameworks allows many kinds of tests (they're not limited to unit
tests).

*Note*: WebDriver is an API for [Selenium](http://docs.seleniumhq.org/), a java
server which allows you to interract with a browser.

### References

* [xUnit conventions](http://www.xprogramming.com/testfram.htm)
* [Mathias Verraes writing tests to allow him to improve the code](http://verraes.net/2013/09/extract-till-you-drop/)

## Test driven development (TDD)

A process in which:

1. you write the test first
2. then you write the code to make the test pass as quickly as possible (commit any sins)
3. refactor the code, clean your sins

This allows you to naturally have a 100% test coverage, and it has the side
effect of making your code more decoupled (you need your code to be decoupled in
order to test it).

### References:

* [Kent Beck's book: Test Driven Development by Example](http://en.wikipedia.org/wiki/Test-Driven_Development_by_Example)
* [Ian Cooper coming back to the sources of TDD](http://vimeo.com/68375232)
* [False arguments against TDD](http://codemanship.co.uk/parlezuml/blog/?postid=1170)
* [What TDD is and is not](http://www.daedtech.com/what-tdd-is-and-is-not)
* [Where is the design phase in TDD](http://blog.8thlight.com/uncle-bob/2014/03/11/when-to-think.html)

About writing the code as quickly as possible, commiting any sins:

* [Duct tape programming](http://www.joelonsoftware.com/items/2009/09/23.html)
* [You should write ugly code](http://redotheweb.com/2013/06/04/you-should-write-ugly-code.html)
* [Managed technical debt](http://verraes.net/2013/07/managed-technical-debt/)

## Behavior Driven Development (BDD)

BDD is divided in two sections: spec and story. It comes from the lack of
direction in TDD and introduces the concept of business value.

* spec BDD: test methods should be sentences
* story BDD: acceptance criteria (from user stories) should be executable

[Behat](http://behat.org/) and [phpspec](http://www.phpspec.net/) allows you to
automate the process by allowing you to:

1. bootstrap the test
2. then you have to manually implement the test
3. bootstrap the code from the written tests
4. then you have to manually implement the code

### References:

* [Introductiong BDD](http://dannorth.net/introducing-bdd/)
* [Whose domain is it anyway?](http://dannorth.net/2011/01/31/whose-domain-is-it-anyway/)
* [Slides by Liz Keogh](http://www.slideshare.net/lunivore/behavior-driven-development-11754474)
* [Are you really doing BDD?](http://www.wekeroad.com/2013/08/28/how-behavioral-is-your-bdd/)
* [Acceptance Test fail!](http://ht.ly/pfNW5)

## Conclusion

Automated tests allow you to make sure your system isn't full of bug, and help
to detect any regressions.

Theres many kinds out there: you can test what the user sees, what the computer
sees and what the product owner expects.

I'd be really glad if this cheat sheet was of some use to you. If you have any
comments, you can contact me on [Twitter](https://twitter.com/epiloic) :) .

### Note about BDD, behat and selenium

I had [great feedbacks](https://twitter.com/epiloic/status/449280860236570625)
about the {{ link('posts/2014-03-26-behat-quick-tour.md', 'Behat article') }}:
which were triggered by the following statement: "if you're using Mink
or Selenium, then you're doing it wrong". Let me re-phrase that.

If you're using Selenium or Mink, then you're doing integration tests, not
behavior ones. Those tools are fine: the UI is what the user sees and interacts
with, so it's important to make sure it isn't broken.

What isn't fine is to use Behat with these tools and then to say that you're
doing BDD. Use the right tools for the job:
[PHPUnit can perfectly be used with selenium](http://phpunit.de/manual/3.7/en/selenium.html),
and libraries like [webdriver](https://github.com/alexandresalome/php-webdriver)
allow you to work with selenium without using Behat.

One of the question raised was: "If I can't interract with the UI, how do I test
the behavior of my application?"" Well there's many ways and the answer deserves
a whole article or even a whole series! I'll just give you the douchebag (it's
the actual application name, I mean no offense!) example:

* [the slides explaining the application](https://speakerdeck.com/igorw/silex-an-implementation-detail)
* [the sources](https://github.com/igorw/doucheswag/)

Inner conclusion: make a distinction between integration (HTML, UI, etc) and
Behavior (business value, acceptance criteria from user stories) tests.
If you can't do both, then the choice is yours: which one is the most important
to you?
